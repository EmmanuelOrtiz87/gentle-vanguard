# check-gitflow.ps1
# Valida convenciones de gitflow y mensajes de commit

$ErrorActionPreference = 'Continue'

# FF-015: hook output safety
$_safety = Join-Path $PSScriptRoot 'hook-output-safety.ps1'
if (Test-Path $_safety) { . $_safety }
function _Wh { param([string]$M,[string]$C='White')
    if (Get-Command 'Write-SafeHook' -EA SilentlyContinue) { Write-SafeHook $M -Color $C } else { Write-Host $M -ForegroundColor $C } }

# Bloquear commits directos a main/master
$branch = git rev-parse --abbrev-ref HEAD
if ($branch -eq 'main' -or $branch -eq 'master') {
    _Wh "[GITFLOW] No se permite commit directo a $branch. Usa PR." Red
    exit 1
}

# Validar mensaje de commit (convencional)
$commitMsg = git log -1 --pretty=%B
if ($commitMsg -notmatch '^(feat|fix|docs|style|refactor|test|chore)\:') {
    _Wh "[GITFLOW] Mensaje de commit no sigue convencion convencional (feat:, fix:, etc.)" Yellow
    exit 1
}

_Wh "[GITFLOW] Convenciones gitflow validadas." Green
exit 0
