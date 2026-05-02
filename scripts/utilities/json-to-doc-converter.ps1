# json-to-doc-converter.ps1
# Converts JSON output from agents/subagents to the correct document format.
# Supports: Markdown, CSV, HTML, Text, JSON-pretty, and more.

param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$InputJson,

    [Parameter(Mandatory=$false)]
    [string]$OutputPath,

    [Parameter(Mandatory=$false)]
    [ValidateSet("markdown", "csv", "html", "text", "json", "pdf", "xml", "yaml")]
    [string]$OutputFormat = "markdown",

    [Parameter(Mandatory=$false)]
    [string]$TemplatePath,

    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

#region Functions
function ConvertTo-Markdown {
    param($Data, $Title = "Report")

    $md = "# $Title`n`n"
    $md += "**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"

    foreach ($key in $Data.Keys) {
        $value = $Data[$key]
        if ($value -is [hashtable] -or $value -is [PSCustomObject]) {
            $md += "## $key`n`n"
            foreach ($subKey in $value.PSObject.Properties.Name) {
                $md += "- **$subKey**: $($value.$subKey)`n"
            }
            $md += "`n"
        } elseif ($value -is [array]) {
            $md += "## $key`n`n"
            $md += "| Item | Value |`n"
            $md += "|------|--------|`n"
            $i = 1
            foreach ($item in $value) {
                $md += "| $i | $item |`n"
                $i++
            }
            $md += "`n"
        } else {
            $md += "- **$key**: $value`n"
        }
    }

    return $md
}

function ConvertTo-CsvData {
    param($Data, $Title = "Report")

    $csvRows = @()
    $row = [PSCustomObject]@{
        Title = $Title
        Date = Get-Date -Format 'yyyy-MM-dd'
        Time = Get-Date -Format 'HH:mm:ss'
    }

    foreach ($key in $Data.Keys) {
        if ($key -notin @('Title', 'Date', 'Time')) {
            $row | Add-Member -NotePropertyName $key -NotePropertyValue $Data[$key] -Force
        }
    }

    $csvRows += $row
    return $csvRows
}

function ConvertTo-Html {
    param($Data, $Title = "Report")

    $html = "<!DOCTYPE html>`n"
    $html += "<html><head><title>$Title</title>`n"
    $html += "<style>body{font-family:Arial,sans-serif;margin:20px;} "
    $html += "table{border-collapse:collapse;width:100%;} "
    $html += "th,td{border:1px solid #ddd;padding:8px;text-align:left;} "
    $html += "th{background-color:#4CAF50;color:white;}</style>`n"
    $html += "</head><body>`n"
    $html += "<h1>$Title</h1>`n"
    $html += "<p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>`n"

    $html += "<table>`n"
    foreach ($key in $Data.Keys) {
        $value = $Data[$key]
        if ($value -isnot [hashtable] -and $value -isnot [array]) {
            $html += "<tr><th>$key</th><td>$value</td></tr>`n"
        }
    }
    $html += "</table>`n"
    $html += "</body></html>"

    return $html
}

function ConvertTo-Text {
    param($Data, $Title = "Report")

    $text = "=" * 60 + "`n"
    $text += "  $Title`n"
    $text += "=" * 60 + "`n`n"
    $text += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"

    foreach ($key in $Data.Keys) {
        $value = $Data[$key]
        if ($value -is [hashtable] -or $value -is [PSCustomObject]) {
            $text += "`n--- $key ---`n"
            foreach ($subKey in $value.PSObject.Properties.Name) {
                $text += "  {0,-30}: {1}`n" -f $subKey, $value.$subKey
            }
        } elseif ($value -is [array]) {
            $text += "`n--- $key ({0} items) ---`n" -f $value.Count
            for ($i = 0; $i -lt $value.Count; $i++) {
                $text += "  [{0}] {1}`n" -f ($i+1), $value[$i]
            }
        } else {
            $text += "{0,-30}: {1}`n" -f $key, $value
        }
    }

    return $text
}

function ConvertTo-XmlData {
    param($Data, $RootName = "Report")

    $xml = "<?xml version='1.0' encoding='UTF-8'?>`n"
    $xml += "<$RootName>`n"
    $xml += "  <Generated>$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')</Generated>`n"

    foreach ($key in $Data.Keys) {
        $safeKey = $key -replace '[^a-zA-Z0-9]', ''
        $value = $Data[$key]
        if ($value -isnot [hashtable] -and $value -isnot [array]) {
            $xml += "  <$safeKey>$([Security.SecurityElement]::Escape($value))</$safeKey>`n"
        }
    }

    $xml += "</$RootName>"
    return $xml
}

function ConvertTo-YamlData {
    param($Data, $Title = "Report")

    $yaml = "---
# $Title
generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
`n"

    foreach ($key in $Data.Keys) {
        $value = $Data[$key]
        if ($value -is [array]) {
            $yaml += "$key:`n"
            foreach ($item in $value) {
                $yaml += "  - $item`n"
            }
        } else {
            $yaml += "$key: $value`n"
        }
    }

    $yaml += "---"
    return $yaml
}

function Get-OutputPath {
    param($Format, $Data)

    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $type = if ($Data.type) { $Data.type } else { "report" }

    switch ($Format) {
        "markdown" {
            $baseDir = Join-Path $workspaceRoot "docs"
            if ($type -eq "session") { $baseDir = Join-Path $baseDir "sessions" }
            elseif ($type -eq "audit") { $baseDir = Join-Path $baseDir "audits" }
            elseif ($type -eq "judgment") { $baseDir = Join-Path $baseDir "judgment" }
            elseif ($type -eq "management-report") { $baseDir = Join-Path $workspaceRoot "reports" }

            if (-not (Test-Path $baseDir)) { New-Item -Path $baseDir -ItemType Directory | Out-Null }
            return Join-Path $baseDir "$type-$timestamp.md"
        }
        "csv" {
            $baseDir = Join-Path $workspaceRoot "reports"
            if (-not (Test-Path $baseDir)) { New-Item -Path $baseDir -ItemType Directory | Out-Null }
            $month = Get-Date -Format "yyyy-MM"
            return Join-Path $baseDir "MANAGEMENT-REPORT-$month.csv"
        }
        "html" {
            $baseDir = Join-Path $workspaceRoot "reports\html"
            if (-not (Test-Path $baseDir)) { New-Item -Path $baseDir -ItemType Directory | Out-Null }
            return Join-Path $baseDir "report-$timestamp.html"
        }
        "text" {
            $baseDir = Join-Path $workspaceRoot "logs"
            if (-not (Test-Path $baseDir)) { New-Item -Path $baseDir -ItemType Directory | Out-Null }
            return Join-Path $baseDir "output-$timestamp.txt"
        }
        "json" {
            $baseDir = Join-Path $workspaceRoot "logs"
            if (-not (Test-Path $baseDir)) { New-Item -Path $baseDir -ItemType Directory | Out-Null }
            return Join-Path $baseDir "session-$timestamp.json"
        }
        "xml" { return Join-Path $workspaceRoot "reports\report-$timestamp.xml" }
        "yaml" { return Join-Path $workspaceRoot "reports\report-$timestamp.yaml" }
        default { return Join-Path $workspaceRoot "output-$timestamp.$Format" }
    }
}

function Get-Title {
    param($Data)

    if ($Data.title) { return $Data.title }
    if ($Data.Name) { return $Data.Name }
    if ($Data.type) { return "$($Data.type) Report" }
    return "Agent Output Report"
}
#endregion

#region Main
try {
    # Read input JSON
    if ($InputJson -match '^\s*\{') {
        $jsonData = $InputJson | ConvertFrom-Json
    } elseif (Test-Path $InputJson) {
        $jsonData = Get-Content $InputJson -Raw | ConvertFrom-Json
    } else {
        throw "Input must be valid JSON string or existing file path"
    }

    # Determine output path
    if (-not $OutputPath) {
        $OutputPath = Get-OutputPath $OutputFormat $jsonData
    }

    # Get title
    $title = Get-Title $jsonData

    # Convert based on format
    Write-Host "Converting JSON to $OutputFormat..."
    switch ($OutputFormat) {
        "markdown" {
            $output = ConvertTo-Markdown $jsonData $title
            $output | Out-File $OutputPath -Encoding UTF8
        }
        "csv" {
            $csvData = ConvertTo-CsvData $jsonData $title
            $csvData | Export-Csv $OutputPath -NoTypeInformation -Encoding UTF8
        }
        "html" {
            $output = ConvertTo-Html $jsonData $title
            $output | Out-File $OutputPath -Encoding UTF8
        }
        "text" {
            $output = ConvertTo-Text $jsonData $title
            $output | Out-File $OutputPath -Encoding UTF8
        }
        "json" {
            $jsonData | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding UTF8
        }
        "xml" {
            $output = ConvertTo-XmlData $jsonData
            $output | Out-File $OutputPath -Encoding UTF8
        }
        "yaml" {
            $output = ConvertTo-YamlData $jsonData $title
            $output | Out-File $OutputPath -Encoding UTF8
        }
    }

    Write-Host "✅ Conversion complete: $OutputPath"
    return $OutputPath

} catch {
    Write-Host "❌ Conversion failed: $_" -ForegroundColor Red
    exit 1
}
#endregion
