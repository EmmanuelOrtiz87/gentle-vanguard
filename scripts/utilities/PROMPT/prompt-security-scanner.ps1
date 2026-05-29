param(
    [Parameter(Mandatory=$true)][string]$PromptContent,
    [string]$WorkspaceRoot = "."
)
$cfgPath = Join-Path $WorkspaceRoot "config/system-prompt-optimization.json"
$blockSecrets = $true
$blockXss = $true
if (Test-Path $cfgPath) {
    $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
    if ($cfg.security) {
        $blockSecrets = if ($cfg.security.blockSecrets -eq $false) { $false } else { $true }
        $blockXss = if ($cfg.security.blockXss -eq $false) { $false } else { $true }
    }
}
$issues = @()
if ($blockSecrets -and $PromptContent -match "password") { $issues += "Potential secret" }
if ($blockXss -and $PromptContent -match "<script>") { $issues += "XSS detected" }
if ($PromptContent -match "\.\./") { $issues += "Path traversal" }
if ($PromptContent -match "DROP TABLE") { $issues += "SQL injection" }
if ($issues.Count -eq 0) { Write-Output "PASSED" } else { Write-Output "ISSUES:"; $issues | ForEach-Object { Write-Output "  - $_" } }
