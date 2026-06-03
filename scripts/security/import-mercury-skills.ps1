param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$MercuryDir = Resolve-Path (Join-Path $PSScriptRoot '..\..\.tmp\mercury-skills')
$SkillsDir = Resolve-Path (Join-Path $PSScriptRoot '..\..\skills')

$imports = @(
    @{ src = 'ai-ml/prompt-engineering';              name = 'prompt-engineering-skill';          triggers = '"prompt engineering", "prompt design", "system prompt", "few-shot", "chain of thought"' },
    @{ src = 'ai-ml/ai-agent-design';                 name = 'ai-agent-design-skill';             triggers = '"agent design", "agent architecture", "tool use", "agent orchestration"' },
    @{ src = 'ai-ml/memory-management';               name = 'memory-management-skill';           triggers = '"memory management", "context window", "vector database", "RAG", "summarization"' },
    @{ src = 'ai-ml/token-budget-tracking';           name = 'token-budget-tracking-skill';       triggers = '"token budget", "cost optimization", "token tracking", "LLM costs"' },
    @{ src = 'ai-ml/agent-audit-logging';             name = 'agent-audit-logging-skill';         triggers = '"audit logging", "compliance", "observability", "agent tracing"' },
    @{ src = 'security/security-audit';               name = 'security-audit-skill';              triggers = '"security audit", "vulnerability assessment", "OWASP", "security review"' },
    @{ src = 'development/clean-code';                name = 'clean-code-skill';                  triggers = '"clean code", "code quality", "refactoring", "readability", "maintainability"' },
    @{ src = 'development/architecture-decision-records'; name = 'adr-skill';                     triggers = '"ADR", "architecture decision", "decision record", "architecture governance"' },
    @{ src = 'testing-qa/test-strategy';              name = 'testing-skill';                      triggers = '"test strategy", "test planning", "test pyramid", "risk-based testing"'; note = 'merged into testing-skill' },
    @{ src = 'testing-qa/e2e-testing';                name = 'e2e-testing-skill';                 triggers = '"e2e test", "end-to-end", "Playwright", "Cypress", "visual testing"' },
    @{ src = 'testing-qa/api-testing';                name = 'api-testing-skill';                 triggers = '"API test", "REST testing", "GraphQL testing", "contract testing"' },
    @{ src = 'testing-qa/accessibility-testing';      name = 'accessibility-testing-skill';       triggers = '"accessibility test", "a11y", "WCAG", "axe-core"' },
    @{ src = 'devops/monitoring-observability';       name = 'monitoring-observability-skill';    triggers = '"monitoring", "observability", "Prometheus", "Grafana", "alerting"' },
    @{ src = 'automation/shell-scripting';            name = 'shell-scripting-skill';             triggers = '"shell script", "bash", "scripting", "automation script"' },
    @{ src = 'design/accessibility';                  name = 'accessibility-design-skill';        triggers = '"accessibility", "WCAG", "inclusive design", "ARIA", "a11y"' },
    @{ src = 'presentation/data-storytelling';        name = 'data-storytelling-skill';           triggers = '"data storytelling", "data viz", "charts", "dashboard", "analytics presentation"' }
)

$count = 0
foreach ($item in $imports) {
    $srcPath = Join-Path $MercuryDir 'categories' ($item.src + '/SKILL.md')
    $dstDir = Join-Path $SkillsDir $item.name
    $dstPath = Join-Path $dstDir 'SKILL.md'

    if (-not (Test-Path $srcPath)) {
        Write-Warning "NOT FOUND: $srcPath"
        continue
    }

    $content = Get-Content $srcPath -Raw

    # Extract body (everything after first ---\n...\n---)
    $singleLineContent = $content -replace "`r`n", "`n"
    if ($singleLineContent -match '(?s)^---\s*\n(.*?)\n---\s*\n(.*)') {
        $frontmatter = $matches[1]
        $body = $matches[2]

        # Parse original name from frontmatter
        $origName = ($frontmatter -split "`n" | Where-Object { $_ -match '^name:\s*(.*)' } | ForEach-Object { $matches[1] })

        # Build new GV-style frontmatter
        $gvDesc = "Imported from mercury-agent-skills. Use when working with $($item.triggers -replace '"', '""'). Triggers: $($item.triggers)."
        $newFrontmatter = @"
name: $($item.name)
description: >
  $gvDesc
metadata:
  source: mercury-agent-skills
  original-name: $origName
"@
        $newContent = "---`n$newFrontmatter`n---`n$body"

        if ($DryRun) {
            Write-Host "[DRYRUN] Would create: $dstDir/SKILL.md ($($body.Length) chars body)"
            continue
        }

        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        [System.IO.File]::WriteAllText($dstPath, $newContent)
        $count++
        Write-Host "IMPORTED: $($item.name) ($($item.src))" -ForegroundColor Green
    } else {
        Write-Warning "PARSE ERROR: $srcPath — invalid frontmatter format"
    }
}

Write-Host "`nImported $count / $($imports.Count) skills to $SkillsDir" -ForegroundColor Cyan
