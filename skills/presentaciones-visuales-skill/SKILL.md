---
name: presentaciones-visuales-skill
description: >
  Creates self-contained HTML presentations with modern design and clear narrative from any content.
  Converts ideas, documents, transcripts, or PowerPoint content into browser-ready slides. Trigger:
  "crea una presentación", "convierte esto en slides", "deck", "diapositivas", "presentación
  visual", "create presentation", "make slides", "convert to slides", "presentation HTML", "create a
  deck", "slide deck"
license: Apache-2.0
metadata:
  author: workspace-local
  version: '1.0'
---

# Presentaciones Visuales

Crea presentaciones HTML autocontenidas con diseño profesional, narrativa clara y calidad para
reuniones, clases, vídeos o propuestas.

## Proceso paso a paso

### 1. Analiza el input

Extrae: tema/objetivo, público, número de slides, tono
(formal/divulgativo/comercial/educativo/técnico), uso previsto (reunión/vídeo/formación/pitch)

Si falta información crítica (público, objetivo, duración), pregunta antes de generar.

### 2. Define la estructura narrativa

| Sección           | Propósito                         |
| ----------------- | --------------------------------- |
| Portada           | Captar atención, enmarcar el tema |
| Contexto/problema | Por qué importa                   |
| Desarrollo        | Contenido principal, ideas clave  |
| Ejemplos/datos    | Prueba, evidencia                 |
| Cierre            | Resumen o llamada a la acción     |

### 3. Elige un estilo visual

| Estilo                  | Cuándo usarlo                      |
| ----------------------- | ---------------------------------- |
| Profesional minimalista | Propuestas, reuniones corporativas |
| Tecnológico/oscuro      | IA, producto digital, startups     |
| Educativo/claro         | Formaciones, clases                |
| Premium/editorial       | Marca personal, lujo               |
| Creativo                | Agencias, diseño                   |
| Corporativo             | Empresas grandes, informes         |

### 4. Reglas de diseño

**Estructura visual:** una idea por slide, jerarquía clara, márgenes amplios, tipografía legible

**Variedad de layouts:** no repitas el mismo layout - usa centrada, dos columnas, tarjetas, lista
con iconos, timeline, comparativa

**Prohibido:** párrafos largos, más de 5-6 puntos, colores sin coherencia, fondos con imágenes
externas

### 5. Genera el HTML

Único archivo HTML autocontenido: CSS incluido en `<style>`, sin dependencias externas, navegación
por teclado (← →), responsive.

```html
<!DOCTYPE html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Presentación</title>
    <style>
      :root {
        --primary: #...;
        --accent: #...;
        --bg: #...;
        --text: #...;
      }
      /* Reset, slides, navegación, animaciones */
    </style>
  </head>
  <body>
    <!-- slides como divs o sections -->
    <script>
      // navegación
    </script>
  </body>
</html>
```

### 6. Formatos especiales

**Para vídeo:** frases muy cortas, elementos grandes, fondo sólido, sin listas largas

**Para reunión/formación:** claridad sobre espectacularidad, más contenido por slide, numeración
visible

## Formato de salida

**Resumen de enfoque:**

> [objetivo, público asumido, estilo elegido]

**Estructura de slides:**

> [títulos numerados]

**Presentación HTML:**

> [código completo listo para abrir en navegador]
