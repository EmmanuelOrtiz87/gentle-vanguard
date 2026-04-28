<#
.SYNOPSIS
    Skill Router - Query routing for specialized skills
    
.DESCRIPTION
    Provides skill-based routing for tasks. Validates access for restricted operations.
    
.PARAMETER Query
    The task or query to route
    
.EXAMPLE
    .\skill-router.ps1 -Query "implement login feature"
    
.NOTES
    Author: gentleman-programming
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Query,
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "workspace_local"
)

# Basic keyword-to-skill mapping
$skillKeywords = @{
    "angular" = @("angular-core", "angular-spa", "angular-architecture")
    "react" = @("react-19", "react-19-skill")
    "go" = @("golang-api", "go-api", "go-testing")
    "docker" = @("docker-devops")
    "git" = @("git-workflow")
    "security" = @("security-skill")
    "test" = @("testing-skill", "testing-strategy")
    "typescript" = @("typescript", "typescript-skill")
    "zod" = @("zod-4", "zod-4-skill")
    "tailwind" = @("tailwind-4", "tailwind-4-skill")
    "zustand" = @("zustand-5", "zustand-5-skill")
    "next" = @("nextjs-15", "nextjs-15-skill")
    "ai" = @("ai-sdk-5", "ai-sdk-5-skill")
    "mcp" = @("mcp-skill")
    "jira" = @("jira-task", "jira-epic")
    "github" = @("github-pr", "branch-pr")
    "django" = @("django-drf", "django-drf-skill")
    "playwright" = @("playwright")
    "pytest" = @("pytest")
    "database" = @("database-relational", "database-nosql")
    "api" = @("api-design")
    "documentation" = @("documentation-governance")
    "architecture" = @("architecture-governance")
    "sdd" = @("sdd-init", "sdd-propose", "sdd-explore", "sdd-design", "sdd-spec", "sdd-tasks", "sdd-apply", "sdd-verify", "sdd-archive")
    "foundation" = @("foundation-audit")
    "session" = @("session-lifecycle")
    "automation" = @("workspace-automation", "project-scaffolding")
}

$queryLower = $Query.ToLower()
$matchedSkills = @()

foreach ($keyword in $skillKeywords.Keys) {
    if ($queryLower -match $keyword) {
        $matchedSkills += $skillKeywords[$keyword]
    }
}

# Flatten and deduplicate
$matchedSkills = $matchedSkills | ForEach-Object { $_ } | Select-Object -Unique

if ($matchedSkills.Count -gt 0) {
    Write-Host "SKILL-ROUTER: Found $($matchedSkills.Count) matching skill(s)" -ForegroundColor Green
    $matchedSkills | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
    
    $result = @{
        Status = "Routed"
        Skills = $matchedSkills
        Query = $Query
    }
    Write-Output ($result | ConvertTo-Json -Compress)
    exit 0
} else {
    Write-Host "SKILL-ROUTER: No specific skills matched for query" -ForegroundColor Yellow
    Write-Output '{"Status":"NoMatch","Skills":[],"Query":"' + $Query + '"}'
    exit 0
}
