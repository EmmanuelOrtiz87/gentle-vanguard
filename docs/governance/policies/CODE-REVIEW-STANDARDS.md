# Código de Conducta para Revisiones de Código

Este documento establece los estándares y mejores prácticas para las revisiones de código en el
proyecto Gentle-Vanguard.

## 1. Objetivo

Establecer un marco consistente para revisiones de código que garantice:

- Calidad del código
- Seguridad
- Mantenibilidad
- Cumplimiento de estándares de desarrollo

## 2. Criterios de Revisión (Five-Axis Review)

### 2.1 Correctitud

- Verificar que el código cumple con los requisitos especificados
- Comprobar manejo de casos extremos y errores
- Validar cobertura de pruebas unitarias
- Revisar condiciones de carrera y problemas de concurrencia

### 2.2 Legibilidad

- Verificar nombres de variables, funciones y clases descriptivos
- Comprobar estructura de control clara y lógica
- Validar complejidad del código (cyclomatic complexity)
- Revisar presencia de código muerto o comentarios obsoletos

### 2.3 Arquitectura

- Verificar patrones de diseño aplicados
- Comprobar límites de módulo y dependencias
- Validar dirección de dependencias (no deben ir hacia atrás)
- Revisar acoplamiento y cohesión

### 2.4 Seguridad

- Validar entrada de usuario y sanitización
- Revisar manejo de secretos y credenciales
- Comprobar autenticación y autorización
- Verificar protección contra inyección de prompts y ataques comunes

### 2.5 Rendimiento

- Revisar operaciones N+1
- Validar uso de recursos (memoria, CPU)
- Comprobar operaciones sincrónicas innecesarias
- Verificar paginación y límites de datos

## 3. Proceso de Revisión

### 3.1 Preparación

1. Asegurar que el código pasa todas las pruebas unitarias
2. Verificar que el código compila sin errores ni advertencias
3. Confirmar que se siguen las convenciones de estilo del proyecto
4. Validar que se han incluido pruebas de integración si aplica

### 3.2 Revisión

1. Revisar el propósito del cambio
2. Aplicar los cinco criterios mencionados anteriormente
3. Identificar hallazgos por severidad:
   - **Crítico**: Bloquea la fusión (seguridad, pérdida de datos, fallo)
   - **Requerido**: Debe corregirse antes de fusionar
   - **Opcional**: Sugerencia que vale la pena considerar
   - **FYI**: Información de interés

### 3.3 Comunicación

1. Comentar en el código específico donde se encuentran problemas
2. Usar lenguaje constructivo y profesional
3. Proporcionar sugerencias de mejora cuando sea apropiado
4. Documentar decisiones importantes en el historial de commits

## 4. Plantillas de Revisión

### 4.1 Cambios de Funcionalidad

```
## Revisión de Funcionalidad

### ¿Qué se cambió?
[Descripción breve del cambio]

### ¿Por qué se cambió?
[Justificación del cambio]

### ¿Cómo se puede probar?
[Pasos para validar el cambio]

### Criterios de aceptación
- [ ] Todos los tests pasan
- [ ] Cobertura de código adecuada
- [ ] No hay regresiones
```

### 4.2 Cambios de Seguridad

```
## Revisión de Seguridad

### Amenazas identificadas
- [ ] Inyección de prompts
- [ ] Acceso no autorizado
- [ ] Exposición de información sensible
- [ ] Vulnerabilidades de dependencias

### Medidas de protección implementadas
- [ ] Sanitización de entradas
- [ ] Validación de datos
- [ ] Control de acceso
- [ ] Registro de eventos de seguridad
```

### 4.3 Cambios de Rendimiento

```
## Revisión de Rendimiento

### Impacto potencial
- [ ] Uso de memoria
- [ ] Tiempo de ejecución
- [ ] Uso de CPU
- [ ] Acceso a bases de datos

### Optimizaciones implementadas
- [ ] Eliminación de operaciones redundantes
- [ ] Mejora en algoritmos
- [ ] Uso eficiente de caché
- [ ] Paginación de resultados
```

## 5. Herramientas de Apoyo

### 5.1 Verificación Automática

- `npm run lint` - Verificación de estilo de código
- `npm run typecheck` - Verificación de tipos
- `npm test` - Ejecución de pruebas unitarias
- `npm run security:check` - Verificación de seguridad

### 5.2 Métricas de Calidad

- Cobertura de código (mínimo 80%)
- Complejidad ciclomática (máximo 10 por función)
- Líneas de código por función (máximo 50)
- Número de dependencias (mínimo 10)

## 6. Buenas Prácticas

### 6.1 Para Revisores

1. Revisar el código con atención a los detalles
2. Entender el contexto del cambio antes de revisar
3. Ser constructivo y profesional en los comentarios
4. Priorizar problemas críticos y de seguridad
5. Verificar que las pruebas cubren el nuevo código

### 6.2 Para Autores

1. Escribir código limpio y bien documentado
2. Incluir pruebas unitarias para el nuevo código
3. Seguir las convenciones de estilo del proyecto
4. Documentar cambios significativos
5. Solicitar revisión temprana para código complejo

## 7. Aprobación Final

Una revisión se considera aprobada cuando:

1. Todos los hallazgos críticos y requeridos están resueltos
2. El código cumple con los estándares de calidad del proyecto
3. Todas las pruebas pasan satisfactoriamente
4. No hay objeciones significativas de los revisores
5. El cambio está alineado con los objetivos del proyecto

## 8. Revisión Periódica

Este documento debe revisarse cada 6 meses o después de cualquier cambio importante en las prácticas
de desarrollo del equipo.
