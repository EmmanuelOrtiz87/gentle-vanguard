# Gentle-Vanguard-Launcher.exe — Smart Launcher v2.3
# Dual-mode: embedded encrypted archive (single .exe) + file-based .enc (installed)
# AES-256 decryption with master.key caching — secure single-file distribution
# Silent professional mode — no interactive prompts except first-run key input

param([string]$Command = "gv")

$ErrorActionPreference = "Stop"

# Self-contained mode: placeholder replaced by sfx-build.ps1 with Base64-encoded
# ZIP of encrypted (.enc) files. If non-empty, embedded mode activates.
$embeddedArchiveBase64 = "__EMBEDDED_SCRIPTS__"

$appDataDir = "$env:LOCALAPPDATA\Gentle-Vanguard\scripts"
$dataDir = "$env:LOCALAPPDATA\Gentle-Vanguard\data"
$cacheKeyPath = Join-Path $dataDir "master.key"
$cacheScript = Join-Path $appDataDir "scripts\utilities\WORKFLOW-ORCHESTRATION\gv.ps1"
$embeddedTempDir = Join-Path $env:TEMP "Gentle-Vanguard\embedded"

function Write-Log {
    param($Message, $Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Read-Host-Safe {
    # Read-Host wrapper that works in both console and noConsole modes
    try { return Read-Host @args } catch { return $null }
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

function Decrypt-Bytes {
    param([byte[]]$Data, [byte[]]$Key)
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $Key
    $aes.IV = $Data[0..15]
    $encryptedData = $Data[16..($Data.Length - 1)]
    $decryptor = $aes.CreateDecryptor()
    return $decryptor.TransformFinalBlock($encryptedData, 0, $encryptedData.Length)
}

function Extract-EncryptedArchive {
    param([string]$Base64, [string]$OutDir)
    $zipBytes = [Convert]::FromBase64String($Base64)
    $stream = [System.IO.MemoryStream]::new($zipBytes)
    try {
        $archive = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Read)
        $extracted = 0
        foreach ($entry in $archive.Entries) {
            $outPath = Join-Path $OutDir $entry.FullName
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

function Resolve-MasterKey {
    # Returns byte[] key or $null
    # Order: AppData cache → next to exe → user prompt
    $keyPaths = @(
        $cacheKeyPath,
        (Join-Path $baseDir "master.key"),
        (Join-Path $baseDir "keys\master.key"),
        (Join-Path $baseDir "..\keys\master.key")
    )
    foreach ($p in $keyPaths) {
        if (Test-Path $p) {
            $bytes = [System.IO.File]::ReadAllBytes($p)
            if ($bytes.Length -eq 32) { return $bytes }
        }
    }
    # Recursive search in base dir
    $found = Find-File "master.key" $baseDir
    if ($found) {
        $bytes = [System.IO.File]::ReadAllBytes($found)
        if ($bytes.Length -eq 32) { return $bytes }
    }
    return $null
}

function Prompt-For-Key {
    Write-Log "`nGENTLE_VANGUARD LAUNCHER: First-time setup" "Cyan"
    Write-Log "No master.key found. This exe contains encrypted scripts." "Yellow"
    Write-Log "Enter the master.key contents (Base64, 32 bytes):" "Yellow"
    $input = Read-Host-Safe "> "
    if (-not $input) { return $null }
    $input = $input.Trim()
    try {
        $bytes = [Convert]::FromBase64String($input)
        if ($bytes.Length -ne 32) {
            Write-Log "Invalid key: expected 32 bytes, got $($bytes.Length)" "Red"
            return $null
        }
        # Cache for next run
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
        [System.IO.File]::WriteAllBytes($cacheKeyPath, $bytes)
        Write-Log "Key cached to $cacheKeyPath" "Green"
        return $bytes
    } catch {
        Write-Log "Invalid Base64: $_" "Red"
        return $null
    }
}

# Get base directory
$exePath = $MyInvocation.MyCommand.Path
$baseDir = if ($exePath) { Split-Path -Parent $exePath } else { Get-Location }

# Ensure AppData dirs exist
New-Item -ItemType Directory -Path $appDataDir -Force | Out-Null
New-Item -ItemType Directory -Path $dataDir -Force | Out-Null

# Detect mode
$isEmbedded = ($embeddedArchiveBase64 -ne "" -and $embeddedArchiveBase64 -ne "__EMBEDDED_SCRIPTS__")

if ($isEmbedded -and -not (Test-Path $cacheScript)) {
    # MODE 1: Embedded encrypted archive — extract .enc files to temp
    Write-Log "GENTLE_VANGUARD LAUNCHER: Extracting encrypted scripts from archive..." "Green"
    if (Test-Path $embeddedTempDir) { Remove-Item $embeddedTempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $embeddedTempDir -Force | Out-Null
    $count = Extract-EncryptedArchive -Base64 $embeddedArchiveBase64 -OutDir $embeddedTempDir
    Write-Log "GENTLE_VANGUARD LAUNCHER: Extracted $count encrypted files" "Green"
    $encryptedBasePath = $embeddedTempDir
    $isEmbeddedEncrypted = $true
} elseif ($isEmbedded) {
    # Already cached — AppData has decrypted scripts, skip
    $isEmbeddedEncrypted = $false
} else {
    # MODE 2: File-based encrypted distribution
    $isEmbeddedEncrypted = $false
    foreach ($p in @((Join-Path $baseDir "protected"), (Join-Path $baseDir "..\protected"), $baseDir)) {
        if (Test-Path (Join-Path $p "scripts\utilities\WORKFLOW-ORCHESTRATION\gv.ps1.enc")) {
            $encryptedBasePath = $p; break
        }
    }
    if (-not $encryptedBasePath) {
        Write-Log "GENTLE_VANGUARD LAUNCHER: No protected scripts found." "Red"
        Write-Log "Install Gentle-Vanguard properly or use Gentle-Vanguard.exe (self-contained)." "Yellow"
        exit 1
    }
}

# Resolve master key (for both embedded-encrypted and file-based modes)
if ($isEmbeddedEncrypted -or (-not $isEmbedded -and -not (Test-Path $cacheScript))) {
    $key = Resolve-MasterKey
    if (-not $key) {
        $key = Prompt-For-Key
        if (-not $key) {
            Write-Log "GENTLE_VANGUARD LAUNCHER: Master key required to decrypt scripts." "Red"
            exit 1
        }
    }

    # Decrypt all .enc files to AppData cache
    try {
        $encFiles = Get-ChildItem -Path $encryptedBasePath -Recurse -Filter "*.enc" -File
        $decryptedCount = 0
        foreach ($encFile in $encFiles) {
            $relativePath = $encFile.FullName.Substring($encryptedBasePath.Length + 1)
            $relativePath = $relativePath -replace '\.enc$', ''
            $outputFile = Join-Path $appDataDir $relativePath
            $outputDir = Split-Path $outputFile -Parent
            if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }
            $decrypted = Decrypt-Script -EncryptedPath $encFile.FullName -Key $key
            [System.IO.File]::WriteAllText($outputFile, $decrypted, [System.Text.Encoding]::UTF8)
            $decryptedCount++
        }
    } catch {
        Write-Log "GENTLE_VANGUARD LAUNCHER: Failed to decrypt scripts: $_" "Red"
        exit 1
    }

    if ($isEmbeddedEncrypted) {
        # Clean up temp embedded files
        Remove-Item $embeddedTempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Inject environment variables
$env:GENTLE_VANGUARD_BASE_DIR = $baseDir
$env:GENTLE_VANGUARD_APPDATA_DIR = $appDataDir
$env:GENTLE_VANGUARD_DATA_DIR = $dataDir

# Execute from AppData
if (-not (Test-Path $cacheScript)) {
    Write-Log "GENTLE_VANGUARD LAUNCHER: gv.ps1 not found in AppData cache." "Red"
    exit 1
}
try { & $cacheScript @args }
catch { Write-Log "GENTLE_VANGUARD LAUNCHER: Failed to execute script: $_" "Red"; exit 1 }


