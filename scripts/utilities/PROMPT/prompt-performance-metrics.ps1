param([Parameter(Mandatory=$true)][string]$Action,[string]$MetricName,[object]$Value,[string]$MetricsDir=".session/prompt-metrics")
if(-not(Test-Path $MetricsDir)){New-Item -ItemType Directory -Path $MetricsDir -Force|Out-Null}
switch($Action){
    "record"{$file=Join-Path $MetricsDir "$(Get-Date -Format 'yyyy-MM').csv";"$(Get-Date -Format 'o'),$MetricName,$Value"|Add-Content $file;Write-Host "Recorded: $MetricName = $Value"}
    "report"{Write-Host "Performance report";Get-ChildItem $MetricsDir -Filter "*.csv"|ForEach-Object{Write-Host "  $($_.Name)"}}
    "analyze"{Write-Host "Analyzing trends"}
}
