param(
    [Parameter(Mandatory = $true)]
    [string]$StateFile,
    [Parameter(Mandatory = $true)]
    [string]$MessageFile,
    [Parameter(Mandatory = $true)]
    [string]$DayEndScript,
    [Parameter(Mandatory = $true)]
    [string]$SessionId,
    [int]$IdleTimeoutMinutes = 60
)

$ErrorActionPreference = 'Stop'

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class IdleTime {
  [StructLayout(LayoutKind.Sequential)]
  struct LASTINPUTINFO {
    public uint cbSize;
    public uint dwTime;
  }
  [DllImport("user32.dll")]
  static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
  public static uint GetIdleMilliseconds() {
    LASTINPUTINFO lii = new LASTINPUTINFO();
    lii.cbSize = (uint)System.Runtime.InteropServices.Marshal.SizeOf(lii);
    if (!GetLastInputInfo(ref lii)) return 0;
    return (uint)Environment.TickCount - lii.dwTime;
  }
}
"@

function Load-State {
    if (-not (Test-Path $StateFile)) { return $null }
    try { return (Get-Content -Path $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}

function Save-State {
    param([pscustomobject]$State)
    $State | ConvertTo-Json -Depth 8 | Set-Content -Path $StateFile -Encoding UTF8
}

function Set-StateValue {
    param(
        [psobject]$State,
        [string]$Name,
        $Value
    )

    if ($State.PSObject.Properties[$Name]) {
        $State.$Name = $Value
    } else {
        $State | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }
}

function Write-Message {
    param([string]$Text)
    $dir = Split-Path -Parent $MessageFile
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Set-Content -Path $MessageFile -Value $Text -Encoding UTF8
}

while ($true) {
    $state = Load-State
    if (-not $state) { exit 0 }
    if ([string]$state.status -ne 'active') { exit 0 }

    $idleMinutes = [math]::Floor(([IdleTime]::GetIdleMilliseconds() / 1000.0) / 60.0)
    if ($idleMinutes -ge $IdleTimeoutMinutes) {
        try {
            & $DayEndScript -SessionId $SessionId -AutoTriggered -SkipValidation -SkipRotation -Force | Out-Null
            $closedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            $msg = @"
[AUTO-CLOSE] Session ended due to inactivity.
Project: workspace_local
Session: $SessionId
Reason: $idleMinutes minutes of inactivity (timeout: $IdleTimeoutMinutes minutes)
Closed at: $closedAt
Actions executed:
- day-end-closure.ps1 -SessionId $SessionId -AutoTriggered -SkipValidation -SkipRotation -Force
- Delivery closure and Engram memory capture requested

To continue with all tools active, start a new session:
1) Auto   -> .\tools\session-autostart.cmd
2) Manual -> .\tools\session-manual-start.cmd
"@
            Write-Message -Text $msg

            Set-StateValue -State $state -Name 'status' -Value 'closed-idle-timeout'
            Set-StateValue -State $state -Name 'closedAt' -Value ((Get-Date).ToString('s'))
            Set-StateValue -State $state -Name 'monitorPid' -Value $null
            Save-State -State $state
        }
        catch {
            $errorMessage = $_.Exception.Message
            $msg = @"
[AUTO-CLOSE] Idle timeout reached, but closure had errors.
Project: workspace_local
Session: $SessionId
Reason: $idleMinutes minutes of inactivity (timeout: $IdleTimeoutMinutes minutes)
Error: $errorMessage

Please run manual closure:
1) scripts\utilities\session-manual-end.cmd
Then start again:
2) scripts\utilities\session-autostart.cmd
"@
            Write-Message -Text $msg
        }
        exit 0
    }

    Start-Sleep -Seconds 60
}