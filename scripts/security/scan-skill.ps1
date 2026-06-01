param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [ValidateSet('terminal', 'json', 'markdown', 'sarif')]
    [string]$Format = 'json',
    [string]$OutputPath,
    [switch]$NoLLM = $true,
    [int]$ThresholdScore = 50,
    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'
$SkillspectorDir = Join-Path $PSScriptRoot '..\..\.tmp\skillspector'

if (-not (Test-Path $SkillspectorDir)) {
    Write-Error "skillspector not found at $SkillspectorDir. Run setup first."
    exit 1
}

$resolvedPath = Resolve-Path $Path -ErrorAction Stop
$pythonExe = "$SkillspectorDir\.venv\Scripts\python.exe"
$outputArgs = if ($OutputPath) { "--output", $OutputPath } else { @() }

& $pythonExe -m skillspector.cli scan $resolvedPath --format $Format --no-llm @outputArgs 2>&1 | Out-Null

if ($Format -ne 'json') { return }

if ($OutputPath -and (Test-Path $OutputPath)) {
    $jsonText = Get-Content $OutputPath -Raw
} else {
    $jsonText = & $pythonExe -m skillspector.cli scan $resolvedPath --format json --no-llm 2>$null | Out-String
}

if ($jsonText -notmatch '"risk_assessment"') { return }

$result = $jsonText | ConvertFrom-Json
$score = $result.risk_assessment.score
$severity = $result.risk_assessment.severity
$recommendation = $result.risk_assessment.recommendation
$issueCount = ($result.issues | Measure-Object).Count
$status = if ($score -ge $ThresholdScore) { "FAIL" } else { "PASS" }

$summary = [PSCustomObject]@{
    Status         = $status
    Score          = $score
    Severity       = $severity
    Recommendation = $recommendation
    IssueCount     = $issueCount
    Issues         = $result.issues
    Path           = $resolvedPath
}

if ($PassThru) { return $summary }

Write-Host "[$status] Risk Score: $score/100 ($severity) — $recommendation — $issueCount issues"
foreach ($issue in $result.issues) {
    Write-Host "  • [$($issue.severity)] $($issue.category): $($issue.finding) (L$($issue.location.start_line))"
}
