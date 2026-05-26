---
name: android-jetpack-compose
user-invocable: false
description:
  Use when building Android UIs with Jetpack Compose, managing state with remember/mutableStateOf,
  or implementing declarative UI patterns.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
---

# Android - Jetpack Compose

## State Management

| API                                     | Use Case                 |
| --------------------------------------- | ------------------------ |
| `remember { mutableStateOf() }`         | Local composable state   |
| `rememberSaveable { mutableStateOf() }` | Survives config changes  |
| `derivedStateOf {}`                     | Computed state with deps |
| `collectAsStateWithLifecycle()`         | ViewModel Flow → Compose |

## Key Patterns

- **State Hoisting**: Stateless composables with `(value, onValueChange)` params
- **Side Effects**: `LaunchedEffect(key)` for coroutines, `DisposableEffect` for cleanup,
  `SideEffect` for non-suspend
- **Keys**: `key = { it.id }` in `LazyColumn`/`LazyVerticalGrid` items for stable recomposition
- **Modifier**: First optional param with `Modifier = Modifier` default

## Critical Rules

- Never call `viewModel.loadData()` directly in composition body — use `LaunchedEffect`
- Use `remember(key) { ... }` keys — reading state inside plain `remember {}` won't update
- Heavy computation → `derivedStateOf {}` with `remember(items)`
- `Slot APIs` for flexible composable layouts

## References

See `references/patterns.md` for: Navigation Compose, Material 3 theming, LazyVerticalGrid, sticky
headers, and detailed anti-patterns with before/after examples.
