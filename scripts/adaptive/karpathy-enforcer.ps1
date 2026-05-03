# karpathy-enforcer.ps1 (Refined Expert Level)
# Eliminates false positives through context-aware analysis

param(
    [ValidateSet('session-start', 'pre-commit', 'code-review', 'task-complete')]
    [string]$Trigger = 'session-start',
    
    [switch]$AutoFix,
    [switch]$VerboseOutput,
    [string]$TargetPath = ".",
    [string]$FailureLearningDb = "C:\Workspace_local\workspace-foundation\scripts\adaptive\.failure-learning.json"
)

$ErrorActionPreference = "Continue"

# Smart logging
function Write-KLog {
    param([string]$Message, [string]$Color = "Magenta")
    if ($VerboseOutput) { Write-Host "[KARPATHY-ENFORCER] $Message" -ForegroundColor $Color }
}

# Context-aware file classification
function Get-FileContext {
    param([string]$FilePath)
    
    $fileName = Split-Path $FilePath -Leaf
    $directory = Split-Path $FilePath -Parent
    
    # Orchestrators/large utilities that are SUPPOSED to be comprehensive
    $legitimateLarge = @(
        "orchestrator", "manager", "dashboard", "monitor", "generator",
        "bootstrap", "wf.ps1", "validate-foundation", "judgment-day"
    )
    
    # Files that SHOULD be simple
    $shouldBeSimple = @(
        "policy", "config", "setup", "init", "get-", "set-", "test-"
    )
    
    $context = @{
        IsLegitimatelyLarge = $false
        ShouldBeSimple = $false
        ExpectedMaxLines = 300  # default
        Type = "unknown"
    }
    
    # Check if it's a known large-type file
    foreach ($pattern in $legitimateLarge) {
        if ($fileName -match $pattern -or $directory -match $pattern) {
            $context.IsLegitimatelyLarge = $true
            $context.ExpectedMaxLines = 800
            $context.Type = "orchestrator"
            break
        }
    }
    
    # Check if it should be simple
    foreach ($pattern in $shouldBeSimple) {
        if ($fileName -match $pattern) {
            $context.ShouldBeSimple = $true
            $context.ExpectedMaxLines = 150
            $context.Type = "simple-utility"
            break
        }
    }
    
    return $context
}

# Detect TRUE overcomplication (not just line count)
function Test-RealOvercomplication {
    param([string]$FilePath, [hashtable]$Context)
    
    $violations = @()
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $violations }
    
    $lines = ($content -split "`n").Count
    $fileName = Split-Path $FilePath -Leaf
    
    # Skip if legitimately large
    if ($Context.IsLegitimatelyLarge) {
        Write-KLog "Skipping $fileName (legitimately large: $($Context.Type))" "Gray"
        return $violations
    }
    
    # Real overcomplication patterns
    $overcomplicationPatterns = @(
        @{ Pattern = "interface.*Factory|abstract.*Factory"; Message = "Factory pattern for simple task" },
        @{ Pattern = "Singleton|Strategy|Observer"; Message = "Design pattern bloat" },
        @{ Pattern = "class.*Manager|class.*Handler"; Message = "Unnecessary abstraction layer" },
        @{ Pattern = "configuration.*json|appsettings"; Message = "Config file for simple script" },
        @{ Pattern = "try.*catch.*finally.*throw"; Message = "Over-engineered error handling" }
    )
    
    foreach ($check in $overcomplicationPatterns) {
        if ($content -match $check.Pattern) {
            $violations += "File: $fileName - $($check.Message)"
        }
    }
    
    # Check for massive functions (>50 lines each)
    $functions = [regex]::Matches($content, "function\s+\w+")
    if ($functions.Count -gt 10 -and $lines -lt 500) {
        $violations += "File: $fileName - Too many functions ($($functions.Count)) for $lines lines"
    }
    
    # Check for deep nesting (real complexity)
    $maxNesting = 0
    $currentNesting = 0
    foreach ($char in $content.ToCharArray()) {
        if ($char -eq '{') { $currentNesting++; $maxNesting = [math]::Max($maxNesting, $currentNesting) }
        if ($char -eq '}') { $currentNesting-- }
    }
    if ($maxNesting -gt 5) {
        $violations += "File: $fileName - Deep nesting detected (depth: $maxNesting)"
    }
    
    return $violations
}

# Detect unstated assumptions intelligently
function Test-RealAssumptions {
    param([string]$FilePath)
    
    $violations = @()
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $violations }
    
    $fileName = Split-Path $FilePath -Leaf
    
    # Skip test files and auto-generated
    if ($fileName -match "test|spec|\.generated\.") {
        return $violations
    }
    
    # Real signs of unstated assumptions
    $assumptionPatterns = @(
        @{ Pattern = "I assume|Assuming"; Message = "Explicit assumption not stated upfront" },
        @{ Pattern = "TODO:.*implement|HACK|WORKAROUND"; Message = "Hidden technical debt without explanation" },
        @{ Pattern = "#.*should.*|#.*TODO:.*should"; Message = "Unstated expectation in comment" }
    )
    
    foreach ($check in $assumptionPatterns) {
        if ($content -match $check.Pattern) {
            $violations += "File: $fileName - $($check.Message)"
        }
    }
    
    return $violations
}

# Detect surgical changes (real orthogonal edits)
function Test-SurgicalChanges {
    param([string]$TargetPath)
    
    $violations = @()
    
    # Get changed files in last commit
    $changedFiles = git -C $TargetPath diff --name-only HEAD~1...HEAD 2>$null
    if (-not $changedFiles) {
        return $violations
    }
    
    $filesChanged = ($changedFiles -split "`n") | Where-Object { $_.Trim() -ne "" }
    
    # Check for clearly unrelated changes
    $unrelatedPatterns = @(
        "package.json", "package-lock.json",  # Don't mess with deps
        "\.css$", "\.scss$"  # Don't touch styles unless asked
    )
    
    # Only flag if MANY unrelated files changed (likely drive-by)
    $unrelatedCount = 0
    foreach ($file in $filesChanged) {
        foreach ($pattern in $unrelatedPatterns) {
            if ($file -match $pattern) {
                $unrelatedCount++
                break
            }
        }
    }
    
    if ($unrelatedCount -gt 2) {
        $violations += "Too many unrelated files changed: $unrelatedCount (possible drive-by edits)"
    }
    
    return $violations
}

# Detect missing success criteria
function Test-GoalDriven {
    param([string]$TargetPath)
    
    $violations = @()
    
    # Check if there are test files for recent changes
    $changedFiles = git -C $TargetPath diff --name-only HEAD~1...HEAD 2>$null
    if (-not $changedFiles) {
        return $violations
    }
    
    $filesChanged = ($changedFiles -split "`n") | Where-Object { $_.Trim() -ne "" }
    $hasCode = $filesChanged | Where-Object { $_ -match "\.(ps1|ts|js|go|py)$" }
    $hasTests = $filesChanged | Where-Object { $_ -match "test|spec" }
    
    if ($hasCode -and -not $hasTests) {
        $violations += "Code changes without corresponding tests (violates Goal-Driven principle)"
    }
    
    return $violations
}

# Main enforcement
function Invoke-KarpathyEnforcement {
    Write-KLog "Karpathy Guidelines Enforcement (Trigger: $Trigger)" "Magenta"
    
    $allViolations = @()
    
    switch ($Trigger) {
        'session-start' {
            Write-KLog "Scanning codebase for REAL Karpathy violations..."
            $files = Get-ChildItem -Path $TargetPath -Include *.ps1,*.ts,*.js,*.go -Recurse -ErrorAction SilentlyContinue |
                     Where-Object { $_.FullName -notmatch "node_modules|\.git|build|dist" }
            
            foreach ($file in $files) {
                $context = Get-FileContext -FilePath $file.FullName
                $allViolations += Test-RealOvercomplication -FilePath $file.FullName -Context $context
                $allViolations += Test-RealAssumptions -FilePath $file.FullName
            }
        }
        'pre-commit' {
            Write-KLog "Verifying surgical changes and goal-driven execution..."
            $allViolations += Test-SurgicalChanges -TargetPath $TargetPath
            $allViolations += Test-GoalDriven -TargetPath $TargetPath
        }
        'code-review' {
            Write-KLog "Full Karpathy review..."
            $files = Get-ChildItem -Path $TargetPath -Include *.ps1,*.ts,*.js,*.go -Recurse -ErrorAction SilentlyContinue |
                     Where-Object { $_.FullName -notmatch "node_modules|\.git|build|dist" }
            
            foreach ($file in $files) {
                $context = Get-FileContext -FilePath $file.FullName
                $allViolations += Test-RealOvercomplication -FilePath $file.FullName -Context $context
                $allViolations += Test-RealAssumptions -FilePath $file.FullName
            }
            $allViolations += Test-SurgicalChanges -TargetPath $TargetPath
            $allViolations += Test-GoalDriven -TargetPath $TargetPath
        }
    }
    
    # Report
    if ($allViolations.Count -eq 0) {
        Write-Host "[KARPATHY] No Karpathy violations found" -ForegroundColor Green
        return 0
    } else {
        Write-Host "[KARPATHY-WARNING] Found $($allViolations.Count) REAL violation(s):" -ForegroundColor Yellow
        foreach ($v in $allViolations) {
            Write-Host "  - $v" -ForegroundColor Yellow
        }
        
        # Log to failure learning
        if (Test-Path $FailureLearningDb) {
            $data = Get-Content $FailureLearningDb -Raw | ConvertFrom-Json
            foreach ($v in $allViolations) {
                $failure = @{
                    timestamp = Get-Date -Format "o"
                    type = "karpathy-violation"
                    context = $v
                    resolution = "auto-detected"
                    session = $env:SESSION_ID
                    autonomous = $false
                    success = $false
                }
                $data.failures += $failure
            }
            $data.last_updated = Get-Date -Format "o"
            $data | ConvertTo-Json -Depth 10 | Set-Content $FailureLearningDb
        }
        
        return 1
    }
}

# Execute
$result = Invoke-KarpathyEnforcement
exit $result
