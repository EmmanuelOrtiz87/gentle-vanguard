# Plantilla de Revisión de Código

## Información General

- **Autor**: [Nombre del autor]
- **Fecha**: [Fecha de la revisión]
- **Tipo de Cambio**: [Funcionalidad | Seguridad | Rendimiento | Refactorización | Otro]
- **Prioridad**: [Alta | Media | Baja]

## Descripción del Cambio

[Descripción breve del cambio implementado]

## Criterios de Revisión

### 1. Correctitud

- [ ] ¿El código cumple con los requisitos especificados?
- [ ] ¿Se manejan correctamente los casos extremos?
- [ ] ¿Las pruebas unitarias cubren el nuevo código?
- [ ] ¿No hay regresiones en funcionalidad existente?

### 2. Legibilidad

- [ ] ¿Los nombres de variables y funciones son descriptivos?
- [ ] ¿La estructura del código es clara?
- [ ] ¿No hay código muerto o comentarios obsoletos?
- [ ] ¿Se sigue el estilo de codificación del proyecto?

### 3. Arquitectura

- [ ] ¿Se aplican correctamente los patrones de diseño?
- [ ] ¿Los límites de módulo son adecuados?
- [ ] ¿No hay acoplamiento innecesario?
- [ ] ¿La estructura es mantenible?

### 4. Seguridad

- [ ] ¿Se sanitizan adecuadamente las entradas de usuario?
- [ ] ¿No se exponen secretos o credenciales?
- [ ] ¿Se implementan controles de acceso adecuados?
- [ ] ¿Se protege contra inyección de prompts?

### 5. Rendimiento

- [ ] ¿Se evitan operaciones N+1?
- [ ] ¿Se usa la memoria de forma eficiente?
- [ ] ¿No hay operaciones sincrónicas innecesarias?
- [ ] ¿Se implementan paginación cuando es necesario?

## Hallazgos

### Críticos (Bloquean la fusión)

-
-

### Requeridos (Debe corregirse antes de fusionar)

-
-

### Opcionales (Sugerencias de mejora)

-
-

### FYI (Información de interés)

-
-

## Recomendaciones

[Recomendaciones específicas para mejorar el código]

## Aprobación

- **Revisor**: [Nombre del revisor]
- **Estado**: [Pendiente | Aprobado | Rechazado | Revisar]
- **Fecha de aprobación**: [Fecha]

## Historial de Cambios

- [Fecha] - [Usuario] - [Descripción del cambio]
