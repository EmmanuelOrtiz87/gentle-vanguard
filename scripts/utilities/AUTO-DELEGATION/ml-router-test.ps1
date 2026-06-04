param(
    [Parameter(Mandatory = $true)]
    [string]$Query,
    [int]$TopN = 3,
    [switch]$Json,
    [switch]$Details
)

$ErrorActionPreference = "Stop"

$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
if (-not (Test-Path $RouterPath)) {
    Write-Error "ml-router.ps1 not found at $RouterPath"
    exit 1
}

function Write-Separator { Write-Host ("=" * 70) -ForegroundColor DarkGray }
function Write-SubSeparator { Write-Host ("-" * 70) -ForegroundColor DarkGray }

Write-Host @"

  __  __ _      _          _   _      _
 |  \/  | |    | |        | \ | |    (_)
 | \  / | |    | | ___   _|  \| | ___ _ _ __ ___
 | |\/| | |    | |/ / | | | . ` |/ _ \ | '__/ _ \
 | |  | | |____|   <| |_| | |\  |  __/ | | |  __/
 |_|  |_|______|_|\_\\__,_|_| \_|\___|_|_|  \___|

 ML Router Test — Embedding-Based Skill Matching
"@ -ForegroundColor Magenta

Write-Host "Query:       " -NoNewline; Write-Host "'$Query'" -ForegroundColor Cyan
Write-Host "Top-N:       " -NoNewline; Write-Host "$TopN" -ForegroundColor Cyan
Write-Host "Details:     " -NoNewline; Write-Host "$Details" -ForegroundColor Cyan
Write-Host ""

$timer = [System.Diagnostics.Stopwatch]::StartNew()

$routerArgs = @{
    Query = $Query
    TopN = $TopN
    Raw = $true
}

if ($Details) { $routerArgs.Details = $true }

$matches = & $RouterPath @routerArgs 2>&1

$timer.Stop()

$infoLines = @()
$resultLines = @()
foreach ($line in $matches) {
    if ($line -is [string]) {
        $infoLines += $line
    } else {
        $resultLines += $line
    }
}

$infoText = $infoLines -join "`n"

$colorMap = @{
    "tier1_direct" = "Green"
    "tier2_confirm" = "Yellow"
    "tier3_clarify" = "DarkYellow"
}

$parsedResults = @()
foreach ($r in $resultLines) {
    if ($r -is [System.Management.Automation.PSObject] -or $r -is [Hashtable]) {
        $parsedResults += $r
    }
}

if ($parsedResults.Count -eq 0) {
    try { $parsedResults = $infoText | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Debug "Exception caught: param(
    [Parameter(Mandatory = $true)]
    [string]$Query,
    [int]$TopN = 3,
    [switch]$Json,
    [switch]$Details
)

$ErrorActionPreference = "Stop"

$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
if (-not (Test-Path $RouterPath)) {
    Write-Error "ml-router.ps1 not found at $RouterPath"
    exit 1
}

function Write-Separator { Write-Host ("=" * 70) -ForegroundColor DarkGray }
function Write-SubSeparator { Write-Host ("-" * 70) -ForegroundColor DarkGray }

Write-Host @"

  __  __ _      _          _   _      _
 |  \/  | |    | |        | \ | |    (_)
 | \  / | |    | | ___   _|  \| | ___ _ _ __ ___
 | |\/| | |    | |/ / | | | . ` |/ _ \ | '__/ _ \
 | |  | | |____|   <| |_| | |\  |  __/ | | |  __/
 |_|  |_|______|_|\_\\__,_|_| \_|\___|_|_|  \___|

 ML Router Test — Embedding-Based Skill Matching
"@ -ForegroundColor Magenta

Write-Host "Query:       " -NoNewline; Write-Host "'$Query'" -ForegroundColor Cyan
Write-Host "Top-N:       " -NoNewline; Write-Host "$TopN" -ForegroundColor Cyan
Write-Host "Details:     " -NoNewline; Write-Host "$Details" -ForegroundColor Cyan
Write-Host ""

$timer = [System.Diagnostics.Stopwatch]::StartNew()

$routerArgs = @{
    Query = $Query
    TopN = $TopN
    Raw = $true
}

if ($Details) { $routerArgs.Details = $true }

$matches = & $RouterPath @routerArgs 2>&1

$timer.Stop()

$infoLines = @()
$resultLines = @()
foreach ($line in $matches) {
    if ($line -is [string]) {
        $infoLines += $line
    } else {
        $resultLines += $line
    }
}

$infoText = $infoLines -join "`n"

$colorMap = @{
    "tier1_direct" = "Green"
    "tier2_confirm" = "Yellow"
    "tier3_clarify" = "DarkYellow"
}

$parsedResults = @()
foreach ($r in $resultLines) {
    if ($r -is [System.Management.Automation.PSObject] -or $r -is [Hashtable]) {
        $parsedResults += $r
    }
}

if ($parsedResults.Count -eq 0) {
    try { $parsedResults = $infoText | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Debug "Exception caught: param(
    [Parameter(Mandatory = $true)]
    [string]$Query,
    [int]$TopN = 3,
    [switch]$Json,
    [switch]$Details
)

$ErrorActionPreference = "Stop"

$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
if (-not (Test-Path $RouterPath)) {
    Write-Error "ml-router.ps1 not found at $RouterPath"
    exit 1
}

function Write-Separator { Write-Host ("=" * 70) -ForegroundColor DarkGray }
function Write-SubSeparator { Write-Host ("-" * 70) -ForegroundColor DarkGray }

Write-Host @"

  __  __ _      _          _   _      _
 |  \/  | |    | |        | \ | |    (_)
 | \  / | |    | | ___   _|  \| | ___ _ _ __ ___
 | |\/| | |    | |/ / | | | . ` |/ _ \ | '__/ _ \
 | |  | | |____|   <| |_| | |\  |  __/ | | |  __/
 |_|  |_|______|_|\_\\__,_|_| \_|\___|_|_|  \___|

 ML Router Test — Embedding-Based Skill Matching
"@ -ForegroundColor Magenta

Write-Host "Query:       " -NoNewline; Write-Host "'$Query'" -ForegroundColor Cyan
Write-Host "Top-N:       " -NoNewline; Write-Host "$TopN" -ForegroundColor Cyan
Write-Host "Details:     " -NoNewline; Write-Host "$Details" -ForegroundColor Cyan
Write-Host ""

$timer = [System.Diagnostics.Stopwatch]::StartNew()

$routerArgs = @{
    Query = $Query
    TopN = $TopN
    Raw = $true
}

if ($Details) { $routerArgs.Details = $true }

$matches = & $RouterPath @routerArgs 2>&1

$timer.Stop()

$infoLines = @()
$resultLines = @()
foreach ($line in $matches) {
    if ($line -is [string]) {
        $infoLines += $line
    } else {
        $resultLines += $line
    }
}

$infoText = $infoLines -join "`n"

$colorMap = @{
    "tier1_direct" = "Green"
    "tier2_confirm" = "Yellow"
    "tier3_clarify" = "DarkYellow"
}

$parsedResults = @()
foreach ($r in $resultLines) {
    if ($r -is [System.Management.Automation.PSObject] -or $r -is [Hashtable]) {
        $parsedResults += $r
    }
}

if ($parsedResults.Count -eq 0) {
    try { $parsedResults = $infoText | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Debug "Exception caught: param(
    [Parameter(Mandatory = $true)]
    [string]$Query,
    [int]$TopN = 3,
    [switch]$Json,
    [switch]$Details
)

$ErrorActionPreference = "Stop"

$RouterPath = Join-Path $PSScriptRoot "ml-router.ps1"
if (-not (Test-Path $RouterPath)) {
    Write-Error "ml-router.ps1 not found at $RouterPath"
    exit 1
}

function Write-Separator { Write-Host ("=" * 70) -ForegroundColor DarkGray }
function Write-SubSeparator { Write-Host ("-" * 70) -ForegroundColor DarkGray }

Write-Host @"

  __  __ _      _          _   _      _
 |  \/  | |    | |        | \ | |    (_)
 | \  / | |    | | ___   _|  \| | ___ _ _ __ ___
 | |\/| | |    | |/ / | | | . ` |/ _ \ | '__/ _ \
 | |  | | |____|   <| |_| | |\  |  __/ | | |  __/
 |_|  |_|______|_|\_\\__,_|_| \_|\___|_|_|  \___|

 ML Router Test — Embedding-Based Skill Matching
"@ -ForegroundColor Magenta

Write-Host "Query:       " -NoNewline; Write-Host "'$Query'" -ForegroundColor Cyan
Write-Host "Top-N:       " -NoNewline; Write-Host "$TopN" -ForegroundColor Cyan
Write-Host "Details:     " -NoNewline; Write-Host "$Details" -ForegroundColor Cyan
Write-Host ""

$timer = [System.Diagnostics.Stopwatch]::StartNew()

$routerArgs = @{
    Query = $Query
    TopN = $TopN
    Raw = $true
}

if ($Details) { $routerArgs.Details = $true }

$matches = & $RouterPath @routerArgs 2>&1

$timer.Stop()

$infoLines = @()
$resultLines = @()
foreach ($line in $matches) {
    if ($line -is [string]) {
        $infoLines += $line
    } else {
        $resultLines += $line
    }
}

$infoText = $infoLines -join "`n"

$colorMap = @{
    "tier1_direct" = "Green"
    "tier2_confirm" = "Yellow"
    "tier3_clarify" = "DarkYellow"
}

$parsedResults = @()
foreach ($r in $resultLines) {
    if ($r -is [System.Management.Automation.PSObject] -or $r -is [Hashtable]) {
        $parsedResults += $r
    }
}

if ($parsedResults.Count -eq 0) {
    try { $parsedResults = $infoText | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Output "[ML-ROUTER] Operation failed, continuing" }
}

if ($Json) {
    if ($parsedResults.Count -gt 0) {
        $parsedResults | Select-Object -First $TopN | ForEach-Object { $_ } | ConvertTo-Json -Depth 5
    } else {
        @($infoLines[-1]) | ConvertFrom-Json -ErrorAction SilentlyContinue | ConvertTo-Json -Depth 5
    }
    return
}

Write-Separator
Write-Host "Matching Results" -ForegroundColor Cyan
Write-SubSeparator
Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-18} {5,-10} {6,-10}" -f "Rank", "Skill", "Agent", "Score", "MatchType", "Cosine", "Jaccard")
Write-SubSeparator

$rank = 1
foreach ($r in $parsedResults) {
    $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
    $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
    $mt = if ($r.matchType) { $r.matchType } else { "tier3_clarify" }
    $cos = if ($r.cosineScore) { [Math]::Round($r.cosineScore, 3) } else { "-" }
    $jac = if ($r.jaccardScore) { [Math]::Round($r.jaccardScore, 3) } else { "-" }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-18} {5,-10} {6,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $mt, $cos, $jac) -ForegroundColor $color
    $rank++
}

Write-SubSeparator
Write-Host "Response time: $($timer.Elapsed.TotalMilliseconds.ToString('F1'))ms" -ForegroundColor DarkGray

$uniqueAgents = @($parsedResults | ForEach-Object { $_.agent } | Select-Object -Unique)
if ($uniqueAgents.Count -gt 0) {
    Write-Host "Agents:        " -NoNewline; Write-Host ($uniqueAgents -join ", ") -ForegroundColor DarkGray
}

$firstScore = if ($parsedResults.Count -gt 0 -and $parsedResults[0].score) { $parsedResults[0].score } else { 0 }
$firstMt = if ($parsedResults.Count -gt 0 -and $parsedResults[0].matchType) { $parsedResults[0].matchType } else { "unknown" }

if ($firstScore -ge 0.8) {
    Write-Host "Routing:       " -NoNewline
    Write-Host "tier1_direct (dispatch immediately)" -ForegroundColor Green
} elseif ($firstScore -ge 0.6) {
    Write-Host "Routing:       " -NoNewline
    Write-Host "tier2_confirm (dispatch with summary)" -ForegroundColor Yellow
} else {
    Write-Host "Routing:       " -NoNewline
    Write-Host "tier3_clarify (activate BA exploration)" -ForegroundColor DarkYellow
}

Write-Separator
" }
}

if ($Json) {
    if ($parsedResults.Count -gt 0) {
        $parsedResults | Select-Object -First $TopN | ForEach-Object { $_ } | ConvertTo-Json -Depth 5
    } else {
        @($infoLines[-1]) | ConvertFrom-Json -ErrorAction SilentlyContinue | ConvertTo-Json -Depth 5
    }
    return
}

Write-Separator
Write-Host "Matching Results" -ForegroundColor Cyan
Write-SubSeparator
Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-18} {5,-10} {6,-10}" -f "Rank", "Skill", "Agent", "Score", "MatchType", "Cosine", "Jaccard")
Write-SubSeparator

$rank = 1
foreach ($r in $parsedResults) {
    $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
    $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
    $mt = if ($r.matchType) { $r.matchType } else { "tier3_clarify" }
    $cos = if ($r.cosineScore) { [Math]::Round($r.cosineScore, 3) } else { "-" }
    $jac = if ($r.jaccardScore) { [Math]::Round($r.jaccardScore, 3) } else { "-" }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-18} {5,-10} {6,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $mt, $cos, $jac) -ForegroundColor $color
    $rank++
}

Write-SubSeparator
Write-Host "Response time: $($timer.Elapsed.TotalMilliseconds.ToString('F1'))ms" -ForegroundColor DarkGray

$uniqueAgents = @($parsedResults | ForEach-Object { $_.agent } | Select-Object -Unique)
if ($uniqueAgents.Count -gt 0) {
    Write-Host "Agents:        " -NoNewline; Write-Host ($uniqueAgents -join ", ") -ForegroundColor DarkGray
}

$firstScore = if ($parsedResults.Count -gt 0 -and $parsedResults[0].score) { $parsedResults[0].score } else { 0 }
$firstMt = if ($parsedResults.Count -gt 0 -and $parsedResults[0].matchType) { $parsedResults[0].matchType } else { "unknown" }

if ($firstScore -ge 0.8) {
    Write-Host "Routing:       " -NoNewline
    Write-Host "tier1_direct (dispatch immediately)" -ForegroundColor Green
} elseif ($firstScore -ge 0.6) {
    Write-Host "Routing:       " -NoNewline
    Write-Host "tier2_confirm (dispatch with summary)" -ForegroundColor Yellow
} else {
    Write-Host "Routing:       " -NoNewline
    Write-Host "tier3_clarify (activate BA exploration)" -ForegroundColor DarkYellow
}

Write-Separator

" }
}

if ($Json) {
    if ($parsedResults.Count -gt 0) {
        $parsedResults | Select-Object -First $TopN | ForEach-Object { $_ } | ConvertTo-Json -Depth 5
    } else {
        @($infoLines[-1]) | ConvertFrom-Json -ErrorAction SilentlyContinue | ConvertTo-Json -Depth 5
    }
    return
}

Write-Separator
Write-Host "Matching Results" -ForegroundColor Cyan
Write-SubSeparator
Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-18} {5,-10} {6,-10}" -f "Rank", "Skill", "Agent", "Score", "MatchType", "Cosine", "Jaccard")
Write-SubSeparator

$rank = 1
foreach ($r in $parsedResults) {
    $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
    $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
    $mt = if ($r.matchType) { $r.matchType } else { "tier3_clarify" }
    $cos = if ($r.cosineScore) { [Math]::Round($r.cosineScore, 3) } else { "-" }
    $jac = if ($r.jaccardScore) { [Math]::Round($r.jaccardScore, 3) } else { "-" }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-18} {5,-10} {6,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $mt, $cos, $jac) -ForegroundColor $color
    $rank++
}

Write-SubSeparator
Write-Host "Response time: $($timer.Elapsed.TotalMilliseconds.ToString('F1'))ms" -ForegroundColor DarkGray

$uniqueAgents = @($parsedResults | ForEach-Object { $_.agent } | Select-Object -Unique)
if ($uniqueAgents.Count -gt 0) {
    Write-Host "Agents:        " -NoNewline; Write-Host ($uniqueAgents -join ", ") -ForegroundColor DarkGray
}

$firstScore = if ($parsedResults.Count -gt 0 -and $parsedResults[0].score) { $parsedResults[0].score } else { 0 }
$firstMt = if ($parsedResults.Count -gt 0 -and $parsedResults[0].matchType) { $parsedResults[0].matchType } else { "unknown" }

if ($firstScore -ge 0.8) {
    Write-Host "Routing:       " -NoNewline
    Write-Host "tier1_direct (dispatch immediately)" -ForegroundColor Green
} elseif ($firstScore -ge 0.6) {
    Write-Host "Routing:       " -NoNewline
    Write-Host "tier2_confirm (dispatch with summary)" -ForegroundColor Yellow
} else {
    Write-Host "Routing:       " -NoNewline
    Write-Host "tier3_clarify (activate BA exploration)" -ForegroundColor DarkYellow
}

Write-Separator
" }
}

if ($Json) {
    if ($parsedResults.Count -gt 0) {
        $parsedResults | Select-Object -First $TopN | ForEach-Object { $_ } | ConvertTo-Json -Depth 5
    } else {
        @($infoLines[-1]) | ConvertFrom-Json -ErrorAction SilentlyContinue | ConvertTo-Json -Depth 5
    }
    return
}

Write-Separator
Write-Host "Matching Results" -ForegroundColor Cyan
Write-SubSeparator
Write-Host ("{0,-5} {1,-32} {2,-8} {3,-8} {4,-18} {5,-10} {6,-10}" -f "Rank", "Skill", "Agent", "Score", "MatchType", "Cosine", "Jaccard")
Write-SubSeparator

$rank = 1
foreach ($r in $parsedResults) {
    $scorePct = if ($r.score) { [Math]::Round($r.score * 100) } else { 0 }
    $color = if ($scorePct -ge 80) { "Green" } elseif ($scorePct -ge 60) { "Yellow" } else { "DarkYellow" }
    $mt = if ($r.matchType) { $r.matchType } else { "tier3_clarify" }
    $cos = if ($r.cosineScore) { [Math]::Round($r.cosineScore, 3) } else { "-" }
    $jac = if ($r.jaccardScore) { [Math]::Round($r.jaccardScore, 3) } else { "-" }

    Write-Host ("{0,-5} {1,-32} {2,-8} {3,-3}%  {4,-18} {5,-10} {6,-10}" -f $rank, $r.skill, $r.agent, $scorePct, $mt, $cos, $jac) -ForegroundColor $color
    $rank++
}

Write-SubSeparator
Write-Host "Response time: $($timer.Elapsed.TotalMilliseconds.ToString('F1'))ms" -ForegroundColor DarkGray

$uniqueAgents = @($parsedResults | ForEach-Object { $_.agent } | Select-Object -Unique)
if ($uniqueAgents.Count -gt 0) {
    Write-Host "Agents:        " -NoNewline; Write-Host ($uniqueAgents -join ", ") -ForegroundColor DarkGray
}

$firstScore = if ($parsedResults.Count -gt 0 -and $parsedResults[0].score) { $parsedResults[0].score } else { 0 }
$firstMt = if ($parsedResults.Count -gt 0 -and $parsedResults[0].matchType) { $parsedResults[0].matchType } else { "unknown" }

if ($firstScore -ge 0.8) {
    Write-Host "Routing:       " -NoNewline
    Write-Host "tier1_direct (dispatch immediately)" -ForegroundColor Green
} elseif ($firstScore -ge 0.6) {
    Write-Host "Routing:       " -NoNewline
    Write-Host "tier2_confirm (dispatch with summary)" -ForegroundColor Yellow
} else {
    Write-Host "Routing:       " -NoNewline
    Write-Host "tier3_clarify (activate BA exploration)" -ForegroundColor DarkYellow
}

Write-Separator


