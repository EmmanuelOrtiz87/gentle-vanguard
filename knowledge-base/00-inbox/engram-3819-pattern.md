---
created: 2026-09-09 18:31:09
tags: [engram, pattern]
engram_id: 3819
type: pattern
---

# Nuevo hero academy: GENTLE VANGUARD ACADEMY + tagline + features

**What**: Nuevo hero en la home de GV Academy. Reemplazado "Academia local-first multi-curso / Una academia en archivos..." por: h1 "GENTLE VANGUARD ACADEMY" (span .g con gradiente en ACADEMY), tagline "Aprendé. Experimentá. Construí. Transformá." (gradiente), intro "Un espacio de aprendizaje creado para convertir conocimiento en capacidad real.", descripción "Explorá cursos prácticos sobre IA, tecnología, software...", 4 features pills (Cursos independientes · Aprendizaje práctico · Contenido siempre disponible · 100% local), y quote de cierre "No se trata solamente de aprender tecnología. Se trata de aprender a utilizarla para transformar lo que hacés." CTAs y stats intactos.
**Why**: Usuario pidió cambiar el título y descripción de la página principal de academy con el nuevo copy de marca.
**Where**: apps/academy-web/app.js (viewCourses hero), apps/academy-web/academy-style-v2.css (nuevas clases: .hero-tagline, .hero-intro, .hero-desc, .hero-features, .hero-feature, .hero-quote)
**Learned**: (1) El hero usa texto hardcodeado en español (no i18n) — patrón existente, se mantuvo. (2) El quote usa border-left con var(--gv-gradient-border) para el acento visual. (3) Verificación: Playwright 9/9 PASS (h1, tagline, intro, desc, 4 features, quote, 2 CTAs, 3 stats, sin page errors) + smoke 18/18.

---
*Imported from Engram on 2026-09-09*
