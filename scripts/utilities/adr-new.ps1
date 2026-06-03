param(
    [Parameter(Mandatory, Position=0)]
    [string]$Title,
    [Parameter(Position=1)]
    [string]$Number = '',
    [string]$Author = '',
    [string]$Status = 'Proposed',
    [string]$Context = '',
    [switch]$Open,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$adrDir = Join-Path $repoRoot 'docs\architecture\decisions'

if (-not (Test-Path $adrDir)) {
    New-Item -ItemType Directory -Path $adrDir -Force | Out-Null
}

$existing = @(Get-ChildItem $adrDir -Filter 'ADR-*.md')
$nextNum = if ([string]::IsNullOrWhiteSpace($Number)) {
    $max = 0
    foreach ($f in $existing) {
        if ($f.BaseName -match 'ADR-0*(\d+)') {
            $n = [int]$Matches[1]
            if ($n -gt $max) { $max = $n }
        }
    }
    $max + 1
} else {
    [int]$Number
}

$slug = $Title.ToLowerInvariant() -replace '[^a-z0-9]+', '-' -replace '-+', '-' -replace '^-|-$', ''
$filename = "ADR-$(($nextNum).ToString('D3'))-$slug.md"
$filePath = Join-Path $adrDir $filename

if ((Test-Path $filePath) -and -not $Force) {
    Write-Error "ADR already exists: $filename — use -Force to overwrite"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Author)) {
    try { $Author = git config user.name 2>$null } catch { $Author = 'Gentle-Vanguard Team' }
}

$date = Get-Date -Format 'MMMM yyyy'
$today = Get-Date -Format 'yyyy-MM-dd'

$content = @"---
# ADR-$(($nextNum).ToString('D3')): $Title

**Status**: $Status
**Date**: $today
**Author**: $Author
**Context**: $(if ($Context) { $Context } else { 'TBD' })

---

## Context

[Describe the problem, context, constraints, and decision drivers]

### Alternatives Considered

| Option | Pros | Cons | Chosen? |
| ------ | ---- | ---- | ------- |
| **A**  |      |      |         |
| B      |      |      |         |

---

## Decision

[What we decided and why]

### Rationale

1.

---

## Consequences

### Positive

- [+]

### Negative

- [-]

### Mitigation

-

---

## Related Decisions

- `ADR-XXX-example.md`

---

## References

-

---

**Review Date**: Q4 $((Get-Date).Year)
**Reviewers**: Gentle-Vanguard Team
**Status**: Proposed

"@

$content | Set-Content -Path $filePath -Encoding UTF8

Write-Host "[ADR] Created: $filename" -ForegroundColor Green
Write-Host "[ADR] Path: $filePath" -ForegroundColor Cyan
Write-Host "[ADR] Number: $(($nextNum).ToString('D3'))" -ForegroundColor Gray
Write-Host "" -ForegroundColor Gray
Write-Host "[HINT] Edit the file to fill Context, Decision, Consequences sections" -ForegroundColor Yellow
Write-Host "[HINT] Update docs/architecture/decisions/README.md to add to the table" -ForegroundColor Yellow

if ($Open) { Start-Process $filePath }
exit 0
