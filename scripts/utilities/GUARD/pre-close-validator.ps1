param(
    [string]$WorkspaceRoot,
    [switch]$Json
)
$uncommitted = @(git -C $WorkspaceRoot status --porcelain 2>$null)
$result = @{
    Status = if ($uncommitted.Count -eq 0) { "clean" } else { "dirty" }
    UncommittedFiles = $uncommitted.Count
    Timestamp = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
}
if ($Json) { $result | ConvertTo-Json } else { $result }