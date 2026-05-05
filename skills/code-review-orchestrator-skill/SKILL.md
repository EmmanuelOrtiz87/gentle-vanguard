---
name: code-review-orchestrator
description: >
  Unified system for all code quality and security reviews across 7 dimensions.
  Trigger: "code review", "review all", "quality check", "orchestrator"
---

# Code Review Orchestrator Skill

**Trigger Keywords:** code review, review, review all, full review, check code, analyze code, quality check, audit code, orchestrator, orchestrate, coordinate

## Overview

The Code Review Orchestrator is the **single, unified system** for all code quality and security reviews.

```

                     CODE REVIEW ORCHESTRATOR                                 

                                                                              
        
                         7 REVIEW DIMENSIONS                                 
                                                                              
      [S] Security  [Q] Quality  [A] Architecture                          
      [T] Testing   [D] Docs     [API] API Design  [G] Git Workflow         
                                                                              
        
                                                                            
                                                                            
        
                         OUTPUTS                                              
                                                                              
      [R] Reports         [I] Issues       [X] Automation                   
      docs/reviews/      CSV export        Pre-commit hooks                  
                                                                              
        
                                                                              

```

## The Unified Flow

### Automatic (Pre-commit)

```
    git commit
        
        

 pre-commit hook       
 (auto-installed)  1. Reentrant protection check             
      2. Get staged files                       
                          3. Critical secrets scan (fast)           
                          4. Quality patterns scan                  
                          5. Generate report                         
                         
                                                   
                             
                                                                         
                                                                         
                                              
                        CRITICAL           REPORT                   
                         FOUND?           GENERATED                 
                                              
                                                                          
                                                
                  YES                    NO                             
                                                                       
                                               
              [X] BLOCK              [OK] ALLOW                          
              Exit code 1            Exit code 0                       
                                               
                                                                      
         

    Performance: ~30 seconds for full quick scan
```

### Manual (On Demand)

```
    wf review [scope] [options]
        
        

 Load config           
 from JSON         Scope validation                            
       all, security, quality, testing          
                           docs, api, git, quick, full             
                         
                                                   
                                                   
                
 Execute scans     Run selected dimension checks       
 (1-7 dimensions)                  
                                    
                                                       
                  
                                                                         
                                                                         
               
 Generate output                  Generate detailed markdown report    
 (Console + File)  docs/code-reviews/YYYY-MM-DD-...   
               
```

## Review Dimensions

### Dimension Details

| Dimension | Icon | Auto | Scope | What it Checks |
|-----------|------|------|-------|----------------|
| **Security** | [S] | Yes | security | Secrets, vulnerabilities, OWASP |
| **Quality** | [Q] | Yes | quality | Code smells, complexity, patterns |
| **Architecture** | [A] | No | architecture | Structure, coupling, design |
| **Testing** | [T] | No | testing | Coverage, test quality |
| **Documentation** | [D] | No | docs | README, comments, ADRs |
| **API Design** | [API] | No | api | REST compliance, validation |
| **Git Workflow** | [G] | No | git | Commits, branches, hooks |

### Security Dimension Details

```

                          SECURITY SCAN                                       


    Pattern Detection:
    
    [!C] CRITICAL                          [!H] HIGH
                             
     AWS Access Keys (AKIA...)           Generic API Keys
     GitHub Tokens (ghp_...)             Bearer Tokens
     Private Keys (PEM/RSA)              Basic Auth strings
     Stripe Keys (sk_live_...)           JWT Tokens
     SendGrid Keys (SG....)              Database URLs w/ creds
    
    Detection Method: Regex pattern matching on staged files
    Performance: < 1 second for critical patterns
```

## Severity Levels

```

                          SEVERITY MATRIX                                     


    
     [!C] CRITICAL  Security breach risk                                  
                 Exposed credentials                                       
                 Data loss vulnerability                                   
    
                BLOCK commit (exit code 1)                                  
    

    
     [!H] HIGH     Major quality issues                                   
                 SQL injection risk                                         
                 Missing authentication                                    
    
                WARN + require review (exit code 0 with warning)            
    

    
     [!M] MEDIUM   Technical debt                                         
                 Error handling gaps                                       
                 Missing validation                                        
    
                INFO + log for review (exit code 0)                       
    

    
     [!L] LOW      Code style violations                                   
                 Missing comments                                          
                 TODO/FIXME notes                                         
    
                SUGgestión + log (exit code 0)                             
    
```

## Commands

### Quick Reference

| Command | Description |
|---------|-------------|
| `wf review` | Full review (all 7 dimensions) |
| `wf review --scope security` | Security only |
| `wf review --scope quality` | Quality only |
| `wf review --scope testing` | Testing only |
| `wf review --scope docs` | Documentation only |
| `wf review --scope api` | API design only |
| `wf review --scope git` | Git workflow only |
| `wf review --scope quick` | Security + Quality (fast, ~30s) |
| `wf review --scope full` | Alias for 'all' |
| `wf review --report` | Generate detailed report |
| `wf review --track` | Export issues to CSV |
| `wf review --verbose` | Verbose output |

### Scope Options Flow

```
    
                        SCOPE SELECTION FLOW                         
    
    
                              wf review
                                  
                    
                                              
                                              
               --scope        (default)      --help
               required           
                                 
                                 
              
                    SCOPE MAPPING          
              
              
    
       all        security     quality     testing   
       (7 dims)    (1 dim)      (1 dim)      (1 dim)   
    
       quick        docs         api          git      
      (2 dims)     (1 dim)      (1 dim)      (1 dim)   
    
```

## Report Format

### Console Output

```
[REVIEW] Code Review Orchestrator
======================================

[--------------------] 0% Starting review...
[REVIEW] Security Review
[======--------------] 30% Security reviewed
[REVIEW] Quality Review
[========------------] 40% Quality reviewed
[REVIEW] Architecture Review
[===========---------] 55% Architecture reviewed
[REVIEW] Testing Review
[==============------] 70% Testing reviewed
[REVIEW] Documentation Review
[================----] 80% Documentation reviewed
[REVIEW] API Design Review
[==================--] 90% API reviewed
[REVIEW] Git Workflow Review
[====================] 100% Complete

======================================
 Review Complete
======================================

 Found: 24 issues
   - 2 critical
   - 5 high
   - 10 medium
   - 7 low

 Report saved to: docs/code-reviews/2026-04-08-all-review.md
```

### Report File Structure

```markdown
# Code Review Report

**Date:** 2026-04-08 14:30
**Scope:** all
**Total Issues:** 24 (2 critical, 5 high, 10 medium, 7 low)

## Summary

### Issues by Severity
| Severity | Count | Action Required |
|----------|-------|----------------|
| CRITICAL | 2     | Block deployment |
| HIGH     | 5     | Fix before merge |
| MEDIUM   | 10    | Review and fix |
| LOW      | 7     | Consider fixing |

### Issues by Category
| Category | Total | Critical | High | Medium | Low |
|----------|-------|----------|------|--------|-----|
| Security | 8     | 2        | 3    | 2      | 1   |
| Quality  | 6     | 0        | 2    | 2      | 2   |
| ...

## Critical Issues (Action Required)

### 1. [SECURITY] API Key Exposed
**File:** `src/config/api.ts:15`
**Category:** Security

**Issue:** Hardcoded API key detected.

**Recommendation:** Use environment variables.
```

## Integration Points

### Git Hooks

```
.git/hooks/
 pre-commit               Auto-installed
    pre-commit-review.ps1 (or .sh)
 pre-push                Optional
 commit-msg              Optional (conventional commits)
```

### CI/CD Integration

```yaml
# GitHub Actions Example
- name: Code Review
  run: |
    ./scripts/utilities/wf.ps1 review --scope all --report
    ./scripts/utilities/wf.ps1 review --track

- name: Upload Review Report
  uses: actions/upload-artifact@v7
  with:
    name: code-review-report
    path: docs/code-reviews/
```

## Configuration

Edit `configs/review-config.json`:

```json
{
  "skills": {
    "security-expert-skill": {
      "enabled": true,
      "order": 1
    }
  },
  "severity": {
    "critical": { "action": "block" },
    "high": { "action": "warn" },
    "medium": { "action": "info" },
    "low": { "action": "suggest" }
  },
  "exclusions": {
    "paths": ["**/node_modules/**", "**/dist/**"]
  }
}
```

## Performance

| Scope | Dimensions | Est. Time |
|-------|------------|-----------|
| quick | 2 | ~30s |
| security | 1 | ~15s |
| quality | 1 | ~15s |
| all | 7 | ~2-5min |

*Times vary based on project size and disk I/O*

## Next Steps After Review

1. **Review critical issues immediately** - Run `wf review --scope security`
2. **Schedule high issues for next sprint** - Generate report with `wf review --report`
3. **Address medium issues in tech debt** - Track with `wf review --track`
4. **Consider low issues for code polish** - Part of regular maintenance
5. **Update report after fixes** - Re-run to verify resolution

---

## Judgment Day - Dual Review Protocol

### Overview

**Judgment Day** is a foundation-native capability that complements  pre-commit reviews with deep pre-merge adversarial validation.

###  vs Judgment Day

| Aspect |  | Judgment Day |
|--------|-----|--------------|
| **Trigger** | Pre-commit | Pre-merge |
| **Mode** | Single reviewer | Two parallel judges |
| **Purpose** | Fast block of critical issues | Deep adversarial validation |
| **Speed** | ~seconds | ~minutes |

### Workflow

```
git commit >  > Block critical issues
                                  
                                  
                         Significant work ready for merge
                                  
                                  
                     wf review --scope judgment-day
                                  
                    
                                                  
               APPROVED                         ESCALATED
               (merge)                    (manual review)
```

### Commands

| Command | Description |
|---------|-------------|
| `wf review --scope judgment-day` | Run dual review protocol |
| `wf review --scope judgment-day --target <path>` | Target specific path |
| `wf review --scope judgment-day --max-iterations 3` | Custom iteration limit |

### AGENT-QA Integration

AGENT-QA owns Judgment Day execution:

```powershell
wf agent QA "judgment day on src/features/auth"
```

See: `skills/multi-agent-registry/SKILL.md` - AGENT-QA section


