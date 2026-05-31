param([string]$ToolName = "", [string]$ToolArgs = "")
$ErrorActionPreference = 'Continue'
$hookDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $hookDir
$autoScript = Join-Path $repoRoot "scripts\utilities\TOKEN\token-usage-auto.ps1"
if (-not (Test-Path $autoScript)) { exit 0 }
$ctxChars = if ($ToolArgs) { [math]::Max(1, [math]::Floor($ToolArgs.Length * 1.5)) } else { 0 }
$turnLabel = if ($ToolName) { "tool:$ToolName" } else { "auto-hook" }
& $autoScript -InputTokens 0 -OutputTokens 0 -ContextChars $ctxChars -TurnLabel $turnLabel -Model "auto-detected"
exit 0