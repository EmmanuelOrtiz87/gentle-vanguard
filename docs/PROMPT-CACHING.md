# Prompt Caching Configuration

## Overview
Configuracin de prompt caching para optimizar costos de tokens en opencode.

## Requisitos Implementados

### 1. Estructura de Prompt (Orden Obligatorio)
1. **Herramientas (tools)** - Primeras en el prompt
2. **System Prompt** - Segundo en el prompt  
3. **Mensajes (messages)** - ltimos en el prompt

### 2. Configuracin de Cache
- `cache_control: { type: "ephemeral" }` en bloques de contenido
- Tokens mnimos: 2000
- Tokens mximos: 4500

### 3. Restricciones
- **No imgenes**: No se aceptan imgenes para gestin de cache
- **No contenido dinmico**: Nada de contenido dinmico antes de guardar en cache
- **No cambios de parmetros de razonamiento**: 
  - No cambiar nivel de "thinking" entre requests
  - Esto invalida la cache

### 4. Configuracin en opencode.json

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "openrouter": {
      "options": {
        "setCacheKey": true,
        "timeout": 600000
      }
    },
    "anthropic": {
      "options": {
        "setCacheKey": true,
        "timeout": 600000
      }
    }
  },
  "agent": {
    "default": {
      "model": "anthropic/claude-sonnet-4-5",
      "options": {
        "minTokens": 2000,
        "maxTokens": 4500
      }
    }
  }
}
```

## Uso de cache_control

Para proveedores que soportan prompt caching (Anthropic, OpenRouter), usar:

```typescript
// En mensajes o system prompts
{
  role: 'system',
  content: [
    {
      type: 'text',
      text: 'Static content here...',
      providerOptions: {
        openrouter: {
          cacheControl: { type: 'ephemeral' }
        },
        anthropic: {
          cacheControl: { type: 'ephemeral' }
        }
      }
    }
  ]
}
```

## Verificacin

Para verificar que el cache est funcionando:
1. Revisar logs de proveedor (ej. OpenRouter logs)
2. Confirmar que hay cache hits en requests consecutivos
3. Verificar que no hay cambios en parmetros entre requests

## Notas Importantes

- Anthropic requiere >1024 tokens para activar caching
- OpenRouter usa TTL de 5 minutos por defecto
- Cambios en herramientas (tools) invalidan el cache de system prompt
- Mantener contenido estable antes de los breakpoints de cache
