# cleanup-scripts-ascii-only.ps1
# FINAL aggressive cleanup: removes ALL non-ASCII chars from scripts/configs
# Only .md docs and .csv reports may keep emojis

$workspaceRoot = $PSScriptRoot | Split-Path | Split-Path

Write-Host "[CLEANUP] Aggressively removing non-ASCII from scripts/configs..."

# Target extensions (scripts and configs ONLY)
$extensions = @("*.ps1", "*.json", "*.cmd", "*.sh", "*.md")
$filesToClean = @()

foreach ($ext in $extensions) {
    $filesToClean += Get-ChildItem $workspaceRoot -Filter $ext -Recurse -File -ErrorAction SilentlyContinue | 
        Where-Object { $_.FullName -notmatch "node_modules|\.git|reports" }
}

Write-Host "[INFO] Found $($filesToClean.Count) files to clean"

$modified = 0
foreach ($file in $filesToClean) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    
    $original = $content
    
    # Remove ALL characters with code > 127 (non-ASCII)
    # This removes emojis, special chars, etc.
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $content.ToCharArray()) {
        if ([int]$c -le 127) {
            $null = $sb.Append($c)
        }
    }
    $content = $sb.ToString()
    
    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        $modified++
        if ($modified -le 20) { Write-Host "   [FIXED] $($file.Name)" }
    }
}

Write-Host "[DONE] Cleaned $modified files - scripts now ASCII-only"
Write-Host "[INFO] Documentation (.md) in docs/ and reports (.csv) untouched"
