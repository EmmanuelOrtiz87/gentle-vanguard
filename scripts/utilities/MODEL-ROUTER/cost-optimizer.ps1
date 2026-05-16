param(
    [ValidateSet('route', 'compare', 'estimate', 'session-spend', 'status')]
    [string]$Action = 'status',
    [string]$Model = '',
    [string]$RequestedProvider = '',
    [string]$Tier = '',
    [int]$EstimatedInputTokens = 0,
    [int]$EstimatedOutputTokens = 0,
    [string]$AgentType = '',
    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path
$costsPath = Join-Path $repoRoot 'config\provider-costs.json'
$stateDir = Join-Path $repoRoot '.session'
$spendFile = Join-Path $stateDir 'token-spend.json'

function Write-CLog {
    param([string]$M, [string]$C = 'White')
    if (-not $Quiet) { Write-Host $M -ForegroundColor $C }
}

function Initialize-SpendFile {
    if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
    if (-not (Test-Path $spendFile)) {
        @{ sessionStart = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'); providers = @{}; totalTokens = 0; totalCost = 0.0; routes = 0 } | ConvertTo-Json | Set-Content $spendFile -Encoding UTF8
    }
}

function Get-CostsConfig {
    if (Test-Path $costsPath) { return Get-Content $costsPath -Raw | ConvertFrom-Json }
    return $null
}

function Get-Spend {
    Initialize-SpendFile
    return Get-Content $spendFile -Raw | ConvertFrom-Json
}

function Save-Spend {
    param([object]$Data)
    Initialize-SpendFile
    $Data | ConvertTo-Json -Depth 5 | Set-Content $spendFile -Encoding UTF8 -Force
}

function Get-BestProvider {
    param([string]$TargetModel, [string]$PreferredTier, [array]$ExcludeProviders = @())
    $cfg = Get-CostsConfig
    if (-not $cfg) { return $null }

    $candidates = @()
    foreach ($prov in $cfg.providers.PSObject.Properties) {
        if ($ExcludeProviders -contains $prov.Name) { continue }
        $m = $prov.Value.models.PSObject.Properties[$TargetModel]
        if (-not $m) { continue }
        $candidates += @{ provider = $prov.Name; model = $TargetModel; input = [double]$m.Value.input; output = [double]$m.Value.output; tier = [string]$m.Value.tier }
    }

    if ($PreferredTier) {
        $filtered = @($candidates | Where-Object { $_.tier -eq $PreferredTier })
        if ($filtered) { $candidates = $filtered }
    }

    if ($candidates.Count -eq 0) { return $null }

    $sorted = $candidates | Sort-Object input, output
    return $sorted[0]
}

function Get-EquivalentModels {
    param([string]$TargetModel)
    $fallbackMap = @{
        'kimi-k2.6'    = @('qwen-3.6-plus', 'claude-haiku-3-5')
        'glm-5'        = @('gpt-4o-mini', 'claude-haiku-3-5')
        'qwen-3.6-plus' = @('claude-haiku-3-5', 'gpt-4o-mini', 'llama3')
    }
    if ($fallbackMap.ContainsKey($TargetModel)) { return $fallbackMap[$TargetModel] }
    return @()
}

switch ($Action) {
    'route' {
        $cfg = Get-CostsConfig
        if (-not $cfg) { Write-CLog '[ERR] provider-costs.json not found' 'Red'; exit 1 }

        $model = if ($Model) { $Model } else { 'qwen-3.6-plus' }
        $exclude = @()
        if ($RequestedProvider) { $exclude = @($RequestedProvider) }

        $best = Get-BestProvider -TargetModel $model -PreferredTier $Tier -ExcludeProviders $exclude
        if (-not $best) {
            $equiv = Get-EquivalentModels -TargetModel $model
            foreach ($em in $equiv) {
                $best = Get-BestProvider -TargetModel $em -PreferredTier $Tier -ExcludeProviders $exclude
                if ($best) { $best.originalModel = $model; $best.fallbackModel = $em; break }
            }
        }

        if (-not $best) {
            Write-CLog "[COST] No provider found for model $model" 'Yellow'
            if ($AsJson) { return (@{ model = $model; provider = $null; reason = 'no-provider' } | ConvertTo-Json) }
            exit 1
        }

        $estimatedCost = 0.0
        if ($EstimatedInputTokens -gt 0 -or $EstimatedOutputTokens -gt 0) {
            $estimatedCost = ($EstimatedInputTokens / 1000) * $best.input + ($EstimatedOutputTokens / 1000) * $best.output
        }

        # Track spend
        Initialize-SpendFile
        $spend = Get-Spend
        if (-not $spend.providers.PSObject.Properties[$best.provider]) {
            $spend.providers | Add-Member -NotePropertyName $best.provider -NotePropertyValue (@{ tokens = 0; cost = 0.0; routes = 0 })
        }
        $spend.providers.$($best.provider).routes++
        $spend.totalTokens += $EstimatedInputTokens + $EstimatedOutputTokens
        $spend.totalCost = [double]$spend.totalCost + $estimatedCost
        $spend.routes++
        Save-Spend -Data $spend

        $result = @{
            provider = $best.provider
            model = if ($best.fallbackModel) { $best.fallbackModel } else { $best.model }
            originalModel = $best.originalModel
            tier = $best.tier
            inputCostPer1K = $best.input
            outputCostPer1K = $best.output
            estimatedCost = [math]::Round($estimatedCost, 6)
            estimatedInputTokens = $EstimatedInputTokens
            estimatedOutputTokens = $EstimatedOutputTokens
        }

        if ($AsJson) { return ($result | ConvertTo-Json) }
        $tag = if ($result.originalModel) { "(fallback: $($result.originalModel))" } else { '' }
        Write-CLog "[COST] $($result.provider)/$($result.model) $tag" 'Green'
        Write-CLog "  Tier: $($result.tier) | Input: `$$($result.inputCostPer1K)/1K | Output: `$$($result.outputCostPer1K)/1K" 'Gray'
        if ($estimatedCost -gt 0) { Write-CLog "  Estimated: `$$($result.estimatedCost)" 'Cyan' }
    }

    'compare' {
        $cfg = Get-CostsConfig
        if (-not $cfg) { Write-CLog '[ERR] provider-costs.json not found' 'Red'; exit 1 }
        $model = if ($Model) { $Model } else { '*' }

        Write-CLog "=== Cost Comparison ===" 'Cyan'
        foreach ($prov in $cfg.providers.PSObject.Properties) {
            foreach ($m in $prov.Value.models.PSObject.Properties) {
                if ($model -eq '*' -or $m.Name -eq $model) {
                    $tier = $m.Value.tier
                    $color = if ($tier -eq 'free') { 'Green' } elseif ($tier -eq 'standard') { 'White' } else { 'Yellow' }
                    Write-Host "  $($prov.Name)/$($m.Name): input=`$$($m.Value.input)/1K output=`$$($m.Value.output)/1K [$tier]" -ForegroundColor $color
                }
            }
        }
    }

    'estimate' {
        if ($EstimatedInputTokens -eq 0 -and $EstimatedOutputTokens -eq 0) {
            Write-CLog 'Specify -EstimatedInputTokens and -EstimatedOutputTokens' 'Yellow'; exit 1
        }
        $cfg = Get-CostsConfig
        if (-not $cfg) { Write-CLog '[ERR] provider-costs.json not found' 'Red'; exit 1 }

        $results = @()
        foreach ($prov in $cfg.providers.PSObject.Properties) {
            $modelKey = if ($Model) { $Model } else { ($prov.Value.models.PSObject.Properties | Select-Object -First 1).Name }
            $m = $prov.Value.models.PSObject.Properties[$modelKey]
            if (-not $m) { continue }
            $cost = ($EstimatedInputTokens / 1000) * [double]$m.Value.input + ($EstimatedOutputTokens / 1000) * [double]$m.Value.output
            $results += @{ provider = $prov.Name; model = $modelKey; cost = [math]::Round($cost, 6); tier = [string]$m.Value.tier }
        }

        $sorted = $results | Sort-Object cost
        if ($AsJson) { return ($sorted | ConvertTo-Json) }
        Write-CLog "=== Cost Estimate ($EstimatedInputTokens in / $EstimatedOutputTokens out) ===" 'Cyan'
        foreach ($r in $sorted) {
            $color = if ($r.tier -eq 'free') { 'Green' } elseif ($r -eq $sorted[0]) { 'Cyan' } else { 'Gray' }
            Write-Host "  $($r.provider)/$($r.model): `$$($r.cost) [$($r.tier)]" -ForegroundColor $color
        }
    }

    'session-spend' {
        Initialize-SpendFile
        $spend = Get-Spend
        if ($AsJson) { return ($spend | ConvertTo-Json) }
        Write-CLog "=== Session Token Spend ===" 'Cyan'
        Write-Host "  Session: $($spend.sessionStart)" -ForegroundColor White
        Write-Host "  Total tokens: $($spend.totalTokens)" -ForegroundColor White
        Write-Host "  Total cost: `$$([math]::Round($spend.totalCost, 4))" -ForegroundColor Cyan
        Write-Host "  Routes evaluated: $($spend.routes)" -ForegroundColor White
        Write-Host "  By provider:" -ForegroundColor Yellow
        foreach ($p in $spend.providers.PSObject.Properties) {
            Write-Host "    $($p.Name): $($p.Value.tokens) tokens, `$$($p.Value.cost), $($p.Value.routes) routes" -ForegroundColor Gray
        }
    }

    'status' {
        $cfg = Get-CostsConfig
        if (-not $cfg) { Write-CLog '[ERR] provider-costs.json not found' 'Red'; exit 1 }
        Initialize-SpendFile
        $spend = Get-Spend

        $providerCount = @($cfg.providers.PSObject.Properties).Count
        $modelCount = 0
        foreach ($p in $cfg.providers.PSObject.Properties) { $modelCount += @($p.Value.models.PSObject.Properties).Count }

        if ($AsJson) {
            return (@{
                providers = $providerCount; models = $modelCount
                routingStrategy = $cfg.routingStrategy.preference
                sessionRoutes = $spend.routes; sessionCost = $spend.totalCost
            } | ConvertTo-Json)
        }
        Write-CLog "=== Cost Optimizer ===" 'Cyan'
        Write-Host "  Providers: $providerCount" -ForegroundColor White
        Write-Host "  Models tracked: $modelCount" -ForegroundColor White
        Write-Host "  Strategy: $($cfg.routingStrategy.preference)" -ForegroundColor White
        Write-Host "  Session routes: $($spend.routes)" -ForegroundColor Gray
        Write-Host "  Session cost: `$$([math]::Round($spend.totalCost, 4))" -ForegroundColor Cyan
    }
}
