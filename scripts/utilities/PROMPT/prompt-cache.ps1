param([Parameter(Mandatory=$true)][string]$Action,[string]$PromptHash,[string]$PromptContent,[string]$CacheDir=".session/prompt-cache")
if(-not(Test-Path $CacheDir)){New-Item -ItemType Directory -Path $CacheDir -Force|Out-Null}
switch($Action){
    "get"{$path=Join-Path $CacheDir "$PromptHash.txt";if(Test-Path $path){Get-Content $path -Raw}else{$null}}
    "set"{$path=Join-Path $CacheDir "$PromptHash.txt";$PromptContent|Set-Content $path;Write-Host "Cached: $PromptHash"}
    "clear"{Remove-Item -Path "$CacheDir\*.txt" -Force -ErrorAction SilentlyContinue;Write-Host "Cache cleared"}
    "stats"{$count=(Get-ChildItem $CacheDir -Filter "*.txt" -ErrorAction SilentlyContinue).Count;Write-Host "Cached: $count prompts"}
}
