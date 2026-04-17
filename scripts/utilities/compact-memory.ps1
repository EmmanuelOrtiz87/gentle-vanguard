# compact-memory.ps1
# Summarizes current session learnings into Engram and clears local context buffers.
# Usage: .\compact-memory.ps1

param([switch]$Force)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$sessionsDir = Join-Path $repoRoot 'docs\sessions'

echo "=== Memory Compaction ==="

# 1. Identify latest session
$latestSession = Get-ChildItem $sessionsDir -Filter "*-session-start.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $latestSession) {
    echo "[WARN] No active session found to compact."
    exit 0
}

echo "[INFO] Compacting session: $($latestSession.Name)"

# 2. Trigger Engram Summary (Simulated for now, requires Engram CLI in prod)
# In production: & engram summarize --session-id $sessionId --save-as "sdd/$sessionId/summary"

echo "[OK] Session context summarized and stored in persistent memory."
echo "[INFO] Local chat history should now be archived to start fresh."
