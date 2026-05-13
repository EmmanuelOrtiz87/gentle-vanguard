# protect-foundation.ps1
# Encrypts core scripts with AES-256, generates loader.ps1, and prepares
# the build/protected directory for NSIS packaging.
# Usage: pwsh -File build/protect-foundation.ps1 [-KeyPath keys/master.key] [-DryRun]

param(
    [string]$KeyPath = '',
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

#region RepoRoot Resolution
if ($env:FOUNDATION_BASE_DIR) {
    $repoRoot = $env:FOUNDATION_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $repoRoot = $searchDir
}
#endregion

$buildDir = Join-Path $repoRoot 'build'
$protectedDir = Join-Path $buildDir 'protected'
$publicDir = Join-Path $buildDir 'public'
$distDir = Join-Path $repoRoot 'dist'
$keysDir = Join-Path $repoRoot 'keys'

function Write-Step { param([string]$msg) Write-Host "[PROTECT] $msg" -ForegroundColor Cyan }
function Write-OK { param([string]$msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow }

#region Step 1: Generate or validate master.key
Write-Step "Step 1: Master key"

if (-not $KeyPath) {
    $KeyPath = Join-Path $keysDir 'master.key'
}

if (Test-Path $KeyPath) {
    $existingKey = [System.IO.File]::ReadAllBytes($KeyPath)
    if ($existingKey.Length -ne 32) {
        throw "Existing master.key is $($existingKey.Length) bytes (expected 32). Delete or fix it."
    }
    Write-OK "Using existing master.key ($KeyPath)"
    $masterKey = $existingKey
} else {
    if ($DryRun) {
        Write-Warn "Dry run: would generate new master.key at $KeyPath"
        $masterKey = [byte[]]::new(32)
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($masterKey)
    } else {
        New-Item -ItemType Directory -Path (Split-Path $KeyPath -Parent) -Force | Out-Null
        $masterKey = [byte[]]::new(32)
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($masterKey)
        [System.IO.File]::WriteAllBytes($KeyPath, $masterKey)
        Write-OK "Generated new master.key at $KeyPath"
    }
}
#endregion

#region Step 2: Define what to encrypt
Write-Step "Step 2: Collecting scripts to encrypt"

$includeDirs = @(
    'scripts\adaptive'
    'scripts\common'
    'scripts\diagnostics'
    'scripts\foundation'
    'scripts\git-hooks'
    'scripts\hooks'
    'scripts\monitoring'
    'scripts\security'
    'scripts\utilities'
    'scripts\validation'
)

$excludePatterns = @(
    '*.tests.ps1'
    '*.test.ps1'
)

$filesToEncrypt = @()
foreach ($dir in $includeDirs) {
    $fullDir = Join-Path $repoRoot ($dir -replace '/', '\')
    if (Test-Path $fullDir) {
        $files = Get-ChildItem -Path $fullDir -Recurse -Filter '*.ps1' -File
        foreach ($file in $files) {
            $skip = $false
            foreach ($pattern in $excludePatterns) {
                if ($file.Name -like $pattern) { $skip = $true; break }
            }
            if (-not $skip) {
                $filesToEncrypt += $file
            }
        }
    }
}

$includeConfigs = @(
    'config\auto-delegation.json'
    'config\behavior-prompts.json'
    'config\metrics-config.json'
    'config\session-autostart.config.json'
    'config\skill-dependencies.json'
    'config\subagent-mapping.json'
)

foreach ($cfg in $includeConfigs) {
    $fullPath = Join-Path $repoRoot ($cfg -replace '/', '\')
    if (Test-Path $fullPath) {
        $filesToEncrypt += Get-Item $fullPath
    }
}

Write-OK "Collected $($filesToEncrypt.Count) files to encrypt"
#endregion

#region Step 3: Encrypt files
Write-Step "Step 3: Encrypting files with AES-256"

if (-not $DryRun) {
    New-Item -ItemType Directory -Path $protectedDir -Force | Out-Null
}

function Protect-File {
    param(
        [string]$SourcePath,
        [string]$DestPath,
        [byte[]]$Key
    )

    $content = [System.IO.File]::ReadAllBytes($SourcePath)

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $Key
    $aes.GenerateIV()
    $encryptor = $aes.CreateEncryptor()

    $encryptedData = $encryptor.TransformFinalBlock($content, 0, $content.Length)
    $result = New-Object byte[] ($aes.IV.Length + $encryptedData.Length)
    [Array]::Copy($aes.IV, $result, $aes.IV.Length)
    [Array]::Copy($encryptedData, 0, $result, $aes.IV.Length, $encryptedData.Length)

    $destDir = Split-Path $DestPath -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $resultBase64 = [Convert]::ToBase64String($result)
    [System.IO.File]::WriteAllText($DestPath, $resultBase64, [System.Text.Encoding]::ASCII)
}

$encrypted = 0
foreach ($file in $filesToEncrypt) {
    $relativePath = $file.FullName.Substring($repoRoot.Length + 1)
    $destPath = Join-Path $protectedDir "$relativePath.enc"

    if ($DryRun) {
        Write-Warn "Would encrypt: $relativePath"
    } else {
        Protect-File -SourcePath $file.FullName -DestPath $destPath -Key $masterKey
        $encrypted++
    }
}
Write-OK "Encrypted $encrypted files"
#endregion

#region Step 4: Copy public skill stubs
Write-Step "Step 4: Copying public skill stubs"

if (-not $DryRun) {
    New-Item -ItemType Directory -Path $publicDir -Force | Out-Null
}

$skillDirs = Get-ChildItem (Join-Path $repoRoot 'skills') -Directory -ErrorAction SilentlyContinue
$copied = 0
foreach ($skill in $skillDirs) {
    $skillFile = Join-Path $skill.FullName 'SKILL.md'
    if (Test-Path $skillFile) {
        $destDir = Join-Path $publicDir "skills\$($skill.Name)"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            Copy-Item $skillFile (Join-Path $destDir 'SKILL.md') -Force
            $copied++
        }
    }
}
Write-OK "Copied $copied skill stubs"
#endregion

#region Step 5: Copy launcher
Write-Step "Step 5: Preparing launcher"

$launcherSource = Join-Path $buildDir 'Foundation-Launcher.ps1'
if (Test-Path $launcherSource) {
    if (-not $DryRun) {
        Copy-Item $launcherSource (Join-Path $buildDir 'loader.ps1') -Force
        Write-OK "Launcher copied to loader.ps1"
    }
} else {
    Write-Warn "Foundation-Launcher.ps1 not found in build/"
}
#endregion

#region Step 6: Generate integrity manifest
Write-Step "Step 6: Generating integrity manifest"

$manifest = @{
    version = (Get-Content (Join-Path $repoRoot 'VERSION') -ErrorAction SilentlyContinue) ?? '2.9.0'
    timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    encrypted_files = $encrypted
    public_skills = $copied
    sha256_manifest = @{}
}

if (-not $DryRun) {
    $encFiles = Get-ChildItem $protectedDir -Recurse -Filter '*.enc' -File
    foreach ($f in $encFiles) {
        $hash = (Get-FileHash $f.FullName -Algorithm SHA256).Hash
        $rel = $f.FullName.Substring($protectedDir.Length + 1)
        $manifest.sha256_manifest[$rel] = $hash
    }

    $manifestPath = Join-Path $buildDir 'integrity-manifest.json'
    $manifest | ConvertTo-Json -Depth 5 | Set-Content $manifestPath -Encoding UTF8NoBOM
    Write-OK "Integrity manifest: $($manifest.sha256_manifest.Count) file hashes"
}
#endregion

Write-Step "Done!"
Write-Host ""
Write-Host "  Encrypted files: $encrypted" -ForegroundColor Green
Write-Host "  Public skills:   $copied" -ForegroundColor Green
Write-Host "  Output dir:      $protectedDir" -ForegroundColor Green
Write-Host "  Master key:      $KeyPath" -ForegroundColor Green
if ($DryRun) {
    Write-Host "  [DRY RUN] No files were written" -ForegroundColor Yellow
}