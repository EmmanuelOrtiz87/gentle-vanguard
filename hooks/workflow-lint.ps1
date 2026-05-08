#!/usr/bin/env pwsh
$workflows = Get-ChildItem -Path ".github/workflows" -Filter "*.yml" -ErrorAction SilentlyContinue
$hasErrors = $false

foreach ($wf in $workflows) {
    try {
        $content = Get-Content $wf.FullName -Raw -ErrorAction Stop

        if ($wf.Name -eq "codeql-analysis.yml") {
            if ($content -match "language:\s*powershell") {
                Write-Host "[WARN] $($wf.Name): 'powershell' language may fail on ubuntu-latest - use 'actions' or 'javascript' instead" -ForegroundColor Yellow
            }
        }

        $trivyFlows = @("owasp-scan.yml", "dependency-backup.yml")
        if ($wf.Name -in $trivyFlows) {
            if ($content -match "aquasecurity/trivy-action" -and $content -notmatch "format:\s") {
                Write-Host "[WARN] $($wf.Name): Trivy action missing 'format:' and 'output:' parameters - report artifact may be empty" -ForegroundColor Yellow
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
