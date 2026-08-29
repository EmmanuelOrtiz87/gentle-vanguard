# NORMATIVA-SCRIPT-LIFECYCLE — Lifecycle de scripts

**Estado:** Activa  
**Aplica a:** scripts operacionales, launchers, comandos npm y pruebas de scripts  
**Autoridad:** complementa `rules/TYPESCRIPT-FIRST-POLICY.md` y
`docs/operations/PS1-LEGACY-POLICY.md`.

## 1. Objetivo

Mantener un único camino operativo, reproducible y auditable para cada capacidad del stack. Una
migración no termina por crear un `.ts`: debe dejar entry point soportado, callers actualizados,
pruebas ejecutables y una decisión explícita sobre el artefacto anterior.

## 2. Reglas obligatorias

1. **TS-only para lógica operacional.** Todo script nuevo y toda sustitución debe implementarse en
   TypeScript sobre Node.js. No se crean nuevos `.ps1` para operaciones del stack.
2. **CMD-first para invocación.** Los comandos documentados funcionan desde CMD y no requieren
   perfiles, módulos, aliases o semántica de PowerShell. Un launcher `.cmd` solo puede delegar al
   entry point TS; no puede duplicar su lógica.
3. **PowerShell no es dependencia.** `pwsh` solo aparece por excepción explícita y documentada,
   con motivo, caller, owner y fecha de revisión.
4. **Un entry point por capacidad.** Un alias o wrapper delega al entry point canónico. No se
   mantienen dos implementaciones activas para la misma capacidad.
5. **Evidencia antes de afirmar estado.** Inventarios y reportes distinguen archivos rastreados,
   cambios locales, referencias históricas y runtime verificado. La presencia de un `.ts` no prueba
   que una migración esté completa.

## 3. Estados e inventario

| Estado | Significado | ¿Se puede ejecutar? |
| --- | --- | --- |
| `active` | Entry point canónico soportado y probado | Sí |
| `wrapper` | Fachada que delega a `active` | Sí, como compatibilidad |
| `deprecated` | Visible durante transición, con reemplazo y fecha | Solo si la guía lo indica |
| `archived` | Histórico, fuera del runtime | No |
| `protected` | Histórico sensible/cifrado, fuera del runtime | No |
| `candidate` | Hallazgo sin decisión todavía | No se publica como soportado |

El inventario mínimo contiene ruta, estado, capacidad, entry point canónico, comandos soportados,
callers conocidos, owner, pruebas, fecha de revisión y destino del reemplazo. Debe estar versionado
y no ocultar candidatos.

**Hallazgo de este repositorio (snapshot de trabajo, 2026-08-29):** `package.json` expone comandos
operacionales mediante `npx tsx`/`node --import tsx` (por ejemplo líneas 63–69, 126–129 y 170–180),
y existen launchers `.cmd` rastreados como `gentle-vanguard-cmd.cmd`, `start.bat` y
`scripts/utilities/session/session-autostart.cmd`. En el mismo snapshot, `git ls-files '*.ps1'`
devuelve rutas históricas y rutas sujetas a cambios locales; por ello este documento no declara un
conteo global ni una migración completa.

## 4. Ownership

El owner de una capacidad mantiene entry point, contrato CLI, callers, documentación y pruebas, y
decide deprecación o archivo. El reviewer verifica que no queden duplicados activos. Sin owner
identificable, el script permanece `candidate` y no puede promocionarse a `active`.

## 5. Comandos soportados

- El comando soportado se registra en `package.json` o en un launcher `.cmd` versionado.
- La documentación indica propósito, entradas, salida y errores relevantes.
- `npx tsx <ruta.ts>` es la forma bloqueante para scripts TS. `node --import tsx <ruta.ts>` es válida
  para launchers/daemons cuando el proceso debe ser el hijo real.
- No se documentan `.ps1` archivados, rutas inexistentes, `dist/` no producido por su flujo ni
  helpers privados como si fueran API.
- Un cambio de ruta actualiza callers, `package.json`, guías, Academy y workflows afectados.

## 6. Procedimiento reproducible de migración

1. **Inventariar:** archivo, callers, comandos, workflows, tests y referencias Markdown.
2. **Definir contrato:** conservar nombre/flags/salida cuando sea compatible y documentar breaking
   changes antes de implementarlos.
3. **Implementar una sola vez:** crear el módulo TS y, si hace falta, un wrapper delgado.
4. **Registrar ownership:** estado, owner y comando canónico.
5. **Actualizar referencias:** callers y documentación en el mismo cambio lógico.
6. **Probar:** pruebas focalizadas, typecheck, lint y smoke del comando desde CMD. Para daemons,
   verificar PID/cleanup y ausencia de ventanas visibles en Windows.
7. **Archivar o eliminar:** solo tras la verificación de §7.

La migración debe poder repetirse en un checkout limpio con las mismas entradas y comandos. No se
aceptan pasos manuales no documentados, estado local implícito ni resultados obtenidos solo por
reintentar.

## 7. Archivo, protección, eliminación y recreación

- Un reemplazado se mueve a `.archive/` conservando contexto, o a `protected/` si es histórico
  sensible/cifrado. Ambos quedan fuera del runtime y no se descifran ni invocan.
- Antes de archivar se verifica: callers actualizados, cero referencias funcionales, pruebas del
  reemplazo, comando canónico operativo y documentación corregida.
- La eliminación definitiva requiere demostrar que no hay obligación de auditoría, recuperación,
  compatibilidad o retención. Mover a `.archive/` es el valor predeterminado; no se borra para
  esconder un hallazgo.
- Recrear un script archivado requiere un nuevo cambio: justificar la necesidad, asignar owner,
  definir contrato, añadir pruebas y actualizar inventario. No se restaura silenciosamente la ruta.
- Un artefacto histórico no justifica mantener un duplicado ejecutable.

## 8. Pruebas y deprecación

| Gate | Evidencia |
| --- | --- |
| Parseo/tipos | `npm run typecheck` pasa |
| Calidad | `npm run lint` pasa |
| Comportamiento | prueba focalizada, por ejemplo `npm run test:scripts-smoke` |
| Contrato | comando soportado ejecutado desde CMD |
| Referencias | búsqueda de callers y rutas antiguas |

La deprecación declara reemplazo, versión/fecha de inicio, owner y fecha de retirada. Durante la
transición el deprecated path solo puede ser wrapper o mensaje explícito; no recibe funcionalidad
nueva. Después se archiva o elimina según §7.

## 9. Criterio de aceptación

Un cambio de lifecycle es aceptable únicamente si tiene entry point canónico, no añade dependencia
de PowerShell, es invocable por comando soportado, tiene owner y pruebas, es reproducible y no deja
duplicados activos sin uso justificado.
