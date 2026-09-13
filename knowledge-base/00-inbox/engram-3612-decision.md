---
created: 2026-09-02 11:40:04
tags: [engram, decision]
engram_id: 3612
type: decision
---

# Fuente canónica de marca: docs/brand v2 Premium (oficial)

**What**: Decisión de fuente canónica de marca del stack Gentle-Vanguard. LA FUENTE OFICIAL es docs/brand/ v2 Premium, NO el design-system alpha.
**Why**: El stack tenía dos definiciones de marca en conflicto; el usuario pidió determinar cuál es la oficial (la última hecha) y deprecar las anteriores como histórico.
**Where**: docs/brand/BRAND-DECISION-2026-09-01.md (decisión oficial), docs/brand/TOKENS-v2.json (tokens), docs/brand/BRAND-GUIDELINES-v2.md (guidelines), assets/logo.svg (logo v2.1), docs/brand/assets/*.svg (versions). Deprecado: packages/gv-design-system (alpha ADR-0026 #121212/Orbitron), v3 Kinetic (archivada).
**Learned**:
- OFICIAL v2 Premium: bg #0F1115, deep #090C11, surface #1a1f2a, raised #252b38; purple #a78bfa, cyan #22d3ee; text #e8eef4, muted #c4cdd8; display font Space Grotesk, body Inter, mono JetBrains Mono; gradient 135deg #a78bfa→#22d3ee; logo = monograma v1 + gradiente v2 (flecha en V + glow), wordmark "GentleVanguard".
- DEPRECADO (histórico): design-system alpha con bg #121212 y display Orbitron (ADR-0026). NO usar para marca nueva.
- ARCHIVADO: v3 Kinetic (lime terciario, Outfit) — NO es marca, solo experimento en Design Hub > Labs.
- PARA CREAR NUEVA DOC/DOCUMENTO (HTML/PDF/PPT/Word): usar siemprador docs/brand (guidelines + tokens + assets XML). El brand kit completo vive en docs/brand/.
**Árbol de assets**: logos → docs/brand/assets/ (logo-v2.svg, logo-icon-v2.svg, mono dark/light v2, banners, favicon); logo operativo del stack → assets/logo.svg.

---
*Imported from Engram on 2026-09-06*
