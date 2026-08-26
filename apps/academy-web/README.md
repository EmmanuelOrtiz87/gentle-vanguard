# Gentle-Vanguard Academy

Web educativa local-first con todo el contenido del stack: fundamentos, arquitectura, optimización,
agentes, workflows, laboratorio práctico, negocio y glosario completo.

## Cómo ejecutarla

**Opción 1 — doble click (file://)**: abrir `index.html` en cualquier navegador. Funciona porque el
contenido está embebido en JS (sin fetch, sin servidor).

**Opción 2 — servidor estático** (recomendada para compartir en la red local):

```bash
# desde la raíz del repo
npx tsx src/dashboard-cmd-launcher.ts   # si el stack está corriendo (usa su entorno)
# o cualquier static server:
python -m http.server 4173 -d apps/academy-web
```

Sin build, sin dependencias externas, sin login, sin red: 100% local.

## Estructura

| Archivo             | Propósito                                                      |
| ------------------- | -------------------------------------------------------------- |
| `index.html`        | Shell (header, nav, footer, carga de datos)                    |
| `style.css`         | Estilos con los brand tokens oficiales (14-BRAND-SYSTEM)       |
| `app.js`            | SPA vanilla: hash router + renderer markdown-subset + buscador |
| `assets/logo*.svg`  | Monograma y lockup oficiales                                   |
| `data/tracks.js`    | Registro de rutas de aprendizaje                               |
| `data/content-*.js` | Contenido por track (lecciones en markdown-subset embebido)    |
| `data/glossary.js`  | Glosario (IA + técnico + negocio + términos propios)           |

## Markdown soportado en lecciones

`##` `###` · **bold** · `code` · bloques ``` · listas `-` y `1.` · `>` quote · tablas `| |` · `---`
· `==resaltado gradiente==`. Sin imágenes ni links (por diseño: todo local, sin dependencias).

## Rutas

- `#/` — home con las rutas de aprendizaje
- `#/track/:id` — índice de lecciones del track
- `#/lesson/:track/:lesson` — lección con sidebar, pager prev/next
- `#/glosario` — diccionario con filtros alfabéticos
- Buscador (tecla `/`): lecciones + glosario

## Actualizar contenido

Editar el `md` de la lección en `data/content-*.js` (o añadir lecciones al array). El contenido
deriva del stack real (AGENTS.md, stack-manual, GLOSSARY.md, guides, normativas y el kit comercial)
— al actualizar el stack, actualizar las lecciones afectadas en la misma pasada.

## Publicación futura

Cuando se desee exponer en un servidor con login: servir `apps/academy-web/` como estáticos tras el
authenticador que se elija (el dashboard WS ya trae RBAC v1 deployment-scoped reutilizable). El
perfil local-first no requiere nada de esto.
