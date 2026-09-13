---
created: 2026-08-14 05:34:40
tags: [engram, decision]
engram_id: 2830
type: decision
---

# Plan próxima sesión: optimización consumo tokens (4 frentes)

**What**: Plan de la próxima sesión (2026-08-14+): atacar los 4 frentes de consumo/costo/tokens/contexto identificados en el resumen de cierre — inicio de sesión, cierre de sesión, delegación de agentes y cache
**Why**: El usuario pidió cerrar sesión y en la próxima atacar estos temas para mejorar y optimizar consumos, costos, gastos, tokens y contexto, automatizando y evolucionando configuraciones, prácticas, optimizaciones, mecanismos, flujos de trabajo y normativas
**Where**: config/session-autostart.config.json, src/token-ingest.ts, src/token-budget-guard.ts, src/prompt-compression.ts, src/structural-compression.ts, src/summarize-wipe.ts, src/adaptive-steps.ts, config/token-budget-guard.json
**Learned**:
- FRENTE 1 - INICIO DE SESIÓN: el token-ingest acumula TODAS las sesiones del día (12.4M vs budget 5M = 249% excedido). Optimizar: separar tracking por sesión actual vs acumulado, subir daily budget a valor realista (~13M), revisar steps lazy del autostart que consumen contexto
- FRENTE 2 - CIERRE DE SESIÓN: verificar que el cierre persista métricas reales (token-metrics-store lee Nexus → token-ingest → session-file), revisar que la compactación final se ejecute antes del cierre
- FRENTE 3 - DELEGACIÓN DE AGENTES: subagentes reenvían contexto completo (ses_05abdc8ecffey6: 4.85M input, ses_06f39b1a5ffebe: 1.47M). Optimizar: aplicar structural-compression modo input (lossless) a delegaciones, adaptive-steps para limitar pasos, prompt-compression (defaultCompressionRatio 0.4) antes de cada delegación
- FRENTE 4 - CACHE: 1.381.336.064 tokens de cache reads históricos (mecanismo dominante de ahorro). Optimizar: verificar que el cache se reutilice correctamente, evaluar FF-016 (RTK) si ratio sube >100:1
- Umbral de compactación actual: 5.000 tokens estimados — considerar bajar a 3.000
- Ratio actual 10.5:1 (excelente) vs 496:1 histórico (ses_006dfc914ffePcVi 15.9M tokens)

---
*Imported from Engram on 2026-09-06*
