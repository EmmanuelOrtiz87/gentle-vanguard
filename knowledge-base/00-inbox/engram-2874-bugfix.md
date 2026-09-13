---
created: 2026-08-18 02:03:12
tags: [engram, bugfix]
engram_id: 2874
type: bugfix
---

# Fix cuelgue grype en container-scan + integración CI/hook

**What**: Resuelto el cuelgue de grype en container-scan (red) + integración en hooks y CI. Stack 95/95 health, git limpio.
**Why**: Grype se colgaba indefinidamente en el chequeo de actualizaciones de red (Windows); el scanner daba exit 2 "toolchain unavailable" y tardaba 99s.
**Where**: src/container-scan.ts, .lefthook.yml, .github/workflows/reusable-security.yml
**Learned**:
1. LA CAUSA RAÍZ: grype intenta chequear actualizaciones de DB/app en cada ejecución (GRYPE_DB_AUTO_UPDATE + GRYPE_CHECK_FOR_APP_UPDATE). Cuando la URL de update es inalcanzable, se cuelga SIN timeout útil. Fix: pasar esas env vars en spawnSync env (no hay flag CLI --offline en grype 0.117.0).
2. Trivy tiene el mismo problema: necesita --skip-db-update para no colgarse en el fetch de DB. En el entorno: trivy sbom con --skip-db-update funciona en 3.5s, grype con env vars en ~9s.
3. Solución implementada: Path 1 = grype (con env vars), Path 1b = trivy sbom --skip-db-update (fallback), Path 3 = trivy fs --skip-db-update. El orden de proveedores en scanArtifacts es ahora: grype SBOM → trivy SBOM → syft+grype dir → trivy fs.
4. Hook pre-push container-scan integrado en .lefthook.yml (--fail-on high --json, exit 1 bloquea push si vulns ≥ high). Job CI container-scan añadido a reusable-security.yml (instala Syft+Grype).
5. Commits: 7d8cd059 (scanner+ADR-0017+fix coverage-runner), 077cbdbb (artefactos), 546f5224 (fix cuelgue + CI/hook). Push a origin/develop OK, suite 367/367 PASS, health 95/95.

---
*Imported from Engram on 2026-09-06*
