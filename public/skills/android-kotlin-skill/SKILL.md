---
name: android-kotlin
description: Android Kotlin development with Coroutines, Jetpack Compose, Hilt, and MockK testing
when-to-use: When working on Android Kotlin source files
user-invocable: false
paths: ['**/*.kt', '**/*.kts', 'android/**', '**/build.gradle.kts']
effort: medium
metadata:
  source: GV-native
---

# Android Kotlin Skill

## Project Structure

```
app/src/main/kotlin/com/example/app/
  data/local/  remote/  repository/
  di/
  domain/model/  repository/  usecase/
  ui/feature/  components/  theme/
  App.kt
app/src/test/  androidTest/
```

## Key Patterns

- **ViewModel**: `MutableStateFlow` + `StateFlow`, `viewModelScope.launch`, `SavedStateHandle`
- **Repository**: `Flow` with offline-first pattern (cache→network→emit)
- **Sealed Interface**: `Result<T>` with `Success/Error/Loading`

## Compose Integration

- `collectAsStateWithLifecycle()`, `hiltViewModel()`, `LaunchedEffect`
- State hoisting, slot APIs, `Modifier` as first param

## Critical Rules

- Expose `StateFlow`, never `MutableStateFlow`
- `catch` operator on every Flow collection
- Inject dispatchers (`Dispatchers.IO`) for testability
- Use `sealed interface` for finite state sets
- `LaunchedEffect`/`SideEffect`, never side effects in composition
- Stable/immutable types or `@Stable` for Compose params

---

## References

See `references/patterns.md` for: Gradle config, full ViewModel/Repository/Compose code examples,
Testing with MockK+Turbine, GitHub Actions CI, detekt lint config, and detailed anti-patterns.
