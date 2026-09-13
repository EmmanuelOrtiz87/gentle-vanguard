---
created: 2026-08-04 02:32:52
tags: [engram, bugfix]
engram_id: 2489
type: bugfix
---

# Error 503 queue full detectado - modelo nativo también afectado

**What**: El error "Streaming response failed: [503] The request queue is full" fue detectado en los logs de OpenCode. Añadí la firma "QueueFull" al model-provider-healer para detectar este tipo de error y hacer auto-switch automático.

**Why**: El error 503 indica que el proveedor LLM (incluso el modelo nativo opencode/deepseek-v4-flash-free) está experimentando alta carga y su cola de requests está llena. Esto causa que las llamadas a herramientas MCP (engram) se queden colgadas.

**Where**:
- Config actualizado: config/model-health.json - nueva firma "QueueFull" con pattern "request queue is full|503.*queue|streaming.*failed.*503|queue.*capacity"
- Estado actual: opencode/deepseek-v4-flash-free marcado como unhealthy (cooldown 60min)

**Learned**:
- El error 503 afecta tanto a modelos externos (kimi-2-5 via Bedrock) como al modelo nativo opencode cuando hay alta demanda
- El sistema de healer ahora detecta y marca estos modelos como unhealthy, pero NO puede auto-switch a otro modelo si TODOS están fallando
- Workaround: esperar al cooldown (60min) o usar timeout más agresivo en llamadas MCP

---
*Imported from Engram on 2026-09-06*
