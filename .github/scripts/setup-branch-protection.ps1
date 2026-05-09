#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Configure GitHub branch protection rulesets via API.
.DESCRIPTION
    Creates/updates rulesets for main/master and develop branches.
    Requires gh CLI authenticated with admin permissions.
    Usage: pwsh setup-branch-protection.ps1 -owner "org" -repo "repo"
.PARAMETER owner
    GitHub owner (user or org).
.PARAMETER repo
    Repository name.
.PARAMETER dryRun
    If set, show payload without applying.
.EXAMPLE
    pwsh setup-branch-protection.ps1 -owner EmmanuelOrtiz87 -repo gentleman-foundation
#>

param(
    [Parameter(Mandatory)] [string] $owner,
    [Parameter(Mandatory)] [string] $repo,
    [switch] $dryRun
)

$apiBase = "repos/$owner/$repo/rulesets"
$accept  = "Accept: application/vnd.github+json"
$apiVer  = "X-GitHub-Api-Version: 2022-11-28"

function New-Ruleset {
    param([string]$name, [array]$include, [array]$rules, [string]$enforcement = "active")
    
    $body = @{
        name        = $name
        target      = "branch"
        enforcement = $enforcement
        conditions  = @{
            ref_name = @{
                include = $include
                exclude = @()
            }
        }
        rules       = $rules
    } | ConvertTo-Json -Depth 10

    if ($dryRun) {
        Write-Output "=== DRY RUN: Would create ruleset '$name' ==="
        Write-Output $body
        return
    }

    try {
        $result = gh api --method POST $apiBase -H $accept -H $apiVer --input - $body 2>&1
        if ($LASTEXITCODE -eq 0) {
            $id = ($result | ConvertFrom-Json).id
            Write-Output "Created ruleset '$name' (ID: $id)"
        } else {
            Write-Error "Failed to create ruleset '$name': $result"
        }
    } catch {
        Write-Error "Error creating ruleset '$name': $_"
    }
}

# --- Main branch ruleset ---
$mainRules = @(
    @{ type = "pull_request"; parameters = @{
        dismiss_stale_reviews_on_push      = $true
        require_code_owner_review          = $true
        require_last_push_approval          = $true
        required_approving_review_count    = 1
        required_review_thread_resolution  = $true
    }}
    @{ type = "non_fast_forward" }
    @{ type = "deletion" }
    @{ type = "required_status_checks"; parameters = @{
        required_status_checks = @(
            @{ context = "Test Suite (Pester)" }
            @{ context = "Gitleaks Secret Detection" }
            @{ context = "PowerShell Lint (PSScriptAnalyzer)" }
            @{ context = "Format Check (Prettier)" }
        )
        strict_required_status_checks_policy = $true
    }}
)

New-Ruleset `
    -name "main - PR + Status Checks + No Force Push" `
    -include @("refs/heads/main") `
    -rules $mainRules

# --- Develop branch ruleset (lighter) ---
$developRules = @(
    @{ type = "pull_request"; parameters = @{
        dismiss_stale_reviews_on_push      = $false
        require_code_owner_review          = $false
        require_last_push_approval          = $false
        required_approving_review_count    = 1
        required_review_thread_resolution  = $false
    }}
    @{ type = "non_fast_forward" }
    @{ type = "deletion" }
)

New-Ruleset `
    -name "develop - PR + Basic Checks" `
    -include @("refs/heads/develop") `
    -rules $developRules

Write-Output "Branch protection setup complete."
