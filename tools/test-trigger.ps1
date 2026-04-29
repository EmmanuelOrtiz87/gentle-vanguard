# test-trigger.ps1
# Simple test script to debug trigger detection

param([string]$UserInput = "iniciar sesion")

# Read SKILL.md
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Split-Path -Parent $scriptDir
$filePath = Join-Path $workspaceRoot "skills\session-workflow-skill\SKILL.md"
if (-not (Test-Path $filePath)) {
    Write-Output "ERROR: File not found: $filePath"
    exit 1
}

$content = Get-Content $filePath -Raw
Write-Output "File read OK, length: $($content.Length)"

# Extract frontmatter
if ($content -match '(?s)---\s*\n(.*?)---\s*\n') {
    $frontMatter = $matches[1]
    Write-Output "Frontmatter found, length: $($frontMatter.Length)"
    
    # Extract trigger
    if ($frontMatter -match '(?m)^[Tt]rigger:\s*"([^"]+)"') {
        $triggerText = $matches[1]
        Write-Output "Trigger found: $triggerText"
        
        # Parse triggers
        $triggers = $triggerText -split ',' | ForEach-Object { $_.Trim().Trim('"') } | Where-Object { $_.Length -gt 0 }
        Write-Output "Triggers parsed: $($triggers -join ', ')"
        
        # Check if user input matches
        $inputLower = $UserInput.ToLower()
        Write-Output "User input (lower): $inputLower"
        
        foreach ($trigger in $triggers) {
            Write-Output "Checking trigger: '$trigger'"
            if ($inputLower -match [regex]::Escape($trigger.ToLower())) {
                Write-Output "MATCH FOUND: '$trigger'"
                Write-Output "ACTION: Load skill 'session-workflow-skill'"
                exit 0
            }
        }
        Write-Output "NO MATCH"
    } else {
        Write-Output "No trigger pattern found in frontmatter"
    }
} else {
    Write-Output "No frontmatter found"
}
