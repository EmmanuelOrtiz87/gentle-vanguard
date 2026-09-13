---
created: 2026-09-03 15:12:59
tags: [engram, bugfix]
engram_id: 3654
type: bugfix
---

# Fix Error JSON - GV Analytics API

## What

Error "Failed to execute 'json' on 'Response': Unexpected end of JSON input" al intentar analizar URLs en GV Analytics.

## Why

El error ocurría porque:
1. La función `readJson()` en App.tsx intentaba parsear JSON antes de verificar si la respuesta era exitosa
2. Si el servidor retornaba un error HTTP (500) con body vacío o no JSON, el parseo fallaba
3. El servidor no tenía try-catch en el endpoint `/api/analyze` para manejar errores gracefully

## Where

- apps/gv-analytics/src/App.tsx - función readJson()
- apps/gv-analytics/server/index.ts - endpoint /api/analyze

## Fix Applied

### Frontend (App.tsx):

```typescript
// Antes: parseaba JSON antes de verificar response.ok
const body = await response.json();
if (!response.ok) { throw... }

// Ahora: lee como texto primero, intenta parsear, maneja errores
const text = await response.text();
let body: unknown;
try {
  body = text ? JSON.parse(text) : {};
} catch (e) {
  throw new Error(`Respuesta no válida del servidor: ${text.substring(0, 200)}`);
}
if (!response.ok) { throw... }
```

### Backend (server/index.ts):

```typescript
// Agregado try-catch alrededor de analyzeInput
try {
  const report = await analyzeInput({ urls, request: body.request });
  sendJson(res, 200, report);
} catch (error) {
  console.error('[API /api/analyze] Error:', error);
  sendJson(res, 500, { 
    error: 'Error al procesar el análisis',
    details: error.message 
  });
}
```

## Learned

- Siempre leer respuesta como texto primero antes de intentar parsear JSON
- Agregar try-catch en endpoints críticos del servidor
- Proveer mensajes de error descriptivos al usuario
- Build exitoso: 1346 módulos transformados

---
*Imported from Engram on 2026-09-06*
