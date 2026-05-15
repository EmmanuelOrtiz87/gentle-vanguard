param(
    [string]$WorkspaceRoot = ".",
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$WorkspaceRoot = Resolve-Path $WorkspaceRoot

$registryPath = Join-Path (Join-Path $WorkspaceRoot ".atl") "skill-registry.md"
$autoDelegationPath = Join-Path (Join-Path $WorkspaceRoot "config") "auto-delegation.json"

# --- Helpers ---
function Extract-FrontmatterField {
    param([string[]]$Lines, [string]$Field)
    # Find YAML frontmatter block
    $inFrontmatter = $false
    $frontmatter = @()
    foreach ($line in $Lines) {
        if ($line.Trim() -eq '---' -and -not $inFrontmatter) { $inFrontmatter = $true; continue }
        if ($line.Trim() -eq '---' -and $inFrontmatter) { break }
        if ($inFrontmatter) { $frontmatter += $line }
    }
    # Find field value (handles pipe/folded multi-line and quoted strings)
    $inField = $false
    $foundField = $false
    $fieldVal = @()
    foreach ($line in $frontmatter) {
        if ($line -match "^$Field\s*:(.*)$") {
            $val = $Matches[1].Trim()
            $foundField = $true
            if ($val -eq '|' -or $val -eq '>' -or $val -eq '|-' -or $val -eq '>-') {
                $inField = $true; continue
            }
            if ($val -match "^['""](.+)['""]$") { $val = $Matches[1] }
            if ($val -match "^>\s*(.+)$") { $val = $Matches[1]; return $val }
            if ($val -ne '') { return $val }
            # Empty value: next indented lines are the value
            $inField = $true; continue
        }
        if ($inField -and $foundField) {
            if ($line -match '^\s+(\S.+)') {
                $fieldVal += $Matches[1].Trim()
            } else {
                break
            }
        }
    }
    if ($fieldVal.Count -gt 0) { return ($fieldVal -join ' ').Trim() }
    return ""
}

function Extract-Trigger {
    param([string[]]$Lines)
    # Try direct frontmatter trigger fields
    foreach ($f in @('trigger', 'when-to-use', 'triggers')) {
        $trig = Extract-FrontmatterField -Lines $Lines -Field $f
        if ($trig) { return $trig }
    }
    # Extract from description field
    $desc = Extract-FrontmatterField -Lines $Lines -Field "description"
    if ($desc) {
        # "Trigger: when..." or "**Trigger**: when..." anywhere in description
        if ($desc -match 'Trigger\s*:\s*(.+?)(?:\.\s*|$)') { return $Matches[1].Trim() }
        if ($desc -match '\*\*Trigger\*\*\s*:\s*(.+?)(?:\.\s*|$)') { return $Matches[1].Trim() }
    }
    # Fallback: use description itself on important patterns
    if ($desc -match '^(Use when|When|Load this skill|Load when)') { return $desc }
    # Fallback: grab first bullet from ## When to Use
    $inWhen = $false
    foreach ($line in $Lines) {
        if ($line -match '^## When to Use') { $inWhen = $true; continue }
        if ($inWhen -and $line -match '^## ') { break }
        if ($inWhen -and $line -match '^-\s+(.+)') {
            $val = $Matches[1].Trim()
            if ($val.Length -gt 3) { return $val }
        }
    }
    return ""
}

function Extract-CompactRules {
    param([string[]]$Lines)
    $rules = @()
    $inRules = $false
    $sectionHeaders = @(
        '^## (Critical Rules|Hard Rules|Critical Patterns|Rule)',
        '^## (Rules|Rules and Constraints|Constraints)',
        '^## (Workflow|Process)',
        '^## (Core Rules|Key Rules)'
    )
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        foreach ($h in $sectionHeaders) {
            if ($line -match $h) { $inRules = $true; break }
        }
        if ($inRules -and $line -match '^## [A-Z]' -and $line -notmatch '^## (Critical Rules|Hard Rules|Rules|Constraints|Workflow)') {
            $inRules = $false
        }
        if ($inRules) {
            # Extract bullet items with actionable language
            if ($line -match '^- \*\*([^:]+)\*\*\s*[:.]?\s*(.*)') {
                $rules += "- $($Matches[1]): $($Matches[2])"
            } elseif ($line -match '^- (Rule|Must|Never|Always|Do not|Do |Require|Every|Check|Verify|Use|MUST|NEVER|ALWAYS|Should|Prefer|Keep|Avoid|Limit|Prevent|Block|Preserve|Respect)') {
                $rules += $line.Trim()
            } elseif ($line -match '^\d+\.\s+\*\*([^*]+)\*\*') {
                $rules += "- $($Matches[1]): $($line -replace '^\d+\.\s+\*\*[^*]+\*\*\s*','')"
            } elseif ($line -match '^\d+\.\s+(Rule|Must|Never|Always|Do|Require|Every|Check|Verify|Use|MUST|NEVER|ALWAYS)') {
                $rules += "- $($line -replace '^\d+\.\s+','')"
            }
        }
    }
    # Fallback: look for imperative bullets anywhere
    if ($rules.Count -eq 0) {
        foreach ($line in $Lines) {
            if ($line -match '^-\s+(Rule|Must|Never|Always|Do not|Do not |Do |Require|Every|Check|Verify|Use|MUST|NEVER|ALWAYS|Should|Prefer|Keep|Avoid|Limit|Prevent|Block|Preserve|Respect)') {
                $rules += $line.Trim()
            }
        }
    }
    if ($rules.Count -gt 15) { $rules = $rules[0..14] }
    return $rules
}

# --- Load agent role mapping ---
$agentMap = @{}
if (Test-Path $autoDelegationPath) {
    $deleg = Get-Content $autoDelegationPath -Raw | ConvertFrom-Json
    # Map: skill name -> agent code
    foreach ($entry in $deleg.skillToAgentProfile.PSObject.Properties) {
        $agentMap[$entry.Name] = $entry.Value
    }
}

# Agent code descriptions
$agentLabels = @{
    ORCHESTRATOR = "Orchestrator"
    BA = "BA - Analysis"
    SAD = "SAD - Design"
    DEV = "DEV - Code"
    QA = "QA - Testing"
    OPS = "OPS - DevOps"
    GOV = "GOV - Governance"
    DOC = "DOC - Documentation"
    MKT = "MKT - Marketing"
    SALES = "SALES - Sales"
    FINANCE = "FINANCE - Finance"
    HR = "HR - Talent"
    LEGAL = "LEGAL - Legal"
    PREMORTEM = "PREMORTEM - Risk"
    SESSION = "SESSION - Session"
    SCRIPT = "SCRIPT - Scripts"
    'SCRIPT-GOV' = "SCRIPT-GOV - Scripts"
    'SELF-DIAG' = "SELF-DIAG - Diagnosis"
    GITFLOW = "GITFLOW - Git"
    'BUS-TELE' = "BUS-TELE - Telemetry"
    REPORT = "REPORT - Reports"
}

# --- Scan skill roots ---
$userProfile = [Environment]::GetFolderPath("UserProfile")
$skillRoots = @(
    (Join-Path $WorkspaceRoot "skills"),
    (Join-Path $WorkspaceRoot ".claude" "skills"),
    (Join-Path $WorkspaceRoot ".gemini" "skills"),
    (Join-Path $WorkspaceRoot ".agent" "skills"),
    (Join-Path $WorkspaceRoot ".cursor" "skills"),
    (Join-Path (Join-Path $userProfile ".claude") "skills"),
    (Join-Path (Join-Path (Join-Path $userProfile ".config") "opencode") "skills"),
    (Join-Path (Join-Path $userProfile ".gemini") "skills"),
    (Join-Path (Join-Path $userProfile ".cursor") "skills"),
    (Join-Path (Join-Path $userProfile ".copilot") "skills")
)

$skipDirs = @("sdd-", "_shared", "skill-registry", "node_modules", ".git")

$skills = @()
foreach ($root in $skillRoots) {
    if (-not (Test-Path $root)) { continue }
    Get-ChildItem -Path $root -Directory | ForEach-Object {
        foreach ($s in $skipDirs) { if ($_.Name -like "$s*") { return } }
        $skillMd = Join-Path $_.FullName "SKILL.md"
        if (Test-Path $skillMd) {
            $skills += @{
                Name = $_.Name
                Path = $skillMd
                IsProject = ($_.FullName -like "$WorkspaceRoot*")
            }
        }
    }
}

# Deduplicate: project-level wins
$skills = $skills | Sort-Object Name, @{e={$_.IsProject}} -Descending | Group-Object Name | ForEach-Object { $_.Group[0] }

# --- Read all skills to extract metadata ---
$skillData = @()
foreach ($s in $skills) {
    if (-not (Test-Path $s.Path)) { continue }
    $rawLines = Get-Content $s.Path
    $trigger = Extract-Trigger -Lines $rawLines
    $rules = Extract-CompactRules -Lines $rawLines
    $roleCode = $agentMap[$s.Name]
    $roleLabel = if ($roleCode -and $agentLabels[$roleCode]) { $agentLabels[$roleCode] } else { "" }
    $skillData += @{
        Name = $s.Name
        Path = $s.Path
        Trigger = $trigger
        Rules = $rules
        RoleCode = $roleCode
        RoleLabel = $roleLabel
        IsProject = $s.IsProject
    }
}

# --- Segment: grouped skills + unassigned ---
$grouped = $skillData | Where-Object { $_.RoleCode } | Group-Object RoleCode
$unassigned = $skillData | Where-Object { -not $_.RoleCode }

# --- Build registry ---
$sb = [System.Text.StringBuilder]::new()

[void]$sb.AppendLine("# Skill Registry")
[void]$sb.AppendLine()
[void]$sb.AppendLine("**Auto-generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | **Skills**: $($skillData.Count)")
[void]$sb.AppendLine()
[void]$sb.AppendLine("**Delegator use only.** Sub-agents receive compact rules pre-digested in launch prompt.")
[void]$sb.AppendLine("Orchestrator reads this registry to resolve skill->agent mappings and inject compact rules.")

# --- Summary table ---
[void]$sb.AppendLine()
[void]$sb.AppendLine("## Summary")
[void]$sb.AppendLine()
[void]$sb.AppendLine("| Agent | Skills |")
[void]$sb.AppendLine("|-------|--------|")
foreach ($g in ($grouped | Sort-Object Name)) {
    $code = $g.Name
    $label = if ($agentLabels[$code]) { $agentLabels[$code] } else { $code }
    [void]$sb.AppendLine("| $label | $($g.Count) |")
}
if ($unassigned.Count -gt 0) {
    [void]$sb.AppendLine("| *(unassigned)* | $($unassigned.Count) |")
}

# --- Skill table with agent mapping ---
[void]$sb.AppendLine()
[void]$sb.AppendLine("## Skill-Agent Mapping")
[void]$sb.AppendLine()
[void]$sb.AppendLine("| Agent | Skill | Trigger |")
[void]$sb.AppendLine("|-------|-------|--------|")

$ordered = $skillData | Sort-Object RoleLabel, Name
foreach ($s in $ordered) {
    $role = if ($s.RoleLabel) { $s.RoleLabel } else { "(unassigned)" }
    $truncated = ($s.Trigger -replace '\|','').Trim()
    if ($truncated.Length -gt 80) { $truncated = $truncated.Substring(0,77) + "..." }
    [void]$sb.AppendLine("| $role | $($s.Name) | $truncated |")
}

# --- Compact rules by agent role ---
[void]$sb.AppendLine()
[void]$sb.AppendLine("## Compact Rules by Agent")
[void]$sb.AppendLine()
[void]$sb.AppendLine("Delegators copy matching blocks into sub-agent prompts under `Project Standards (auto-resolved)`.")
[void]$sb.AppendLine()

foreach ($g in ($grouped | Sort-Object Name)) {
    $code = $g.Name
    $label = if ($agentLabels[$code]) { $agentLabels[$code] } else { $code }
    [void]$sb.AppendLine("### $label")
    [void]$sb.AppendLine()
    foreach ($sk in ($g.Group | Sort-Object Name)) {
        [void]$sb.AppendLine("#### $($sk.Name)")
        [void]$sb.AppendLine()
        if ($sk.Rules.Count -gt 0) {
            foreach ($r in $sk.Rules) { [void]$sb.AppendLine("$r") }
        } else {
            [void]$sb.AppendLine("- No compact rules extracted")
        }
        [void]$sb.AppendLine()
    }
}

# --- Unassigned compact rules ---
if ($unassigned.Count -gt 0) {
    [void]$sb.AppendLine("### *(Unassigned Skills)*")
    [void]$sb.AppendLine()
    foreach ($sk in ($unassigned | Sort-Object Name)) {
        [void]$sb.AppendLine("#### $($sk.Name)")
        [void]$sb.AppendLine()
        if ($sk.Rules.Count -gt 0) {
            foreach ($r in $sk.Rules) { [void]$sb.AppendLine("$r") }
        } else {
            [void]$sb.AppendLine("- No compact rules extracted")
        }
        [void]$sb.AppendLine()
    }
}

# --- Project conventions ---
[void]$sb.AppendLine("## Project Conventions")
[void]$sb.AppendLine()
[void]$sb.AppendLine("| File | Path |")
[void]$sb.AppendLine("|------|------|")

$conventionFiles = @(
    "docs/AGENTS.md", "CLAUDE.md", ".cursorrules",
    "config/orchestrator.json", "config/auto-delegation.json",
    "config/model-routing.json", "rules/DELEGATION-RULES.md",
    "rules/DEVELOPMENT-STANDARDS.md", "openspec/config.yaml"
)
foreach ($f in $conventionFiles) {
    $fullPath = Join-Path $WorkspaceRoot $f
    if (Test-Path $fullPath) { [void]$sb.AppendLine("| $f | $fullPath |") }
}

[void]$sb.AppendLine()
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("*Auto-generated by build-skill-registry.ps1*")

# --- Write ---
$atlDir = Split-Path $registryPath -Parent
if (-not (Test-Path $atlDir)) { New-Item -ItemType Directory -Path $atlDir -Force | Out-Null }

Set-Content -Path $registryPath -Value $sb.ToString() -Encoding UTF8

# --- Report ---
if (-not $Quiet) {
    $projectCount = ($skills | Where-Object { $_.IsProject }).Count
    $userCount = ($skills | Where-Object { -not $_.IsProject }).Count
    $assignedCount = $skillData | Where-Object { $_.RoleCode }
    Write-Host "[SKILL-REGISTRY] Written: $registryPath"
    Write-Host "[SKILL-REGISTRY] Skills: $projectCount project + $userCount user = $($skillData.Count) total"
    Write-Host "[SKILL-REGISTRY] Segmented: $($assignedCount.Count) assigned to agents, $($unassigned.Count) unassigned"
    Write-Host "[SKILL-REGISTRY] Agent groups: $(($grouped | Measure-Object).Count)"
}

return @{ Status = "OK"; Path = $registryPath; Count = $skillData.Count }
