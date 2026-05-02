<#
.SYNOPSIS
    Pre-commit validation hook
.DESCRIPTION
    Validates code before allowing commit
#>
param()

$valid = $true
$errors = @()

# Check for large files
$files = git diff --cached --name-only
foreach ($file in $files) {
    if (Test-Path $file) {
        $size = (Get-Item $file).Length
        if ($size -gt 1MB) {
            $errors += "File too large: $file ($($size/1MB) MB)"
            $valid = $false
        }
    }
}

# Check for secrets (basic patterns)
$content = git diff --cached --unified=0
if ($content -match '(api[_-]?key|secret|password|token)\s*[:=]\s*["\']?\w+') {
    $errors += "Possible secret detected in staged changes"
    $valid = $false
}

if (-not $valid) {
    Write-Host "[FAIL] Pre-commit validation failed:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    exit 1
}

Write-Host "[OK] Pre-commit validation passed" -ForegroundColor Green
exit 0
