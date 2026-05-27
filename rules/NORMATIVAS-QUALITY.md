# NORMATIVAS-QUALITY.md — Quality Standards & Best Practices

Version: 1.0.0 | Last updated: 2026-05-26 | Status: ACTIVE

---

## 1. PROPOSITO

Definir los estándares de calidad, testing, CI/CD y mejores prácticas para el desarrollo
y mantenimiento del stack Gentle-Vanguard, asegurando que todo el código sea robusto,
mantenible y cumpla con estándares enterprise.

---

## 2. PRINCIPIOS DE CALIDAD

### 2.1 Testing First
- Todo cambio debe incluir tests
- Tests automatizados en CI/CD
- Cobertura mínima: 80%

### 2.2 Code Review
- Todo PR requiere aprobación
- Checklist de calidad obligatorio
- No se permite merge con tests fallidos

### 2.3 Documentación
- Cada script debe tener header con SYNOPSIS
- Cambios deben actualizar documentación
- README actualizado

### 2.4 Observabilidad
- Logging estructurado
- Métricas de performance
- Alertas proactivas

---

## 3. ESTANDARES DE CODIGO

### 3.1 PowerShell

#### Estructura de Archivos
```powershell
#Requires -Version 7.0
<#
.SYNOPSIS
    Breve descripción del script
.DESCRIPTION
    Descripción detallada
.PARAMETER Param1
    Descripción del parámetro
.EXAMPLE
    .\script.ps1 -Param1 valor
.NOTES
    Version: 1.0.0
    Author: Gentle-Vanguard Team
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Param1,
    
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Functions
function Main {
    # Main logic
}

# Execution
Main
```

#### Naming Conventions
- **Functions**: `Verb-Noun` (PascalCase)
- **Variables**: `$camelCase`
- **Constants**: `$UPPER_SNAKE_CASE`
- **Parameters**: PascalCase
- **Private functions**: `Verb-Noun` con prefijo `_`

#### Error Handling
```powershell
try {
    # Operation
} catch [System.Net.WebException] {
    Write-Log "Network error: $_" 'ERROR'
    throw
} catch {
    Write-Log "Unexpected error: $_" 'ERROR'
    throw
} finally {
    # Cleanup
}
```

### 3.2 JavaScript (Dashboard)

#### Estructura
```javascript
// Namespace global
var GV_APP = GV_APP || {};

// Module pattern
GV_APP.Module = (function() {
    // Private
    var _privateVar = '';
    
    function _privateFunction() {
        // Implementation
    }
    
    // Public
    return {
        publicFunction: function() {
            // Implementation
        }
    };
})();

// Event listeners
document.addEventListener('DOMContentLoaded', function() {
    GV_APP.Module.init();
});
```

#### Naming Conventions
- **Variables**: `camelCase`
- **Constants**: `UPPER_SNAKE_CASE`
- **Functions**: `camelCase`
- **Classes**: `PascalCase`
- **Private**: `_prefixed`

#### Error Handling
```javascript
try {
    // Operation
} catch (error) {
    console.error('[GV] Error:', error);
    // Log to error tracking
    GV_APP.ErrorTracker.log(error);
}
```

---

## 4. TESTING

### 4.1 Tipos de Tests

| Tipo | Descripción | Ubicación |
|------|-------------|-----------|
| Unit | Tests de funciones individuales | `tests/unit/` |
| Integration | Tests de integración entre componentes | `tests/integration/` |
| E2E | Tests end-to-end del dashboard | `tests/e2e/` |
| Validation | Validación de estructura y datos | `tests/validation/` |

### 4.2 Test Framework

#### PowerShell: Pester
```powershell
Describe "Dashboard Tests" {
    BeforeAll {
        # Setup
    }
    
    It "Should generate dashboard" {
        & "scripts/metrics/dashboard-render.ps1"
        "reports/dashboard.html" | Should -Exist
    }
    
    AfterAll {
        # Cleanup
    }
}
```

#### JavaScript: Jest
```javascript
describe('Dashboard', () => {
    beforeEach(() => {
        // Setup
    });
    
    test('should render charts', () => {
        const chart = document.getElementById('chartToken');
        expect(chart).toBeTruthy();
    });
});
```

### 4.3 Coverage Requirements

| Component | Cobertura Mínima |
|-----------|------------------|
| Scripts PowerShell | 80% |
| JavaScript Dashboard | 70% |
| API Endpoints | 90% |

---

## 5. CI/CD PIPELINE

### 5.1 GitHub Actions Workflow

```yaml
name: Dashboard CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Tests
        run: .\scripts\tests\dashboard-validator.ps1
      
  deploy:
    needs: validate
    runs-on: windows-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy
        run: .\scripts\metrics\dashboard-render.ps1
```

### 5.2 Pre-commit Hooks

```powershell
# .git/hooks/pre-commit
$files = git diff --cached --name-only
if ($files -match "\.runtime/metrics") {
    Write-Host "ERROR: Metrics files should not be committed" -ForegroundColor Red
    exit 1
}
```

### 5.3 Deployment Gates

| Gate | Requisito |
|------|-----------|
| Build | Tests pasan |
| Security | No secrets expuestos |
| Performance | < 3s load time |
| Accessibility | WCAG 2.1 AA |

---

## 6. MONITOREO Y OBSERVABILIDAD

### 6.1 Métricas Clave

| Métrica | Target | Alerta |
|---------|--------|--------|
| Dashboard Load Time | < 2s | > 3s |
| API Response Time | < 500ms | > 1s |
| Error Rate | < 0.1% | > 1% |
| Uptime | 99.9% | < 99% |

### 6.2 Logging

#### Niveles
- **ERROR**: Errores críticos
- **WARN**: Advertencias
- **INFO**: Información general
- **DEBUG**: Debug detallado

#### Formato
```
[2026-05-26 14:30:00] [ERROR] [Component] Message
```

### 6.3 Alertas

| Condición | Severidad | Canal |
|-----------|-----------|-------|
| Dashboard down | CRITICAL | Email + Slack |
| Error rate > 1% | HIGH | Slack |
| Load time > 3s | MEDIUM | Dashboard |
| Stale metrics | LOW | Log |

---

## 7. SEGURIDAD

### 7.1 Data Protection

- No commitear datos sensibles
- Usar variables de entorno para secrets
- Encriptar datos en reposo cuando sea necesario
- Sanitizar inputs

### 7.2 Secrets Management

```powershell
# .env.example (no commitear .env)
API_KEY=your_api_key_here
WEBHOOK_URL=https://hooks.slack.com/...
```

### 7.3 Security Scanning

- GitHub Advanced Security
- Secret scanning habilitado
- Dependency review
- CodeQL analysis

---

## 8. PERFORMANCE

### 8.1 Targets

| Métrica | Target |
|---------|--------|
| First Contentful Paint | < 1.5s |
| Time to Interactive | < 3s |
| Largest Contentful Paint | < 2.5s |
| Cumulative Layout Shift | < 0.1 |

### 8.2 Optimizaciones

- Lazy loading de secciones
- Caching con Service Worker
- Minificación de assets
- Compresión gzip
- CDN para assets estáticos

---

## 9. ACCESIBILIDAD

### 9.1 WCAG 2.1 AA Requirements

- Contraste mínimo 4.5:1
- Navegación por teclado
- ARIA labels
- Alt text para imágenes
- Focus indicators visibles

### 9.2 Testing

```bash
# Lighthouse CI
lighthouse https://localhost:8090 --preset=desktop
```

---

## 10. DOCUMENTACION

### 10.1 Estructura

```
docs/
├── ARCHITECTURE.md      # Arquitectura del sistema
├── API.md              # Documentación de API
├── DEPLOYMENT.md       # Guía de deployment
├── TROUBLESHOOTING.md  # Guía de troubleshooting
└── CHANGELOG.md        # Historial de cambios
```

### 10.2 Comentarios

#### PowerShell
```powershell
<#
.SYNOPSIS
    One-line description
.DESCRIPTION
    Detailed description
.PARAMETER Name
    Parameter description
.EXAMPLE
    Example usage
#>
```

#### JavaScript
```javascript
/**
 * Description of function
 * @param {string} param1 - Description
 * @param {number} param2 - Description
 * @returns {boolean} Description
 */
function example(param1, param2) {
    // Implementation
}
```

---

## 11. CHECKLIST DE CALIDAD

### Pre-commit
- [ ] Tests pasan
- [ ] No secrets expuestos
- [ ] Documentación actualizada
- [ ] Código formateado

### Pre-merge
- [ ] Code review aprobado
- [ ] CI/CD verde
- [ ] Coverage >= 80%
- [ ] Performance validada
- [ ] Accesibilidad verificada

### Pre-release
- [ ] Changelog actualizado
- [ ] Versión bump
- [ ] Tag creado
- [ ] Release notes escritas

---

## 12. HERRAMIENTAS RECOMENDADAS

| Categoría | Herramienta |
|-----------|-------------|
| Testing | Pester, Jest, Playwright |
| Linting | PSScriptAnalyzer, ESLint |
| Coverage | CodeCov, Coveralls |
| Security | GitHub Advanced Security, Snyk |
| Performance | Lighthouse, WebPageTest |
| Monitoring | Application Insights, Datadog |

---

_Version: 1.0.0 — Status: ACTIVE_
