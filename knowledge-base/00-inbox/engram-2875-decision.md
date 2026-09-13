---
created: 2026-08-18 03:32:12
tags: [engram, decision]
engram_id: 2875
type: decision
---

# Chaos L4 en CI + container-scan db-update (roadmap 100% completo)

**What**: Chaos L4 (automated en CI/CD) + container-scan db-update implementados y pusheados. Stack completamente maduro.
**Why**: Completar los items de madurez a largo plazo del roadmap que eran accionables (chaos L4 era "siguiente paso" en ADR-0016; db-update era mitigación pendiente en ADR-0017).
**Where**: .github/workflows/scheduled.yml (job chaos semanal), src/chaos-engineering.ts (flag --json), src/container-scan.ts (acción db-update), package.json (container:db-update), docs/adr/ADR-0016 + ADR-0017, docs/guides/STACK-OPTIMIZATION-ROADMAP.md
**Learned**:
1. Commit 7287bd6f pusheado (546f5224..7287bd6f). Hooks pre-push pasaron (perf-baseline, typecheck, container-scan, etc.).
2. db-update: `grype db update` tarda ~51s y funciona (exit 0). Tras actualizar la DB, el scan bajó de ~9s a 1.9s (DB más fresca = matching más rápido).
3. Chaos L4: job semanal en scheduled.yml (cron 0 6 ** 0) ejecuta `chaos:run-all --json` y falla si hay experimentos FAILED. El CLI de chaos ahora soporta --json (run/run-all/report).
4. ESTADO FINAL DEL STACK: 367/367 tests PASS, health 95/95, git limpio, 18 ADRs (0001-0017), roadmap COMPLETO (todos los gaps cerrados), todas las capacidades nativas operativas (SLSA signer, chaos L4, container scan con hook CI + db-update).
5. El roadmap de optimización está 100% completo. No quedan items accionables de infraestructura. El siguiente valor real viene de USAR el stack para construir un proyecto, no de seguir puliendo.

---
*Imported from Engram on 2026-09-06*
