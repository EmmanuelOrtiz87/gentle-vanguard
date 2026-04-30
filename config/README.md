# Configuration Directory

## Descripcin

Directorio centralizado para toda la configuracin del proyecto workspace-foundation.

**Versin**: 2.0.0
**ltima actualizacin**: 2026-04-21
**Estado**:  PRODUCCIN

---

##  Estructura de Directorios

```
config/
 README.md                          # Este archivo
 testing.config.json                # Configuracin de testing
 engram-memory.json                 # Configuracin de Engram Memory
 orchestrator.json                  # Configuracin del Orquestador
 ai-tool-detector.json              # Configuracin de deteccin de herramientas
 dynamic-optimization.json          # Configuracin de optimizacin dinmica
 tool-configs-template.json         # Template de configuracin de herramientas
 security-policy.json               # Polticas de seguridad
 tls-config.json                    # Configuracin TLS/SSL
 cline-dify-optimized.config.json   # Configuracin optimizada Cline-Dify
```

---

##  Archivos de Configuracin

### testing.config.json
**Propsito**: Configuracin de la suite de testing

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
Write-Host "Coverage mnimo: $($config.testCoverage.minimumThreshold)"
```

---

### engram-memory.json
**Propsito**: Configuracin del Engram Memory System

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

**Parmetros clave**:
- `threshold`: Lmite de tokens (250)
- `triggerThreshold`: Nmero de packs para consolidar (5)
- `compressionRatio`: Ratio de compresin (0.65 = 65%)
- `qualityScore`: Puntuacin mnima de calidad (0.91)

---

### orchestrator.json
**Propsito**: Configuracin del Orquestador Universal

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

**Herramientas soportadas**:
- Cline (200,000 tokens)
- Continue (100,000 tokens)
- Cursor (150,000 tokens)
- Copilot (100,000 tokens)

---

### ai-tool-detector.json
**Propsito**: Configuracin de deteccin automtica de herramientas

**Caractersticas**:
- Deteccin automtica de herramientas IA
- Configuracin por herramienta
- Parmetros especficos
- Fallback automtico

---

### dynamic-optimization.json
**Propsito**: Configuracin de optimizacin dinmica

**Mtricas monitoreadas**:
- CPU usage
- Memory usage
- Token usage
- Cache hit rate
- Compression ratio
- Quality score
- Processing time
- Error rate

**Estrategias de optimizacin**:
1. Ajuste de threshold
2. Cambio de ratio de compresin
3. Modificacin de consolidacin
4. Ajuste de cach
5. Rebalanceo de carga

---

### security-policy.json
**Propsito**: Polticas de seguridad

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
**Propsito**: Configuracin TLS/SSL

**Parmetros**:
- Certificados
- Cipher suites
- Validacin de certificados
- HSTS headers
- Versin mnima de TLS

---

##  Cmo Usar Configuraciones

### Cargar configuracin
```powershell
$config = Get-Content .\config\testing.config.json | ConvertFrom-Json
```

### Modificar configuracin
```powershell
$config.testCoverage.minimumThreshold = 0.85
$config | ConvertTo-Json | Set-Content .\config\testing.config.json
```

### Validar configuracin
```powershell
$schema = Get-Content .\config\schema.json | ConvertFrom-Json
# Validar contra schema
```

---

##  Valores por Defecto

### Engram Memory
- Threshold: 250 tokens
- Consolidation trigger: 5 packs
- Compression ratio: 0.65 (65%)
- Quality score: 0.91
- Cache hit rate: 70-80%

### Testing
- Coverage mnimo: 80%
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

##  Configuracin Inicial

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

### 3. Validar configuracin
```powershell
.\scripts\testing\run-tests.ps1 -TestType all
```

---

##  Checklist de Configuracin

- [ ] Revisar `testing.config.json`
- [ ] Revisar `engram-memory.json`
- [ ] Revisar `orchestrator.json`
- [ ] Configurar `security-policy.json`
- [ ] Configurar secretos
- [ ] Ejecutar tests
- [ ] Validar configuracin

---

##  Seguridad

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

##  Documentacin Relacionada

- `docs/guides/SECURITY-HARDENING.md` - Seguridad
- `docs/guides/TESTING-GUIDE.md` - Testing
- `scripts/README.md` - Scripts
- `docs/supplementary/IMPLEMENTATION-COMPLETE.md` - Implementacin

---

##  Troubleshooting

### Problema: Configuracin invlida
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

##  Conclusin

Todos los archivos de configuracin estn centralizados, documentados y listos para usar.

**Estado**:  PRODUCCIN

---

**ltima actualizacin**: 2026-04-21
**Versin**: 2.0.0