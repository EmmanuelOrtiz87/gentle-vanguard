# extract-engram-json.ps1
# Extracts pure JSON from engram export output (which prints summary text first)

param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputFile
)

$lines = Get-Content $InputFile
$jsonStart = -1

# Find the line where JSON starts (first line that starts with '{')
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*\{') {
        $jsonStart = $i
        break
    }
}

if ($jsonStart -ge 0) {
    # Extract from JSON start to end
    $jsonLines = $lines[$jsonStart..($lines.Count - 1)]
    $jsonLines | Out-File $OutputFile -Encoding UTF8
    Write-Host " Extracted JSON to $OutputFile (started at line $($jsonStart+1))"
    exit 0
} else {
    Write-Host " No JSON found in $InputFile"
    exit 1
}

