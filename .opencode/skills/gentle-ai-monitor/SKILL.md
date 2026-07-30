---
name: gentle-ai-monitor
description: Monitor gentle-ai releases without installation. Absorb updates and generate actionable suggestions.
triggers:
  - gentle-ai
  - monitor updates
  - track releases
---

# Gentle AI Monitor Skill

Monitors gentle-ai releases to absorb updates, learnings, and architectural improvements WITHOUT
installing or creating dependencies. Generates actionable suggestions for Gentle-Vanguard.

## Usage

```bash
/gentle-ai-monitor
/gentle-ai-monitor --analyze-release
```

## Purpose

Gentle-Vanguard is built on the same architecture, concepts, and criteria as gentle-ai. When
gentle-ai publishes updates, we want to:

1. **Know** what's new (releases, features, fixes)
2. **Learn** from their implementation (patterns, approaches)
3. **Analyze** the changes for relevance to our stack
4. **Suggest** concrete actions to improve Gentle-Vanguard
5. **Validate** we're aligned with their methodology

## Workflow

### 1. Check Current State

Load previous version from state file (`.runtime/gentle-ai-monitor-state.json`). We don't check if
gentle-ai is installed — we only monitor remotely.

### 2. Fetch Latest Release

Try GitHub API first:

```
GET https://api.github.com/repos/Gentleman-Programming/gentle-ai/releases/latest
```

If rate-limited (403), fallback to scraping the releases page.

Extract:

- `tag_name` (version)
- `name` (release title)
- `body` (changelog/release notes)
- `published_at` (date)
- `html_url` (link to release)

### 3. Compare and Report

Report in JSON:

```json
{
  "currentVersion": "2.1.9",
  "latestVersion": "2.1.10",
  "updateAvailable": true,
  "releaseDate": "2026-07-20",
  "url": "https://github.com/..."
}
```

### 4. Analyze for Learning

If `--analyze-release` is specified:

1. **Parse changelog** for categories:
   - Skills (new/updated skills)
   - Patterns (architectural patterns)
   - Security (vulnerability fixes)
   - Performance (optimizations)
   - Review (quality/audit changes)
   - Memory (engram/persistence)
   - Integrations (MCP/connectors)
   - CLI (command-line tools)
   - Documentation

2. **Generate suggestions** based on learnings:
   - For each category, create actionable suggestions
   - Assign priority (high/medium/low)
   - Map gentle-ai features to Gentle-Vanguard actions

3. **Save suggestions** to `.session/gentle-ai-suggestions.md`

### 5. Output Format

Console output with colors:

- `[INFO]` - Version info, release details
- `[WARN]` - New version available
- `[SUCCESS]` - Already on latest
- `[LEARN]` - Learning identified
- `[SUGGEST]` - Actionable suggestion generated

## Options

- **`--analyze-release`**: Deep analysis with suggestions (recommended)

## Output Files

- `.runtime/gentle-ai-monitor-state.json` - Version tracking
- `.session/audit/logs/gentle-ai-monitor-YYYY-MM-DD.jsonl` - Audit log
- `.session/gentle-ai-suggestions.md` - Actionable suggestions (with --analyze-release)

## Error Handling

- Network errors: Log and continue, don't crash
- No releases: Log warning, continue
- Parse errors: Log error, skip analysis gracefully

## Notes

- This skill NEVER installs gentle-ai
- It's a monitoring/learning tool only
- Runs at session start (lazy step in autostart)
- All analysis saved to audit logs for future reference
- Suggestions are actionable but require human review before implementation