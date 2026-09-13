---
created: 2026-09-10 04:08:53
tags: [engram, architecture]
engram_id: 3849
type: architecture
---

# Academy: Landing pública (#/landing)

**What**: Landing pública de Academy (#/landing) — la puerta de entrada comercial de la estrategia de venta. Presenta la Academy como producto con stats del catálogo, audiencias (Personas/Estudiantes/Empresas con links a paquetes), formatos (Cursos/eBooks/Toolkits/Paquetes con contadores), destacados con export PDF y banner "Todo exportable a PDF".

**Why**: El usuario pidió seguir potenciando el stack. La landing es el "front door" que faltaba: atrae personas, estudiantes y empresas hacia los productos (lead magnets → bundles → combos).

**Where**:
- `apps/academy-web/app.js` — `viewLanding()` (hero con 4 stats, 3 landing-aud-card con links a paquetes por audiencia, 4 landing-format-card con contadores, 8 featured store-cards, landing-export-banner), ruta `#/landing`, i18n landing (es/en/pt, ~20 claves)
- `apps/academy-web/index.html` — nav con link "Inicio" (data-route="landing") al frente
- `apps/academy-web/academy-layout.css` — estilos `.landing-aud-grid/card/icon/link`, `.landing-format-grid/card/icon/count`, `.landing-export-banner/icon`

**Learned**: (1) La landing reutiliza los componentes existentes (store-card, hero, animateCounters) — cero duplicación. (2) Los links de audiencia se resuelven dinámicamente desde los paquetes (si un paquete no existe, el link se omite). (3) Verificado: 3 aud-cards + 4 format-cards + 8 featured + banner + nav. (4) Estado: 20 cursos + 12 ebooks + 9 toolkits + 9 paquetes + Landing + Store + dashboard panel.

---
*Imported from Engram on 2026-09-10*
