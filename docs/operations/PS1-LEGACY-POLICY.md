# Política de scripts históricos

El runtime soportado es TS-only y CMD-first: las operaciones se ejecutan con Node/TS (`npx tsx` o
`node --import tsx`) y los comandos portables usan sintaxis POSIX/CMD cuando corresponde.

La normativa completa de inventario, ownership, migración, pruebas, deprecación y recreación está en
[`rules/NORMATIVA-SCRIPT-LIFECYCLE.md`](../../rules/NORMATIVA-SCRIPT-LIFECYCLE.md).

`.archive/` contiene material histórico protegido y no ejecutable. Los archivos `*.ps1.enc` bajo
`protected/` son artefactos históricos protegidos; no se descifran, invocan ni se incluyen en el
runtime. Ninguna automatización activa puede usarlos como launcher.

No toda referencia a `.ps1` es una dependencia funcional: puede ser histórica, documental o parte de
un cambio local pendiente. Antes de eliminar o restaurar una ruta se revisan callers,
`package.json`, workflows y pruebas en un checkout limpio. Una migración solo se cierra cuando queda
un entry point TS único, comando soportado, owner, pruebas reproducibles y ninguna implementación
activa duplicada sin justificación.

Los helpers de mantenimiento de presentaciones fueron sustituidos por
`src/cli/presentations-maintenance.ts`, expuesto como `npm run presentations:maintenance`.
