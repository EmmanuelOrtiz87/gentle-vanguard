#Requires -Version 7.0
# Shared functions for dashboard port allocation and state persistence

function Get-FreePort {
    param(
        [int]$Preferred = 8080,
        [int]$MaxAttempts = 50
    )
    for ($i = 0; $i -lt $MaxAttempts; $i++) {
        $port = $Preferred + $i
        $inUse = $null
        try {
            $inUse = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue |
                Where-Object { $_.State -eq 'Listen' -or $_.State -eq 'Established' -or $_.State -eq 'Bound' }
        } catch {
            # fallback: try a simple test bind
            try {
                $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)
                $listener.Start()
                $listener.Stop()
                return $port
            } catch { continue }
        }
        if (-not $inUse) { return $port }
    }
    return $Preferred  # give up, let caller handle error
}

function Save-DashboardPorts {
    param(
        [int]$WsPort,
        [int]$VitePort
    )
    $portsFile = Join-Path $repoRoot '.runtime' 'dashboard-ports.json'
    $dir = Split-Path $portsFile -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    @{
        wsPort   = $WsPort
        vitePort = $VitePort
        updated  = (Get-Date -Format 'o')
    } | ConvertTo-Json | Set-Content $portsFile -Force
}

function Read-DashboardPorts {
    $portsFile = Join-Path $repoRoot '.runtime' 'dashboard-ports.json'
    if (Test-Path $portsFile) {
        try {
            return Get-Content $portsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch { return $null }
    }
    return $null
}

function Clear-DashboardPorts {
    $portsFile = Join-Path $repoRoot '.runtime' 'dashboard-ports.json'
    Remove-Item -Path $portsFile -Force -ErrorAction SilentlyContinue
}

function Get-ProcessIdByPort {
    param([int]$Port)
    try {
        $conn = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
            Where-Object { $_.State -eq 'Listen' }
        if ($conn) {
            return $conn.OwningProcess | Select-Object -First 1
        }
    } catch {}
    return $null
}
