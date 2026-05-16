---
name: gitflow-orchestrator-skill
description: GitFlow workflow validation and branch creation orchestration
trigger: gitflow, git, branch, workflow, git hooks
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

**Uso**:

```powershell
# Interactivo (Recomendado)
.\scripts\utilities\create-gitflow-branch.ps1

# Con parmetros
.\scripts\utilities\create-gitflow-branch.ps1 -Type feature -Description "add-user-auth"

# Silencioso
.\scripts\utilities\create-gitflow-branch.ps1 -Type feature -Description "add-user-auth" -Quiet
```

**Flujo Interactivo**:

1. Detecta rama actual
2. Pregunta tipo de cambio (feature/bugfix/chore/hotfix/release)
3. Muestra informacin sobre el tipo seleccionado
4. Solicita descripcin
5. Valida nomenclatura
6. Crea rama desde base correcta
7. Muestra prximos pasos
8. Explica validaciónes automticas

---

### 3. Hooks de Git Mejorados

**archivo**: `scripts/git-hooks/pre-push`

**Caractersticas**:

- Ejecuta validacin de GitFlow automticamente
- Ejecuta validaciónes de cdigo ()
- Ejecuta validaciónes de governance
- Ejecuta validaciónes de homologation
- Proporciona mensajes claros y accionables
- Sugiere acciones correctivas
- Bloquea push si hay violaciones

**Flujo**:

```
git push

pre-push hook ejecuta:
  1. validate-gitflow.ps1 (valida rama)
  2.  run (valida cdigo)
  3. validate-script-governance.ps1 (valida governance)
  4. homologate-workspace.ps1 (valida homologation)

Si todo OK  push permitido
Si hay error  push bloqueado + mensaje de ayuda
```

---

### 4. Documentacin de Referencia

**archivo**: `docs/guides/GITFLOW-QUICK-REFERENCE.md`

**Contenido**:

- Inicio rpido con comando interactivo
- Flujos estndar paso a paso
- Errores comunes y soluciones
- Mejores prcticas
- Ejemplos de nombres vlidos/invlidos
- Informacin de ramas (main, develop, work branches)
- Flujo completo paso a paso
- Informacin de automatización
- Enlaces a documentacin completa

---

## Flujo de Interaccin Completo

```

 Desarrollador intenta hacer cambios


                    Rama vlida?
                    /           \
                  NO             S


         Pre-Push Hook
         Detecta error



         Muestra Gua
         GitFlow Help



         Ofrece crear rama
         automticamente



         create-gitflow-branch
         .ps1 (Interactivo)




                    Rama vlida?
                    /           \
                  NO             S


         Muestra error
         y gua nuevamente



                          Ejecuta
                          validaciónes:
                           GitFlow
                           Cdigo ()
                           Governance
                           Homologation


                            Todo OK?
                            /         \
                          S           NO


                     PUSH OK     PUSH FAIL

                        Muestra
                                   error y
                                   solucin

```

---

## Rol de Maestro/Tutor

El Orchestrator acta como maestro en los siguientes escenarios:

### Escenario 1: Rama Invlida

```
Desarrollador intenta: git push

Pre-push hook detecta rama invlida

Muestra:
   Branch 'my-changes' does not match allowed GitFlow naming

   RAMA NO VLIDA
  Tu rama debe tener uno de estos prefijos:
     feature/  - para nuevas funcionalidades
     bugfix/   - para correcciónes de bugs
     chore/    - para mantenimiento
     hotfix/   - para fixes crticos
     release/  - para preparacin de release

   SOLUCIN RPIDA:
  1. Crea una rama de trabajo:
     .\scripts\utilities\create-gitflow-branch.ps1

   TIPOS DE RAMA PERMITIDOS:
     feature/*   Nuevas funcionalidades  PR base: develop
     bugfix/*    Correccin de bugs     PR base: develop
     chore/*     Mantenimiento          PR base: develop
     hotfix/*    Fixes crticos         PR base: main
     release/*   Preparacin release    PR base: main

   EJEMPLOS DE NOMBRES VLIDOS:
     feature/add-user-authentication
     bugfix/fix-login-timeout
     chore/update-dependencies
     hotfix/critical-security-patch

Desarrollador ejecuta: .\scripts\utilities\create-gitflow-branch.ps1

Script gua interactivamente:
  1. Qu tipo de cambio es? (1-5)
  2. Describe brevemente el cambio
  3. Crea rama automticamente
  4. Muestra prximos pasos
```

### Escenario 2: Base de PR Incorrecta

```
Desarrollador intenta: git push (desde feature/add-auth)

Pre-push hook valida base esperada

Si PR base es 'main' pero debera ser 'develop':
   PR base 'main' violates GitFlow for branch 'feature/add-auth'
  Expected base: 'develop'

   SOLUCIN:
  1. Cierra el PR actual
  2. Crea nuevo PR con base: develop
  3. O edita el PR y cambia la base
```

### Escenario 3: Primer Uso del Proyecto

```
Desarrollador nuevo ejecuta: .\scripts\utilities\create-gitflow-branch.ps1

Script muestra:

             GitFlow Branch Creator


    Rama actual: main

   Qu tipo de cambio es?
     1) feature  - Nueva funcionalidad
     2) bugfix   - Correccin de bug
     3) chore    - Mantenimiento/actualizacin
     4) hotfix   - Fix crtico en produccin
     5) release  - Preparacin de release

  Selecciona (1-5): 1

   Informacin del tipo seleccionado:
      Uso: Nuevas funcionalidades
      Base esperada: develop
      Ejemplo: feature/add-user-authentication

   Describe brevemente el cambio:
     (usa guiones para separar palabras, ej: add-user-auth)
  Descripcin: add-user-authentication

    Nombre de rama propuesto: feature/add-user-authentication
    Base esperada para PR: develop

   Creando rama...
   Rama 'feature/add-user-authentication' creada exitosamente


             Prximos Pasos


  1  Haz tus cambios en los archivos
     Edita los archivos necesarios para tu cambio

  2  Prepara los cambios
     git add .

  3  Crea un commit
     git commit -m 'descripcin clara del cambio'

  4  Pushea la rama
     git push -u origin feature/add-user-authentication

  5  Abre un Pull Request en GitHub
      Base: develop
      Ttulo: Descripcin clara del cambio
      Descripcin: Explica QU cambi y POR QU

   Informacin de la rama:
     Nombre: feature/add-user-authentication
     Tipo: feature
     Base esperada: develop
     Estado:  Lista para trabajar

   Recuerda:
      Los commits se validarn automticamente (pre-commit hook)
      El push ser validado contra GitFlow (pre-push hook)
      El PR debe tener la base correcta: develop
```

---

## Ciclo de Vida de un Cambio

```
1. CREAR RAMA

   Desarrollador ejecuta:
   .\scripts\utilities\create-gitflow-branch.ps1

   Script gua y crea rama vlida


2. HACER CAMBIOS

   Desarrollador edita archivos


3. COMMIT

   git commit -m "descripcin"

   Pre-commit hook valida:
    Cdigo con
    Polticas de revisión

   Si OK  commit permitido
   Si error  commit bloqueado + gua


4. PUSH

   git push -u origin rama

   Pre-push hook valida:
    GitFlow (rama, base)
    Cdigo ()
    Governance
    Homologation

   Si OK  push permitido
   Si error  push bloqueado + gua


5. PULL REQUEST

   Desarrollador abre PR en GitHub

   validaciónes automticas:
    Base correcta
    Descripcin presente
    Nombre sigue convenciones


6. revisión

   Reviewers validan cdigo


7. MERGE

   Una vez aprobado, mergea PR

   Rama se elimina automticamente


8. COMPLETADO
```

---

## Recursos de Aprendizaje

El Orchestrator proporciona acceso a:

1. **GITFLOW-QUICK-REFERENCE.md**
   - Referencia rpida de flujos
   - Errores comunes y soluciones
   - Mejores prcticas

2. **GITFLOW-ENFORCEMENT-ANALYSIS.md**
   - Anlisis detallado de GitFlow
   - Recomendaciones de mejora
   - Plan de accin

3. **DEVELOPER-COMMUNICATION-POLICY.md**
   - Polticas de desarrollo
   - Estndares de cdigo
   - Convenciones de nombres

4. **Scripts de Validacin**
   - `validate-gitflow.ps1` - Validador de GitFlow
   - `validate-script-governance.ps1` - Validador de governance
   - `homologate-workspace.ps1` - Validador de homologation

---

## Checklist de Implementacin

### Nivel 1 (Inmediato - COMPLETADO )

- Enriquecer mensajes de error en `validate-gitflow.ps1`
- Crear `create-gitflow-branch.ps1` interactivo
- Crear `GITFLOW-QUICK-REFERENCE.md`
- Crear `GITFLOW-ENFORCEMENT-ANALYSIS.md`
- Crear `GitFlow Orchestrator Skill`

### Nivel 2 (Corto Plazo - EN PROGRESO)

- Validar PR base antes de push (en pre-push hook)
- Agregar comando `gv.ps1 gitflow-setup` interactivo
- Integrar GitHub Actions para validacin de PR

### Nivel 3 (Mediano Plazo - PENDIENTE)

- Dashboard de cumplimiento de GitFlow
- Reportes de violaciones
- Mtricas de adherencia

---

## Objetivo Logrado

El **GitFlow Orchestrator Skill** proporciona:

**Validacin Estricta**: Bloquea violaciones de GitFlow automticamente

**Gua Interactiva**: Ofrece crear rama correcta automticamente

**Enseanza**: Explica por qu se rechaz una accin

**Prevencin**: Detecta errores ANTES de que ocurran

**automatización**: Ejecuta validaciónes automticamente en cada paso

El desarrollador ahora tiene un **maestro/tutor** que:

- Lo gua en cada paso del proceso
- Le ensea mejores prcticas
- Lo previene de cometer errores
- Lo ayuda a entender por qu algo fue rechazado
- Lo automatiza tareas repetitivas

