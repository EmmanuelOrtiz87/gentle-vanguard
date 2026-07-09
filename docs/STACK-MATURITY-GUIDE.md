# Stack maturity guide

## Objective

Use a simple model to decide whether a capability belongs to the stable core or remains an
experimental feature.

## Rules

1. Core modules are the default path for everyday work.
2. Experimental modules must be explicitly enabled with opt-in activation.
3. Experimental activation requires the minimum governance checks: tests, typecheck, and security
   scan.
4. Any experimental rollout needs one approval and a review before rollout.

## Quick decision

- If the capability is part of the daily operating path, place it in core.
- If the capability is risky, new, or still being validated, keep it experimental.
- If the capability is experimental, do not enable it without the required checks and approval.

## Activation checklist

1. Review the module scope and impact.
2. Run the required checks: tests, typecheck, and security scan.
3. Confirm the module is still experimental and not part of the stable core.
4. Request one approval before rollout.
5. Record the activation decision and rollout date.
