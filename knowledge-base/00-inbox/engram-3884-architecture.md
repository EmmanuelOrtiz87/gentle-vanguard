---
created: 2026-09-11 18:55:40
tags: [engram, architecture]
engram_id: 3884
type: architecture
---

# CRM: multi-moneda USD/ARS/BRL por producto

**What**: Multi-moneda en CRM Studio: cada producto puede tener su propia moneda (USD/ARS/BRL). Los deals heredan la moneda del producto seleccionado. El Historial muestra el revenue agrupado por moneda (sin conversión automática).

**Why**: El usuario planea comercializar en 3 mercados: extranjero (USD), Brasil (BRL) y Argentina (ARS). Cada producto puede tener su propia moneda según el mercado. El revenue final se calcula manualmente con la cotización del día.

**Where**:
- `apps/academy-crm/src/pages/Configuracion.tsx` — CURRENCIES = ['USD', 'ARS', 'BRL'], currencySymbol(), selector de moneda en el formulario de agregar producto Y en cada card de producto (editable inline)
- `apps/academy-crm/src/pages/Deals.tsx` — selectedProduct incluye currency, deal hereda currency del producto, Historial muestra revenue agrupado por moneda (byCurrency), cada card muestra currencySymbol + monto + código de moneda
- `apps/academy-crm/src/i18n.ts` — clave config_currency (es/en/pt)

**Learned**: (1) Multi-moneda por producto (no global) permite vender en diferentes mercados sin depender de tipos de cambio. (2) El Historial agrupa el revenue por moneda (byCurrency) — el usuario ve exactamente cuánto cobró en cada moneda. (3) La conversión a USD es manual (el usuario aplica la cotización del día cuando necesita el total consolidado). (4) El símbolo de moneda ($ para USD/ARS, R$ para BRL) se muestra junto al monto. (5) typecheck pasa.

---
*Imported from Engram on 2026-09-12*
