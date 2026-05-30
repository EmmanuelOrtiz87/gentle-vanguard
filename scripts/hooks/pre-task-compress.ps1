# pre-task-compress.ps1
# Comprime prompt antes de delegacion a subagente - reduce tokens ~30%

param(
    [Parameter(ValueFromPipeline=$true)]
    [string]$PromptText = "",
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'
$nl = "`n"

if (-not $PromptText) { $PromptText = @($input) -join $nl }

$origLines = $PromptText -split $nl
$origLen = $PromptText.Length
$origTokens = [Math]::Floor($origLen / 4)

$line1 = 'COMPRESS: original ' + $origLen + ' chars ~' + $origTokens + ' tokens, ' + $origLines.Count + ' lines'
Write-Output $line1
Write-Output '===compress-start==='

$result = $PromptText

# Pass 1: Strip code blocks >20 lines
$rx1 = [regex]'(?ms)````[\s\S]*?````'
$result = $rx1.Replace($result, {
    param($m)
    $lines2 = $m.Value -split $nl
    if ($lines2.Count -gt 25) {
        $f2 = $lines2[0..5] -join $nl
        $l2 = $lines2[-5..-1] -join $nl
        $cnt2 = $lines2.Count - 1
        $tag2 = '```` compressed=' + $cnt2 + ' lines=12'
        $tag2, $f2, '...', $l2, '```' -join $nl
    } else { $m.Value }
})

# Pass 2: Strip long base64
$rx2 = [regex]'[A-Za-z0-9+/]{100,}={0,2}'
$result = $rx2.Replace($result, '[base64-removed]')

# Pass 3: Collapse repeated empty lines
$rx3 = [regex]($nl + $nl + $nl + '+')
$result = $rx3.Replace($result, $nl + $nl)

# Pass 4: Truncate file reads >50 lines
$rx4 = [regex]'(?m)^(File|File path|Content of).*\n(?:.*\n){50,}'
$result = $rx4.Replace($result, {
    param($m)
    $lines4 = $m.Value -split $nl
    $h4 = $lines4[0..49] -join $nl
    $trunc4 = $lines4.Count - 50
    $tag4 = '===truncated=' + $trunc4 + ' lines==='
    $h4, $tag4 -join $nl
})

$compressedLines = $result -split $nl
$compressedLen = $result.Length
$compressedTokens = [Math]::Floor($compressedLen / 4)
if ($origTokens -gt 0) { $savings = [Math]::Round((1 - $compressedTokens / $origTokens) * 100) } else { $savings = 0 }

$line2 = 'COMPRESS: compressed ' + $compressedLen + ' chars ~' + $compressedTokens + ' tokens, ' + $compressedLines.Count + ' lines, ' + $savings + '% savings'
Write-Output $line2

if (-not $DryRun) { Write-Output $result }
Write-Output '===compress-end==='
exit 0
