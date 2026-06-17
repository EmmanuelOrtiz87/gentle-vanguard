param(
    [Parameter(Mandatory=$true)]
    [string]$UserInput,
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir '..\..') | Select-Object -ExpandProperty Path
$loggerModule = Join-Path $scriptDir '..\common\Logger.psm1'
if (Test-Path $loggerModule) { Import-Module $loggerModule -Force }
$learnedNormsPath = Join-Path $repoRoot "rules\adaptive\LEARNED-NORMS.md"
$correctionLog = Join-Path $repoRoot ".session" "corrections-log.jsonl"

$correctionPatterns = @(
    @{ Pattern = '(?i)(no\s+es\s+(correcto|as[ií]|verdad|lo\s+que\s+ped[ií])|eso\s+no\s+es|mal|incorrecto|wrong|not\s+what\s+I\s+asked|no\s+era\s+eso|te\s+equivocaste|error|no\s+fue\s+lo\s+que\s+ped[ií])'; Type = 'correction'; Severity = 'high' }
    @{ Pattern = '(?i)(en\s+realidad|realmente\s+es|mejor\s+ser[ií]a|deber[ií]a\s+ser|tendr[ií]a\s+que\s+ser|m[aá]s\s+bien|corrige|cambia\s+esto|no\s+me\s+refiero|quiero\s+decir)'; Type = 'refinement'; Severity = 'medium' }
    @{ Pattern = '(?i)(otra\s+vez|ya\s+te\s+dije|te\s+he\s+dicho|como\s+ya\s+dijimos|como\s+comentamos|como\s+hablamos|repetir|nuevamente|de\s+nuevo)'; Type = 'repetition'; Severity = 'low' }
)

function Write-Capture {
    param([string]$Message)
    if ($VerboseOutput) { Write-Host "[CAPTURE] $Message" -ForegroundColor Cyan }
    try { Write-Log -Level DEBUG -Message $Message -Component 'correction-capture' } catch {}
}

function Detect-Correction {
    param([string]$InputText)

    foreach ($cp in $correctionPatterns) {
        $match = [regex]::Match($InputText, $cp.Pattern)
        if ($match.Success) {
            return @{
                IsCorrection = $true
                Type = $cp.Type
                Severity = $cp.Severity
                MatchText = $match.Value
                FullInput = $Input
                Timestamp = Get-Date -Format 'o'
            }
        }
    }

    return @{ IsCorrection = $false }
}

function Log-Correction {
    param($Correction)

    $logEntry = @{
        timestamp = $Correction.Timestamp
        type = $Correction.Type
        severity = $Correction.Severity
        match = $Correction.MatchText
        input = $Correction.FullInput
    }

    try {
        Add-Content -Path $correctionLog -Value (ConvertTo-Json $logEntry -Compress) -ErrorAction SilentlyContinue
        Write-Log -Level INFO -Message "Corrección clasificada como $($Correction.Type)" -Component 'correction-capture' -Data @{type=$Correction.Type;severity=$Correction.Severity;match=$Correction.MatchText}
    } catch { Write-Capture "Could not write to correction log"; Write-Log -Level ERROR -Message "Error en correction-capture" -Component 'correction-capture' -Data @{error=$_.Exception.Message} }

    # Score this correction
    $scoringScript = Join-Path $scriptDir "session-scoring.ps1"
    if (Test-Path $scoringScript) {
        & $scoringScript -Action record -EventType correction -Detail $Correction.Type -Success:$true -DurationSeconds 0
    }

    # For high-severity corrections, trigger immediate norm creation
    if ($Correction.Severity -eq 'high') {
        $learnerScript = Join-Path $repoRoot "scripts\adaptive\auto-norm-learner.ps1"
        if (Test-Path $learnerScript) {
            Write-Host "[CAPTURE] High-severity correction — triggering norm learner" -ForegroundColor Magenta
            Write-Log -Level INFO -Message "Corrección de alta severidad — ejecutando norm learner" -Component 'correction-capture' -Data @{severity='high'}
            & $learnerScript -Trigger manual -VerboseOutput:$VerboseOutput 2>&1 | Out-Null
        }
    }
}

$result = Detect-Correction -InputText $UserInput

if ($result.IsCorrection) {
    Log-Correction -Correction $result
    Write-Output "CORRECTION_CAPTURED:$($result.Type)"
} else {
    Write-Output "NO_CORRECTION"
}
