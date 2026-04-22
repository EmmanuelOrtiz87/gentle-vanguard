# handoff-compress.ps1
# Compresses context for agent handoff - outputs only state + decisions
# Usage: .\handoff-compress.ps1 -Input "<context>" [-OutputFile "<path>"]

param(
    [Parameter(Mandatory=$true)]
    [string]$Input,
    [string]$OutputFile = ''
)

function Compress-HandoffContext {
    param([string]$context)

    $lines = $context -split "`n"
    $compressed = @()

    foreach ($line in $lines) {
        if ($line -match '^\s*[-*#]\s*$') { continue }
        if ($line -match '^\s*$') { continue }
        if ($line -match '^\s*//' -or $line -match '^\s*#') {
            if ($line -match '(FIXED|BUG|DECISION|RESULT|STATUS|OK|ERROR)') {
                $compressed += $line
            }
            continue
        }
        if ($line -match '^(##|###)\s') {
            $compressed += $line
            continue
        }
        if ($line -match '^\|.*\|\s*$') {
            $compressed += $line
            continue
        }
        if ($line.Length -lt 200) {
            $compressed += $line
        } else {
            $truncated = $line.Substring(0, 180) + "..."
            $compressed += $truncated
        }
    }

    return ($compressed -join "`n")
}

$result = Compress-HandoffContext -context $Input

if ($OutputFile) {
    $result | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "[OK] Handoff compressed to: $OutputFile"
} else {
    Write-Output $result
}