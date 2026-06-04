param(
    [string]$SessionId = "",
    [string]$TurnLabel = "",
    [string]$InputSummary = "",
    [string]$OutputSummary = "",
    [int]$InputTokens = 0,
    [int]$OutputTokens = 0,
    [string]$Domain = "",
    [string]$AgentCode = "",
    [string]$SkillUsed = "",
    [switch]$Silent
)

$ErrorActionPreference = "Continue"

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
$sessionDir = Join-Path $ProjectRoot ".session"

if (-not $SessionId) {
    $sFile = Get-ChildItem (Join-Path $sessionDir "session-*.json") -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($sFile) {
        try { $d = Get-Content $sFile.FullName -Raw | ConvertFrom-Json; $SessionId = $d.sessionId } catch { Write-Debug "Exception caught: param(
    [string]$SessionId = "",
    [string]$TurnLabel = "",
    [string]$InputSummary = "",
    [string]$OutputSummary = "",
    [int]$InputTokens = 0,
    [int]$OutputTokens = 0,
    [string]$Domain = "",
    [string]$AgentCode = "",
    [string]$SkillUsed = "",
    [switch]$Silent
)

$ErrorActionPreference = "Continue"

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
$sessionDir = Join-Path $ProjectRoot ".session"

if (-not $SessionId) {
    $sFile = Get-ChildItem (Join-Path $sessionDir "session-*.json") -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($sFile) {
        try { $d = Get-Content $sFile.FullName -Raw | ConvertFrom-Json; $SessionId = $d.sessionId } catch { Write-Debug "Exception caught: param(
    [string]$SessionId = "",
    [string]$TurnLabel = "",
    [string]$InputSummary = "",
    [string]$OutputSummary = "",
    [int]$InputTokens = 0,
    [int]$OutputTokens = 0,
    [string]$Domain = "",
    [string]$AgentCode = "",
    [string]$SkillUsed = "",
    [switch]$Silent
)

$ErrorActionPreference = "Continue"

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
$sessionDir = Join-Path $ProjectRoot ".session"

if (-not $SessionId) {
    $sFile = Get-ChildItem (Join-Path $sessionDir "session-*.json") -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($sFile) {
        try { $d = Get-Content $sFile.FullName -Raw | ConvertFrom-Json; $SessionId = $d.sessionId } catch { Write-Debug "Exception caught: param(
    [string]$SessionId = "",
    [string]$TurnLabel = "",
    [string]$InputSummary = "",
    [string]$OutputSummary = "",
    [int]$InputTokens = 0,
    [int]$OutputTokens = 0,
    [string]$Domain = "",
    [string]$AgentCode = "",
    [string]$SkillUsed = "",
    [switch]$Silent
)

$ErrorActionPreference = "Continue"

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
$sessionDir = Join-Path $ProjectRoot ".session"

if (-not $SessionId) {
    $sFile = Get-ChildItem (Join-Path $sessionDir "session-*.json") -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($sFile) {
        try { $d = Get-Content $sFile.FullName -Raw | ConvertFrom-Json; $SessionId = $d.sessionId } catch { $SessionId = '' }
    }
    if (-not $SessionId) { $SessionId = "session-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')" }
}

$enrichDir = Join-Path $sessionDir "context-log" $SessionId
$null = New-Item -ItemType Directory -Path $enrichDir -Force

$domain = if ($Domain) { $Domain } else {
    if ($AgentCode -match "BA|SAD|DEV|QA|DOC|OPS|GOV") { $AgentCode }
    else { "DEV" }
}

$entry = @{
    timestamp = (Get-Date -Format "o")
    turnLabel = $TurnLabel
    inputSummary = $InputSummary
    outputSummary = $OutputSummary
    inputTokens = $InputTokens
    outputTokens = $OutputTokens
    domain = $domain
    agentCode = $AgentCode
    skillUsed = $SkillUsed
}

$turnNum = (Get-ChildItem (Join-Path $enrichDir "turn-enriched-*.json") -ErrorAction SilentlyContinue).Count + 1
$outFile = Join-Path $enrichDir "turn-enriched-$("{0:D3}" -f $turnNum).json"
$entry | ConvertTo-Json | Out-File $outFile -Encoding utf8

if (-not $Silent) {
    Write-Host "[SESSION-ENRICH] Saved enriched turn #$turnNum for $SessionId" -ForegroundColor Green
    Write-Host "  Domain: $domain | Agent: $AgentCode | Skill: $SkillUsed"
    Write-Host "  Tokens: $InputTokens in / $OutputTokens out"
    Write-Host "  File: $outFile"
}
" }
    }
    if (-not $SessionId) { $SessionId = "session-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')" }
}

$enrichDir = Join-Path $sessionDir "context-log" $SessionId
$null = New-Item -ItemType Directory -Path $enrichDir -Force

$domain = if ($Domain) { $Domain } else {
    if ($AgentCode -match "BA|SAD|DEV|QA|DOC|OPS|GOV") { $AgentCode }
    else { "DEV" }
}

$entry = @{
    timestamp = (Get-Date -Format "o")
    turnLabel = $TurnLabel
    inputSummary = $InputSummary
    outputSummary = $OutputSummary
    inputTokens = $InputTokens
    outputTokens = $OutputTokens
    domain = $domain
    agentCode = $AgentCode
    skillUsed = $SkillUsed
}

$turnNum = (Get-ChildItem (Join-Path $enrichDir "turn-enriched-*.json") -ErrorAction SilentlyContinue).Count + 1
$outFile = Join-Path $enrichDir "turn-enriched-$("{0:D3}" -f $turnNum).json"
$entry | ConvertTo-Json | Out-File $outFile -Encoding utf8

if (-not $Silent) {
    Write-Host "[SESSION-ENRICH] Saved enriched turn #$turnNum for $SessionId" -ForegroundColor Green
    Write-Host "  Domain: $domain | Agent: $AgentCode | Skill: $SkillUsed"
    Write-Host "  Tokens: $InputTokens in / $OutputTokens out"
    Write-Host "  File: $outFile"
}

" }
    }
    if (-not $SessionId) { $SessionId = "session-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')" }
}

$enrichDir = Join-Path $sessionDir "context-log" $SessionId
$null = New-Item -ItemType Directory -Path $enrichDir -Force

$domain = if ($Domain) { $Domain } else {
    if ($AgentCode -match "BA|SAD|DEV|QA|DOC|OPS|GOV") { $AgentCode }
    else { "DEV" }
}

$entry = @{
    timestamp = (Get-Date -Format "o")
    turnLabel = $TurnLabel
    inputSummary = $InputSummary
    outputSummary = $OutputSummary
    inputTokens = $InputTokens
    outputTokens = $OutputTokens
    domain = $domain
    agentCode = $AgentCode
    skillUsed = $SkillUsed
}

$turnNum = (Get-ChildItem (Join-Path $enrichDir "turn-enriched-*.json") -ErrorAction SilentlyContinue).Count + 1
$outFile = Join-Path $enrichDir "turn-enriched-$("{0:D3}" -f $turnNum).json"
$entry | ConvertTo-Json | Out-File $outFile -Encoding utf8

if (-not $Silent) {
    Write-Host "[SESSION-ENRICH] Saved enriched turn #$turnNum for $SessionId" -ForegroundColor Green
    Write-Host "  Domain: $domain | Agent: $AgentCode | Skill: $SkillUsed"
    Write-Host "  Tokens: $InputTokens in / $OutputTokens out"
    Write-Host "  File: $outFile"
}
" }
    }
    if (-not $SessionId) { $SessionId = "session-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')" }
}

$enrichDir = Join-Path $sessionDir "context-log" $SessionId
$null = New-Item -ItemType Directory -Path $enrichDir -Force

$domain = if ($Domain) { $Domain } else {
    if ($AgentCode -match "BA|SAD|DEV|QA|DOC|OPS|GOV") { $AgentCode }
    else { "DEV" }
}

$entry = @{
    timestamp = (Get-Date -Format "o")
    turnLabel = $TurnLabel
    inputSummary = $InputSummary
    outputSummary = $OutputSummary
    inputTokens = $InputTokens
    outputTokens = $OutputTokens
    domain = $domain
    agentCode = $AgentCode
    skillUsed = $SkillUsed
}

$turnNum = (Get-ChildItem (Join-Path $enrichDir "turn-enriched-*.json") -ErrorAction SilentlyContinue).Count + 1
$outFile = Join-Path $enrichDir "turn-enriched-$("{0:D3}" -f $turnNum).json"
$entry | ConvertTo-Json | Out-File $outFile -Encoding utf8

if (-not $Silent) {
    Write-Host "[SESSION-ENRICH] Saved enriched turn #$turnNum for $SessionId" -ForegroundColor Green
    Write-Host "  Domain: $domain | Agent: $AgentCode | Skill: $SkillUsed"
    Write-Host "  Tokens: $InputTokens in / $OutputTokens out"
    Write-Host "  File: $outFile"
}


