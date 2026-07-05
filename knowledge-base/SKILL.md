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
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action init

# Ver estadísticas
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action stats

# Validar estructura
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action validate

# Listar todas las notas
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action list

# Buscar notas
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action search -Query "keyword"

# Crear nota de proyecto
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action create-note -NoteType project -Title "Mi Proyecto"

# Crear nota de sesión
pwsh scripts\utilities\knowledge-base\knowledge-base-manager.ps1 -Action create-note -NoteType session -Title "session-2026-07-03"

# Sync completo (Engram + documentos + backup)
pwsh scripts\utilities\knowledge-base\knowledge-base-sync.ps1 -Mode full

# Sync solo sesiones
pwsh scripts\utilities\knowledge-base\knowledge-base-sync.ps1 -Mode sessions

# Sync solo documentos
pwsh scripts\utilities\knowledge-base\knowledge-base-sync.ps1 -Mode documents
```

### Automation

El vault se sincroniza automáticamente al inicio de sesión via
`config/session-autostart.config.json`:

```json
{
  "id": "knowledge-base-sync",
  "enabled": true,
  "lazy": true,
  "script": "scripts/utilities/knowledge-base/knowledge-base-sync.ps1",
  "args": "-Mode full"
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
- `docs/knowledge-base/USAGE.md` - Guía de uso detallada
- `config/knowledge-base-config.json` - Configuración
- `scripts/utilities/knowledge-base/knowledge-base-manager.ps1` - Manager
- `scripts/utilities/knowledge-base/knowledge-base-sync.ps1` - Sync
