# Knowledge Base Skill

**Trigger:** "knowledge base", "kb", "vault", "obsidian", "notas", "documentación", "archivar",
"buscar nota", "crear nota"

**Agent:** SDD (Software Design)

## Overview

Knowledge Base es el sistema centralizado de gestión de conocimiento de Gentle-Vanguard, basado en
Obsidian-compatible vault con sincronización automática de Engram y documentos del proyecto.

## Capabilities

- **Gestión de notas**: Crear, buscar, listar notas en el vault
- **Sincronización**: Auto-sync con Engram (memoria de sesión) y documentos
- **Templates**: Project, Session, Skill, Decision (ADR)
- **Búsqueda**: Búsqueda por keywords en todo el vault
- **Estadísticas**: Conteo de notas, tamaño, distribución por folders
- **Validación**: Verificar integridad de la estructura del vault

## Architecture

```
knowledge-base/
├── 00-inbox/           # Notas sin clasificar
├── 01-projects/        # Proyectos activos
├── 02-architecture/    # ADRs y decisiones
├── 03-skills/          # Documentación de skills
├── 04-sessions/        # Resúmenes de sesión
├── 05-research/        # Notas de investigación
├── 06-templates/       # Templates
└── 07-archive/         # Contenido archivado
```

## Integration Points

- **Engram**: Memoria de sesión → vault (largo plazo)
- **Session Pipeline**: Auto-sync al inicio de sesión
- **Document Analysis**: Documentos procesados → vault
- **ML Embeddings**: Búsqueda semántica via ml-router

## Usage

### CLI Commands

```powershell
# Inicializar vault (solo si no existe)
pnpm kb:manager -- --action init

# Ver estadísticas
pnpm kb:manager -- --action stats

# Validar estructura
pnpm kb:manager -- --action validate

# Listar todas las notas
pnpm kb:manager -- --action list

# Buscar notas
pnpm kb:manager -- --action search --query "keyword"

# Crear nota de proyecto
pnpm kb:manager -- --action create-note --note-type project --title "Mi Proyecto"

# Crear nota de sesión
pnpm kb:manager -- --action create-note --note-type session --title "session-2026-07-03"

# Sync completo (Engram + documentos + backup)
pnpm kb:sync -- --mode full

# Sync solo sesiones
pnpm kb:sync -- --mode session-summary

# Sync solo documentos
pnpm kb:sync -- --mode import
```

### Automation

El vault se sincroniza automáticamente al inicio de sesión via
`config/session-autostart.config.json`:

```json
{
  "id": "knowledge-base-sync",
  "enabled": true,
  "lazy": true,
    "script": "src/knowledge/knowledge-base-sync.ts",
    "args": "--mode full"
}
```

## Best Practices

1. **Revisar inbox diario**: Mover notas de `00-inbox/` a folders apropiados
2. **Usar templates**: Siempre usar templates para notas nuevas
3. **Tagging**: Incluir tags relevantes en frontmatter
4. **Cross-references**: Usar `[[nota]]` para linking entre notas
5. **Sync regular**: El sync corre automáticamente, pero se puede ejecutar manualmente

## Related Files

- `docs/knowledge-base/ARCHITECTURE.md` - Arquitectura completa
- `docs/knowledge-base/README.md` - Guía de uso detallada
- `config/knowledge-base-config.json` - Configuración
- `src/knowledge/knowledge-base-manager.ts` - Manager
- `src/knowledge/knowledge-base-sync.ts` - Sync
