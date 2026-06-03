param(
    [string]$Type = '',
    [string]$Detail = '',
    [int]$Tokens = 0,
    [int]$ToolCalls = 1,
    [int]$FilesRead = 0,
    [int]$FilesWritten = 0,
    [int]$FilesEdited = 0
)

$ErrorActionPreference = 'Continue'
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path

# Try POST to metrics-server first (fast path)
try {
    $body = @{ type = $Type; detail = $Detail; tokens = $Tokens; toolCalls = $ToolCalls; filesRead = $FilesRead; filesWritten = $FilesWritten; filesEdited = $FilesEdited } | ConvertTo-Json
    Invoke-WebRequest -Uri 'http://localhost:8090/api/ingest' -Method POST -Body $body -ContentType 'application/json' -UseBasicParsing -TimeoutSec 2 | Out-Null
} catch {
    # Fallback: write directly via telemetry-writer
    & "$repo\metrics\telemetry-writer.ps1" -Action event -EventType $Type -Detail $Detail -Tokens $Tokens -ToolCalls $ToolCalls -FilesRead $FilesRead -FilesWritten $FilesWritten -FilesEdited $FilesEdited
}
