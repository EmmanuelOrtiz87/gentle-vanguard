# test-message-tracker.ps1
# Test script to simulate messages and trigger notifications

$SessionId = "session-2026-04-28-01"
$TrackerScript = "C:\Workspace_local\workspace-foundation\tools\message-tracker.ps1"

# Reset counter first
& $TrackerScript -Action Reset -SessionId $SessionId

Write-Host "Testing message tracker notifications..." -ForegroundColor Cyan
Write-Host ""

# Simulate messages up to 21
for ($i = 1; $i -le 21; $i++) {
    $result = & $TrackerScript -Action Increment -SessionId $SessionId
    
    if ($i -eq 16 -or $i -eq 21) {
        Write-Host "After message $i (Status: $($result[1])):" -ForegroundColor Yellow
        Write-Host "Count: $($result[0])" -ForegroundColor White
        Write-Host ""
    }
}

# Show final status
Write-Host "Final status:" -ForegroundColor Green
& $TrackerScript -Action Get -SessionId $SessionId
