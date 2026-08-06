# Process Detail

## Step 1: Detect Stack and Versions

Read the project's dependency file to identify exact versions:

```
package.json    → Node/React/Vue/Angular/Svelte
composer.json   → PHP/Symfony/Laravel
requirements.txt / pyproject.toml → Python/Django/Flask
go.mod          → Go
Cargo.toml      → Rust
Gemfile         → Ruby/Rails
```

State what you found explicitly:

```
STACK DETECTED:
- React 19.1.0 (from package.json)
- Vite 6.2.0
- Tailwind CSS 4.0.3
→ Fetching official docs for the relevant patterns.
```

If versions are missing or ambiguous, **ask the user**. Don't guess.

## Step 2: Fetch Official Documentation

Fetch the specific documentation page for the feature you're implementing.

**Source hierarchy (in order of authority):**

| Priority | Source                    | Example                                            |
| -------- | ------------------------- | -------------------------------------------------- |
| 1        | Official documentation    | react.dev, docs.djangoproject.com, symfony.com/doc |
| 2        | Official blog / changelog | react.dev/blog, nextjs.org/blog                    |
| 3        | Web standards references  | MDN, web.dev, html.spec.whatwg.org                 |
| 4        | Browser/runtime compat    | caniuse.com, node.green                            |

**Not authoritative:** Stack Overflow, blog posts, AI-generated docs, your own training data.

**Be precise:**

```
BAD:  Fetch the React homepage
GOOD: Fetch react.dev/reference/react/useActionState
BAD:  Search "django authentication best practices"
GOOD: Fetch docs.djangoproject.com/en/6.0/topics/auth/
```

After fetching, extract key patterns and note any deprecation warnings. If official sources conflict
(e.g. migration guide contradicts API reference), surface the discrepancy to the user.

## Step 3: Implement Following Documented Patterns

- Use the API signatures from the docs, not from memory
- If the docs show a new way, use the new way
- If the docs deprecate a pattern, don't use it
- If the docs don't cover something, flag it as unverified

**When docs conflict with existing project code:**

```
CONFLICT DETECTED:
The existing codebase uses useState for form loading state,
but React 19 docs recommend useActionState for this pattern.
(Source: react.dev/reference/react/useActionState)

Options:
A) Use the modern pattern (useActionState) — consistent with current docs
B) Match existing code (useState) — consistent with codebase
→ Which approach do you prefer?
```

Surface the conflict. Don't silently pick one.

## Step 4: Cite Your Sources

Every framework-specific pattern gets a citation. The user must be able to verify every decision.

**In code comments:**

```typescript
// React 19 form handling with useActionState
// Source: https://react.dev/reference/react/useActionState#usage
const [state, formAction, isPending] = useActionState(submitOrder, initialState);
```

**In conversation:**

```
I'm using useActionState instead of manual useState for the
form submission state. React 19 replaced the manual
isPending/setIsPending pattern with this hook.

Source: https://react.dev/blog/2024/12/05/react-19#actions
"useTransition now supports async functions [...] to handle
pending states automatically"
```

**Citation rules:**

- Full URLs, not shortened
- Prefer deep links with anchors where possible — anchors survive doc restructuring better than
  top-level pages
- Quote the relevant passage when it supports a non-obvious decision
- Include browser/runtime support data when recommending platform features
- If you cannot find documentation, say so explicitly:

```
UNVERIFIED: I could not find official documentation for this
pattern. This is based on training data and may be outdated.
Verify before using in production.
```
