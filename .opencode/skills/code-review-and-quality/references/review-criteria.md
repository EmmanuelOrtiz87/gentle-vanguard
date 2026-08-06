# Review Criteria: Five-Axis Detail

## 1. Correctness

Does the code do what it claims to do?

- Does it match the spec or task requirements?
- Are edge cases handled (null, empty, boundary values)?
- Are error paths handled (not just the happy path)?
- Does it pass all tests? Are the tests actually testing the right things?
- Are there off-by-one errors, race conditions, or state inconsistencies?

## 2. Readability & Simplicity

Can another engineer (or agent) understand this code without the author explaining it?

- Are names descriptive and consistent with project conventions? (No `temp`, `data`, `result`
  without context)
- Is the control flow straightforward (avoid nested ternaries, deep callbacks)?
- Is the code organized logically (related code grouped, clear module boundaries)?
- Are there any "clever" tricks that should be simplified?
- **Could this be done in fewer lines?** (1000 lines where 100 suffice is a failure)
- **Are abstractions earning their complexity?** (Don't generalize until the third use case)
- Would comments help clarify non-obvious intent? (But don't comment obvious code.)
- Are there dead code artifacts: no-op variables (`_unused`), backwards-compat shims, or
  `// removed` comments?
- **Is a new conditional bolted onto an unrelated flow?** That's a design smell, not a nit — push
  the logic into its own helper, state, or policy instead of tangling an existing path.
- **Do repeated conditionals on the same shape appear?** They signal a missing model or dispatcher.
  A "temporary" branch is usually permanent debt.

## 3. Architecture

Does the change fit the system's design?

- Does it follow existing patterns or introduce a new one? If new, is it justified?
- Does it maintain clean module boundaries?
- Is there code duplication that should be shared?
- Are dependencies flowing in the right direction (no circular dependencies)?
- Is the abstraction level appropriate (not over-engineered, not too coupled)?
- **Does this refactor reduce complexity or just relocate it?** Count the concepts a reader must
  hold to follow the change. If a "cleaner" version leaves that count unchanged, it isn't cleaner —
  prefer the restructuring that makes whole branches, modes, or layers disappear over one that
  re-centralizes the same logic. Prefer deleting an abstraction to polishing it.
- **Is feature-specific logic leaking into a shared or general-purpose module?** Keep logic in its
  owning layer, reuse the existing canonical helper instead of a near-duplicate, and don't normalize
  architectural drift.
- **Are type boundaries explicit?** Question gratuitous `any`/`unknown`/optional/casts and silent
  fallbacks that paper over an unclear invariant — making the boundary explicit often makes the
  surrounding control flow simpler.

## 4. Security

For detailed security guidance, see `security-and-hardening`. Does the change introduce
vulnerabilities?

- Is user input validated and sanitized?
- Are secrets kept out of code, logs, and version control?
- Is authentication/authorization checked where needed?
- Are SQL queries parameterized (no string concatenation)?
- Are outputs encoded to prevent XSS?
- Are dependencies from trusted sources with no known vulnerabilities?
- Is data from external sources (APIs, logs, user content, config files) treated as untrusted?
- Are external data flows validated at system boundaries before use in logic or rendering?

## 5. Performance

For detailed profiling and optimization, see `performance-optimization`. Does the change introduce
performance problems?

- Any N+1 query patterns?
- Any unbounded loops or unconstrained data fetching?
- Any synchronous operations that should be async?
- Any unnecessary re-renders in UI components?
- Any missing pagination on list endpoints?
- Any large objects created in hot paths?

## Structural Remedies

When you flag a structural problem, propose the move — not just the problem. A review that only says
"this is complex" leaves the author guessing. Reach for a named restructuring:

- **Replace a chain of conditionals** with a typed model or an explicit dispatcher.
- **Collapse duplicate branches** into a single clearer flow.
- **Separate orchestration from business logic** so each reads on its own.
- **Move feature-specific logic** out of a shared module into the package that owns the concept.
- **Reuse the canonical helper** instead of a bespoke near-duplicate.
- **Make a type boundary explicit** so downstream branching disappears.
- **Delete a pass-through wrapper** that adds indirection without clarifying the API.
- **Extract a helper, or split a large file** into focused modules.

Prefer the remedy that removes moving pieces over one that spreads the same complexity around.
