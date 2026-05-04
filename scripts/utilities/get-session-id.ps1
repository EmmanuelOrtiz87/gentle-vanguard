# get-session-id.ps1
# Obtiene el Session ID mas reciente y lo devuelve

$sessionFile = Get-ChildItem '.\.session\session-*.json' -File -ErrorAction SilentlyContinue | 
               Sort-Object LastWriteTime -Descending | 
               Select-Object -First 1

if ($sessionFile) {
    Write-Output $sessionFile.BaseName
}
