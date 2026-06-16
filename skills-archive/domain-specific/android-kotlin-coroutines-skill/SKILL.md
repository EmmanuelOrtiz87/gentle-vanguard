---
name: android-kotlin-coroutines
description:
  Kotlin Coroutines and Flow guidance for Android projects (structured concurrency, cancellation,
  testing)
when-to-use: When implementing async logic in Android Kotlin code with coroutines or flow
user-invocable: false
paths: ['**/*.kt', '**/*.kts', 'android/**', '**/build.gradle.kts']
effort: medium
metadata:
  source: GV-native
---

# Android Kotlin Coroutines Skill

## Core Practices

1. Use structured concurrency with clear scope ownership (`viewModelScope`, `lifecycleScope`, or
   injected scope).
2. Expose immutable state with `StateFlow` and one-off events with `SharedFlow`.
3. Keep cancellation cooperative: avoid blocking calls inside coroutines.
4. Encapsulate dispatcher usage (do not hardcode `Dispatchers.IO` deep in domain logic).
5. Test with `kotlinx-coroutines-test` and deterministic virtual time.

## Recommended Patterns

```kotlin
class ExampleViewModel(
    private val repository: ExampleRepository,
    private val ioDispatcher: CoroutineDispatcher
) : ViewModel() {

    private val _uiState = MutableStateFlow(ExampleUiState())
    val uiState: StateFlow<ExampleUiState> = _uiState.asStateFlow()

    fun load() {
        viewModelScope.launch {
            _uiState.update { it.copy(loading = true) }
            val result = withContext(ioDispatcher) { repository.fetch() }
            _uiState.update { it.copy(loading = false, data = result) }
        }
    }
}
```

## Testing Notes

1. Use `runTest` and a `StandardTestDispatcher`.
2. Replace production dispatchers with test dispatchers via dependency injection.
3. Assert `StateFlow` emissions in order for success and failure paths.
