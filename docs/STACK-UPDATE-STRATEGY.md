# Gentle-Vanguard Stack Update & Synchronization Strategy

## Visión General

Gentle-Vanguard soporta dos escenarios de actualización:

### ✅ Escenario 1: Gentle-Vanguard NO está instalado

**Método**: Ejecutar el instalador

```bash
.\Gentle-Vanguard-Setup.exe  # o doble-clic
```

- Instala core con scripts encriptados
- Descrypta automáticamente en %APPDATA%\Gentle-Vanguard en primer uso
- Usuario obtiene acceso inmediato a `gv` CLI

### ✅ Escenario 2: Gentle-Vanguard YA está instalado

**Método**: Usar comandos de CLI o sincronización

## Estrategia de Actualización para Instalaciones Existentes

### Opción A: Actualización Parcial (Recomendado para cambios menores)

**Para actualizar solo skills y herramientas:**

```powershell
# CLI directo
gv update                    # Sincroniza skills
gv update-all               # Sincroniza skills + herramientas (engram, opencode)
gv check                    # Verifica actualizaciones disponibles
```

**Desde repositorio clonado:**

```powershell
cd C:\Workspace_local\gentle-vanguard
scripts\gentle-vanguard\sync-skills.ps1 -Force
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
# En desarrollo (gentle-vanguard)
cd C:\Workspace_local\gentle-vanguard

# 1. Encriptar scripts actualizados
$env:GENTLE_VANGUARD_BASE_DIR='c:\Workspace_local\gentle-vanguard'
pwsh -NoProfile -ExecutionPolicy Bypass -File "build\protect-gentle-vanguard.ps1"

# 2. Compilar nuevo instalador
pwsh -NoProfile -ExecutionPolicy Bypass -File "build\create-installer.ps1" -SkipEncrypt

# Output: dist\Gentle-Vanguard-Setup.exe (versión actualizada)
```

**Distribución:**

- Publicar nuevo .exe en GitHub Releases
- Usuarios instalan sobre versión existente (NSIS permite upgrade)
- Launcher automáticamente descrypta scripts nuevos

### Opción C: Sincronización SIN Reinstalar (Desarrollo/Testing)

**Para testers y developers:** Actualizar installation sin pasar por instalador

```powershell
cd C:\Workspace_local\gentle-vanguard

# Primero encriptar
build\protect-gentle-vanguard.ps1

# Luego sincronizar con installation existente
scripts\gentle-vanguard\sync-stack.ps1 -Source local -Check    # Ver cambios
scripts\gentle-vanguard\sync-stack.ps1 -Source local -Force    # Aplicar cambios
```

**Qué hace sync-stack.ps1:**

- Detecta installation de Gentle-Vanguard
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
¿Hay cambios en los scripts core (comprehensive-validation, gv.ps1)?
├─ SÍ → Generar nuevo .exe (Opción B)
│       └─ Distribución: Gentle-Vanguard-Setup.exe en releases
│
└─ NO ¿Hay cambios en skills o herramientas?
    ├─ SÍ → gv update (Opción A)
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
- Se almacena en `gentle-vanguard.version` en %APPDATA%

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

1. Descargar `Gentle-Vanguard-Setup.exe` desde releases
2. Ejecutar instalador
3. Seguir prompts (instala en `Program Files\Gentle-Vanguard` por defecto)
4. Reiniciar terminal o ejecutar `refreshenv`
5. Verificar: `gv --help` o `gv validate`

### Actualizar Skills (Versiones Menores)

```powershell
gv update
```

O desde repo:

```powershell
git pull origin main
gv update
```

### Actualizar Gentle-Vanguard Core (Versiones Mayores)

1. Descargar nuevo `Gentle-Vanguard-Setup.exe`
2. Ejecutar (automáticamente upgrade sobre versión anterior)
3. Reiniciar terminal
4. Verificar: `gv validate`

## Recuperación / Rollback

**Si algo falla después de sync-stack.ps1:**

```powershell
# Listar backups disponibles
ls "C:\Program Files\Gentle-Vanguard\backup-*"

# Restaurar desde backup
copy "C:\Program Files\Gentle-Vanguard\backup-YYYYMMDD-HHMMSS\protected\*" `
     "C:\Program Files\Gentle-Vanguard\protected\" -Recurse -Force
```

**Si Gentle-Vanguard no funciona después de instalador:**

1. Panel de Control → Desinstalar programas
2. Buscar "Gentle-Vanguard" y desinstalar
3. Descargar .exe más reciente
4. Reinstalar

## Integración Futura: Auto-Update

**Roadmap:**

- [ ] Gentle-Vanguard-Launcher.exe chequea versión remota al inicio
- [ ] Notificación si nueva versión disponible
- [ ] Opción auto-download de nuevo .exe
- [ ] Instalación silenciosa con `Gentle-Vanguard-Setup.exe /S`

## Referencias

| Script                      | Propósito                          | Ubicación                |
| --------------------------- | ---------------------------------- | ------------------------ |
| sync-stack.ps1              | Sincronizar installation existente | scripts/gentle-vanguard/ |
| protect-gentle-vanguard.ps1 | Encriptar scripts                  | build/                   |
| create-installer.ps1        | Compilar .exe                      | build/                   |
| sync-skills.ps1             | Sincronizar skills                 | scripts/gentle-vanguard/ |
| gv.ps1                      | CLI principal                      | bin/                     |

## Ejemplos de Uso

### Dev local: Aplicar cambios y testear

```powershell
cd C:\Workspace_local\gentle-vanguard

# 1. Hacer cambios en scripts
# ... editar comprehensive-validation.ps1

# 2. Encriptar cambios
build\protect-gentle-vanguard.ps1

# 3. Sincronizar con instalación local (si existe)
scripts\gentle-vanguard\sync-stack.ps1 -Source local -Check
scripts\gentle-vanguard\sync-stack.ps1 -Source local -Force

# 4. Testear
gv validate
```

### Buildear para distribución

```powershell
cd C:\Workspace_local\gentle-vanguard

# 1. Asegurar encrypt
build\protect-gentle-vanguard.ps1

# 2. Buildear .exe
build\create-installer.ps1 -SkipEncrypt

# 3. Publicar
# - Subir dist\Gentle-Vanguard-Setup.exe a GitHub releases
# - Actualizar CHANGELOG.md con version
# - Git tag: v1.0.0
```

### Usuarios finales: Actualizar instalación existente

```powershell
# Opción 1: Solo skills
gv update

# Opción 2: Verificar disponible
gv check

# Opción 3: Core update (descargar nuevo .exe primero)
# ... descargar Gentle-Vanguard-Setup.exe
.\Gentle-Vanguard-Setup.exe
```
