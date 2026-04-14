param(
    [ValidateSet('check', 'apply')]
    [string]$Mode = 'check',

    [string]$ManifestPath = '',
    [string]$FoundationPath = '',

    # When set, apply also creates a PR (branch + commit + gh pr create)
    [switch]$CreatePR,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Resolve-AbsolutePath {
    param(
        [string]$BasePath,
        [string]$Candidate
    )

    if ([string]::IsNullOrWhiteSpace($Candidate)) {
        return ''
    }

    if ([System.IO.Path]::IsPathRooted($Candidate)) {
        return [System.IO.Path]::GetFullPath($Candidate)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Candidate))
}

function Get-AssetStrategy {
    param($Asset)
    $raw = if ($Asset.PSObject.Properties['strategy']) { [string]$Asset.strategy } else { '' }
    switch ($raw.ToLowerInvariant()) {
        'preserve-local' { return 'preserve-local' }
        default           { return 'replace' }
    }
}

try {
    if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
        $ManifestPath = Join-Path $repoRoot 'config/foundation-sync.json'
    } else {
        $ManifestPath = Resolve-AbsolutePath -BasePath $repoRoot -Candidate $ManifestPath
    }

    if (-not (Test-Path $ManifestPath)) {
        Write-ErrorMessage "Foundation sync manifest not found: $ManifestPath"
        Write-Host "Create config/foundation-sync.json and try again."
        exit 1
    }

    $manifestRaw = Get-Content -Path $ManifestPath -Raw -Encoding UTF8
    $manifest = $manifestRaw | ConvertFrom-Json

    $role = if ($manifest.PSObject.Properties['role']) { [string]$manifest.role } else { 'consumer' }
    if ($role -eq 'source') {
        Write-Success 'This repository is marked as foundation source. Nothing to sync here.'
        exit 0
    }

    $fromVersion = if ($manifest.PSObject.Properties['fromVersion']) { [string]$manifest.fromVersion } else { '' }
    $toVersion   = if ($manifest.PSObject.Properties['toVersion'])   { [string]$manifest.toVersion }   else { '' }

    if ([string]::IsNullOrWhiteSpace($FoundationPath)) {
        if ($manifest.PSObject.Properties['foundationPath'] -and -not [string]::IsNullOrWhiteSpace([string]$manifest.foundationPath)) {
            $FoundationPath = [string]$manifest.foundationPath
        } elseif ($env:FOUNDATION_REPO_PATH) {
            $FoundationPath = [string]$env:FOUNDATION_REPO_PATH
        } else {
            $FoundationPath = '..\workspace-foundation'
        }
    }

    $foundationRoot = Resolve-AbsolutePath -BasePath $repoRoot -Candidate $FoundationPath
    if (-not (Test-Path $foundationRoot)) {
        Write-ErrorMessage "Foundation path not found: $foundationRoot"
        Write-Host "Pass -FoundationPath <path> or set FOUNDATION_REPO_PATH."
        exit 1
    }

    # Resolve current foundation version from its own manifest
    $foundationManifestPath = Join-Path $foundationRoot 'config/foundation-sync.json'
    $currentFoundationVersion = ''
    if (Test-Path $foundationManifestPath) {
        $fm = (Get-Content $foundationManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json)
        if ($fm.PSObject.Properties['foundationVersion']) {
            $currentFoundationVersion = [string]$fm.foundationVersion
        }
    }

    $assets = @()
    if ($manifest.PSObject.Properties['assets'] -and $manifest.assets) {
        $assets = @($manifest.assets)
    }

    if ($assets.Count -eq 0) {
        Write-Warning 'No assets defined in foundation sync manifest.'
        exit 0
    }

    Write-Step "Foundation sync ($Mode)"
    Write-Host "Manifest:          $ManifestPath"
    Write-Host "Foundation:        $foundationRoot"
    Write-Host "Target:            $repoRoot"
    if (-not [string]::IsNullOrWhiteSpace($fromVersion))             { Write-Host "From version:      $fromVersion" }
    if (-not [string]::IsNullOrWhiteSpace($toVersion))               { Write-Host "To version:        $toVersion" }
    if (-not [string]::IsNullOrWhiteSpace($currentFoundationVersion)) { Write-Host "Foundation latest: $currentFoundationVersion" }

    $results = @()

    foreach ($asset in $assets) {
        $sourceRel = [string]$asset.source
        if ([string]::IsNullOrWhiteSpace($sourceRel)) {
            continue
        }

        $targetRel = if ($asset.PSObject.Properties['target'] -and -not [string]::IsNullOrWhiteSpace([string]$asset.target)) {
            [string]$asset.target
        } else {
            $sourceRel
        }

        $strategy  = Get-AssetStrategy -Asset $asset

        $sourceAbs = [System.IO.Path]::GetFullPath((Join-Path $foundationRoot $sourceRel))
        $targetAbs = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $targetRel))

        if (-not (Test-Path $sourceAbs)) {
            $results += [pscustomobject]@{ Source = $sourceRel; Target = $targetRel; Strategy = $strategy; Status = 'missing-source' }
            continue
        }

        if (-not (Test-Path $targetAbs)) {
            if ($strategy -eq 'preserve-local') {
                $results += [pscustomobject]@{ Source = $sourceRel; Target = $targetRel; Strategy = $strategy; Status = 'preserve-no-target' }
            } else {
                $results += [pscustomobject]@{ Source = $sourceRel; Target = $targetRel; Strategy = $strategy; Status = 'missing-target' }
            }
            continue
        }

        if ($strategy -eq 'preserve-local') {
            $results += [pscustomobject]@{ Source = $sourceRel; Target = $targetRel; Strategy = $strategy; Status = 'preserved' }
            continue
        }

        $sourceHash = (Get-FileHash -Path $sourceAbs -Algorithm SHA256).Hash
        $targetHash = (Get-FileHash -Path $targetAbs -Algorithm SHA256).Hash

        $status = if ($sourceHash -eq $targetHash) { 'up-to-date' } else { 'drift' }
        $results += [pscustomobject]@{ Source = $sourceRel; Target = $targetRel; Strategy = $strategy; Status = $status }
    }

    $drifted      = @($results | Where-Object { $_.Status -in @('drift', 'missing-target') })
    $missingSource = @($results | Where-Object { $_.Status -eq 'missing-source' })
    $upToDate     = @($results | Where-Object { $_.Status -eq 'up-to-date' })
    $preserved    = @($results | Where-Object { $_.Status -in @('preserved', 'preserve-no-target') })

    foreach ($row in $results) {
        switch ($row.Status) {
            'up-to-date'        { Write-Host "[OK]     $($row.Target)  [strategy=$($row.Strategy)]" -ForegroundColor Green }
            'drift'             { Write-Host "[DIFF]   $($row.Target) <= $($row.Source)  [strategy=$($row.Strategy)]" -ForegroundColor Yellow }
            'missing-target'    { Write-Host "[MISS]   $($row.Target) <= $($row.Source)  [strategy=$($row.Strategy)]" -ForegroundColor Yellow }
            'missing-source'    { Write-Host "[ERR]    source missing: $($row.Source)" -ForegroundColor Red }
            'preserved'         { Write-Host "[KEEP]   $($row.Target)  [strategy=preserve-local]" -ForegroundColor DarkGray }
            'preserve-no-target' { Write-Host "[KEEP]   $($row.Target) not found locally - skipped  [strategy=preserve-local]" -ForegroundColor DarkGray }
        }
    }

    Write-Host "`nSummary: up-to-date=$($upToDate.Count)  to-update=$($drifted.Count)  preserved=$($preserved.Count)  source-errors=$($missingSource.Count)"

    if ($Mode -eq 'check') {
        if ($missingSource.Count -gt 0) { exit 1 }

        if ($drifted.Count -eq 0) {
            Write-Success 'Foundation sync check: no changes required.'
        } else {
            Write-Warning "Foundation sync check detected $($drifted.Count) file(s) to update."
            Write-Host "Run: .\scripts\utilities\wf.ps1 foundation-sync apply"
            Write-Host "     .\scripts\utilities\wf.ps1 foundation-sync apply -CreatePr   (auto PR)"
        }
        exit 0
    }

    # --- APPLY ---

    if ($missingSource.Count -gt 0) {
        Write-ErrorMessage 'Cannot apply while source files are missing in foundation.'
        exit 1
    }

    if ($drifted.Count -eq 0) {
        Write-Success 'Nothing to apply. Target already aligned with foundation.'
        exit 0
    }

    $dirty = git status --porcelain 2>$null
    if (-not [string]::IsNullOrWhiteSpace($dirty) -and -not $Force -and -not $CreatePR) {
        Write-ErrorMessage 'Working tree has local changes. Re-run with -Force or -CreatePR.'
        exit 1
    }

    $syncBranch = ''
    if ($CreatePR) {
        $dateStamp  = (Get-Date -Format 'yyyyMMdd')
        $syncBranch = "chore/foundation-sync-$dateStamp"
        $existing   = git branch --list $syncBranch 2>$null
        if ($existing) {
            $syncBranch = "chore/foundation-sync-$dateStamp-$(Get-Random -Maximum 999)"
        }

        git checkout -b $syncBranch 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMessage "Could not create sync branch: $syncBranch"
            exit 1
        }
        Write-Success "Created sync branch: $syncBranch"
    }

    foreach ($row in $drifted) {
        $sourceAbs = [System.IO.Path]::GetFullPath((Join-Path $foundationRoot $row.Source))
        $targetAbs = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $row.Target))
        $targetDir = Split-Path -Parent $targetAbs
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        Copy-Item -Path $sourceAbs -Destination $targetAbs -Force
        Write-Success "Synced: $($row.Target)"
    }

    if ($CreatePR) {
        $fvLabel = if (-not [string]::IsNullOrWhiteSpace($currentFoundationVersion)) { " v$currentFoundationVersion" } else { '' }
        $fileCount = $drifted.Count
        $commitMsg = 'chore(foundation-sync): sync' + $fvLabel + ' managed assets (' + $fileCount + ' files)'

        git add . 2>&1 | Out-Null
        git commit -m $commitMsg 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMessage 'Commit failed during foundation-sync apply -CreatePr.'
            exit 1
        }

        git push -u origin $syncBranch 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMessage ('Push of sync branch ' + $syncBranch + ' failed.')
            exit 1
        }

        $fileLines = ($drifted | ForEach-Object { '- ' + $_.Target }) -join "`n"
        $prBody = "## Foundation Sync`n`n" +
            "Automated sync of foundation-managed assets.`n`n" +
            "- Foundation version: $currentFoundationVersion`n" +
            "- Files updated: $fileCount`n" +
            "- Manifest: config/foundation-sync.json`n`n" +
            "### Files`n$fileLines`n`n" +
            '> Review and merge to complete the foundation update.'
        $prBodyFile = [System.IO.Path]::GetTempFileName()
        $prBody | Out-File -FilePath $prBodyFile -Encoding UTF8

        gh pr create --base develop --head $syncBranch --title $commitMsg --body-file $prBodyFile

        Remove-Item $prBodyFile -Force -ErrorAction SilentlyContinue

        if ($LASTEXITCODE -ne 0) {
            Write-Warning ('PR creation failed. Branch ' + $syncBranch + ' is pushed -- create PR manually.')
            exit 1
        }

        Write-Success ('Foundation sync PR created from branch ' + $syncBranch + ' -> develop.')
    } else {
        Write-Success "Foundation sync apply complete. Updated $($drifted.Count) file(s)."
    }

    exit 0
}
catch {
    Write-ErrorMessage $_.Exception.Message
    exit 1
}
