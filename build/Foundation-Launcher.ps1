# Foundation-Launcher.exe — Smart Launcher v2.3
# Self-contained or encrypted distribution modes
# Single .exe: embedded ZIP → AppData cache → execute
# Installed: AES-256 decryption pipeline with master.key
# Silent professional mode — no interactive prompts

param([string]$Command = "wf")

$ErrorActionPreference = "Stop"

# Self-contained mode: this placeholder is replaced by sfx-build.ps1
# with Base64-encoded ZIP of all scripts. If non-empty, embedded mode activates.
$embeddedArchiveBase64 = "__EMBEDDED_SCRIPTS__"

$appDataDir = "$env:LOCALAPPDATA\Foundation\scripts"
$dataDir = "$env:LOCALAPPDATA\Foundation\data"
$cacheScript = Join-Path $appDataDir "scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1"

function Write-Log {
    param($Message, $Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Find-File {
    param($FileName, $SearchPath)
    try {
        $result = Get-ChildItem -Path $SearchPath -Recurse -Filter $FileName -ErrorAction Stop | Select-Object -First 1
        return $result.FullName
    } catch { return $null }
}

function Decrypt-Script {
    param($EncryptedPath, $Key)
    $encryptedBase64 = Get-Content $EncryptedPath -Raw
    $combinedBytes = [Convert]::FromBase64String($encryptedBase64)
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $Key
    $aes.IV = $combinedBytes[0..15]
    $encryptedData = $combinedBytes[16..($combinedBytes.Length - 1)]
    $decryptor = $aes.CreateDecryptor()
    $decryptedBytes = $decryptor.TransformFinalBlock($encryptedData, 0, $encryptedData.Length)
    return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
}

function Extract-EmbeddedArchive {
    param([string]$Base64)
    $zipBytes = [Convert]::FromBase64String($Base64)
    $stream = [System.IO.MemoryStream]::new($zipBytes)
    try {
        $archive = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Read)
        $extracted = 0
        foreach ($entry in $archive.Entries) {
            $outPath = Join-Path $appDataDir $entry.FullName
            $outDir = Split-Path $outPath -Parent
            if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
            $reader = $entry.Open()
            $bytes = [byte[]]::new($entry.Length)
            $reader.Read($bytes, 0, $bytes.Length) | Out-Null
            $reader.Dispose()
            [System.IO.File]::WriteAllBytes($outPath, $bytes)
            $extracted++
        }
        $archive.Dispose()
        return $extracted
    } finally { $stream.Dispose() }
}

# Get base directory
$exePath = $MyInvocation.MyCommand.Path
$baseDir = if ($exePath) { Split-Path -Parent $exePath } else { Get-Location }

# Ensure AppData dirs exist
New-Item -ItemType Directory -Path $appDataDir -Force | Out-Null
New-Item -ItemType Directory -Path $dataDir -Force | Out-Null

# MODE 1: Embedded archive — single self-contained .exe
$isEmbedded = ($embeddedArchiveBase64 -ne "" -and $embeddedArchiveBase64 -ne "__EMBEDDED_SCRIPTS__")
if ($isEmbedded) {
    if (-not (Test-Path $cacheScript)) {
        Write-Log "FOUNDATION LAUNCHER: Extracting embedded scripts..." "Green"
        $count = Extract-EmbeddedArchive -Base64 $embeddedArchiveBase64
        Write-Log "FOUNDATION LAUNCHER: Extracted $count scripts to AppData" "Green"
    }
} else {
    # MODE 2: Encrypted distribution — requires master.key + protected/.enc files
    $masterKeyPaths = @(
        (Join-Path $baseDir "keys\master.key"),
        (Join-Path $baseDir "master.key"),
        (Join-Path $baseDir "..\keys\master.key")
    )
    $masterKeyPath = $null
    foreach ($path in $masterKeyPaths) { if (Test-Path $path) { $masterKeyPath = $path; break } }
    if (-not $masterKeyPath) { $masterKeyPath = Find-File "master.key" $baseDir }
    if (-not $masterKeyPath) {
        Write-Log "FOUNDATION LAUNCHER: Master key not found." "Red"
        Write-Log "Place master.key in: $baseDir\keys\master.key" "Yellow"
        exit 1
    }
    try {
        $key = [System.IO.File]::ReadAllBytes($masterKeyPath)
        if ($key.Length -ne 32) {
            Write-Log "FOUNDATION LAUNCHER: Invalid master key (expected 32 bytes, got $($key.Length))" "Red"
            exit 1
        }
    } catch { Write-Log "FOUNDATION LAUNCHER: Failed to load master.key: $_" "Red"; exit 1 }

    $encryptedBasePath = $null
    foreach ($p in @((Join-Path $baseDir "protected"), (Join-Path $baseDir "..\protected"), $baseDir)) {
        if (Test-Path (Join-Path $p "scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1.enc")) { $encryptedBasePath = $p; break }
    }
    if (-not $encryptedBasePath) {
        Write-Log "FOUNDATION LAUNCHER: No protected scripts found." "Red"
        Write-Log "Install Foundation properly first." "Yellow"
        exit 1
    }
    try {
        $encFiles = Get-ChildItem -Path $encryptedBasePath -Recurse -Filter "*.enc" -File
        $cachedCount = 0
        foreach ($encFile in $encFiles) {
            $relativePath = $encFile.FullName.Substring($encryptedBasePath.Length + 1)
            $relativePath = $relativePath -replace '\.enc$', ''
            $outputFile = Join-Path $appDataDir $relativePath
            if (-not (Test-Path $outputFile) -or (Get-Item $encFile.FullName).LastWriteTime -gt (Get-Item $outputFile -ErrorAction SilentlyContinue).LastWriteTime) {
                $outputDir = Split-Path $outputFile -Parent
                New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
                $decrypted = Decrypt-Script -EncryptedPath $encFile.FullName -Key $key
                [System.IO.File]::WriteAllText($outputFile, $decrypted, [System.Text.Encoding]::UTF8)
                $cachedCount++
            }
        }
    } catch { Write-Log "FOUNDATION LAUNCHER: Failed to cache scripts: $_" "Red"; exit 1 }
}

# Inject environment variables
$env:FOUNDATION_BASE_DIR = $baseDir
$env:FOUNDATION_APPDATA_DIR = $appDataDir
$env:FOUNDATION_DATA_DIR = $dataDir

# Execute from AppData
if (-not (Test-Path $cacheScript)) {
    Write-Log "FOUNDATION LAUNCHER: wf.ps1 not found in AppData cache." "Red"
    exit 1
}
try { & $cacheScript @args }
catch { Write-Log "FOUNDATION LAUNCHER: Failed to execute script: $_" "Red"; exit 1 }
