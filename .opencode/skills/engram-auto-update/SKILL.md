---
name: engram-auto-update
description: Auto-update engram to latest version with validation and rollback.
triggers:
  - engram update
  - update engram
  - memory update
---

# Engram Auto-Update Skill

Automatically checks for, installs, and validates engram updates to keep the persistent memory
system current without breaking the stack.

## Usage

```bash
/engram-auto-update
/engram-auto-update --check-only
/engram-auto-update --force
```

## Workflow

### 1. Check Current Version

Run `engram --version` to get the currently installed version. Parse the output to extract the
semantic version number (e.g., "1.19.0").

### 2. Check Latest Version

Query the GitHub API to get the latest release:

```
GET https://api.github.com/repos/Gentleman-Programming/engram/releases/latest
```

Extract `tag_name` from the response (e.g., "v1.20.0").

### 3. Compare Versions

Use semantic version comparison:

- If latest > current: update available
- If latest == current: already up-to-date
- If latest < current: unusual (log warning)

### 4. Install Update (if needed)

Run the installation command:

```bash
go install github.com/Gentleman-Programming/engram/cmd/engram@latest
```

This installs to `$GOPATH/bin` or `$HOME/go/bin`.

### 5. Validate Installation

After installation, run `engram --version` again and verify:

- Command executes without error
- Version matches the latest release
- No breaking changes in output format

### 6. Health Check

Run a quick engram health check to ensure the stack works:

```bash
engram doctor --json
```

Verify the response indicates healthy status.

### 7. Rollback (if validation fails)

If validation fails:

1. Note the error
2. Log the incident to audit
3. Notify user of failure
4. Do NOT proceed with the update

## Options

- **`--check-only`**: Only check and report, don't install
- **`--force`**: Force reinstall even if up-to-date

## Output Format

Report in JSON:

```json
{
  "currentVersion": "1.19.0",
  "latestVersion": "1.20.0",
  "updateAvailable": true,
  "updated": true,
  "validationPassed": true,
  "errors": []
}
```

## Error Handling

- Network errors: Log and continue, don't crash
- Installation errors: Log, notify user, don't break session
- Validation errors: Attempt rollback, log incident

## Notes

- This skill runs automatically at session start (lazy step)
- Always validate after update to prevent broken sessions
- Log all update attempts to `.session/audit/logs/`
- Respect user's choice if they opt out of auto-updates