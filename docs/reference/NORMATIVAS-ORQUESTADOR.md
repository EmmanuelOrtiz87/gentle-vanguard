# NORMATIVAS DE ORQUESTADOR Y AUTORIZACIONES GLOBALES (Foundation)

## Objetivo
Centralizar y versionar todas las reglas, patrones, decisiones y aprendizajes clave del orquestador, agentes y skills, cumpliendo la directiva de almacenamiento dentro del proyecto Foundation.

---

## 1. Ubicacin y Estructura
- Este archivo debe residir en `docs/reference/NORMATIVAS-ORQUESTADOR.md` dentro del proyecto Foundation.
- No debe haber archivos normativos sueltos fuera del proyecto.
- Si exista un archivo global, su contenido debe migrarse aqu y eliminarse el original.

## 2. Contenido
- Autorizaciones globales y blanket approval
- Consulta y registro de autorizaciones
- Registro de decisiones y lecciones
- Consistencia y versionado
- mbito de aplicacin
- Ejemplos de patrones y decisiones
- Referencias cruzadas y protocolo de handoff

---

## 3. Referencias
- [OPERATING-DECISIONS-2026-04-15.md](OPERATING-DECISIONS-2026-04-15.md)

---

# [ANEXO] Migracin de normativas globales

El contenido de normativas-orquestador-global.md ha sido migrado y consolidado aqu para cumplir la directiva de centralizacin y versionado nico en Foundation.

## 1. Autorizaciones Globales y Blanket Approval
- Si el usuario otorga autorizacin global ("blanket approval"), ningn agente, subagente o skill debe solicitar confirmaciones adicionales para acciones dentro del alcance autorizado.
- Las autorizaciones globales deben registrarse en memoria persistente y en este archivo para consulta por cualquier agente/humano.
- Ejemplo: "autorizo limpieza total sin confirmacin" implica que toda accin de limpieza, refactor, homologacin y commit/push puede ejecutarse sin repregunta.

## 2. Consulta de Autorizaciones
- Antes de solicitar validacin al usuario, los agentes deben consultar:
  - Memoria persistente (engram, etc.)
  - Este archivo de normativas
- Si existe autorizacin previa, proceder sin repreguntar.

## 3. Registro de Decisiones y Lecciones
- Toda decisin arquitectnica, patrn, excepcin o aprendizaje relevante debe:
  - Guardarse en memoria persistente (engram)
  - Reflejarse en este archivo o en docs/reference/operating-decisions-*.md
- Ejemplo: "No repreguntar tras autorizacin global" es un patrn obligatorio.

## 4. Consistencia y Versionado
- Este archivo debe versionarse en el repositorio y actualizarse ante cualquier cambio de poltica, excepcin o aprendizaje relevante.
- Los skills y scripts deben consultar este archivo para operar de forma consistente.

## 5. mbito de Aplicacin
- Aplica a todo el workspace local y a todos los proyectos bajo Foundation - Development Stack.
- Debe ser referenciado desde README, CONTRIBUTING y skills de orquestacin.

## 6. Ejemplos de Patrones y Decisiones
- No repreguntar tras autorizacin global.
- Registrar todas las autorizaciones y excepciones en memoria y en archivo.
- Los agentes deben optimizar validaciones y evitar redundancias.
- Toda limpieza, refactor, homologacin y commit/push puede ejecutarse sin repregunta si hay blanket approval.
- Las normativas aqu descritas prevalecen salvo que un archivo de proyecto indique restricciones explcitas.

---

ltima actualizacin: 2026-04-19
Responsable: Orquestador Foundation
