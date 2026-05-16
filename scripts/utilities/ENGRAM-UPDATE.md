# Engram Update Procedure - Gentle-Vanguard

## Problema Identificado

Al actualizar engram mientras un cliente MCP (OpenCode) esta corriendo, el binario en disco se
actualiza pero el subproceso MCP en memoria sigue siendo el viejo. Esto causa:

- Archivo bloqueado (no se puede sobrescribir)
- Version desactualizada aunque el archivo en disco sea nuevo
- Comportamiento inconsistente

## Procedimiento Oficial (segun README.md de Engram)

### Paso 1: Detener el cliente MCP

Antes de actualizar, cerrar completamente OpenCode (o el cliente que use engram).

### Paso 2: Actualizar el binario

**Opcion A (recomendada - go install):**

```powershell
go install github.com/gentle-vanguard/engram/cmd/engram@latest
```

El binario va a `%USERPROFILE%\go\bin\engram.exe`

**Opcion B (copiar desde herramientas del workspace):**

```powershell
Copy-Item ".\gentle-vanguard\\tools\engram.exe" "$HOME\bin\engram.exe"
```

**Opcion C (descargar release):**

- Ir a: https://github.com/gentle-vanguard/engram/releases
- Descargar `engram_<version>_windows_amd64.zip`
- Extraer `engram.exe` a `$HOME\bin\`

### Paso 3: Reconfigurar el agente

```powershell
engram setup opencode
```

Esto actualiza:

- `~/.config/opencode/plugins/engram.ts` (plugin de sesion)
- `opencode.json` (servidor MCP)
- `tui.json` o `tui.jsonc` (status de sub-agentes)

### Paso 4: Reiniciar el cliente MCP

Abrir OpenCode (u otro cliente). Automaticamente cargara el nuevo binario engram.exe.

### Paso 5: Verificar

```powershell
engram --version
# Debe mostrar la version nueva (ej: 1.15.1)
```

## Script de Actualizacion Automatica

Ver: `scripts/utilities/update-engram.ps1`

## Notas Importantes

1. **No sirve solo con copiar el .exe** - el proceso en memoria debe reiniciarse
2. **Engram en PATH** (`$HOME\bin\`) vs **Engram en scripts/utilities/**
   (`gentle-vanguard/scripts/utilities/`)
   - El de scripts/utilities/ se usa para actualizaciones internas
   - El de PATH es el que usa el sistema y los agentes MCP
3. **OpenCode en Windows** usa `~/.config/opencode/` (no `%APPDATA%\opencode\`)
4. **Datos** se guardan en `%USERPROFILE%\.engram\engram.db`

## Referencias

- https://github.com/gentle-vanguard/engram/blob/main/README.md
- https://github.com/gentle-vanguard/engram/blob/main/docs/INSTALLATION.md
- https://github.com/gentle-vanguard/engram/blob/main/docs/AGENT-SETUP.md

