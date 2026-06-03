# Templates

## Audit Document

```markdown
# Audit Document - [DATE]

**Project:** [project-name] **Session:** [session-id] **Date:** [ISO date]

## Summary

Brief description of session work.

## Changes

| File    | Change        | Lines    |
| ------- | ------------- | -------- |
| file.go | Added feature | +150/-20 |

## Commits

| Hash   | Type | Message     |
| ------ | ---- | ----------- |
| abc123 | feat | description |

## Findings

| Severity | Count |
| -------- | ----- |
| CRITICAL | 0     |
| HIGH     | 1     |
| MEDIUM   | 2     |
| LOW      | 3     |

## Tests

- Go: X passed
- Angular: Y passed

## Specification

- Status: COMPLETE
- Notes: ...

## Next Steps

- [ ] Item 1
- [ ] Item 2
```

## Code Review Findings

```markdown
## Findings Summary

**Found:** X issues

- [x] CRITICAL: N (blocks if any)
- [!] HIGH: N
- [-] MEDIUM: N
- [*] LOW: N

### Options

1. Fix everything now (recommended)
2. Fix CRITICAL/HIGH now, handle the rest later
3. Create the PR, then fix later
4. Only create the PR
5. Go back to implementation

**Choose:**
```

## Session Summary

```markdown
## Session Summary - [DATE]

### Goal

[What we worked on]

### Accomplished

- [Completed item 1]
- [Completed item 2]

### Findings

- [x] Critical: N
- [!] High: N
- [-] Medium: N
- [*] Low: N

### Git

- Branch: [branch]
- Commits: [list]

### Specification

- Validated: YES/NO
- Notes: ...

### Next Steps

- [ ] Item 1
- [ ] Item 2

### Skills Used

- skill-1
- skill-2

### Relevant Files

- path - description
```

## Todo Management

```typescript
todowrite([
  { content: 'Task 1', status: 'in_progress', priority: 'high' },
  { content: 'Task 2', status: 'pending', priority: 'medium' },
]);
```
