# Documento Técnico: Archictectura de Workspace Foundation

## Estructura de Directorios
- `/scripts`: Motores de automatización en PowerShell Core (agnóstico de plataforma).
- `/tools`: Repositorios de herramientas core (Engram, Gentleman-Skills, GGA).
- `/config`: Configuración centralizada en JSON con soporte para resolución de variables dinámicas.
- `/.engram-data`: Persistencia de contexto para modelos de lenguaje (aislado del código fuente).

## Componentes Críticos

### 1. El Orquestador de Arranque (`bootstrap.ps1`)
Utiliza una lógica de verificación de dependencias (Git, Go, Engram). Si una herramienta falta, el script se encarga de su despliegue, asegurando que el entorno sea determinista.

### 2. Protocolo de Validación (`validate-project.ps1`)
Implementa una jerarquía de validación:
1. **Seguridad:** Invoca a Gentleman Guardian Angel (GGA).
2. **Integridad IA:** Verifica la carga de Gentleman-Skills.
3. **Documentación:** Dispara `generate-session-review.ps1`.

### 3. Persistencia de Sesión y Memoria de IA
El sistema genera archivos Markdown en `docs/code-reviews/`. Estos archivos no son solo para humanos; sirven como "memoria a largo plazo" para que Gemini/Claude entiendan la evolución del proyecto en futuras sesiones.

### 4. Modelo de Configuración Agnostico
El archivo `workspace.config.json` utiliza *placeholders* (ej: `{workspaceRoot}`) que se resuelven en tiempo de ejecución, permitiendo que el proyecto se mueva entre diferentes rutas de disco o servidores sin romperse.

## Flujo de Publicación (Finalize)
El script `finalize-session.ps1` garantiza la atomicidad de la publicación:
```powershell
Validation -> Tagging -> Commit -> Push (Auto-Upstream) -> Pull Request (gh)
```
Esto crea un historial de Git inmaculado y listo para despliegues basados en Tags.

## Requisitos de Sistema
- PowerShell Core 7+
- Git 2.30+
- Go 1.20+ (para herramientas backend)