---
name: optimizador-prompts-skill
description: >
  Transforms messy ideas, poorly written prompts, voice notes, or incomplete instructions into
  clear, structured prompts ready for AI tools. Trigger: "mejora este prompt", "conviértelo en un
  prompt", "ordena esta idea", "hazme un prompt para", "optimiza esto para", "te voy a dictar una
  idea desordenada", "improve this prompt", "optimize prompt", "structure this idea", "create a
  prompt for", "make a prompt for", "turn this into a prompt"
license: Apache-2.0
metadata:
  author: workspace-local
  version: '1.0'
metadata:
  source: GV-native
---

# Optimizador de Prompts

Convierte ideas caóticas, notas rápidas o instrucciones incompletas en prompts profesionales,
precisos y listos para usar.

## Proceso

### 1. Detecta la herramienta objetivo

Antes de generar el prompt, identifica para qué herramienta o modelo se va a usar:

- Claude, ChatGPT, Gemini (conversacionales/texto)
- Claude Code u otras herramientas de programación
- Midjourney, Flux, Stable Diffusion, Firefly (imagen)
- Sora, Kling, Runway (vídeo)
- n8n, Make, Zapier (automatizaciones)

Si no queda claro, pregunta antes de continuar.

### 2. Extrae los componentes del prompt

Del input del usuario, identifica y extrae:

1. Objetivo real: qué quiere conseguir
2. Contexto relevante: rol, situación, datos de partida
3. Tarea concreta: acción específica que debe ejecutar la IA
4. Especificaciones: detalles técnicos, restricciones, tono, estilo
5. Formato de salida: cómo debe presentarse el resultado
6. Criterios de calidad: qué hace que el resultado sea bueno
7. Cosas a evitar: errores frecuentes, restricciones, exclusiones
8. Verificación final: si aplica, instrucción de autocomprobación

Si falta información imprescindible, pregunta. Si no es crítica, asume lo razonable.

### 3. Construye el prompt final

Estructura el prompt con estas secciones (adapta según la herramienta y complejidad):

```
[CONTEXTO Y ROL]
Quién es la IA, desde qué perspectiva actúa y en qué situación.

[TAREA CONCRETA]
Qué debe hacer exactamente.

[ESPECIFICACIONES]
Detalles importantes: tono, estilo, longitud, idioma, público objetivo.

[CRITERIOS DE CALIDAD]
Cómo saber si el resultado es bueno.

[FORMATO DE RESPUESTA]
Cómo debe estructurarse la salida.

[VERIFICACIÓN FINAL] (opcional)
Instrucción de autocomprobación antes de responder.
```

## Adaptación por herramienta

### Claude / ChatGPT / Gemini

- Prioriza contexto claro, pasos definidos y formato de salida explícito

### Claude Code / herramientas de programación

- Incluye objetivo del código, lenguaje/framework, estructura del proyecto
- Define criterios de validación y casos límite

### Midjourney / Flux / Stable Diffusion

- Estructura: sujeto -> composición -> estilo visual -> iluminación -> encuadre -> aspecto
- Añade negative prompts si aplica

### Sora / Kling / Runway

- Incluye escena de apertura, movimiento de cámara, acción principal, progresión visual

### n8n / Make / Zapier

- Incluye trigger, inputs, pasos del flujo, herramientas conectadas, output esperado
- Añade manejo de errores

## Formato de respuesta

**Prompt optimizado:** [Prompt final limpio, listo para copiar y pegar]

**Cambios principales realizados:** [Lista breve de 3 a 5 mejoras aplicadas]

**Dudas opcionales:** _(solo si hay información que mejoraría el resultado)_ [Preguntas concretas,
máximo 2-3]

## Reglas

- No inventes detalles críticos que el usuario no ha dado
- No cambies el objetivo original del usuario
- No hagas el prompt más largo de lo necesario
- No des varias versiones salvo que el usuario lo pida explícitamente
- El resultado debe ser inmediatamente usable
