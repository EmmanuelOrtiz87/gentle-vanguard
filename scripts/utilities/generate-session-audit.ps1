# generate-session-audit.ps1
# Generates session audit log for AI-assisted development

param(
    [switch]$Start,
    [switch]$End,
    [switch]$Activity,
    [string]$SessionId,
    [string]$Action = ""
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
$auditDir = Join-Path $projectRoot ".audit"

function Ensure-AuditDirs {
    $dirs = @("sessions", "ai-activity", "code-reviews", "metrics", "reports")
    foreach ($dir in $dirs) {
        $path = Join-Path $auditDir $dir
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
}

function Get-MachineId {
    $id = $env:COMPUTERNAME
    if (Test-Path "C:\Users\.machine-id") {
        $id = Get-Content "C:\Users\.machine-id" -Raw -ErrorAction SilentlyContinue
    }
    return $id.Trim()
}

function Get-UserName {
    return $env:USERNAME
}

function New-SessionAudit {
    param([string]$SessionId)
    
    Ensure-AuditDirs
    
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $date = Get-Date -Format "yyyy-MM-dd"
    
    $sessionFile = Join-Path $auditDir "sessions\$date-session-$SessionId.json"
    
    $session = @{
        id = $SessionId
        type = "session"
        timestamp = $timestamp
        endTime = $null
        project = @{
            name = Split-Path $projectRoot -Leaf
            path = $projectRoot.ToString()
        }
        user = @{
            machineId = Get-MachineId
            userName = Get-UserName
        }
        aiTools = @{
            claude = @{ requests = 0; tokensEstimated = 0 }
            opencode = @{ requests = 0; tokensEstimated = 0 }
            gentleAi = @{ requests = 0; tokensEstimated = 0 }
            gga = @{ invocations = 0; commandsExecuted = @() }
        }
        activity = @{
            actions = @()
            filesModified = @()
            linesAdded = 0
            linesRemoved = 0
            commandsExecuted = @()
            errors = @()
        }
        metrics = @{
            duration = 0
            filesCreated = 0
            filesUpdated = 0
            filesDeleted = 0
            prsCreated = 0
            prsMerged = 0
        }
        validation = @{
            passed = $false
            warnings = @()
            errors = @()
        }
    }
    
    $session | ConvertTo-Json -Depth 10 | Out-File -FilePath $sessionFile -Encoding UTF8
    
    Write-Host "[OK] Session audit started: $sessionFile" -ForegroundColor Green
    
    $env:WFS_SESSION_ID = $SessionId
    $env:WFS_SESSION_FILE = $sessionFile
    
    return $sessionFile
}

function Update-SessionAudit {
    param(
        [string]$File,
        [string]$Tool,
        [int]$Requests = 0,
        [int]$Tokens = 0,
        [string]$ActionType = "",
        [string[]]$Files = @(),
        [int]$LinesAdded = 0,
        [int]$LinesRemoved = 0,
        [string]$Command = "",
        [string]$ErrorMsg = ""
    )
    
    if (-not (Test-Path $File)) {
        Write-Warning "Session file not found: $File"
        return
    }
    
    $session = Get-Content $File -Raw | ConvertFrom-Json
    
    if ($Tool -and $session.aiTools.$Tool) {
        $session.aiTools.$Tool.requests += $Requests
        $session.aiTools.$Tool.tokensEstimated += $Tokens
    }
    
    if ($ActionType) {
        $session.activity.actions += @{
            type = $ActionType
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        }
    }
    
    if ($Files.Count -gt 0) {
        $session.activity.filesModified += $Files
    }
    
    $session.activity.linesAdded += $LinesAdded
    $session.activity.linesRemoved += $LinesRemoved
    
    if ($Command) {
        $session.activity.commandsExecuted += $Command
    }
    
    if ($ErrorMsg) {
        $session.activity.errors += @{
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            message = $ErrorMsg
        }
    }
    
    $session | ConvertTo-Json -Depth 10 | Out-File -FilePath $File -Encoding UTF8
}

function Complete-SessionAudit {
    param([string]$File)
    
    if (-not (Test-Path $File)) {
        Write-Warning "Session file not found: $File"
        return
    }
    
    $session = Get-Content $File -Raw | ConvertFrom-Json
    
    $startTime = [DateTime]::Parse($session.timestamp)
    $session.endTime = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $session.metrics.duration = ((Get-Date) - $startTime).TotalMinutes
    
    $gitStatus = git status --porcelain 2>$null
    if ($gitStatus) {
        $files = $gitStatus | ForEach-Object { $_.Substring(3) }
        $session.activity.filesModified = @($files | Select-Object -Unique)
        
        $session.metrics.filesCreated = ($gitStatus | Where-Object { $_.StartsWith("??") }).Count
        $session.metrics.filesUpdated = ($gitStatus | Where-Object { $_.StartsWith(" M") -or $_.StartsWith("MM") }).Count
        $session.metrics.filesDeleted = ($gitStatus | Where-Object { $_.StartsWith(" D") -or $_.StartsWith("D") }).Count
    }
    
    $diff = git diff --stat 2>$null
    if ($diff) {
        $lines = $diff -split '\s+' | Where-Object { $_ -match '^\d+$' }
        if ($lines.Count -ge 2) {
            $session.activity.linesAdded = [int]$lines[0]
            $session.activity.linesRemoved = [int]$lines[1]
        }
    }
    
    $session.validation.passed = $true
    
    $session | ConvertTo-Json -Depth 10 | Out-File -FilePath $File -Encoding UTF8
    
    Write-Host "[OK] Session audit completed: $File" -ForegroundColor Green
    Write-Host "     Duration: $($session.metrics.duration) minutes" -ForegroundColor Cyan
    Write-Host "     Files modified: $($session.activity.filesModified.Count)" -ForegroundColor Cyan
    Write-Host "     Lines: +$($session.activity.linesAdded) / -$($session.activity.linesRemoved)" -ForegroundColor Cyan
    
    Remove-Item Env:\WFS_SESSION_ID -ErrorAction SilentlyContinue
    Remove-Item Env:\WFS_SESSION_FILE -ErrorAction SilentlyContinue
    
    return $File
}

Ensure-AuditDirs

switch ($true) {
    $Start {
        if ([string]::IsNullOrEmpty($SessionId)) {
            $SessionId = (Get-Random -Maximum 9999).ToString("0000")
        }
        New-SessionAudit -SessionId $SessionId
    }
    $End {
        if ([string]::IsNullOrEmpty($SessionId) -and $env:WFS_SESSION_FILE) {
            Complete-SessionAudit -File $env:WFS_SESSION_FILE
        } elseif (-not [string]::IsNullOrEmpty($SessionId)) {
            $date = Get-Date -Format "yyyy-MM-dd"
            $sessionFile = Join-Path $auditDir "sessions\$date-session-$SessionId.json"
            Complete-SessionAudit -File $sessionFile
        } else {
            Write-Warning "No active session. Use -Start first or provide -SessionId"
        }
    }
    $Activity {
        $file = if ($env:WFS_SESSION_FILE) { $env:WFS_SESSION_FILE } else { $null }
        if (-not $file) {
            $date = Get-Date -Format "yyyy-MM-dd"
            $SessionId = if ($SessionId) { $SessionId } else { (Get-Random -Maximum 9999).ToString("0000") }
            $file = Join-Path $auditDir "sessions\$date-session-$SessionId.json"
            if (-not (Test-Path $file)) {
                New-SessionAudit -SessionId $SessionId
            }
        }
        
        Update-SessionAudit -File $file -Tool $Action -Tokens 100
        Write-Host "[OK] Activity logged to session" -ForegroundColor Green
    }
    default {
        Write-Host "Usage: generate-session-audit.ps1 -Start [-SessionId XXXX]" -ForegroundColor Yellow
        Write-Host "       generate-session-audit.ps1 -End [-SessionId XXXX]" -ForegroundColor Yellow
        Write-Host "       generate-session-audit.ps1 -Activity -Action claude" -ForegroundColor Yellow
    }
}
