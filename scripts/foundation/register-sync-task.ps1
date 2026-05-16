# =============================================================================
# SCHEDULED SYNC TASK
# =============================================================================
# Runs sync-public-repo.ps1 daily at 2:00 AM
# =============================================================================

$TaskName = "Gentle-Vanguard-AutoSync"
$ScriptPath = "$PSScriptRoot\..\scripts\gentle-vanguard\sync-public-repo.ps1"
$TriggerTime = "02:00"

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -Daily -At $TriggerTime

$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

$Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Gentle-Vanguard auto-sync to public repo" -Force

Write-Host "[OK] Scheduled task created: $TaskName" -ForegroundColor Green
Write-Host "  - Runs daily at $TriggerTime" -ForegroundColor Cyan
Write-Host "  - Script: $ScriptPath" -ForegroundColor Gray
