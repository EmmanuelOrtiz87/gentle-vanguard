param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("BA","SAD","DEV","QA")]
    [string]$Domain,
    [string]$DatasetPath = "",
    [string]$OutputPath = "",
    [string]$BaseModel = "mistral-7b",
    [ValidateSet("local-ollama", "api", "python-unsloth", "dry-run")]
    [string]$Mode = "dry-run",
    [int]$Epochs = 3,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectRoot {
    $dir = $PSScriptRoot
    for ($i = 0; $i -lt 8; $i++) {
        if (Test-Path (Join-Path $dir ".git")) { return $dir }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    return $PSScriptRoot
}

$ProjectRoot = Resolve-ProjectRoot
if (-not $DatasetPath) { $DatasetPath = Join-Path $ProjectRoot ".ft" "dataset" }
if (-not $OutputPath) { $OutputPath = Join-Path $ProjectRoot ".ft" "adapters" $Domain }

$trainFile = Join-Path $DatasetPath "train" "$Domain.jsonl"
$valFile = Join-Path $DatasetPath "val" "$Domain.jsonl"

Write-Host "=== FT Trainer ===" -ForegroundColor Cyan
Write-Host "Domain: $Domain"
Write-Host "Mode: $Mode"
Write-Host "Base model: $BaseModel"
Write-Host ""

if (-not (Test-Path $trainFile)) {
    Write-Host "[FT-TRAIN] No training data for $Domain at $trainFile" -ForegroundColor Yellow
    Write-Host "[FT-TRAIN] Run ft-dataset-builder.ps1 first" -ForegroundColor Yellow
    exit 0
}

$trainCount = (Get-Content $trainFile -ErrorAction SilentlyContinue | Measure-Object).Count
$valCount = (Get-Content $valFile -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Host "[FT-TRAIN] Training records: $trainCount"
Write-Host "[FT-TRAIN] Validation records: $valCount"
Write-Host ""

switch ($Mode) {
    "dry-run" {
        Write-Host "[FT-TRAIN] DRY RUN — no training executed" -ForegroundColor Yellow
        Write-Host "[FT-TRAIN] Would train LoRA adapter for $Domain with:"
        Write-Host "  Dataset: $trainFile ($trainCount records)"
        Write-Host "  Base: $BaseModel"
        Write-Host "  Epochs: $Epochs"
        Write-Host "  Output: $OutputPath"
        Write-Host ""
        Write-Host "[FT-TRAIN] To train, use: -Mode python-unsloth (requires Python + unsloth)"
        Write-Host "  or: -Mode local-ollama (requires Ollama)"
        Write-Host "  or: -Mode api (requires API endpoint)"
    }

    "local-ollama" {
        Write-Host "[FT-TRAIN] Local Ollama training not yet implemented" -ForegroundColor Yellow
        Write-Host "[FT-TRAIN] Requires Ollama with modelfile support for LoRA"
    }

    "api" {
        Write-Host "[FT-TRAIN] API-based fine-tuning not yet implemented" -ForegroundColor Yellow
        Write-Host "[FT-TRAIN] Requires OpenAI-compatible API with fine-tuning endpoint"
    }

    "python-unsloth" {
        Write-Host "[FT-TRAIN] Python unsloth trainer not yet implemented" -ForegroundColor Yellow
        Write-Host "[FT-TRAIN] Future: scripts/utilities/FINE-TUNING/python/train_lora.py"
    }
}

$null = New-Item -ItemType Directory -Path $OutputPath -Force
$manifest = @{
    domain = $Domain
    baseModel = $BaseModel
    mode = $Mode
    epochs = $Epochs
    trainRecords = $trainCount
    valRecords = $valCount
    trainedAt = (Get-Date -Format "o")
    status = "pending"
    outputPath = $OutputPath
}
$manifest | ConvertTo-Json | Out-File (Join-Path $OutputPath "training-manifest.json") -Encoding utf8
Write-Host "[FT-TRAIN] Training manifest saved to $OutputPath" -ForegroundColor Gray
