---
created: 2026-08-18 00:27:28
tags: [engram, decision]
engram_id: 2873
type: decision
---

# Container scanner nativo + fix coverage-runner + push (ADR-0017)

**What**: Container/Artifact Scanner nativo TS (ADR-0017) + fix de 2 tests coverage-runner + push a origin/develop. Suite completo 367/367 PASS.
**Why**: Cerrar el gap "container image scanning" del roadmap sin Docker (Syft+Grype+Trivy disponibles, Docker no).
**Where**: src/container-scan.ts, tests/unit/container-scan.test.ts (14 tests), tests/unit/coverage-runner.test.ts (fix noWrite), package.json (scripts container:*), docs/adr/ADR-0017, docs/adr/README.md (18 ADRs), STACK-OPTIMIZATION-ROADMAP.md (5.3 + summaries), STACK-STATUS-REPORT.md
**Learned**:
1. Commits: 7d8cd059 (scanner+docs+fix) y 077cbdbb (artefactos autostart). Push 353c9904..077cbdbb OK (hooks pre-push: perf-baseline, typecheck, codegraph-sync, hashline-snapshot pasaron).
2. Los 2 tests fallidos de coverage-runner eran pre-existentes: el flag --no-write se añadió en 6032c6f2 pero los tests no se actualizaron. Fix: añadir noWrite:false al expected.
3. gentle-ai v2.4.0 (2026-08-17): RDD ahora es opt-in (breaking change), PI runtime con background-subagents, fixes de review/SDD. Nuestro stack ya tiene RDD nativo + SLSA + chaos + container scan — vamos por camino propio (absorción nativa), no dependemos de gentle-ai.
4. Health check 95/95 PASS tras restaurar daemons (dashboard-ws port 8080 PID 41144, codegraph PID 3608).

---
*Imported from Engram on 2026-09-06*
