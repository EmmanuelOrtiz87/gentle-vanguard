param([Parameter(Mandatory=$true)][string]$PromptContent)
$issues=@()
if($PromptContent -match "password"){$issues+="Potential secret"}
if($PromptContent -match "<script>"){$issues+="XSS detected"}
if($PromptContent -match "\.\./"){$issues+="Path traversal"}
if($PromptContent -match "DROP TABLE"){$issues+="SQL injection"}
if($issues.Count -eq 0){Write-Output "PASSED"}else{Write-Output "ISSUES:";$issues|ForEach-Object{Write-Output "  - $_"}}
