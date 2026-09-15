---
created: 2026-09-13 13:28:04
tags: [engram, decision]
engram_id: 3895
type: decision
---

# Directorio marketing aislado + evaluación CMS

**What**: Directorio aislado de marketing creado en C:\Users\emman\gentle-vanguard-marketing\ con estructura completa (00_ESTRATEGIA a 07_PLANTILLAS), índice README.md, y el Speech Playbook copiado. Evaluación técnica del Content CMS completada.

**Why**: El usuario quiere un espacio único y aislado para todo el material de marketing, y evaluar si el CMS puede mejorarse para generar publicaciones de calidad y administrar publicaciones/charlas.

**Where**: C:\Users\emman\gentle-vanguard-marketing\ (fuera del repo), apps/content-cms/

**Learned**: 
- CMS es MVP sólido (51 tests, arquitectura limpia): calendario editorial funcional, video pipeline ffmpeg, 8 skills deterministas, generación multi-red con 4 providers (template/gemini/openai/stack)
- Limitación de generación: prompt de sistema genérico sin brand kit/few-shot/skills, un solo call LLM, provider default es "template" (determinista, no LLM), parseo JSON frágil
- Publicación: NUNCA publica a redes reales (solo copy-paste con gate humano, por diseño ADR-0021)
- Charlas/lives: NO existe soporte (solo posts)
- Mejoras estimadas: (a) calidad generación 2-4 días, (b) admin publicaciones 3-5 días, (c) calendario charlas 1-2 días = ~1-2 semanas total, sin reescritura (mejora incremental, no migración)
- Puntos de extensión: server/generator.ts, contrato adapter de platforms.json, tablas calendar_slots/content_items

---
*Imported from Engram on 2026-09-14*
