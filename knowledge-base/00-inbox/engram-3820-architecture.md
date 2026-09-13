---
created: 2026-09-09 19:32:05
tags: [engram, architecture]
engram_id: 3820
type: architecture
---

# Absorción Gentle-AI v2.7.0: gv rdd assess + risk-aware delegation + fix regex

**What**: Absorción de Gentle-AI v2.7.0 completada: (1) `gv rdd assess` — risk assessment standalone (equivalente a `gentle-ai review assess --json`), expone classify/explain/factors/review/gates vía case 'rdd' en gv.ts; (2) risk-aware delegation en recommend-agent.ts (`--risk-aware`): clasifica el diff con classifyRisk() y decide verificación low→none, standard→sdd-verify, high→rdd-4r-review; (3) fix bug crítico: 21 ocurrencias de \u005c en regex literales de risk-classifier.ts (rompían todos los patrones — \u005cs matchea \s literal no whitespace, por eso el classifier nunca detectaba cambios); (4) fix suma vs max en categoryScores (810→90). Doc: docs/reference/ABSORPTION-GENTLE-AI-V2.7.md.
**Why**: Usuario pidió revisar la release de Gentle-Programming/gentle-ai y absorber lo que complemente/potencie el stack.
**Where**: src/cli/gv.ts (case rdd), src/orchestration/recommend-agent.ts (--risk-aware + riskAwareVerification), src/rdd/risk-classifier.ts (fixes \u005c, max, patrones auth), docs/reference/ABSORPTION-GENTLE-AI-V2.7.md
**Learned**: (1) GOTCHA: en regex literal, \u005c se interpreta como barra invertida pero NO se combina con la letra siguiente — \u005cs = \ + s (matchea secuencia literal \s), no whitespace. (2) El stack ya tenía RDD nativo maduro (src/rdd/, src/review/) con las mismas 4R de Gentle-AI — el gap real era solo assess standalone + risk-aware delegation. (3) Los skills portables de gentle-ai (branch-pr, chained-pr, work-unit-commits, cognitive-doc-design, comment-writer) ya estaban absorbidos. (4) Verificación: tsc 0 errores, eslint 0, gv rdd assess clasifica diff real, recommend-agent --risk-aware devuelve {riskTier, riskScore, verification, rationale}.

---
*Imported from Engram on 2026-09-09*
