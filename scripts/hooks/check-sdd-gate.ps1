# check-sdd-gate.ps1
# FF-001: SDD CI Hardening - validates that staged changes have an associated
# SDD document with status `validated` or `done` before allowing a commit/push
# to protected branches (main, develop).
#
# Behaviour:
#   - No SDD docs in docs/sdd/ -> advisory (not blocking), warns author.
#   - SDD found but status is 'draft' -> blocking for main; advisory for develop.
#   - SDD found with status 'validated' or 'done' -> pass.
#   - Skips gate if commit is on a feature/bugfix/chore branch (not protected).
#
# Usage: called by pre-commit / pre-push hooks, or directly for local validation.

$ErrorActionPreference = 'Continue'

# FF-015: hook output safety
$_safety = Join-Path $PSScriptRoot 'hook-output-safety.ps1'
if (Test-Path $_safety) { . $_safety }
function _Wh { param([string]$M, [string]$C = 'White')
    if (Get-Command 'Write-SafeHook' -EA SilentlyContinue) { Write-SafeHook $M -Color $C }
    else { Write-Host $M -ForegroundColor $C }
}

# FF-003: advisory vs blocking classifier
$_classifier = Join-Path $PSScriptRoot 'hook-advisory-classifier.ps1'
if (Test-Path $_classifier) { . $_classifier }

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }

# --- Determine current branch ------------------------------------------------
$branch = git rev-parse --abbrev-ref HEAD 2>$null
$isProtected = $branch -in @('main', 'develop')
$isMain = $branch -eq 'main'

# If not on a protected branch, skip gate entirely
if (-not $isProtected) {
    _Wh "[SDD-GATE] Branch '$branch' is not protected - gate skipped." Gray
    exit 0
}

# --- Discover SDD docs -------------------------------------------------------
$sddDir = Join-Path $repoRoot 'docs/sdd'
if (-not (Test-Path $sddDir)) {
    if (Get-Command 'Add-AdvisoryFinding' -EA SilentlyContinue) {
        Add-AdvisoryFinding "SDD-GATE: docs/sdd/ directory not found. Create at least one SDD for protected branches."
        Exit-HookCheck "sdd-gate"
    } else {
        _Wh "[SDD-GATE] ADVISORY: docs/sdd/ not found. Consider adding SDD documents." Yellow
        exit 0
    }
}

$sddFiles = Get-ChildItem -Path $sddDir -Filter '*.md' -File -ErrorAction SilentlyContinue
if (-not $sddFiles -or $sddFiles.Count -eq 0) {
    if (Get-Command 'Add-AdvisoryFinding' -EA SilentlyContinue) {
        Add-AdvisoryFinding "SDD-GATE: No SDD documents found in docs/sdd/. Add a spec before merging to protected branches."
        Exit-HookCheck "sdd-gate"
    } else {
        _Wh "[SDD-GATE] ADVISORY: No SDD files in docs/sdd/." Yellow
        exit 0
    }
}

# --- Parse SDD statuses ------------------------------------------------------
$allStatuses = @()
foreach ($sddFile in $sddFiles) {
    $content = Get-Content -Path $sddFile.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    # Look for "**Status:**" or "status:" in YAML-like front matter or body
    if ($content -match '(?im)^\*\*Status\*\*:\s*(.+)$') {
        $allStatuses += [pscustomobject]@{ File = $sddFile.Name; Status = $matches[1].Trim().ToLower() }
    } elseif ($content -match '(?im)^status:\s*(.+)$') {
        $allStatuses += [pscustomobject]@{ File = $sddFile.Name; Status = $matches[1].Trim().ToLower() }
    } else {
        $allStatuses += [pscustomobject]@{ File = $sddFile.Name; Status = 'unknown' }
    }
}

_Wh "[SDD-GATE] Branch: $branch | SDD docs found: $($allStatuses.Count)" Cyan

$draftDocs = @($allStatuses | Where-Object { $_.Status -notin @('validated', 'done', 'active') })
$validDocs  = @($allStatuses | Where-Object { $_.Status -in @('validated', 'done', 'active') })

_Wh "[SDD-GATE] Valid (validated/done/active): $($validDocs.Count) | Draft/Unknown: $($draftDocs.Count)" Cyan

# --- Gate decision ------------------------------------------------------------
if ($validDocs.Count -eq 0 -and $draftDocs.Count -gt 0) {
    $draftList = ($draftDocs | ForEach-Object { "$($_.File) [status: $($_.Status)]" }) -join ', '

    if ($isMain) {
        # main: blocking - must have at least one validated/done SDD
        if (Get-Command 'Add-BlockingFinding' -EA SilentlyContinue) {
            Add-BlockingFinding "SDD-GATE: No SDD with status 'validated' or 'done' found before merging to main. Drafts: $draftList"
            Exit-HookCheck "sdd-gate"
        } else {
            _Wh "[SDD-GATE] BLOCKING: Merging to main requires a validated/done SDD. Drafts: $draftList" Red
            exit 1
        }
    } else {
        # develop: advisory
        if (Get-Command 'Add-AdvisoryFinding' -EA SilentlyContinue) {
            Add-AdvisoryFinding "SDD-GATE: All SDDs are in draft state on develop. Update spec status before merging to main. Drafts: $draftList"
            Exit-HookCheck "sdd-gate"
        } else {
            _Wh "[SDD-GATE] ADVISORY: All SDDs are drafts - update before merging to main. Drafts: $draftList" Yellow
            exit 0
        }
    }
}

_Wh "[SDD-GATE] PASS - at least one validated/done SDD present." Green
exit 0
