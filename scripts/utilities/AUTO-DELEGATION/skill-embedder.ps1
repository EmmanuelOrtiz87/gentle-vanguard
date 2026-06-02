param(
    [string]$RegistryPath = "",
    [string]$DelegationConfigPath = "",
    [string]$OutputPath = ""
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

if (-not $RegistryPath) { $RegistryPath = Join-Path $ProjectRoot ".atl\skill-registry.md" }
if (-not $DelegationConfigPath) { $DelegationConfigPath = Join-Path $ProjectRoot "config\auto-delegation.json" }
if (-not $OutputPath) { $OutputPath = Join-Path $ProjectRoot ".atl\skill-embeddings.json" }

$StopWords = @('a', 'an', 'the', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or', 'is', 'it', 'as', 'be', 'by', 'with', 'from', 'that', 'this', 'are', 'was', 'were', 'been', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'can', 'could', 'should', 'may', 'might', 'shall', 'not', 'no', 'but', 'if', 'so', 'up', 'out', 'about', 'into', 'over', 'after', 'before', 'between', 'under', 'again', 'further', 'then', 'once', 'also', 'very', 'just', 'each', 'any', 'all', 'both', 'more', 'most', 'some', 'such', 'only', 'own', 'same', 'than', 'too', 'el', 'la', 'los', 'las', 'de', 'del', 'en', 'un', 'una', 'que', 'es', 'se', 'por', 'para', 'con', 'una', 'lo', 'como', 'mas', 'pero', 'sus', 'le', 'ya', 'este', 'entre', 'porque', 'todo', 'esta', 'sin', 'son') | ForEach-Object { $_.ToLower() }
$StopWordsSet = @{}
foreach ($w in $StopWords) { $StopWordsSet[$w] = $true }

function Get-StopWordsSet { return $StopWordsSet }

function Tokenize {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }

    $tokens = @()
    $text = $Text.ToLower()
    $text = $text -replace '[^a-z0-9\s-]', ' '
    $parts = $text -split '[\s-]+' | Where-Object { $_.Length -ge 2 -and $_.Length -le 40 }

    $sw = Get-StopWordsSet
    foreach ($p in $parts) {
        if (-not $sw.ContainsKey($p)) {
            $tokens += $p
        }
    }
    return $tokens
}

function Get-CharNgrams {
    param([string]$Text, [int]$N = 3)
    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }

    $text = $Text.ToLower() -replace '[^a-z0-9]', ''
    $ngrams = @{}
    for ($i = 0; $i -le $text.Length - $N; $i++) {
        $gram = $text.Substring($i, $N)
        $ngrams[$gram] = $true
    }
    return $ngrams.Keys
}

function Parse-SkillRegistry {
    param([string]$Path)
    if (-not (Test-Path $Path)) { Write-Error "Skill registry not found: $Path"; return @{} }

    $content = Get-Content -Path $Path -Raw
    $lines = $content -split "`r`n|`n"

    $skills = [ordered]@{}
    $inMappingTable = $false

    foreach ($line in $lines) {
        if ($line -match '^## Compact Rules') { break }

        if ($line -match '^## Skill-Agent Mapping') {
            $inMappingTable = $true
            continue
        }

        if (-not $inMappingTable) { continue }

        if ($line.TrimStart() -match '^\|') {
            $parts = $line -split '\|' | ForEach-Object { $_.Trim() }
            if ($parts.Count -ge 4) {
                $agentPart = $parts[1]
                $skillPart = $parts[2]
                $triggerPart = $parts[3]

                if ($agentPart -match 'Agent|^-+') { continue }
                if ($skillPart -match 'Skill|^-+' -or [string]::IsNullOrWhiteSpace($skillPart)) { continue }
                if ($triggerPart -match '^-+') { continue }
                if ($skillPart -match '^\d+$') { continue }

                $agentCode = ($agentPart -split '[\s-]')[0]
                if ([string]::IsNullOrWhiteSpace($agentCode)) { continue }

                $triggers = @()
                if (-not [string]::IsNullOrWhiteSpace($triggerPart)) {
                    $triggerList = $triggerPart -split ',' | ForEach-Object {
                        $_.Trim().Trim('"').Trim("'").Trim()
                    } | Where-Object {
                        $_ -ne '' -and $_ -ne '...' -and $_ -ne '...' -and $_ -notmatch '^…\.?$'
                    }
                    $triggers = @($triggerList)
                }

                $skills[$skillPart] = @{
                    agent = $agentCode
                    triggers = $triggers
                }
            }
        }
    }

    return $skills
}

function Get-AgentKeywords {
    param([string]$Path)
    if (-not (Test-Path $Path)) { Write-Warning "Delegation config not found: $Path"; return @{} }

    $configJson = Get-Content -Path $Path -Raw
    $config = $configJson | ConvertFrom-Json

    $keywords = @{}
    $km = $config.keywordMappings
    if (-not $km) { return $keywords }

    foreach ($prop in $km.PSObject.Properties) {
        $agentCode = $prop.Name
        $items = @()
        foreach ($val in $prop.Value) {
            $clean = "$val".Trim('"').Trim("'")
            if (-not [string]::IsNullOrWhiteSpace($clean) -and $clean -notmatch '^(when|for|or|and|after|in|user mentions|if the|when creating|when writing|when working|when using|when building|when a|when you|when orchestrator|when managing|when planning|when adding)') {
                $items += $clean
            }
        }
        if ($items.Count -gt 0) {
            $keywords[$agentCode] = $items
        }
    }

    return $keywords
}

function Add-SkillsFromConfig {
    param(
        [System.Collections.IDictionary]$Skills,
        [string]$DelegationConfigPath
    )

    if (-not (Test-Path $DelegationConfigPath)) { Write-Warning "Config not found: $DelegationConfigPath"; return $Skills }

    $json = Get-Content -Path $DelegationConfigPath -Raw | ConvertFrom-Json
    $result = [ordered]@{}
    foreach ($k in $Skills.Keys) { $result[$k] = $Skills[$k] }

    if ($json.skillToAgentProfile) {
        $added = 0
        foreach ($prop in $json.skillToAgentProfile.PSObject.Properties) {
            $skillName = $prop.Name
            $agentName = "$($prop.Value)"
            if (-not $result.Contains($skillName)) {
                $result[$skillName] = @{
                    agent = $agentName
                    triggers = @()
                }
                $added++
            }
        }
        Write-Host "  Added $added skills from skillToAgentProfile"
    }

    return $result
}

function Build-SkillText {
    param(
        [System.Collections.IDictionary]$Skills,
        [System.Collections.IDictionary]$AgentKeywords
    )

    $result = @{}
    foreach ($skillName in $Skills.Keys) {
        $skill = $Skills[$skillName]
        $baseParts = @()
        $fullParts = @()

        $nameTokens = $skillName -replace '[-_]', ' '
        $baseParts += $nameTokens
        $fullParts += $nameTokens

        foreach ($t in $skill.triggers) {
            if (-not [string]::IsNullOrWhiteSpace($t)) {
                $baseParts += $t
                $fullParts += $t
            }
        }

        $agentCode = $skill.agent
        if ($AgentKeywords.ContainsKey($agentCode)) {
            foreach ($kw in $AgentKeywords[$agentCode]) {
                $fullParts += $kw
            }
        }

        $result[$skillName] = @{
            agent = $agentCode
            text = ($fullParts -join ' ')
            baseText = ($baseParts -join ' ')
            triggers = $skill.triggers
        }
    }

    return $result
}

function Build-Vocabulary {
    param([System.Collections.IDictionary]$SkillTexts)

    $vocab = [ordered]@{}
    $docFreq = @{}
    $allTokens = @()

    foreach ($skillName in $SkillTexts.Keys) {
        $info = $SkillTexts[$skillName]
        $tokens = Tokenize $info.text
        $allTokens += @{$skillName = $tokens}

        $seen = @{}
        foreach ($t in $tokens) {
            if ($null -eq $vocab[$t]) {
                $vocab[$t] = $vocab.Count
            }
            $seen[$t] = $true
        }
        foreach ($t in $seen.Keys) {
            if (-not $docFreq.ContainsKey($t)) { $docFreq[$t] = 0 }
            $docFreq[$t]++
        }
    }

    $N = $SkillTexts.Count
    $idf = @{}
    $vocabSize = $vocab.Count
    $minIdf = [Math]::Log($N)

    foreach ($word in $vocab.Keys) {
        $df = $docFreq[$word]
        if ($df -eq 0) { $df = 1 }
        $idf[$word] = [Math]::Log(($N + 1) / $df) + 1.0
    }

    return @{
        vocabulary = $vocab
        idf = $idf
        allTokens = $allTokens
        vocabSize = $vocabSize
    }
}

function Build-SkillVectors {
    param(
        [System.Collections.IDictionary]$SkillTexts,
        [System.Collections.IDictionary]$Vocabulary,
        [System.Collections.IDictionary]$Idf
    )

    $vectors = @{}
    $charNgrams = @{}

    foreach ($skillName in $SkillTexts.Keys) {
        $info = $SkillTexts[$skillName]
        $tokens = Tokenize $info.text

        $tf = @{}
        foreach ($t in $tokens) {
            if (-not $tf.ContainsKey($t)) { $tf[$t] = 0 }
            $tf[$t]++
        }

        $totalTerms = $tokens.Count
        if ($totalTerms -eq 0) { $totalTerms = 1 }

        $vector = [ordered]@{}
        foreach ($t in $tf.Keys) {
            if ($null -ne $Vocabulary[$t]) {
                $tfVal = [Math]::Log10(1 + $tf[$t] / $totalTerms * 100)
                $idfVal = if ($Idf.ContainsKey($t)) { $Idf[$t] } else { 1.0 }
                $vector[$t] = $tfVal * $idfVal
            }
        }

        $norm = [Math]::Sqrt(($vector.Values | ForEach-Object { $_ * $_ } | Measure-Object -Sum).Sum)
        if ($norm -gt 0) {
            $keysCopy = @($vector.Keys)
            foreach ($t in $keysCopy) { $vector[$t] /= $norm }
        }

        $vectors[$skillName] = @{
            agent = $info.agent
            vector = $vector
            triggers = $info.triggers
        }

        $ngramSrc = if ($info.baseText) { $info.baseText } else { $info.text }
        $rawText = $ngramSrc -replace '[^a-zA-Z0-9]', ''
        $ngrams = @{}
        for ($i = 0; $i -le $rawText.Length - 3; $i++) {
            $ngrams[$rawText.Substring($i, 3)] = $true
        }
        $charNgrams[$skillName] = @{
            agent = $info.agent
            ngrams = $ngrams
        }
    }

    return @{ vectors = $vectors; charNgrams = $charNgrams }
}

function Save-Embeddings {
    param(
        [System.Collections.IDictionary]$Vectors,
        [System.Collections.IDictionary]$CharNgrams,
        [System.Collections.IDictionary]$Vocabulary,
        [System.Collections.IDictionary]$Idf,
        [string]$OutputPath
    )

    $outputDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

    $vocabList = @()
    foreach ($w in $Vocabulary.Keys) { $vocabList += $w }

    $idfList = @{}
    foreach ($w in $Idf.Keys) { $idfList[$w] = [Math]::Round($Idf[$w], 4) }

    $skillsOut = @()
    foreach ($skillName in $Vectors.Keys) {
        $v = $Vectors[$skillName]
        $vecObj = @{}
        foreach ($kv in $v.vector.Keys) {
            $vecObj[$kv] = [Math]::Round($v.vector[$kv], 6)
        }

        $charN = $CharNgrams[$skillName]
        $ngramArr = @($charN.ngrams.Keys)

        $skillsOut += @{
            name = $skillName
            agent = $v.agent
            triggers = @($v.triggers)
            vector = $vecObj
            charNgrams = $ngramArr
        }
    }

    $embeddings = @{
        version = "1.0"
        generated = (Get-Date -Format "o")
        metadata = @{
            totalSkills = $skillsOut.Count
            vocabularySize = $vocabList.Count
            ngramSize = 3
        }
        vocabulary = $vocabList
        idf = $idfList
        skills = $skillsOut
    }

    $json = $embeddings | ConvertTo-Json -Depth 10
    Set-Content -Path $OutputPath -Value $json -Encoding UTF8
    Write-Host "Embeddings saved to $OutputPath ($($skillsOut.Count) skills, $($vocabList.Count) vocabulary terms)"
}

Write-Host "=== Skill Embedding Generator ==="

if (-not (Test-Path $RegistryPath)) { Write-Error "Registry not found: $RegistryPath"; exit 1 }

Write-Host "Parsing skill registry: $RegistryPath"
$skills = Parse-SkillRegistry $RegistryPath
Write-Host "Found $($skills.Count) skills from registry"

Write-Host "Supplementing missing skills from auto-delegation config..."
$supplemented = Add-SkillsFromConfig -Skills $skills -DelegationConfigPath $DelegationConfigPath
Write-Host "Total skills after supplement: $($supplemented.Count)"

Write-Host "Loading agent keywords from: $DelegationConfigPath"
$agentKeywords = Get-AgentKeywords $DelegationConfigPath
Write-Host "Loaded keywords for $($agentKeywords.Count) agents"

Write-Host "Building text corpus..."
$skillTexts = Build-SkillText -Skills $supplemented -AgentKeywords $agentKeywords

Write-Host "Building vocabulary..."
$vocabResult = Build-Vocabulary -SkillTexts $skillTexts
Write-Host "Vocabulary: $($vocabResult.vocabSize) terms"

Write-Host "Building vectors..."
$vectorResult = Build-SkillVectors -SkillTexts $skillTexts -Vocabulary $vocabResult.vocabulary -Idf $vocabResult.idf

Write-Host "Saving embeddings..."
Save-Embeddings -Vectors $vectorResult.vectors -CharNgrams $vectorResult.charNgrams -Vocabulary $vocabResult.vocabulary -Idf $vocabResult.idf -OutputPath $OutputPath

Write-Host "Done"
