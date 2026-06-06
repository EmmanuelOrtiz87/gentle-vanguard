param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Debug "Exception caught: param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Debug "Exception caught: param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Debug "Exception caught: param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}
" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Debug "Exception caught: param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}
" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}

" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Debug "Exception caught: param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Debug "Exception caught: param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}
" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Debug "Exception caught: param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}
" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}

" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}
" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Debug "Exception caught: param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Debug "Exception caught: param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Debug "Exception caught: param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}
" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Debug "Exception caught: param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}
" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}

" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Debug "Exception caught: param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Debug "Exception caught: param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}
" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Debug "Exception caught: param(
    [string]$Context = "",
    [string]$TaskDescription = "",
    [int]$TopN = 5,
    [switch]$Raw,
    [switch]$Proactive
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
$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
$AnalyzerPath = Join-Path $PSScriptRoot "context-analyzer.ps1"

function Get-WorkspaceContext {
    if (-not (Test-Path $AnalyzerPath)) { return "" }
    try {
        $result = & $AnalyzerPath -Raw 2>$null | ConvertFrom-Json
        if ($result -and $result.contextText) { return $result.contextText }
    } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    return ""
}

function Invoke-SkillRecommendation {
    param([string]$QueryText)

    if (-not (Test-Path $RouterPath)) {
        Write-Error "ML router not found at $RouterPath"
        return @()
    }

    $matches = & $RouterPath -Query $QueryText -TopN ($TopN * 2) -Raw 2>$null
    $parsed = @()
    foreach ($m in $matches) {
        if ($m -is [System.Management.Automation.PSObject] -or $m -is [Hashtable]) {
            $parsed += $m
        }
    }
    if ($parsed.Count -eq 0) {
        try { $parsed = $matches | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Output "[AUTO-DELEGATION] Operation failed, continuing" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}
" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}

" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}
" }
    }
    return $parsed
}

function Get-ContextKeywords {
    param([string]$ContextText)
    $keywords = @{}
    $parts = $ContextText -split '\s*\|\s*'
    foreach ($part in $parts) {
        $clean = $part -replace '^(branch:|modified:|staged:|commit:|active:)\s*', ''
        $clean = $clean -replace '[/\\]', ' '
        $clean = $clean -replace '[_-]', ' '
        $words = $clean -split '\s+' | Where-Object { $_.Length -gt 1 }
        foreach ($w in $words) {
            $lower = $w.ToLower()
            if (-not $keywords.ContainsKey($lower)) { $keywords[$lower] = 0 }
            $keywords[$lower]++
        }
    }
    return $keywords
}

function Get-BranchSkillHint {
    param([string]$Branch)
    if ([string]::IsNullOrWhiteSpace($Branch)) { return "" }
    $branchLower = $Branch.ToLower()
    $hints = @()
    if ($branchLower -match 'feature') { $hints += "new feature development" }
    if ($branchLower -match 'bug|fix|hotfix') { $hints += "bug fixing debugging" }
    if ($branchLower -match 'release') { $hints += "release management deployment" }
    if ($branchLower -match 'docs?|readme') { $hints += "documentation writing" }
    if ($branchLower -match 'refactor') { $hints += "refactoring code quality" }
    if ($branchLower -match 'test') { $hints += "testing quality assurance" }
    if ($branchLower -match 'sec|security') { $hints += "security audit review" }
    if ($branchLower -match 'deps?|update') { $hints += "dependency update maintenance" }
    return ($hints -join " ")
}

try {
    $queryParts = @()

    if ([string]::IsNullOrWhiteSpace($Context)) {
        $Context = Get-WorkspaceContext
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        $queryParts += $Context
    }

    if (-not [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $queryParts += $TaskDescription
    }

    if ($Proactive -or [string]::IsNullOrWhiteSpace($TaskDescription)) {
        $branchHint = Get-BranchSkillHint (git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
        if ($branchHint) { $queryParts += $branchHint }
    }

    if ($queryParts.Count -eq 0) {
        Write-Host "No context available for skill recommendation" -ForegroundColor Yellow
        return @()
    }

    $combinedQuery = ($queryParts | Where-Object { $_ }) -join " "

    $recommendations = Invoke-SkillRecommendation -QueryText $combinedQuery

    $top = $recommendations | Select-Object -First $TopN

    if ($Raw) {
        $top | ConvertTo-Json -Depth 5
        return
    }

    Write-Host "=== Skill Recommendations ===" -ForegroundColor Cyan
    if ($Proactive) { Write-Host "[Proactive Mode]" -ForegroundColor Magenta }
    Write-Host "Query: '$($combinedQuery.Substring(0, [Math]::Min(80, $combinedQuery.Length)))...'" -ForegroundColor DarkGray
    Write-Host ("-" * 70)

    if ($top.Count -eq 0) {
        Write-Host "No relevant skills found for current context." -ForegroundColor Yellow
        return
    }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-10}" -f "Rank", "Skill", "Agent", "Score", "Confidence")
    Write-Host ("-" * 70)

    $rank = 1
    foreach ($r in $top) {
        $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
        $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
        $conf = if ($r.confidence) { $r.confidence } else { "low" }
        Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $conf) -ForegroundColor $color
        $rank++
    }

    Write-Host ("-" * 70) -ForegroundColor DarkGray

    return $top
}
catch {
    Write-Error "Skill recommendation failed: $_"
    return @()
}


