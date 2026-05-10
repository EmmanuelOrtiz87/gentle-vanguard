# 🏛️ Workspace Foundation

<h3 align="center">El Stack Definitivo para Desarrollo Asistido por IA</h3>

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.8.0-brightgreen?style=for-the-badge" alt="Version">
  <img src="https://img.shields.io/badge/Status-Production%20Ready-success?style=for-the-badge" alt="Status">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/PowerShell-7+-purple?style=for-the-badge" alt="PowerShell">
</p>

<p align="center">
  <b>🌐 100% Local-First • 🔒 Privacidad Total • 🚀 125+ Skills Especializados • ⚡ Cero Dependencias Externas</b>
</p>

---

## 🎯 ¿Qué es Workspace Foundation?

> **Workspace Foundation** no es solo otra herramienta de desarrollo — es un **ecosistema completo**
> que transforma cualquier AI assistant (OpenCode, Claude, Cursor, Windsurf, VS Code) en un
> **orquestador inteligente** capaz de delegar, trackear, auditar y reportar todas tus tareas de
> desarrollo.

### ✨ La Magia en 3 Pasos:

```powershell
# 🚀 PASO 1: Clona y configura (5 minutos)
git clone https://github.com/EmmanuelOrtiz87/foundation-public.git
cd foundation-public
.\scripts\foundation\bootstrap.ps1  # Bootstrap portable y seguro

# 🖥️ Opcional: setup completo de foundation + foundation-public en nueva PC
.\scripts\foundation\setup-multi-machine.ps1

# ⚡ PASO 2: Inicia sesión automática
.\scripts\utilities\session-autostart.cmd

# 🎯 PASO 3: ¡Pide lo que necesites!
"Genera un informe ejecutivo de la sesión de ayer"
"Implementa autenticación JWT con tests"
"Audita la seguridad del proyecto"
```

---

## 🚀 Inicio Rápido

| Acción                 | Comando                                                        | Descripción                   |
| ---------------------- | -------------------------------------------------------------- | ----------------------------- |
| 🎨 **Bootstrap**       | `.\scripts\foundation\bootstrap.ps1`                           | Inicializa el workspace       |
| 🖥️ **Multi-PC setup**  | `.\scripts\foundation\setup-multi-machine.ps1`                 | Replica entorno en otra PC    |
| 🤖 **Runner opcional** | `.\scripts\utilities\DEPLOYMENT\install-github-runner.ps1`     | Instala self-hosted runner    |
| 📊 **Health Check**    | `.\scripts\utilities\wf.ps1 health`                            | Verifica estado del workspace |
| 🔍 **Listar Skills**   | `.\scripts\utilities\wf.ps1 skills`                            | Catálogo de 125+ skills       |
| 📈 **Dashboard**       | `.\scripts\monitoring\executive-dashboard.ps1 -Mode dashboard` | Monitoreo en tiempo real      |
| 🧪 **Validación**      | `.\scripts\utilities\agent-verify.ps1 -Domain all`             | Auditoría completa            |

> 💡 **TIP:** Usa `wf.ps1 help` para ver todos los comandos disponibles. La CLI `wf.ps1` es tu
> interfaz unificada para TODO.

> 🔐 **Runner seguro:** usa `config/github-runner.example.json` como base local y no dirijas
> workflows de `pull_request_target` o forks no confiables a un self-hosted runner en repos
> públicos.

---

## 🌟 Características Principales

### 🧠 Auto-Delegación Inteligente

El orquestador analiza tu solicitud y **enruta automáticamente** al agente especializado:

| Tu Solicitud                   | Agente Asignado | Skill Activado             |
| ------------------------------ | --------------- | -------------------------- |
| _"Implementa login con React"_ | 🛠️ **DEV**      | `react-19-skill`           |
| _"Genera tests E2E"_           | 🧪 **QA**       | `playwright-skill`         |
| _"Audita seguridad"_           | 🔒 **GOV**      | `judgment-day`             |
| _"Despliega a producción"_     | ⚙️ **OPS**      | `docker-devops-skill`      |
| _"Documenta la API"_           | 📚 **DOC**      | `documentation-governance` |

### 📊 Token Budget Guard 💰

Control total sobre el consumo de tokens de IA:

- **Tracking en tiempo real**: Prompt + Completion tokens
- **Presupuestos configurables**: Alertas al 80%, 90%, 95%
- **Reporte automático**: `TOKEN-REPORTING-PROCESS.md`

### 🔗 Git Hooks + Seguridad

- ✅ **Lefthook**: Hooks automáticos de calidad
- ✅ **Trufflehog**: Detección de secretos en tiempo real
- ✅ **Pre-commit**: Validación de JSON, scripts y configuraciones

### 🧩 Plugin Architecture

Sistema extensible con **manifest schema**:

```powershell
# Crear nuevo plugin
.\scripts\utilities\wf.ps1 plugin create --name "mi-plugin"
```

---

## 📚 Catálogo de Skills (125+ Disponibles)

### 🎨 Frontend (15 Skills)

| Skill               | Tecnología                 | Estado    |
| ------------------- | -------------------------- | --------- |
| `react-19-skill`    | React 19 + Compiler        | ✅ Activo |
| `angular-spa-skill` | Angular 19+ Standalone     | ✅ Activo |
| `nextjs-15-skill`   | Next.js 15 App Router      | ✅ Activo |
| `tailwind-4-skill`  | Tailwind CSS 4             | ✅ Activo |
| `zustand-5-skill`   | Zustand 5 State Management | ✅ Activo |

### ⚙️ Backend (12 Skills)

| Skill                       | Tecnología             | Estado    |
| --------------------------- | ---------------------- | --------- |
| `golang-api-skill`          | Go 1.26+ REST APIs     | ✅ Activo |
| `django-drf-skill`          | Django REST Framework  | ✅ Activo |
| `database-relational-skill` | PostgreSQL, MySQL      | ✅ Activo |
| `database-nosql-skill`      | MongoDB, Redis         | ✅ Activo |
| `api-design-skill`          | REST, GraphQL, OpenAPI | ✅ Activo |

### 📱 Mobile (8 Skills)

`flutter-skill`, `android-kotlin-skill`, `ios-swiftui-patterns-skill`, `react-native-skill`,
`mobile-developer`, `mobile-app-debugging`

### 🔒 Security & Governance (18 Skills)

`security-skill`, `security-expert-skill`, `judgment-day`, `architecture-governance`,
`documentation-governance`, `owasp-scan` (CI/CD)

### 🧪 Testing (12 Skills)

`testing-skill`, `playwright-skill`, `pytest-skill`, `testing-strategy-skill`,
`testing-coverage-skill`

> 📖 **Ver catálogo completo**: `docs/reference/SKILL-ORGANIZATION.md` o ejecuta `wf.ps1 skills`

---

## 🏗️ Arquitectura de 5 Capas (100% Agnóstica)

```
┌─────────────────────────────────────────────────────────────┐
│  🎯 Layer 1: AGENTS (BA, DEV, QA, OPS, GOV, DOC, SAD)    │
├─────────────────────────────────────────────────────────────┤
│  ⚙️ Layer 2: COMMANDS (wf.ps1, pre-process-input.ps1)    │
├─────────────────────────────────────────────────────────────┤
│  🔌 Layer 3: MCP SERVERS (Model Context Protocol)         │
├─────────────────────────────────────────────────────────────┤
│  🧩 Layer 4: SKILLS (125+ specialized skills)              │
├─────────────────────────────────────────────────────────────┤
│  🧠 Layer 5: MEMORY (Engram - persistent cross-session)    │
└─────────────────────────────────────────────────────────────┘
```

> 💡 **Agnóstico**: Funciona con OpenCode, Cursor, Codex, Windsurf, VS Code, Cline, Claude. ¡Tu
> eliges!

---

## 🚦 CI/CD Pipeline (14 Workflows Automáticos)

| Workflow                           | Propósito                                        | Frecuencia             | Estado    |
| ---------------------------------- | ------------------------------------------------ | ---------------------- | --------- |
| 🔍 `autonomous-validation.yml`     | Validación completa semanal                      | Lunes 10:00 GMT-3      | ✅ Activo |
| 🧪 `foundation-quality-gate.yml`   | Quality gates en PRs                             | Por PR                 | ✅ Activo |
| 📊 `dashboard-auto-refresh.yml`    | Actualización de dashboards                      | Diario 07:00 UTC       | ✅ Activo |
| 💾 `dependency-backup.yml`         | Backup de dependencias                           | Domingos 13:30 GMT-3   | ✅ Activo |
| 🔒 `owasp-scan.yml`                | Escaneo de seguridad OWASP                       | Domingos 13:30 GMT-3   | ✅ Activo |
| 🔐 `codeql-analysis.yml`           | Análisis CodeQL (security-quality)               | Lunes 10:00            | ✅ Activo |
| 🧪 `test-suite.yml`                | Suite completa de tests (28 tests, 4 categorías) | Por PR/Push            | ✅ Activo |
| 📈 `monthly-management-report.yml` | Reporte gerencial                                | Mensual 06:00 UTC      | ✅ Activo |
| 🚀 `release.yml`                   | Gestión de releases                              | Manual/Tag             | ✅ Activo |
| 🧹 `ps-lint.yml`                   | Linting de PowerShell con PSScriptAnalyzer       | Por PR                 | ✅ Activo |
| 📋 `script-governance.yml`         | Governanza de scripts                            | Por PR                 | ✅ Activo |
| 🏷️ `labeler.yml`                   | Auto-etiquetado de PRs                           | Por PR                 | ✅ Activo |
| 📝 `sdd-gate.yml`                  | Bloqueo de PRs sin SDD validado                  | Por PR                 | ✅ Activo |
| ✅ `workflow-lint.yml`             | Validación de sintaxis de workflows              | Por cambio en .github/ | ✅ Activo |

---

**Modo actual de publicación**: `develop-first`. Los pushes frecuentes y la validación continua
corren sobre `develop`; `main` queda reservado para release PRs, hotfixes y tags semver.

---

## 📖 Documentación Disponible

| Documento              | Descripción                         | Enlace                                                                         |
| ---------------------- | ----------------------------------- | ------------------------------------------------------------------------------ |
| 🚀 **Getting Started** | Guía de inicio para nuevos usuarios | [docs/getting-started/README.md](docs/getting-started/README.md)               |
| 🏗️ **Architecture**    | Vista general de arquitectura       | [docs/architecture/README.md](docs/architecture/README.md)                     |
| 📚 **Skills Catalog**  | Referencia de 125+ skills           | [docs/reference/SKILL-ORGANIZATION.md](docs/reference/SKILL-ORGANIZATION.md)   |
| 💰 **Token Tracking**  | Guía de monitoreo de tokens         | [docs/reference/REAL-TOKEN-TRACKING.md](docs/reference/REAL-TOKEN-TRACKING.md) |
| 🧩 **Plugin System**   | Guía de desarrollo de plugins       | [docs/reference/PLUGIN-ARCHITECTURE.md](docs/reference/PLUGIN-ARCHITECTURE.md) |
| 📜 **Changelog**       | Historial de cambios v2.8.0         | [CHANGELOG.md](CHANGELOG.md)                                                   |
| 🎯 **Next Session**    | Guía para la próxima sesión         | [docs/NEXT_SESSION_GUIDE.md](docs/NEXT_SESSION_GUIDE.md)                       |
| 📋 **Contributing**    | Cómo contribuir al proyecto         | [CONTRIBUTING.md](CONTRIBUTING.md)                                             |

---

## 🔧 Prerrequisitos

| Requisito         | Versión | Estado       | Opcional                     |
| ----------------- | ------- | ------------ | ---------------------------- |
| 🔷 **PowerShell** | 7+      | ✅ Requerido | ❌                           |
| 🌿 **Git**        | 2.50+   | ✅ Requerido | ❌                           |
| 🔷 **Go**         | 1.26+   | ⚠️ Opcional  | ✅ Solo scripts específicos  |
| 🟢 **Node.js**    | 18+     | ⚠️ Opcional  | ✅ Solo algunas herramientas |

---

## 📂 Estructura del Proyecto

```
workspace-foundation/
├── 📜 scripts/           # 248 scripts PowerShell (CLI, TUI, monitoreo)
├── 🧩 skills/            # 125+ skills especializados de IA
├── ⚙️ config/            # Configuraciones (auto-delegation, DAG, tokens)
├── 📖 docs/              # 16 documentos principales
├── 🧪 tests/             # 28 tests (22 unit + 3 integration + 2 security + 1 perf) - 100% PASS
├── 📋 rules/             # Reglas y estándares del proyecto
└── 💾 .engram-data/     # Memoria persistente (607 observations)
```

---

## 🎖️ Estado de Validación (100% PASS)

```
╔══════════════════════════════════════════════════════════════╗
║           🏆 AGENT SELF-VERIFICATION REPORT 🏆             ║
╠══════════════════════════════════════════════════════════════╣
║  ✅ CONFIG: 3/3 PASS (json-syntax, auto-delegation, quality)  ║
║  ✅ SKILLS: 1/1 PASS (125 skills validados)                 ║
║  ✅ TESTS: 1/1 PASS (20 unit + 10 integration)             ║
║  ✅ HOOKS: 2/2 PASS (hook-scripts, git-hook-installed)    ║
║  ✅ STRUCTURE: 7/7 PASS (all checks)                       ║
║                                                              ║
║  📊 14/14 passed | 0 error(s) | 0 warning(s)              ║
║  🏆 RESULT: ALL CHECKS PASS — work verified clean.           ║
╚══════════════════════════════════════════════════════════════╝
```

---

## 🚀 Inicio Rápido (Resumido)

```powershell
# 1️⃣ Clonar el repositorio público
git clone https://github.com/EmmanuelOrtiz87/foundation-public.git
cd foundation-public

# 2️⃣ Ejecutar el instalador interactivo (o usa wf.ps1)
.\scripts\utilities\foundation-installer-tui.ps1

# 3️⃣ Iniciar sesión automática
.\scripts\utilities\session-autostart.cmd

# 4️⃣ ¡Listo! El orquestador detectará y delegará automáticamente
# "Implementa feature X" → DEV agent
# "Genera tests" → QA agent
# "Audita seguridad" → GOV agent
```

---

## 🌟 ¿Por qué elegir Workspace Foundation?

| Beneficio                  | Impacto                      | Métrica                                 |
| -------------------------- | ---------------------------- | --------------------------------------- |
| ⏱️ **Reducción de tiempo** | 80% menos tiempo en setup    | TUI installer: 5 min vs 2+ horas manual |
| 🎯 **Consistencia**        | 100% adherencia a estándares | Auto-delegación + judgment-day          |
| 🧪 **Cobertura**           | ~75% objetivos cubiertos     | 28 tests automatizados (4 categorías)   |
| 🔒 **Seguridad**           | Detección temprana           | Trufflehog + OWASP scan                 |
| 🔄 **Continuidad**         | Memoria persistente          | Engram: 607 observations                |
| 👁️ **Visibilidad**         | Reportes automáticos         | Dashboards semanales y mensuales        |

---

## 📱 Conecta con Nosotros

| Plataforma              | Enlace                                                                                                     |
| ----------------------- | ---------------------------------------------------------------------------------------------------------- |
| 🐙 **GitHub (Public)**  | [github.com/EmmanuelOrtiz87/foundation-public](https://github.com/EmmanuelOrtiz87/foundation-public)       |
| 🔒 **GitHub (Private)** | [github.com/EmmanuelOrtiz87/gentleman-foundation](https://github.com/EmmanuelOrtiz87/gentleman-foundation) |
| 📖 **Docs**             | [docs.foundation.local](docs/README.md)                                                                    |

### #️⃣ Hashtags

`#FoundationStack` `#AIDevelopment` `#DevTools` `#OpenCode` `#Productivity` `#LocalFirst`
`#AIAgents`

---

## 📜 Licencia

MIT License - Ver archivo [LICENSE](LICENSE) para detalles.

---

## 🎯 Perfecto para:

- ✅ **Nuevos proyectos**: Scaffolding con templates (service, cli, library, frontend, fullstack,
  microservices)
- ✅ **Desarrollo continuo**: Auto-delegación, code review, testing
- ✅ **QA y testing**: E2E, unit, integration, security testing
- ✅ **Operaciones**: Docker, K8s, Terraform, CI/CD
- ✅ **Governanza**: Auditorías, compliance, reportes gerenciales
- ✅ **Monitoreo**: Dashboards ejecutivos, métricas semanales

---

<p align="center">
  <b>🏛️ Workspace Foundation v2.8.0 — El Stack Definitivo para IA-First Development</b><br>
  <i>100% Local-First • Privacidad Total • Listo para Producción</i><br><br>
  <code>git clone https://github.com/EmmanuelOrtiz87/foundation-public.git</code>
</p>
