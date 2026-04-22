# Authentication, Authorization, and Secret Management

## Authentication
- Use environment variables to store all credentials and API keys.
- Never hardcode secrets in scripts or code.
- For web APIs or services, implement authentication middleware (e.g., JWT, OAuth2, or API key header).
- For CLI tools, require users to provide credentials via environment or secure prompts.

## Authorization
- Restrict access to sensitive scripts and endpoints based on user roles or groups.
- Use role-based access control (RBAC) for multi-user systems.
- Document who can run critical scripts (e.g., deployment, homologation, or production changes).

## Secret Management
- Store secrets in `.env.local` (gitignored) or a secure vault (e.g., Azure Key Vault, AWS Secrets Manager).
- Rotate secrets regularly and after any suspected exposure (see SECURITY-API-KEY-ROTATION.md).
- Audit `.gitignore` and scripts for new secret/config files after each release.
- Never log secrets or print them to the console.

## Example: .env.local
```
# .env.local (never committed)
AGENT_CUSTOM_APIKEY=sk-prod-NEWKEY
DATABASE_URL=postgres://user:pass@host:5432/db
```

## Enforcement
- Pre-commit hooks and CI/CD pipelines must check for secrets in code and config files.
- Use tools like git-secrets, truffleHog, or gitleaks for automated scanning.
- Document all secret variables and their purpose in README or a dedicated secrets doc.

## References
- See docs/guides/SECURITY-API-KEY-ROTATION.md for rotation procedures.
- See README.md for environment setup and security practices.
