# session-notification.ps1
# Timezone-aware session notifications - Provider agnostic

param(
    [string]$SessionId = '',
    [string]$TimeZone = 'Argentina Standard Time',
    [int]$PeakStart = 9,
    [int]$PeakEnd = 15,
    [string]$Region = 'Argentina'
)

$ErrorActionPreference = 'Continue'

function Get-LocalizedTime {
    param([string]$TimeZoneId)
    
    try {
        $timeZoneInfo = [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZoneId)
        $localTime = [System.TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $timeZoneInfo)
        return $localTime
    }
    catch {
        # Fallback to UTC-3 (Argentina)
        $utcNow = [DateTime]::UtcNow
        return $utcNow.AddHours(-3)
    }
}

function Show-PeakHourNotification {
    param([string]$Region, [int]$PeakStart, [int]$PeakEnd)
    
    Write-Host ""
    Write-Host "====== PEAK HOUR DETECTED ($PeakStart`:00 - $PeakEnd`:00) ======" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Token consumption is POTENTIALLY HIGH during peak hours." -ForegroundColor White
    Write-Host ""
    Write-Host "  Recommendations:" -ForegroundColor Cyan
    Write-Host "    - Keep tasks SHORT and CONCISE" -ForegroundColor White
    Write-Host "    - Avoid heavy or complex tasks" -ForegroundColor White
    Write-Host "    - Complex tasks should be done at off-peak hours" -ForegroundColor White
    Write-Host "    - Goal: avoid excessive token waste" -ForegroundColor White
    Write-Host ""
    Write-Host "====== End Peak Hour Notice ======" -ForegroundColor Red
    Write-Host ""
}

function Show-OffPeakNotification {
    param([string]$Region)
    
    Write-Host ""
    Write-Host "====== OFF-PEAK HOURS ($Region) ======" -ForegroundColor Green
    Write-Host ""
    Write-Host "  You can operate NORMALLY with large/complex tasks." -ForegroundColor White
    Write-Host ""
    Write-Host "  Advantages of this time:" -ForegroundColor Cyan
    Write-Host "    - No elevated token consumption" -ForegroundColor White
    Write-Host "    - Ideal for heavy and complex tasks" -ForegroundColor White
    Write-Host "    - Weekend work also recommended" -ForegroundColor White
    Write-Host "    - Outside of peak business hours" -ForegroundColor White
    Write-Host ""
    Write-Host "  Enjoy the IA agent without restrictions!" -ForegroundColor Green
    Write-Host ""
    Write-Host "====== End Off-Peak Notice ======" -ForegroundColor Green
    Write-Host ""
}

function Test-PeakHour {
    param([DateTime]$LocalTime, [int]$PeakStart, [int]$PeakEnd)
    
    $hour = $LocalTime.Hour
    return ($hour -ge $PeakStart -and $hour -lt $PeakEnd)
}

# Main
$localTime = Get-LocalizedTime -TimeZoneId $TimeZone

Write-Host "[NOTIFICATION] Current time ($Region): $($localTime.ToString('HH:mm:ss zzz'))" -ForegroundColor Gray

if (Test-PeakHour -LocalTime $localTime -PeakStart $PeakStart -PeakEnd $PeakEnd) {
    Show-PeakHourNotification -Region $Region -PeakStart $PeakStart -PeakEnd $PeakEnd
} else {
    Show-OffPeakNotification -Region $Region
}

if ($SessionId) {
    Write-Host "[INFO] Session: $SessionId" -ForegroundColor Gray
}
