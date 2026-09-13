---
created: 2026-08-12 03:56:34
tags: [engram, bugfix]
engram_id: 2763
type: bugfix
---

# trivy-action inputs verificados + vulns HIGH resueltas

**What**: Verificado en el código fuente de trivy-action v0.36.0 (action.yaml, SHA a9c7b0f0) que los inputs `exit-code`, `severity`, `scan-ref`, `scan-type`, `format`, `output` son válidos. El action es composite y mapea inputs a env vars TRIVY_EXIT_CODE, TRIVY_SEVERITY, etc. Además: el archivo de metadatos del action se llama **action.yaml** (NO action.yml) — por eso el fetch con action.yml daba 404.

**Why**: Configurar el job Dependency Scan como gate real de seguridad (fail si hay vulns HIGH/CRITICAL) en reusable-security.yml. Trivy v0.73 local confirma que el repo está limpio tras actualizar react-router a 7.18.2 y golang.org/x/text a v0.39.0.

**Where**: .github/workflows/reusable-security.yml, scripts/utilities/model-router-tui/go.mod

**Learned**:
1. El README de trivy-action documenta exit-code: "exit code when vulnerabilities were found" — es el estándar para gates.
2. El repo tenía 2 vulns HIGH reales: react-router 7.18.1 (GHSA-qwww-vcr4-c8h2, fix 7.18.2/8.3.0) y golang.org/x/text v0.3.8 (CVE-2026-56852, fix 0.39.0). Ambas resueltas.
3. apps/web-dashboard/package-lock.json (npm lock) fue eliminado del repo: la normativa rules/NORMATIVAS-SECURITY-COMPLIANCE.md dice "pnpm only, no package-lock.json", el proyecto es 100% pnpm, y el lock npm estaba desincronizado generando falsas vulns en trivy. Añadido a .gitignore.

---
*Imported from Engram on 2026-09-06*
