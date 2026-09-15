---
created: 2026-09-13 14:42:08
tags: [engram, decision]
engram_id: 3896
type: decision
---

# Marketing GV aislado + CMS standalone slots + CSV import operativos

**What**: Aislé el marketing de Gentle-Vanguard en su propio directorio `C:\Users\emman\gentle-vanguard-marketing\` (único, libre de contrato del stack, portable), Y ESTA SESIÓN hice operativo el backend que faltaba.

**Por qué / contexto**: El usuario pidió un directorio de marketing aislado con SOLO el contenido (speeches, charlas, plan, captions) para operar las redes de la marca GV sin arrastrar el stack. Al mismo tiempo el stack tiene un CMS (apps/content-cms) que EL USUARIO considera "parte del negocio" y quiere que genere publicaciones de calidad tipo ChatGPT y administre calendario/lives — el usuario dijo "mejoremos, optimicemos, conectemos y hagamos que esto sea el mejor stack".

**Trabajo completado**:
1. Directorio marketing completo + README + índice en `C:\Users\emman\gentle-vanguard-marketing\`: `00_ESTRATEGIA` (GV-SPEECH-PLAYBOOK 1.0 con 8 speeches, 4 charlas, lives, plan 30 días, calendario, voz de marca) + plantillas operativas en `01_SPEECHES/`, `02_PLAN_PUBLICACIONES/`, `03_CAPTIONS/`, `04_ASSETS/`, `05_LEADS_Y_VENTAS/`, `06_METRICAS/`, `07_PLANTILLAS/`.
2. CMS (apps/content-cms) — servicios nuevos confirmados EN VIVO contra el server real:
   - `POST /api/slots` ahora acepta slots **standalone** (sin item_id: auto-crea item ligero) → es el flujo que faltaba para "agregar publicación sin crear contenido primero".
   - `POST /api/slots/import` — import CSV masivo (parsea header, columnas título/plataforma/fecha[,brief|objetivo|estado|rationale], fomato `YYYY-MM-DD HH:MM` local → ISO, auto-crea items). ✅ probado: `created=1`.
   - `POST /api/slots` con item_id sigue funcionando (backward compatible).
   - Cleanup de slots de prueba + 2 servers CMS reiniciados (scripts basados en bash + pidfile `.runtime/*.pid`, port check por netstat).
3. LlmGenerator (`apps/content-cms/server/generator.ts`): pipeline multi-paso — hooks → drafts → rewrite + scoring heurístico local (GV_BRAND_KIT + brand kit GV + few-shot por red + anti-slop). Typecheck OK. El prompt ya inyecta `docs/brand/BRAND-KIT.md` y la voz.
4. Nuevos tests de CSV/standalone agregados (62→65 tests pasan con 7 archivos). Se generaron las primeras piezas (8 speeches TikTok + 4 charlas + lives + captions).
5. Se limpiaron los procesos: maté los PIDs viejos (API 3787 + Vite 5175) sin tocar la sesión, y se relanzó con el código nuevo.

**Pendiente para la próxima sesión**:
- Verificar si el CMS UI (apps/content-cms/src/...contentos.tsx) tiene botones para los servicios nuevos (import CSV + standalone + fabric races) — el backend está pero hay que ver la capa UI/adapters.
- Los 8 speeches necesitan el resto de la estructura (brand kit GV + captions por red).
- Conectar con `apps/academy-web` (52 productos → calendar_slots) y con el `command-center` si se quiere. Decisión de negocio a confirmar con usuario: ¿el CMS es un producto de venta (Content OS) o solo para uso interno del stack? — esto define si se invierten días en publicar a redes reales (API/adapters).
- El README del directorio marketing aún enumera `07_PLANTILLAS` etc. como "pendiente" — falta llenar esas carpetas.

**Stack/técnica**: `npm run watchtower:health` (154 checks) → PASS excepto skill-embeddings freshness (se regeneró). Tests unidad CMS 65/65. API REST self-hosted 127.0.0.1:3787 con Vite UI en 3787. No hay dependencias externas nuevas salvo playwright + better-sqlite3 ya presentes. Columnas de calendar: title/platform/scheduled_at/status/score.

---
*Imported from Engram on 2026-09-14*
