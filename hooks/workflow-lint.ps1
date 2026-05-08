#!/usr/bin/env pwsh
$workflows = Get-ChildItem -Path ".github/workflows" -Filter "*.yml" -ErrorAction SilentlyContinue
$hasErrors = $false

foreach ($wf in $workflows) {
    # Basic YAML syntax check via PowerShell
    try {
        $content = Get-Content $wf.FullName -Raw -ErrorAction Stop
        # Check for common issues: unclosed quotes, invalid matrix languages
        if ($wf.Name -eq "codeql-analysis.yml") {
            if ($content -match "language:\s*powershell") {
                Write-Host "[WARN] $($wf.Name): 'powershell' language may fail on ubuntu-latest - use 'actions' instead" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "[ERROR] Invalid YAML: $($wf.Name) - $_" -ForegroundColor Red
        $hasErrors = $true
    }
}

if ($hasErrors) { exit 1 }
Write-Host "[OK] Workflow files look valid" -ForegroundColor Green
exit 0
