# Kubernetes manifest validation

This directory documents **external-promotion gates**. Kubernetes is optional and is not required
for the supported local-first operating profile. Use these checks only when an operator is preparing
an external server/cluster deployment.

The checked-in manifest intentionally does not contain registry digests: this repository does not
own the registry or release image metadata. It therefore reports mutable image references rather
than inventing `sha256` values.

Run the local production/auth and generated-artifact gate with:

```sh
pnpm ci:static-gates
```

For a rendered release manifest (or after replacing image references in a deployment workspace),
enforce immutable images with:

```sh
pnpm ci:static-gates:strict-images
```

The release/deployment system must provide real `image@sha256:<64 hex characters>` references.
Cluster topology, registry ownership, and digest values are deliberately outside this repository.
