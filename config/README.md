# Configuration Directory

## Descripción

Directorio centralizado para toda la configuración del proyecto workspace-foundation.

**Versión**: 2.0.0 **última actualización**: 2026-04-21 **Estado**: PRODUCCIÓN

---

## Estructura de Directorios

```
config/
 README.md                          # Este archivo
 testing.config.json                # Configuración de testing
 engram-memory.json                 # Configuración de Engram Memory
 orchestrator.json                  # Configuración del Orquestador
 ai-tool-detector.json              # Configuración de detección de herramientas
 dynamic-optimization.json          # Configuración de optimización dinmica
 tool-configs-template.json         # Template de configuración de herramientas
 security-policy.json               # Polticas de seguridad
 tls-config.json                    # Configuración TLS/SSL
 cline-dify-optimized.config.json   # Configuración optimizada Cline-Dify
```

---

## Archivos de Configuración

### testing.config.json

**Propósito**: Configuración de la suite de testing

**Secciones principales**:

```json
{
  "version": "1.0.0",
  "testFramework": "pester",
  "testCoverage": {
    "minimumThreshold": 0.80,
    "targetThreshold": 0.90
  },
  "testTypes": {
    "unit": { ... },
    "integration": { ... },
    "performance": { ... },
    "security": { ... }
  },
  "cicd": {
    "runOnCommit": true,
    "runOnPR": true,
    "failOnCoverageLow": true
  }
}
```

**Uso**:

```powershell
$config = Get-Content .\config\testing.config.json | ConvertFrom-Json
Write-Host "Coverage mínimo: $($config.testCoverage.minimumThreshold)"
```

---

### engram-memory.json

**Propósito**: Configuración del Engram Memory System

**Secciones principales**:

```json
{
  "version": "2.0.0",
  "phases": {
    "phase1": {
      "threshold": 250,
      "description": "Pack creation"
    },
    "phase2": {
      "description": "Trigger system"
    },
    "phase3": {
      "description": "Advanced optimization"
    }
  },
  "consolidation": {
    "triggerThreshold": 5,
    "compressionRatio": 0.65
  }
}
```

**Parámetros clave**:

- `threshold`: Lmite de tokens (250)
- `triggerThreshold`: Nmero de packs para consolidar (5)
- `compressionRatio`: Ratio de compresión (0.65 = 65%)
- `qualityScore`: Puntuacin mnima de calidad (0.91)

---

### orchestrator.json

**Propósito**: Configuración del Orquestador Universal

**Secciones principales**:

```json
{
  "orchestration": {
    "aiToolDetection": {
      "enabled": true,
      "autoDetect": true
    }
  },
  "tools": {
    "cline": { ... },
    "continue": { ... },
    "cursor": { ... }
  },
  "rules": { ... }
}
```

**herramientas soportadas**:

- Cline (200,000 tokens)
- Continue (100,000 tokens)
- Cursor (150,000 tokens)
- Copilot (100,000 tokens)

---

### ai-tool-detector.json

**Propósito**: Configuración de detección automática de herramientas

**Caractersticas**:

- Detección automática de herramientas IA
- Configuración por herramienta
- Parámetros especficos
- Fallback automático

---

### dynamic-optimization.json

**Propósito**: Configuración de optimización dinámica

**Métricas monitoreadas**:

- CPU usage
- Memory usage
- Token usage
- Cache hit rate
- Compression ratio
- Quality score
- Processing time
- Error rate

**Estrategias de optimización**:

1. Ajuste de threshold
2. Cambio de ratio de compresión
3. Modificacin de consolidacin
4. Ajuste de cach
5. Rebalanceo de carga

---

### security-policy.json

**Propósito**: Configuración de políticas de seguridad

**Secciones**:

```json
{
  "encryption": {
    "algorithm": "AES-256",
    "keyLength": 256,
    "mode": "CBC"
  },
  "validation": {
    "maxStringLength": 10000,
    "maxIntegerValue": 10000
  },
  "secrets": {
    "rotationInterval": 90,
    "requiredSecrets": ["API_KEY", "ENCRYPTION_KEY"]
  },
  "logging": {
    "enabled": true,
    "retentionDays": 90,
    "auditTrail": true
  }
}
```

---

### tls-config.json

**Propsito**: Configuración TLS/SSL

**Parámetros**:

- Certificados
- Cipher suites
- Validación de certificados
- HSTS headers
- Versión mínima de TLS

---

## Cmo Usar configuraciónes

### Cargar configuración

```powershell
$config = Get-Content .\config\testing.config.json | ConvertFrom-Json
```

### Modificar configuración

```powershell
$config.testCoverage.minimumThreshold = 0.85
$config | ConvertTo-Json | Set-Content .\config\testing.config.json
```

### Validar configuración

```powershell
$schema = Get-Content .\config\schema.json | ConvertFrom-Json
# Validar contra schema
```

---

## Valores por Defecto

### Engram Memory

- Threshold: 250 tokens
- Consolidation trigger: 5 packs
- Compression ratio: 0.65 (65%)
- Quality score: 0.91
- Cache hit rate: 70-80%

### Testing

- Coverage mínimo: 80%
- Coverage target: 90%
- Timeout unit tests: 30s
- Timeout integration: 60s
- Timeout performance: 120s

### Seguridad

- Algoritmo: AES-256
- Key length: 256 bits
- Mode: CBC
- Padding: PKCS7
- Rotation interval: 90 das

---

## Configuración Inicial

### 1. Copiar templates

```bash
cp config/tool-configs-template.json config/tool-configs.json
```

### 2. Personalizar valores

```powershell
$config = Get-Content .\config\engram-memory.json | ConvertFrom-Json
$config.phases.phase1.threshold = 300  # Aumentar threshold
$config | ConvertTo-Json | Set-Content .\config\engram-memory.json
```

### 3. Validar configuración

```powershell
.\scripts\testing\run-tests.ps1 -TestType all
```

---

## Checklist de Configuración

- [ ] Revisar `testing.config.json`
- [ ] Revisar `engram-memory.json`
- [ ] Revisar `orchestrator.json`
- [ ] Configurar `security-policy.json`
- [ ] Configurar secretos
- [ ] Ejecutar tests
- [ ] Validar configuración

---

## Seguridad

### Archivos Sensibles

- `.secrets` - NO incluir en git
- `*.key` - NO incluir en git
- `credentials.json` - NO incluir en git

### Proteccin

```bash
# Agregar a .gitignore
echo ".secrets" >> .gitignore
echo "*.key" >> .gitignore
echo "credentials.json" >> .gitignore
```

---

## Documentacin Relacionada

- `docs/guides/SECURITY-HARDENING.md` - Seguridad
- `docs/guides/TESTING-GUIDE.md` - Testing
- `scripts/README.md` - Scripts
- `docs/supplementary/IMPLEMENTATION-COMPLETE.md` - Implementación

---

## Troubleshooting

### Problema: Configuración inválida

**Solucin**: Validar JSON

```powershell
$config = Get-Content .\config\testing.config.json | ConvertFrom-Json
```

### Problema: Valores por defecto no funcionan

**Solucin**: Revisar `engram-memory.json`

```powershell
$config = Get-Content .\config\engram-memory.json | ConvertFrom-Json
$config | ConvertTo-Json -Depth 10
```

---

## Conclusin

Todos los archivos de configuración estn centralizados, documentados y listos para usar.

**Estado**: PRODUCCIÓN

---

**última actualización**: 2026-04-21 **Versión**: 2.0.0
