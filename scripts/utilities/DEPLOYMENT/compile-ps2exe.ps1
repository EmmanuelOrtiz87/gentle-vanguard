#!/usr/bin/env pwsh
# Compile PowerShell scripts to .exe using PS2EXE

param(
    [string]$SourceScript = "",
    [string]$OutputDir = "build\compiled"
)

if (-not (Get-Command "ps2exe" -ErrorAction SilentlyContinue)) {
    Write-Output "[WARN]  PS2EXE not installed. Installing..."
    Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

if ($SourceScript -and (Test-Path $SourceScript)) {
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($SourceScript)
    $outputPath = Join-Path $OutputDir "$fileName.exe"
    
    Write-Output " Compiling: $SourceScript"
    ps2exe -inputFile $SourceScript -outputFile $outputPath -noConsole -iconFile "" -title "Gentle-Vanguard Utility" -description "Gentle-Vanguard automated utility"
    
    if (Test-Path $outputPath) {
        Write-Output "[OK] Created: $outputPath"
    }
} else {
    Write-Output "Usage: .\compile-ps2exe.ps1 -SourceScript 'path\to\script.ps1'"
    Write-Output "Or run without parameters to see this help."
}

