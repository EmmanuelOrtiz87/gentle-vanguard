# Reference Card Demo 07 Mixed Cookbook

**Workspace:** `.\gentle-vanguard` **Proyecto demo:** `demos/shared/task-tracker/`

---

## Comandos por Segmento

### Preflight (REQUIRED - ejecutar primero)

```powershell
./demos/07-mixed-cookbook-real-request/preflight.ps1
```

### Apertura

```powershell
./scripts/utilities/gv.ps1 status
```

### Orquestador

```powershell
./scripts/utilities/orchestrator-next-steps.ps1
./scripts/utilities/gv.ps1 response-mode list
```

### Tokens

```powershell
./scripts/utilities/response-mode-efficiency-matrix.ps1
./scripts/utilities/response-mode-efficiency-matrix.ps1 -AsCsv
```

### Implementacin

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
./scripts/utilities/gv.ps1 end-session demo-task-tracker
```

---

## Ejes de Comunicacin Activos

| Eje        | Valor activo |
| ---------- | :----------: |
| Idioma     |     `es`     |
| Detalle    | `executive`  |
| Perfil     |    `lite`    |
| Preset     |   `bugfix`   |
| Auto-apply |    `true`    |

---

## Tiempos

| Versin         | Duracin |
| -------------- | :-----: |
| Solo ejecutiva |  5 min  |
| Completa (dev) | 15 min  |

---

## Checklist Pre-Demo

- [ ] `gv.ps1 status` responde sin error
- [ ] `go version` disponible en PATH
- [ ] `tasks.json` eliminado si hubo corrida previa
- [ ] Repo limpio (`git status` sin cambios)
