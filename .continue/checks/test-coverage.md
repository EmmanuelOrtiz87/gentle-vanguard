---
name: Test Coverage
description: Ensure new code has corresponding tests
---

Look for new code that's missing tests:

- A new source file was added without a corresponding test file (e.g., `utils.ps1` added but no `utils.test.ps1`) -- create a test file with basic coverage
- New exported functions or public methods with no tests exercising them -- add tests covering main code paths
- An existing test file was deleted without the corresponding source file also being deleted -- flag for review

No changes needed if:
- All new source files have corresponding test files
- New functions/methods are already covered by tests
- Only test files, docs, or config files were changed
