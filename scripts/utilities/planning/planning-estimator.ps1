#Requires -Version 7.0
<#
.SYNOPSIS
    Planning & Estimation Framework — Generate task estimates, PR sizes, and cost projections

.DESCRIPTION
    Implements the Planning & Estimation Framework from rules/PLANNING-ESTIMATION-FRAMEWORK.md.
    Provides automated estimation for AI-assisted development tasks.

.PARAMETER Action
    estimate — Generate estimate for a task
    pr-size — Calculate PR size classification
    velocity — Show velocity metrics
    report — Generate estimation report

.PARAMETER TaskType
    feature, bugfix, refactor, documentation, test, security, performance, infrastructure

.PARAMETER Complexity
    Task complexity score 1-5

.PARAMETER FilesChanged
    Number of files changed

.PARAMETER LinesChanged
    Number of lines changed

.EXAMPLE
    .\planning-estimator.ps1 -Action estimate -TaskType feature -Complexity 3 -FilesChanged 5 -LinesChanged 200
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('estimate', 'pr-size', 'velocity', 'report')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [ValidateSet('feature', 'bugfix', 'refactor', 'documentation', 'test', 'security', 'performance', 'infrastructure')]
    [string]$TaskType = 'feature',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 5)]
    [int]$Complexity = 3,

    [Parameter(Mandatory = $false)]
    [int]$FilesChanged = 5,

    [Parameter(Mandatory = $false)]
    [int]$LinesChanged = 200,

    [Parameter(Mandatory = $false)]
    [string[]]$Factors = @(),

    [Parameter(Mandatory = $false)]
    [string]$Model = 'claude-3.5-sonnet',

    [Parameter(Mandatory = $false)]
    [switch]$AsJson,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

# === Cost Reference (2026) ===
$modelPricing = @{
    'gpt-4o'         = @{ input = 2.50; output = 10.00 }
    'claude-3.5-sonnet' = @{ input = 3.00; output = 15.00 }
    'gpt-4o-mini'    = @{ input = 0.15; output = 0.60 }
    'claude-3-haiku' = @{ input = 0.25; output = 1.25 }
    'gemini-2.0-flash' = @{ input = 0.10; output = 0.40 }
}

# === Base Times (minutes) ===
$baseTime = @{
    1 = 3      # Trivial
    2 = 15     # Simple
    3 = 60     # Medium
    4 = 240    # Complex
    5 = 480    # Critical
}

# === Base Tokens ===
$baseTokens = @{
    1 = 1000
    2 = 4000
    3 = 15000
    4 = 40000
    5 = 80000
}

# === Task Type Multipliers ===
$taskMultipliers = @{
    'feature'        = 1.0
    'bugfix'         = 0.7
    'refactor'       = 0.8
    'documentation'  = 0.3
    'test'           = 0.5
    'security'       = 1.2
    'performance'    = 0.9
    'infrastructure' = 0.6
}

# === Complexity Factor Multipliers ===
$factorMultipliers = @{
    'external-dependency' = 1.3
    'security-impact'     = 1.5
    'breaking-change'     = 1.4
    'cross-platform'      = 1.2
    'performance-critical' = 1.3
    'no-tests'            = 1.2
    'legacy-code'         = 1.3
}

function Get-Estimate {
    param(
        [string]$TaskType,
        [int]$Complexity,
        [string[]]$Factors,
        [string]$Model
    )

    $baseMinutes = $baseTime[$Complexity]
    $taskMult = $taskMultipliers[$TaskType]
    $factorMult = 1.0
    $appliedFactors = @()

    foreach ($f in $Factors) {
        if ($factorMultipliers.ContainsKey($f)) {
            $factorMult *= $factorMultipliers[$f]
            $appliedFactors += $f
        }
    }

    $estimatedMinutes = [math]::Round($baseMinutes * $taskMult * $factorMult)
    $estimatedTokens = [math]::Round($baseTokens[$Complexity] * $taskMult * $factorMult)

    # Cost estimation
    $inputRatio = 0.7
    $outputRatio = 0.3
    $pricing = $modelPricing[$Model]
    if (-not $pricing) { $pricing = $modelPricing['claude-3.5-sonnet'] }

    $inputCost = ($estimatedTokens * $inputRatio) / 1000000 * $pricing.input
    $outputCost = ($estimatedTokens * $outputRatio) / 1000000 * $pricing.output
    $estimatedCost = [math]::Round($inputCost + $outputCost, 4)

    # Time formatting
    $timeFormatted = if ($estimatedMinutes -lt 60) {
        "$estimatedMinutes min"
    } elseif ($estimatedMinutes -lt 1440) {
        "$([math]::Round($estimatedMinutes / 60, 1)) hours"
    } else {
        "$([math]::Round($estimatedMinutes / 1440, 1)) days"
    }

    return @{
        task_type       = $TaskType
        complexity      = $Complexity
        factors         = $appliedFactors
        model           = $Model
        estimated_time  = $timeFormatted
        estimated_minutes = $estimatedMinutes
        estimated_tokens = $estimatedTokens
        estimated_cost  = $estimatedCost
        confidence      = if ($Complexity -le 2) { 'high' } elseif ($Complexity -le 3) { 'medium' } else { 'low' }
    }
}

function Get-PRSize {
    param(
        [int]$FilesChanged,
        [int]$LinesChanged
    )

    $size = 'XS'
    $reviewTime = '5 min'
    $mergeWindow = 'Same day'
    $reviewersRequired = 0

    if ($LinesChanged -gt 1000 -or $FilesChanged -gt 30) {
        $size = 'XL'
        $reviewTime = '2+ hours'
        $mergeWindow = '3-5 days'
        $reviewersRequired = 2
    } elseif ($LinesChanged -gt 500 -or $FilesChanged -gt 15) {
        $size = 'L'
        $reviewTime = '1 hour'
        $mergeWindow = '2-3 days'
        $reviewersRequired = 2
    } elseif ($LinesChanged -gt 200 -or $FilesChanged -gt 5) {
        $size = 'M'
        $reviewTime = '30 min'
        $mergeWindow = '1-2 days'
        $reviewersRequired = 1
    } elseif ($LinesChanged -gt 50 -or $FilesChanged -gt 2) {
        $size = 'S'
        $reviewTime = '15 min'
        $mergeWindow = 'Same day'
        $reviewersRequired = 0
    }

    return @{
        size              = $size
        files_changed     = $FilesChanged
        lines_changed     = $LinesChanged
        review_time       = $reviewTime
        merge_window      = $mergeWindow
        reviewers_required = $reviewersRequired
    }
}

function Show-Report {
    $estimate = Get-Estimate -TaskType $TaskType -Complexity $Complexity -Factors $Factors -Model $Model
    $prSize = Get-PRSize -FilesChanged $FilesChanged -LinesChanged $LinesChanged

    if ($AsJson) {
        return @{ estimate = $estimate; pr_size = $prSize } | ConvertTo-Json -Depth 5
    }

    if (-not $Quiet) {
        Write-Host ""
        Write-Host "=== Planning & Estimation Report ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Task Type:     $($estimate.task_type)" -ForegroundColor White
        Write-Host "Complexity:    $($estimate.complexity)/5" -ForegroundColor White
        if ($estimate.factors.Count -gt 0) {
            Write-Host "Factors:       $($estimate.factors -join ', ')" -ForegroundColor Yellow
        }
        Write-Host "Model:         $($estimate.model)" -ForegroundColor White
        Write-Host ""
        Write-Host "--- Estimate ---" -ForegroundColor Cyan
        Write-Host "Time:          $($estimate.estimated_time)" -ForegroundColor Green
        Write-Host "Tokens:        $($estimate.estimated_tokens)" -ForegroundColor Green
        Write-Host "Cost:          `$$($estimate.estimated_cost)" -ForegroundColor Green
        Write-Host "Confidence:    $($estimate.confidence)" -ForegroundColor $(switch($estimate.confidence) { 'high' { 'Green' } 'medium' { 'Yellow' } default { 'Red' } })
        Write-Host ""
        Write-Host "--- PR Classification ---" -ForegroundColor Cyan
        Write-Host "PR Size:       $($prSize.size)" -ForegroundColor Green
        Write-Host "Review Time:   $($prSize.review_time)" -ForegroundColor White
        Write-Host "Merge Window:  $($prSize.merge_window)" -ForegroundColor White
        Write-Host "Reviewers:     $($prSize.reviewers_required)" -ForegroundColor White
        Write-Host ""

        # Warnings
        if ($prSize.size -eq 'XL') {
            Write-Host "[WARN] XL PR detected — MUST split into smaller PRs (< 1000 lines)" -ForegroundColor Yellow
        }
        if ($estimate.confidence -eq 'low') {
            Write-Host "[WARN] Low confidence estimate — consider breaking down into smaller tasks" -ForegroundColor Yellow
        }
    }

    return $estimate
}

# === Main ===
switch ($Action) {
    'estimate' {
        Show-Report
    }
    'pr-size' {
        $prSize = Get-PRSize -FilesChanged $FilesChanged -LinesChanged $LinesChanged
        if ($AsJson) {
            $prSize | ConvertTo-Json -Depth 3
        } else {
            Write-Host "PR Size: $($prSize.size) | Review: $($prSize.review_time) | Merge: $($prSize.merge_window) | Reviewers: $($prSize.reviewers_required)"
        }
    }
    'velocity' {
        $metricsFile = Join-Path $root '.session/velocity-metrics.json'
        if (Test-Path $metricsFile) {
            Get-Content $metricsFile -Raw | ConvertFrom-Json | ConvertTo-Json -Depth 5
        } else {
            Write-Host "No velocity data yet. Metrics will be collected as tasks are completed."
        }
    }
    'report' {
        Show-Report
    }
}
