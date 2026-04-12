param(
    [switch]$Quiet,
    [switch]$SkipFallbackTests,
    [switch]$StrictToolchain,
    [switch]$EnforceCanonicalStructure
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

function Write-Step { param([string]$Message) if (-not $Quiet) { Write-Host "`n=== $Message ===" -ForegroundColor Cyan } }
function Write-Ok   { param([string]$Message) if (-not $Quiet) { Write-Host "[OK] $Message" -ForegroundColor Green } }
function Write-Warn { param([string]$Message) if (-not $Quiet) { Write-Host "[WARN] $Message" -ForegroundColor Yellow } }
function Write-Fail { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

function Register-ToolingGap {
    param(
        [string]$Message,
        [string]$Remediation
    )

    if ($StrictToolchain) {
        Write-Fail "$Message`
  Remediation: $Remediation"
        $script:failures++
    } else {
        Write-Warn "$Message`
  Remediation: $Remediation"
    }
}

function Register-StructureIssue {
    param(
        [string]$Message,
        [string]$Remediation
    )

    if ($script:effectiveEnforce) {
        Write-Fail "$Message`
  Remediation: $Remediation"
        $script:failures++
    } else {
        Write-Warn "$Message`
  Remediation: $Remediation"
    }
}

# SLO budget in milliseconds per script category
$SLO = @{
    StartupSafe   = 8000   # Level-A: invoked on every shell open
    SessionOps    = 15000  # Level-B: on-demand session operations
    SmokeBudget   = 20000  # overall smoke-check ceiling
}

$failures = 0

# Load structure policy configuration (config/structure-policy.json)
$policyFile = Join-Path $repoRoot 'config/structure-policy.json'
$policyMode = 'adopt-existing'
$policyAllowedRootFiles = @('README.md')
$policyAllowedRootMarkdownFiles = @('README.md', 'AGENTS.md', 'CHANGELOG.md', 'CONTRIBUTING.md')
$policyDeprecatedPatterns = $null
if (Test-Path $policyFile) {
    $policy = Get-Content $policyFile -Raw | ConvertFrom-Json
    if ($policy.structureMode) { $policyMode = $policy.structureMode }
    if ($policy.allowedRootFiles) { $policyAllowedRootFiles = $policy.allowedRootFiles }
    if ($policy.allowedRootMarkdownFiles) { $policyAllowedRootMarkdownFiles = $policy.allowedRootMarkdownFiles }
    if ($policy.deprecatedPathPatterns) { $policyDeprecatedPatterns = $policy.deprecatedPathPatterns }
    if (-not $Quiet) { Write-Ok "Loaded config/structure-policy.json (mode: $policyMode)" }
} else {
    if (-not $Quiet) { Write-Warn 'config/structure-policy.json not found — using defaults (adopt-existing)' }
}
$effectiveEnforce = $EnforceCanonicalStructure -or ($policyMode -eq 'enforce-canonical')

function Get-RepoRelativePath {
    param([string]$Path)

    return $Path.Replace(($repoRoot.Path + '\\'), '').Replace('\\', '/')
}

# ---------------------------------------------------------------------------
# 1. Required path inventory
# ---------------------------------------------------------------------------
$requiredPaths = @(
    "docs/reference/script-registry.md",
    "scripts/utilities/detect-ide-session.ps1",
    "scripts/utilities/auto-init-dev-environment.ps1",
    "scripts/utilities/ensure-tools-active.ps1",
    "scripts/utilities/run-gentle-ai.ps1",
    "scripts/utilities/end-session.ps1",
    "scripts/utilities/wf.ps1",
    "scripts/utilities/stack-on-demand.ps1",
    "scripts/utilities/orchestrator-status.ps1",
    "scripts/git-hooks/pre-push"
)

Write-Step "1. Validating required scripts and registry"
foreach ($relativePath in $requiredPaths) {
    $fullPath = Join-Path $repoRoot $relativePath
    if (Test-Path $fullPath) {
        Write-Ok "$relativePath"
    } else {
        Write-Fail "Missing: $relativePath"
        $failures++
    }
}

# ---------------------------------------------------------------------------
# 1.0 Structure and path hygiene enforcement
# ---------------------------------------------------------------------------
Write-Step "1.0 Validating script structure and deprecated references"

$scriptsRoot = Join-Path $repoRoot 'scripts'
$allowedRootFiles = $policyAllowedRootFiles
$rootFiles = Get-ChildItem -Path $scriptsRoot -File -ErrorAction SilentlyContinue

foreach ($file in $rootFiles) {
    if ($allowedRootFiles -notcontains $file.Name) {
        Register-StructureIssue `
            -Message "Loose root script/config found under scripts/: $(Get-RepoRelativePath -Path $file.FullName)" `
            -Remediation "Move to canonical subfolder or run with -EnforceCanonicalStructure when migration is approved"
    }
}

$rootMarkdownFiles = Get-ChildItem -Path $repoRoot -File -Filter '*.md' -ErrorAction SilentlyContinue
foreach ($md in $rootMarkdownFiles) {
    if ($policyAllowedRootMarkdownFiles -notcontains $md.Name) {
        Register-StructureIssue `
            -Message "Loose root markdown found: $(Get-RepoRelativePath -Path $md.FullName)" `
            -Remediation "Move to docs/* and update references, or whitelist in config/structure-policy.json if intentionally root-scoped"
    }
}

$deprecatedPathPatterns = if ($policyDeprecatedPatterns) { $policyDeprecatedPatterns } else {
    @(
        '.\\scripts\\update-all.ps1',
        'scripts/update-all.ps1'
    )
}

$deprecatedCommandPatterns = @(
    '^\s*&\s*gga\s+check(?:\s+--local)?(?:\s|$)',
    '^\s*gga\s+check(?:\s+--local)?(?:\s|$)'
)

$searchFiles = Get-ChildItem -Path $repoRoot -Recurse -File -Include *.md,*.ps1,*.sh,*.yml,*.yaml,*.json -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -ne $PSCommandPath } |
    Where-Object { $_.FullName -ne $policyFile }
foreach ($searchFile in $searchFiles) {
    foreach ($pattern in $deprecatedPathPatterns) {
        $foundMatches = Select-String -Path $searchFile.FullName -Pattern $pattern -SimpleMatch -ErrorAction SilentlyContinue
        foreach ($match in $foundMatches) {
            Register-StructureIssue `
                -Message "Deprecated path reference found: $(Get-RepoRelativePath -Path $match.Path):$($match.LineNumber) -> $($match.Line.Trim())" `
                -Remediation "Update to canonical command paths, or keep advisory mode until migration approval"
        }
    }

    foreach ($pattern in $deprecatedCommandPatterns) {
        $foundMatches = Select-String -Path $searchFile.FullName -Pattern $pattern -ErrorAction SilentlyContinue
        foreach ($match in $foundMatches) {
            Register-StructureIssue `
                -Message "Deprecated GGA command found: $(Get-RepoRelativePath -Path $match.Path):$($match.LineNumber) -> $($match.Line.Trim())" `
                -Remediation "Replace legacy GGA invocations with: gga run --no-cache"
        }
    }
}

# ---------------------------------------------------------------------------
# 1.1 Required governance artifacts
# ---------------------------------------------------------------------------
Write-Step "1.1 Validating governance artifacts"

$orchestratorSkillPath = Join-Path $repoRoot "skills/project-orchestrator-skill/SKILL.md"
$scriptSkillPath = Join-Path $repoRoot "skills/script-governance-skill/SKILL.md"

if (Test-Path $orchestratorSkillPath) {
    Write-Ok "skills/project-orchestrator-skill/SKILL.md"
} else {
    Write-Fail "Missing: skills/project-orchestrator-skill/SKILL.md"
    $failures++
}

if (Test-Path $scriptSkillPath) {
    Write-Ok "skills/script-governance-skill/SKILL.md"
} else {
    Write-Fail "Missing: skills/script-governance-skill/SKILL.md"
    $failures++
}

$sessionBriefExists = (Get-ChildItem -Path (Join-Path $repoRoot "docs/sessions") -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -like '*-session-start.md' -or
        $_.Name -match '^\d{4}-\d{2}-\d{2}-\d{6}-session-start\.md$'
    } |
    Measure-Object).Count -gt 0
$taskBriefExists = (Get-ChildItem -Path (Join-Path $repoRoot "docs/tasks") -Filter "*.md" -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0

if ($sessionBriefExists) {
    Write-Ok "Session start artifact exists"
} else {
    Write-Fail "Missing session start artifact under docs/sessions/*-session-start.md or docs/sessions/YYYY-MM-DD-HHmmss-session-start.md"
    $failures++
}

if ($taskBriefExists) {
    Write-Ok "Task brief artifact exists"
} else {
    Write-Fail "Missing task brief artifact under docs/tasks/*.md"
    $failures++
}

# ---------------------------------------------------------------------------
# 1.2 Toolchain availability checks (advisory by default)
# ---------------------------------------------------------------------------
Write-Step "1.2 Toolchain availability checks"

$toolChecks = @(
    @{ Name = "engram"; Remediation = "Install/repair Engram and verify with: engram version" },
    @{ Name = "gga"; Remediation = "Install/repair GGA and verify with: gga --help" },
    @{ Name = "gentle-ai"; Remediation = "Use compatibility launcher: .\\scripts\\utilities\\run-gentle-ai.ps1 status" }
)

foreach ($tool in $toolChecks) {
    $toolAvailable = $false
    $cmd = Get-Command $tool.Name -ErrorAction SilentlyContinue
    if ($null -ne $cmd) {
        $toolAvailable = $true
    } elseif ($tool.Name -eq "gentle-ai") {
        $launcherPath = Join-Path $repoRoot "scripts/utilities/run-gentle-ai.ps1"
        if (Test-Path $launcherPath) {
            $toolAvailable = $true
        }
    }

    if ($toolAvailable) {
        Write-Ok "Tool available: $($tool.Name)"
    } else {
        Register-ToolingGap -Message "Tool missing: $($tool.Name)" -Remediation $tool.Remediation
    }
}

# ---------------------------------------------------------------------------
# 2. Smoke checks with SLO enforcement
# ---------------------------------------------------------------------------
Write-Step "2. Smoke checks with SLO timing"

$wfScript       = Join-Path $repoRoot "scripts/utilities/wf.ps1"
$autoInitScript = Join-Path $repoRoot "scripts/utilities/auto-init-dev-environment.ps1"

if ($env:CI -eq 'true') {
    Write-Ok "Smoke checks skipped in CI environment (local-only checks)"
} else {
    # wf ide-status  (Level-A — startup budget)
    try {
        $elapsed = (Measure-Command {
            & powershell -NoProfile -ExecutionPolicy Bypass -File $wfScript ide-status 2>&1 | Out-Null
        }).TotalMilliseconds

        if ($LASTEXITCODE -ne 0) { throw "non-zero exit" }

        if ($elapsed -gt $SLO.StartupSafe) {
            Write-Warn "wf ide-status completed but exceeded SLO: ${elapsed}ms > $($SLO.StartupSafe)ms"
            $failures++
        } else {
            Write-Ok "wf ide-status [${elapsed}ms / SLO $($SLO.StartupSafe)ms]"
        }
    } catch {
        Write-Fail "wf ide-status smoke check failed: $_"
        $failures++
    }

    # auto-init -Quiet  (Level-A — startup budget)
    try {
        $elapsed = (Measure-Command {
            & powershell -NoProfile -ExecutionPolicy Bypass -File $autoInitScript -Quiet 2>&1 | Out-Null
        }).TotalMilliseconds

        if ($LASTEXITCODE -ne 0) { throw "non-zero exit" }

        if ($elapsed -gt $SLO.StartupSafe) {
            Write-Warn "auto-init exceeded SLO: ${elapsed}ms > $($SLO.StartupSafe)ms"
            $failures++
        } else {
            Write-Ok "auto-init -Quiet [${elapsed}ms / SLO $($SLO.StartupSafe)ms]"
        }
    } catch {
        Write-Fail "auto-init smoke check failed: $_"
        $failures++
    }
} # end CI-skip else block

# ---------------------------------------------------------------------------
# 3. Negative / fallback tests
# ---------------------------------------------------------------------------
if (-not $SkipFallbackTests) {
    Write-Step "3. Negative fallback tests"

    $detectScript = Join-Path $repoRoot "scripts/utilities/detect-ide-session.ps1"
    $tempName     = "$detectScript.__gov_bak__"

    try {
        # Rename the detection script to simulate its absence
        Rename-Item -Path $detectScript -NewName $tempName -ErrorAction Stop

        # auto-init must still exit 0 (graceful degradation, not hard crash)
        $exitCode = 0
        try {
            & powershell -NoProfile -ExecutionPolicy Bypass -File $autoInitScript -Quiet 2>&1 | Out-Null
            $exitCode = $LASTEXITCODE
        } catch {
            $exitCode = 1
        }

        if ($exitCode -eq 0) {
            Write-Ok "Fallback: auto-init survives missing detect-ide-session.ps1"
        } else {
            Write-Fail "Fallback: auto-init crashed when detect-ide-session.ps1 was missing (exit $exitCode)"
            $failures++
        }
    } catch {
        Write-Fail "Fallback test setup error: $_"
        $failures++
    } finally {
        # Always restore the script
        if (Test-Path $tempName) {
            Rename-Item -Path $tempName -NewName $detectScript -ErrorAction SilentlyContinue
        }
    }

    # Verify file was properly restored
    if (Test-Path $detectScript) {
        Write-Ok "detect-ide-session.ps1 restored"
    } else {
        Write-Fail "detect-ide-session.ps1 was NOT restored — manual fix required: rename $tempName"
        $failures++
    }
}

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------
Write-Step "Result"
if ($failures -gt 0) {
    Write-Fail "Script governance validation failed with $failures issue(s)."
    exit 1
}

Write-Ok "Script governance validation passed"
exit 0
