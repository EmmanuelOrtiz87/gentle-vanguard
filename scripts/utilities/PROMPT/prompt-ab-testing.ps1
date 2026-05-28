param([Parameter(Mandatory=$true)][string]$Action,[string]$TestName,[string]$VariantA,[string]$VariantB,[string]$ResultsDir=".session/ab-tests")
if(-not(Test-Path $ResultsDir)){New-Item -ItemType Directory -Path $ResultsDir -Force|Out-Null}
switch($Action){
    "create"{$test=@{Name=$TestName;VariantA=$VariantA;VariantB=$VariantB;Created=(Get-Date -Format "o");Status="active"};$test|ConvertTo-Json|Set-Content (Join-Path $ResultsDir "$TestName.json");Write-Host "Created test: $TestName"}
    "record"{Write-Host "Recording result for: $TestName"}
    "analyze"{Write-Host "Analyzing test results"}
    "winner"{Write-Host "Selecting winning variant"}
}
