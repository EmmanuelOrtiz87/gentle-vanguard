# optimize-skill-sizes.ps1
# Analyzes and suggests optimizations for oversized skills
# Usage: pwsh -NoProfile -File scripts/utilities/optimize-skill-sizes.ps1 [-Apply]

param(
    [switch]$Apply,
    [int]$TokenThreshold = 1000,
    [int]$LineThreshold = 150
)

$ErrorActionPreference = 'Continue'
$workspaceRoot = $PSScriptRoot | Split-Path | Split-Path

# Categories of legitimately large skills (should not be optimized)
$exemptCategories = @(
    'flutter-skill',
    'android-kotlin-skill',
    'android-jetpack-compose-skill',
    'android-architecture-skill',
    'react-19-skill',
    'react-native-skill',
    'nextjs-15-skill',
    'angular-spa-skill',
    'django-drf-skill',
    'ios-swiftui-patterns-skill',
    'typescript-skill',
    'tailwind-4-skill',
    'zustand-5-skill',
    'zod-4-skill',
    'ai-sdk-5-skill',
    'playwright-skill',
    'pytest-skill',
    'go-testing',
    'golang-api-skill',
    'mcp-skill',
    'firecrawl-web-skill',
    'fireworks-tech-graph',
    'project-orchestrator-skill',
    'backup-orchestrator',
    'cross-workspace-sync',
    'monitoring-aggregator',
    'gitflow-orchestrator-skill',
    'adaptive-mode-orchestrator',
    'parallel-execution-limits',
    'auto-delegation-router',
    'judgment-day'
)

Write-Host "=== SKILL SIZE OPTIMIZATION ANALYSIS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Thresholds: $TokenThreshold tokens / $LineThreshold lines" -ForegroundColor Gray
Write-Host "Apply mode: $(if ($Apply) { 'YES - Will create references/' } else { 'NO - Analysis only' })" -ForegroundColor $(if ($Apply) { 'Red' } else { 'Green' })
Write-Host ""

$skillsDir = Join-Path $workspaceRoot "skills"
$skills = Get-ChildItem $skillsDir -Directory

$optimizable = @()
$exempt = @()
$alreadyOptimized = @()

foreach ($skill in $skills) {
    $skillFile = Join-Path $skill.FullName "SKILL.md"
    if (-not (Test-Path $skillFile)) { continue }
    
    $content = Get-Content $skillFile -Raw
    $lines = ($content -split "`n").Count
    $tokens = [math]::Round($content.Length / 4)  # Rough estimate: 1 token ~= 4 chars
    $sizeKB = [math]::Round((Get-Item $skillFile).Length / 1KB, 1)
    
    $hasReferences = Test-Path (Join-Path $skill.FullName "references")
    $isExempt = $exemptCategories -contains $skill.Name
    
    $info = [PSCustomObject]@{
        Name = $skill.Name
        Tokens = $tokens
        Lines = $lines
        SizeKB = $sizeKB
        HasReferences = $hasReferences
        IsExempt = $isExempt
    }
    
    if ($hasReferences) {
        $alreadyOptimized += $info
    } elseif ($isExempt) {
        $exempt += $info
    } elseif ($tokens -gt $TokenThreshold -or $lines -gt $LineThreshold) {
        $optimizable += $info
    }
}

# Display results
Write-Host "1. ALREADY OPTIMIZED (has references/)" -ForegroundColor Green
$alreadyOptimized | Sort-Object Tokens -Descending | Format-Table -AutoSize

Write-Host "2. EXEMPT (frameworks/orchestrators - keep large)" -ForegroundColor Yellow
$exempt | Sort-Object Tokens -Descending | Select-Object -First 15 | Format-Table -AutoSize
if ($exempt.Count -gt 15) {
    Write-Host "   ... and $($exempt.Count - 15) more" -ForegroundColor Gray
}

Write-Host "3. SHOULD OPTIMIZE (utility skills > thresholds)" -ForegroundColor Cyan
if ($optimizable.Count -eq 0) {
    Write-Host "   None found! All skills are optimized or exempt." -ForegroundColor Green
} else {
    $optimizable | Sort-Object Tokens -Descending | Format-Table -AutoSize
    
    if ($Apply) {
        Write-Host "`n=== APPLYING OPTIMIZATIONS ===" -ForegroundColor Red
        foreach ($skill in $optimizable) {
            Write-Host "Processing: $($skill.Name)..." -ForegroundColor Yellow
            # TODO: Implement automatic optimization
            # This would:
            # 1. Create references/ directory
            # 2. Extract code blocks >30 lines
            # 3. Move examples to references/
            # 4. Update SKILL.md with links
            Write-Host "   (Manual optimization required for now)" -ForegroundColor Gray
        }
    } else {
        Write-Host "`nTo optimize these skills, manually:" -ForegroundColor Yellow
        Write-Host "  1. Create references/ directory in skill folder"
        Write-Host "  2. Move large code blocks to references/code.md"
        Write-Host "  3. Move examples to references/examples.md"
        Write-Host "  4. Update SKILL.md with links to references/"
        Write-Host "`nSee docs/guides/SKILL-SIZE-OPTIMIZATION.md for full guide"
    }
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total skills: $($skills.Count)"
Write-Host "Already optimized: $($alreadyOptimized.Count)"
Write-Host "Exempt (legitimately large): $($exempt.Count)"
Write-Host "Should optimize: $($optimizable.Count)"
