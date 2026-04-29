# test-trigger2.ps1
# Simple debug script

$filePath = "C:\Workspace_local\workspace-foundation\skills\session-workflow-skill\SKILL.md"
$content = Get-Content $filePath -Raw

Write-Output "Content length: $($content.Length)"

# Find frontmatter
$startMarker = $content.IndexOf("---")
Write-Output "First --- at: $startMarker"

if ($startMarker -ge 0) {
    $secondMarker = $content.IndexOf("---", $startMarker + 3)
    Write-Output "Second --- at: $secondMarker"
    
    if ($secondMarker -ge 0) {
        $frontMatter = $content.Substring($startMarker + 3, $secondMarker - $startMarker - 3)
        Write-Output "Frontmatter length: $($frontMatter.Length)"
        Write-Output "Frontmatter content:"
        Write-Output $frontMatter
        
        # Find trigger line
        $lines = $frontMatter -split "`n"
        foreach ($line in $lines) {
            if ($line -match '^[Tt]rigger:') {
                Write-Output "Found trigger line: $line"
                
                # Extract trigger text
                if ($line -match '"([^"]+)"') {
                    $triggerText = $matches[1]
                    Write-Output "Extracted trigger text: $triggerText"
                    
                    $triggers = $triggerText -split ',' | ForEach-Object { $_.Trim().Trim('"') }
                    Write-Output "Parsed triggers:"
                    foreach ($t in $triggers) {
                        if ($t) { Write-Output "  - '$t'" }
                    }
                }
            }
        }
    }
}
