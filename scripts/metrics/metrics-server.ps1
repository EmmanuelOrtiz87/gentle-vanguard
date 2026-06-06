param(
    [int]$Port = 8090,
    [switch]$Daemon
)

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[$ts] $Message"
}

function Send-Json {
    param($Response, $Json, [int]$StatusCode = 200)
    $Response.StatusCode = $StatusCode
    $Response.ContentType = 'application/json'
    $Response.Headers.Add('Access-Control-Allow-Origin', '*')
    $buf = [System.Text.Encoding]::UTF8.GetBytes($Json)
    $Response.OutputStream.Write($buf, 0, $buf.Length)
}

function Send-Bytes {
    param($Response, $Bytes, $ContentType, $StatusCode = 200)
    $Response.StatusCode = $StatusCode
    $Response.ContentType = $ContentType
    $Response.Headers.Add('Access-Control-Allow-Origin', '*')
    $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
}

function Send-Text {
    param($Response, $Text, $ContentType = 'text/plain; charset=utf-8', [int]$StatusCode = 200)
    $Response.StatusCode = $StatusCode
    $Response.ContentType = $ContentType
    $Response.Headers.Add('Access-Control-Allow-Origin', '*')
    $buf = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $Response.OutputStream.Write($buf, 0, $buf.Length)
}

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$metricsDir = Join-Path $repoRoot '.runtime/metrics'
$reportsDir = Join-Path $repoRoot 'reports'
$dashFile = Join-Path $reportsDir 'dashboard.html'

$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add("http://localhost:${Port}/")
$running = $true

$serverScript = @"
<style>.export-bar{display:flex;gap:6px;margin-bottom:10px;flex-wrap:wrap}.export-bar button{border:1px solid var(--bd,#274255);background:var(--s1,#12202c);color:var(--tx,#d7e4ed);padding:5px 10px;border-radius:999px;cursor:pointer;font-weight:600;font-size:.75rem}.export-bar button:hover{background:#1d3142}</style>
<script>
;(function(){
var baseUrl = 'http://localhost:$Port';

function fetchLive(){
 fetch(baseUrl+'/api/live').then(function(r){return r.json()}).then(function(d){
   var cards = document.querySelectorAll('.cd .vl');
   if(d.tokensUsed !== undefined && cards.length>2 && cards[2]) cards[2].textContent=d.tokensUsed;
 }).catch(function(){})
}

function addExportBar(){
 var nav = document.querySelector('.nav');
 if(!nav || document.getElementById('gv-export-bar')) return;
 var bar = document.createElement('div');
 bar.id = 'gv-export-bar';
 bar.className = 'export-bar';
 bar.innerHTML = '<button onclick="gvExportPdf()"> PDF</button><button onclick="gvExportPng()"> PNG</button>';
 nav.parentNode.insertBefore(bar, nav.nextSibling);
}

window.gvExportPdf = function(){
 fetch(baseUrl+'/api/export/pdf').then(function(r){if(!r.ok)throw Error(r.status);return r.blob()}).then(function(b){
  var a=document.createElement('a');a.href=URL.createObjectURL(b);a.download='dashboard-'+new Date().toISOString().slice(0,10)+'.pdf';
  document.body.appendChild(a);a.click();document.body.removeChild(a);
 }).catch(function(){window.print()});
};

window.gvExportPng = function(){
 var sec = document.querySelector('.section.active');
 if(!sec){alert('No active section');return}
 fetch(baseUrl+'/api/export/png').then(function(r){if(!r.ok)throw Error(r.status);return r.blob()}).then(function(b){
  var a=document.createElement('a');a.href=URL.createObjectURL(b);a.download='dashboard-'+new Date().toISOString().slice(0,10)+'.png';
  document.body.appendChild(a);a.click();document.body.removeChild(a);
 }).catch(function(){
  if(typeof html2canvas==='undefined'){alert('PNG export requires html2canvas library or server-side endpoint. Use PDF instead.');return}
  html2canvas(sec,{backgroundColor:'#081016',scale:1.5,useCORS:true,logging:false}).then(function(c){var a=document.createElement('a');a.download='dashboard-export.png';a.href=c.toDataURL('image/png');a.click()}).catch(function(e){alert('PNG export failed: '+e.message)});
 });
};

setInterval(fetchLive,15000);
fetchLive();
addExportBar();
})();
</script>
"@

try {
    $http.Start()
    if (-not $Daemon) {
        Write-Log "METRICS-SERVER started at http://localhost:${Port}/"
    }

    while ($running) {
        $task = $http.GetContextAsync()
        while (-not $task.IsCompleted -and $running) { Start-Sleep -Milliseconds 100 }
        if (-not $running) { break }

        $ctx = $task.Result
        $req = $ctx.Request
        $res = $ctx.Response
        $path = $req.RawUrl

        try {
            # SSE endpoint - keep connection open and stream feed.json every 5s
            if ($path -eq '/events') {
                $res.ContentType = 'text/event-stream'
                $res.Headers.Add('Cache-Control', 'no-cache')
                $res.Headers.Add('Connection', 'keep-alive')
                $res.Headers.Add('Access-Control-Allow-Origin', '*')
                $data = "data: connected`n`n"
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($data)
                $res.OutputStream.Write($bytes, 0, $bytes.Length)
                $res.OutputStream.Flush()

                while ($res.OutputStream.CanWrite) {
                    $consPath = Join-Path $metricsDir 'feed.json'
                    if (Test-Path $consPath) {
                        $json = Get-Content $consPath -Raw
                        $sseData = "data: $json`n`n"
                        $sBytes = [System.Text.Encoding]::UTF8.GetBytes($sseData)
                        try {
                            $res.OutputStream.Write($sBytes, 0, $sBytes.Length)
                            $res.OutputStream.Flush()
                        } catch { break }
                    }
                    Start-Sleep -Seconds 5
                }
                continue
            }

            # Serve dashboard HTML
            if ($path -eq '/' -or $path -eq '/index.html') {
                if (Test-Path $dashFile) {
                    $html = Get-Content $dashFile -Raw -Encoding UTF8
                    $html = $html -replace '</body>', "$serverScript</body>"
                    Send-Bytes $res ([System.Text.Encoding]::UTF8.GetBytes($html)) 'text/html; charset=utf-8'
                } else {
                    Send-Text $res 'Dashboard not found. Run dashboard-render.ps1 first.' -StatusCode 404
                }

            # Live feed data
            } elseif ($path -eq '/api/live') {
                $feedPath = Join-Path $metricsDir 'feed.json'
                $consPath = Join-Path $metricsDir 'consolidated.json'
                $src = if (Test-Path $feedPath) { $feedPath } elseif (Test-Path $consPath) { $consPath } else { $null }
                if ($src) {
                    $json = Get-Content $src -Raw
                    Send-Json $res $json
                } else {
                    Send-Json $res '{}'
                }

            # Serve arbitrary metrics files from .runtime/metrics/
            } elseif ($path -match '^/metrics/(.+)') {
                $file = $Matches[1]
                $fpath = Join-Path $metricsDir $file
                if (Test-Path $fpath) {
                    $json = Get-Content $fpath -Raw
                    Send-Json $res $json
                } else {
                    $res.StatusCode = 404
                }

            # Combined chart data
            } elseif ($path -eq '/api/metrics/charts') {
                $resp = @{}
                @('sessions', 'token', 'live', 'git', 'pr', 'cost') | ForEach-Object {
                    $fp = Join-Path $metricsDir "$_.json"
                    if (Test-Path $fp) {
                        try { $resp[$_] = Get-Content $fp -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
                    }
                }
                $dashHealth = Join-Path $metricsDir 'live/daemon-health.json'
                if (Test-Path $dashHealth) {
                    try { $resp['daemon'] = Get-Content $dashHealth -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
                }
                $json = $resp | ConvertTo-Json -Depth 5 -Compress
                Send-Json $res $json

            # PDF export
            } elseif ($path -eq '/api/export/pdf') {
                $pdfScript = Join-Path $repoRoot 'scripts' 'utilities' 'export-dashboard-pdf.ps1'
                $pdfPath = Join-Path $reportsDir 'dashboard-export.pdf'
                if (Test-Path $pdfScript) {
                    $output = & $pdfScript -InputHtml $dashFile -OutputPdf $pdfPath -Quiet 2>&1
                    $exitCode = $LASTEXITCODE
                    if ($exitCode -eq 0 -and (Test-Path $pdfPath)) {
                        $pdfBytes = [System.IO.File]::ReadAllBytes($pdfPath)
                        $res.Headers.Add('Content-Disposition', "attachment; filename=dashboard-export.pdf")
                        Send-Bytes $res $pdfBytes 'application/pdf'
                    } else {
                        $errMsg = "PDF generation failed (exit code: $exitCode)"
                        if ($output) { $errMsg += "`n$($output -join '; ')" }
                        Send-Text $res $errMsg -StatusCode 500
                    }
                } else {
                    Send-Text $res "PDF export script not found: $pdfScript" -StatusCode 404
                }

            # PNG export
            } elseif ($path -eq '/api/export/png') {
                $pdfScript = Join-Path $repoRoot 'scripts' 'utilities' 'export-dashboard-pdf.ps1'
                $pngPath = Join-Path $reportsDir 'dashboard-export.png'
                if (Test-Path $pdfScript) {
                    $output = & $pdfScript -InputHtml $dashFile -OutputPdf $pngPath -Quiet 2>&1
                    $exitCode = $LASTEXITCODE
                    if ($exitCode -eq 0 -and (Test-Path $pngPath)) {
                        $imgBytes = [System.IO.File]::ReadAllBytes($pngPath)
                        $res.Headers.Add('Content-Disposition', "attachment; filename=dashboard-export.png")
                        Send-Bytes $res $imgBytes 'image/png'
                    } else {
                        $errMsg = "PNG generation failed (exit code: $exitCode)"
                        if ($output) { $errMsg += "`n$($output -join '; ')" }
                        Send-Text $res $errMsg -StatusCode 500
                    }
                } else {
                    Send-Text $res "Export script not found" -StatusCode 404
                }

            # Health check
            } elseif ($path -eq '/health') {
                $dashHealth = Join-Path $metricsDir 'live/daemon-health.json'
                $livePid = if (Test-Path $dashHealth) { (Get-Content $dashHealth -Raw | ConvertFrom-Json).liveFeedAlive } else { $false }
                $json = "{`"status`":`"ok`",`"server`":`"running`",`"liveFeedAlive`":$($livePid -eq $true),`"port`":$Port}"
                Send-Json $res $json

            } else {
                $res.StatusCode = 404
            }
        } catch {
            Write-Log "ERROR processing $path : $_"
        } finally {
            try { $res.Close() } catch {}
        }
    }
} catch {
    Write-Log "FATAL: $_"
} finally {
    if ($http.IsListening) { $http.Stop() }
    $http.Close()
    if (-not $Daemon) {
        Write-Log 'METRICS-SERVER stopped'
    }
}
