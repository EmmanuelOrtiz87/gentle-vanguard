param(
    [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
    [string]$InputText = '',
    [Parameter(Mandatory=$false)]
    [string]$InputFile = '',
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = '',
    [switch]$Interactive,
    [switch]$Detailed,
    [switch]$SaveMetrics
)

$ErrorActionPreference = 'Continue'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir '..\..')

function Write-Status { param([string]$m) Write-Host "[SIMPLIFY] $m" -ForegroundColor Green }
function Write-Info { param([string]$m) Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Warn { param([string]$m) Write-Host "[WARN] $m" -ForegroundColor Yellow }

function Write-Metric {
    param([string]$Key, $Value)
    $metricsFile = Join-Path $repoRoot 'docs/sessions/metrics/text-simplification.csv'
    $dir = Split-Path $metricsFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
    if (-not (Test-Path $metricsFile)) {
        "timestamp,metric,original_chars,simplified_chars,reduction_pct,tokens_saved_estimate" | Set-Content -Path $metricsFile -Encoding UTF8
    }
    Add-Content -Path $metricsFile -Value "$timestamp,$Key,$Value" -Encoding UTF8
}

function Remove-NonText {
    param([string]$Text)
    $Text = $Text -replace '[^\w\s.,;:!?()''""-]', ' '
    return $Text
}

function Normalize-Whitespace {
    param([string]$Text)
    $Text = $Text -replace '\t', ' '
    $Text = $Text -replace '(?m)^\s+', ''
    $Text = $Text -replace '(?m)\s+$', ''
    $Text = $Text -replace '\r\n', "`n"
    $Text = $Text -replace '(\n){3,}', "`n`n"
    $Text = $Text -replace ' {2,}', ' '
    return $Text.Trim()
}

function Remove-MarkdownNoise {
    param([string]$Text)
    $Text = $Text -replace '\*{1,3}([^*]+)\*{1,3}', '$1'
    $Text = $Text -replace '_{1,3}([^_]+)_{1,3}', '$1'
    $Text = $Text -replace '#+\s*', ''
    $Text = $Text -replace '`{1,3}', ''
    $Text = $Text -replace '\[([^\]]+)\]\([^\)]+\)', '$1'
    return $Text
}

function Abbreviate-Common {
    param([string]$Text)
    $abbrevs = @{
        'por favor' = 'pls'
        'muchas gracias' = 'thx'
        'buenos dias' = 'morning'
        'buenas tardes' = 'afternoon'
        'buenas noches' = 'evening'
        'con respecto a' = 're'
        'en cuanto a' = 're'
        'sin embargo' = 'but'
        'ademas' = 'also'
        'es importante' = 'imp'
        'tener en cuenta' = 'note'
        'a continuacion' = 'next'
        'en conclusion' = 'end'
        'es decir' = 'ie'
        'para que' = 'so'
    }
    foreach ($key in $abbrevs.Keys) {
        $Text = $Text -replace [regex]::Escape($key), $abbrevs[$key]
    }
    return $Text
}

function Remove-RedundantPhrases {
    param([string]$Text)
    $redundant = @('claro esta', 'como se puede ver', 'en este sentido', 'a modo de ejemplo', 'en primer lugar', 'por ultimo', 'finalmente', 'resumiendo')
    foreach ($phrase in $redundant) {
        $Text = $Text -replace [regex]::Escape($phrase), ''
    }
    return $Text
}

function Deduplicate-Words {
    param([string]$Text)
    $lines = $Text -split "`n"
    $result = @()
    foreach ($line in $lines) {
        $words = $line -split '\s+'
        $prevWord = ''
        $deduped = @()
        foreach ($word in $words) {
            if ($word -ne $prevWord) { $deduped += $word; $prevWord = $word }
        }
        $result += $deduped -join ' '
    }
    return $result -join "`n"
}

function Simplify-Text {
    param([string]$Text)
    $originalChars = $Text.Length
    $originalTokens = [math]::Ceiling($originalChars / 4)
    if ($Detailed) { Write-Info "Original: $originalChars chars, ~${originalTokens} tokens" }

    $Text = Remove-NonText -Text $Text
    if ($Detailed) { Write-Info "After cleanup: $($Text.Length) chars" }

    $Text = Normalize-Whitespace -Text $Text
    if ($Detailed) { Write-Info "After whitespace: $($Text.Length) chars" }

    $Text = Remove-MarkdownNoise -Text $Text
    if ($Detailed) { Write-Info "After markdown: $($Text.Length) chars" }

    $Text = Abbreviate-Common -Text $Text
    if ($Detailed) { Write-Info "After abbreviations: $($Text.Length) chars" }

    $Text = Remove-RedundantPhrases -Text $Text
    if ($Detailed) { Write-Info "After redundant: $($Text.Length) chars" }

    $Text = Deduplicate-Words -Text $Text
    if ($Detailed) { Write-Info "After dedup: $($Text.Length) chars" }

    $Text = Normalize-Whitespace -Text $Text
    if ($Detailed) { Write-Info "After final: $($Text.Length) chars" }

    $simplifiedChars = $Text.Length
    $simplifiedTokens = [math]::Ceiling($simplifiedChars / 4)
    $reduction = [math]::Round((1 - ($simplifiedChars / $originalChars)) * 100, 1)
    $tokensSaved = $originalTokens - $simplifiedTokens

    if ($Detailed -or $SaveMetrics) {
        Write-Status "Reduction: $reduction% (~ $tokensSaved tokens saved)"
        Write-Metric -Key "simplify" -Value "$originalChars,$simplifiedChars,$reduction,$tokensSaved"
    }

    return @{
        Text = $Text
        OriginalChars = $originalChars
        SimplifiedChars = $simplifiedChars
        Reduction = $reduction
        TokensSaved = $tokensSaved
    }
}

$inputContent = ''
if ($InputFile) {
    if (Test-Path $InputFile) { $inputContent = Get-Content $InputFile -Raw; Write-Info "Reading from: $InputFile" }
    else { Write-Warn "File not found: $InputFile"; exit 1 }
}
elseif ($InputText) { $inputContent = $InputText }
elseif ($Interactive) {
    Write-Status "Interactive mode - paste text, empty line to finish:"
    $lines = @()
    while ($true) {
        $line = Read-Host
        if ([string]::IsNullOrWhiteSpace($line)) { break }
        $lines += $line
    }
    $inputContent = $lines -join "`n"
}

if ([string]::IsNullOrWhiteSpace($inputContent)) {
    Write-Warn "No input. Usage: simplify-text.ps1 -InputText 'text' or -InputFile 'path'"
    exit 1
}

$result = Simplify-Text -Text $inputContent

if ($OutputFile) {
    $result.Text | Set-Content -Path $OutputFile -Encoding UTF8
    Write-Status "Output saved to: $OutputFile"
} else {
    Write-Output $result.Text
}

$msg = "Done. Reduced from " + $result.OriginalChars + " to " + $result.SimplifiedChars + " chars (" + $result.Reduction + "% reduction)"
Write-Status $msg
exit 0