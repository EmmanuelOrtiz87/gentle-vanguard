# Gentle-Vanguard Content Studio

CMS local-first para gestionar contenidos estructurados en el navegador. Es una aplicación React +
TypeScript + Vite independiente; su estado `published` es local y no publica en Internet.

## Propósito y público

| Aspecto          | Definición                                                                                        |
| ---------------- | ------------------------------------------------------------------------------------------------- |
| Propósito        | Crear, revisar, previsualizar y transportar contenidos mediante JSON.                             |
| Usuarios         | Autores, editores y equipos que preparan material para sitios estáticos o integraciones futuras.  |
| Cliente objetivo | Equipos pequeños que necesitan una herramienta local de edición, no un CMS multiusuario completo. |
| Estado comercial | MVP funcional local; no es un servicio de publicación administrado.                               |

## Capacidades actuales

- Listar, crear, editar, previsualizar y eliminar contenidos.
- Estados `draft` y `published` locales, con flujo explícito de guardar y publicar.
- Historial inmutable por contenido, restauración como nueva versión y registro de auditoría local.
- Persistencia en `localStorage` con clave `gentle-vanguard.content-cms.v2`.
- Importación y exportación JSON con envelope `schemaVersion: 2`; el importador rechaza esquemas no
  compatibles.
- Validación de título, slug, cuerpo, etiquetas, estado y URL de portada.
- Gestión de assets raster locales: metadatos, MIME permitido, límite de 10 MB y alt obligatorio.
  SVG no se acepta ni se ejecuta.
- Preview de cuerpo como texto; no inyecta HTML.

## Arquitectura

`src/App.tsx` compone la interfaz; `src/domain.ts` define el modelo, schema, versionado, rollback y
validaciones; `src/storage.ts` encapsula persistencia; `src/main.tsx` monta React. La app no tiene
servidor propio, base de datos, MCP ni conexión directa con Obsidian, Engram, Nexus, CodeGraph o
Graphify. Esos componentes forman parte de la arquitectura del stack y pueden documentar/operar el
contexto alrededor de la app, pero no son capacidades de este MVP.

Modelo mínimo: `id`, `title`, `slug`, `excerpt`, `body`, `coverUrl`, `tags`, `status`, `updatedAt` y
assets locales opcionales.

## Instalación, comandos y operación independiente

```bash
cd apps/content-cms
pnpm install
pnpm dev          # desarrollo
pnpm build        # typecheck + build Vite
pnpm typecheck
pnpm test
pnpm test:quality # typecheck + lint + tests
pnpm lint
pnpm preview
```

La app se puede ejecutar sin las otras tres apps. El navegador debe permitir almacenamiento local;
si no lo permite, se usa un fallback en memoria que se pierde al cerrar la sesión.

## Pruebas de calidad

La suite de Vitest cubre el flujo de crear, editar, publicar, exportar, importar y hacer rollback
mediante transiciones del dominio, además de validaciones de URL de portada y assets raster
(incluido el bloqueo de SVG, payloads `data:` no permitidos, rutas relativas, credenciales en URL,
tamaños y alt). Ejecuta `pnpm test -- --reporter=verbose` para ver cada caso.

También incluye un smoke check estático de accesibilidad que verifica feedback de estado, grupos
identificables, labels de los controles y alt de assets. No hay `jsdom`, Testing Library, axe ni un
navegador instalado como dependencia de esta app, por lo que no se ejecutan clicks reales ni un
análisis WCAG completo; el límite queda documentado intencionadamente para no añadir dependencias
pesadas. La validación manual en navegador sigue siendo necesaria para layout, foco, teclado y
lectores de pantalla.

## Importación y exportación

La UI intercambia un objeto `{ "schemaVersion": 2, "items": [...] }`. El schema se valida antes de
modificar el estado y un archivo incompatible no se importa. Las URL de portada aceptan únicamente
`http` y `https`; una portada vacía es válida. La exportación no es publicación ni sincronización.

## Seguridad y límites conocidos

- No hay autenticación, autorización, backend, colaboración, CDN ni publicación remota.
- `published` significa publicado localmente y queda auditado en el navegador; no implica
  disponibilidad pública.
- Los assets se guardan como datos locales y solo se aceptan imágenes raster. No se interpreta SVG.
- Los datos quedan en el perfil del navegador y no están cifrados por la app; no introducir secretos
  ni datos sensibles.
- El JSON importado debe declarar schema 2; no existe migrador automático entre esquemas.

## Soporte y criterios de comercialización

Soporte técnico: ejecutar `pnpm test`, conservar el JSON reproducible y reportar ruta y navegador en
el canal de mantenimiento del repositorio. No hay SLA comercial definido.

**Apta para prototipos, edición local, preparación de contenido, historial y publicación local
auditable.** No es un CMS multiusuario: faltan identidad/RBAC, API, almacenamiento server-side,
workflow de aprobación, publicación remota, backups centralizados, observabilidad y soporte
operativo.
