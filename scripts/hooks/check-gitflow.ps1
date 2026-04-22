# check-gitflow.ps1
# Valida convenciones de gitflow y mensajes de commit

$ErrorActionPreference = 'Continue'

# Bloquear commits directos a main/master
$branch = git rev-parse --abbrev-ref HEAD
if ($branch -eq 'main' -or $branch -eq 'master') {
    Write-Host "[GITFLOW] No se permite commit directo a $branch. Usa PR." -ForegroundColor Red
    exit 1
}

# Validar mensaje de commit (convencional)
$commitMsg = git log -1 --pretty=%B
if ($commitMsg -notmatch '^(feat|fix|docs|style|refactor|test|chore)\:') {
    Write-Host "[GITFLOW] Mensaje de commit no sigue convencin convencional (feat:, fix:, etc.)" -ForegroundColor Yellow
    exit 1
}

Write-Host "[GITFLOW] Convenciones gitflow validadas." -ForegroundColor Green
exit 0
