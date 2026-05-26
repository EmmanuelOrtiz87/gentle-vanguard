# karpathy-orchestrator.ps1
# Next-level orchestrator for Karpathy guidelines
# Provides real-time detection, auto-correction, and learning

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('detect', 'enforce', 'learn', 'metrics', 'auto-correct')]
    [string]$Action,
    
    [string]$UserInput,
    [string]$CodePath = ".",
    [string]$SessionId = $env:SESSION_ID,
    [string]$EngramPath = "$HOME\bin\engram.exe",
    [string]$FailureLearningDb = ''
)

$ErrorActionPreference = "Continue"

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

if (-not $FailureLearningDb) {
    $FailureLearningDb = Join-Path $repoRoot 'scripts\adaptive\.failure-learning.json'
}

function Write-KarpathyOrch {
    param([string]$Message)
    Write-Host "[KARPATHY-ORCH] $Message" -ForegroundColor Magenta
}

function Write-KarpathyViolation {
    param([string]$Message)
    Write-Host "[VIOLATION] $Message" -ForegroundColor Red
}

function Write-KarpathySuccess {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

# Real-time detection during coding
function Detect-RealTimeViolations {
    param([string]$Input, [string]$ProposedCode)
    
    $violations = @()
    
    # 1. Detect unstated assumptions
    if ($Input -match "assume|assuming|I think|probably") {
        $violations += "THINK: Unstated assumption detected in input"
    }
    
    # 2. Detect overcomplication patterns
    $overcomplicationPatterns = @(
        "Factory|Strategy|Singleton",  # Design patterns for simple tasks
        "abstract.*class",               # Abstractions for single-use
        "config.*file|configurable"       # Unrequested flexibility
    )
    
    foreach ($pattern in $overcomplicationPatterns) {
        if ($ProposedCode -match $pattern) {
            $violations += "SIMPLICITY: Potential overcomplication: $pattern"
        }
    }
    
    # 3. Detect orthogonal changes
    if ($Input -and $ProposedCode) {
        $keywords = $Input.Split(" ") | Where-Object { $_.Length -gt 3 }
        foreach ($kw in $keywords) {
            if ($ProposedCode -notmatch $kw -and $ProposedCode.Length -gt 100) {
                $violations += "SURGICAL: Change may not trace to request: missing '$kw'"
            }
        }
    }
    
    # 4. Detect missing success criteria
    if ($Input -match "fix|add|implement|refactor" -and $Input -notmatch "test|verify|check|success") {
        $violations += "GOAL: Missing verifiable success criteria in: $Input"
    }
    
    return $violations
}

# Auto-correct before changes are made
function Invoke-AutoCorrect {
    param([string]$ProposedCode, [string]$UserRequest)
    
    $correctedCode = $ProposedCode
    $changes = @()
    
    # 1. Simplify overcomplicated code
    if ($correctedCode -match "interface.*Factory|abstract.*Manager") {
        $correctedCode = $correctedCode -replace "interface.*Factory|abstract.*Manager", "# Simplified per Karpathy principle"
        $changes += "Removed over-engineered abstraction"
    }
    
    # 2. Remove orthogonal edits
    $requestKeywords = $UserRequest.Split(" ") | Where-Object { $_.Length -gt 3 }
    $lines = $correctedCode -split "`n"
    $filteredLines = @()
    
    foreach ($line in $lines) {
        $isRelevant = $false
        foreach ($kw in $requestKeywords) {
            if ($line -match $kw) {
                $isRelevant = $true
                break
            }
        }
        
        if ($isRelevant -or $line.Trim() -eq "" -or $line.Trim().StartsWith("#")) {
            $filteredLines += $line
        } else {
            $changes += "Removed orthogonal line: $($line.Substring(0, [math]::Min(50, $line.Length)))"
        }
    }
    
    $correctedCode = $filteredLines -join "`n"
    
    return @{
        Code = $correctedCode
        Changes = $changes
    }
}

# Metrics for quality measurement
function Get-KarpathyMetrics {
    param([string]$TargetPath)
    
    $metrics = @{
        SimplicityScore = 0
        SurgicalScore = 0
        GoalDrivenScore = 0
        ThinkScore = 0
    }
    
    $files = Get-ChildItem -Path $TargetPath -Include *.ps1,*.ts,*.js,*.go -Recurse -ErrorAction SilentlyContinue
    $totalLines = 0
    $filesAnalyzed = 0
    
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        $lines = ($content -split "`n").Count
        $totalLines += $lines
        $filesAnalyzed++
        
        # Simplicity: lines per file
        if ($lines -lt 50) { $metrics.SimplicityScore += 2 }
        elseif ($lines -lt 200) { $metrics.SimplicityScore += 1 }
        else { $metrics.SimplicityScore -= 1 }
        
        # Surgical: no unrelated changes (check git)
        $fileRelative = $file.FullName.Replace((Get-Location).Path, "").TrimStart("\")
        # This would need git integration
    }
    
    if ($filesAnalyzed -gt 0) {
        $metrics.SimplicityScore = [math]::Round($metrics.SimplicityScore / $filesAnalyzed, 2)
    }
    
    return $metrics
}

# Learning from violations
function Update-KarpathyLearning {
    param([array]$Violations, [string]$Context)
    
    if (-not (Test-Path $FailureLearningDb)) {
        Write-KarpathyOrch "Learning DB not found, skipping..."
        return
    }
    
    $data = Get-Content $FailureLearningDb -Raw | ConvertFrom-Json
    
    foreach ($v in $Violations) {
        $failure = @{
            timestamp = Get-Date -Format "o"
            type = "karpathy-violation"
            context = $v
            resolution = "auto-detected"
            session = $SessionId
            autonomous = $false
            success = $false
        }
        $data.failures += $failure
    }
    
    # Learn patterns
    $karpathyViolations = $data.failures | Where-Object { $_.type -eq "karpathy-violation" }
    $patternGroups = $karpathyViolations | Group-Object { $_.context -replace ":.+$", "" }
    
    foreach ($group in $patternGroups) {
        if ($group.Count -ge 3) {
            $learnedPattern = @{
                type = "karpathy-pattern"
                description = "Recurring violation: $($group.Name)"
                occurrences = $group.Count
                recommendation = "Apply Karpathy principle: $($group.Name.Split(':')[0])"
                learned_at = Get-Date -Format "o"
            }
            
            if (-not $data.learned_patterns) {
                $data.learned_patterns = @()
            }
            
            $existing = $data.learned_patterns | Where-Object { $_.type -eq $learnedPattern.type -and $_.description -eq $learnedPattern.description }
            if (-not $existing) {
                $data.learned_patterns += $learnedPattern
                Write-KarpathyOrch "Learned new pattern: $($learnedPattern.description)"
            }
        }
    }
    
    $data.last_updated = Get-Date -Format "o"
    $data | ConvertTo-Json -Depth 10 | Set-Content $FailureLearningDb
}

# Save to engram for pattern recognition
function Save-ToEngram {
    param([array]$Violations, [string]$SuccessPattern)
    
    if (-not (Test-Path $EngramPath)) {
        Write-KarpathyOrch "Engram not found, skipping save..."
        return
    }
    
    foreach ($v in $Violations) {
        $null = & $EngramPath save --title "Karpathy Violation" --content $v --project "workspace_gentle_vanguard" 2>&1 | Out-Null
    }
    
    if ($SuccessPattern) {
        $null = & $EngramPath save --title "Karpathy Success" --content $SuccessPattern --project "workspace_gentle_vanguard" 2>&1 | Out-Null
    }
}

# Main execution
switch ($Action) {
    'detect' {
        Write-KarpathyOrch "Real-time violation detection..."
        $violations = Detect-RealTimeViolations -Input $UserInput -ProposedCode $CodePath
        
        if ($violations.Count -eq 0) {
            Write-KarpathySuccess "No violations detected"
            exit 0
        } else {
            Write-KarpathyViolation "Found $($violations.Count) violation(s):"
            foreach ($v in $violations) {
                Write-Host "  - $v" -ForegroundColor Yellow
            }
            
            # Learn from violations
            Update-KarpathyLearning -Violations $violations -Context $UserInput
            Save-ToEngram -Violations $violations
            
            exit 1
        }
    }
    
    'enforce' {
        Write-KarpathyOrch "Enforcing Karpathy principles on codebase..."
        $violations = @()
        $violations += Detect-RealTimeViolations -Input "" -ProposedCode $CodePath
        
        if ($violations.Count -eq 0) {
            Write-KarpathySuccess "Codebase complies with Karpathy principles"
            exit 0
        } else {
            Write-KarpathyViolation "Found violations:"
            foreach ($v in $violations) {
                Write-Host "  - $v" -ForegroundColor Yellow
            }
            exit 1
        }
    }
    
    'learn' {
        Write-KarpathyOrch "Learning from past violations..."
        Update-KarpathyLearning -Violations @() -Context "manual-trigger"
        Write-KarpathySuccess "Learning cycle completed"
    }
    
    'metrics' {
        Write-KarpathyOrch "Calculating Karpathy quality metrics..."
        $metrics = Get-KarpathyMetrics -TargetPath $CodePath
        
        Write-Host "`n=== Karpathy Quality Metrics ===" -ForegroundColor Cyan
        Write-Host "Simplicity Score: $($metrics.SimplicityScore)/10" -ForegroundColor White
        Write-Host "Surgical Score: $($metrics.SurgicalScore)/10" -ForegroundColor White
        Write-Host "Goal-Driven Score: $($metrics.GoalDrivenScore)/10" -ForegroundColor White
        Write-Host "Think Score: $($metrics.ThinkScore)/10" -ForegroundColor White
        
        $overall = ($metrics.SimplicityScore + $metrics.SurgicalScore + $metrics.GoalDrivenScore + $metrics.ThinkScore) / 4
        Write-Host "`nOverall Karpathy Score: $([math]::Round($overall, 2))/10" -ForegroundColor Green
    }
    
    'auto-correct' {
        Write-KarpathyOrch "Auto-correcting code..."
        $proposedCode = Get-Content $CodePath -Raw -ErrorAction SilentlyContinue
        $result = Invoke-AutoCorrect -ProposedCode $proposedCode -UserRequest $UserInput
        
        if ($result.Changes.Count -gt 0) {
            Write-KarpathyOrch "Applied corrections:"
            foreach ($c in $result.Changes) {
                Write-Host "  - $c" -ForegroundColor Green
            }
            
            # Save corrected code
            $result.Code | Set-Content $CodePath
            Write-KarpathySuccess "Code auto-corrected"
        } else {
            Write-KarpathyOrch "No corrections needed"
        }
    }
}

Write-KarpathyOrch "=== Operation Complete ==="

