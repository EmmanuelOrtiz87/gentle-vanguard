# Prompt Caching Configuration

## Overview
Configuración de prompt caching para optimizar costos de tokens en opencode.

## Requisitos Implementados

### 1. Estructura de Prompt (Orden Obligatorio)
1. **Herramientas (tools)** - Primeras en el prompt
2. **System Prompt** - Segundo en el prompt  
3. **Mensajes (messages)** - Últimos en el prompt

### 2. Configuración de Cache
- `cache_control: { type: "ephemeral" }` en bloques de contenido
- Tokens mínimos: 2000
- Tokens máximos: 4500

### 3. Restricciones
- **No imágenes**: No se aceptan imágenes para gestión de cache
- **No contenido dinámico**: Nada de contenido dinámico antes de guardar en cache
- **No cambios de parámetros de razonamiento**: 
  - No cambiar nivel de "thinking" entre requests
  - Esto invalida la cache

### 4. Configuración en opencode.json

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

## Verificación

Para verificar que el cache está funcionando:
1. Revisar logs de proveedor (ej. OpenRouter logs)
2. Confirmar que hay cache hits en requests consecutivos
3. Verificar que no hay cambios en parámetros entre requests

## Notas Importantes

- Anthropic requiere >1024 tokens para activar caching
- OpenRouter usa TTL de 5 minutos por defecto
- Cambios en herramientas (tools) invalidan el cache de system prompt
- Mantener contenido estable antes de los breakpoints de cache
