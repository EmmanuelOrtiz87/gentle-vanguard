param(
    [Parameter(ParameterSetName="Resolve")]
    [switch]$ResolveUser,
    [Parameter(ParameterSetName="Format")]
    [string]$Format = "",
    [Parameter(ParameterSetName="Format")]
    [string]$ArtifactType = "audit",
    [Parameter(ParameterSetName="Format")]
    [string]$Extension = "md",
    [Parameter(ParameterSetName="Format")]
    [string]$Timestamp = "",
    [Parameter(ParameterSetName="Lock")]
    [switch]$AcquireLock,
    [Parameter(ParameterSetName="Lock")]
    [switch]$ReleaseLock,
    [Parameter(ParameterSetName="Lock")]
    [string]$LockName = "",
    [Parameter()]
    [string]$ConfigPath = "config/orchestrator.json"
)

function Get-CanonicalUser {
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $sources = $config.subagent_orchestration.artifact_naming.username_sources
    $sanitize = $config.subagent_orchestration.artifact_naming.sanitize

    $user = $null
    foreach ($src in $sources) {
        if ($src -match '^\$env:(.+)') {
            $val = [Environment]::GetEnvironmentVariable($Matches[1])
            if ($val) { $user = $val; break }
        }
        elseif ($src -match '^git config (.+)') {
            try {
                $val = git config --global $Matches[1] 2>$null
                if ($val) { $user = $val; break }
            } catch {}
        }
    }
    if (-not $user) { $user = "unknown" }

    if ($sanitize) {
        $user = $user -replace '[^\w.-]', '_' -replace '^[^a-zA-Z]+', ''
        if ($user.Length -eq 0) { $user = "unknown" }
    }
    return $user.ToLowerInvariant()
}

function Format-ArtifactName {
    param(
        [string]$Type,
        [string]$Ext,
        [string]$TimestampRaw
    )

    $user = Get-CanonicalUser
    if (-not $TimestampRaw) {
        $TimestampRaw = (Get-Date -Format "yyyy-MM-dd-HHmmss")
    }
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $sep = $config.subagent_orchestration.artifact_naming.separator

    $templateMap = @{
        "audit"     = ".audit/audits/${user}${sep}audit_${TimestampRaw}.${Ext}"
        "budget"    = ".audit/budgets/${user}${sep}budget_${TimestampRaw}.${Ext}"
        "telemetry" = ".audit/telemetry/${user}${sep}telemetry_${TimestampRaw}.${Ext}"
        "session"   = ".session/${user}${sep}session-${TimestampRaw}.json"
        "report"    = ".session/reports/${user}${sep}report_${TimestampRaw}.${Ext}"
        "review"    = "docs/code-reviews/${user}${sep}${TimestampRaw}-session-review.${Ext}"
        "metric"    = "docs/sessions/metrics/${user}${sep}${Type}_${TimestampRaw}.${Ext}"
        "trace"     = ".telemetry/${user}${sep}${Type}_${TimestampRaw}.${Ext}"
    }

    $template = $templateMap[$Type]
    if (-not $template) {
        $template = "${user}${sep}${Type}_${TimestampRaw}.${Ext}"
    }

    $dir = Split-Path $template -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    return $template
}

function Invoke-FileLock {
    param(
        [string]$TargetFile,
        [switch]$Acquire,
        [switch]$Release
    )

    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $lockDir = $config.subagent_orchestration.artifact_naming.file_locking.lock_directory
    $retries = $config.subagent_orchestration.artifact_naming.file_locking.retry_attempts
    $delayMs = $config.subagent_orchestration.artifact_naming.file_locking.retry_delay_ms

    if (-not (Test-Path $lockDir)) {
        New-Item -ItemType Directory -Path $lockDir -Force | Out-Null
    }

    $lockFile = Join-Path $lockDir "$([System.IO.Path]::GetFileName($TargetFile)).lock"

    if ($Acquire) {
        for ($i = 0; $i -lt $retries; $i++) {
            try {
                $fh = [System.IO.File]::Open($lockFile, 'OpenOrCreate', 'ReadWrite', 'None')
                $lockData = @{
                    pid = $PID
                    user = Get-CanonicalUser
                    host = $env:COMPUTERNAME
                    acquired = (Get-Date -Format "o")
                }
                $sw = [System.IO.StreamWriter]::new($fh)
                $sw.Write(($lockData | ConvertTo-Json -Compress))
                $sw.Flush()
                return $fh
            } catch {
                if ($i -lt ($retries - 1)) {
                    Start-Sleep -Milliseconds $delayMs
                }
            }
        }
        throw "Could not acquire lock on $TargetFile after $retries attempts"
    }

    if ($Release) {
        if (Test-Path $lockFile) {
            Remove-Item -Path $lockFile -Force -ErrorAction SilentlyContinue
        }
    }
    return $null
}

switch ($PSCmdlet.ParameterSetName) {
    "Resolve" {
        Get-CanonicalUser
    }
    "Format" {
        Format-ArtifactName -Type $ArtifactType -Ext $Extension -TimestampRaw $Timestamp
    }
    "Lock" {
        if ($AcquireLock) {
            Invoke-FileLock -TargetFile $LockName -Acquire
        }
        elseif ($ReleaseLock) {
            Invoke-FileLock -TargetFile $LockName -Release
        }
    }
    default {
        Get-CanonicalUser
    }
}
