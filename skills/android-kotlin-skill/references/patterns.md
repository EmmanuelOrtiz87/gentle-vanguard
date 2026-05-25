# Android Kotlin — Reference Patterns

Moved from SKILL.md to reduce context size. Load this file only when implementing these patterns.

## Gradle Configuration

App-level `build.gradle.kts` with Compose BOM, Hilt 2.50, Room 2.6.1, Coroutines 1.7.3, MockK
1.13.9, Turbine 1.0.0. Min SDK 24, target 34, compile 34. JVM target 17.

## ViewModel + StateFlow

Full ViewModel pattern with `MutableStateFlow`, `SavedStateHandle`, `viewModelScope.launch`, `catch`
operator, `UserUiState` data class. Repository with Flow: offline-first (cache→network→emit).

## Jetpack Compose Screen

Screen + Content pattern with `Scaffold`, `TopAppBar`, `CircularProgressIndicator`, `Snackbar`.
State hoisting with callback lambdas.

## Sealed Result Wrapper

`sealed interface Result<T>` with `Success`, `Error`, `Loading`. Extension functions `getOrNull()`
and `map()`.

## Testing

`MainDispatcherRule` (TestWatcher + UnconfinedTestDispatcher). ViewModel test with `mockk()`,
`coEvery`, `flowOf`, `turbine.test {}`.

## GitHub Actions CI

Standard Android CI: JDK 17, Gradle setup, detekt, ktlint, unit tests, debug APK.

## detekt Lint Config

Max 0 issues, LongMethod > 20, MaxLineLength 120, no wildcard imports, GlobalCoroutineUsage active.
