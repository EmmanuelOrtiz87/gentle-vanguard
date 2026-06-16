param(
    [ValidateSet("detect", "suggest", "report")]
    [string]$Action = "detect",
    [string]$UserInput = "",
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir '..\..') | Select-Object -ExpandProperty Path
$sessionDir = Join-Path $repoRoot ".session"
$correctionLog = Join-Path $sessionDir "corrections-log.jsonl"
$patternDb = Join-Path $sessionDir "pattern-frequency.json"

function Write-Detect {
    param([string]$Message)
    if ($VerboseOutput) { Write-Host "[DETECT] $Message" -ForegroundColor Cyan }
}

function Load-PatternDb {
    if (Test-Path $patternDb) {
        return Get-Content $patternDb -Raw | ConvertFrom-Json -AsHashtable
    }
    return @{ patterns = @{}; suggestions = @() }
}

function Save-PatternDb {
    param($Db)
    $Db | ConvertTo-Json -Depth 10 | Set-Content $patternDb
}

# Detect recurring patterns from user input
function Detect-Patterns {
    param([string]$UserText)

    $db = Load-PatternDb
    $inputLower = $UserText.ToLower()

    # Extract key phrases (n-grams of 2-4 words)
    $words = $inputLower -split '\s+' | Where-Object { $_.Length -gt 2 -and $_ -notmatch '^(para|que|con|por|las|los|una|uno|del|esta|este|como|m[aá]s|pero|sin|entre|sobre|durante|tiene|puede|debe|muy|tan|son|era|fue)$' }
    $phrases = @()
    for ($i = 0; $i -lt $words.Count - 1; $i++) {
        $phrases += $words[$i] + ' ' + $words[$i + 1]
    }
    for ($i = 0; $i -lt $words.Count - 2; $i++) {
        $phrases += $words[$i] + ' ' + $words[$i + 1] + ' ' + $words[$i + 2]
    }

    # Increment frequency for matching patterns
    foreach ($phrase in $phrases) {
        if ($phrase.Length -gt 5) {
            if (-not $db.patterns.ContainsKey($phrase)) {
                $db.patterns[$phrase] = 0
            }
            $db.patterns[$phrase]++
        }
    }

    # Detect task categories
    $taskCategories = @{
        'implementacion|desarrollar|crear|build|implement|feature|funcionalidad' = 'development'
        'bug|fix|error|arreglar|reparar|root cause|issue|problema|fallo' = 'bugfix'
        'refactor|mejorar|optimizar|clean|redesign|rediseñar|reestructurar' = 'refactor'
        'doc|documentar|readme|manual|gu[ií]a|wiki|documentación' = 'documentation'
        'test|prueba|testing|coverage|unit|integration|e2e' = 'testing'
        'deploy|release|ci/cd|pipeline|despliegue|publicar|deployment' = 'devops'
        'review|revisar|auditar|code review|pull request|pr' = 'review'
        'arquitectura|design|diseñar|architecture|schema|diagram' = 'architecture'
        'seguridad|security|vuln|vulnerabilidad|auth|permisos' = 'security'
        'dashboard|report|reporte|metrics|metricas|telemetr[ií]a' = 'analytics'
    }

    $detectedCategories = @()
    foreach ($catPattern in $taskCategories.Keys) {
        if ($inputLower -match $catPattern) {
            $detectedCategories += $taskCategories[$catPattern]
        }
    }

    Save-PatternDb $db

    return @{
        Categories = ($detectedCategories | Select-Object -Unique)
        TopPhrases = ($db.patterns.GetEnumerator() | Where-Object { $_.Value -ge 2 } | Sort-Object Value -Descending | Select-Object -First 5)
    }
}

# Generate proactive suggestions based on patterns
function Get-Suggestions {
    param([string]$UserText)

    $db = Load-PatternDb
    $suggestions = [System.Collections.Generic.List[string]]::new()

    $topPatterns = $db.patterns.GetEnumerator() | Sort-Object Value -Descending | Where-Object { $_.Value -ge 3 } | Select-Object -First 10

    $suggestionRules = @(
        @{ Match = 'dashboard|reporte|metricas'; Suggestion = 'Parece que trabajas frecuentemente con dashboards. ¿Quieres que automatice la generación del reporte al inicio de cada sesión?' }
        @{ Match = 'test|prueba'; Suggestion = 'Veo que haces pruebas seguido. ¿Quieres que configure un watch mode para que los tests corran automáticamente al detectar cambios?' }
        @{ Match = 'deploy|release|publicar'; Suggestion = 'Sueles hacer deploys. ¿Quieres que automatice el pipeline de release con validación pre-deploy?' }
        @{ Match = 'doc|documentar|readme'; Suggestion = 'Documentas frecuentemente. ¿Quieres que genere automáticamente docs a partir del código?' }
        @{ Match = 'refactor|mejorar|optimizar'; Suggestion = 'Haces refactors seguido. ¿Quieres que ejecute el analysis de code quality antes de empezar cada refactor?' }
        @{ Match = 'bug|fix|error'; Suggestion = 'Corriges bugs frecuentemente. ¿Quiero sugerir: ejecutar diagnosis automática antes de proponer fix?' }
    )

    $inputLower = $UserText.ToLower()
    foreach ($rule in $suggestionRules) {
        if ($inputLower -match $rule.Match -and -not $suggestions.Contains($rule.Suggestion)) {
            $suggestions.Add($rule.Suggestion)
        }
    }

    # If we have 3+ occurrences of any pattern, generate a suggestion
    if ($topPatterns.Count -gt 0) {
        $mostFrequent = $topPatterns | Select-Object -First 1
        if ($mostFrequent.Value -ge 5) {
            $suggestions.Add("He notado que repites '$($mostFrequent.Key)' con frecuencia ($($mostFrequent.Value) veces). ¿Quieres que cree un skill o automatización para esto?")
        }
    }

    return $suggestions
}

function Show-Report {
    $db = Load-PatternDb
    Write-Host "`n=== PATTERN DETECTION REPORT ===" -ForegroundColor Cyan
    Write-Host "Known patterns: $($db.patterns.Count)" -ForegroundColor White

    if ($db.patterns.Count -gt 0) {
        Write-Host "`n--- Top Recurring Patterns ---" -ForegroundColor Yellow
        $sorted = $db.patterns.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10
        foreach ($p in $sorted) {
            $bar = '#' * [Math]::Min(40, $p.Value)
            Write-Host "  $($p.Key): $($p.Value) $bar" -ForegroundColor White
        }
    }

    if ($db.suggestions.Count -gt 0) {
        Write-Host "`n--- Active Suggestions ---" -ForegroundColor Yellow
        foreach ($s in $db.suggestions) {
            Write-Host "  - $s" -ForegroundColor Green
        }
    }
}

switch ($Action) {
    'detect' {
        $result = Detect-Patterns -UserText $UserInput
        Write-Output (ConvertTo-Json $result -Compress)
    }
    'suggest' {
        $suggestions = Get-Suggestions -UserText $UserInput
        if ($suggestions.Count -gt 0) {
            foreach ($s in $suggestions) {
                Write-Host "[PROACTIVE] $s" -ForegroundColor Green
            }
            # Score this as a proactive attempt
            $scoringScript = Join-Path $scriptDir "session-scoring.ps1"
            if (Test-Path $scoringScript) {
                & $scoringScript -Action record -EventType proactive -Detail "suggestion: $($suggestions[0])" -Success:$true -DurationSeconds 0
            }
        }
    }
    'report' { Show-Report }
}
