#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Apply branch protection using canonical quality gates.

.DESCRIPTION
    Uses GitHub CLI to apply branch protection settings based on
    config/quality-gates.json. Requires gh auth.

.PARAMETER Owner
    GitHub owner/org.

.PARAMETER Repo
    GitHub repository name.

.PARAMETER Branch
    Target branch. Default: main.

.EXAMPLE
    pwsh -File scripts/utilities/apply-branch-protection.ps1 -Owner EmmanuelOrtiz87 -Repo gentle-vanguard -Branch main
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Owner,

    [Parameter(Mandatory = $true)]
    [string]$Repo,

    [string]$Branch = "main",

    [string]$HostName = "github.com"
)

$ErrorActionPreference = "Stop"

$root = git -C $PSScriptRoot rev-parse --show-toplevel 2>$null
if (-not $root) { $root = (Get-Location).Path }

$qualityPath = Join-Path $root "config/quality-gates.json"
if (-not (Test-Path $qualityPath)) {
    throw "quality-gates.json not found at $qualityPath"
}

$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    throw "GitHub CLI (gh) not found in PATH."
}

$authStatus = gh auth status --hostname $HostName 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI not authenticated for $HostName. Run: gh auth login --hostname $HostName"
}

$qg = Get-Content $qualityPath -Raw | ConvertFrom-Json
$contexts = @($qg.requiredStatusChecks.contexts)
if ($contexts.Count -eq 0) {
    throw "No required status check contexts defined in config/quality-gates.json"
}

$body = @{
    required_status_checks = @{
        strict = [bool]$qg.requiredStatusChecks.strict
        contexts = $contexts
    }
    enforce_admins = $true
    required_pull_request_reviews = @{
        dismiss_stale_reviews = [bool]$qg.pullRequestRules.dismissStaleReviews
        require_code_owner_reviews = [bool]$qg.pullRequestRules.requireCodeOwnerReviews
        required_approving_review_count = [int]$qg.pullRequestRules.requiredApprovingReviewCount
    }
    restrictions = $null
    required_conversation_resolution = [bool]$qg.pullRequestRules.requireConversationResolution
}

$jsonBody = $body | ConvertTo-Json -Depth 8 -Compress
$endpoint = "/repos/$Owner/$Repo/branches/$Branch/protection"

Write-Host "Applying branch protection to ${Owner}/${Repo}:${Branch}..." -ForegroundColor Cyan
$tempJson = Join-Path $env:TEMP "branch-protection-$Owner-$Repo-$Branch.json"
Set-Content -Path $tempJson -Value $jsonBody -Encoding UTF8
$null = gh api --hostname $HostName --method PUT $endpoint --input $tempJson
Remove-Item -Path $tempJson -Force -ErrorAction SilentlyContinue
if ($LASTEXITCODE -ne 0) {
    throw "Failed to apply branch protection via gh api on host $HostName"
}

Write-Host "[OK] Branch protection applied using config/quality-gates.json" -ForegroundColor Green

