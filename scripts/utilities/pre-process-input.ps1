param(
    [Parameter(Mandatory=$true)]
    [string]$UserInput,
    [string]$WorkspaceRoot = "."
)

$realScript = Join-Path $PSScriptRoot 'utils' 'pre-process-input.ps1'
$realScript = Resolve-Path $realScript -ErrorAction Stop
& $realScript -UserInput $UserInput -WorkspaceRoot $WorkspaceRoot
exit $LASTEXITCODE
