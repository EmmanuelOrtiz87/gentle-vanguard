---
name: gitflow-orchestrator-skill
description: GitFlow workflow validation and branch creation orchestration
trigger: gitflow, git, branch, workflow, git hooks
---

# GitFlow Orchestrator Skill

**Versión**: 1.0.0  
**Tipo**: Orchestrator Skill  
**Propósito**: Coordinar, validar y guiar el cumplimiento de GitFlow  
**Estado**: ACTIVO

---

## 📋 Descripción

El **GitFlow Orchestrator Skill** actúa como un maestro/tutor que:

1. **Valida** que se respete el flujo de GitFlow en cada paso
2. **Guía** a los desarrolladores con instrucciones claras
3. **Previene** errores antes de que ocurran
4. **Enseña** mejores prácticas cuando sea necesario
5. **Automatiza** tareas repetitivas

---

## 🎯 Responsabilidades

### 1. Validación Estricta
- ✅ Bloquea pushes a ramas protegidas (main/develop)
- ✅ Valida nomenclatura de rama
- ✅ Valida PR base según tipo de rama
- ✅ Verifica que los cambios cumplan políticas

### 2. Guía Interactiva
- ✅ Ofrece crear rama automáticamente si es inválida
- ✅ Proporciona ejemplos claros de comandos
- ✅ Explica qué tipo de rama usar
- ✅ Muestra próximos pasos

### 3. Prevención de Errores
- ✅ Detecta ramas mal nombradas ANTES de hacer push
- ✅ Valida PR base ANTES de mergear
- ✅ Verifica que los commits cumplan políticas
- ✅ Alerta sobre configuraciones incorrectas

### 4. Enseñanza
- ✅ Explica por qué se rechazó una acción
- ✅ Proporciona documentación relevante
- ✅ Sugiere mejores prácticas
- ✅ Ofrece recursos de aprendizaje

---

## 🔧 Componentes Implementados

### 1. Script de Validación Mejorado
**Archivo**: `scripts/diagnostics/validate-gitflow.ps1`

**Características**:
- Detecta rama actual automáticamente
- Clasifica por tipo (feature, bugfix, chore, hotfix, release)
- Valida nomenclatura de rama
- Calcula base esperada para PR
- Proporciona guía contextual si hay error
- Modo interactivo para crear rama
- Mensajes de error informativos con ejemplos

**Uso**:
```powershell
# Validación automática (en pre-push hook)
.\scripts\diagnostics\validate-gitflow.ps1

# Validación interactiva (con opción de crear rama)
.\scripts\diagnostics\validate-gitflow.ps1 -Interactive

# Validación silenciosa
.\scripts\diagnostics\validate-gitflow.ps1 -Quiet
```

---

### 2. Creador de Rama Interactivo
**Archivo**: `scripts/utilities/create-gitflow-branch.ps1`

**Características**:
- Pregunta interactivamente qué tipo de cambio es
- Solicita descripción del cambio
- Valida y limpia el nombre de rama
- Crea rama desde la base correcta (develop o main)
- Verifica que la rama no exista
- Muestra información contextual sobre el tipo
- Proporciona próximos pasos claros
- Explica qué validaciones se ejecutarán

**Uso**:
```powershell
# Interactivo (Recomendado)
.\scripts\utilities\create-gitflow-branch.ps1

# Con parámetros
.\scripts\utilities\create-gitflow-branch.ps1 -Type feature -Description "add-user-auth"

# Silencioso
.\scripts\utilities\create-gitflow-branch.ps1 -Type feature -Description "add-user-auth" -Quiet
```

**Flujo Interactivo**:
1. Detecta rama actual
2. Pregunta tipo de cambio (feature/bugfix/chore/hotfix/release)
3. Muestra información sobre el tipo seleccionado
4. Solicita descripción
5. Valida nomenclatura
6. Crea rama desde base correcta
7. Muestra próximos pasos
8. Explica validaciones automáticas

---

### 3. Hooks de Git Mejorados
**Archivo**: `scripts/git-hooks/pre-push`

**Características**:
- Ejecuta validación de GitFlow automáticamente
- Ejecuta validaciones de código (gga)
- Ejecuta validaciones de governance
- Ejecuta validaciones de homologation
- Proporciona mensajes claros y accionables
- Sugiere acciones correctivas
- Bloquea push si hay violaciones

**Flujo**:
```
git push
  ↓
pre-push hook ejecuta:
  1. validate-gitflow.ps1 (valida rama)
  2. gga run (valida código)
  3. validate-script-governance.ps1 (valida governance)
  4. homologate-workspace.ps1 (valida homologation)
  ↓
Si todo OK → push permitido
Si hay error → push bloqueado + mensaje de ayuda
```

---

### 4. Documentación de Referencia
**Archivo**: `docs/guides/GITFLOW-QUICK-REFERENCE.md`

**Contenido**:
- Inicio rápido con comando interactivo
- Flujos estándar paso a paso
- Errores comunes y soluciones
- Mejores prácticas
- Ejemplos de nombres válidos/inválidos
- Información de ramas (main, develop, work branches)
- Flujo completo paso a paso
- Información de automatización
- Enlaces a documentación completa

---

## 📊 Flujo de Interacción Completo

```
┌─────────────────────────────────────────────────────────────┐
│ Desarrollador intenta hacer cambios                         │
└────────────────────────┬──────────────────────────────────────┘
                         │
                    ¿Rama válida?
                    /           \
                  NO             SÍ
                  │              │
        ┌─────────▼──────┐       │
        │ Pre-Push Hook  │       │
        │ Detecta error  │       │
        └────────┬───────┘       │
                 │               │
        ┌────────▼──────────┐    │
        │ Muestra Guía      │    │
        │ GitFlow Help      │    │
        └────────┬──────────┘    │
                 │               │
        ┌────────▼──────────────┐│
        │ Ofrece crear rama     ││
        │ automáticamente       ││
        └────────┬──────────────┘│
                 │               │
        ┌────────▼──────────────┐│
        │ create-gitflow-branch ││
        │ .ps1 (Interactivo)    ││
        └────────┬──────────────┘│
                 │               │
                 └───────┬───────┘
                         │
                    ¿Rama válida?
                    /           \
                  NO             SÍ
                  │              │
        ┌─────────▼──────┐       │
        │ Muestra error  │       │
        │ y guía nuevamente      │
        └────────────────┘       │
                                 │
                         ┌───────▼──────────┐
                         │ Ejecuta          │
                         │ Validaciones:    │
                         │ • GitFlow        │
                         │ • Código (GGA)   │
                         │ • Governance     │
                         │ • Homologation   │
                         └───────┬──────────┘
                                 │
                            ¿Todo OK?
                            /         \
                          SÍ           NO
                          │            │
                    ┌─────▼──┐   ┌────▼──────┐
                    │ PUSH OK │   │ PUSH FAIL │
                    │ ✅      │   │ ❌        │
                    └─────────┘   │ Muestra  │
                                  │ error y  │
                                  │ solución │
                                  └──────────┘
```

---

## 🎓 Rol de Maestro/Tutor

El Orchestrator actúa como maestro en los siguientes escenarios:

### Escenario 1: Rama Inválida
```
Desarrollador intenta: git push
↓
Pre-push hook detecta rama inválida
↓
Muestra:
  ❌ Branch 'my-changes' does not match allowed GitFlow naming
  
  ❌ RAMA NO VÁLIDA
  Tu rama debe tener uno de estos prefijos:
    • feature/  - para nuevas funcionalidades
    • bugfix/   - para correcciones de bugs
    • chore/    - para mantenimiento
    • hotfix/   - para fixes críticos
    • release/  - para preparación de release
  
  ✅ SOLUCIÓN RÁPIDA:
  1. Crea una rama de trabajo:
     .\scripts\utilities\create-gitflow-branch.ps1
  
  📚 TIPOS DE RAMA PERMITIDOS:
    • feature/*  → Nuevas funcionalidades → PR base: develop
    • bugfix/*   → Corrección de bugs    → PR base: develop
    • chore/*    → Mantenimiento         → PR base: develop
    • hotfix/*   → Fixes críticos        → PR base: main
    • release/*  → Preparación release   → PR base: main
  
  💡 EJEMPLOS DE NOMBRES VÁLIDOS:
    ✓ feature/add-user-authentication
    ✓ bugfix/fix-login-timeout
    ✓ chore/update-dependencies
    ✓ hotfix/critical-security-patch
↓
Desarrollador ejecuta: .\scripts\utilities\create-gitflow-branch.ps1
↓
Script guía interactivamente:
  1. ¿Qué tipo de cambio es? (1-5)
  2. Describe brevemente el cambio
  3. Crea rama automáticamente
  4. Muestra próximos pasos
```

### Escenario 2: Base de PR Incorrecta
```
Desarrollador intenta: git push (desde feature/add-auth)
↓
Pre-push hook valida base esperada
↓
Si PR base es 'main' pero debería ser 'develop':
  ❌ PR base 'main' violates GitFlow for branch 'feature/add-auth'
  Expected base: 'develop'
  
  ✅ SOLUCIÓN:
  1. Cierra el PR actual
  2. Crea nuevo PR con base: develop
  3. O edita el PR y cambia la base
```

### Escenario 3: Primer Uso del Proyecto
```
Desarrollador nuevo ejecuta: .\scripts\utilities\create-gitflow-branch.ps1
↓
Script muestra:
  ╔════════════════════════════════════════════════════════════╗
  ║           GitFlow Branch Creator                           ║
  ╚════════════════════════════════════════════════════════════╝
  
  ℹ️  Rama actual: main
  
  📋 ¿Qué tipo de cambio es?
     1) feature  - Nueva funcionalidad
     2) bugfix   - Corrección de bug
     3) chore    - Mantenimiento/actualización
     4) hotfix   - Fix crítico en producción
     5) release  - Preparación de release
  
  Selecciona (1-5): 1
  
  📚 Información del tipo seleccionado:
     • Uso: Nuevas funcionalidades
     • Base esperada: develop
     • Ejemplo: feature/add-user-authentication
  
  📝 Describe brevemente el cambio:
     (usa guiones para separar palabras, ej: add-user-auth)
  Descripción: add-user-authentication
  
  ℹ️  Nombre de rama propuesto: feature/add-user-authentication
  ℹ️  Base esperada para PR: develop
  
  🔄 Creando rama...
  ✅ Rama 'feature/add-user-authentication' creada exitosamente
  
  ╔════════════════════════════════════════════════════════════╗
  ║           Próximos Pasos                                   ║
  ╚════════════════════════════════════════════════════════════╝
  
  1️⃣  Haz tus cambios en los archivos
     Edita los archivos necesarios para tu cambio
  
  2️⃣  Prepara los cambios
     git add .
  
  3️⃣  Crea un commit
     git commit -m 'descripción clara del cambio'
  
  4️⃣  Pushea la rama
     git push -u origin feature/add-user-authentication
  
  5️⃣  Abre un Pull Request en GitHub
     • Base: develop
     • Título: Descripción clara del cambio
     • Descripción: Explica QUÉ cambió y POR QUÉ
  
  📋 Información de la rama:
     Nombre: feature/add-user-authentication
     Tipo: feature
     Base esperada: develop
     Estado: ✅ Lista para trabajar
  
  💡 Recuerda:
     • Los commits se validarán automáticamente (pre-commit hook)
     • El push será validado contra GitFlow (pre-push hook)
     • El PR debe tener la base correcta: develop
```

---

## 🔄 Ciclo de Vida de un Cambio

```
1. CREAR RAMA
   ↓
   Desarrollador ejecuta:
   .\scripts\utilities\create-gitflow-branch.ps1
   ↓
   Script guía y crea rama válida
   ↓

2. HACER CAMBIOS
   ↓
   Desarrollador edita archivos
   ↓

3. COMMIT
   ↓
   git commit -m "descripción"
   ↓
   Pre-commit hook valida:
   • Código con GGA
   • Políticas de revisión
   ↓
   Si OK → commit permitido
   Si error → commit bloqueado + guía
   ↓

4. PUSH
   ↓
   git push -u origin rama
   ↓
   Pre-push hook valida:
   • GitFlow (rama, base)
   • Código (GGA)
   • Governance
   • Homologation
   ↓
   Si OK → push permitido
   Si error → push bloqueado + guía
   ↓

5. PULL REQUEST
   ↓
   Desarrollador abre PR en GitHub
   ↓
   Validaciones automáticas:
   • Base correcta
   • Descripción presente
   • Nombre sigue convenciones
   ↓

6. REVISIÓN
   ↓
   Reviewers validan código
   ↓

7. MERGE
   ↓
   Una vez aprobado, mergea PR
   ↓
   Rama se elimina automáticamente
   ↓

8. COMPLETADO ✅
```

---

## 📚 Recursos de Aprendizaje

El Orchestrator proporciona acceso a:

1. **GITFLOW-QUICK-REFERENCE.md**
   - Referencia rápida de flujos
   - Errores comunes y soluciones
   - Mejores prácticas

2. **GITFLOW-ENFORCEMENT-ANALYSIS.md**
   - Análisis detallado de GitFlow
   - Recomendaciones de mejora
   - Plan de acción

3. **DEVELOPER-COMMUNICATION-POLICY.md**
   - Políticas de desarrollo
   - Estándares de código
   - Convenciones de nombres

4. **Scripts de Validación**
   - `validate-gitflow.ps1` - Validador de GitFlow
   - `validate-script-governance.ps1` - Validador de governance
   - `homologate-workspace.ps1` - Validador de homologation

---

## ✅ Checklist de Implementación

### Nivel 1 (Inmediato - COMPLETADO ✅)
- ✅ Enriquecer mensajes de error en `validate-gitflow.ps1`
- ✅ Crear `create-gitflow-branch.ps1` interactivo
- ✅ Crear `GITFLOW-QUICK-REFERENCE.md`
- ✅ Crear `GITFLOW-ENFORCEMENT-ANALYSIS.md`
- ✅ Crear `GitFlow Orchestrator Skill`

### Nivel 2 (Corto Plazo - EN PROGRESO)
- ⏳ Validar PR base antes de push (en pre-push hook)
- ⏳ Agregar comando `wf.ps1 gitflow-setup` interactivo
- ⏳ Integrar GitHub Actions para validación de PR

### Nivel 3 (Mediano Plazo - PENDIENTE)
- 🔲 Dashboard de cumplimiento de GitFlow
- 🔲 Reportes de violaciones
- 🔲 Métricas de adherencia

---

## 🎯 Objetivo Logrado

El **GitFlow Orchestrator Skill** proporciona:

✅ **Validación Estricta**: Bloquea violaciones de GitFlow automáticamente

✅ **Guía Interactiva**: Ofrece crear rama correcta automáticamente

✅ **Enseñanza**: Explica por qué se rechazó una acción

✅ **Prevención**: Detecta errores ANTES de que ocurran

✅ **Automatización**: Ejecuta validaciones automáticamente en cada paso

El desarrollador ahora tiene un **maestro/tutor** que:
- Lo guía en cada paso del proceso
- Le enseña mejores prácticas
- Lo previene de cometer errores
- Lo ayuda a entender por qué algo fue rechazado
- Lo automatiza tareas repetitivas