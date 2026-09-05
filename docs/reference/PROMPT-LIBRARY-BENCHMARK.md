# Benchmark: bancos de prompts (alpackaai.xyz) — absorción a Prompt Studio

**Fecha:** 2026-08-31 · **Origen:** análisis competitivo solicitado (sesión 13b/13c pendiente).
**Objeto:** qué hace bien un banco de prompts comercial y qué absorbimos nativamente en
`apps/prompt-studio` (ADR-0017: nada de SaaS externo — capacidad propia).

## 1. Qué es alpackaai.xyz

"Alpacka" — banco de prompts en español, 530 prompts publicados (marketing "+1.000"), freemium
(Gratis/Premium), modelo-agnóstico ("Cualquier modelo": ChatGPT, Claude, Gemini, DeepSeek, Grok).
Posicionamiento: _"resultados de nivel experto sin escribir nada desde cero"_.

### Taxonomía observada (8 categorías, conteo aproximado del directorio público)

| Categoría           | Enfoque          | Observación                                                         |
| ------------------- | ---------------- | ------------------------------------------------------------------- |
| Negocios            | Premium          | venta B2B, pricing, pitch deck, ops — el core monetizado            |
| Redes Sociales      | Premium          | hooks virales, hilos X, carruseles, TikTok/Reels, reciclaje 1→15    |
| E-commerce          | Premium          | fichas de producto, carritos, CRO, bundles                          |
| Finanzas Personales | Premium          | deuda, presupuesto, inversión indexada                              |
| Programación        | Premium          | code review, debugging sistemático, legacy, vibe coding, API design |
| Imagen              | Premium          | prompt-engineering visual (foto producto, miniaturas, avatares)     |
| Empleo              | Premium          | CV anti-ATS                                                         |
| Educación           | Gratis (señuelo) | 2-3 prompts gratis como puerta de entrada                           |

### Patrones de producto que sí valen

1. **Título outcome-driven**: no "prompt de ventas" sino _"El Cerrador de Ventas B2B:
   descubrimiento, demo y cierre consultivo"_ — promete el resultado, no la herramienta.
2. **Descripción = transformación**: siempre "de X a Y" (de hoja plana → descripción que vende).
3. **Modelo-agnóstico**: cada prompt declara "Cualquier modelo" — cero lock-in, más mercado.
4. **Freemium con señuelo funcional**: los gratis son útiles (no demos rotas) pero cubren 1
   categoría.
5. **Categorías por audiencia/industria**, no por técnica: la gente busca "mi problema", no
   "chain-of-thought".

## 2. Lo que ya hacemos mejor (diferencial)

| Dimensión   | Alpacka                   | Prompt Studio (GV)                                                              |
| ----------- | ------------------------- | ------------------------------------------------------------------------------- |
| Naturaleza  | SaaS cerrado (copia/pega) | App local + biblioteca SQLite/FTS5 editable, propiedad del usuario              |
| Contenido   | 530 prompts fijos         | Generador estructurado (rol/task/criterios/verificación) + biblioteca NL-search |
| Integración | Ninguna                   | Guías de uso con agentes + creación de Gemas de Gemini; vida en el stack GV     |
| Datos       | —                         | Facets reales, favoritos, tags, categorías — cero vendor lock-in                |

## 3. Absorbido (implementado 2026-08-31)

- **Taxonomía de categorías** (`CATEGORIES` en `App.tsx`): Desarrollo, Negocios, Marketing/Redes,
  Educación, E-commerce, Finanzas, Empleo, Imagen — espejo del patrón por-audiencia del benchmark.
- **Columna `category`** en `prompts.db` (migración ligera `ALTER TABLE` idempotente) + campo en API
  POST/PUT.
- **Facet de categorías**: `GET /api/prompts` devuelve `categories` (conteos por categoría), filtro
  `?category=`, chips de filtro en la UI de biblioteca y badge violeta en cada card.
- Circuito verificado en vivo: POST con categoría → filtro → facet → delete.

## 4. Evolución v4 (2026-09-05) — de biblioteca a Gem Manager nativo

Con la evolución v4, Prompt Studio absorbe el siguiente nivel de las herramientas de referencia
(prompts.chat: librería navegable con detalle; alpackaai: títulos outcome-driven + freemium) y lo
supera con capacidades de plataforma:

1. **Pool por defecto curado de 12 gemas GV** (títulos outcome-driven, una por categoría benchmark)
   — la biblioteca ya no nace vacía ni depende del usuario (pendiente histórico §4 resuelto).
2. **Gemas como asistentes reutilizables** con modelo propio + chat operativo nativo (Gemini API,
   `system_instruction`).
3. **Convertir prompt → gema** en un clic (el generador estructurado alimenta las instrucciones).
4. **Login con Google (OAuth)** opcional y **API key de Gemini** opcional — todo local-first sin
   nada de esto.
5. Research Gemas Gemini (no hay API pública de CRUD): documentado en
   `docs/reference/PROMPT-STUDIO-GEMS.md` con el diseño local-first + conector Google.

## 5. Evolución v4.1 (2026-09-05) — Gem Space embebido + feedback real

Iteración basada en el uso real de la pantalla de Gemas:

1. **Chat multi-proveedor dentro de la app**: cada gema se usa en un chat embebido (Gem Space)
   con el **modelo del stack** (`opencode run -m big-pickle`, sin requisitos) o **Gemini** (API
   key validada en vivo). Respuestas etiquetadas con proveedor + modelo usado.
2. **Validación de API key en vivo**: al guardar la key se comprueba contra la API de Gemini
   (feedback `✅`/`❌`); el estado muestra los modelos disponibles.
3. **Import real de gemas de Google** (experimental, cookie de sesión): lista tus gemas
   (incluidas las predefinidas ocultas) y las importa localmente — el usuario ya no necesita
   salir de la app para ver lo que tiene en Gemini.
4. **UX corregida**: dos filas de filtros etiquetadas (Origen + Categoría), cards clickeables →
   modal de detalle con el prompt completo y acciones, chat prominente con toggle de proveedor.
5. **Fallback de modelos Gemini**: ante 404/503 reintenta modelos estables verificados
   (`gemini-flash-lite-latest` → `gemini-flash-latest` → `gemini-pro-latest` → `gemini-3.6-flash`).
   ⚠️ Google retiró 2.0/2.5-flash en esta fecha.

## 6. Pendiente (no bloqueante)

- Ampliar pool a 8-10 gemas por categoría con uso real.
- Export/import de gemas como plantillas JSON (alternativa robusta al sync frágil por cookies).
- OAuth completo (redirect con client ID) para login Google sin pegar token manual.
- Si algún día se comercializa la biblioteca, el patrón freemium del benchmark ya está documentado
  aquí (F5 MASTER).
