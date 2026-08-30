/* Gentle-Vanguard Academy — referencia: knowledge base y grafos. */
window.GV_CONTENT = window.GV_CONTENT || {};
window.GV_CONTENT['knowledge-base'] = {
  lessons: [
    {
      id: 'roles-y-sincronizacion',
      title: 'Obsidian, Engram y Nexus: roles y sincronización',
      minutes: 12,
      type: 'referencia',
      md: `## Una autoridad por pregunta

| Sistema | Rol | Ubicación | Autoridad |
| --- | --- | --- | --- |
| Obsidian / vault | conocimiento curado y portable en Markdown | \`knowledge-base/\` | notas y estructura |
| Engram | memoria persistente de sesiones, decisiones y aprendizajes | \`.engram-data/\` + MCP | observations y veredictos |
| Nexus | datos operativos agregados | \`.runtime/gentle-vanguard.db\` | métricas, tokens y estado operacional |
| CodeGraph | índice incremental para tooling | \`.codegraph/\` | consultas MCP del código |
| Graphify | grafo AST determinista para análisis | \`graphify-out/\` | query, report y wiki |

### Flujo real

\`\`\`text
Sesión → Engram (memoria) ──export──→ 00-inbox/ (Obsidian)
   │                                      │
   ├──────────────→ Nexus (operación)    └──import──→ Engram
   ├──────────────→ CodeGraph (.codegraph/)
   └──────────────→ Graphify (graphify-out/)
\`\`\`

La sincronización del vault es aditiva: no borra notas existentes y deduplica importaciones por hash. Obsidian no reemplaza a Engram, y Nexus no es un almacén de decisiones.

## Comandos

\`\`\`bash
npm run kb:sync -- --mode full --dry-run  # previsualizar
npm run kb:sync -- --mode full            # export + import
npm run kb:sync -- --mode session-summary # resumen explícito
npm run db:health                          # Nexus
npm run session:autostart:detached         # pipeline de sesión
\`\`\`

La configuración está en \`config/knowledge-base-config.json\`: vault, carpetas, proyecto Engram, modos, retención y backup.

## Límites

- El vault local no es un servicio multiusuario ni un gestor de secretos.
- Un \`--dry-run\` evita escrituras, pero no convierte una fuente ausente en válida.
- La UI de Academy consume contenido publicado; no escribe en Obsidian, Engram ni Nexus.
- Las notas importadas necesitan revisión humana antes de convertirse en decisión canónica.`,
    },
    {
      id: 'codegraph-y-graphify-en-practica',
      title: 'CodeGraph y Graphify: cuándo consultar cada uno',
      minutes: 10,
      type: 'referencia',
      md: `## Dos índices, dos trabajos

**CodeGraph** mantiene el índice incremental expuesto por MCP para contexto, símbolos, callers, callees e impacto. **Graphify** construye un grafo AST local y determinista para análisis y consultas amplias. No se fusionan.

\`\`\`bash
npm run graphify -- build
npm run graphify -- query "dónde se ingieren los tokens"
npm run graphify -- explain <node_id>
npm run graphify -- update .
npm run graphify -- status
\`\`\`

Regla práctica: usá \`query\` para encontrar el nodo y luego \`explain\`; \`path\` y \`affected\` tienen alcance limitado a edges \`contains\`/\`calls\`. Tras editar código, actualizá el grafo para evitar resultados viejos.

### Sincronización y límites

Los hooks actualizan CodeGraph después de ediciones y Graphify se actualiza con \`update .\`. El análisis AST no entiende toda la semántica de negocio; el labeling opcional puede consumir la cuota gratuita de Gemini (20 requests/día). Visualizaciones grandes requieren limitar nodos. No instalar el paquete npm \`graphify@1.0.0\`: el comando soportado es el CLI local del repositorio.

## Puntos clave

- Vault = conocimiento curado; Engram = memoria de sesión; Nexus = operación.
- CodeGraph sirve tooling incremental; Graphify sirve análisis AST determinista.
- La sincronización conserva datos y deja límites explícitos; no es replicación transaccional.`,
    },
  ],
};
