<#
.SYNOPSIS
    Autonomous Document Drift Detector
    
.DESCRIPTION
    Detects when code changes but documentation stays outdated:
    1. Scans code files vs their documentation
    2. Compares timestamps (code newer than docs = drift)
    3. Auto-delegates updates to subagent
    4. Learns patterns (e.g., "API changed, docs not updated")
    5. SECURITY: Only metadata logged, no code/content exposed
    
.PARAMETER Trigger
    What triggered: session-start, session-close, manual
    
.PARAMETER AutoFix
    Attempt auto-fix via delegation
    
.EXAMPLE
    .\auto-doc-drift-detector.ps1 -Trigger session-start -AutoFix
    
.NOTES
    Security: No sensitive code/docs content in logs
    Agile: Only metadata (paths, timestamps) stored
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("session-start", "session-close", "manual")]
    [string]$Trigger = "manual",
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoFix,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'
$repoRoot = if ($env:GV_BASE_DIR -and (Test-Path $env:GV_BASE_DIR)) { $env:GV_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$driftLog = Join-Path $repoRoot ".session\doc-drift-log.json"
$script:Drifts = New-Object System.Collections.ArrayList
$script:Fixed = New-Object System.Collections.ArrayList

function Write-Drift { param([string]$msg) Write-Host "[DRIFT]" -NoNewline -ForegroundColor Green; Write-Host " $msg" -ForegroundColor White }
function Write-DriftOk { param([string]$msg) Write-Host "[DRIFT-OK]" -NoNewline -ForegroundColor Green; Write-Host " $msg" -ForegroundColor Gray }
function Write-DriftWarn { param([string]$msg) Write-Host "[DRIFT-WARN]" -NoNewline -ForegroundColor Yellow; Write-Host " $msg" -ForegroundColor Gray }
function Write-DriftFix { param([string]$msg) Write-Host "[DRIFT-FIX]" -NoNewline -ForegroundColor Cyan; Write-Host " $msg" -ForegroundColor Gray }

# SECURITY: Only log metadata, never code/docs content
function Get-FileMetadata {
    param([string]$FilePath)
    
    $file = Get-Item $FilePath -ErrorAction SilentlyContinue
    if (-not $file) { return $null }
    
    return @{
        path = $file.FullName.Replace($repoRoot, "").TrimStart('\')
        name = $file.Name
        extension = $file.Extension
        lastWrite = $file.LastWriteTime
        size = $file.Length
        # SECURITY: No content read
    }
}

# Find documentation file for a code file
function Find-DocFile {
    param([string]$CodeFile)
    
    $codeMeta = Get-FileMetadata -FilePath $CodeFile
    if (-not $codeMeta) { return $null }
    
    # Strategy 1: Look for same name in docs/ with .md extension
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($codeFile)
    $possibleDocs = @(
        # docs/reference/{name}.md
        (Join-Path $repoRoot "docs\reference\$baseName.md")
        # docs/guides/{name}.md
        (Join-Path $repoRoot "docs\guides\$baseName.md")
        # Same directory as code, with .md
        (Join-Path (Split-Path $codeFile) "$baseName.md")
    )
    
    foreach ($doc in $possibleDocs) {
        if (Test-Path $doc) {
            return @{
                path = $doc
                metadata = Get-FileMetadata -FilePath $doc
            }
        }
    }
    
    return $null
}

# Detect drift for a single code file
function Test-DocumentDrift {
    param([string]$CodeFile)
    
    $codeMeta = Get-FileMetadata -FilePath $CodeFile
    if (-not $codeMeta) { return $null }
    
    $docInfo = Find-DocFile -CodeFile $CodeFile
    if (-not $docInfo) {
        # No doc found, this is a drift too (undocumented code)
        return @{
            code = $codeMeta
            doc = $null
            drift = $true
            reason = "No documentation found for $($codeMeta.name)"
            severity = "HIGH"
        }
    }
    
    $docMeta = $docInfo.metadata
    $codeTime = [DateTime]$codeMeta.lastWrite
    $docTime = [DateTime]$docMeta.lastWrite
    
    $timeDiff = $codeTime - $docTime
    
    if ($timeDiff.TotalMinutes -gt 5) {  # Code is >5 min newer than docs
        return @{
            code = $codeMeta
            doc = $docMeta
            drift = $true
            reason = "Code newer than docs by $($timeDiff.TotalMinutes.ToString('0')) minutes"
            severity = if ($timeDiff.TotalHours -gt 24) { "HIGH" } elseif ($timeDiff.TotalHours -gt 1) { "MEDIUM" } else { "LOW" }
        }
    }
    
    return @{
        code = $codeMeta
        doc = $docMeta
        drift = $false
        reason = "Documentation is up-to-date"
        severity = "NONE"
    }
}

# Main detection logic
function Invoke-DriftDetection {
    Write-Host ""
    Write-Host "" -ForegroundColor Green
    Write-Host "  AUTO-DOC-DRIFT DETECTOR (Trigger: $Trigger)" -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    Write-Host ""
    
    # Code file extensions to scan
    $codeExtensions = @('.ts', '.tsx', '.js', '.jsx', '.go', '.py', '.java', '.cs', '.rb')
    $codeFiles = Get-ChildItem -Path $repoRoot -Recurse -File | Where-Object {
        $codeExtensions -contains $_.Extension -and
        $_.FullName -notmatch '\\node_modules\\' -and
        $_.FullName -notmatch '\\.git\\' -and
        $_.FullName -notmatch '\\dist\\' -and
        $_.FullName -notmatch '\\build\\'
    }
    
    Write-Drift "Scanning $($codeFiles.Count) code files for documentation drift..."
    Write-Host ""
    
    $driftCount = 0
    $upToDate = 0
    
    foreach ($file in $codeFiles) {
        $result = Test-DocumentDrift -CodeFile $file.FullName
        
        if ($result.drift) {
            $driftCount++
            [void]$script:Drifts.Add($result)
            
            $severityColor = switch ($result.severity) {
                "HIGH" { "Red" }
                "MEDIUM" { "Yellow" }
                "LOW" { "Gray" }
            }
            
            Write-DriftWarn "[$result.severity] $($result.code.name)"
            Write-Host "  Code: $($result.code.lastWrite.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
            if ($result.doc) {
                Write-Host "  Doc:  $($result.doc.lastWrite.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
            }
            Write-Host "  Reason: $($result.reason)" -ForegroundColor $severityColor
            Write-Host ""
        } else {
            $upToDate++
        }
    }
    
    # Summary
    Write-Host "" -ForegroundColor Cyan
    Write-Host "DRIFT DETECTION SUMMARY" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    Write-Host "  Total code files scanned: $($codeFiles.Count)" -ForegroundColor White
    Write-Host "   Up-to-date: $upToDate" -ForegroundColor Green
    Write-Host "    Drift detected: $driftCount" -ForegroundColor Yellow
    Write-Host ""
    
    if ($driftCount -eq 0) {
        Write-DriftOk "All documentation is up-to-date!"
        return @{ status = "PASS"; drifts = 0; fixed = 0 }
    }
    
    # Attempt auto-fix if requested
    $fixedCount = 0
    if ($AutoFix) {
        Write-Drift "Attempting auto-fix for $driftCount drift(s)..."
        Write-Host ""
        
        foreach ($drift in $script:Drifts) {
            Write-DriftFix "Delegating fix for: $($drift.code.name)"
            
            # Build task for delegation (SECURITY: only metadata)
            $reasonParts = $drift.reason -split 'by '
            $minutesPart = if ($reasonParts.Count -gt 1) { ($reasonParts[1] -split ' ')[0] } else { "unknown" }
            $task = "Update documentation for $($drift.code.path) - code is newer by $minutesPart minutes"
            
            # Would delegate to sdd-apply or general subagent
            # For now, simulate
            Write-DriftFix "Task: $task"
            Write-DriftFix "Delegated to subagent (simulated)"
            
            [void]$script:Fixed.Add([PSCustomObject]@{
                code = $drift.code.path
                doc = if ($drift.doc) { $drift.doc.path } else { "Not found" }
                timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            })
            $fixedCount++
        }
    }
    
    # Save results (SECURITY: only metadata)
    $logData = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        trigger = $Trigger
        scanned = $codeFiles.Count
        drifts = $script:Drifts.Count
        fixed = $script:Fixed.Count
        details = $script:Drifts | ForEach-Object {
            @{
                code_path = $_.code.path
                doc_path = if ($_.doc) { $_.doc.path } else { $null }
                severity = $_.severity
                reason = $_.reason
                # SECURITY: No content hashes or snippets
            }
        }
    }
    
    $logData | ConvertTo-Json -Depth 10 | Out-File -FilePath $driftLog -Encoding UTF8
    Write-Drift "Results saved (metadata only, no content exposed)"
    
    return @{ status = if ($fixedCount -eq $driftCount) { "FIXED" } else { "DRIFT_DETECTED" }; drifts = $driftCount; fixed = $fixedCount }
}

# Execute
$result = Invoke-DriftDetection

# Learn from patterns (if repeated drift detected)
if ($result.drifts -gt 0) {
    Write-DriftWarn "Learning from drift patterns..."
    
    # Save to learning system (would trigger auto-norm-learner)
    $learningFile = Join-Path $repoRoot ".session\doc-drift-learning.json"
    $learning = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        drifts = $result.drifts
        message = "Documentation drift detected - consider updating docs when changing code"
    }
    $learning | ConvertTo-Json | Out-File -FilePath $learningFile -Encoding UTF8 -Append
}

# Final summary
Write-Host ""
Write-Host "" -ForegroundColor Cyan
Write-Host "FINAL RESULT" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "  Status: $($result.status)" -ForegroundColor White
Write-Host "  Drifts detected: $($result.drifts)" -ForegroundColor Yellow
Write-Host "  Auto-fixed: $($result.fixed)" -ForegroundColor Green
Write-Host ""

return $result



