# Architecture Standards

## 1. Default decisión Shape

Use this order when writing an architecture note:

1. Project context.
2. decisión.
3. Why this default is safe.
4. What the user can override.
5. Impact on structure, scripts, and validation.
6. Follow-up notes.

## 2. Common decisión Areas

1. Layering and module boundaries.
2. Project kind and scaffold shape.
3. Data and secret placement.
4. Runtime state and cleanup rules.
5. Compatibility constraints across OSes.
6. Tooling boundaries between project code and external tools.

## 3. Suggested Repository Targets

Use these files for architecture records:

1. `ARCHITECTURE.md`
2. `docs/project-context.md`
3. `docs/technical/*.md` when the change needs a technical summary
4. `docs/code-reviews/*.md` when the change is tied to a review

## 4. Minimal Architecture Note Template

1. Context
2. decisión
3. Expected result
4. Current implementation
5. Notes or constraints

## 5. Compatibility Checklist

Before closing an architecture change, verify:

1. Defaults are safe for a new developer.
2. User choices are explicit where needed.
3. The repo does not depend on embedded external tools.
4. OS-specific behavior is documented.
5. Scripts and docs match the selected structure.
