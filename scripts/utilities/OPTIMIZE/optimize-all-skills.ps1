# optimize-all-skills.ps1
# Mass optimization script for oversized skills
# Creates references/ structure and extracts large code sections

param(
    [switch]$Apply,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$workspaceRoot = $PSScriptRoot | Split-Path | Split-Path

# Skills to optimize (from analysis)
$skillsToOptimize = @(
    'ui-mobile-skill',
    'content-output-skill', 
    'chained-pr',
    'issue-creation',
    'skill-registry',
    'reporting-skill',
    'codegraph-skill',
    'design-md',
    'sdd-lifecycle',
    'seo-audit-skill',
    'docker-devops-skill',
    'branch-pr',
    'web-artifacts-builder-skill',
    'database-nosql-skill',
    'marketing-growth-hacker',
    'visual-content-skill',
    'sales-outbound-strategist',
    'data-scientist',
    'database-relational-skill',
    'post-session-learning-skill',
    'premortem-skill',
    'git-workflow-skill',
    'content-strategist',
    'seo-specialist',
    'sales-account-executive',
    'api-design-skill',
    'design-ui-designer',
    'devops-sre',
    'skill-creator-skill',
    'marketing-content-writer',
    'customer-success-manager',
    'brand-guide-skill',
    'game-designer',
    'hr-talent-acquisition',
    'github-pr-skill',
    'guardian-fallback-skill',
    'mobile-developer',
    'frontend-engineer',
    'testing-evidence-qa',
    'legal-compliance-officer',
    'product-manager',
    'security-pentester',
    'semantic-skill-matcher',
    'operations-manager',
    'cognitive-doc-design',
    'finance-financial-analyst',
    'customer-support-lead',
    'data-analyst',
    'design-ux-researcher',
    'project-manager',
    'script-runtime-engineering-skill',
    'work-unit-commits',
    'backend-engineer',
    'testing-skill'
)

Write-Host "=== MASS SKILL OPTIMIZATION ===" -ForegroundColor Cyan
Write-Host "Skills to process: $($skillsToOptimize.Count)" -ForegroundColor Yellow
Write-Host "Mode: $(if ($Apply) { 'APPLY' } else { 'DRY RUN (preview only)' })" -ForegroundColor $(if ($Apply) { 'Red' } else { 'Green' })
Write-Host ""

$processed = 0
$created = 0
$errors = @()

foreach ($skillName in $skillsToOptimize) {
    $skillPath = Join-Path $workspaceRoot "skills\$skillName"
    $skillFile = Join-Path $skillPath "SKILL.md"
    
    if (-not (Test-Path $skillFile)) {
        Write-Host "[SKIP] $skillName - SKILL.md not found" -ForegroundColor Gray
        continue
    }
    
    $refsPath = Join-Path $skillPath "references"
    
    Write-Host "Processing: $skillName..." -ForegroundColor Cyan
    
    try {
        $content = Get-Content $skillFile -Raw
        $lines = ($content -split "`n").Count
        
        # Check if already has references
        if (Test-Path $refsPath) {
            Write-Host "  [SKIP] Already has references/" -ForegroundColor Gray
            continue
        }
        
        if ($Apply) {
            # Create references directory
            New-Item -ItemType Directory -Path $refsPath -Force | Out-Null
            
            # Extract code examples (find blocks longer than 30 lines)
            $codeBlocks = [regex]::Matches($content, '```[\s\S]*?```')
            $largeBlocks = @()
            $blockNum = 0
            
            foreach ($block in $codeBlocks) {
                $blockLines = ($block.Value -split "`n").Count
                if ($blockLines -gt 30) {
                    $blockNum++
                    $largeBlocks += $block
                    
                    # Save to references/
                    $refFile = Join-Path $refsPath "code-example-$blockNum.md"
                    @"
# Code Example $blockNum

From: SKILL.md

$($block.Value)
"@ | Out-File $refFile -Encoding UTF8
                }
            }
            
            # Create index file
            $indexFile = Join-Path $refsPath "README.md"
            @"
# References for $skillName

This directory contains extracted content from SKILL.md to keep the main file under size limits.

## Files

$(if ($largeBlocks.Count -gt 0) { "- code-example-*.md - Large code examples extracted from SKILL.md" } else { "- (No large blocks extracted)" })

## Usage

Reference these files when you need detailed examples. The main SKILL.md contains the essential rules and patterns only.
"@ | Out-File $indexFile -Encoding UTF8
            
            $created++
            Write-Host "  [CREATED] references/ with $($largeBlocks.Count) code blocks" -ForegroundColor Green
        } else {
            # Dry run - just show what would happen
            $codeBlocks = [regex]::Matches($content, '```[\s\S]*?```')
            $largeBlockCount = ($codeBlocks | Where-Object { ($_.Value -split "`n").Count -gt 30 }).Count
            
            Write-Host "  [WOULD CREATE] references/ with $largeBlockCount code blocks" -ForegroundColor Yellow
        }
        
        $processed++
    } catch {
        $errors += "$skillName`: $_"
        Write-Host "  [ERROR] $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Processed: $processed/$($skillsToOptimize.Count)"
Write-Host "Created references/: $created"
if ($errors.Count -gt 0) {
    Write-Host "Errors: $($errors.Count)" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

if (-not $Apply) {
    Write-Host ""
    Write-Host "This was a DRY RUN. To apply changes, run with -Apply flag:" -ForegroundColor Yellow
    Write-Host "  pwsh -File scripts/utilities/optimize-all-skills.ps1 -Apply"
}
