# fix-emoji-cleanup.ps1
# Removes emojis and special characters from all PowerShell scripts
# Ensures maximum compatibility across all CLI tools and shells

$workspaceRoot = $PSScriptRoot | Split-Path | Split-Path

Write-Host "[CLEANUP] Starting emoji removal from PowerShell scripts..."

# Find all .ps1 files in scripts and tools directories
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
        
        # Replace common emojis with ASCII text
        $content = $content.Replace("[OK]", "[OK]")
        $content = $content.Replace("[FAIL]", "[FAIL]")
        $content = $content.Replace("[WARN]", "[WARN]")
        $content = $content.Replace("[DATA]", "[DATA]")
        $content = $content.Replace("[EXPORT]", "[EXPORT]")
        $content = $content.Replace("", "")
        $content = $content.Replace("", "")
        $content = $content.Replace("[INFO]", "[INFO]")
        $content = $content.Replace("[SEARCH]", "[SEARCH]")
        $content = $content.Replace("[NOTE]", "[NOTE]")
        $content = $content.Replace("[TOOL]", "[TOOL]")
        $content = $content.Replace("[FAST]", "[FAST]")
        $content = $content.Replace("[LIST]", "[LIST]")
        $content = $content.Replace("[PIN]", "[PIN]")
        $content = $content.Replace("[DOC]", "[DOC]")
        $content = $content.Replace("[SECURE]", "[SECURE]")
        $content = $content.Replace("[UNLOCK]", "[UNLOCK]")
        $content = $content.Replace("[SYNC]", "[SYNC]")
        $content = $content.Replace("[ALERT]", "[ALERT]")
        $content = $content.Replace("[TARGET]", "[TARGET]")
        $content = $content.Replace("[CHART]", "[CHART]")
        $content = $content.Replace("[CHART]", "[CHART]")
        $content = $content.Replace("[NEW]", "[NEW]")
        $content = $content.Replace("[LOOP]", "[LOOP]")
        $content = $content.Replace("[RUN]", "[RUN]")
        $content = $content.Replace("[STOP]", "[STOP]")
        $content = $content.Replace("[PAUSE]", "[PAUSE]")
        $content = $content.Replace("", "")
        $content = $content.Replace("", "")
        $content = $content.Replace("", "")
        $content = $content.Replace("", "")
        $content = $content.Replace("", "")
        
        # Only write if content changed
        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8
            Write-Host "   [FIXED] $($file.Name)"
            $modifiedFiles++
        }
    }
}

Write-Host "[DONE] Processed $totalFiles files, modified $modifiedFiles files"
Write-Host "[INFO] Emoji cleanup complete - scripts now CLI-compatible"

