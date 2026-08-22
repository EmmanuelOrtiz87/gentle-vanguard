# Context Management Strategy — Respuesta al Usuario

## Resumen de Opciones Evaluadas

He investigado 5 caminos diferentes para resolver el problema de millones de tokens. Aquí está el
análisis completo:

---

## 🔍 **Opción 1: Plugin para OpenCode**

**Estado**: ❌ **NO RESUELVE EL PROBLEMA**

Investigué la API de plugins de opencode (`message.updated`, `session.idle`,
`experimental.chat.system.transform`). El hook más poderoso (`experimental.chat.system.transform`)
solo permite **modificar el system prompt**, no el array de mensajes del historial.

**Conclusión**: Los plugins de opencode NO exponen acceso para truncar/modificar mensajes previos de
la conversación.

---

## 🔍 **Opción 2: Middleware Interceptor**

**Estado**: ❌ **NO VIABLE**

Node.js/JavaScript no permite interceptar requests HTTPS salientes sin:

- Proxy HTTP externo (complejo)
- Monkey-patching de librerías internas (fragil)
- Modificar código de opencode (vuelve a Opción 3)

**Conclusión**: No podemos interceptar las llamadas al LLM desde fuera.

---

## 🔍 **Opción 3: Fork de OpenCode**

**Estado**: ✅ **POSIBLE PERO COMPLEJO**

OpenCode es open source (github.com/opencode-ai/opencode).

### Lo que haría falta modificar:

1. Encontrar el archivo que construye el payload de mensajes (probablemente en `src/core/llm/`)
2. Agregar configuración `maxContextMessages: 10` en su config
3. Implementar sliding window antes de enviar al provider
4. Manejar resumen automático de mensajes antiguos

### Esfuerzo estimado:

- **2-3 días** para entender la arquitectura y hacer el fork
- **1-2 semanas** para testing y estabilización
- **Mantenimiento continuo**: sync con upstream cada release

### Consideraciones:

- OpenCode usa Bun (runtime diferente a Node)
- Arquitectura de plugins propia
- Tests con Playwright
- CI/CD propio

**Veredicto**: Es la solución "real", pero requiere compromiso de mantenimiento.

---

## 🔍 **Opción 4: Plugin context-mode existente**

**Estado**: ❌ **NO APLICABLE**

El plugin `context-mode` de npm es para otra arquitectura (MCP + hooks genéricos), no
específicamente para opencode. Requiere investigación adicional.

---

## 🔍 **Opción 5: Optimizaciones desde NUESTRO LADO** ✅ IMPLEMENTADO

**Estado**: ✅ **YA FUNCIONANDO**

Implementado:

1. `src/context-truncator.ts` - Monitor de tamaño de contexto
2. `config/context-truncator.json` - Configuración de sliding window
3. `docs/reference/CONTEXT-OPTIMIZATION-GUIDE.md` - Documentación completa
4. `token-session-banner.ts` - Ahora muestra advertencias visibles

**Lo que SÍ funciona**:

- Prompt compression por mensaje individual (40-60% ahorro)
- Output compression (50-70% ahorro)
- Chat level enforcement (límites de respuesta)
- Checkpoints automáticos
- Monitoreo y alertas

---

## 💡 **Recomendación Final**

Dado el análisis, propongo **un enfoque híbrido**:

### **FASE 1 (Inmediato - esta semana)**: Mitigaciones desde nuestro lado

1. ✅ Implementado: context-truncator + guía + alertas
2. Implementar: Checkpoint automático cada 10 mensajes o 10k tokens
3. Crear: Comando `/reset` o botón para forzar nueva sesión

### **FASE 2 (Corto plazo - 1-2 semanas)**: Fork de OpenCode

1. Fork del repo opencode-ai/opencode
2. Identificar dónde se ensambla el payload de mensajes
3. Implementar `maxContextMessages: 10` con sliding window
4. PR al upstream o mantener fork propio

### **FASE 3 (Mediano plazo)**: Contribución upstream

1. Contactar equipo de opencode para proponer feature nativa
2. Presentar nuestra implementación como referencia
3. Colaborar en diseño de API para context management

---

## 📋 **Comparativa Rápida**

| Solución              | Esfuerzo | Esfuerzo Mant. | Impacto | Viabilidad     |
| --------------------- | -------- | -------------- | ------- | -------------- |
| Plugin API            | 1 día    | Bajo           | 0%      | ❌ No soporta  |
| Middleware            | 2-3 días | Medio          | 10%     | ❌ No viable   |
| Fork opencode         | 1-2 sem  | Alto           | 90%     | ✅ Posible     |
| context-mode          | 2-3 días | Medio          | ?       | ⚠️ Desconocido |
| Nuestro lado (actual) | 1 día    | Bajo           | 30%     | ✅ Funciona    |

---

## 🎯 **Decisión Requerida**

**¿Quieres que proceda con el fork de OpenCode?**

Si sí:

1. Haré fork del repo
2. Buscaré dónde se construyen los mensajes
3. Implementaré sliding window básico
4. Crearé PR o mantendré versión propia

Costo: ~1-2 semanas de trabajo + mantenimiento continuo.

Beneficio: Solución "real" al problema de millones de tokens.
