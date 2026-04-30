# Scripts Directory

## Descripcin

Directorio centralizado para todos los scripts del proyecto workspace-foundation.

**Versin**: 2.0.0
**ltima actualizacin**: 2026-04-21
**Estado**:  PRODUCCIN

---

##  Estructura de Directorios

```
scripts/
 README.md                          # Este archivo
 common/                            # Funciones compartidas
    platform-helpers.ps1           # Helpers multiplataforma
 testing/                           # Scripts de testing
    run-tests.ps1                  # Test runner principal
    git-hooks-setup.ps1            # Configuracin de git hooks
    pre-test.ps1                   # Hook pre-test
    post-test.ps1                  # Hook post-test
    on-failure.ps1                 # Hook en caso de fallo
 security/                          # Scripts de seguridad
    encryption-manager.ps1         # Gestin de encriptacin AES-256
    input-validator.ps1            # Validacin de entrada
    secrets-manager.ps1            # Gestin de secretos
    security-logger.ps1            # Logging de seguridad
 monitoring/                        # Scripts de monitoreo
    health-check.ps1               # Verificacin de salud
 utilities/                         # Scripts utilitarios
     setup.ps1                      # Setup inicial
     cleanup.ps1                    # Limpieza
```

---

##  Scripts Disponibles

### Common (Funciones Compartidas)

#### platform-helpers.ps1
**Propsito**: Proporciona funciones de compatibilidad multiplataforma

**Funciones principales**:
- `Get-OSType` - Detecta el sistema operativo
- `Get-SafePath` - Crea rutas agnsticas
- `Get-UserHome` - Obtiene directorio del usuario
- `Write-Log` - Logging con timestamp
- `Set-ExecutablePermission` - Permisos ejecutables

**Uso**:
```powershell
. .\scripts\common\platform-helpers.ps1
$osType = Get-OSType
$safePath = Get-SafePath @(".", "config", "test.json")
Write-Log "Mensaje" "info"
```

---

### Testing (Scripts de Testing)

#### run-tests.ps1
**Propsito**: Ejecutor principal de tests

**Parmetros**:
- `-TestType` (all, unit, integration, performance, security)
- `-GenerateReport` (genera reportes)
- `-FailOnLowCoverage` (falla si coverage bajo)

**Uso**:
```powershell
.\scripts\testing\run-tests.ps1 -TestType all -GenerateReport
```

**Salida**:
- Reportes en `test-results/`
- Cobertura en `coverage/`

---

#### git-hooks-setup.ps1
**Propsito**: Configura git hooks automticamente

**Hooks configurados**:
- Pre-commit: Ejecuta unit tests
- Pre-push: Ejecuta todos los tests

**Uso**:
```powershell
.\scripts\testing\git-hooks-setup.ps1
```

---

### Security (Scripts de Seguridad)

#### encryption-manager.ps1
**Propsito**: Gestin de encriptacin AES-256

**Acciones**:
- `generate-key` - Genera clave de 256-bit
- `encrypt` - Encripta datos
- `decrypt` - Desencripta datos
- `validate` - Valida configuracin

**Uso**:
```powershell
# Generar clave
.\scripts\security\encryption-manager.ps1 -Action generate-key

# Encriptar
.\scripts\security\encryption-manager.ps1 -Action encrypt -Data "sensitive"

# Validar
.\scripts\security\encryption-manager.ps1 -Action validate
```

---

#### input-validator.ps1
**Propsito**: Validacin y sanitizacin de entrada

**Tipos de validacin**:
- `string` - Strings con lmites
- `integer` - Nmeros enteros
- `path` - Rutas seguras
- `command` - Comandos sin inyeccin
- `email` - Emails vlidos

**Uso**:
```powershell
.\scripts\security\input-validator.ps1 -Input "test" -Type string
.\scripts\security\input-validator.ps1 -Input ".\config\test.json" -Type path
```

---

#### secrets-manager.ps1
**Propsito**: Gestin segura de secretos

**Acciones**:
- `get` - Obtiene secreto
- `set` - Establece secreto
- `delete` - Elimina secreto
- `list` - Lista secretos
- `rotate` - Rota secretos
- `validate` - Valida configuracin

**Uso**:
```powershell
# Establecer
.\scripts\security\secrets-manager.ps1 -Action set -SecretName "API_KEY" -SecretValue "secret123"

# Obtener
.\scripts\security\secrets-manager.ps1 -Action get -SecretName "API_KEY"

# Listar
.\scripts\security\secrets-manager.ps1 -Action list

# Rotar
.\scripts\security\secrets-manager.ps1 -Action rotate
```

---

#### security-logger.ps1
**Propsito**: Logging y auditora de seguridad

**Tipos de eventos**:
- `access` - Acceso a recursos
- `modification` - Cambios
- `deletion` - Eliminaciones
- `error` - Errores
- `warning` - Advertencias
- `info` - Informacin

**Uso**:
```powershell
# Registrar evento
.\scripts\security\security-logger.ps1 -EventType access -Message "User accessed config" -Severity low

# Generar reporte
.\scripts\security\security-logger.ps1 -Action report

# Detectar anomalas
.\scripts\security\security-logger.ps1 -Action anomalies
```

---

### Monitoring (Scripts de Monitoreo)

#### health-check.ps1
**Propsito**: Verificacin de salud del sistema

**Verifica**:
- Estado de Engram
- Disponibilidad de recursos
- Integridad de datos
- Configuracin

---

### Utilities (Scripts Utilitarios)

#### setup.ps1
**Propsito**: Setup inicial del proyecto

**Realiza**:
- Creacin de directorios
- Instalacin de dependencias
- Configuracin inicial
- Validacin de requisitos

---

#### cleanup.ps1
**Propsito**: Limpieza del proyecto

**Limpia**:
- Archivos temporales
- Logs antiguos
- Cach
- Archivos de build

---

#### simplify-text.ps1
**Propsito**: Simplificacin de texto para eficiencia de tokens

**Transformaciones**:
- Normaliza whitespace (tabs, saltos mltiples)
- Remueve ruido de markdown (negrita, links, headers)
- Abbrevia frases comunes ("por favor"  "pls", "es importante"  "imp")
- Remueve frases redundantes ("en conclusion", "por ultimo")
- Deduplica palabras consecutivas

**Uso**:
```powershell
.\scripts\utilities\simplify-text.ps1 -InputText "Hola! Buenos dias, por favor necesito tu ayuda!"
.\scripts\utilities\wf.ps1 simplify-text "texto a simplificar"
.\scripts\utilities\simplify-text.ps1 -InputFile "archivo.md" -OutputFile "resultado.txt"
```

**Mtricas**: Guarda reduccin en `docs/sessions/metrics/text-simplification.csv`

**Resultado tpico**: 15-25% reduccin en caracteres (~5-10 tokens ahorrados)

---

##  Requisitos

### Mnimos
- PowerShell 7.0+
- .NET 6.0+
- Pester (para tests)

### Recomendados
- PowerShell 7.4+
- .NET 8.0+
- Git 2.40+

---

##  Compatibilidad

### Sistemas Operativos
-  Windows 10/11
-  Linux (Ubuntu, CentOS, etc.)
-  macOS 11+

### Shells
-  PowerShell 7+
-  Bash 5+
-  Zsh

---

##  Seguridad

### Mejores Prcticas
1. **Nunca hardcodear secretos**
   - Usar `secrets-manager.ps1`
   - Usar variables de entorno

2. **Validar siempre entrada**
   - Usar `input-validator.ps1`
   - Validar tipos y rangos

3. **Encriptar datos sensibles**
   - Usar `encryption-manager.ps1`
   - AES-256 CBC

4. **Registrar eventos**
   - Usar `security-logger.ps1`
   - Auditora completa

---

##  Ejemplos de Uso

### Ejecutar Tests Completos
```powershell
cd workspace-foundation
.\scripts\testing\run-tests.ps1 -TestType all -GenerateReport
```

### Configurar Git Hooks
```powershell
.\scripts\testing\git-hooks-setup.ps1
```

### Encriptar Datos
```powershell
.\scripts\security\encryption-manager.ps1 -Action generate-key
$encrypted = .\scripts\security\encryption-manager.ps1 -Action encrypt -Data "sensitive"
```

### Validar Entrada
```powershell
.\scripts\security\input-validator.ps1 -Input "user@example.com" -Type email
```

### Gestionar Secretos
```powershell
.\scripts\security\secrets-manager.ps1 -Action set -SecretName "DB_PASSWORD" -SecretValue "pass123"
.\scripts\security\secrets-manager.ps1 -Action rotate
```

---

##  Troubleshooting

### Problema: Script no ejecuta
**Solucin**: Verificar permisos de ejecucin
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Problema: Rutas no funcionan
**Solucin**: Usar `platform-helpers.ps1`
```powershell
. .\scripts\common\platform-helpers.ps1
$path = Get-SafePath @(".", "config", "test.json")
```

### Problema: Tests fallan
**Solucin**: Verificar Pester instalado
```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck
```

---

##  Documentacin Relacionada

- `docs/guides/TESTING-GUIDE.md` - Gua de testing
- `docs/guides/SECURITY-HARDENING.md` - Gua de seguridad
- `docs/supplementary/IMPLEMENTATION-COMPLETE.md` - Implementacin completa
- `config/README.md` - Configuracin

---

##  Notas

- Todos los scripts son agnsticos de plataforma
- Compatibles con PowerShell 7+
- Logging automtico en todos los scripts
- Manejo de errores robusto
- Documentacin inline completa

---

##  Checklist de Uso

- [ ] Instalar PowerShell 7+
- [ ] Clonar repositorio
- [ ] Ejecutar `setup.ps1`
- [ ] Configurar git hooks
- [ ] Ejecutar tests
- [ ] Revisar documentacin
- [ ] Configurar secretos
- [ ] Iniciar desarrollo

---

##  Soporte

Para reportar problemas o sugerencias:
1. Revisar documentacin
2. Ejecutar `health-check.ps1`
3. Revisar logs en `logs/`
4. Crear issue en GitHub

---

**ltima actualizacin**: 2026-04-21
**Versin**: 2.0.0
**Estado**:  PRODUCCIN