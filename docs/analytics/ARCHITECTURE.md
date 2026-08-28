# Gentle-Vanguard Analytics - Architecture

## Topologia

```text
apps/gv-analytics
  UI React/Vite
  API local Node
        |
        v
  Atlassian connector
        |
        +-- Jira REST API v3
        +-- Confluence REST API v2
        +-- Bitbucket Cloud REST API 2.0
        |
        v
  Evidence normalizer
        |
        v
  Gentle-Vanguard stack
        |
        +-- MCP Atlassian
        +-- Nexus
        +-- Graphify / CodeGraph
        +-- route-and-delegate
        +-- config/model-router.json
        +-- OpenCode provider
```

## Modelo de analisis

```text
Entrada
  -> deteccion de tipo
  -> recupero de evidencia
  -> normalizacion
  -> lectura BA
  -> diseno SAD
  -> impacto DEV
  -> escenarios QA
  -> documentacion DOC
  -> reporte final
```

## Seguridad

- Read-only por defecto.
- Secretos fuera del repo.
- Auditoria para acciones futuras.
- Links y contenido externo tratados como datos no confiables.
- Writes en Jira, Confluence o Bitbucket solo con aprobacion humana.

## Integracion con OpenCode

La app no debe depender de la UI de OpenCode. La integracion viable es indirecta:

```text
Analytics API -> Gentle-Vanguard orchestration -> model-router -> OpenCode provider
```

Esto permite reutilizar modelos, perfiles y agentes existentes sin duplicar suscripciones ni
credenciales de modelo.
