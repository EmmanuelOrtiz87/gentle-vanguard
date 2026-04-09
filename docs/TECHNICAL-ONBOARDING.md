# Workspace Foundation
## Technical Onboarding Guide

**Versión:** 1.0  
**Fecha:** Abril 2026  
**Audiencia:** Equipo de Desarrollo  

---

## Tabla de Contenidos

1. [¿Qué es Workspace Foundation?](#1-qué-es-workspace-foundation)
2. [Conceptos Fundamentales de IA](#2-conceptos-fundamentales-de-ia)
3. [Configuración de IA](#3-configuración-de-ia)
4. [Herramientas Integradas](#4-herramientas-integradas)
5. [Flujo de Trabajo](#5-flujo-de-trabajo)
6. [Guía de Uso por Herramienta](#6-guía-de-uso-por-herramienta)
7. [Diccionario y Glosario](#7-diccionario-y-glosario)
8. [Mejores Prácticas](#8-mejores-prácticas)
9. [FAQ - Preguntas Frecuentes](#9-faq---preguntas-frecuentes)
10. [Bibliografía y Recursos](#10-bibliografía-y-recursos)

---

## 1. ¿Qué es Workspace Foundation?

### Definición

Workspace Foundation es un **sistema de plantillas y automatización** que estandariza cómo se configura, desarrolla y documenta un proyecto de software, integrando herramientas de Inteligencia Artificial en el flujo de trabajo diario.

### Objetivo Principal

```
Problema: Cada proyecto comienza desde cero con configuración manual
          ↓
Solución: Un sistema que configura, estandariza y mide automáticamente
          ↓
Resultado: Más tiempo en código, menos tiempo en setup
```

### ¿Qué problemas resuelve?

| Problema | Solución |
|----------|----------|
| Configuración manual de herramientas | Bootstrap automático |
| Inconsistencia entre proyectos | Plantillas unificadas |
| Sin estándares de código | GGA (revisión automática) |
| Desconocimiento de AI tools | Integración nativa |
| Sin métricas de productividad | Sistema de auditoría |

### Componentes Core

```
Workspace Foundation
├── Bootstrap System       → Configura el entorno automáticamente
├── Project Templates     → Estructuras predefinidas por tipo de proyecto
├── AI Integration       → Conexión con Claude, OpenCode, Gentle-AI
├── Code Review (GGA)    → Revisión automática con IA
├── Audit System         → Métricas y tracking de actividad
└── Documentation        → Plantillas de docs automatizadas
```

---

## 2. Conceptos Fundamentales de IA

### 2.1 ¿Qué es un LLM?

**LLM** = Large Language Model (Modelo de Lenguaje Grande)

```
┌─────────────────────────────────────────────────────────────┐
│                        LLM                                   │
│                                                              │
│   Input: "Escribe una función que sume dos números"         │
│          ↓                                                   │
│   [Entiende el contexto]                                     │
│   [Genera respuesta basada en patrones aprendidos]          │
│          ↓                                                   │
│   Output: "function sum(a, b) { return a + b; }"          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Analogía:** Es como un estudiante que leyó millones de libros de código. Puede escribir código porque "aprendió" los patrones.

### 2.2 Prompt Engineering

**Prompt** = La instrucción que le das a la IA

| Tipo de Prompt | Ejemplo | Resultado |
|----------------|---------|-----------|
| Básico | "Escribe una función" | Funcional pero genérico |
| Específico | "Escribe una función en TypeScript con tipos para suma de números" | Más preciso |
| Con contexto | "Estoy en un proyecto React, necesito una función que..." | Contextualizado |

**Regla de oro:** Cuanto más contexto, mejor respuesta.

### 2.3 Tokens

**Token** = Unidad básica de texto que la IA procesa

```
Ejemplo: "Hola mundo"
Tokens: ["Hola", "mund", "o"] → 3 tokens aproximadamente

1 token ≈ 4 caracteres en inglés
1 token ≈ 2 caracteres en español
```

**¿Por qué importa?** Los modelos cobran por token.

### 2.4 Temperature y Creativity

| Setting | Uso |
|---------|-----|
| **Temperature 0** | Respuestas determinísticas (código, facts) |
| **Temperature 0.7** | Balance (respuestas creativas) |
| **Temperature 1+** | Máxima creatividad (brainstorming) |

### 2.5 Context Window

**Context Window** = La cantidad de texto que la IA puede "recordar" en una conversación

| Modelo | Context Window |
|--------|----------------|
| Claude Sonnet 4 | 200K tokens (~150K palabras) |
| GPT-4o | 128K tokens |
| Gemini 1.5 | 1M tokens |

**Analogía:** Es como la memoria de trabajo. Si le das mucha información, puede "olvidar" partes anteriores.

### 2.6 Few-shot vs Zero-shot

| Técnica | Descripción | Ejemplo |
|---------|-------------|---------|
| **Zero-shot** | Sin ejemplos | "Clasifica: positivo/negativo" |
| **Few-shot** | Con ejemplos | "Ejemplo: 'amo esto' → positivo. Clasifica: 'no me gusta' → ?" |

---

## 3. Configuración de IA

### 3.1 Opciones Disponibles

| Opción | Requiere | Costo | Offline |
|--------|----------|-------|---------|
| **Cloud (API)** | API Key | $10-20/mes | ❌ |
| **Local (Ollama)** | GPU 8GB+ | $0 | ✅ |
| **Híbrido** | Ambos | $variable | ⚠️ |

### 3.2 Cloud: Configuración Rápida

**Solo necesitas una API Key:**

```powershell
# 1. Obtener API Key de https://console.anthropic.com/
# 2. Crear archivo .env en tu proyecto
ANTHROPIC_API_KEY=sk-ant-xxxxx

# 3. Listo - Foundation usa la API automáticamente
```

**Proveedores soportados:**

| Proveedor | Modelos | Website |
|-----------|---------|---------|
| **Anthropic** (Recomendado) | Claude Sonnet, Opus | console.anthropic.com |
| **OpenAI** | GPT-4, GPT-4o | platform.openai.com |
| **Google** | Gemini 1.5, 2.0 | aistudio.google.com |

### 3.3 Local: Ollama (Offline)

**Para 100% offline o sin costos de API:**

```powershell
# 1. Instalar Ollama
winget install Ollama.Ollama

# 2. Descargar modelo (requiere GPU 8GB+)
ollama pull codellama:13b

# 3. Foundation detecta Ollama automáticamente
```

### 3.4 Híbrido (Recomendado)

Usa cloud como primario, local como backup:

```powershell
# .env - Configuración híbrida

# Cloud
ANTHROPIC_API_KEY=sk-ant-xxxxx

# Local
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=codellama:13b

# Priority
AI_PROVIDER_PRIORITY=anthropic,ollama
```

**Flujo automático:**
```
Internet disponible → Usa Claude Cloud
    ↓
Sin internet → Usa Ollama local
```

### 3.5 Verificación

```powershell
# Testea que todo funciona
claude "Hola, responde con 'Funcionando!'"

# Ver configuración
opencode config show

# Si hay errores
# Ver docs/AI-CONFIGURATION.md para troubleshooting
```

### 3.6 Sin IA (Solo Templates)

Si no querés usar IA:

```powershell
# Foundation funciona sin IA
# Solo usarás templates, GGA no estará activo
# Audit system sigue funcionando

# Para desactivar AI tools completamente:
NO_AI_MODE=true
```

---

## 4. Herramientas Integradas

### 4.1 Comparativa Rápida

| Herramienta | Función Principal | Mejor Para |
|-------------|-------------------|------------|
| **Claude Code** | Asistencia general con código | Coding, debugging, explanations |
| **OpenCode** | Interface CLI para modelos | Developers que prefieren terminal |
| **Gentle-AI** | Asistente contextual | Tareas específicas del proyecto |
| **GGA** | Code review automático | Pre-commit hooks, calidad |

### 3.2 Claude Code

**¿Qué es?** Interface de línea de comandos para usar Claude (Anthropic) en tu terminal.

**Casos de uso:**
- Generar código
- Explicar código existente
- Debugging
- Refactoring
- Crear tests

**Ejemplo de uso:**
```bash
# Iniciar sesión interactiva
claude

# Comando único
claude "Explica este error: Cannot read property 'map' of undefined"
```

### 3.3 OpenCode

**¿Qué es?** Interface CLI que permite usar diferentes modelos de IA (OpenAI, Anthropic, etc.)

**Casos de uso:**
- same as Claude Code
- Switch entre modelos según necesidad
- Configuración unificada

**Ejemplo de uso:**
```bash
# Usar GPT-4
opencode --model gpt-4 "Optimiza esta función"

# Usar Claude
opencode --model claude-sonnet-4 "Refactoriza este componente"
```

### 3.4 Gentle-AI

**¿Qué es?** Asistente integrado que conoce el contexto de tu proyecto.

**Casos de uso:**
- Tareas específicas del dominio
- Queries sobre arquitectura
- Explicaciones de decisiones técnicas

**Característica distintiva:** Mantiene contexto del proyecto entre conversaciones.

### 3.5 GGA (Gentleman Guardian Angel)

**¿Qué es?** Sistema de hooks de pre-commit que revisa código con IA.

**Workflow:**
```
Git commit → GGA hook → Revisión IA → Aprueba/Bloquea
```

**Beneficios:**
- Código revisado antes de push
- Estándares aplicados automáticamente
- Feedback inmediato

---

## 4. Flujo de Trabajo

### 4.1 Día Típico

```
┌─────────────────────────────────────────────────────────────────┐
│                         DESARROLLADOR                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Mañana: Iniciar workspace                                        │
│ $ ./scripts/init-workspace.ps1                                   │
│                                                                  │
│   ✓ Bootstraps herramientas                                      │
│   ✓ Descarga templates                                           │
│   ✓ Configura AI tools                                          │
│   ✓ Inicia sesión de auditoría                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Trabajo: Desarrollo con IA                                        │
│                                                                  │
│   1. Usar Claude/OpenCode para generar código                   │
│   2. Usar GGA para revisión pre-commit                          │
│   3. Gentle-AI para consultas contextuales                      │
│   4. Todo se loggea automáticamente                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ Fin de día: Finalizar sesión                                      │
│ $ ./scripts/finalize-session.ps1                                 │
│                                                                  │
│   ✓ Git add/commit/push                                          │
│   ✓ Genera métricas de actividad                                 │
│   ✓ Reporta auditoría                                            │
│   ✓ (Semanal: Genera reporte)                                   │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Comandos Esenciales

```powershell
# Iniciar día
.\scripts\init-workspace.ps1

# Trabajar normalmente con Git
git checkout -b feature/nueva-funcionalidad
# ... desarrollo con AI tools ...

# Revisar con GGA (automático en pre-commit)
git add .
git commit -m "feat: nueva funcionalidad"

# Finalizar día
.\scripts\finalize-session.ps1
```

---

## 5. Guía de Uso por Herramienta

### 5.1 Claude Code - Guía Rápida

#### Generación de Código

```bash
# Generar función específica
claude "Crea una función en TypeScript que valide un email"

# Generar componente completo
claude "Crea un componente React para un formulario de login con:
- Email input
- Password input  
- Submit button
- Validación
- Estilos con Tailwind"

# Generar desde archivo
claude "Revisa y mejora src/utils/helpers.ts"
```

#### Debugging

```bash
# Explicar error
claude "Explica este error y sugiere solución:
Error: TypeError: Cannot read property 'map' of undefined"

# Debug con contexto
claude "En el archivo src/api/users.ts línea 45, el array 'users' viene undefined.
El código es:
const names = users.map(u => u.name);
¿Qué está mal?"
```

#### Refactoring

```bash
# Pedir refactor
claude "Refactoriza esta función para que sea más eficiente:
function processData(data) {
  // ... código ...
}"

# Mejorar legibilidad
claude "Mejora la legibilidad de este código sin cambiar funcionalidad:
function calc(a,b,c){
  return a*b+c*2-a/b
}"
```

#### Tests

```bash
# Generar tests
claude "Genera tests unitarios con Jest para esta función:
export function calculateTotal(items) {
  return items.reduce((sum, item) => sum + item.price, 0)
}"
```

### 5.2 OpenCode - Guía Rápida

```bash
# Configurar modelo por defecto
opencode config set default-model claude-sonnet-4

# Modo interactivo
opencode

# Comando rápido
opencode "Explica este código"

# Con archivo específico
opencode --file src/app.ts "Mejora este código"

# Cambiar modelo
opencode --model gpt-4o "Usa el código anterior y..."
```

### 5.3 Gentle-AI - Guía Rápida

```bash
# Query sobre el proyecto
gentle-ai "Explica la arquitectura del módulo de auth"

# Solicitar help
gentle-ai "Necesito crear un nuevo endpoint REST. Dame el template"

# Consultar estándares
gentle-ai "Cuáles son los estándares de naming en este proyecto?"
```

### 5.4 GGA - Guía de Uso

#### Configuración

```bash
# Instalar hooks
./scripts/install-gga-hooks.ps1

# Ver configuración
cat .gga/config.yml
```

#### Workflow

```bash
# Commit normal - GGA corre automáticamente
git add .
git commit -m "feat: nueva funcionalidad"

# Output de GGA:
# ✓ Code review passed
# ✓ Style checks passed  
# ✓ No security issues detected
```

#### Override (casos excepcionales)

```bash
# Forzar commit sin revisión
git commit -m "feat: fix urgente" --no-verify

# ⚠️ Usar solo en casos necesarios
```

---

## 6. Diccionario y Glosario

### Términos de IA

| Término | Definición | Ejemplo |
|---------|------------|---------|
| **AI** | Artificial Intelligence - Simulacros de inteligencia humana por máquinas | ChatGPT, Claude |
| **ML** | Machine Learning - Sistemas que aprenden de datos | Recomendaciones de Netflix |
| **DL** | Deep Learning - Redes neuronales complejas | Reconocimiento de imágenes |
| **NLP** | Natural Language Processing - Procesamiento de lenguaje natural | Traductores automáticos |
| **LLM** | Large Language Model - Modelos entrenados con texto a gran escala | GPT-4, Claude |
| **Prompt** | Instrucción que se le da a una IA | "Escribe un poema" |
| **Token** | Unidad básica de texto procesada por IA | ~4 caracteres |
| **Context Window** | Memoria máxima de una IA en una sesión | 200K tokens |
| **Temperature** | Parámetro que controla creatividad de respuesta | 0 = preciso, 1 = creativo |
| **Inference** | Proceso de generar respuesta con un modelo | Lo que hace la IA cuando preguntas |
| **Fine-tuning** | Entrenar un modelo con datos específicos | Modelo custom para tu código |
| **Embedding** | Representación numérica de texto | Para búsqueda semántica |
| **Hallucination** | Cuando la IA genera información incorrecta | Invents facts |
| **Zero-shot** | Tarea sin ejemplos previos | "Clasifica esto" |
| **Few-shot** | Tarea con pocos ejemplos | "Ejemplo: X→Y. Clasifica: Z" |

### Términos Técnicos del Proyecto

| Término | Definición |
|---------|------------|
| **Bootstrap** | Script que configura el entorno automáticamente |
| **Template** | Estructura base para nuevos proyectos |
| **Skill** | Patrón reutilizable de prompts/acciones |
| **Hook (Git)** | Script que corre en eventos de Git |
| **Agent** | Instancia de AI tool en una máquina |
| **Audit** | Registro de actividad para métricas |
| **GGA** | Gentleman Guardian Angel - Sistema de code review |
| **Foundation** | Workspace Foundation - El sistema principal |

### Abreviaciones

| Abreviatura | Significado |
|-------------|-------------|
| **WF** | Workspace Foundation |
| **CLI** | Command Line Interface |
| **API** | Application Programming Interface |
| **SDK** | Software Development Kit |
| **IDE** | Integrated Development Environment |
| **CRUD** | Create, Read, Update, Delete |
| **REST** | Representational State Transfer |
| **JSON** | JavaScript Object Notation |
| **YAML** | YAML Ain't Markup Language |
| **SSH** | Secure Shell Protocol |
| **URL** | Uniform Resource Locator |
| **MVP** | Minimum Viable Product |
| **ROI** | Return on Investment |

### Flags de Comandos

| Flag | Significado | Ejemplo |
|------|-------------|---------|
| `-m` | Mensaje de commit | `git commit -m "fix"` |
| `-f` | Force | `git push -f` |
| `--dry-run` | Simular sin ejecutar | `./script.ps1 --dry-run` |
| `-v` | Verbose (más output) | `npm install -v` |
| `--help` | Mostrar ayuda | `claude --help` |

---

## 7. Mejores Prácticas

### 7.1 Prompt Engineering

#### ✅ Hacer

```bash
# Bueno: Específico y con contexto
claude "Crea un hook de React para fetching de datos con:
- Loading state
- Error handling
- Cacheo en localStorage
- TypeScript con tipos explícitos"

# Bueno: Con código existente
claude "Revisa este código y sugiere mejoras:
$(cat src/utils/format.ts)"
```

#### ❌ Evitar

```bash
# Malo: Muy vago
claude "Crea algo para los datos"

# Malo: Sin contexto
claude "Hazlo mejor"
```

### 7.2 Seguridad

#### ✅ Hacer

```bash
# Nunca compartir:
# - API keys
# - Tokens de acceso
# - Credenciales
# - Secrets de producción
```

#### ❌ Evitar

```bash
# Malo: Poner secrets en prompts
claude "Mi API key es: sk-1234567890, haz algo con ella"

# Malo: Enviar datos sensibles
claude "Aquí están las contraseñas de usuarios: [datos]"
```

### 7.3 Code Review con GGA

#### Antes de commit

```bash
# 1. Revisar los cambios
git diff --staged

# 2. Asegurar que GGA pasó
# (corre automáticamente)

# 3. Si GGA sugiere cambios, considerarlos
```

#### Casos de override

```bash
# Solo para casos urgentes con justificación
git commit --no-verify -m "WIP: hotfix - será refactorizado después"
```

### 7.4 Uso Responsable de IA

| Situación | Recomendación |
|----------|---------------|
| Código crítico | IA como sugerencia, humano decide |
| Código de seguridad | Verificación manual obligatoria |
| Código legacy | Revisar output antes de aplicar |
| Nuevas features | IA + tests + code review |
| Bugs | IA sugiere, pero verificar causa raíz |

---

## 8. FAQ - Preguntas Frecuentes

### ¿La IA puede ver todos mis archivos?

**R:** Sí, cuando le das contexto. El audit system registra qué archivos fueron accedidos. No envía código a servidores externos excepto a través de las APIs configuradas.

### ¿Mis API keys están seguras?

**R:** Las keys se almacenan localmente en `.env` (gitignored). Nunca se comparten con terceros.

### ¿Qué pasa si la IA da código incorrecto?

**R:** Por eso existe GGA y el code review. LA IA es una herramienta de asistencia, no de reemplazo. Siempre verificar.

### ¿Puedo usar múltiples AI tools?

**R:** Sí. Cada una tiene fortalezas. Se recomienda usar la más apropiada para cada caso.

### ¿El sistema funciona offline?

**R:** Parcialmente. Bootstrap requiere internet para descargar tools. Una vez configurado, algunas funciones funcionan offline.

### ¿Cómo reporto problemas?

**R:** Crear issue en el repo con:
- Pasos para reproducir
- Output/Error
- Versión de WF

### ¿Puedo contribuir al proyecto?

**R:** Sí. Ver CONTRIBUTING.md para guidelines.

---

## 9. Bibliografía y Recursos

### Documentación Oficial

| Recurso | URL | Descripción |
|---------|-----|-------------|
| Workspace Foundation | [Repo](https://github.com/EmmanuelOrtiz87/AI-development-stack) | Repo principal |
| Documentación | [docs/](docs/) | Documentos técnicos |
| AGENTS.md | [Template](templates/project-root/AGENTS.md) | Reglas para AI agents |

### Cursos Recomendados

| Curso | Plataforma | Tema |
|-------|------------|------|
| ChatGPT Prompt Engineering | Coursera | Prompting efectivo |
| AI for Everyone | Coursera | Conceptos de IA |
| Generative AI with LLMs | Coursera | Cómo funcionan los LLMs |
| Anthropic Documentation | docs.anthropic.com | Guía de Claude |

### Lecturas Recomendadas

#### Prompt Engineering

1. **"Prompt Engineering Guide"** - comprehensive prompting techniques
2. **"Learn Prompting"** - Free course on prompting

#### AI in Development

1. **"The Pragmatic Programmer"** - Software development best practices
2. **"Accelerate"** - Science of Lean and Agile

#### Tool-Specific

1. **Anthropic Cookbook** - Claude code examples
2. **OpenAI API docs** - GPT best practices

### Tools Documentation

| Herramienta | Docs |
|-------------|------|
| Claude | docs.anthropic.com |
| OpenAI | platform.openai.com/docs |
| GitHub Copilot | docs.github.com/copilot |
| Cursor | cursor.sh |

### Blogs y News

| Blog | URL |
|------|-----|
| Anthropic Blog | anthropic.com/blog |
| OpenAI Blog | openai.com/blog |
| Towards Data Science | towardsdatascience.com |
| Hacker News | news.ycombinator.com |

---

## Quick Reference Card

```
╔═══════════════════════════════════════════════════════════════╗
║              WORKSPACE FOUNDATION - QUICK REF               ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  INICIAR DÍA                                                 ║
║  $ ./scripts/init-workspace.ps1                               ║
║                                                               ║
║  USAR AI                                                     ║
║  $ claude "tu pregunta o request"                            ║
║  $ opencode --model claude "tu request"                       ║
║  $ gentle-ai "consulta contextual"                             ║
║                                                               ║
║  CODE REVIEW                                                 ║
║  $ git add . && git commit -m "msg"  ← GGA corre automático ║
║                                                               ║
║  FINALIZAR DÍA                                               ║
║  $ ./scripts/finalize-session.ps1                            ║
║                                                               ║
║  HELP                                                         ║
║  $ ./scripts/help.ps1                                        ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

**Documento preparado por:** Equipo de Desarrollo  
**Última actualización:** Abril 2026  
**Versión:** 1.0
