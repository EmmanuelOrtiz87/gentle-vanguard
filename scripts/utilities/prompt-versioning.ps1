param([Parameter(Mandatory=$true)][string]$Action,[string]$PromptName,[string]$Content,[string]$VersionDir=".session/prompt-versions")
if(-not(Test-Path $VersionDir)){New-Item -ItemType Directory -Path $VersionDir -Force|Out-Null}
switch($Action){
    "save"{$v=(Get-Date -Format "yyyyMMdd-HHmmss");$path=Join-Path $VersionDir "$PromptName-$v.md";$Content|Set-Content $path;Write-Output "SAVED:$v"}
    "list"{$versions=Get-ChildItem $VersionDir -Filter "$PromptName-*.md"|Sort-Object Name -Descending;Write-Output "VERSIONS:";$versions|ForEach-Object{Write-Output $_.Name}}
    "diff"{Write-Output "DIFF"}
    "rollback"{Write-Output "ROLLBACK"}
}
