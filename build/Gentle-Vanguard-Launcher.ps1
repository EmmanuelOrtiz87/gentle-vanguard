param([string]$Command)

$ErrorActionPreference = "Stop"

$embeddedArchiveBase64 = "__EMBEDDED_SCRIPTS__"

$appDataDir = "$env:LOCALAPPDATA\Gentle-Vanguard\scripts"
$dataDir = "$env:LOCALAPPDATA\Gentle-Vanguard\data"
$stateFile = Join-Path $dataDir "setup-state.json"
$cacheKeyPath = Join-Path $dataDir "master.key"
$cacheScript = Join-Path $appDataDir "scripts\utilities\WORKFLOW-ORCHESTRATION\gv.ps1"
$embeddedTempDir = Join-Path $env:TEMP "Gentle-Vanguard\embedded"

function Write-Log {
    param($Message, $Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([string]$Label, [string]$Message)
    Write-Host "  [$Label] $Message" -ForegroundColor Cyan
}

function Write-OK {
    param([string]$Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "  [WARN] $Message" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "  [FAIL] $Message" -ForegroundColor Red
}

function Read-Host-Safe {
    try { return Read-Host @args } catch { return $null }
}

function Show-Banner {
    Clear-Host
    Write-Log "╔══════════════════════════════════════════════════╗" "Cyan"
    Write-Log "║         GENTLE-VANGUARD SETUP WIZARD v3.0       ║" "Cyan"
    Write-Log "║     AI-First Development Workspace Launcher     ║" "Cyan"
    Write-Log "╚══════════════════════════════════════════════════╝" "Cyan"
    Write-Log ""
}

function Show-MainMenu {
    Show-Banner
    Write-Log "  SELECT INSTALLATION MODE:" "White"
    Write-Log ""
    Write-Log "  1. Full Installation (recommended)" "Green"
    Write-Log "     Install all components: core, skills, configs, tools"
    Write-Log ""
    Write-Log "  2. Minimal Installation" "Yellow"
    Write-Log "     Core launcher only: gv.ps1 + essential scripts"
    Write-Log ""
    Write-Log "  3. Reconfigure" "Cyan"
    Write-Log "     Re-run configuration, fix paths, update settings"
    Write-Log ""
    Write-Log "  4. Environment Check" "Magenta"
    Write-Log "     Verify prerequisites, detect installed tools"
    Write-Log ""
    Write-Log "  5. Help / About" "Gray"
    Write-Log "     Version info, key management, documentation links"
    Write-Log ""
    Write-Log "  6. Exit" "Red"
    Write-Log ""
    $choice = Read-Host-Safe "  Selection [1-6]"
    return $choice
}

function Test-Prerequisites {
    $issues = @()
    $pwshVer = $PSVersionTable.PSVersion
    if ($pwshVer.Major -lt 7) {
        $issues += "PowerShell 7+ required (found v$($pwshVer))"
    }
    $gitVer = git --version 2>$null
    if (-not $gitVer) {
        $issues += "Git not found in PATH"
    }
    return $issues
}

function Show-EnvironmentCheck {
    Show-Banner
    Write-Log "  ENVIRONMENT CHECK" "Cyan"
    Write-Log "  =================="
    Write-Log ""
    $issues = Test-Prerequisites
    if ($issues.Count -eq 0) {
        Write-OK "All prerequisites satisfied"
    } else {
        foreach ($issue in $issues) {
            Write-Err $issue
        }
    }
    $pwshVer = $PSVersionTable.PSVersion
    Write-Step "PowerShell" "v$($pwshVer.Major).$($pwshVer.Minor).$($pwshVer.Build)"
    Write-Step "OS" "$([Environment]::OSVersion)"
    Write-Step "Arch" "$([Environment]::Is64BitProcess ? '64-bit' : '32-bit')"
    Write-Step "AppData" $appDataDir
    Write-Step "Cache key" $(if (Test-Path $cacheKeyPath) { "Present" } else { "Not found" })
    Write-Step "Installation" $(if (Test-Path $stateFile) { "Configured" } else { "Not configured" })
    Write-Log ""
    Write-Log "  Detected AI tools:"
    $tools = @()
    if ($env:OPENCODE_SERVER_USERNAME) { $tools += "OpenCode" }
    if ($env:CLAUDE_VSCODE_VERSION) { $tools += "Claude Code" }
    if (Test-Path ".clinerules") { $tools += "Cline" }
    if (Test-Path ".cursorrules") { $tools += "Cursor" }
    if (Test-Path ".windsurf") { $tools += "Windsurf" }
    if ($tools.Count -eq 0) { $tools += "None detected" }
    foreach ($t in $tools) { Write-Log "    - $t" "Gray" }
    Write-Log ""
    Write-Host "Press Enter to continue..." -NoNewline
    Read-Host-Safe
}

function Show-Help {
    Show-Banner
    Write-Log "  HELP / ABOUT" "Cyan"
    Write-Log "  ============"
    Write-Log ""
    Write-Log "  Gentle-Vanguard v2.30.0 — AI-First Development Workspace"
    Write-Log ""
    Write-Log "  What this does:"
    Write-Log "  Decrypts and runs the Gentle-Vanguard AI orchestration stack."
    Write-Log "  Encrypted scripts are embedded in this .exe for secure distribution."
    Write-Log ""
    Write-Log "  First-time setup:"
    Write-Log "  1. Run this .exe — the wizard will guide you through setup"
    Write-Log "  2. You need a master.key (32 bytes, Base64) to decrypt scripts"
    Write-Log "  3. Scripts are cached to %LOCALAPPDATA%\Gentle-Vanguard\scripts"
    Write-Log "  4. After setup, run again to launch the workspace CLI"
    Write-Log ""
    Write-Log "  Commands:"
    Write-Log "    gv              Launch workspace CLI (interactive)"
    Write-Log "    gv <command>    Run specific command"
    Write-Log "    gv --help       Show available commands"
    Write-Log ""
    Write-Log "  Documentation: docs/AGENTS.md"
    Write-Log ""
    Write-Host "Press Enter to continue..." -NoNewline
    Read-Host-Safe
}

function Resolve-MasterKey {
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
    $found = Find-File "master.key" $baseDir
    if ($found) {
        $bytes = [System.IO.File]::ReadAllBytes($found)
        if ($bytes.Length -eq 32) { return $bytes }
    }
    return $null
}

function Find-File {
    param($FileName, $SearchPath)
    try {
        $result = Get-ChildItem -Path $SearchPath -Recurse -Filter $FileName -ErrorAction Stop | Select-Object -First 1
        return $result.FullName
    } catch { return $null }
}

function Prompt-For-Key {
    Write-Log "`nMASTER KEY REQUIRED" "Yellow"
    Write-Log "Encrypted scripts require a 32-byte master.key (Base64)." "Yellow"
    Write-Log "Enter the key contents below:" "Yellow"
    $input = Read-Host-Safe "> "
    if (-not $input) { return $null }
    $input = $input.Trim()
    try {
        $bytes = [Convert]::FromBase64String($input)
        if ($bytes.Length -ne 32) {
            Write-Err "Invalid key: expected 32 bytes, got $($bytes.Length)"
            return $null
        }
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
        [System.IO.File]::WriteAllBytes($cacheKeyPath, $bytes)
        Write-OK "Key cached to $cacheKeyPath"
        return $bytes
    } catch {
        Write-Err "Invalid Base64: $_"
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

function Decrypt-Bytes {
    param([byte[]]$Data, [byte[]]$Key)
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $Key
    $aes.IV = $Data[0..15]
    $encryptedData = $Data[16..($Data.Length - 1)]
    $decryptor = $aes.CreateDecryptor()
    return $decryptor.TransformFinalBlock($encryptedData, 0, $encryptedData.Length)
}

function Extract-EmbeddedArchive {
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

function Install-Scripts {
    param([string]$Mode)
    $isEmbedded = ($embeddedArchiveBase64 -ne "" -and $embeddedArchiveBase64 -ne "__EMBEDDED_SCRIPTS__")
    if (-not $isEmbedded) {
        $encBasePath = $null
        foreach ($p in @((Join-Path $baseDir "protected"), (Join-Path $baseDir "..\protected"), $baseDir)) {
            if (Test-Path (Join-Path $p "scripts\utilities\WORKFLOW-ORCHESTRATION\gv.ps1.enc")) {
                $encBasePath = $p; break
            }
        }
        if (-not $encBasePath) {
            Write-Err "No protected scripts found in embedded archive or local filesystem."
            Write-Log "Run this .exe from the installation directory or obtain the correct distribution." "Yellow"
            return $false
        }
    }
    $key = Resolve-MasterKey
    if (-not $key) {
        $key = Prompt-For-Key
        if (-not $key) {
            Write-Err "Master key required to decrypt scripts."
            return $false
        }
    }
    if ($isEmbedded) {
        Write-Step "Extract" "Extracting encrypted archive..."
        if (Test-Path $embeddedTempDir) { Remove-Item $embeddedTempDir -Recurse -Force }
        New-Item -ItemType Directory -Path $embeddedTempDir -Force | Out-Null
        $count = Extract-EmbeddedArchive -Base64 $embeddedArchiveBase64 -OutDir $embeddedTempDir
        Write-OK "Extracted $count encrypted files"
        $encBasePath = $embeddedTempDir
    }
    try {
        $encFiles = Get-ChildItem -Path $encBasePath -Recurse -Filter "*.enc" -File
        $decryptedCount = 0
        foreach ($encFile in $encFiles) {
            $relativePath = $encFile.FullName.Substring($encBasePath.Length + 1)
            $relativePath = $relativePath -replace '\.enc$', ''
            $outputFile = Join-Path $appDataDir $relativePath
            $outputDir = Split-Path $outputFile -Parent
            if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }
            $decrypted = Decrypt-Script -EncryptedPath $encFile.FullName -Key $key
            [System.IO.File]::WriteAllText($outputFile, $decrypted, [System.Text.Encoding]::UTF8)
            $decryptedCount++
        }
        Write-OK "Decrypted $decryptedCount scripts to AppData cache"
        if ($isEmbedded) {
            Remove-Item $embeddedTempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        $env:GENTLE_VANGUARD_BASE_DIR = $baseDir
        $env:GENTLE_VANGUARD_APPDATA_DIR = $appDataDir
        $env:GENTLE_VANGUARD_DATA_DIR = $dataDir
        $state = @{
            version = "3.0"
            installMode = $Mode
            timestamp = (Get-Date -Format "o")
            appDataDir = $appDataDir
            baseDir = $baseDir
        }
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
        $state | ConvertTo-Json | Set-Content $stateFile -Encoding UTF8
        return $true
    } catch {
        Write-Err "Failed to decrypt and install scripts: $_"
        if ($isEmbedded) {
            Remove-Item $embeddedTempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        return $false
    }
}

function Do-FullInstall {
    Show-Banner
    Write-Log "  FULL INSTALLATION" "Cyan"
    Write-Log "  ================="
    Write-Log ""
    $issues = Test-Prerequisites
    if ($issues.Count -gt 0) {
        Write-Warn "Prerequisite issues detected:"
        foreach ($issue in $issues) {
            Write-Err $issue
        }
        Write-Log ""
        $cont = Read-Host-Safe "Continue anyway? (y/N)"
        if ($cont -ne "y") {
            Write-Log "Installation cancelled." "Yellow"
            return
        }
    }
    Write-Log ""
    if (Install-Scripts -Mode "full") {
        Write-Log ""
        Write-OK "Gentle-Vanguard installed successfully!"
        Write-Log ""
        Write-Log "  Next steps:" "Green"
        Write-Log "  1. Run 'gv' to launch the Gentle-Vanguard CLI" "White"
        Write-Log "  2. Or run 'gv help' to see available commands" "White"
        Write-Log ""
        Write-Log "  Installation details:" "Gray"
        Write-Log "  - Scripts cached to: $appDataDir" "Gray"
        Write-Log "  - State saved to: $stateFile" "Gray"
    }
    Write-Log ""
    Write-Host "Press Enter to continue..." -NoNewline
    Read-Host-Safe
}

function Do-MinimalInstall {
    Show-Banner
    Write-Log "  MINIMAL INSTALLATION" "Yellow"
    Write-Log "  ===================="
    Write-Log ""
    Write-Warn "Minimal mode installs only the core launcher (gv.ps1)."
    Write-Warn "Skills, tools, and extras are NOT included."
    Write-Log ""
    $cont = Read-Host-Safe "Proceed with minimal installation? (y/N)"
    if ($cont -ne "y") {
        Write-Log "Installation cancelled." "Yellow"
        return
    }
    if (Install-Scripts -Mode "minimal") {
        Write-Log ""
        Write-OK "Gentle-Vanguard (minimal) installed successfully!"
    }
    Write-Log ""
    Write-Host "Press Enter to continue..." -NoNewline
    Read-Host-Safe
}

function Do-Reconfigure {
    Show-Banner
    Write-Log "  RECONFIGURE" "Cyan"
    Write-Log "  ==========="
    Write-Log ""
    if (-not (Test-Path $stateFile)) {
        Write-Warn "No existing installation found. Run Full or Minimal installation first."
        Write-Log ""
        Write-Host "Press Enter to continue..." -NoNewline
        Read-Host-Safe
        return
    }
    Write-Log "Current configuration:"
    Get-Content $stateFile -Raw | ConvertFrom-Json | Format-List
    Write-Log ""
    Write-Log "Options:"
    Write-Log "  1. Re-install scripts (decrypt again)"
    Write-Log "  2. Clear cache and re-install"
    Write-Log "  3. Update master.key"
    Write-Log "  4. Reset everything (clear all cached data)"
    Write-Log ""
    $opt = Read-Host-Safe "Selection [1-4]"
    switch ($opt) {
        "1" {
            if (Install-Scripts -Mode "reinstall") {
                Write-OK "Re-installation complete"
            }
        }
        "2" {
            Remove-Item "$appDataDir\*" -Recurse -Force -ErrorAction SilentlyContinue
            if (Install-Scripts -Mode "reinstall") {
                Write-OK "Re-installation complete"
            }
        }
        "3" {
            Remove-Item $cacheKeyPath -Force -ErrorAction SilentlyContinue
            $key = Prompt-For-Key
            if ($key) {
                Remove-Item "$appDataDir\*" -Recurse -Force -ErrorAction SilentlyContinue
                if (Install-Scripts -Mode "reinstall") {
                    Write-OK "Key updated, scripts re-installed"
                }
            }
        }
        "4" {
            $confirm = Read-Host-Safe "This will remove ALL cached data. Continue? (y/N)"
            if ($confirm -eq "y") {
                Remove-Item "$appDataDir\*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item "$dataDir\*" -Recurse -Force -ErrorAction SilentlyContinue
                Write-OK "All cached data cleared"
            }
        }
    }
    Write-Log ""
    Write-Host "Press Enter to continue..." -NoNewline
    Read-Host-Safe
}

function Do-Launch {
    if (-not (Test-Path $cacheScript)) {
        Write-Err "gv.ps1 not found in AppData cache."
        Write-Log "Run the setup wizard first (run this .exe without arguments)." "Yellow"
        exit 1
    }
    $env:GENTLE_VANGUARD_BASE_DIR = $baseDir
    $env:GENTLE_VANGUARD_APPDATA_DIR = $appDataDir
    $env:GENTLE_VANGUARD_DATA_DIR = $dataDir
    try { & $cacheScript @args }
    catch {
        Write-Err "Failed to execute script: $_"
        exit 1
    }
}

# =====================================================================
# MAIN
# =====================================================================

$exePath = $MyInvocation.MyCommand.Path
$baseDir = if ($exePath) { Split-Path -Parent $exePath } else { Get-Location }

$isFirstRun = -not (Test-Path $stateFile) -or -not (Test-Path $cacheScript)

if ($isFirstRun) {
    do {
        $choice = Show-MainMenu
        switch ($choice) {
            "1" { Do-FullInstall }
            "2" { Do-MinimalInstall }
            "3" { Do-Reconfigure }
            "4" { Show-EnvironmentCheck }
            "5" { Show-Help }
            "6" { Write-Log "Exiting..."; exit 0 }
            default { Write-Warn "Invalid selection. Choose 1-6."; Start-Sleep 1 }
        }
    } while ($true)
} else {
    Do-Launch
}
