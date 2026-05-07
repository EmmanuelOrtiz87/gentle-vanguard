# Foundation-Launcher.exe - Smart Launcher v2.0
# Automatically finds its components in relative or parent paths
# Full AES-256 decryption and execution pipeline

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

# Get the directory where this .exe is running from
$exePath = $MyInvocation.MyCommand.Path
if ($exePath) {
    $baseDir = Split-Path -Parent $exePath
} else {
    $baseDir = Get-Location
}

Write-Log "Foundation Launcher v2.0" "Green"
Write-Log "Base directory: $baseDir" "Gray"
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

# Find encrypted script to run
$scriptName = "wf.ps1.enc"
if ($Command -eq "help") { $scriptName = "foundation-installer-tui.ps1.enc" }

# Strategy 1: Check standard paths
$scriptPaths = @(
    (Join-Path $baseDir "protected\scripts\utilities\WORKFLOW-ORCHESTRATION\$scriptName"),
    (Join-Path $baseDir "scripts\utilities\WORKFLOW-ORCHESTRATION\$scriptName"),
    (Join-Path $baseDir "protected\$scriptName")
)

$scriptPath = $null
foreach ($path in $scriptPaths) {
    if (Test-Path $path) {
        $scriptPath = $path
        Write-Log "Found script at: $path" "Green"
        break
    }
}

# Strategy 2: Search recursively
if (-not $scriptPath) {
    Write-Log "Searching for $scriptName..." "Yellow"
    $foundScript = Find-File $scriptName $baseDir
    if ($foundScript) {
        $scriptPath = $foundScript
        Write-Log "Found script at: $scriptPath" "Green"
    }
}

if (-not $scriptPath) {
    Write-Log "ERROR: Encrypted script not found: $scriptName" "Red"
    Write-Log ""
    Write-Log "TIP: Run protect-foundation.ps1 to encrypt scripts first." "Yellow"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Log ""
Write-Log "Decrypting and launching..." "Cyan"

# Decrypt and execute
try {
    $decryptedScript = Decrypt-Script -EncryptedPath $scriptPath -Key $key

    # Create a temporary file to run the decrypted script
    $tempDir = [System.IO.Path]::GetTempPath()
    $tempFile = Join-Path $tempDir "foundation_$([System.Guid]::NewGuid().ToString('N')).ps1"
    [System.IO.File]::WriteAllText($tempFile, $decryptedScript, [System.Text.Encoding]::UTF8)

    # Execute the decrypted script and pass through arguments
    & $tempFile @args

    # Clean up temp file
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
} catch {
    Write-Log "ERROR: Failed to decrypt/execute script: $_" "Red"
    Write-Log "This may indicate a corrupted key or encrypted file." "Yellow"
    Read-Host "Press Enter to exit"
    exit 1
}
