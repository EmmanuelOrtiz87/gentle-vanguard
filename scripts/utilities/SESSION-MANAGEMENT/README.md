# SESSION-MANAGEMENT

Documentacion operativa del flujo actual de sesiones en Foundation.

## Resumen

El flujo vigente combina autostart, gestion de sesion y aprendizaje post-sesion:

- `session-autostart.cmd` prepara el workspace, hooks, Engram y contexto.
- `session-manager.ps1` crea, inspecciona, limpia y cierra sesiones.
- `post-session-learning.ps1` analiza artefactos de la sesion y persiste resumenes o propuestas en Engram.

## session-manager.ps1

Parámetros reales:

```powershell
-Mode <AutoStart|Manual|Health|End|Cleanup>
-ProjectName <string>
-SessionDir <string>                # default: .\.session
-OrphanMaxAgeHours <int>            # default: 24
-SkipPreCloseValidation
-NoExit
```

Modos:

- `AutoStart`: inicializa una nueva sesión de workspace y ejecuta el arranque asociado.
- `Manual`: crea una nueva sesión sin el flujo completo de autostart.
- `Health`: informa el estado de la sesión más reciente y del directorio de sesiones.
- `End`: cierra la sesion activa mas reciente, guarda metricas y persiste el cierre en Engram.
- `Cleanup`: marca sesiones huerfanas, archiva JSON corruptos y limpia estado antiguo.

Ejemplos:

```powershell
# Inicio manual
pwsh -File .\scripts\utilities\session-manager.ps1 -Mode Manual

# Estado del directorio de sesiones
pwsh -File .\scripts\utilities\session-manager.ps1 -Mode Health

# Cierre sin pre-close validator (util para tests aislados)
pwsh -File .\scripts\utilities\session-manager.ps1 -Mode End -SkipPreCloseValidation

# Limpieza agresiva de huerfanas
pwsh -File .\scripts\utilities\session-manager.ps1 -Mode Cleanup -OrphanMaxAgeHours 1
```

Notas operativas:

- Los inicios y cierres de sesion se guardan en Engram cuando `tools\engram.exe` esta disponible.
- `-NoExit` permite ejecución in-process en Pester y es parte del gate de cobertura real.
- Los JSON corruptos no detienen el script: se ignoran en `Health` y se archivan en `Cleanup`.

## post-session-learning.ps1

Parámetros relevantes:

```powershell
-SessionId <string>
-AutoApplyLow
-ProjectName <string>
-NoExit
```

Comportamiento:

- Lee `scripts/.session/startup-summary.json` cuando existe.
- Analiza commits recientes, cambios y gaps de skills.
- Guarda propuestas en `.local/improvement-proposals/`.
- Persiste en Engram un resumen de aprendizaje o una propuesta searchable por `SessionId`.

Ejemplo:

```powershell
pwsh -File .\scripts\utilities\post-session-learning.ps1 -SessionId "session-YYYY-MM-DD-01"
```

## Validación actual

La cobertura real se valida con Pester `CodeCoverage` sobre workflows declarados en `tests/coverage-config.json`.

Targets actuales:

- `session-manager-critical-workflow`
- `post-session-learning-persistence`
- `session-autostart-critical-workflow`

Comandos útiles:

```powershell
pwsh -File .\scripts\utilities\verify-coverage.ps1
Invoke-Pester .\tests\integration\engram-session-persistence.integration.tests.ps1 -Output Detailed
Invoke-Pester .\tests\integration\post-session-learning.integration.tests.ps1 -Output Detailed
Invoke-Pester .\tests\integration\session-autostart.integration.tests.ps1 -Output Detailed
```
  "prompt_price_unit": "0",
  "prompt_price": "0",
  "completion_tokens": 8096,
  "completion_unit_price": "0",
  "completion_price_unit": "0",
  "completion_price": "0",
  "total_tokens": 41264,
  "total_price": "0",
  "currency": "USD",
  "latency": 49.391,
  "time_to_first_token": 3.304,
  "time_to_generate": 46.087
}
```
