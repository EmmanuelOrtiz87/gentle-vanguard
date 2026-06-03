# Observabilidad: Gua de Artefactos y Ubicacin

## Objetivo

Centralizar la referencia de todos los artefactos, mtricas, logs y normativas relevantes para
observabilidad, continuidad y auditora en Gentle-Vanguard.

---

## 1. Artefactos de Sesin y Cierre

- **docs/sessions/**
  - `*-session-start.md`: Brief de inicio de sesin
  - `*-context-pack.md`: Handoff de contexto
  - `*-delivery-closure.md`: Cierre operativo
  - `closure-report-*.md`: Reporte consolidado de cierre
  - `README.md`: Explicacin de artefactos y comandos
- **docs/sessions/metrics/**
  - `agent-usage.csv`: Uso de agentes y skills
  - `context-usage.csv`: Uso de contexto y handoff
  - `judgment-history.csv`: Historial de revisiones adversariales
  - `token-guard-usage.csv`: Consumo de tokens y riesgos

## 2. Auditoras y Reportes

- **docs/audits/**
  - `*-audit.md`: Reportes de auditora peridica
  - `README.md`: Explicacin y comandos de auditora

## 3. Normativas y Protocolos

- **docs/reference/NORMATIVAS-ORQUESTADOR.md**: Normativas de orquestador y autorizaciones globales
  (debe estar SIEMPRE dentro del proyecto Gentle-Vanguard)
- **docs/reference/OPERATING-DECISIONS-\*.md**: decisiónes y reglas clave

## 4. Engram

- Memoria persistente de decisiónes, aprendizajes y autorizaciones (consultar desde skills y
  scripts)

## 5. Cumplimiento de Directivas

- Todas las normativas y protocolos deben estar almacenados dentro de `docs/reference/` en
  Gentle-Vanguard.
- No deben quedar archivos normativos sueltos a nivel global fuera del proyecto.
- Si existe un archivo global, migrar su contenido a Gentle-Vanguard y eliminar el archivo suelto.

## 6. Resumen Ejecutivo

- Toda la informacin relevante para observabilidad, auditora y continuidad est centralizada en los
  directorios y archivos anteriores.
- Skills, scripts y humanos deben consultar estos artefactos para operar y auditar el sistema.
- Si se detecta informacin fuera de esta estructura, debe migrarse y documentarse en
  Gentle-Vanguard.

---

ltima actualizacin: 2026-04-19 Responsable: Orquestador Gentle-Vanguard
