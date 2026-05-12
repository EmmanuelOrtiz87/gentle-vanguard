# fix-all-markdown.ps1 - Comprehensive markdown fix for foundation
# Fixes: Spanish accents, broken links, code blocks, emojis, tables, formatting

$basePath = ".\foundation"
$totalFiles = 0
$fixedFiles = 0

# Function to fix markdown content
function Fix-MarkdownContent {
    param($content, $filePath)
    
    $original = $content
    
    # 1. Fix Spanish accents (comprehensive list)
    $content = $content -replace 'automatizacin', 'automatizacion'
    $content = $content -replace 'configuracion', 'configuracion'
    $content = $content -replace 'revisin', 'revision'
    $content = $content -replace 'activacin', 'activacion'
    $content = $content -replace 'aceptacin', 'aceptacion'
    $content = $content -replace 'documentacion', 'documentacion'
    $content = $content -replace 'instalacion', 'instalacion'
    $content = $content -replace 'validacion', 'validacion'
    $content = $content -replace 'implementacion', 'implementacion'
    $content = $content -replace 'desarrollo profesional', 'desarrollo profesional'
    $content = $content -replace 'herramienta', 'herramienta'
    $content = $content -replace 'est activo', 'esta activo'
    $content = $content -replace 'slo con', 'solo con'
    $content = $content -replace 'slo cuando', 'solo cuando'
    $content = $content -replace 'desarrollo', 'desarrollo'
    
    # 2. Fix broken links (common patterns found in audit)
    # Fix TECHNICAL-ONBOARDING path
    $content = $content -replace 'docs/supplementary/TECHNICAL-ONBOARDING\.md', 'docs/guides/TECHNICAL-ONBOARDING.md'
    $content = $content -replace 'guides/TECHNICAL-ONBOARDING\.md(?!\.)', 'guides/TECHNICAL-ONBOARDING.md'
    
    # Fix OPERATING-DECISIONS case
    $content = $content -replace 'OPERATING-decisionS', 'OPERATING-DECISIONS'
    $content = $content -replace 'OPERATING-decisionS', 'OPERATING-DECISIONS'
    
    # Fix DOCUMENTATION-STANDARDS references (point to existing files)
    $content = $content -replace 'DOCUMENTATION-STANDARDS\.md', 'TOKEN-CONTEXT-STANDARDS.md'
    $content = $content -replace 'docs/DOCUMENTATION-STANDARDS\.md', 'docs/guides/TOKEN-CONTEXT-STANDARDS.md'
    $content = $content -replace '\.\./DOCUMENTATION-STANDARDS\.md', './TOKEN-CONTEXT-STANDARDS.md'
    
    # 3. Ensure code blocks have language specification
    # Find ``` followed by nothing or just whitespace, add appropriate language
    $content = $content -replace '```\s*\n', {
        param($match)
        # Try to detect language from context (simplified)
        if ($match.Value -match 'powershell|\.ps1') { '```powershell' }
        elseif ($match.Value -match 'bash|sh|\.sh') { '```bash' }
        elseif ($match.Value -match 'json') { '```json' }
        elseif ($match.Value -match 'typescript|\.ts') { '```typescript' }
        elseif ($match.Value -match 'javascript|\.js') { '```javascript' }
        else { '```text' }
    }
    
    # 4. Add blank lines before/after headers (if missing)
    $content = $content -replace "([^\n])\n(#{1,6} )", '$1' + "`n`n" + '$2'
    $content = $content -replace "(#{1,6} .*)\n([^#\n])", '$1' + "`n`n" + '$2'
    
    # 5. Add emojis to common headers (if missing)
    if ($content -match "^## Quick Start" -and $content -notmatch "##  Quick Start") {
        $content = $content -replace "^## Quick Start", "##  Quick Start"
    }
    if ($content -match "^## Documentation" -and $content -notmatch "##  Documentation") {
        $content = $content -replace "^## Documentation", "##  Documentation"
    }
    if ($content -match "^## Configuration" -and $content -notmatch "## [*] Configuration") {
        $content = $content -replace "^## Configuration", "## [*] Configuration"
    }
    if ($content -match "^## Installation" -and $content -notmatch "##  Installation") {
        $content = $content -replace "^## Installation", "##  Installation"
    }
    
    return $content
}

# Process all markdown files
Get-ChildItem -Path $basePath -Filter *.md -Recurse | ForEach-Object {
    $file = $_.FullName
    $totalFiles++
    
    try {
        $content = Get-Content -Path $file -Raw -Encoding UTF8
        $fixedContent = Fix-MarkdownContent -content $content -filePath $file
        
        if ($fixedContent -ne $content) {
            Set-Content -Path $file -Value $fixedContent -Encoding UTF8
            Write-Host "[OK] Fixed: $file"
            $fixedFiles++
        }
    }
    catch {
        Write-Host "[FAIL] Error processing $file : $_"
    }
}

Write-Host "`n========================================="
Write-Host "Total files processed: $totalFiles"
Write-Host "Files fixed: $fixedFiles"
Write-Host "========================================="
