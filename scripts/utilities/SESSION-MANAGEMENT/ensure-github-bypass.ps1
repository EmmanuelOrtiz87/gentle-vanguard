#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ensures the authenticated GitHub user can bypass develop rulesets.
.DESCRIPTION
    Resolves the current GitHub user via gh, locates branch rulesets targeting develop,
    and ensures the user is added as a bypass actor with bypass_mode=always in both
    foundation and foundation-public.
.PARAMETER Owner
    Repository owner/user.
.PARAMETER Repos
    Repository names to enforce.
.PARAMETER Branch
    Branch protected by ruleset (default: develop).
.PARAMETER Strict
    If set, exits non-zero when any repo cannot be updated.
#>

param(
    [string]$Owner = 'EmmanuelOrtiz87',
    [string[]]$Repos = @('foundation', 'foundation-public'),
    [string]$Branch = 'develop',
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$hasFailure = $false

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Warn 'GitHub CLI (gh) not found. Skipping bypass enforcement.'
    exit 0
}

try {
    $viewer = gh api user | ConvertFrom-Json
    $actorId = [int]$viewer.id
    $actorLogin = [string]$viewer.login
    Write-Info "Authenticated as $actorLogin ($actorId)"
} catch {
    Write-Warn 'Unable to resolve authenticated GitHub user. Skipping bypass enforcement.'
    exit 0
}

$branchRef = "refs/heads/$Branch"

foreach ($repo in $Repos) {
    try {
        Write-Info "Checking rulesets for $Owner/$repo ($branchRef)..."
        $rulesets = gh api "repos/$Owner/$repo/rulesets" | ConvertFrom-Json

        $target = $null
        foreach ($item in $rulesets) {
            $detail = gh api "repos/$Owner/$repo/rulesets/$($item.id)" | ConvertFrom-Json
            $includes = @($detail.conditions.ref_name.include)
            if ($detail.target -eq 'branch' -and $includes -contains $branchRef) {
                $target = $detail
                break
            }
        }

        if (-not $target) {
            Write-Warn "No branch ruleset found for $repo on $branchRef."
            $hasFailure = $true
            continue
        }

        $existingActors = @($target.bypass_actors)
        $alreadyBypassed = $target.current_user_can_bypass -eq 'always' -or (
            $existingActors | Where-Object {
                $_.actor_type -eq 'User' -and [int]$_.actor_id -eq $actorId -and $_.bypass_mode -eq 'always'
            }
        )

        if ($alreadyBypassed) {
            Write-Ok "${repo}: bypass already active for $actorLogin"
            continue
        }

        $newActors = @()
        if ($existingActors) {
            $newActors += $existingActors
        }

        $newActors += @{
            actor_id   = $actorId
            actor_type = 'User'
            bypass_mode = 'always'
        }

        $body = [ordered]@{
            name          = $target.name
            target        = $target.target
            enforcement   = $target.enforcement
            conditions    = $target.conditions
            rules         = $target.rules
            bypass_actors = $newActors
        }

        $json = $body | ConvertTo-Json -Depth 20
        $json | gh api "repos/$Owner/$repo/rulesets/$($target.id)" -X PUT --input - | Out-Null

        $check = gh api "repos/$Owner/$repo/rulesets/$($target.id)" | ConvertFrom-Json
        if ($check.current_user_can_bypass -eq 'always') {
            Write-Ok "${repo}: bypass enabled for $actorLogin"
        } else {
            Write-Warn "${repo}: update sent but bypass check did not return always."
            $hasFailure = $true
        }
    } catch {
        Write-Warn "${repo}: bypass enforcement failed ($($_.Exception.Message))"
        $hasFailure = $true
    }
}

if ($Strict -and $hasFailure) {
    exit 1
}

exit 0