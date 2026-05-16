# NORMATIVAS DE ORQUESTADOR Y AUTORIZACIONES GLOBALES (Gentle-Vanguard)

## Objetivo

Centralizar y versiónar todas las reglas, patrones, decisiones y aprendizajes clave del orquestador,
agentes y skills, cumpliendo la directiva de almacenamiento dentro del proyecto Gentle-Vanguard.

---

## Ubicación

## 1. Ubicación y Estructura

- Este archivo debe residir en `docs/reference/NORMATIVAS-ORQUESTADOR.md` dentro del proyecto
  Gentle-Vanguard.
- No debe haber archivos normativos sueltos fuera del proyecto.
- Si existía un archivo global, su contenido debe migrarse aquí y eliminarse el original.

## Contenido

## 2. Contenido

- Autorizaciones globales y blanket approval
- Consulta y registro de autorizaciones
- Registro de decisiones y lecciones
- Consistencia y versiónado
- Ámbito de aplicación
- Ejemplos de patrones y decisiones
- Referencias cruzadas y protocolo de handoff

## Decisiones

---

## 3. Autorizaciones Globales y Blanket Approval

- Si el usuario otorga autorización global ("blanket approval"), ningún agente, subagente o skill
  debe solicitar confirmaciones adicionales para acciones dentro del alcance autorizado.
- Las autorizaciones globales deben registrarse en memoria persistente y en este archivo para
  consulta por cualquier agente/humano.
- Ejemplo: "autorizo limpieza total sin confirmación" implica que toda acción de limpieza, refactor,
  homologación y commit/push puede ejecutarse sin repreguntar.

## 4. Consulta de Autorizaciones

- Antes de solicitar validación al usuario, los agentes deben consultar:
  - Memoria persistente (engram, etc.)
  - Este archivo de normativas
- Si existe autorización previa, proceder sin repreguntar.

## 5. Registro de Decisiones y Lecciones

- Toda decisión arquitectónica, patrón, excepción o aprendizaje relevante debe:
  - Guardarse en memoria persistente (engram)
  - Reflejarse en este archivo o en `docs/reference/OPERATING-DECISIONS-*.md`
- Ejemplo: "No repreguntar tras autorización global" es un patrón obligatorio.

## 6. Consistencia y Versiónado

- Este archivo debe versiónarse en el repositorio y actualizarse ante cualquier cambio de política,
  excepción o aprendizaje relevante.
- Los skills y scripts deben consultar este archivo para operar de forma consistente.

## 7. Ámbito de Aplicación

- Aplica a todo el workspace local y a todos los proyectos bajo Gentle-Vanguard - Development Stack.
- Debe ser referenciado desde README, CONTRIBUTING y skills de orquestación.

## 8. Ejemplos de Patrones y Decisiones

- No repreguntar tras autorización global.
- Registrar todas las autorizaciones y excepciones en memoria y en archivo.
- Los agentes deben optimizar validaciones y evitar redundancias.
- Toda limpieza, refactor, homologación y commit/push puede ejecutarse sin repreguntar si hay
  blanket approval.
- Las normativas aquí descritas prevalecen salvo que un archivo de proyecto indique restricciones
  explícitas.

---

## 9. Lecciones Aprendidas (2026-04-15 al 2026-05-02)

### Incidente: Eliminación Accidental de Hooks (2026-04-15)

**Problema:** Durante una limpieza rutinaria, los hooks pre-commit y commit-msg (lefthooks) fueron
eliminados accidentalmente.

**Causa Raíz:**

- Script de limpieza demasiado agresivo sin exclusiones para `.git/hooks/` y archivos de
  configuración de hooks
- Falta de protección para archivos de infraestructura crítica
- No se validó antes de ejecutar operaciones de eliminación masiva

**Prevención (Aplicado 2026-05-02):**

- ✅ Reglas de protección de infraestructura añadidas en scripts de limpieza
- ✅ `comprehensive-validation.ps1` actualizado para verificar configuración de hooks
- ✅ `.gitignore` actualizado para proteger archivos de hooks
- ✅ Procedimiento de recuperación documentado en `LESSONS-LEARNED-HOOKS-INCIDENT.md`

### Lección: Validación de Estructura Real vs Teórica

**Problema:** El validador original verificaba archivos y directorios que no existían (12% pass
rate).

**Solución (2026-05-02):**

- ✅ Actualizado `comprehensive-validation.ps1` para verificar archivos reales
- ✅ Pass rate mejorado: 12% → 96.36% (53 de 55 checks)
- ✅ Estructura documentada y homologada

### Lección: Acentos y Formato en Documentación

**Decisión:** Todos los archivos markdown deben tener:

- ✅ Acentos españoles correctos (automatización, configuración, revisión, activación)
- ✅ Bloques de código con lenguaje especificado (`powershell, `bash, ```json)
- ✅ Codificación UTF-8 sin BOM
- ✅ Emojis para escaneo visual (🚀, ⚙️, 🤖, 💡, 🚨, ✅)
- ✅ Tablas para datos estructurados
- ✅ Uso de `write` en lugar de `edit` para cambios grandes (evita errores de "múltiples
  coincidencias")

### Lección: PowerShell `-replace` Operator

**Problema:** El operador `-replace` en PowerShell no acepta bloques de script con `{}`.

**Solución:**

- ✅ Usar cadenas de reemplazo simples, no bloques script
- ✅ Ejemplo: `"texto" -replace "buscar", "reemplazar"` (NO usar `{}`)

### Lección: Delegación vs Ejecución Local

**Descubrimiento:** La delegación puede agotar el tiempo de espera (timeout) para operaciones
masivas.

**Solución:**

- ✅ Para operaciones masivas (ej. corregir 370+ archivos), usar scripts PowerShell locales
- ✅ Delegar solo tareas que requieren razonamiento, no procesamiento masivo

---

## 10. Referencias

- [OPERATING-DECISIONS-2026-04-15.md](OPERATING-DECISIONS-2026-04-15.md)
- LESSONS-LEARNED-HOOKS-INCIDENT.md (contenido integrado arriba)
- [CONFIGURATION-VALIDATION-CHECKLIST.md](../CONFIGURATION-VALIDATION-CHECKLIST.md)
- [AUTONOMOUS-VALIDATION-SYSTEM.md](../AUTONOMOUS-VALIDATION-SYSTEM.md)
- [AUTONOMOUS-SYSTEM-GUIDE.md](../AUTONOMOUS-SYSTEM-GUIDE.md)

---

## 11. Actualización y Mantenimiento

- **Versión:** 2.0 (Actualizado 2026-05-02)
- **Responsable:** Orquestador Gentle-Vanguard
- **Frecuencia de actualización:** Ante cualquier cambio de política, excepción o aprendizaje
  relevante
- **Validación:** Ejecutar `gv.ps1 verify` y `gv.ps1 audit` periódicamente

---

**Última actualización:** 2026-05-02  
**Responsable:** Orquestador Gentle-Vanguard

