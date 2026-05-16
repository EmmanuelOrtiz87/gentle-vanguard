# Session Handoff Protocol

## Standard Flow

```mermaid
flowchart LR
    A[Session Active] --> B{Context >60%?}
    B -->|No| C[Continue Working]
    B -->|Yes| D[Run compact-start]
    D --> E[Copy compact prompt]
    E --> F[Open new thread]
    F --> G[Paste prompt + continue]
```

## Steps

### 1. Pre-Handoff

```powershell
# Save session state
gv end-session

# Generate context pack
gentle-vanguard context-pack "objective"

# Generate compact prompt
gv compact-start "objective"
```

### 2. Start New Session

```powershell
# From new thread: paste compact prompt
# Then run:
gv start-session
```

### 3. Intra-Session Context Pack

```powershell
# Mid-session snapshot
gentle-vanguard context-pack "current objective"
```

## Marker Protocol

The `.session/.compact-marker` file prevents duplicate compact-start runs:

```
1. User runs "gv compact-start" → writes marker + timestamp
2. Auto-trigger fires (LiveAssist) → checks marker → skips if <60min
3. User runs "gv start-session" → start-session.ps1 checks marker → skips if <60min
```

**Result**: compact-start runs at most once per 60 min regardless of trigger source.


