param(
    [Parameter(Mandatory = $true)]
    [string]$Query,
    [int]$TopN = 5,
    [string]$EmbeddingsPath = "",
    [string]$DelegationConfigPath = "",
    [string]$RegistryPath = "",
    [switch]$Raw
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectRoot {
    $dir = $PSScriptRoot
    for ($i = 0; $i -lt 8; $i++) {
        if (Test-Path (Join-Path $dir ".git")) { return $dir }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    return $PSScriptRoot
}

$ProjectRoot = Resolve-ProjectRoot

if (-not $EmbeddingsPath) { $EmbeddingsPath = Join-Path $ProjectRoot ".atl\skill-embeddings.json" }
if (-not $DelegationConfigPath) { $DelegationConfigPath = Join-Path $ProjectRoot "config\auto-delegation.json" }
if (-not $RegistryPath) { $RegistryPath = Join-Path $ProjectRoot ".atl\skill-registry.md" }

$StopWords = @('a', 'an', 'the', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or', 'is', 'it', 'as', 'be', 'by', 'with', 'from', 'that', 'this', 'are', 'was', 'were', 'been', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'can', 'could', 'should', 'may', 'might', 'shall', 'not', 'no', 'but', 'if', 'so', 'up', 'out', 'about', 'into', 'over', 'after', 'before', 'between', 'under', 'again', 'further', 'then', 'once', 'also', 'very', 'just', 'each', 'any', 'all', 'both', 'more', 'most', 'some', 'such', 'only', 'own', 'same', 'than', 'too', 'el', 'la', 'los', 'las', 'de', 'del', 'en', 'un', 'una', 'que', 'es', 'se', 'por', 'para', 'con', 'una', 'lo', 'como', 'mas', 'pero', 'sus', 'le', 'ya', 'este', 'entre', 'porque', 'todo', 'esta', 'sin', 'son') | ForEach-Object { $_.ToLower() }
$StopWordsSet = @{}
foreach ($w in $StopWords) { $StopWordsSet[$w] = $true }

function Get-StopWordsSet { return $StopWordsSet }

function Tokenize {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }

    $text = $Text.ToLower() -replace '[^a-z0-9\s-]', ' '
    $parts = $text -split '[\s-]+' | Where-Object { $_.Length -ge 2 -and $_.Length -le 40 }
    $sw = Get-StopWordsSet
    return @($parts | Where-Object { -not $sw.ContainsKey($_) })
}

function Ensure-EmbeddingsExist {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        Write-Warning "Embeddings not found at $Path — running embedder..."
        $embedderPath = Join-Path $PSScriptRoot "skill-embedder.ps1"
        if (-not (Test-Path $embedderPath)) {
            Write-Error "Embedder not found at $embedderPath"
            return $false
        }
        & $embedderPath
        if (-not (Test-Path $Path)) {
            Write-Error "Embedder ran but output not found at $Path"
            return $false
        }
    }
    return $true
}

function Load-Embeddings {
    param([string]$Path)
    $json = Get-Content -Path $Path -Raw | ConvertFrom-Json

    $idf = @{}
    foreach ($prop in $json.idf.PSObject.Properties) {
        $idf[$prop.Name] = [double]$prop.Value
    }

    $vocab = @{}
    for ($i = 0; $i -lt $json.vocabulary.Count; $i++) {
        $vocab[$json.vocabulary[$i]] = $i
    }

    $skills = @()
    foreach ($s in $json.skills) {
        $vector = @{}
        foreach ($prop in $s.vector.PSObject.Properties) {
            $vector[$prop.Name] = [double]$prop.Value
        }
        $ngramSet = @{}
        foreach ($g in $s.charNgrams) { $ngramSet[$g] = $true }

        $skills += @{
            name = $s.name
            agent = $s.agent
            triggers = @($s.triggers)
            vector = $vector
            charNgrams = $ngramSet
        }
    }

    return @{
        metadata = $json.metadata
        vocabulary = $vocab
        idf = $idf
        skills = $skills
        sourcePath = $Path
    }
}

function Load-DelegationConfig {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }

    $json = Get-Content -Path $Path -Raw | ConvertFrom-Json
    return $json
}

function Compute-QueryVector {
    param(
        [string]$Query,
        [System.Collections.IDictionary]$Vocabulary,
        [System.Collections.IDictionary]$Idf
    )

    $tokens = Tokenize $Query
    if ($tokens.Count -eq 0) { return @{ vector = @{}; tokens = @(); tokenTf = @{} } }

    $tf = @{}
    foreach ($t in $tokens) {
        if (-not $tf.ContainsKey($t)) { $tf[$t] = 0 }
        $tf[$t]++
    }

    $total = $tokens.Count
    $vector = @{}
    foreach ($t in $tf.Keys) {
        if ($Vocabulary.ContainsKey($t)) {
            $tfVal = [Math]::Log10(1 + $tf[$t] / $total * 100)
            $idfVal = if ($Idf.ContainsKey($t)) { $Idf[$t] } else { 1.0 }
            $vector[$t] = $tfVal * $idfVal
        }
    }

    $norm = 0.0
    foreach ($v in $vector.Values) { $norm += $v * $v }
    $norm = [Math]::Sqrt($norm)
    if ($norm -gt 0) {
        $keysCopy = @($vector.Keys)
        foreach ($t in $keysCopy) { $vector[$t] /= $norm }
    }

    $unmatchedTokens = @($tokens | Where-Object { -not $Vocabulary.ContainsKey($_) })
    return @{
        vector = $vector
        tokens = $tokens
        tokenTf = $tf
        unmatchedTokens = $unmatchedTokens
    }
}

function Compute-QueryCharNgrams {
    param([string]$Query)
    $raw = $Query.ToLower() -replace '[^a-z0-9]', ''
    $ngrams = @{}
    for ($i = 0; $i -le $raw.Length - 3; $i++) {
        $ngrams[$raw.Substring($i, 3)] = $true
    }
    return $ngrams
}

function Compute-CosineSimilarity {
    param(
        [System.Collections.IDictionary]$QueryVector,
        [System.Collections.IDictionary]$SkillVector
    )

    $dot = 0.0
    $shared = 0

    foreach ($kv in $QueryVector.GetEnumerator()) {
        $term = $kv.Key
        $qVal = [double]$kv.Value
        if ($SkillVector.ContainsKey($term)) {
            $dot += $qVal * [double]$SkillVector[$term]
            $shared++
        }
    }

    return @{ similarity = $dot; sharedTerms = $shared }
}

function Compute-JaccardSimilarity {
    param(
        [System.Collections.IDictionary]$QueryNgrams,
        [System.Collections.IDictionary]$SkillNgrams
    )

    if ($QueryNgrams.Count -eq 0) { return 0.0 }

    $intersection = 0
    foreach ($g in $QueryNgrams.Keys) {
        if ($SkillNgrams.ContainsKey($g)) { $intersection++ }
    }

    return [double]$intersection / $QueryNgrams.Count
}

function Get-MatchType {
    param([double]$Score, $Config)
    $confPct = [Math]::Round($Score * 100)

    if ($Config) {
        $tiers = $Config.routingBindings.tiers
        if ($confPct -ge $tiers.tier1_direct.confidenceMin) { return "tier1_direct" }
        if ($confPct -ge $tiers.tier2_confirm.confidenceMin) { return "tier2_confirm" }
        return "tier3_clarify"
    }

    if ($confPct -ge 80) { return "tier1_direct" }
    if ($confPct -ge 60) { return "tier2_confirm" }
    return "tier3_clarify"
}

function Get-ConfidenceLevel {
    param([double]$Score)
    $pct = [Math]::Round($Score * 100)
    if ($pct -ge 80) { return "high" }
    if ($pct -ge 60) { return "medium" }
    return "low"
}

function Resolve-AgentCode {
    param([string]$SkillName, $Config)
    if (-not $Config) { return $null }
    if (-not $Config.skillToAgentProfile) { return $null }

    foreach ($prop in $Config.skillToAgentProfile.PSObject.Properties) {
        if ($prop.Name -eq $SkillName) {
            return "$($prop.Value)"
        }
    }
    return $null
}

function Invoke-SkillMatching {
    param(
        [string]$QueryText,
        [System.Collections.IDictionary]$Embeddings,
        $DelegationConfig
    )

    $queryVectorInfo = Compute-QueryVector -Query $QueryText -Vocabulary $Embeddings.vocabulary -Idf $Embeddings.idf
    $queryNgrams = Compute-QueryCharNgrams $QueryText

    $results = @()
    $uniqueAgents = @{}

    foreach ($skill in $Embeddings.skills) {
        $cosResult = Compute-CosineSimilarity -QueryVector $queryVectorInfo.vector -SkillVector $skill.vector
        $jaccard = Compute-JaccardSimilarity -QueryNgrams $queryNgrams -SkillNgrams $skill.charNgrams

        $cosScore = $cosResult.similarity
        if ($cosScore -lt 0) { $cosScore = 0.0 }
        if ($cosScore -gt 1) { $cosScore = 1.0 }

        $combinedScore = 0.70 * $cosScore + 0.30 * $jaccard

        if ($combinedScore -gt 0.01) {
            $agentFromEmbedding = $skill.agent
            $agentFromConfig = Resolve-AgentCode -SkillName $skill.name -Config $DelegationConfig
            $finalAgent = if ($agentFromConfig) { $agentFromConfig } else { $agentFromEmbedding }

            $results += @{
                skill = $skill.name
                agent = $finalAgent
                score = [Math]::Round($combinedScore, 4)
                cosineScore = [Math]::Round($cosScore, 4)
                jaccardScore = [Math]::Round($jaccard, 4)
                sharedTerms = $cosResult.sharedTerms
                matchType = Get-MatchType -Score $combinedScore -Config $DelegationConfig
                confidence = Get-ConfidenceLevel $combinedScore
                triggers = $skill.triggers
            }
        }
    }

    $sorted = $results | Sort-Object { $_.score } -Descending
    return $sorted
}

if (-not (Ensure-EmbeddingsExist $EmbeddingsPath)) { exit 1 }

Write-Host "Loading embeddings from $EmbeddingsPath ..." -ForegroundColor Cyan
$embeddings = Load-Embeddings $EmbeddingsPath
Write-Host "Loaded $($embeddings.metadata.totalSkills) skills with $($embeddings.metadata.vocabularySize) vocabulary terms" -ForegroundColor Cyan

$delegConfig = Load-DelegationConfig $DelegationConfigPath

Write-Host "Matching query: '$Query'" -ForegroundColor Cyan
$rankedResults = Invoke-SkillMatching -QueryText $Query -Embeddings $embeddings -DelegationConfig $delegConfig

$topMatches = $rankedResults | Select-Object -First $TopN

if ($Raw) {
    $topMatches | ConvertTo-Json -Depth 5
    return
}

$hasResults = $topMatches.Count -gt 0

if (-not $hasResults) {
    Write-Host "No matches found for query: '$Query'" -ForegroundColor Yellow
    $fallback = @(@{
        skill = "sdd-lifecycle"
        agent = "BA"
        score = 0.0
        matchType = "tier3_clarify"
        confidence = "low"
        reason = "No semantic matches found — BA exploration required"
    })
    $fallback | ConvertTo-Json -Depth 5
    return
}

$uniqueAgents = @{}
$top100 = $rankedResults | Select-Object -First 100
foreach ($m in $top100) { $uniqueAgents[$m.agent] = $true }

Write-Host "`nTop $($topMatches.Count) skill matches for: '$Query'" -ForegroundColor Green
Write-Host ("=" * 70)
Write-Host ("{0,-5} {1,-30} {2,-8} {3,-8} {4,-18}" -f "Rank", "Skill", "Agent", "Score", "MatchType")
Write-Host ("-" * 70)

$rank = 1
foreach ($m in $topMatches) {
    $scorePct = [Math]::Round($m.score * 100)
    $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
    Write-Host ("{0,-5} {1,-30} {2,-8} {3,-3}%  {4,-18}" -f $rank, $m.skill, $m.agent, $scorePct, $m.matchType) -ForegroundColor $color
    $rank++
}

Write-Host ""
Write-Host "Agents referenced: $($uniqueAgents.Count)" -ForegroundColor DarkGray
Write-Host "Total candidates scored: $($rankedResults.Count)" -ForegroundColor DarkGray

return $topMatches
