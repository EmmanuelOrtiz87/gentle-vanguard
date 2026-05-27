# Pre-session optimization hook
# Runs automatically before each session

param([string]$WorkspaceRoot = ".")

Write-Host "[AUTO] Running prompt optimization..." -ForegroundColor Cyan

# Compress system prompt if needed
$claudePath = Join-Path $WorkspaceRoot "CLAUDE.md"
$compressedPath = Join-Path $WorkspaceRoot ".session\CLAUDE.min.md"

if (Test-Path $claudePath) {
    $content = Get-Content $claudePath -Raw
    if ($content.Length -gt 3000) {
        & (Join-Path $WorkspaceRoot "scripts\utilities\semantic-compression.ps1") -InputPath $claudePath -OutputPath $compressedPath | Out-Null
        Write-Host "[AUTO] System prompt compressed" -ForegroundColor Green
    }
}

# Security scan
& (Join-Path $WorkspaceRoot "scripts\utilities\prompt-security-scanner.ps1") -PromptContent (Get-Content $claudePath -Raw) | Out-Null

# Cache stats
& (Join-Path $WorkspaceRoot "scripts\utilities\prompt-cache.ps1") -Action stats | Out-Null

Write-Host "[AUTO] Optimization complete" -ForegroundColor Green
