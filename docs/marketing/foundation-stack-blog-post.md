# 🏛️ Foundation: Mi AI Development Workspace

<p align="center">
  <b>🌐 Cómo optimizar tu desarrollo con AI assistants usando un workspace agnóstico</b>
</p>

---

## 🚨 El Problema

Cada día, más equipos usan AI assistants como **OpenCode, Claude, Cursor o GitHub Copilot**. Pero:

| Desafío | Impacto |
|---------|---------|
| ❌ Sin tracking de sesiones | No hay visibilidad del trabajo |
| ❌ Sin métricas de consumo | Costos descontrolados de tokens |
| ❌ Sin estructura para delegar | Agents trabajando aisladamente |
| ❌ Informes scattered | No hay visión unificada |
| ❌ Sin gobernanza | Riesgos de seguridad y calidad |

> **Foundation** resuelve esto.

---

## 🤔 ¿Qué es Foundation?

```
            🏛️ FOUNDATION v2.7.0                         
      AI Development Workspace                    
 
   🎮 Session Manager    🚀 Auto-Delegation    📈 Reporting  
   💰 Token Guard     🎭 Orchestrator      🔍 Tracing    
 
 Un workspace agnóstico que funciona con **cualquier** AI assistant.
```

---

## 🧩 Componentes Core

### 1️⃣ 🎮 Session Manager
```powershell
.\scripts\utilities\session-autostart.cmd
# Inicia sesión trackeada automáticamente
```

Tracking automático de:
- 📊 Sesiones activas
- ⏱️ Duración
- 💰 Métricas de tokens

### 2️⃣ 🚀 Auto-Delegation
El orquestador detecta qué necesitas y delega al skill/subagente correcto:

```
"génerame un informe"        → 📈 REPORT agent + wf-report.ps1
"implementa login"              → 🛠️ DEV agent + implementation skill
"audita seguridad"             → 🔒 GOV agent + judgment-day
```

**15+ categorías**: GOV, DEV, QA, DOC, SAD, OPS, REPORT, etc.

### 3️⃣ 📈 Reporting On-Demand
```powershell
# Informes desde CLI:
.\scripts\utilities\wf-report.ps1 -Type sessions -Period 7days
.\scripts\utilities\wf-report.ps1 -Type executive
.\scripts\utilities\wf-report.ps1 -Type costs
```

O simplemente:
> *"génerame un resumen ejecutivo"* → auto-delegación al reporting skill

### 4️⃣ 💰 Token Guard
Control de contexto:
- 📊 Budget: 128K tokens
- ⚠️ Alertas: 80%, 90%, 95%
- 🧩 Fragmentation strategy

---

## 📊 Métricas Reales

| Fecha | Sesiones | Activas | Tendencia |
|-------|-----------|--------|----------|
| 24-Abr | 5 | 5 | ➡️ |
| 25-Abr | 7 | 7 | 📈 +40% |
| 26-Abr | 1 | 1 | 🔄 En curso |

**🖥️ Sistema**: Operativo  
**💰 Token Guard**: Activo (128K budget)  
**📈 Reporting**: Implementado

---

## 🌐 ¿Por qué agnóstico?

Foundation **NO depende de un AI específico**:

| AI Assistant | Compatible |
|------------|-----------|
| ✅ OpenCode | 🟢 Total |
| ✅ Claude (Anthropic) | 🟢 Total |
| ✅ Cursor | 🟢 Total |
| ✅ GitHub Copilot | 🟢 Total |
| ✅ Any LLM | 🟢 Total |

El workspace es **agnóstico** - trabaja con la herramienta que vos elijas.

---

## 🛠️ Installing

```powershell
# Clone
git clone https://github.com/EmmanuelOrtiz87/foundation-public.git

# Setup
.\scripts\utilities\session-autostart.cmd

# ¡Listo!
```

---

## 🎯 Próximos Pasos

| Tarea | Estado |
|-------|--------|
| 1. [x] Git hooks (pre-commit, pre-push) | ✅ Activo |
| 2. [ ] MCP servers | 📋 Pendiente |
| 3. [ ] Dashboard UI | 📋 Pendiente |
| 4. [ ] Plugin marketplace | 📋 Pendiente |

Ver: `reports/RECOMENDACIONES-FOUNDATION-PRODUCTO.md`

---

## 🎓 Conclusión

Foundation transforma tu AI assistant en un **sistema de desarrollo completo** con:

- 📊 Métricas reales
- 🚀 Auto-delegación
- 📈 Reporting
- 🔒 Gobernanza

> **¿Querés probarlo?** Clonalo y corré `.\scripts\utilities\session-autostart.cmd`

---

<p align="center">
  <i>* Built for AI-first teams*</i><br>
  <i>* Open source • Mejorando continuamente*</i>
</p>

`#FoundationStack` `#AIDevelopment` `#DevTools`
