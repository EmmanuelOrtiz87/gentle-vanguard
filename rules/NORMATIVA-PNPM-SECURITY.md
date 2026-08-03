# pnpm Security Normativa

- Use pnpm over npm/yarn
- Always commit pnpm-lock.yaml
- Audit deps before major upgrades
- Dependency security gates must parse machine-readable output (`pnpm audit --json`,
  `pnpm licenses list --json`) before reporting a violation.
- A dependency policy failure must include evidence from the tool output. Timeouts and parser
  failures are infrastructure issues, not proof of a vulnerable dependency.
