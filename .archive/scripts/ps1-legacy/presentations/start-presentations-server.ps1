param(
  [int]$Port = 3000,
  [switch]$NoBrowser,
  [switch]$Quiet
)

$LogPath = ".runtime/presentations-server.log"
$PresentationsDir = "docs/presentations"

$HostIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
  $_.IPAddress -notmatch '^(127\.|169\.254\.)' -and $_.InterfaceAlias -notmatch 'Loopback|Bluetooth|vEthernet|Virtual|Hyper-V|Docker|veth'
} | Select-Object -First 1).IPAddress

if (-not $HostIP) { $HostIP = "127.0.0.1" }

$Banner = @"

  ██████╗ ███████╗███╗   ██╗████████╗██╗     ███████╗
 ██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝██║     ██╔════╝
 ██║  ███╗█████╗  ██╔██╗ ██║   ██║   ██║     █████╗
 ██║   ██║██╔══╝  ██║╚██╗██║   ██║   ██║     ██╔══╝
 ╚██████╔╝███████╗██║ ╚████║   ██║   ███████╗███████╗
  ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚══════╝

    ██╗   ██╗ █████╗ ███╗   ██╗ ██████╗ ██╗   ██╗ █████╗ ██████╗ ██████╗
    ██║   ██║██╔══██╗████╗  ██║██╔════╝ ██║   ██║██╔══██╗██╔══██╗██╔══██╗
    ██║   ██║███████║██╔██╗ ██║██║      ██║   ██║███████║██████╔╝██║  ██║
    ╚██╗ ██╔╝██╔══██║██║╚██╗██║██║      ██║   ██║██╔══██║██╔══██╗██║  ██║
     ╚████╔╝ ██║  ██║██║ ╚████║╚██████╗ ╚██████╔╝██║  ██║██║  ██║██████╔╝
      ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝

  ██████╗ ██████╗ ███████╗███████╗███████╗███╗   ██╗████████╗ █████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗
  ██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝████╗  ██║╚══██╔══╝██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
  ██████╔╝██████╔╝█████╗  ███████╗█████╗  ██╔██╗ ██║   ██║   ███████║   ██║   ██║██║   ██║██╔██╗ ██║███████╗
  ██╔═══╝ ██╔══██╗██╔══╝  ╚════██║██╔══╝  ██║╚██╗██║   ██║   ██╔══██║   ██║   ██║██║   ██║██║╚██╗██║╚════██║
  ██║     ██║  ██║███████╗███████║███████╗██║ ╚████║   ██║   ██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║███████║
  ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

"@

$Info = @"
  Local:    http://localhost:$Port
  Network:  http://${HostIP}:$Port
  Log:      $LogPath
  Dir:      $PresentationsDir

"@

if (-not $Quiet) {
  Write-Host $Banner -ForegroundColor Cyan
  Write-Host $Info -ForegroundColor Yellow
}

$LogDir = Split-Path -Parent $LogPath
if (-not (Test-Path -LiteralPath $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$Timestamp] Presentations server starting on port $Port..." | Out-File -FilePath $LogPath -Encoding utf8

function Write-Log {
  param([string]$Message)
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  "[$ts] $Message" | Out-File -FilePath $LogPath -Append -Encoding utf8
}

function Start-NpxServe {
  $server = Start-Process -FilePath "npx" -ArgumentList "serve", $PresentationsDir, "-l", $Port, "-n" -PassThru -NoNewWindow
  Write-Log "Started npx serve (PID: $($server.Id))"
  return $server
}

function Start-PythonServer {
  $server = Start-Process -FilePath "python" -ArgumentList "-m", "http.server", $Port, "--directory", $PresentationsDir -PassThru -NoNewWindow
  Write-Log "Started Python http.server (PID: $($server.Id))"
  return $server
}

function Start-PowerShellListener {
  $listenerCode = @"
    `$listener = New-Object System.Net.HttpListener
    `$listener.Prefixes.Add("http://+:$Port/")
    `$listener.Start()
    Write-Log "PowerShell HttpListener started on port $Port"

    while (`$listener.IsListening) {
      `$context = `$listener.GetContext()
      `$request = `$context.Request
      `$response = `$context.Response

      `$localPath = `$request.Url.LocalPath.TrimStart('/')
      if ([string]::IsNullOrEmpty(`$localPath)) { `$localPath = "index.html" }

      `$filePath = Join-Path -Path "$PresentationsDir" -ChildPath `$localPath
      `$filePath = `$filePath.Replace('/', [IO.Path]::DirectorySeparatorChar)

      Write-Log "GET `$localPath -> `$filePath"

      if (Test-Path -LiteralPath `$filePath -PathType Leaf) {
        `$content = [IO.File]::ReadAllBytes(`$filePath)
        `$ext = [IO.Path]::GetExtension(`$filePath).ToLower()
        `$mime = @{
          '.html' = 'text/html'; '.htm' = 'text/html'
          '.css'  = 'text/css'; '.js' = 'application/javascript'
          '.json' = 'application/json'; '.png' = 'image/png'
          '.jpg'  = 'image/jpeg'; '.jpeg' = 'image/jpeg'
          '.gif'  = 'image/gif'; '.svg' = 'image/svg+xml'
          '.ico'  = 'image/x-icon'; '.pdf' = 'application/pdf'
          '.md'   = 'text/markdown'; '.txt' = 'text/plain'
          '.woff2' = 'font/woff2'; '.woff' = 'font/woff'
        }
        `$response.ContentType = if (`$mime.ContainsKey(`$ext)) { `$mime[`$ext] } else { 'application/octet-stream' }
        `$response.ContentLength64 = `$content.Length
        `$response.OutputStream.Write(`$content, 0, `$content.Length)
      } else {
        `$response.StatusCode = 404
        `$notFound = [Text.Encoding]::UTF8.GetBytes("<h1>404 - Not Found</h1><p>`$localPath</p>")
        `$response.ContentLength64 = `$notFound.Length
        `$response.OutputStream.Write(`$notFound, 0, `$notFound.Length)
      }
      `$response.Close()
    }
"@
  $listenerJob = Start-Job -ScriptBlock ([scriptblock]::Create($listenerCode))
  Write-Log "Started PowerShell HttpListener (Job ID: $($listenerJob.Id))"
  return $listenerJob
}

$ServerType = ""
$Process = $null

if (Get-Command "node" -ErrorAction SilentlyContinue) {
  Write-Log "Node.js found, trying npx serve..."
  try {
    $null = & npx --yes serve --version 2>&1
    $Process = Start-NpxServe
    $ServerType = "npx serve"
  } catch {
    Write-Log "npx serve not available, falling back..."
  }
}

if (-not $Process -and (Get-Command "python" -ErrorAction SilentlyContinue)) {
  Write-Log "Python found, trying http.server..."
  try {
    $Version = & python --version 2>&1
    if ($Version -match 'Python 3') {
      $Process = Start-PythonServer
      $ServerType = "Python http.server"
    }
  } catch {
    Write-Log "Python http.server failed, falling back..."
  }
}

if (-not $Process) {
  Write-Log "Using PowerShell HttpListener fallback..."
  $Process = Start-PowerShellListener
  $ServerType = "PowerShell HttpListener"
}

Write-Log "Server running ($ServerType) on port $Port"

if (-not $Quiet) {
  Write-Host "  Server:   " -NoNewline -ForegroundColor Green
  Write-Host "$ServerType" -ForegroundColor White
  Write-Host "  Status:   " -NoNewline -ForegroundColor Green
  Write-Host "RUNNING" -ForegroundColor Green
  Write-Host ""
  Write-Host "  QR Code:  https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=http://${HostIP}:${Port}" -ForegroundColor DarkGray
  Write-Host ""
  Write-Host "  Press Ctrl+C to stop the server" -ForegroundColor DarkGray
  Write-Host ""
}

if (-not $NoBrowser) {
  Start-Process "http://localhost:$Port"
  Write-Log "Browser opened to http://localhost:$Port"
}

Write-Log "Server ready. Listening on port $Port."

$handler = {
  Write-Log "Server stopping (Ctrl+C)..."
  if (-not $Quiet) {
    Write-Host ""
    Write-Host "  Server stopped." -ForegroundColor Yellow
  }
  $global:ServerStopped = $true
}
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action $handler | Out-Null

try {
  if ($Process -is [System.Diagnostics.Process]) {
    $Process.WaitForExit()
  } else {
    while (-not $global:ServerStopped) { Start-Sleep -Seconds 1 }
  }
} finally {
  Write-Log "Server stopped."
  if (-not $Quiet) { Write-Host "  Log: $LogPath" -ForegroundColor DarkGray }
}
