# Deployment prerequisite contract

These are prerequisites for **external promotion**, not for local-first operation. The default local
profile uses the repository's local runtime and does not require Kubernetes, a registry, CNI evidence,
Cosign identity, or an OS/container sandbox. Apply this contract only when deliberately promoting to a
server, Kubernetes, or hosted deployment.

This repository deliberately does not contain registry coordinates, release digests, a CNI choice,
or an OS sandbox guarantee. Those are deployment-owner inputs, not safe defaults.

## Validate

```bash
pnpm validate:deployment
pnpm validate:deployment -- --promotion
pnpm validate:deployment -- --report --json
pnpm validate:deployment -- --network-policy path/to/operator-approved-network-policy.yml
```

The command checks the committed contract at `config/deployment-prerequisites.json`, the Kubernetes
deployment shape, the MCP execution policy, and operator evidence. It reports each missing external
input by name. `--report` prints findings without failing, which is suitable for pull requests.
`--promotion` makes missing/unrendered image digests blocking. It never rewrites manifests or
chooses a registry, digest, CNI, runtime, network rule, or workspace path.

## Required external inputs

| Input                                                                           | Meaning                                                                           |
| ------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `GV_IMAGE_DIGEST_DASHBOARD`, `GV_IMAGE_DIGEST_WEBSOCKET`, `GV_IMAGE_DIGEST_MCP` | Release-rendered `sha256:<64 hex>` values; supplied only by the promotion system. |
| `GV_K8S_CNI_PROVIDER`                                                           | Operator's actual CNI/provider identity.                                          |
| `GV_K8S_NETWORKPOLICY_ENFORCED`                                                 | Evidence that the target cluster enforces NetworkPolicy.                          |
| `GV_MCP_SANDBOX_PROVIDER`                                                       | Actual OS/runtime sandbox provider.                                               |
| `GV_MCP_SANDBOX_ENFORCED`                                                       | Evidence that the MCP sandbox is enforced, not merely configured.                 |
| `GV_MCP_SANDBOX_WORKSPACE`                                                      | The operator-approved workspace boundary.                                         |

The repository currently has no NetworkPolicy manifest because ingress, egress, DNS, telemetry, and
service topology are environment-specific. Pass an approved manifest with `--network-policy` once
those inputs are known. A policy must declare `podSelector` and `policyTypes`; this validator does
not infer or approve traffic rules.

The committed MCP policy is empty and therefore does not enable commands. Any future skill entry
must explicitly use `network: false` and `filesystem: workspace`; broad filesystem access and
network access are not implicit fallbacks.
