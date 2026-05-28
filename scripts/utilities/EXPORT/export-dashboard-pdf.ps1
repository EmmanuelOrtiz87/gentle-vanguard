param(
    [string]$InputHtml = '',
    [string]$OutputPdf = '',
    [string[]]$Sections = @(),
    [switch]$Open,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$reportsDir = Join-Path $repoRoot 'reports'

if (-not $InputHtml) {
    $InputHtml = Join-Path $reportsDir 'dashboard.html'
}
if (-not (Test-Path $InputHtml)) {
    Write-Host "[PDF] ERROR: HTML not found: $InputHtml" -ForegroundColor Red
    exit 1
}

if (-not $OutputPdf) {
    $dateStr = Get-Date -Format 'yyyy-MM-dd'
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputHtml)
    $OutputPdf = Join-Path $reportsDir "${baseName}-${dateStr}.pdf"
}

$browserPaths = @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
    "${env:LOCALAPPDATA}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles}\Mozilla Firefox\firefox.exe"
)

$browserExe = $null
foreach ($bp in $browserPaths) {
    if (Test-Path $bp) { $browserExe = $bp; break }
}

if (-not $browserExe) {
    Write-Host "[PDF] WARNING: No headless browser found. Falling back to print dialog." -ForegroundColor Yellow
    Write-Host "[PDF] Install Edge or Chrome for server-side PDF generation." -ForegroundColor Gray

    $htmlContent = Get-Content $InputHtml -Raw -Encoding UTF8
    $printScript = @"
<script>
window.onload = function() { window.print(); };
</script>
"@
    $printHtml = $htmlContent -replace '</head>', "${printScript}</head>"
    $printPath = $InputHtml -replace '\.html$', '-print.html'
    $printHtml | Set-Content $printPath -Encoding UTF8
    Start-Process $printPath

    Write-Host "[PDF] Print dialog opened for: $printPath" -ForegroundColor Cyan
    Write-Host "[PDF] Save as PDF using the browser's print dialog (Ctrl+P > Save as PDF)" -ForegroundColor Gray
    exit 0
}

$isEdge = $browserExe -match 'msedge'
$isChrome = $browserExe -match 'chrome'

$absInput = (Resolve-Path $InputHtml).Path
$absOutput = (New-Object -ComObject Scripting.FileSystemObject).GetAbsolutePathName($OutputPdf)

$argsList = @(
    '--headless',
    '--disable-gpu',
    '--no-sandbox',
    '--disable-extensions',
    '--disable-software-rasterizer',
    "--print-to-pdf=$absOutput",
    "--print-to-pdf-no-header"
)

if ($Sections.Count -gt 0) {
    $hashStr = $Sections -join ','
    $argsList += "--print-to-pdf-page-ranges=1-1"
}

$argsList += "file:///$($absInput.Replace('\','/').Replace(':',''))"

try {
    if (-not $Quiet) {
        Write-Host "[PDF] Generating: $absOutput" -ForegroundColor Cyan
        Write-Host "[PDF] Browser: $browserExe" -ForegroundColor Gray
    }
    $proc = Start-Process -FilePath $browserExe -ArgumentList $argsList -NoNewWindow -Wait -PassThru

    if ($proc.ExitCode -eq 0 -and (Test-Path $absOutput) -and ((Get-Item $absOutput).Length -gt 0)) {
        if (-not $Quiet) {
            Write-Host "[OK] PDF generated: $absOutput ($('{0:N1}' -f ((Get-Item $absOutput).Length / 1KB)) KB)" -ForegroundColor Green
        }
        if ($Open) { Start-Process $absOutput }
        exit 0
    } else {
        Write-Host "[PDF] ERROR: Browser exit code $($proc.ExitCode)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[PDF] ERROR: $_" -ForegroundColor Red
    exit 1
}
