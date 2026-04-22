param(
    [int]$TasksPerMonth = 20,
    [int]$BaselineTokensPerTask = 14000,
    [double]$BaseReductionPercent = 30,
    [switch]$AsJson,
    [switch]$AsCsv,
    [switch]$PassThru,
    [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

if ($TasksPerMonth -le 0 -or $BaselineTokensPerTask -le 0) {
    throw 'TasksPerMonth and BaselineTokensPerTask must be greater than zero.'
}

if ($BaseReductionPercent -lt 0 -or $BaseReductionPercent -gt 100) {
    throw 'BaseReductionPercent must be between 0 and 100.'
}

$languages = @('es', 'pt-BR', 'en')
$details = @('simple', 'executive', 'expanded')
$profiles = @('lite', 'lleno', 'ultra')

# Multipliers are intentionally conservative and configurable in script.
$detailMultiplier = @{
    simple = 1.15
    executive = 1.00
    expanded = 0.80
}

$profileMultiplier = @{
    lite = 1.00
    lleno = 1.15
    ultra = 1.30
}

$languageMultiplier = @{
    es = 1.00
    'pt-BR' = 0.99
    en = 0.98
}

$rows = @()
foreach ($language in $languages) {
    foreach ($detail in $details) {
        foreach ($profile in $profiles) {
            $effectiveReduction = $BaseReductionPercent * $detailMultiplier[$detail] * $profileMultiplier[$profile] * $languageMultiplier[$language]

            if ($effectiveReduction -gt 85) { $effectiveReduction = 85 }
            if ($effectiveReduction -lt 5) { $effectiveReduction = 5 }

            $effectiveReduction = [math]::Round($effectiveReduction, 2)
            $optimizedTokensPerTask = [math]::Round($BaselineTokensPerTask * (1 - ($effectiveReduction / 100)), 0)
            $monthlyTokenSavings = ($BaselineTokensPerTask - $optimizedTokensPerTask) * $TasksPerMonth
            $yearlyTokenSavings = $monthlyTokenSavings * 12

            $rows += [pscustomobject]@{
                language = $language
                detail = $detail
                profile = $profile
                baseReductionPercent = [math]::Round($BaseReductionPercent, 2)
                effectiveReductionPercent = $effectiveReduction
                baselineTokensPerTask = $BaselineTokensPerTask
                optimizedTokensPerTask = $optimizedTokensPerTask
                monthlyTokenSavings = $monthlyTokenSavings
                yearlyTokenSavings = $yearlyTokenSavings
            }
        }
    }
}

$rows = @(
    $rows |
        Sort-Object @{Expression = 'effectiveReductionPercent'; Descending = $true}, language, detail, profile
)

if ($AsJson) {
    $json = $rows | ConvertTo-Json -Depth 6
    if ($PassThru) {
        Write-Output $json
    }
    else {
        Write-Host $json
    }

    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        Set-Content -Path $OutputPath -Value $json -Encoding UTF8
        Write-Host "[OK] Matrix saved to: $OutputPath" -ForegroundColor Green
    }
    exit 0
}

if ($AsCsv) {
    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $OutputPath = Join-Path $repoRoot ('docs/sessions/{0}-response-mode-efficiency-matrix.csv' -f (Get-Date -Format 'yyyy-MM-dd-HHmmss'))
    }

    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    $rows | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "[OK] Matrix saved to: $OutputPath" -ForegroundColor Green

    if ($PassThru) {
        Write-Output $OutputPath
    }
    exit 0
}

$top = $rows | Select-Object -First 9
$bottom = $rows | Select-Object -Last 3

Write-Host 'Response Mode Efficiency Matrix' -ForegroundColor Cyan
Write-Host "Baseline: tasks/month=$TasksPerMonth, tokens/task=$BaselineTokensPerTask, base-reduction=$BaseReductionPercent%" -ForegroundColor White
Write-Host ''
Write-Host 'Top combinations by estimated reduction:' -ForegroundColor Yellow
$top | Format-Table language, detail, profile, effectiveReductionPercent, optimizedTokensPerTask, monthlyTokenSavings -AutoSize

Write-Host ''
Write-Host 'Lowest combinations by estimated reduction:' -ForegroundColor Yellow
$bottom | Format-Table language, detail, profile, effectiveReductionPercent, optimizedTokensPerTask, monthlyTokenSavings -AutoSize

if ($PassThru) {
    Write-Output ($rows | ConvertTo-Json -Depth 6)
}
