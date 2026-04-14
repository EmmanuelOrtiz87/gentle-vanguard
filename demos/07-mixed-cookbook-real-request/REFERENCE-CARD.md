# Reference Card — Demo 07 Mixed Cookbook

**Workspace:** `C:\Workspace_local\workspace-foundation`
**Proyecto demo:** `demos/shared/task-tracker/`

---

## Comandos por Segmento

### Preflight opcional (si vas a mostrar Engram)
```powershell
./scripts/utilities/wf.ps1 install-engram
```

### Apertura
```powershell
./scripts/utilities/wf.ps1 status
```

### Orquestador
```powershell
./scripts/utilities/orchestrator-next-steps.ps1
./scripts/utilities/wf.ps1 response-mode list
```

### Tokens
```powershell
./scripts/utilities/response-mode-efficiency-matrix.ps1
./scripts/utilities/response-mode-efficiency-matrix.ps1 -AsCsv
```

### Implementación
```powershell
cd demos/shared/task-tracker
go run . add --title "prepare standup notes"
go run . list
go run . done --id 1
go run . stats
cd ../../..
```

### Engram
```powershell
./scripts/utilities/run-engram.ps1 --help
```

### Review / Audit
```powershell
./scripts/utilities/generate-session-review.ps1
./scripts/utilities/generate-audit-report.ps1 -Period weekly
```

### Cierre
```powershell
./scripts/utilities/wf.ps1 end-session demo-task-tracker
```

---

## Ejes de Comunicación Activos

| Eje       | Valor activo |
|-----------|:------------:|
| Idioma    | `es`         |
| Detalle   | `executive`  |
| Perfil    | `lite`       |
| Preset    | `bugfix`     |
| Auto-apply| `true`       |

---

## Tiempos

| Versión       | Duración |
|---------------|:--------:|
| Solo ejecutiva | 5 min   |
| Completa (dev) | 15 min  |

---

## Checklist Pre-Demo

- [ ] `wf.ps1 status` responde sin error
- [ ] `go version` disponible en PATH
- [ ] `tasks.json` eliminado si hubo corrida previa
- [ ] Repo limpio (`git status` sin cambios)
