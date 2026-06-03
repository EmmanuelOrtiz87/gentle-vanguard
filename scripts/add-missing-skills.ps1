# Add missing skills to SKILL_INDEX.md
$indexPath = '.\gentle-vanguard\\skills\SKILL_INDEX.md'
$content = Get-Content $indexPath -Raw

# Define missing skills with their sections
$missing = @(
    @{name='angular-spa-skill'; section='Frontend'; trigger='Angular.*'; text="### angular-spa-skill`n**Trigger**: `Angular`, `Angular component`, `Angular service`, `Angular signal`, `Angular SPA`, `@defer`, `standalone component``n**Use when**: Angular 19+ SPA patterns: signals, zoneless, standalone components, defer loading`n---"},
    @{name='github-pr-skill'; section='Workflow'; trigger='github.*'; text="### github-pr-skill`n**Trigger**: `github`, `PR`, `pull request`, `pr creation``n**Use when**: Creating GitHub pull requests with conventional commits and proper descriptions`n---"},
    @{name='gitflow-orchestrator-skill'; section='Workflow'; trigger='gitflow.*'; text="### gitflow-orchestrator-skill`n**Trigger**: `gitflow`, `gitflow-orchestrator`, `branch creation`, `git hooks``n**Use when**: GitFlow workflow validation, branch creation, pre-push hooks`n---"},
    @{name='incident-response-skill'; section='Operations'; trigger='incident.*'; text="### incident-response-skill`n**Trigger**: `incident`, `outage`, `production issue`, `runbook`, `mitigation``n**Use when**: Handling incidents, response coordination, mitigation, and recovery planning`n---"},
    @{name='issue-creation'; section='Workflow'; trigger='issue.*'; text="### issue-creation`n**Trigger**: `issue`, `create issue`, `github issue`, `bug report``n**Use when**: Creating GitHub issues, reporting bugs, requesting features`n---"},
    @{name='nextjs-15-skill'; section='Frontend'; trigger='nextjs.*'; text="### nextjs-15-skill`n**Trigger**: `Next.js`, `Next.js 15`, `App Router`, `Server Component`, `Server Action`, `next.config``n**Use when**: Next.js 15 App Router patterns: Server Components, Server Actions, data fetching`n---"}
)

foreach($m in $missing) {
    if($content -notmatch [regex]::Escape($m.name)) {
        Write-Host "Adding $($m.name)..."
        # Find section to insert before next major section
        # Simple approach: add before "## Skill Categories" or at end of file
        if($content -match "## Skill Categories") {
            $content = $content -replace "(## Skill Categories)", "$($m.text)`n`$1"
        } else {
            $content += "`n" + $m.text
        }
    }
}

Set-Content -Path $indexPath -Value $content -Encoding UTF8
Write-Host "Done. Check SKILL_INDEX.md"
