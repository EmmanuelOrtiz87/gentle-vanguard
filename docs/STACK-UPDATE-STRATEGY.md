# Foundation Stack Update & Synchronization Strategy

## Visión General

Foundation soporta dos escenarios de actualización:

### ✅ Escenario 1: Foundation NO está instalado
**Método**: Ejecutar el instalador
```bash
.\Foundation-Setup.exe  # o doble-clic
```
- Instala core con scripts encriptados
- Descrypta automáticamente en %APPDATA%\Foundation en primer uso
- Usuario obtiene acceso inmediato a `gf` CLI

### ✅ Escenario 2: Foundation YA está instalado
**Método**: Usar comandos de CLI o sincronización

## Estrategia de Actualización para Instalaciones Existentes

### Opción A: Actualización Parcial (Recomendado para cambios menores)

**Para actualizar solo skills y herramientas:**
```powershell
# CLI directo
gf update                    # Sincroniza skills
gf update-all               # Sincroniza skills + herramientas (engram, opencode)
gf check                    # Verifica actualizaciones disponibles
```

**Desde repositorio clonado:**
```powershell
cd C:\Workspace_local\foundation
scripts\foundation\sync-skills.ps1 -Force
```

**Qué se actualiza:**
- Skills (en `~/.gentleman/skills/`)
- Herramientas externas (engram, opencode)
- Documentación de skills

**Qué NO se actualiza:**
- Core scripts encriptados
- Launcher ejecutable
- Integridad de validación

### Opción B: Actualización del Core (Para cambios importantes)

**Cuando**: Se han realizado cambios en:
- comprehensive-validation.ps1 (como nuestro hardening)
- cross-platform-tests.yml (shellcheck fixes)
- gitleaks allowlist
- Launcher o decryption pipeline

**Método**: Generar nuevo .exe y reinstalar

```powershell
# En desarrollo (foundation)
cd C:\Workspace_local\foundation

# 1. Encriptar scripts actualizados
$env:FOUNDATION_BASE_DIR='c:\Workspace_local\foundation'
pwsh -NoProfile -ExecutionPolicy Bypass -File "build\protect-foundation.ps1"

# 2. Compilar nuevo instalador
pwsh -NoProfile -ExecutionPolicy Bypass -File "build\create-installer.ps1" -SkipEncrypt

# Output: dist\Foundation-Setup.exe (versión actualizada)
```

**Distribución:**
- Publicar nuevo .exe en GitHub Releases
- Usuarios instalan sobre versión existente (NSIS permite upgrade)
- Launcher automáticamente descrypta scripts nuevos

### Opción C: Sincronización SIN Reinstalar (Desarrollo/Testing)

**Para testers y developers:** Actualizar installation sin pasar por instalador

```powershell
cd C:\Workspace_local\foundation

# Primero encriptar
build\protect-foundation.ps1

# Luego sincronizar con installation existente
scripts\foundation\sync-stack.ps1 -Source local -Check    # Ver cambios
scripts\foundation\sync-stack.ps1 -Source local -Force    # Aplicar cambios
```

**Qué hace sync-stack.ps1:**
- Detecta installation de Foundation
- Crea backup automático con timestamp
- Reemplaza `protected/` y `public/` folders
- Revalida manifest de integridad
- Permite rollback si falla

**Ventajas:**
- No requiere desinstalar
- Respaldo automático para recovery
- Ideal para CI/CD deployments
- No interrumpe PATH ni shortcuts

## Flujo de Decisión: ¿Cuál usar?

```
¿Hay cambios en los scripts core (comprehensive-validation, wf.ps1)?
├─ SÍ → Generar nuevo .exe (Opción B)
│       └─ Distribución: Foundation-Setup.exe en releases
│
└─ NO ¿Hay cambios en skills o herramientas?
    ├─ SÍ → gf update (Opción A)
    │       └─ Instantáneo, sin reinstalar
    │
    └─ NO → Solo documentación
            └─ Sin cambios necesarios
```

## Versionado

**Archivo**: `VERSION` (en repo root)
- Formato: `MAJOR.MINOR.PATCH` (ej: 1.0.0)
- Se empaqueta en cada .exe
- Se valida en integrity-manifest.json
- Se almacena en `foundation.version` en %APPDATA%

**Historial de versiones:**
```
1.0.0     (mayo 2026) - Inicial con hardening completo
          Incluye: comprehensive-validation hardening,
                   cross-platform test fixes,
                   gitleaks allowlist,
                   workflow standardization
```

## Processo paso a paso: Usuarios Finales

### Primera Instalación
1. Descargar `Foundation-Setup.exe` desde releases
2. Ejecutar instalador
3. Seguir prompts (instala en `Program Files\Foundation` por defecto)
4. Reiniciar terminal o ejecutar `refreshenv`
5. Verificar: `gf --help` o `gf validate`

### Actualizar Skills (Versiones Menores)
```powershell
gf update
```
O desde repo:
```powershell
git pull origin main
gf update
```

### Actualizar Foundation Core (Versiones Mayores)
1. Descargar nuevo `Foundation-Setup.exe`
2. Ejecutar (automáticamente upgrade sobre versión anterior)
3. Reiniciar terminal
4. Verificar: `gf validate`

## Recuperación / Rollback

**Si algo falla después de sync-stack.ps1:**
```powershell
# Listar backups disponibles
ls "C:\Program Files\Foundation\backup-*"

# Restaurar desde backup
copy "C:\Program Files\Foundation\backup-YYYYMMDD-HHMMSS\protected\*" `
     "C:\Program Files\Foundation\protected\" -Recurse -Force
```

**Si Foundation no funciona después de instalador:**
1. Panel de Control → Desinstalar programas
2. Buscar "Foundation" y desinstalar
3. Descargar .exe más reciente
4. Reinstalar

## Integración Futura: Auto-Update

**Roadmap:**
- [ ] Foundation-Launcher.exe chequea versión remota al inicio
- [ ] Notificación si nueva versión disponible
- [ ] Opción auto-download de nuevo .exe
- [ ] Instalación silenciosa con `Foundation-Setup.exe /S`

## Referencias

| Script | Propósito | Ubicación |
|--------|-----------|-----------|
| sync-stack.ps1 | Sincronizar installation existente | scripts/foundation/ |
| protect-foundation.ps1 | Encriptar scripts | build/ |
| create-installer.ps1 | Compilar .exe | build/ |
| sync-skills.ps1 | Sincronizar skills | scripts/foundation/ |
| gf.ps1 | CLI principal | bin/ |

## Ejemplos de Uso

### Dev local: Aplicar cambios y testear
```powershell
cd C:\Workspace_local\foundation

# 1. Hacer cambios en scripts
# ... editar comprehensive-validation.ps1

# 2. Encriptar cambios
build\protect-foundation.ps1

# 3. Sincronizar con instalación local (si existe)
scripts\foundation\sync-stack.ps1 -Source local -Check
scripts\foundation\sync-stack.ps1 -Source local -Force

# 4. Testear
gf validate
```

### Buildear para distribución
```powershell
cd C:\Workspace_local\foundation

# 1. Asegurar encrypt
build\protect-foundation.ps1

# 2. Buildear .exe
build\create-installer.ps1 -SkipEncrypt

# 3. Publicar
# - Subir dist\Foundation-Setup.exe a GitHub releases
# - Actualizar CHANGELOG.md con version
# - Git tag: v1.0.0
```

### Usuarios finales: Actualizar instalación existente
```powershell
# Opción 1: Solo skills
gf update

# Opción 2: Verificar disponible
gf check

# Opción 3: Core update (descargar nuevo .exe primero)
# ... descargar Foundation-Setup.exe
.\Foundation-Setup.exe
```
