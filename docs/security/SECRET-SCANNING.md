# Secret scanning

Secret scanning is a blocking control for pull requests and pushes to `main` or `develop`. The
reusable security workflow runs both the pinned Gitleaks action and the native scanner gate.

## Local commands

```bash
pnpm scan:secrets:gate
pnpm exec tsx src/security/secret-scan-gate.ts --base origin/main --head HEAD
pnpm scan:secrets -- --dir . --redact --patterns all
```

The gate examines only added lines, which prevents an existing fixture from becoming a reason to
bypass scanning while still blocking newly introduced matches. Findings print file, line, rule and
risk only; secret values and surrounding context are never printed.

## Triage and rotation

1. Treat every high or medium finding as exposed until verified otherwise.
2. Do not paste the value into an issue, PR, chat, or CI log. Identify it by file and line, then
   remove it and replace it with an environment or secret manager reference.
3. Revoke and rotate the credential with its provider, invalidate related sessions/tokens, and check
   provider audit logs for use.
4. Run the local gate again, then push the remediation. Do not add an allowlist entry for a real
   credential.
5. For an intentional fixture, keep it synthetic and confined to the existing fixture location. Any
   exception must be narrow, documented, and reviewed; this change adds no baseline or allowlist
   entries.

Gitleaks scans repository history in addition to the native added-line gate. Finding an old real
credential is still a failure: rotate it and remediate the repository without rewriting history as
part of this gate change.
