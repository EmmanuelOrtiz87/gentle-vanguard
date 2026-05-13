# sfx-build.ps1 — Builds portable Foundation.exe (DEPRECATED)
# Embeds encrypted (.enc) files as compressed ZIP, compiles with ps2exe.
# Output: dist/Foundation.exe (portable, no installation).
#
# ⚠️ DEPRECATED: Use create-installer.ps1 instead.
#    Foundation.exe is now the NSIS installer (professional wizard, all-in-one).
#    This portable approach no longer represents the canonical distribution.
#    Kept for reference only.
#
# Usage: pwsh -File build/sfx-build.ps1

param([switch]$DryRun)

$ErrorActionPreference = 'Stop'

if ($env:FOUNDATION_BASE_DIR) { $repoRoot = $env:FOUNDATION_BASE_DIR }
else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $repoRoot = $searchDir
}

$buildDir = Join-Path $repoRoot 'build'
$distDir = Join-Path $repoRoot 'dist'
$protectedDir = Join-Path $buildDir 'protected'
$launcherPs1 = Join-Path $buildDir 'Foundation-Launcher.ps1'
$outExe = Join-Path $distDir 'Foundation.exe'

function Write-Step { param([string]$msg) Write-Host "[SFX] $msg" -ForegroundColor Cyan }
function Write-OK  { param([string]$msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn{ param([string]$msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow }

# Step 1: Ensure encrypted files exist
Write-Step "Step 1: Checking encrypted files"
if (-not (Test-Path $protectedDir)) {
    throw "build/protected/ not found — run protect-foundation.ps1 first"
}
$encFiles = Get-ChildItem -Path $protectedDir -Recurse -Filter "*.enc" -File
if ($encFiles.Count -eq 0) {
    throw "No .enc files found in build/protected/"
}
Write-OK "Found $($encFiles.Count) encrypted files ($([math]::Round(($encFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB)"

# Step 2: Create ZIP of encrypted files
Write-Step "Step 2: Compressing encrypted files"
$zipStream = [System.IO.MemoryStream]::new()
$zip = [System.IO.Compression.ZipArchive]::new($zipStream, [System.IO.Compression.ZipArchiveMode]::Create, $true)
$totalIn = 0
foreach ($file in $encFiles) {
    $relativePath = $file.FullName.Substring($protectedDir.Length + 1)
    $entry = $zip.CreateEntry($relativePath, [System.IO.Compression.CompressionLevel]::Optimal)
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $entryStream = $entry.Open()
    $entryStream.Write($bytes, 0, $bytes.Length)
    $entryStream.Dispose()
    $totalIn += $bytes.Length
}
$zip.Dispose()
$zipBytes = $zipStream.ToArray()
$zipStream.Dispose()
$base64 = [Convert]::ToBase64String($zipBytes, [System.Base64FormattingOptions]::None)
Write-OK "Compressed: $([math]::Round($totalIn/1MB,2)) MB → $([math]::Round($zipBytes.Length/1MB,2)) MB ZIP → $([math]::Round($base64.Length/1MB,2)) MB Base64"

# Step 3: Embed in launcher
Write-Step "Step 3: Embedding in launcher"
$launcherContent = Get-Content $launcherPs1 -Raw
$embeddedLine = '$embeddedArchiveBase64 = "__EMBEDDED_SCRIPTS__"'
$replacementLine = '$embeddedArchiveBase64 = "' + $base64 + '"'
if (-not $launcherContent.Contains($embeddedLine)) {
    Write-Warn "Placeholder not found — appending"
    $launcherContent += "`r`n$replacementLine"
} else {
    $launcherContent = $launcherContent.Replace($embeddedLine, $replacementLine)
}
$tempPs1 = Join-Path $buildDir 'Foundation-SFX.ps1'
[System.IO.File]::WriteAllText($tempPs1, $launcherContent, [System.Text.Encoding]::UTF8)
Write-OK "Embedded $($base64.Length) chars of encrypted data"

# Step 4: Compile with ps2exe
Write-Step "Step 4: Compiling to executable"
$ps2exe = Get-Command ps2exe -ErrorAction SilentlyContinue
if (-not $ps2exe) { throw "ps2exe not found — Install-Module ps2exe -Scope CurrentUser" }
if (-not $DryRun) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
    & ps2exe -inputFile $tempPs1 -outputFile $outExe -noConsole -requireAdmin -title "Foundation" -description "Foundation Framework Launcher v2.3 (AES-256)" -product "Foundation" -copyright "Gentleman Foundation"
    if (Test-Path $outExe) {
        $size = [math]::Round((Get-Item $outExe).Length / 1MB, 2)
        Write-OK "Foundation.exe compiled: $outExe ($size MB)"
        Remove-Item $tempPs1 -Force
    } else { throw "ps2exe did not produce output" }
} else { Write-Warn "Dry run — would compile to $outExe" }

Write-Step "Done!"
Write-Host "  Output: $outExe ($size MB)" -ForegroundColor Green
Write-Host "  Security: AES-256 encrypted — master.key required on first run" -ForegroundColor Green
Write-Host "  Usage: Just run Foundation.exe (key cached after first use)" -ForegroundColor Green
