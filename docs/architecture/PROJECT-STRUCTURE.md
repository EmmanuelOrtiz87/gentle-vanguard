# Project Structure Refactoring Plan

## Current Structure (Key Areas)
- Scripts, docs, configs, and tools are mixed at the root and in scripts/.
- Some folders (e.g., scripts/project, scripts/utilities, scripts/validation) are well-scoped, but others are broad.
- Documentation is mostly in docs/, but some README.md files are scattered.

## Recommendations
- Group all scripts under scripts/ by function (e.g., scripts/validation, scripts/diagnostics, scripts/project).
- Move all documentation (except root README.md) to docs/.
- Place all configuration files in a config/ directory.
- Place all test files in a tests/ directory at the root.
- Add or update README.md files in each major directory to clarify scope and usage.
- Remove or archive obsolete files and folders.

## Example Structure
```
workspace-foundation/
├── config/
├── docs/
├── scripts/
│   ├── diagnostics/
│   ├── project/
│   ├── utilities/
│   ├── validation/
├── skills/
├── tests/
├── tools/
├── .gitignore
├── README.md
```

## Next Steps
1. Review all files/folders for correct placement.
2. Move misplaced files to their recommended locations.
3. Update or add README.md files as needed.
4. Remove or archive obsolete items.
5. Document the new structure in docs/architecture/PROJECT-STRUCTURE.md.
