---
created: 2026-07-25 01:04:04
tags: [engram, pattern]
engram_id: 1962
type: pattern
---

# NORMATIVA: execSync en Windows sin || true

**What**: NORMATIVA OBLIGATORIA — NO usar '|| true' en comandos de execSync en Windows. cmd.exe no tiene comando 'true'. En su lugar, capturar stdout del error thrown por execSync cuando el comando sale con código no-zero.

**Why**: pnpm outdated --long || true falla en Windows con "'true' is not recognized as an internal or external command". Esto rompe los security checks del dependency-security-enforcer.

**Where**: src/security/dependency-security-enforcer.ts, y cualquier script que use execSync con pipes.

**Learned**:
- Usar try/catch anidado: try { execSync(cmd) } catch (e) { result = e.stdout?.toString() || e.message }
- NO modificar el comando con || true, || cmd /c exit 0, ni otras variantes.
- El error de execSync contiene stdout, stderr, status — aprovecharlos.

---
*Imported from Engram on 2026-09-06*
