param(
    [Parameter(Mandatory=$true)]
    [string]$UserInput,
    [string]$WorkspaceRoot = "."
)

# Pre-processing was removed in Phase 1 cleanup.
# Input is passed directly to the LLM without transformation.
exit 0
