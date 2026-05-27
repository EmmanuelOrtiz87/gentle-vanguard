param([Parameter(Mandatory=$true)][string]$PromptContent,[Parameter(Mandatory=$true)][ValidateSet("openai","anthropic","google","local")][string]$TargetModel)
$adapted=$PromptContent
switch($TargetModel){
    "openai"{$adapted="# System`n$PromptContent`n# User`n{input}"}
    "anthropic"{$adapted="<instructions>$PromptContent</instructions>`n<user>{input}</user>"}
    "google"{$adapted="system:`n$PromptContent`n`nuser: {input}"}
    "local"{$adapted="### System`n$PromptContent`n### User`n{input}"}
}
Write-Output $adapted
