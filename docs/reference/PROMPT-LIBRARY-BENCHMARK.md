# Benchmark: bancos de prompts (alpackaai.xyz) — absorción a Prompt Studio

**Fecha:** 2026-08-31 · **Origen:** análisis competitivo solicitado (sesión 13b/13c pendiente).
**Objeto:** qué hace bien un banco de prompts comercial y qué absorbimos nativamente en
`apps/prompt-studio` (ADR-0017: nada de SaaS externo — capacidad propia).

## 1. Qué es alpackaai.xyz

"Alpacka" — banco de prompts en español, 530 prompts publicados (marketing "+1.000"),
freemium (Gratis/Premium), modelo-agnóstico ("Cualquier modelo": ChatGPT, Claude, Gemini,
DeepSeek, Grok). Posicionamiento: *"resultados de nivel experto sin escribir nada desde cero"*.

### Taxonomía observada (8 categorías, conteo aproximado del directorio público)

| Categoría        | Enfoque | Observación |
| ---------------- | ------- | ----------- |
| Negocios         | Premium | venta B2B, pricing, pitch deck, ops — el core monetizado |
| Redes Sociales   | Premium | hooks virales, hilos X, carruseles, TikTok/Reels, reciclaje 1→15 |
| E-commerce       | Premium | fichas de producto, carritos, CRO, bundles |
| Finanzas Personales | Premium | deuda, presupuesto, inversión indexada |
| Programación     | Premium | code review, debugging sistemático, legacy, vibe coding, API design |
| Imagen           | Premium | prompt-engineering visual (foto producto, miniaturas, avatares) |
| Empleo           | Premium | CV anti-ATS |
| Educación        | Gratis (señuelo) | 2-3 prompts gratis como puerta de entrada |

### Patrones de producto que sí valen

1. **Título outcome-driven**: no "prompt de ventas" sino *"El Cerrador de Ventas B2B:
   descubrimiento, demo y cierre consultivo"* — promete el resultado, no la herramienta.
2. **Descripción = transformación**: siempre "de X a Y" (de hoja plana → descripción que vende).
3. **Modelo-agnóstico**: cada prompt declara "Cualquier modelo" — cero lock-in, más mercado.
4. **Freemium con señuelo funcional**: los gratis son útiles (no demos rotas) pero cubren 1 categoría.
5. **Categorías por audiencia/industria**, no por técnica: la gente busca "mi problema",
   no "chain-of-thought".

## 2. Lo que ya hacemos mejor (diferencial)

| Dimensión | Alpacka | Prompt Studio (GV) |
| --------- | ------- | ------------------ |
| Naturaleza | SaaS cerrado (copia/pega) | App local + biblioteca SQLite/FTS5 editable, propiedad del usuario |
| Contenido | 530 prompts fijos | Generador estructurado (rol/task/criterios/verificación) + biblioteca NL-search |
| Integración | Ninguna | Guías de uso con agentes + creación de Gemas de Gemini; vida en el stack GV |
| Datos | — | Facets reales, favoritos, tags, categorías — cero vendor lock-in |

## 3. Absorbido (implementado 2026-08-31)

- **Taxonomía de categorías** (`CATEGORIES` en `App.tsx`): Desarrollo, Negocios,
  Marketing/Redes, Educación, E-commerce, Finanzas, Empleo, Imagen — espejo del patrón
  por-audiencia del benchmark.
- **Columna `category`** en `prompts.db` (migración ligera `ALTER TABLE` idempotente) + campo
  en API POST/PUT.
- **Facet de categorías**: `GET /api/prompts` devuelve `categories` (conteos por categoría),
  filtro `?category=`, chips de filtro en la UI de biblioteca y badge violeta en cada card.
- Circuito verificado en vivo: POST con categoría → filtro → facet → delete.

## 4. Pendiente (no bloqueante)

- Contenido: precargar 10-20 prompts GV de alta calidad por categoría (los nuestros, no
  copiados de Alpacka) para que el facet no nazca vacío — mejor desde uso real primero.
- Gemas: sigue esperando la doc del usuario (video B7BY3TugqPA) para ampliar la guía.
- Si algún día se comercializa la biblioteca, el patrón freemium del benchmark ya está
  documentado aquí (F5 MASTER).
