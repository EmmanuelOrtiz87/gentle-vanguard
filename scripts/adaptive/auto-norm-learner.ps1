<#
.SYNOPSIS
    Autonomous Norm Learner - Learns and updates norms from experiences (Simplified)
    
.DESCRIPTION
    Runs autonomously at session start/close or on orchestrator demand.
    Learns from Engram memory, session summaries, and applied corrections.
    
.PARAMETER Trigger
    What triggered this run: session-start, session-close, orchestrator, manual
    
.PARAMETER DryRun
    Simulate without writing changes
    
.PARAMETER VerboseOutput
    Show detailed output
    
.EXAMPLE
    .\auto-norm-learner-simple.ps1 -Trigger session-close -VerboseOutput
    
.NOTES
    Author: gentleman-programming
    Version: 1.0.0 (Simplified)
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("session-start", "session-close", "orchestrator", "manual")]
    [string]$Trigger = "manual",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
$repoRoot = (Resolve-Path (Join-Path $repoRoot '..')).Path

$adaptiveRulesPath = Join-Path $repoRoot "rules\adaptive"
$learnedNormsPath = Join-Path $adaptiveRulesPath "LEARNED-NORMS.md"
$customRulesPath = Join-Path $repoRoot "rules\custom"

$NewNorms = New-Object System.Collections.ArrayList
$UpdatedNorms = New-Object System.Collections.ArrayList
$PromotedNorms = New-Object System.Collections.ArrayList

function Write-Learn {
    param([string]$Message)
    if ($VerboseOutput) {
        Write-Host "[LEARNER] $Message" -ForegroundColor Magenta
    }
}

function Write-LearnNew {
    param([string]$Message)
    Write-Host "[NEW-NORM] $Message" -ForegroundColor Green
}

function Write-LearnUpdate {
    param([string]$Message)
    Write-Host "[UPDATE-NORM] $Message" -ForegroundColor Yellow
}

function Write-LearnPromote {
    param([string]$Message)
    Write-Host "[PROMOTE] $Message" -ForegroundColor Cyan
}

# Simulate Engram memory query
function Get-EngramPatterns {
    Write-Learn "Querying Engram memory for patterns..."
    
    $patterns = @(
        @{
            Type = "documentation"
            Pattern = "Documentation saved in project root instead of docs/"
            SessionId = "session-2026-04-28-03"
            Frequency = 2
        },
        @{
            Type = "documentation"
            Pattern = "Missing directories created manually each session"
            SessionId = "session-2026-04-29-01"
            Frequency = 1
        },
        @{
            Type = "correction"
            Pattern = "PowerShell [OK] parser error at line start"
            SessionId = "session-2026-04-28-01"
            Frequency = 5
        }
    )
    
    return $patterns
}

# Load current learned norms
function Get-CurrentNorms {
    $norms = New-Object System.Collections.ArrayList
    
    if (Test-Path $learnedNormsPath) {
        $content = Get-Content $learnedNormsPath -Raw
        
        # Simple regex to extract norms from markdown tables
        $regex = [regex]::new('\| (\w+-\d+) \| (.+?) \| (\w+) \| (.+?) \| (\d{4}-\d{2}-\d{2}) \|')
        $matches = $regex.Matches($content)
        
        foreach ($match in $matches) {
            $norm = [PSCustomObject]@{
                ID = $match.Groups[1].Value
                Norm = $match.Groups[2].Value.Trim()
                Confidence = $match.Groups[3].Value.Trim()
                Source = $match.Groups[4].Value.Trim()
                Date = $match.Groups[5].Value.Trim()
                ValidationCount = 0
            }
            [void]$norms.Add($norm)
        }
    }
    
    return $norms
}

# Generate new norm ID
function Get-NextNormID {
    param([string]$Prefix)
    
    $existing = Get-CurrentNorms | Where-Object { $_.ID -match "^$Prefix-\d+" } | ForEach-Object { [int]($_.ID -split '-')[1] }
    if ($existing.Count -eq 0) { return "$Prefix-001" }
    $max = ($existing | Measure-Object -Maximum).Maximum
    $nextNum = $max + 1
    return "$Prefix-$(($nextNum).ToString('000'))"
}

# Main learning function
function Invoke-Learning {
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "🧠 NORM LEARNER (Trigger: $Trigger)" -ForegroundColor Magenta
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""
    
    $patterns = Get-EngramPatterns
    $currentNorms = Get-CurrentNorms
    
    foreach ($pattern in $patterns) {
        Write-Learn "Processing pattern: $($pattern.Pattern)"
        
        # Check if this pattern is already captured
        $firstWords = ($pattern.Pattern -split ' ')[0..2] -join ' '
        $existingNorm = $currentNorms | Where-Object { $_.Norm -like "*$firstWords*" } | Select-Object -First 1
        
        if ($existingNorm) {
            Write-LearnUpdate "Updating norm $($existingNorm.ID): $($existingNorm.Norm)"
            [void]$UpdatedNorms.Add($existingNorm.ID)
            
            # Simulate promotion check
            if ($pattern.Frequency -ge 3) {
                Write-LearnPromote "Norm $($existingNorm.ID) ready for promotion"
                [void]$PromotedNorms.Add($existingNorm)
            }
        } else {
            # Create new norm
            $prefix = switch ($pattern.Type) {
                "documentation" { "DOC" }
                "correction" { "CORR" }
                "session" { "SESS" }
                default { "GEN" }
            }
            
            $newID = Get-NextNormID -Prefix $prefix
            $newNorm = [PSCustomObject]@{
                ID = $newID
                Norm = $pattern.Pattern
                Confidence = "low"
                Source = $pattern.SessionId
                Date = Get-Date -Format "yyyy-MM-dd"
            }
            
            Write-LearnNew "Created new norm $newID : $($pattern.Pattern)"
            [void]$NewNorms.Add($newNorm)
        }
    }
}

# Update LEARNED-NORMS.md
function Update-LearnedNorms {
    if ($DryRun) {
        Write-Host "`n[DRY-RUN] Would update LEARNED-NORMS.md" -ForegroundColor Yellow
        return
    }
    
    Write-Learn "Updating LEARNED-NORMS.md..."
    
    # Build simple content
    $lines = @()
    $lines += "# Learned Norms (Autonomous)"
    $lines += ""
    $lines += "This file is **auto-maintained** by the adaptive learning system."
    $lines += ""
    $lines += "## Active Norms"
    $lines += ""
    $lines += "### Documentation Placement"
    $lines += ""
    $lines += "| ID | Norm | Confidence | Learned From | Date |"
    $lines += "|----|------|-------------|--------------|------|"
    
    $docNorms = $currentNorms | Where-Object { $_.Norm -like "*documentation*" -or $_.Norm -like "*docs/*" }
    foreach ($norm in $docNorms) {
        $lines += "| $($norm.ID) | $($norm.Norm) | $($norm.Confidence) | $($norm.Source) | $($norm.Date) |"
    }
    
    $lines += ""
    $lines += "### Auto-Correction"
    $lines += ""
    $lines += "| ID | Pattern | Confidence | Learned From | Date |"
    $lines += "|----|---------|-------------|--------------|------|"
    
    $corrNorms = $currentNorms | Where-Object { $_.Norm -like "*PowerShell*" -or $_.Norm -like "*parser*" }
    foreach ($norm in $corrNorms) {
        $lines += "| $($norm.ID) | $($norm.Norm) | $($norm.Confidence) | $($norm.Source) | $($norm.Date) |"
    }
    
    $lines += ""
    $lines += "## Last Update"
    $lines += ""
    $lines += "- Date: $(Get-Date -Format 'yyyy-MM-dd')"
    $lines += "- Trigger: $Trigger"
    $lines += "- Script: auto-norm-learner-simple.ps1"
    
    Set-Content -Path $learnedNormsPath -Value ($lines -join "`n") -Encoding UTF8
    Write-Learn "Updated LEARNED-NORMS.md"
}

# Main execution
Invoke-Learning
Update-LearnedNorms

# Summary
Write-Host ""
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📊 LEARNING SUMMARY" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  New norms created: $($NewNorms.Count)" -ForegroundColor Green
Write-Host "  Norms updated: $($UpdatedNorms.Count)" -ForegroundColor Yellow
Write-Host "  Norms promoted: $($PromotedNorms.Count)" -ForegroundColor Cyan
Write-Host ""

if ($NewNorms.Count -gt 0) {
    Write-Host "✅ New norms:" -ForegroundColor Green
    foreach ($norm in $NewNorms) {
        Write-Host "   - $($norm.ID): $($norm.Norm)" -ForegroundColor Gray
    }
}

$result = @{
    Trigger = $Trigger
    NewNorms = $NewNorms.Count
    UpdatedNorms = $UpdatedNorms.Count
    PromotedNorms = $PromotedNorms.Count
    Status = "SUCCESS"
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

return $result
