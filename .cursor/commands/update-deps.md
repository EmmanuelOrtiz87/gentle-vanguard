Update project dependencies.

1. Check for outdated: `npm outdated`
2. Update one dependency at a time: `npm update <package>` or `npm install <package>@latest`
3. Run tests after each update: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/validation/run-tests.ps1`
4. If test passes, commit the update
5. Continue with next dependency
