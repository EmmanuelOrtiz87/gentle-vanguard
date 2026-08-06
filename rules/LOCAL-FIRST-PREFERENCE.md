# Local-First Preference — Gentle-Vanguard

**Normativa**: `rules/LOCAL-FIRST-PREFERENCE.md`  
**Versión**: 1.0.0  
**Estado**: PREFERENCE (guía flexible, no estricta)  
**Última revisión**: 2026-07-30

---

## 1. Filosofía Core

Gentle-Vanguard evoluciona **hacia adentro, no hacia afuera**.

> **Default**: Mejorar lo existente > Agregar dependencias externas

Este principio guía las decisiones de arquitectura pero **no es una cárcel**. Puede sobreescribirse
con confirmación explícita.

---

## 2. Principios de Evolución

| Principio                  | Descripción                                      |
| -------------------------- | ------------------------------------------------ |
| **Profundidad > Amplitud** | Mejorar componentes existentes vs agregar nuevos |
| **Refinamiento Interno**   | Optimizar lo que ya funciona                     |
| **Auto-suficiencia**       | El stack se mantiene y mejora solo               |
| **Sinergia Local**         | Componentes que se potencian entre sí localmente |

---

## 3. Clasificación de Dependencias

### ✅ **LOCAL-ONLY** (Implementar sin aprobación)

Todo lo que corre 100% en la máquina personal:

- TypeScript/JavaScript local
- SQLite (better-sqlite3)
- WebSocket local (ws)
- File-based storage
- Local processes/scripts
- Local dashboard/UI
- Engram (la única dependencia externa permitida por defecto)

### ⚠️ **EXTERNAL** (Requiere aprobación)

Todo lo que requiere servicios externos:

- Cloud providers (AWS, Azure, GCP)
- APIs externas (OpenAI, Anthropic, etc.)
- SaaS platforms
- Marketplaces (VS Code Extension, etc.)
- Hosted services
- Dependencias npm con llamadas externas

---

## 4. Proceso de Decisión

```
┌─────────────────────────────────────────────┐
│  Nuevo feature o mejora                      │
│       ↓                                     │
│  ¿Requiere dependencia externa?              │
│       ├── NO → Implementar directo ✅        │
│       ↓                                     │
│  ¿Es estrictamente necesario?                │
│       ├── NO → Descartar ❌                │
│       ↓                                     │
│  Agregar a backlog con tag 'requires-approval'
│       ↓                                     │
│  Solicitar confirmación explícita           │
│       ↓                                     │
│  ¿Aprobado?                                  │
│       ├── SI → Proceder ✅                 │
│       └── NO → Mantener en backlog ⏸️      │
└─────────────────────────────────────────────┘
```

---

## 5. Backlog: Clasificación OBLIGATORIA

Todo item debe tener tag:

- `local` - Implementable sin aprobación
- `external-dependency` - Requiere confirmación
- `requires-approval` - Bloqueado hasta aprobación

Ejemplo:

```bash
gv backlog add --title "VS Code Extension" \
  --type requirement \
  --tags "external-dependency,requires-approval,vscode"
```

---

## 6. Normativas Relacionadas

| Normativa                   | Relación                              |
| --------------------------- | ------------------------------------- |
| `AI-NORMATIVES.md`          | Local-First Principle de herramientas |
| `DEVELOPMENT-STANDARDS.md`  | Estándares de código                  |
| `NORMATIVAS-PERFORMANCE.md` | Optimización local                    |

---

## 7. Excepciones y Overrides

Esta normativa puede sobreescribirse en casos específicos siempre que:

1. Se documente la razón
2. Se agregue al backlog como excepción
3. Se obtenga confirmación explícita
4. Se actualice esta normativa si es un patrón recurrente

**Ejemplo de override válido**:

- Contexto: "Necesitamos VS Code Extension para usuario X"
- Razón: "Es el IDE principal del equipo"
- Confirmación: ✅ Sí, proceder
- Acción: Implementar con guardas de local-first fallback

---

## 8. Referencias

- Backlog: `gv backlog list`
- Status: `npm run watchtower:health`
- Decision log: Engram topic `decision/local-first`

---

_Esta normativa es una guía viva. Evoluciona con el proyecto._
