param(
    [Parameter(Mandatory = $true)]
    [string]$StagedFiles
)

# scan-skill.ps1 was removed during Phase 1 cleanup.
# Skill validation is now handled by karpathy-enforcer and skill-scan hooks.
exit 0
