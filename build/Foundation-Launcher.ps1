# Foundation-Launcher.exe - Smart Launcher v2.1
# Automatically finds its components in relative or parent paths
# Full AES-256 decryption pipeline with AppData caching and path injection
# Fixes: compact-start, token-guard, and writable paths

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

Write-Log "Foundation Launcher v2.1" "Green"
Write-Log "Install dir: $baseDir" "Gray"
Write-Log "Cache dir:   $appDataDir" "Gray"
Write-Log ""

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
        Write-Log "Found master.key at: $path" "Green"
        break
    }
}

# Strategy 2: If not found, search recursively
if (-not $masterKeyPath) {
    Write-Log "Searching for master.key..." "Yellow"
    $foundKey = Find-File "master.key" $baseDir
    if ($foundKey) {
        $masterKeyPath = $foundKey
        Write-Log "Found master.key at: $masterKeyPath" "Green"
    }
}

# If still not found, prompt user to provide key
if (-not $masterKeyPath) {
    Write-Log "Master key not found." "Yellow"
    Write-Log ""
    Write-Log "Options:" "Cyan"
    Write-Log "  1. Place master.key in: $baseDir\keys\master.key" "Gray"
    Write-Log "  2. Paste the key content below (32-byte AES key as Base64)" "Gray"
    Write-Log ""

    $keyInput = Read-Host "Enter master key (or path to key file)"

    if (Test-Path $keyInput) {
        $masterKeyPath = $keyInput
        Write-Log "Using key from: $masterKeyPath" "Green"
    } elseif ($keyInput -and $keyInput.Length -gt 0) {
        $keysDir = Join-Path $baseDir "keys"
        if (-not (Test-Path $keysDir)) {
            New-Item -ItemType Directory -Path $keysDir -Force | Out-Null
        }
        $masterKeyPath = Join-Path $keysDir "master.key"

        try {
            $keyBytes = [Convert]::FromBase64String($keyInput)
            [System.IO.File]::WriteAllBytes($masterKeyPath, $keyBytes)
            Write-Log "Master key saved to: $masterKeyPath" "Green"
        } catch {
            Write-Log "ERROR: Invalid key format. Must be Base64-encoded 32-byte key." "Red"
            Read-Host "Press Enter to exit"
            exit 1
        }
    } else {
        Write-Log "No key provided. Exiting." "Red"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Load master key
try {
    $key = [System.IO.File]::ReadAllBytes($masterKeyPath)
    if ($key.Length -ne 32) {
        Write-Log "ERROR: Invalid master key (expected 32 bytes, got $($key.Length))" "Red"
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Log "Master key loaded ($($key.Length) bytes)" "Green"
} catch {
    Write-Log "ERROR: Failed to load master.key: $_" "Red"
    Read-Host "Press Enter to exit"
    exit 1
}

# Find all encrypted scripts and cache them to AppData
$encryptedBasePath = $null
foreach ($p in @((Join-Path $baseDir "protected"), (Join-Path $baseDir "..\protected"), $baseDir)) {
    $testPath = Join-Path $p "scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1.enc"
    if (Test-Path $testPath) { $encryptedBasePath = $p; break }
}

if (-not $encryptedBasePath) {
    Write-Log "ERROR: No protected scripts found." "Red"
    Write-Log "Install Foundation properly first." "Yellow"
    Read-Host "Press Enter to exit"
    exit 1
}

try {
    # Ensure AppData directories exist
    New-Item -ItemType Directory -Path $appDataDir -Force | Out-Null
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null

    # Find and cache ALL encrypted scripts
    $encFiles = Get-ChildItem -Path $encryptedBasePath -Recurse -Filter "*.enc" -File
    $cachedCount = 0

    foreach ($encFile in $encFiles) {
        # Build relative path from enc to ps1
        $relativePath = $encFile.FullName.Substring($encryptedBasePath.Length + 1)
        $relativePath = $relativePath -replace '\.enc$', ''
        $outputFile = Join-Path $appDataDir $relativePath

        # Only decrypt if cache doesn't exist (or enc is newer)
        if (-not (Test-Path $outputFile) -or (Get-Item $encFile.FullName).LastWriteTime -gt (Get-Item $outputFile -ErrorAction SilentlyContinue).LastWriteTime) {
            $outputDir = Split-Path $outputFile -Parent
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
            $decrypted = Decrypt-Script -EncryptedPath $encFile.FullName -Key $key
            [System.IO.File]::WriteAllText($outputFile, $decrypted, [System.Text.Encoding]::UTF8)
            $cachedCount++
        }
    }

    Write-Log "Cached $cachedCount scripts to AppData" "Green"
} catch {
    Write-Log "ERROR: Failed to cache scripts: $_" "Red"
    Read-Host "Press Enter to exit"
    exit 1
}

# Inject environment variables for child scripts
$env:FOUNDATION_BASE_DIR = $baseDir
$env:FOUNDATION_APPDATA_DIR = $appDataDir
$env:FOUNDATION_DATA_DIR = $dataDir

# Find the wf.ps1 in AppData cache
$cacheScript = Join-Path $appDataDir "scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1"
if (-not (Test-Path $cacheScript)) {
    Write-Log "ERROR: wf.ps1 not found in AppData cache." "Red"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Log ""
Write-Log "Launching from AppData cache..." "Cyan"

# Execute from AppData (MyInvocation resolves correctly)
try {
    & $cacheScript @args
} catch {
    Write-Log "ERROR: Failed to execute script: $_" "Red"
    Read-Host "Press Enter to exit"
    exit 1
}
