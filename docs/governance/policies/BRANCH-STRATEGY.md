# Branch Strategy — Gentle-Vanguard

## Convention

```
main        ──► release-ready, tagged (vX.Y.Z)
develop     ──► integration branch for next release
feature/*   ──► new features, branched from develop
fix/*       ──► bug fixes, branched from develop
hotfix/*    ──► urgent fixes, branched from main, merged to both
chore/*     ──► tooling/config/maintenance, branched from develop
```

## Flow

1. **Feature/fix/chore**: branch from `develop` → PR to `develop`
2. **Release**: `develop` merges to `main` → tag `vX.Y.Z`
3. **Hotfix**: branch from `main` → PR to `main` **and** `develop`
4. **Pre-release tags**: `vX.Y.Z-alpha.N`, `vX.Y.Z-beta.N` on `develop`

## Public repo sync (`gentle-vanguard-public`)

- After each `main` merge, sync via `scripts/sync-public.ps1`

<!-- REF-OBSOLETA: scripts/sync-public.ps1 no tiene equivalente TS (migración PS1→TS) -->

- Public mirror gets squashed commits — no feature/\* branches

## CI triggers

| Branch      | Events        |
| ----------- | ------------- |
| `main`      | PR only       |
| `develop`   | push + PR     |
| `feature/*` | PR to develop |
| `hotfix/*`  | PR to main    |

## Version file

`VERSION` at repo root — bumped on `develop` before release.
