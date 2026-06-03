---
name: gitflow-orchestrator-skill
description: GitFlow workflow validation and branch creation orchestration
trigger: gitflow, git, branch, workflow, git hooks
metadata:
  source: GV-native
---

# GitFlow Orchestrator Skill

**Versin**: 1.0.0  
**Tipo**: Orchestrator Skill  
**Propsito**: Coordinar, validar y guiar el cumplimiento de GitFlow  
**Estado**: ACTIVO

---

## Descripcin

El **GitFlow Orchestrator Skill** acta como un maestro/tutor que:

1. **Valida** que se respete el flujo de GitFlow en cada paso
2. **Gua** a los desarrolladores con instrucciones claras
3. **Previene** errores antes de que ocurran
4. **Ensea** mejores prcticas cuando sea necesario
5. **Automatiza** tareas repetitivas

---

## Responsabilidades

### 1. Validacin Estricta

- Bloquea pushes a ramas protegidas (main/develop)
- Valida nomenclatura de rama
- Valida PR base segn tipo de rama
- Verifica que los cambios cumplan polticas

### 2. Gua Interactiva

- Ofrece crear rama automticamente si es invlida
- Proporciona ejemplos claros de comandos
- Explica qu tipo de rama usar
- Muestra prximos pasos

### 3. Prevencin de Errores

- Detecta ramas mal nombradas ANTES de hacer push
- Valida PR base ANTES de mergear
- Verifica que los commits cumplan polticas
- Alerta sobre configuraciónes incorrectas

### 4. Enseanza

- Explica por qu se rechaz una accin
- Proporciona documentacin relevante
- Sugiere mejores prcticas
- Ofrece recursos de aprendizaje

---

## Componentes Implementados

### 1. Script de Validacin Mejorado

**archivo**: `scripts/diagnostics/validate-gitflow.ps1`

**Caractersticas**:

- Detecta rama actual automticamente
- Clasifica por tipo (feature, bugfix, chore, hotfix, release)
- Valida nomenclatura de rama
- Calcula base esperada para PR
- Proporciona gua contextual si hay error
- Modo interactivo para crear rama
- Mensajes de error informativos con ejemplos

**Uso**:

```powershell
# Validacin automtica (en pre-push hook)
.\scripts\diagnostics\validate-gitflow.ps1

# Validacin interactiva (con opcin de crear rama)
.\scripts\diagnostics\validate-gitflow.ps1 -Interactive

# Validacin silenciosa
.\scripts\diagnostics\validate-gitflow.ps1 -Quiet
```

---

### 2. Creador de Rama Interactivo

**archivo**: `scripts/utilities/create-gitflow-branch.ps1`

**Caractersticas**:

- Pregunta interactivamente qu tipo de cambio es
- Solicita descripcin del cambio
- Valida y limpia el nombre de rama
- Crea rama desde la base correcta (develop o main)
- Verifica que la rama no exista
- Muestra informacin contextual sobre el tipo
- Proporciona prximos pasos claros
- Explica qu validaciónes se ejecutarn

---

> **Referencia detallada**: [ eferences/detail.md](references/detail.md)
