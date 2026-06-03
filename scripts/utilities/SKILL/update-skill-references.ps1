# update-skill-references.ps1
# Phase 2: Update SKILL.md files to reference extracted content
# Adds links to references/ and reduces file size

param(
    [switch]$Apply,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$workspaceRoot = $PSScriptRoot | Split-Path | Split-Path

# Skills to update (same list from Phase 1)
$skillsToUpdate = @(
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

Write-Host "=== PHASE 2: UPDATE SKILL.md WITH REFERENCES ===" -ForegroundColor Cyan
Write-Host "Skills to update: $($skillsToUpdate.Count)" -ForegroundColor Yellow
Write-Host "Mode: $(if ($Apply) { 'APPLY' } else { 'DRY RUN' })" -ForegroundColor $(if ($Apply) { 'Red' } else { 'Green' })
Write-Host ""

$processed = 0
$updated = 0
$errors = @()
$totalLinesBefore = 0
$totalLinesAfter = 0

foreach ($skillName in $skillsToUpdate) {
    $skillPath = Join-Path $workspaceRoot "skills\$skillName"
    $skillFile = Join-Path $skillPath "SKILL.md"
    $refsPath = Join-Path $skillPath "references"
    
    if (-not (Test-Path $skillFile)) {
        Write-Host "[SKIP] $skillName - SKILL.md not found" -ForegroundColor Gray
        continue
    }
    
    if (-not (Test-Path $refsPath)) {
        Write-Host "[SKIP] $skillName - No references/ directory" -ForegroundColor Gray
        continue
    }
    
    Write-Host "Processing: $skillName..." -ForegroundColor Cyan
    
    try {
        $content = Get-Content $skillFile -Raw
        $linesBefore = ($content -split "`n").Count
        $totalLinesBefore += $linesBefore
        
        # Check if already has references section
        if ($content -match "## References" -or $content -match "references/") {
            Write-Host "  [SKIP] Already has references section" -ForegroundColor Gray
            continue
        }
        
        # Get list of reference files
        $refFiles = Get-ChildItem $refsPath -Filter "*.md" | Where-Object { $_.Name -ne "README.md" }
        
        if ($refFiles.Count -eq 0) {
            Write-Host "  [SKIP] No code examples to reference" -ForegroundColor Gray
            continue
        }
        
        if ($Apply) {
            # Create references section
            $refsSection = "`n`n## References`n`nSee [references/](references/) for detailed examples:`n`n"
            
            foreach ($refFile in $refFiles) {
                $refName = $refFile.BaseName -replace "^code-example-", "Example "
                $refsSection += "- [$refName](references/$($refFile.Name))`n"
            }
            
            # Add references section before the last section or at the end
            if ($content -match "## Quick Reference") {
                $content = $content -replace "(## Quick Reference)", "$refsSection`n`n`$1"
            } else {
                $content = $content + $refsSection
            }
            
            # Write updated content
            $content | Out-File $skillFile -Encoding UTF8
            
            $linesAfter = ($content -split "`n").Count
            $totalLinesAfter += $linesAfter
            
            Write-Host "  [UPDATED] Added $($refFiles.Count) references (+$($linesAfter - $linesBefore) lines)" -ForegroundColor Green
            $updated++
        } else {
            Write-Host "  [WOULD UPDATE] Add $($refFiles.Count) reference links" -ForegroundColor Yellow
        }
        
        $processed++
    } catch {
        $errors += "$skillName`: $_"
        Write-Host "  [ERROR] $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Processed: $processed/$($skillsToUpdate.Count)"
Write-Host "Updated: $updated"
if ($Apply) {
    Write-Host "Total lines before: $totalLinesBefore"
    Write-Host "Total lines after: $totalLinesAfter"
    Write-Host "Net change: +$($totalLinesAfter - $totalLinesBefore)" -ForegroundColor Yellow
}

if (-not $Apply) {
    Write-Host ""
    Write-Host "This was a DRY RUN. To apply changes:" -ForegroundColor Yellow
    Write-Host "  pwsh -File scripts/utilities/update-skill-references.ps1 -Apply"
}
