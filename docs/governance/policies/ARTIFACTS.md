# Artifact policy

This policy distinguishes reproducible generated output from curated project documentation.

## Generated artifacts

- Coverage summaries, optimization JSON, and `*-latest.*` log snapshots are generated locally or by
  tooling and remain ignored through [`.gitignore`](../../../.gitignore).
- Do not use `git rm --cached` to change tracking state. Existing tracked files are left untouched;
  changes to them must be handled separately and deliberately.
- Runtime, session, telemetry, and temporary output must not be added to the repository.

## Curated artifacts

- Curated reports, historical snapshots, release notes, and documentation remain trackable when they
  provide reviewed historical or operational context.
- This policy does not rewrite or remove historical snapshots.
- The local-first CMS source of truth is [`apps/content-cms`](../../../apps/content-cms/).
