---
name: bad-permission-skill
description: Fixture declaring a permission outside the closed enum, which must be rejected.
metadata:
  source: fixtures
  license: MIT
  version: 0.1.0
  permissions: root-access
---

# Bad Permission Skill

This manifest must fail validation: `root-access` is not in the enum.
