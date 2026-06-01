# Security Audit — Imported Skills
**Date**: 2026-06-01
**Sources audited**: anthropic-skills, taste-skill, academic-research-skills, claude-bughunter, knowledge-work-plugins
**Total skills**: 226

## Findings Summary

| Issue Type | Count | Risk | Notes |
|-----------|-------|------|-------|
| SCRIPT_TAG | 16 | Low | HTML/JS code examples embedded in SKILL.md |
| EVAL | 9 | Low | JavaScript eval() in example code |
| SHELL_EXEC | 10 | Low | Shell commands/subprocess in security tools |
| LARGE (>50KB) | 4 | None | Long comprehensive skill files |

## Details by Source

### claude-bughunter (51 skills) — 26 flagged, all LOW
Skills contain shell execution patterns and eval because they're **security/bug bounty tools** that reference:
- Command-line tools (nmap, curl, Burp Suite)
- JavaScript payload examples (XSS, CSRF, SSTI)
- Python scripts for automation
These are **expected patterns** for offensive security content.

### taste-skill (13 skills) — 1 flagged (LOW)
- taste-skill: large file (1210 lines) with embedded HTML/JS examples for frontend design

### anthropic-skills (17 skills) — 2 flagged (LOW)
- algorithmic-art-skill: HTML canvas examples
- skill-creator-skill: eval() in example test generation

### knowledge-work-plugins (141 skills) — 3 flagged (LOW)
- build-dashboard-skill, competitive-intelligence-skill, create-an-asset-skill: HTML templates in output examples

### academic-research-skills (4 skills) — 0 flagged

## Verdict: ALL LOW — No blocking issues
All findings are **inline code examples** in documentation, not executable threats.
