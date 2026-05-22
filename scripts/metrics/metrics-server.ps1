<#
.SYNOPSIS
    Metrics HTTP server — serves dashboard, live API, metric files, SSE events, chart data, and PDF/PNG export.

.DESCRIPTION
    Starts a local HTTP listener (default port 8090) that serves:
    - / or /index.html    → dashboard HTML with live overlay
    - /api/live           → latest feed.json / consolidated.json
    - /api/metrics/charts → consolidated chart data for JS polling
    - /api/export/pdf     → server-side PDF via export-dashboard-pdf.ps1
    - /api/export/png     → server-side PNG (headless browser screenshot)
    - /health             → daemon health check
    - /metrics/<file>     → individual metric JSON files
    - /events             → SSE stream for real-time push

.PARAMETER Port
    HTTP port. Default: 8090

.PARAMETER Daemon
    Run silently (no startup banner).

.EXAMPLE
    .\metrics-server.ps1 -Daemon
    .\metrics-server.ps1 -Port 9090
#>

param(
    [int]$Port = 8090,
    [switch]$Daemon
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add("http://localhost:${Port}/")
$running = $true

$metricsDir = Join-Path $repoRoot '.runtime/metrics'
$reportsDir = Join-Path $repoRoot 'reports'
$dashFile = Join-Path $reportsDir 'dashboard.html'

$presentationFile = Join-Path $repoRoot 'gentle-vanguard-presentation.html'

$mime = @{
    '.html' = 'text/html; charset=utf-8'
    '.json' = 'application/json'
    '.css'  = 'text/css'
    '.js'   = 'application/javascript'
    '.png'  = 'image/png'
    '.svg'  = 'image/svg+xml'
}
$sseClients = [System.Collections.ArrayList]::new()

try {
    $http.Start()
    if (-not $Daemon) {
        Write-Host "[METRICS-SERVER] http://localhost:${Port}/" -ForegroundColor Cyan
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
            if ($path -eq '/events') {
                $sseClients.Add($res) | Out-Null
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

            if ($path -eq '/' -or $path -eq '/index.html') {
                if (Test-Path $dashFile) {
                    $html = Get-Content $dashFile -Raw -Encoding UTF8
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
 bar.innerHTML = '<button onclick="gvExportPdf()">&#128461; PDF</button><button onclick="gvExportPng()">&#128247; PNG</button>';
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
  if(typeof html2canvas==='undefined'){alert('PNG export requires html2canvas library or server-side endpoint.\nUse PDF instead.');return}
  html2canvas(sec,{backgroundColor:'#081016',scale:1.5,useCORS:true,logging:false}).then(function(c){var a=document.createElement('a');a.download='dashboard-export.png';a.href=c.toDataURL('image/png');a.click()}).catch(function(e){alert('PNG export failed: '+e.message)});
 });
};

setInterval(fetchLive,15000);
fetchLive();
addExportBar();
})();
</script>
"@
                    $html = $html -replace '</body>', "$serverScript</body>"
                    $buf = [System.Text.Encoding]::UTF8.GetBytes($html)
                    $res.ContentType = 'text/html; charset=utf-8'
                    $res.Headers.Add('Access-Control-Allow-Origin', '*')
                    $res.OutputStream.Write($buf, 0, $buf.Length)
                } else {
                    $res.StatusCode = 404
                    $buf = [System.Text.Encoding]::UTF8.GetBytes('Dashboard not found. Run dashboard-render.ps1 first.')
                    $res.OutputStream.Write($buf, 0, $buf.Length)
                }
            } elseif ($path -eq '/presentacion') {
                if (Test-Path $presentationFile) {
                    $html = Get-Content $presentationFile -Raw -Encoding UTF8
                    $buf = [System.Text.Encoding]::UTF8.GetBytes($html)
                    $res.ContentType = 'text/html; charset=utf-8'
                    $res.Headers.Add('Access-Control-Allow-Origin', '*')
                    $res.OutputStream.Write($buf, 0, $buf.Length)
                } else {
                    $res.StatusCode = 404
                    $buf = [System.Text.Encoding]::UTF8.GetBytes('Presentation not found at gentile-vanguard-presentation.html')
                    $res.OutputStream.Write($buf, 0, $buf.Length)
                }
            } elseif ($path -eq '/api/ingest' -and $req.HttpMethod -eq 'POST') {
                $reader = New-Object System.IO.StreamReader($req.InputStream)
                $body = $reader.ReadToEnd(); $reader.Close()
                $actFile = Join-Path $metricsDir 'live/activity.json'
                $evtFile = Join-Path $metricsDir 'live/events.ndjson'
                try {
                    $evt = $body | ConvertFrom-Json
                    $evt | Add-Member -NotePropertyName 'ts' -NotePropertyValue (Get-Date -Format 'o') -Force
                    $evt | ConvertTo-Json -Compress -Depth 2 | Add-Content -Path $evtFile -Encoding UTF8
                    $activity = if (Test-Path $actFile) { Get-Content $actFile -Raw | ConvertFrom-Json } else { [PSCustomObject]@{ toolCalls=0; estimatedTokens=0; filesRead=0; filesWritten=0; filesEdited=0; commandsRun=0 } }
                    if ($evt.tokens) { $activity.estimatedTokens += [int]$evt.tokens }
                    if ($evt.toolCalls) { $activity.toolCalls += [int]$evt.toolCalls }
                    if ($evt.filesRead) { $activity.filesRead += [int]$evt.filesRead }
                    if ($evt.filesWritten) { $activity.filesWritten += [int]$evt.filesWritten }
                    if ($evt.filesEdited) { $activity.filesEdited += [int]$evt.filesEdited }
                    if ($evt.type -eq 'bash') { $activity.commandsRun += 1 }
                    $activity.lastUpdate = (Get-Date -Format 'o')
                    $activity | ConvertTo-Json -Depth 3 | Set-Content $actFile
                    $res.StatusCode = 200
                    $buf = [System.Text.Encoding]::UTF8.GetBytes('{"status":"ok"}')
                } catch {
                    $res.StatusCode = 400
                    $buf = [System.Text.Encoding]::UTF8.GetBytes('{"status":"error","detail":"' + $_.Exception.Message + '"}')
                }
                $res.ContentType = 'application/json'
                $res.Headers.Add('Access-Control-Allow-Origin', '*')
                $res.OutputStream.Write($buf, 0, $buf.Length)
            } elseif ($path -eq '/api/live') {
                $feedPath = Join-Path $metricsDir 'feed.json'
                $consPath = Join-Path $metricsDir 'consolidated.json'
                $evtPath = Join-Path $metricsDir 'live/events.ndjson'
                $src = if (Test-Path $feedPath) { $feedPath } elseif (Test-Path $consPath) { $consPath } else { $null }
                if ($src) {
                    $json = Get-Content $src -Raw
                    $data = $json | ConvertFrom-Json
                    if (Test-Path $evtPath) {
                        $events = @(Get-Content $evtPath | ForEach-Object { if ($_) { $_ | ConvertFrom-Json } })
                        if ($data.telemetry) {
                            $data.telemetry | Add-Member -NotePropertyName 'events' -NotePropertyValue @($events) -Force
                        } else {
                            $tel = [PSCustomObject]@{ hasData = ($events.Count -gt 0); events = @($events); toolCalls = 0; estimatedTokens = 0 }
                            $data | Add-Member -NotePropertyName 'telemetry' -NotePropertyValue $tel -Force
                        }
                    }
                    $json = $data | ConvertTo-Json -Depth 5 -Compress
                    $buf = [System.Text.Encoding]::UTF8.GetBytes($json)
                    $res.ContentType = 'application/json'
                    $res.Headers.Add('Access-Control-Allow-Origin', '*')
                    $res.OutputStream.Write($buf, 0, $buf.Length)
                } else {
                    $res.StatusCode = 404
                    $buf = [System.Text.Encoding]::UTF8.GetBytes('{}')
                    $res.OutputStream.Write($buf, 0, $buf.Length)
                }
            } elseif ($path -match '^/metrics/(.+)') {
                $file = $Matches[1]
                $fpath = Join-Path $metricsDir $file
                if (Test-Path $fpath) {
                    $json = Get-Content $fpath -Raw
                    $buf = [System.Text.Encoding]::UTF8.GetBytes($json)
                    $res.ContentType = 'application/json'
                    $res.Headers.Add('Access-Control-Allow-Origin', '*')
                    $res.OutputStream.Write($buf, 0, $buf.Length)
                } else {
                    $res.StatusCode = 404
                }
            } elseif ($path -eq '/api/metrics/charts') {
                $resp = @{}
                @('sessions','token','live','git','pr','cost','telemetry') | ForEach-Object {
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
                $buf = [System.Text.Encoding]::UTF8.GetBytes($json)
                $res.ContentType = 'application/json'
                $res.Headers.Add('Access-Control-Allow-Origin', '*')
                $res.OutputStream.Write($buf, 0, $buf.Length)
            } elseif ($path -eq '/api/export/pdf') {
                $pdfScript = Join-Path $repoRoot 'scripts' 'utilities' 'export-dashboard-pdf.ps1'
                $pdfPath = Join-Path $reportsDir 'dashboard-export.pdf'
                if (Test-Path $pdfScript) {
                    # Create temp HTML with all sections visible for PDF generation
                    $tmpHtml = [System.IO.Path]::GetTempFileName() + '.html'
                    $html = Get-Content $dashFile -Raw -Encoding UTF8
                    $printInject = '<style>@media print{.sec{display:block!important;break-inside:avoid}.export-bar,.nav{display:none!important}}</style><script>window.onload=function(){document.querySelectorAll(".sec").forEach(function(s){s.style.display="block"});document.querySelectorAll(".nav,.export-bar,#gv-export-bar").forEach(function(e){e.style.display="none"});setTimeout(function(){window.print()},600)}</script>'
                    $html = $html -replace '</head>', "${printInject}</head>"
                    $html | Set-Content $tmpHtml -Encoding UTF8
                    $output = & $pdfScript -InputHtml $tmpHtml -OutputPdf $pdfPath -Quiet 2>&1
                    $exitCode = $LASTEXITCODE
                    Remove-Item $tmpHtml -Force -ErrorAction SilentlyContinue
                    if ($exitCode -eq 0 -and (Test-Path $pdfPath)) {
                        $pdfBytes = [System.IO.File]::ReadAllBytes($pdfPath)
                        $res.ContentType = 'application/pdf'
                        $res.Headers.Add('Content-Disposition', "attachment; filename=dashboard-export.pdf")
                        $res.Headers.Add('Access-Control-Allow-Origin', '*')
                        $res.OutputStream.Write($pdfBytes, 0, $pdfBytes.Length)
                    } else {
                        $res.StatusCode = 500
                        $errMsg = "PDF generation failed (exit code: $exitCode)"
                        if ($output) { $errMsg += "`n$($output -join '; ')" }
                        $buf = [System.Text.Encoding]::UTF8.GetBytes($errMsg)
                        $res.OutputStream.Write($buf, 0, $buf.Length)
                    }
                } else {
                    $res.StatusCode = 404
                    $buf = [System.Text.Encoding]::UTF8.GetBytes("PDF export script not found: $pdfScript")
                    $res.OutputStream.Write($buf, 0, $buf.Length)
                }
            } elseif ($path -eq '/api/export/png') {
                $browserPaths = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe","${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe","${env:ProgramFiles}\Google\Chrome\Application\chrome.exe","${env:LOCALAPPDATA}\Google\Chrome\Application\chrome.exe")
                $browserExe = $null; foreach ($bp in $browserPaths) { if (Test-Path $bp) { $browserExe = $bp; break } }
                if (-not $browserExe) {
                    $res.StatusCode = 500; $buf = [System.Text.Encoding]::UTF8.GetBytes('No headless browser found for PNG export')
                } else {
                    $tmpHtml = [System.IO.Path]::GetTempFileName() + '.html'
                    $html = Get-Content $dashFile -Raw -Encoding UTF8
                    # Inject JS to show all sections before rendering
                    $printInject = '<script>window.onload=function(){document.querySelectorAll(".sec").forEach(function(s){s.style.display="block"});setTimeout(function(){window.dispatchEvent(new Event("screenshot-ready"))},500)}</script>'
                    $html = $html -replace '</head>', "${printInject}</head>"
                    $html | Set-Content $tmpHtml -Encoding UTF8
                    $pngPath = Join-Path $reportsDir 'dashboard-export.png'
                    $argsList = @('--headless','--disable-gpu','--no-sandbox','--disable-software-rasterizer','--hide-scrollbars',"--screenshot=$pngPath","--window-size=1280,1800","file:///$($tmpHtml.Replace('\','/').Replace(':',''))")
                    $proc = Start-Process -FilePath $browserExe -ArgumentList $argsList -NoNewWindow -Wait -PassThru
                    if ($proc.ExitCode -eq 0 -and (Test-Path $pngPath) -and ((Get-Item $pngPath).Length -gt 0)) {
                        $imgBytes = [System.IO.File]::ReadAllBytes($pngPath)
                        $res.ContentType = 'image/png'
                        $res.Headers.Add('Content-Disposition', "attachment; filename=dashboard-export.png")
                        $res.Headers.Add('Access-Control-Allow-Origin', '*')
                        $res.OutputStream.Write($imgBytes, 0, $imgBytes.Length)
                    } else {
                        $res.StatusCode = 500
                        $buf = [System.Text.Encoding]::UTF8.GetBytes("PNG generation failed (exit code: $($proc.ExitCode))")
                        $res.OutputStream.Write($buf, 0, $buf.Length)
                    }
                    Remove-Item $tmpHtml -Force -ErrorAction SilentlyContinue
                }
            } elseif ($path -eq '/health') {
                $dashHealth = Join-Path $metricsDir 'live/daemon-health.json'
                $livePid = if (Test-Path $dashHealth) { (Get-Content $dashHealth -Raw | ConvertFrom-Json).liveFeedAlive } else { $false }
                $json = "{`"status`":`"ok`",`"server`":`"running`",`"liveFeedAlive`":$($livePid -eq $true),`"port`":$Port}"
                $buf = [System.Text.Encoding]::UTF8.GetBytes($json)
                $res.ContentType = 'application/json'
                $res.Headers.Add('Access-Control-Allow-Origin', '*')
                $res.OutputStream.Write($buf, 0, $buf.Length)
            } else {
                $res.StatusCode = 404
            }
        } catch {} finally {
            try { $res.Close() } catch {}
        }
    }
} finally {
    $http.Stop()
    $http.Close()
}
