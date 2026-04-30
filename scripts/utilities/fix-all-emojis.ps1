# fix-all-emojis.ps1
# Aggressive emoji removal using character-by-character filtering

$workspaceRoot = $PSScriptRoot | Split-Path | Split-Path

Write-Host "[CLEANUP] Starting aggressive emoji removal..."

$scriptDirs = @(
    (Join-Path $workspaceRoot "scripts"),
    (Join-Path $workspaceRoot "tools")
)

$totalFiles = 0
$modifiedFiles = 0

foreach ($dir in $scriptDirs) {
    if (-not (Test-Path $dir)) { continue }
    
    $ps1Files = Get-ChildItem $dir -Filter "*.ps1" -Recurse -File
    
    foreach ($file in $ps1Files) {
        $totalFiles++
        $content = Get-Content $file.FullName -Raw
        $originalContent = $content
        
        # Remove any character with code point > 255 (catches all emojis)
        $chars = $content.ToCharArray()
        $newChars = @()
        foreach ($c in $chars) {
            $code = [int]$c
            # Keep only ASCII (0-127) and common extended ASCII (128-255)
            # Remove emojis (typically > 255)
            if ($code -le 255) {
                $newChars += $c
            }
        }
        $content = -join $newChars
        
        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8
            Write-Host "   [FIXED] $($file.Name)"
            $modifiedFiles++
        }
    }
}

Write-Host "[DONE] Processed $totalFiles files, modified $modifiedFiles files"
Write-Host "[INFO] All non-ASCII characters removed - max compatibility"
