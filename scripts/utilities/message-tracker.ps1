# message-tracker.ps1
# Message count tracking and token optimization - Provider agnostic

param(
    [string]$SessionId,
    [ValidateSet('Increment', 'Get', 'Reset', 'Status')]
    [string]$Action = 'Increment',
    [int]$WarningThreshold = 15,
    [int]$CriticalThreshold = 20,
    [string]$SessionDir = '.\.session'
)

$WarningThreshold = $WarningThreshold  # 15 mensajes - warning
$CriticalThreshold = $CriticalThreshold  # 20 mensajes - critical

function Get-SessionFile {
    param([string]$SessionId, [string]$SessionDir)
    
    if ($SessionId) {
        $sessionFile = Join-Path $SessionDir "$SessionId.json"
        if (Test-Path $sessionFile) {
            return $sessionFile
        }
    }
    
    # Buscar la sesion mas reciente
    $sessionFile = Get-ChildItem -Path $SessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue | 
                   Sort-Object LastWriteTime -Descending | 
                   Select-Object -First 1 | 
                   ForEach-Object { $_.FullName }
    
    return $sessionFile
}

function Update-MessageCount {
    param([string]$SessionFile)
    
    if (-not (Test-Path $SessionFile)) {
        Write-Error "Session file not found: $SessionFile"
        return $null
    }
    
    $sessionData = Get-Content -Path $SessionFile -Raw | ConvertFrom-Json
    
    # Inicializar contador si no existe
    if (-not ($sessionData.PSObject.Properties.Name -contains 'messageCount')) {
        Add-Member -InputObject $sessionData -NotePropertyName 'messageCount' -NotePropertyValue 0
    }
    
    # Incrementar contador
    $sessionData.messageCount++
    
    # Guardar
    $sessionData | ConvertTo-Json | Out-File -FilePath $SessionFile -Encoding UTF8
    
    return $sessionData.messageCount
}

function Get-MessageCount {
    param([string]$SessionFile)
    
    if (-not (Test-Path $SessionFile)) {
        return 0
    }
    
    $sessionData = Get-Content -Path $SessionFile -Raw | ConvertFrom-Json
    
    if ($sessionData.PSObject.Properties.Name -contains 'messageCount') {
        return $sessionData.messageCount
    }
    
    return 0
}

function Reset-MessageCount {
    param([string]$SessionFile)
    
    if (-not (Test-Path $SessionFile)) {
        return
    }
    
    $sessionData = Get-Content -Path $SessionFile -Raw | ConvertFrom-Json
    
    if ($sessionData.PSObject.Properties.Name -contains 'messageCount') {
        $sessionData.messageCount = 0
        $sessionData | ConvertTo-Json | Out-File -FilePath $SessionFile -Encoding UTF8
    }
}

function Test-Threshold {
    param([int]$Count, [int]$WarningThreshold, [int]$CriticalThreshold)
    
    if ($Count -ge $CriticalThreshold) {
        return 'Critical'
    } elseif ($Count -ge $WarningThreshold) {
        return 'Warning'
    } else {
        return 'OK'
    }
}

function Show-WarningNotification {
    param([int]$Count, [int]$Threshold)
    
    Write-Host ""
    Write-Host "====== WARNING: Approaching message limit ($Count/$Threshold) ======" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Context is gradually being fed." -ForegroundColor White
    Write-Host ""
    Write-Host "  Recommendations:" -ForegroundColor Cyan
    Write-Host "    - Save progress to Engram" -ForegroundColor White
    Write-Host "    - Prepare a summary of work done" -ForegroundColor White
    Write-Host "    - Consider starting a new session soon" -ForegroundColor White
    Write-Host ""
}

function Show-CriticalNotification {
    param([int]$Count, [int]$Threshold)
    
    Write-Host ""
    Write-Host "====== CRITICAL: Message limit reached ($Count/$Threshold) ======" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Context saturated - High token costs." -ForegroundColor White
    Write-Host ""
    Write-Host "  RECOMMENDED ACTIONS:" -ForegroundColor Cyan
    Write-Host "    1. Save EVERYTHING to Engram immediately" -ForegroundColor White
    Write-Host "    2. Request a SUMMARY from the agent" -ForegroundColor White
    Write-Host "    3. START a new chat window" -ForegroundColor White
    Write-Host "    4. Avoid exponential token consumption" -ForegroundColor White
    Write-Host ""
    Write-Host "  This prevents:" -ForegroundColor Yellow
    Write-Host "    - Context saturation" -ForegroundColor Gray
    Write-Host "    - Exponential costs" -ForegroundColor Gray
    Write-Host "    - Loss of token availability" -ForegroundColor Gray
    Write-Host ""
}

# Main logic
$sessionFile = Get-SessionFile -SessionId $SessionId -SessionDir $SessionDir

if (-not $sessionFile) {
    Write-Error "No active session found"
    exit 1
}

switch ($Action) {
    'Increment' {
        $count = Update-MessageCount -SessionFile $sessionFile
        $status = Test-Threshold -Count $count -WarningThreshold $WarningThreshold -CriticalThreshold $CriticalThreshold
        
        Write-Output $count
        Write-Output $status
        
        if ($status -eq 'Warning') {
            Show-WarningNotification -Count $count -Threshold $WarningThreshold
        } elseif ($status -eq 'Critical') {
            Show-CriticalNotification -Count $count -Threshold $CriticalThreshold
        }
    }
    
    'Get' {
        $count = Get-MessageCount -SessionFile $sessionFile
        $status = Test-Threshold -Count $count -WarningThreshold $WarningThreshold -CriticalThreshold $CriticalThreshold
        
        Write-Output "Message count: $count"
        Write-Output "Status: $status"
    }
    
    'Reset' {
        Reset-MessageCount -SessionFile $sessionFile
        Write-Output "Message count reset to 0"
    }
    
    'Status' {
        $count = Get-MessageCount -SessionFile $sessionFile
        $status = Test-Threshold -Count $count -WarningThreshold $WarningThreshold -CriticalThreshold $CriticalThreshold
        
        $result = @{
            MessageCount = $count
            Status = $status
            WarningThreshold = $WarningThreshold
            CriticalThreshold = $CriticalThreshold
            SessionFile = $sessionFile
        }
        
        $result | ConvertTo-Json
    }
}
