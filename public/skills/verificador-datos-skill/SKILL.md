---
name: verificador-datos-skill
description: >
  Reviews texts, posts, scripts, articles, reports, or AI responses to verify factual claims.
  Detects errors, exaggerations, unverifiable statements, and incorrect data before publishing.
  Trigger: "verifica este texto", "comprueba si esto es verdad", "revisa si hay errores", "pásalo
  por el verificador", "comprueba las afirmaciones", "revisa este guion antes de publicarlo", "fact
  check this", "verify this text", "check for errors in this", "validate information", "check this
  article", "verify claims"
license: Apache-2.0
metadata:
  author: workspace-local
  version: '1.0'
metadata:
  source: GV-native
---

# Verificador de Datos

Detecta errores, exageraciones, afirmaciones no verificables y datos incorrectos en cualquier texto
antes de publicarlo.

## Proceso obligatorio

1. **Lee el texto completo** antes de hacer valoraciones
2. **Extrae afirmaciones factuales verificables**: datos numéricos, fechas, estadísticas, precios,
   claims técnicos
3. **Separa opinión de hecho**: distingue afirmaciones comprobables de valoraciones subjetivas
4. **Verifica cada afirmación** usando el material fuente, transcripción, o razonamiento cuidadoso
5. **Clasifica cada afirmación** según las categorías definidas
6. **Señala errores, exageraciones y matices necesarios**
7. **Propón correcciones concretas**
8. **Entrega el informe completo**

## Clasificación de afirmaciones

| Categoría                  | Definición                               |
| -------------------------- | ---------------------------------------- |
| ✅ Correcta                | Respaldada claramente por las fuentes    |
| 🔶 Mayormente correcta     | Cierta en general, necesita matiz        |
| ❓ Dudosa / No verificable | Sin evidencia suficiente                 |
| ⚠️ Exagerada               | Base real, formulación demasiado rotunda |
| ❌ Incorrecta              | Contradice la información disponible     |
| 💬 Opinión / No factual    | Valoración subjetiva                     |

## Formato de respuesta

### 1. Resumen general

Evaluación breve del texto

### 2. Tabla de verificación

| Afirmación | Clasificación | Evidencia | Corrección |
| ---------- | ------------- | --------- | ---------- |

### 3. Errores o riesgos principales

Puntos más importantes ordenados por impacto

### 4. Versión corregida

Frases problemáticas reescritas en su contexto

### 5. Recomendación final

- ✅ Publicar tal cual
- 🔶 Publicar con cambios menores
- ⚠️ Revisar antes de publicar
- ❌ No publicar sin verificar

## Reglas

- No marques como falso algo solo porque no puedas comprobarlo. Clasifícalo como no verificable
- No cambies opiniones subjetivas salvo que se presenten como hechos
- No seas alarmista. Sé útil y constructivo
- Prioriza errores que afectan la credibilidad
- Si hay acceso web, úsalo para verificar afirmaciones cambiantes
- Si no hay acceso web, indica: verificación basada en conocimiento de entrenamiento
- Mantén el idioma original del texto revisado

## Áreas de atención especial

- **Herramientas de IA**: funcionalidades, precios, disponibilidad
- **Estadísticas**: porcentajes, cifras de usuarios, comparativas
- **Fechas**: lanzamientos, actualizaciones, eventos
- **Claims de productividad**: "X veces más rápido", "ahorra 80%"
- **Salud, finanzas o legal**: especialmente sensible por impacto
