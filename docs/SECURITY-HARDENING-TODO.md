# Security hardening TODO

- Verify and replace the optional `@modelcontextprotocol/server-sqlite` and
  `@modelcontextprotocol/server-git` template entries with maintained package versions. The npm
  registry did not expose a verifiable version during this review, so those optional templates
  remain unchanged.
- Replace the Syft and Grype installer bootstrap with release archives and published checksums when
  the CI maintenance process can verify the checksum files. The current workflow pins the installer
  scripts to immutable commits and passes explicit tool versions, but does not claim checksum
  verification.
