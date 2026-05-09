# Foundation-Launcher.exe - Smart Launcher v2.2
# Automatically finds its components in relative or parent paths
# Full AES-256 decryption pipeline with AppData caching and path injection
# Silent professional mode — no interactive prompts

param([string]$Command = "wf")

$ErrorActionPreference = "Stop"

function Write-Log {
    param($Message, $Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Find-File {
    param($FileName, $SearchPath)
    try {
        $result = Get-ChildItem -Path $SearchPath -Recurse -Filter $FileName -ErrorAction Stop | Select-Object -First 1
        return $result.FullName
    } catch {
        return $null
    }
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

# Get the directory where this launcher is running from
$exePath = $MyInvocation.MyCommand.Path
if ($exePath) {
    $baseDir = Split-Path -Parent $exePath
} else {
    $baseDir = Get-Location
}

$appDataDir = "$env:LOCALAPPDATA\Foundation\scripts"
$dataDir = "$env:LOCALAPPDATA\Foundation\data"

# Strategy 1: Check for master.key in standard locations
$masterKeyPaths = @(
    (Join-Path $baseDir "keys\master.key"),
    (Join-Path $baseDir "master.key"),
    (Join-Path $baseDir "..\keys\master.key")
)

$masterKeyPath = $null
foreach ($path in $masterKeyPaths) {
    if (Test-Path $path) {
        $masterKeyPath = $path
        break
    }
}

# Strategy 2: If not found, search recursively
if (-not $masterKeyPath) {
    $foundKey = Find-File "master.key" $baseDir
    if ($foundKey) {
        $masterKeyPath = $foundKey
    }
}

# If still not found, exit gracefully — no interactive prompts
if (-not $masterKeyPath) {
    Write-Log "FOUNDATION LAUNCHER: Master key not found." "Red"
    Write-Log "Place master.key in: $baseDir\keys\master.key" "Yellow"
    exit 1
}

# Load master key
try {
    $key = [System.IO.File]::ReadAllBytes($masterKeyPath)
    if ($key.Length -ne 32) {
        Write-Log "FOUNDATION LAUNCHER: Invalid master key (expected 32 bytes, got $($key.Length))" "Red"
        exit 1
    }
} catch {
    Write-Log "FOUNDATION LAUNCHER: Failed to load master.key: $_" "Red"
    exit 1
}

# Find all encrypted scripts and cache them to AppData
$encryptedBasePath = $null
foreach ($p in @((Join-Path $baseDir "protected"), (Join-Path $baseDir "..\protected"), $baseDir)) {
    $testPath = Join-Path $p "scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1.enc"
    if (Test-Path $testPath) { $encryptedBasePath = $p; break }
}

if (-not $encryptedBasePath) {
    Write-Log "FOUNDATION LAUNCHER: No protected scripts found." "Red"
    Write-Log "Install Foundation properly first." "Yellow"
    exit 1
}

try {
    New-Item -ItemType Directory -Path $appDataDir -Force | Out-Null
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null

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
} catch {
    Write-Log "FOUNDATION LAUNCHER: Failed to cache scripts: $_" "Red"
    exit 1
}

# Inject environment variables for child scripts
$env:FOUNDATION_BASE_DIR = $baseDir
$env:FOUNDATION_APPDATA_DIR = $appDataDir
$env:FOUNDATION_DATA_DIR = $dataDir

# Find the wf.ps1 in AppData cache
$cacheScript = Join-Path $appDataDir "scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1"
if (-not (Test-Path $cacheScript)) {
    Write-Log "FOUNDATION LAUNCHER: wf.ps1 not found in AppData cache." "Red"
    exit 1
}

# Execute from AppData
try {
    & $cacheScript @args
} catch {
    Write-Log "FOUNDATION LAUNCHER: Failed to execute script: $_" "Red"
    exit 1
}
