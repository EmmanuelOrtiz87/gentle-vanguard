# Adaptive Rules - Learned Norms

This directory contains norms learned autonomously by the **Auto-Norm-Learner** system.

## Structure

```
rules/adaptive/
 README.md              (this file)
 LEARNED-NORMS.md      (master index of all learned norms)
 docs-placement/       (documentation location norms)
    DOC-001.md
    DOC-002.md
 auto-correction/       (automatic correction patterns)
    CORR-001.md
    CORR-002.md
 session-patterns/      (session behavior norms)
     SESS-001.md
     SESS-002.md
```

## Norm Types

### DOC-### (Documentation Placement)
Rules about where documentation should be stored, naming conventions, and structure.

**Example**: `DOC-001` - Documentation saved in project root instead of docs/

### CORR-### (Auto-Correction)
Patterns for automatically fixing common mistakes (PowerShell syntax, etc.).

**Example**: `CORR-001` - PowerShell [OK] parser error at line start

### SESS-### (Session Patterns)
Norms about session behavior, startup/shutdown procedures, and agent interactions.

**Example**: `SESS-001` - Missing directories created manually each session

## Lifecycle

1. **Learned**: Norm discovered by Auto-Norm-Learner, added to `LEARNED-NORMS.md`
2. **Validated**: Used successfully 5+ times with success rate >80%
3. **Promoted**: Moved to `rules/custom/` with dedicated file (DOC-###.md, etc.)
4. **Enforced**: Auto-Norm-Enforcer validates and applies the norm

## Confidence Levels

- **low**: Newly learned, <5 usages
- **medium**: 5-20 usages, success rate >70%
- **high**: 20+ usages, success rate >85% (candidate for promotion)

## Master Index

See `LEARNED-NORMS.md` for the complete list of learned norms.

## Autonomous Workflow

```
Session Start:
  1. Auto-Norm-Enforcer validates current structure
  2. Auto-Norm-Learner queries Engram for new patterns
  3. New norms added to LEARNED-NORMS.md
  4. High-confidence norms promoted to rules/custom/

Session Close:
  1. Auto-Norm-Learner updates usage statistics
  2. Auto-Scaling optimizes delegation patterns
  3. Session summary saved to Engram
```

## Adding Norms Manually

While the system learns autonomously, you can manually add norms:

1. Add to `LEARNED-NORMS.md` with proper format
2. Run: `.\scripts\adaptive\auto-norm-enforcer.ps1 -Trigger manual -AutoFix`
3. Norm will be enforced in next session

## Files

- **LEARNED-NORMS.md**: Master index (auto-updated)
- **DOC-###.md**: Individual documentation norms (when promoted)
- **CORR-###.md**: Individual correction norms (when promoted)
- **SESS-###.md**: Individual session norms (when promoted)
