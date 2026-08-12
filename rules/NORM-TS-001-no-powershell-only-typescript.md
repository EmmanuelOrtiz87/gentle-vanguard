# NORMATIVA: STACK TYPE-ONLY

# Gentle-Vanguard Architecture Decision

**Título**: Prohibición de Scripts PowerShell - Stack TypeScript-Nativo **ID**: NORM-TS-001
**Fecha**: 2026-08-10 **Estado**: Active **Categoría**: Architecture

---

## Resumen Ejecutivo

**Normativa**: Todo el código del proyecto Gentle-Vanguard debe ser TypeScript nativo. **Queda
estrictamente prohibido crear o mantener scripts .ps1 (PowerShell).**

**Contexto**: Esta normativa reemplaza cualquier práctica anterior que permitiera scripts
PowerShell.

---

## Motivación

### 1. Consistencia de Stack

```
ANTES: PS1 (legacy) + TS (nuevo) = Duplicación, confusión
DESPUÉS: TS-only = Single source of truth
```

### 2. Cross-Platform

- ✅ TypeScript: Windows, macOS, Linux nativo
- ❌ PowerShell: Windows primario, macOS/Linux con limitaciones

### 3. Type-Safety

- ✅ Compilación-time errors
- ✅ Autocomplete y IntelliSense
- ✅ Refactoring seguro

### 4. Ecosistema

- ✅ Acceso completo a npm
- ✅ Testing con vitest/jest
- ✅ Linting con ESLint

### 5. Mantenibilidad

- Un solo lenguaje en todo el proyecto
- Menor curva de aprendizaje
- Documentación unificada

---

## Reglas Específicas

### ❌ PROHIBIDO (Nunca permitido)

1. **Crear archivos .ps1 nuevos**

   ```
   ❌ archivo.ps1
   ❌ script-helper.ps1
   ❌ deploy.ps1
   ```

2. **Modificar archivos .ps1 existentes**
   - Si existe legacy: migrar a TS primero
   - No parches temporales

3. **Mezclar PS1 y TS para la misma funcionalidad**
   - Elegir uno y migrar el otro

### ✅ REQUERIDO (Siempre usar)

1. **Todo script debe ser .ts**

   ```
   ✅ archivo.ts
   ✅ script-helper.ts
   ✅ deploy.ts
   ```

2. **CRonjobs con node/tsx**

   ```
   # Antes (prohibido)
   * * * * * scripts/task.ps1

   # Después (requerido)
   * * * * * npx tsx src/task.ts
   ```

3. **Git hooks en TypeScript**

   ```json
   // package.json
   "husky": {
     "hooks": {
       "pre-commit": "npx tsx src/hooks/pre-commit.ts"
     }
   }
   ```

4. **Scripts CLI con shebang**

   ```typescript
   #!/usr/bin/env node
   // src/my-script.ts
   ```

---

## Proceso de Migración

### Si encuentras .ps1 legacy:

```bash
# 1. Identificar
find . -name "*.ps1" -type f

# 2. Crear ticket de migración
# Etiqueta: "migration-ps1-ts"

# 3. Migrar siguiendo el patrón
```

### Patrón de Migración PS1 → TS

#### PowerShell:

```powershell
# ❌ ANTES: deploy.ps1
param([string]$Platform)
Write-Host "Deploying to $Platform"
```

#### TypeScript:

```typescript
// ✅ DESPUÉS: src/deploy.ts
#!/usr/bin/env node
import { parseArgs } from 'util';

const { values } = parseArgs({
  args: process.argv.slice(2),
  options: { platform: { type: 'string' } }
});

console.log(`Deploying to ${values.platform}`);
```

#### Package.json (scripts):

```json
{
  "scripts": {
    "deploy": "tsx src/deploy.ts",
    "deploy:prod": "tsx src/deploy.ts --platform=production"
  }
}
```

---

## Validación Automática

### Pre-commit hook:

```yaml
# .lefthook.yml
pre-commit:
  commands:
    check-ps1:
      run: |
        if git diff --cached --name-only | grep -E '\.ps1$'; then
          echo "❌ ERROR: .ps1 files detected! Convert to TypeScript first."
          exit 1
        fi
```

### CI/CD Check:

```yaml
# .github/workflows/check-ts-only.yml
jobs:
  check-ps1:
    steps:
      - name: Check for PS1 files
        run: |
          if find . -name "*.ps1" -type f | grep -q .; then
            echo "❌ Found .ps1 files. Must be converted to TS:"
            find . -name "*.ps1" -type f
            exit 1
          fi
```

---

## Excepciones (Solo con aprobación)

Ninguna excepción permitida.

Si crees que necesitas una excepción, debes:

1. Documentar el caso de uso
2. Proponer alternativa TS
3. Obtener aprobación de 2+ maintainers

---

## Ejemplos de Conversión

### Ejemplo 1: File Operations

```powershell
# ❌ ANTES
Get-ChildItem -Recurse *.ts | Where-Object { $_.Length -gt 1000 }
```

```typescript
// ✅ DESPUÉS
import { readdirSync, statSync } from 'fs';
import { join } from 'path';

function findLargeFiles(dir: string, minSize: number): string[] {
  return readdirSync(dir, { recursive: true })
    .filter((f) => f.endsWith('.ts'))
    .filter((f) => statSync(join(dir, f)).size > minSize);
}
```

### Ejemplo 2: HTTP Requests

```powershell
# ❌ ANTES
Invoke-RestMethod -Uri "https://api.example.com/data" -Method GET
```

```typescript
// ✅ DESPUÉS
import { fetch } from 'undici';

const response = await fetch('https://api.example.com/data');
const data = await response.json();
```

### Ejemplo 3: Environment Variables

```powershell
# ❌ ANTES
$env:NODE_ENV = "production"
```

```typescript
// ✅ DESPUÉS
import { config } from 'dotenv';
config();
process.env.NODE_ENV = 'production';
```

---

## Comandos de Referencia

### Ejecutar script TS:

```bash
# Desarrollo
npx tsx src/script.ts

# Producción (compilado)
npm run build
node dist/script.js

# Con argumentos
npx tsx src/script.ts --env=prod --verbose

# Con watch
npx tsx watch src/script.ts
```

---

## Consecuencias de Incumplimiento

- PRs con .ps1 serán rechazados automáticamente
- Commits con .ps1 fallarán en CI
- No se mergeará a main con código PS1

---

## Historial

| Fecha      | Autor                | Cambio            |
| ---------- | -------------------- | ----------------- |
| 2026-08-10 | Gentle-Vanguard Team | Normativa inicial |

---

**¿Preguntas?** Consulta al equipo o revisa ejemplos en `src/`.

**Aprobado por**: Gentle-Vanguard Architecture Committee **Revisado**: 2026-08-10 **Próxima
revisión**: 2027-01-01
