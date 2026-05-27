param(
    [Parameter(Mandatory=$true)][string]$InputPath,
    [string]$OutputPath,
    [switch]$ShowStats,
    [switch]$Aggressive
)
$content = Get-Content $InputPath -Raw
$original = $content.Length

$replacements = @{
    "implementation"="impl";"function"="fn";"configuration"="cfg"
    "required"="req";"optional"="opt";"reference"="ref"
    "standard"="std";"performance"="perf";"security"="sec"
    "development"="dev";"production"="prod";"environment"="env"
    "database"="db";"application"="app";"service"="svc"
    "repository"="repo";"directory"="dir";"parameter"="param"
    "argument"="arg";"attribute"="attr";"property"="prop"
    "variable"="var";"temporary"="tmp";"temporal"="tmp"
    "previous"="prev";"current"="curr";"initial"="init"
    "increment"="inc";"decrement"="dec";"maximum"="max"
    "minimum"="min";"average"="avg";"between"="b/w"
    "because"="b/c";"before"="b4";"after"="aft"
    "navigate"="nav";"management"="mgmt"
    "authentication"="auth";"authorization"="authz"
    "information"="info";"documentation"="docs"
    "notification"="notif";"optimization"="opt"
    "conversation"="conv";"communication"="comm"
    "additional"="addl";"autonomous"="auto"
    "automatic"="auto";"caching"="cache"
    "compression"="compress";"identifier"="id"
}
foreach ($r in $replacements.Keys) {
    $content = $content -replace "(?<!\w)$r(?!\w)", $replacements[$r]
}
$content = $content -replace '(?s)<!--.*?-->', ''
$content = $content -replace "`r`n", "`n"
$content = $content -replace "`n`n`n+", "`n`n"
if ($Aggressive) {
    $content = $content -replace "`n-{3,}`n", "`n---`n"
    $content = $content -replace ' +\n', "`n"
}
$final = $content.Length
$saved = $original - $final
if ($ShowStats) {
    $pct = [Math]::Round($saved / $original * 100, 1)
    Write-Host "Orig:${original} -> Comp:${final} -> Saved:${saved} (${pct}%)"
}
if ($OutputPath) {
    $content | Set-Content $OutputPath -NoNewline
}
return $content