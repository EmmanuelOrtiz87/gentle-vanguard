# Gentle-Vanguard Academy

Academy es el curso web local-first para aprender a operar y entender Gentle-Vanguard. Presenta
fundamentos, arquitectura, agentes, workflows, laboratorio práctico, negocio y glosario a partir de
la documentación vigente del repositorio.

## Propósito y público

| Aspecto          | Definición                                                                                              |
| ---------------- | ------------------------------------------------------------------------------------------------------- |
| Propósito        | Convertir la arquitectura y las prácticas del stack en un recorrido de aprendizaje navegable.           |
| Usuarios         | Desarrolladores, QA, analistas de negocio, operaciones, gobierno, documentación y nuevos colaboradores. |
| Cliente objetivo | Equipos que necesitan capacitación interna reproducible sin depender de un servicio externo.            |
| Entrega          | Sitio estático; no es un LMS ni gestiona matrículas, calificaciones o certificados.                     |

## Capacidades actuales

- Home, rutas de aprendizaje, índice de lecciones y navegación anterior/siguiente.
- Buscador de lecciones y glosario; rutas `#/`, `#/track/:id`, `#/lesson/:track/:lesson` y
  `#/glosario`.
- Referencias nuevas: caso comparativo antes/después con métricas fechadas y límites, y uso de
  Obsidian/Knowledge Base, Engram, Nexus, CodeGraph y Graphify.
- Renderizado de un subconjunto Markdown embebido: títulos, énfasis, código, bloques, listas, citas,
  tablas, separadores y resaltado.
- Funcionamiento con `file://` o mediante un servidor estático local.

No hay autenticación, perfiles, progreso persistente, evaluación, emisión de certificados, edición
desde la interfaz ni sincronización remota.

## Arquitectura y contenido

Es una SPA vanilla sin build ni dependencias externas. El shell está en `index.html`, la
presentación en `style.css`, el router/renderizador en `app.js` y los datos en `data/`. La app usa
`gv-design-system.css` como snapshot local del sistema visual compartido. El curso documenta la
arquitectura actual del stack: Obsidian como vault de conocimiento; Engram para memoria persistente;
Nexus para datos operativos; CodeGraph para el índice incremental de tooling; y Graphify para
análisis y consultas del grafo. Academy consume contenido publicado/embebido: no escribe
directamente en esos sistemas.

| Archivo             | Responsabilidad                    |
| ------------------- | ---------------------------------- |
| `index.html`        | Shell, navegación y carga de datos |
| `style.css`         | Estilos y tokens visuales          |
| `app.js`            | Router hash, búsqueda y renderer   |
| `data/tracks.js`    | Registro de rutas                  |
| `data/content-*.js` | Lecciones                          |
| `data/glossary.js`  | Glosario                           |

## Instalación y comandos

No requiere dependencias ni build. Desde `apps/academy-web`:

```bash
pnpm dev          # servidor local de desarrollo
pnpm preview      # servidor local para previsualización
```

También se puede ejecutar directamente con `python -m http.server 4173 -d .`.

Abrir `http://127.0.0.1:4173`. En operación normal, Academy se inicia bajo demanda desde Command
Center (`http://127.0.0.1:8090`), no como parte de un arranque total automático. Para una revisión
rápida también se puede abrir `index.html` directamente en el navegador.

La interfaz tiene español por defecto, selector es/en y tema claro/oscuro. El generador de prompts
fue extraído de Academy y ahora vive como Prompt Studio standalone.

## Operación independiente

Academy puede servirse sin Dashboard, CMS, Analytics, Nexus o red externa. Para actualizarla, editar
los archivos de `data/` y verificar manualmente las rutas principales en un navegador. El contenido
debe mantenerse alineado con `AGENTS.md`, `docs/stack-manual-full.md` y las guías activas.

## Importación y exportación

No existe importación/exportación de cursos desde la UI. El intercambio se realiza mediante cambios
de archivos versionados en Git.

## Seguridad, límites y soporte

- Al ser estática y local-first, no maneja credenciales ni datos de usuario.
- El renderer no está diseñado para contenido HTML arbitrario ni para material remoto.
- Si se publica detrás de un servidor, el autenticador, TLS, cabeceras y control de acceso
  pertenecen a esa infraestructura; no están implementados en Academy.
- Soporte: revisar el contenido fuente y abrir una incidencia en el canal de mantenimiento del
  repositorio con ruta, navegador y pasos de reproducción. No existe SLA comercial definido.

## Criterios de comercialización

**Apta como material de capacitación interna o demo estática.** Para venderla como producto
educativo faltan, como mínimo, identidad y roles, progreso por usuario, evaluaciones, certificados,
administración de contenidos y soporte/SLA. Estas capacidades no deben presentarse como disponibles.
