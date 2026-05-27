param([Parameter(Mandatory=$true)][string]$InputPath,[string]$OutputPath,[switch]$ShowStats)
$content=Get-Content $InputPath -Raw
$original=$content.Length
$replacements=@{"implementation"="impl";"function"="fn";"configuration"="cfg";"required"="req";"optional"="opt";"reference"="ref";"standard"="std";"performance"="perf";"security"="sec";"development"="dev";"production"="prod";"environment"="env";"database"="db";"application"="app";"service"="svc";"repository"="repo";"directory"="dir"}
foreach($r in $replacements.Keys){$content=$content-replace"\b$r\b",$replacements[$r]}
$final=$content.Length
if($ShowStats){Write-Host "Original: $original, Compressed: $final, Saved: $($original-$final)"}
if($OutputPath){$content|Set-Content $OutputPath}
