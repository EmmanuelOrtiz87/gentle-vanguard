# sync-drift-report.ps1
# FF-004: Sync Drift Prevention — compares declared skills/config vs actual
# filesystem contents and reports any drift (missing, extra, or mismatched).
#
# Checks performed:
#   1. Skills declared in config/auto-delegation.json vs skills/ directories
#   2. MCP servers declared in config/mcp-servers.json vs actual connectivity
#      (file presence only — no live TCP checks)
#   3. Backlog items with resolved_by script ref vs actual file existence
#
# Usage:
#   pwsh -File scripts/utilities/sync-drift-report.ps1
#   wf sync-drift [-JSON]

param(
    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path

# ─── Load configs ─────────────────────────────────────────────────────────────
$autoDelegPath  = Join-Path $repoRoot 'config\auto-delegation.json'
$mcpConfigPath  = Join-Path $repoRoot 'config\mcp-servers.json'
$backlogPath    = Join-Path $repoRoot 'docs\backlog\items.json'
$skillsDir      = Join-Path $repoRoot 'skills'

$missing_skills = @()
$extra_skills   = @()
$missing_mcp    = @()
$broken_refs    = @()

# ─── 1. Skill drift ───────────────────────────────────────────────────────────
if (Test-Path $autoDelegPath) {
    try {
        $autoCfg = Get-Content $autoDelegPath -Raw -Encoding UTF8 | ConvertFrom-Json
        # Collect all skill values from agentCodeToSkill and skillToAgentProfile
        $declaredSkills = @()
        if ($autoCfg.PSObject.Properties['agentCodeToSkill']) {
            $declaredSkills += @($autoCfg.agentCodeToSkill.PSObject.Properties.Value | Where-Object { $_ })
        }
        if ($autoCfg.PSObject.Properties['skillToAgentProfile']) {
            $declaredSkills += @($autoCfg.skillToAgentProfile.PSObject.Properties.Name | Where-Object { $_ })
        }
        $declaredSkills = $declaredSkills | Sort-Object -Unique

        if (Test-Path $skillsDir) {
            $actualSkills = @(
                Get-ChildItem -Path $skillsDir -Directory -EA SilentlyContinue |
                    Where-Object { $_.Name -notmatch '^_' } |  # skip private dirs
                    Select-Object -ExpandProperty Name
            )

            foreach ($declared in $declaredSkills) {
                if ($actualSkills -notcontains $declared) {
                    $missing_skills += $declared
                }
            }

            foreach ($actual in $actualSkills) {
                if ($declaredSkills -notcontains $actual) {
                    $extra_skills += $actual
                }
            }
        }
    } catch {
        Write-Warning "sync-drift: could not parse auto-delegation.json — $_"
    }
}

# ─── 2. MCP server drift ─────────────────────────────────────────────────────
if (Test-Path $mcpConfigPath) {
    try {
        $mcpCfg = Get-Content $mcpConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        # Support both top-level array and { mcpServers: {...} } shape
        $serverNames = @()
        if ($mcpCfg -is [array]) {
            $serverNames += @($mcpCfg | ForEach-Object { [string]$_.name } | Where-Object { $_ })
        } elseif ($mcpCfg.PSObject.Properties['mcpServers']) {
            $serverNames += @($mcpCfg.mcpServers.PSObject.Properties.Name | Where-Object { $_ })
        } elseif ($mcpCfg.PSObject.Properties['servers']) {
            $serverNames += @($mcpCfg.servers | ForEach-Object { [string]$_.name } | Where-Object { $_ })
        }

        foreach ($srv in $serverNames) {
            # A server is "present" if there's a matching skill dir or known local binary
            $hasSkillDir = Test-Path (Join-Path $skillsDir $srv)
            $hasScript   = (Get-ChildItem -Path $repoRoot -Recurse -Filter "*$srv*" -File -EA SilentlyContinue | Select-Object -First 1)
            if (-not $hasSkillDir -and -not $hasScript) {
                $missing_mcp += $srv
            }
        }
    } catch {
        Write-Warning "sync-drift: could not parse mcp-servers.json — $_"
    }
}

# ─── 3. Resolved-by script references ────────────────────────────────────────
if (Test-Path $backlogPath) {
    try {
        $items = Get-Content $backlogPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($item in ($items | Where-Object { $_.status -eq 'done' -and $_.resolved_by })) {
            # resolved_by often contains a free-text description mentioning a file path
            $refText = [string]$item.resolved_by
            $pathMatches = [regex]::Matches($refText, '[\w\-/\\]+\.ps1|[\w\-/\\]+\.yml|[\w\-/\\]+\.sh')
            foreach ($m in $pathMatches) {
                $candidate = $m.Value -replace '/', [System.IO.Path]::DirectorySeparatorChar
                # Try relative to repo root
                $fullPath = Join-Path $repoRoot $candidate
                if (-not (Test-Path $fullPath) -and -not (Test-Path (Join-Path $repoRoot "scripts" $candidate))) {
                    $broken_refs += [pscustomobject]@{ item = $item.id; ref = $m.Value }
                }
            }
        }
    } catch {
        Write-Warning "sync-drift: could not parse backlog items.json — $_"
    }
}

# ─── Summary ─────────────────────────────────────────────────────────────────
$driftScore = $missing_skills.Count + $extra_skills.Count + $missing_mcp.Count + $broken_refs.Count
$status = if ($driftScore -eq 0) { 'CLEAN' } elseif ($driftScore -le 5) { 'WARN' } else { 'DRIFT' }

$result = [ordered]@{
    as_of              = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')
    status             = $status
    drift_score        = $driftScore
    missing_skills     = $missing_skills
    extra_skills       = $extra_skills
    missing_mcp        = $missing_mcp
    broken_refs        = @($broken_refs | ForEach-Object { "$($_.item): $($_.ref)" })
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 5
    exit ($driftScore -gt 0 ? 1 : 0)
}

if (-not $Quiet) {
    $statusColor = switch ($status) { 'CLEAN' { 'Green' } 'WARN' { 'Yellow' } default { 'Red' } }
    Write-Host ''
    Write-Host '=== Sync Drift Report ===' -ForegroundColor Cyan
    Write-Host "  Status: $status  |  Drift score: $driftScore" -ForegroundColor $statusColor
    Write-Host ''

    if ($missing_skills.Count -gt 0) {
        Write-Host "  Missing skill dirs (declared in config, not in skills/):" -ForegroundColor Yellow
        foreach ($s in $missing_skills) { Write-Host "    - $s" -ForegroundColor Yellow }
    } else {
        Write-Host '  Skill dirs: no missing entries.' -ForegroundColor Green
    }
    Write-Host ''

    if ($extra_skills.Count -gt 0) {
        Write-Host "  Extra skill dirs (in skills/, not declared in config):" -ForegroundColor Yellow
        foreach ($s in $extra_skills) { Write-Host "    + $s" -ForegroundColor Cyan }
    } else {
        Write-Host '  Extra skill dirs: none.' -ForegroundColor Green
    }
    Write-Host ''

    if ($missing_mcp.Count -gt 0) {
        Write-Host '  MCP servers without local skill/script:' -ForegroundColor Yellow
        foreach ($m in $missing_mcp) { Write-Host "    - $m" -ForegroundColor Yellow }
    } else {
        Write-Host '  MCP server refs: no unresolved entries.' -ForegroundColor Green
    }
    Write-Host ''

    if ($broken_refs.Count -gt 0) {
        Write-Host '  Broken resolved_by refs in done backlog items:' -ForegroundColor Yellow
        foreach ($r in $broken_refs) { Write-Host "    - $($r.item): $($r.ref)" -ForegroundColor Yellow }
    } else {
        Write-Host '  Resolved-by script refs: all present.' -ForegroundColor Green
    }
    Write-Host ''
}

exit ($driftScore -gt 0 ? 1 : 0)
