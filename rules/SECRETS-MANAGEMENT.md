# Secrets Management Policy

**Version:** 1.0.0 **Last updated:** 2026-05-14 **Applies to:** All code, configs, CI/CD, and AI
agent interactions

---

## 1. Core Principles

1. **Never hardcode secrets** — No API keys, tokens, passwords, certificates in code
2. **Never commit secrets** — `.env`, credentials files, and key stores are in `.gitignore`
3. **Never prompt-inject secrets** — Do NOT paste secrets into AI agent prompts
4. **Rotate regularly** — All secrets have expiry and MUST be rotated per schedule
5. **Least privilege** — Each secret grants minimum necessary access

---

## 2. What Constitutes a Secret

| Type               | Examples                           | Risk if Exposed                        |
| ------------------ | ---------------------------------- | -------------------------------------- |
| API Keys           | `sk-...`, `ghp_...`, `AKIA...`     | Unauthorized API access, billing abuse |
| Tokens             | JWT, PAT, OAuth tokens             | Identity impersonation                 |
| Passwords          | DB passwords, admin creds          | Data breach                            |
| Certificates       | `.pem`, `.pfx`, `.key`             | TLS impersonation                      |
| Connection strings | `Server=...;User=...;Password=...` | Database access                        |
| SSH Keys           | `id_rsa`, `id_ed25519`             | Infrastructure access                  |
| Cloud credentials  | AWS keys, Azure SP, GCP SA         | Cloud resource hijacking               |

---

## 3. Where Secrets Live

| Environment    | Storage Method                                               | Access Control        |
| -------------- | ------------------------------------------------------------ | --------------------- |
| **Local dev**  | `.env` file (gitignored)                                     | Developer workstation |
| **CI/CD**      | GitHub Secrets / Actions Variables                           | Repo/branch scoped    |
| **Production** | Cloud secret manager (AWS Secrets Manager / Azure Key Vault) | IAM roles + audit     |
| **AI Agent**   | NEVER in prompts or context                                  | N/A — forbidden       |

---

## 4. Forbidden Patterns

- ❌ Hardcoding secrets in scripts, configs, or source code
- ❌ Committing `.env`, `*.key`, `credentials.json`
- ❌ Pasting secrets into AI agent prompts or chat
- ❌ Logging secrets (even masked — avoid entirely)
- ❌ Storing secrets in git history (even if later removed)
- ❌ Using default passwords or well-known test credentials
- ❌ Sharing secrets via unencrypted channels (email, chat, Slack)

---

## 5. Detection & Enforcement

| Tool                  | What It Detects                   | When            |
| --------------------- | --------------------------------- | --------------- |
| **Gitleaks**          | Git history for secrets           | Pre-commit + CI |
| **Trufflehog**        | Deep git history scanning         | Weekly audit    |
| **Secretlint**        | Config file secrets               | Pre-commit      |
| **Pre-commit hooks**  | Staged changes scan               | Every commit    |
| **Agent self-verify** | `agent-verify.ps1` runtime checks | Every session   |

### Response to Leaked Secret

1. **REVOKE** the secret immediately (don't wait for investigation)
2. **ROTATE** — generate new secret and update all consumers
3. **REMOVE** — scrub from git history using `git filter-repo` or BFG
4. **AUDIT** — determine how the leak happened
5. **PREVENT** — add detection rules, update training

---

## 6. Secret Rotation Schedule

| Secret Type        | Rotation Interval           | Rotation Method                           |
| ------------------ | --------------------------- | ----------------------------------------- |
| API Keys           | 90 days                     | Regenerate in provider dashboard          |
| Service tokens     | 30 days                     | Automated via secret manager              |
| Database passwords | 180 days                    | Automated rotation                        |
| SSH Keys           | 365 days                    | Generate new pair, update authorized_keys |
| Certificates       | 365 days (or before expiry) | Renew via CA                              |
| CI/CD tokens       | 90 days                     | GitHub UI or API                          |

---

## 7. AI Agent Rules for Secrets

### 7.1 DO NOT

- ❌ Paste any secret into a chat prompt or AI tool input
- ❌ Ask an agent to "read my .env" or "check my credentials"
- ❌ Include secret values in test fixtures or examples
- ❌ Ask the agent to store or remember a secret

### 7.2 DO

- ✅ Use environment variables (read by the agent at runtime, not in prompts)
- ✅ Reference secret names (e.g., `$env:DB_PASSWORD`) not values
- ✅ Use `Write-SafeHook` for any hook output that might contain sensitive data
- ✅ Use `config/owner-auth.json` workflow for credential operations

---

## 8. References

| Resource            | Path                             |
| ------------------- | -------------------------------- |
| Security Normatives | `docs/NORMATIVAS-SEGURIDAD.md`   |
| Gitleaks Config     | `.gitleaks.toml`                 |
| Secretlint Config   | `.secretlintrc.json`             |
| Security Skill      | `skills/security-skill/SKILL.md` |
| OWASP Top 10 LLM    | `docs/NORMATIVAS-SEGURIDAD.md`   |

---

_Version: 1.0.0 — 2026-05-14 — Status: ACTIVE_
