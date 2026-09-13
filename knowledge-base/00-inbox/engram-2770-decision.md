---
created: 2026-08-13 02:13:49
tags: [engram, decision]
engram_id: 2770
type: decision
---

# Stack validation complete - 89/89 PASS, cloud delegators rebuilt real

**What**: Validación integral del stack completada — 89/89 PASS watchtower, 0 WARN, 0 FAIL. Reporte en reports/stack-health-report-2026-08-12.md
**Why**: Usuario pidió homologación total del stack: sin errores, sin gaps, sin simulaciones, todo documentado y funcional
**Where**: src/aws-delegator.ts (nuevo, HTTPS real), src/azure-delegator.ts (nuevo), src/adaptive-router.ts, src/event-sourcing.ts, src/result-gatekeeper.ts, src/setup-multi-machine.ts, package.json (7 scripts), config/subagent-mapping.json (v1.4), 6 docs prioritarios, .atl/skill-embeddings.json
**Learned**:
1. Los delegators AWS/Azure tenían fuentes TS perdidos pero JS compilado en dist/ — reconstruidos con invocación HTTPS REAL (AWS antes simulaba payload Lambda)
2. codegraph corre como MCP server sobre stdio (--mcp --no-watch), NO abre puerto TCP — el check "port 3000" del watchtower es falso negativo de diseño; validar por tabla de procesos
3. El autoheal del watchtower puede tardar minutos: wrapper launch falla → reintento direct spawn; timing race de ~5s entre spawn y scan de procesos
4. subagent-mapping.json referenciaba 7 agentes fantasma del ciclo SDD clásico (sdd-propose/spec/tasks/onboard/archive/init) — consolidados a agentes reales
5. 19 archivos temporales limpiados: 4 git rm + 15 movidos a .local/ (gitignored)
6. Commits: c4ceac7a (fixes código) + e968e47b (docs + embeddings)

---
*Imported from Engram on 2026-09-06*
