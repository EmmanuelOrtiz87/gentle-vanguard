# Secrets Management

```
.env files:
  ├── .env.example  → Committed (template with placeholder values)
  ├── .env          → NOT committed (contains real secrets)
  └── .env.local    → NOT committed (local overrides)

.gitignore must include:
  .env
  .env.local
  .env.*.local
  *.pem
  *.key
```

## Always Check Before Committing

```bash
# Check for accidentally staged secrets
git diff --cached | grep -i "password\|secret\|api_key\|token"
```

## Secret Rotation

If a secret is ever committed, rotate it. Deleting the line or rewriting history is not enough —
assume it's compromised the moment it reaches a remote. Revoke and reissue the key first, then purge
it from history.
