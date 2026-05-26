param(
    [string]$WorkspaceRoot = ".",
    [switch]$AsJson
)

$ErrorActionPreference = 'Continue'

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

function Write-Result {
    param([string]$Status, [string]$Message, [hashtable]$Data = @{})
    if ($AsJson) {
        $result = @{ status = $Status; message = $Message; timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss") }
        foreach ($key in $Data.Keys) { $result[$key] = $Data[$key] }
        Write-Output ($result | ConvertTo-Json -Compress)
    } else {
        $color = if ($Status -eq "OK") { "Green" } elseif ($Status -eq "WARN") { "Yellow" } else { "Red" }
        Write-Host "[$Status] $Message" -ForegroundColor $color
    }
}

$lefthookCmd = Get-Command lefthook -ErrorAction SilentlyContinue
$gitDir = Join-Path $repoRoot ".git"
$hooksDir = Join-Path $gitDir "hooks"
$requiredHooks = @("pre-commit", "commit-msg", "pre-push", "post-commit", "post-merge")

if (-not $lefthookCmd) {
    Write-Result "WARN" "Lefthook CLI not found in PATH. Hooks (post-commit/post-merge) will NOT run." @{ lefthook = "missing"; action = "verify" }
    exit 0
}

if (-not (Test-Path $gitDir)) {
    Write-Result "WARN" "Not a git repository. Skipping hook verification." @{ lefthook = $lefthookCmd.Source; action = "verify" }
    exit 0
}

$missingHooks = @()
foreach ($hook in $requiredHooks) {
    $hookPath = Join-Path $hooksDir $hook
    if (-not (Test-Path $hookPath)) {
        $missingHooks += $hook
    }
}

$hooksFile = Join-Path $repoRoot ".lefthook.yml"
$hooksConfigOk = Test-Path $hooksFile

if ($missingHooks.Count -eq 0 -and $hooksConfigOk) {
    Write-Result "OK" "Lefthook v$(lefthook version 2>&1) — all hooks installed: $($requiredHooks -join ', ')" @{ lefthook = $lefthookCmd.Source; version = (lefthook version 2>&1); hooks = ($requiredHooks -join ','); action = "verify" }
} else {
    if ($missingHooks.Count -gt 0) {
        Write-Result "WARN" "Missing hooks: $($missingHooks -join ', '). Run 'lefthook install' to fix." @{ lefthook = $lefthookCmd.Source; missing = ($missingHooks -join ','); action = "verify" }
    }
    if (-not $hooksConfigOk) {
        Write-Result "WARN" ".lefthook.yml not found. Hooks config missing." @{ lefthook = $lefthookCmd.Source; action = "verify" }
    }
}

exit 0
