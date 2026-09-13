---
created: 2026-08-22 03:03:46
tags: [engram, bugfix]
engram_id: 2953
type: bugfix
---

# Ghost runs CI: causa raíz ": " en escalar plano YAML

**What**: Resuelta la saga de ghost runs (startup_failure 0s, sin jobs, name=ruta) que afectaba push.yml/pr.yml/reusable-security.yml desde v3.3.1 (commit 45ff78f1). Causa raíz: el step `name: Scan SBOM (gate: fail on high+)` en reusable-security-scan.yml contiene la secuencia ilegal `:` (dos puntos+espacio) dentro de un escalar plano YAML. El parser server-side de GitHub rechaza TODO el archivo (lo registra con su ruta como nombre, referenced_workflows=[]), y cualquier caller cuyo grafo lo incluya falla a 0s.
**Why**: Los validadores locales (workflow-lint.ts, actionlint-style) no hacen parse YAML estricto y lo toleraban; js-yaml lo rechaza con "bad indentation of a mapping entry". Fix: citar el nombre (`name: "Scan SBOM (gate: fail on high+)"`). Commit be3543bd.
**Where**: .github/workflows/reusable-security-scan.yml, .github/workflows/push-checks.yml (renombrado desde push.yml), .github/workflows/pr.yml
**Learned**: 1) Un callee ilegible tumba el grafo completo del caller (no solo su propio run). 2) Renombrar archivos NO cura contenido envenenado — la nueva ruta se registra igual de rota. 3) El bisect A/B (reducir caller a governance-only → probe mínimo → restaurar jobs por chunks) aisló el veneno en 3 pushes. 4) workflow-lint.ts debe integrar parse js-yaml estricto (disponible en node_modules/.pnpm/@textlint+linter-formatter@14.8.4.../js-yaml) — pendiente como mejora. 5) Verificar salud: gh api /actions/workflows debe mostrar nombres propios, nunca rutas.

---
*Imported from Engram on 2026-09-06*
