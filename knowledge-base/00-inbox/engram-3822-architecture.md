---
created: 2026-09-09 19:52:21
tags: [engram, architecture]
engram_id: 3822
type: architecture
---

# Risk-aware verification automática en smallest-route-router (cierre backlog v2.7.0)

**What**: Risk-aware verification automática integrada en smallest-route-router.ts (el routing orgánico del orchestrator). El router ahora clasifica el diff actual con classifyRisk() en analyze() para rutas que tocan código (delegated/sdd/collaborative) y agrega `verification` a la RouteAnalysis: low→none, standard→sdd-verify, high→rdd-4r-review. recommend() lo incluye en la salida. Sin flags — el orchestrator decide la verificación post-apply sola.
**Why**: Cerrar el backlog de absorción Gentle-AI v2.7.0: cablear risk-aware por defecto en el orchestrator (era el único item con valor real pendiente).
**Where**: src/orchestration/smallest-route-router.ts (import classifyRisk, campo verification en RouteAnalysis, cálculo en analyze(), recommend() actualizado), docs/reference/ABSORPTION-GENTLE-AI-V2.7.md (punto 7)
**Learned**: (1) Commits: f0aa9956 (router) + 07653d0a (doc). (2) El router ya implementaba el routing orgánico de Gentle-AI v2.5.0 (direct/delegated/sdd); el risk tier de v2.7.0 lo completa con la verificación post-apply automática. (3) Verificación: tsc 0 errores, eslint 0, test en vivo devuelve {route: delegated, verification: {tier: high, score: 70, action: rdd-4r-review}}.

---
*Imported from Engram on 2026-09-09*
