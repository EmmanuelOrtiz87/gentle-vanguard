# auto-delegation-wrapper.ps1
# Wrapper that loads auto-delegation config with multi-language support

$ErrorActionPreference = 'Continue'

# Keywords for task routing (multi-language support)
$spanishKeywords = @{
    "REPORT" = @("informe", "report", "reporte", "metricas", "metrics", "costos", "costs", "gerencia", "resumen", "session", "sesiones", "analytics", "dashboard")
    "GOV" = @("governance", "modificar", "config", "seguridad", "autenticacion", "permission", "orquestador", "seguro", "orchestrator", "rules", "policy", "admin")
    "DEV" = @("implement", "code", "develop", "feature", "bug", "crear", "agregar", "implementar", "componente", "endpoint", "function")
    "QA" = @("test", "testing", "qa", "validation", "prueba", "verificar", "test", "review", "judge")
    "DOC" = @("documentation", "docs", "document", "leer", "documentacion", "readme", "guide", "spec")
    "SAD" = @("architecture", "design", "sdd", "database", "schema", "api", "model")
    "OPS" = @("deploy", "docker", "kubernetes", "release", "infra", "build", "release")
}

function Get-RoutingConfig {
    param([string]$TaskDescription)
    
    # Multilanguage keywords: Spanish, English, Portuguese (BR)
    $keywordMappings = @{
        "REPORT" = @(
            # ES
            "informe", "report", "reporte", "metricas", "costos", "gerencia", "resumen", "session", "sesiones", "estadisticas", "telemetry",
            # EN
            "report", "metrics", "costs", "summary", "session", "sessions", "statistics", "telemetry",
            # PT-BR
            "relatorio", "metricas", "custos", "resumo", "sessoes", "estatisticas", "telemetria"
        )
        "GOV" = @(
            # ES
            "governance", "modificar", "config", "seguridad", "autenticacion", "permission", "orquestador", "seguro", "rules", "policy", "admin", "normas", "reglas",
            # EN
            "governance", "security", "auth", "permission", "access", "orchestrator", "rules", "policy", "admin",
            # PT-BR
            "governanca", "seguranca", "autenticacao", "permissao", "orquestrador", "regras", "politica"
        )
        "DEV" = @(
            # ES
            "implement", "code", "develop", "feature", "bug", "crear", "agregar", "implementar", "componente", "endpoint", "function", "codigo",
            # EN
            "implement", "code", "develop", "feature", "bug", "create", "add", "component", "endpoint", "function",
            # PT-BR
            "implementar", "codigo", "desenvolver", "feature", "bug", "criar", "adicionar", "componente", "endpoint", "funcao"
        )
        "QA" = @(
            # ES
            "test", "testing", "qa", "validation", "prueba", "verificar", "test", "review", "judge", "revisar",
            # EN
            "test", "testing", "qa", "validation", "verify", "review", "judgment", "judge",
            # PT-BR
            "test", "testing", "qa", "validacao", "verificar", "revisar", "julgar"
        )
        "DOC" = @(
            # ES
            "documentation", "docs", "document", "leer", "documentacion", "readme", "guide", "spec", "documento",
            # EN
            "documentation", "docs", "document", "readme", "guide", "spec",
            # PT-BR
            "documentacao", "docs", "document", "leitura", "guia", "especificacao"
        )
        "SAD" = @(
            # ES
            "architecture", "design", "sdd", "database", "schema", "api", "model", "arquitectura",
            # EN
            "architecture", "design", "sdd", "database", "schema", "api", "model",
            # PT-BR
            "arquitetura", "design", "database", "schema", "api", "modelo"
        )
        "OPS" = @(
            # ES
            "deploy", "docker", "kubernetes", "release", "infra", "build", "despliegue", "infraestructura",
            # EN
            "deploy", "docker", "kubernetes", "release", "infrastructure", "build",
            # PT-BR
            "deploy", "docker", "kubernetes", "release", "infraestrutura", "build"
        )
    }

    Write-Host "Task: $TaskDescription" -ForegroundColor Cyan
    Write-Host "Keywords loaded: $($keywordMappings.Keys -join ', ')" -ForegroundColor Gray
    
    return @{ keywordMappings = $keywordMappings; Enabled = $true }
}

function Route-TaskToAgent {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskDescription
    )
    
    $config = Get-RoutingConfig -TaskDescription $TaskDescription
    
    $taskLower = $TaskDescription.ToLower()
    $matches = @{}
    
    # Match keywords - flexible without word boundaries for Spanish
    foreach ($agent in $config.keywordMappings.Keys) {
        $count = 0
        foreach ($kw in $config.keywordMappings[$agent]) {
            $kwLower = $kw.ToLower()
            # Simple contains for Spanish compatibility
            if ($taskLower.Contains($kwLower)) {
                $count++
            }
        }
        if ($count -gt 0) {
            $matches[$agent] = $count
        }
    }
    
    if ($matches.Count -eq 0) {
        return @{
            Status = "NoKeywordsFound"
            RequiresManualDecision = $true
            Suggestion = "Provide a more specific task description"
        }
    }
    
    $topAgent = $matches.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
    
    return @{
        Status = "Routed"
        PrimaryAgent = $topAgent.Name
        Confidence = [math]::Min(80, 50 + ($topAgent.Value * 10))
        AllMatches = $matches
        RequiresManualDecision = $false
    }
}

# Test if called directly (legacy compatibility)
if ($MyInvocation.InvocationName -ne '.') {
    $Query = $args[0]
    
    if ($Query) {
        Route-TaskToAgent -TaskDescription $Query | ConvertTo-Json -Depth 4
    }
}