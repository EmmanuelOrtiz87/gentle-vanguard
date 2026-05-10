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
