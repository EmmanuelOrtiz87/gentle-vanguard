param(
    [ValidateSet('status', 'export')]
    [string]$Mode = 'status',
    [int]$MaxFilesPerScope = 20,
    [int]$MaxCharsPerFile = 1800,
    [switch]$AsJson,
    [switch]$PassThru,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

function Write-Step {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "`n=== $Message ===" -ForegroundColor Cyan
    }
}

function Write-Info {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor White
    }
}

function Get-OrchestratorRuleConfig {
    $configPath = Join-Path $repoRoot 'config\orchestrator.json'
    $defaults = [ordered]@{
        enabled = $true
        root = 'rules/custom'
        include = @('technical', 'business', 'review')
    }

    if (-not (Test-Path $configPath)) {
        return $defaults
    }

    try {
        $json = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $json.PSObject.Properties['custom_rules']) {
            return $defaults
        }

        $custom = $json.custom_rules
        if ($custom.PSObject.Properties['enabled']) {
            $defaults.enabled = [bool]$custom.enabled
        }
        if ($custom.PSObject.Properties['root'] -and -not [string]::IsNullOrWhiteSpace([string]$custom.root)) {
            $defaults.root = [string]$custom.root
        }
        if ($custom.PSObject.Properties['include'] -and $custom.include) {
            $defaults.include = @($custom.include | ForEach-Object { [string]$_ })
        }
        if ($custom.PSObject.Properties['max_files_per_scope'] -and [int]$custom.max_files_per_scope -gt 0) {
            $script:MaxFilesPerScope = [int]$custom.max_files_per_scope
        }

        return $defaults
    }
    catch {
        return $defaults
    }
}

function Get-RuleFiles {
    param(
        [string]$ScopeDir,
        [int]$Limit
    )

    if (-not (Test-Path $ScopeDir)) {
        return @()
    }

    # Only .md files are accepted. README.md is reserved for scope documentation and excluded.
    $files = @(Get-ChildItem -Path $ScopeDir -File -Filter '*.md' -ErrorAction SilentlyContinue)

    return @(
        $files |
            Where-Object { $_.Name -ne 'README.md' } |
            Sort-Object Name |
            Select-Object -First $Limit
    )
}

try {
    $ruleConfig = Get-OrchestratorRuleConfig
    $rulesRoot = Join-Path $repoRoot $ruleConfig.root
    $scopes = @($ruleConfig.include)

    $statusRows = @()
    $totalFiles = 0

    foreach ($scope in $scopes) {
        $scopeDir = Join-Path $rulesRoot $scope
        $files = Get-RuleFiles -ScopeDir $scopeDir -Limit $MaxFilesPerScope
        $totalFiles += $files.Count

        $statusRows += [pscustomobject]@{
            scope = $scope
            directory = $scopeDir
            exists = (Test-Path $scopeDir)
            fileCount = $files.Count
            files = @(
                $files | ForEach-Object {
                    [pscustomobject]@{
                        path = $_.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
                        size = $_.Length
                    }
                }
            )
        }
    }

    $status = [pscustomobject]@{
        enabled = [bool]$ruleConfig.enabled
        root = $ruleConfig.root
        rootExists = (Test-Path $rulesRoot)
        scopes = $statusRows
        totalFiles = $totalFiles
    }

    if ($Mode -eq 'status') {
        if ($AsJson) {
            $json = $status | ConvertTo-Json -Depth 10
            if ($PassThru) {
                Write-Output $json
            } else {
                Write-Host $json
            }
            exit 0
        }

        Write-Step 'Custom Rules Status'
        Write-Info "Enabled: $($status.enabled)"
        Write-Info "Root: $($status.root)"
        Write-Info "Root exists: $($status.rootExists)"
        Write-Info "Total files loaded: $($status.totalFiles)"

        foreach ($row in $status.scopes) {
            $relDir = $row.directory.Substring($repoRoot.Length + 1).Replace('\\', '/')
            if (-not $row.exists) {
                $relDir = "$relDir (missing)"
            }

            Write-Info "- $($row.scope): $($row.fileCount) file(s) [$relDir]"
            foreach ($f in $row.files) {
                Write-Info "  - $($f.path)"
            }
        }

        if ($PassThru) {
            Write-Output ($status | ConvertTo-Json -Depth 10)
        }

        exit 0
    }

    $lines = @()
    $lines += "Enabled: $($status.enabled)"
    $lines += "Root: $($status.root)"

    if (-not $status.enabled) {
        $lines += '- custom rules disabled in config/orchestrator.json'
    }
    elseif ($status.totalFiles -eq 0) {
        $lines += '- no custom rule files loaded'
    }
    else {
        foreach ($row in $status.scopes) {
            $lines += ''
            $lines += "### Scope: $($row.scope)"

            if ($row.fileCount -eq 0) {
                $lines += '- no files'
                continue
            }

            foreach ($f in $row.files) {
                $lines += "- File: $($f.path)"
                $fullPath = Join-Path $repoRoot $f.path
                $raw = Get-Content -Path $fullPath -Raw -Encoding UTF8

                if ($raw.Length -gt $MaxCharsPerFile) {
                    $raw = $raw.Substring(0, $MaxCharsPerFile) + "`n[truncated]"
                }

                $lines += '```text'
                $lines += $raw.Trim()
                $lines += '```'
            }
        }
    }

    $digest = $lines -join [Environment]::NewLine
    if ($PassThru) {
        Write-Output $digest
    }
    else {
        Write-Host $digest
    }

    exit 0
}
catch {
    Write-Host ("[ERROR] " + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
