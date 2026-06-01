param(
    [Parameter(Mandatory = $true)]
    [string]$StagedFiles
)

$StagedFiles.Split(' ',[StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object {
    & 'scripts/security/scan-skill.ps1' -Path $_ -ThresholdScore 80 -PassThru | Out-Null
}
