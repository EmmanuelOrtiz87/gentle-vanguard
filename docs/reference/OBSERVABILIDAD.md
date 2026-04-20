# Observabilidad: Guía de Artefactos y Ubicación

## Objetivo
Centralizar la referencia de todos los artefactos, métricas, logs y normativas relevantes para observabilidad, continuidad y auditoría en Foundation.

---

## 1. Artefactos de Sesión y Cierre
- **docs/sessions/**
  - `*-session-start.md`: Brief de inicio de sesión
  - `*-context-pack.md`: Handoff de contexto
  - `*-delivery-closure.md`: Cierre operativo
  - `closure-report-*.md`: Reporte consolidado de cierre
  - `README.md`: Explicación de artefactos y comandos
- **docs/sessions/metrics/**
  - `agent-usage.csv`: Uso de agentes y skills
  - `context-usage.csv`: Uso de contexto y handoff
  - `judgment-history.csv`: Historial de revisiones adversariales
  - `token-guard-usage.csv`: Consumo de tokens y riesgos

## 2. Auditorías y Reportes
- **docs/audits/**
  - `*-audit.md`: Reportes de auditoría periódica
  - `README.md`: Explicación y comandos de auditoría

## 3. Normativas y Protocolos
- **docs/reference/NORMATIVAS-ORQUESTADOR.md**: Normativas de orquestador y autorizaciones globales (debe estar SIEMPRE dentro del proyecto Foundation)
- **docs/reference/PROTOCOLO-NORMATIVAS-SESIÓN.md**: Protocolo de normalización y persistencia
- **docs/reference/HANDOFF-TEMPLATE.md**: Plantilla de artefacto de handoff
- **docs/reference/OPERATING-DECISIONS-*.md**: Decisiones y reglas clave

## 4. Engram
- Memoria persistente de decisiones, aprendizajes y autorizaciones (consultar desde skills y scripts)

## 5. Cumplimiento de Directivas
- Todas las normativas y protocolos deben estar almacenados dentro de `docs/reference/` en Foundation.
- No deben quedar archivos normativos sueltos a nivel global fuera del proyecto.
- Si existe un archivo global, migrar su contenido a Foundation y eliminar el archivo suelto.

## 6. Resumen Ejecutivo
- Toda la información relevante para observabilidad, auditoría y continuidad está centralizada en los directorios y archivos anteriores.
- Skills, scripts y humanos deben consultar estos artefactos para operar y auditar el sistema.
- Si se detecta información fuera de esta estructura, debe migrarse y documentarse en Foundation.

---

Última actualización: 2026-04-19
Responsable: Orquestador Foundation
