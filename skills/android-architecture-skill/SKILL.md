---
name: android-architecture
user-invocable: false
description:
  Use when implementing MVVM, clean architecture, dependency injection with Hilt, or structuring
  Android app layers.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
---

# Android - Architecture

Modern Android architecture patterns following Google's recommended practices.

## Key Concepts

### MVVM Architecture

Model-View-ViewModel separates UI from business logic:

```kotlin
// UI State
data class UserUiState(
    val user: User? = null,
    val isLoading: Boolean = false,
    val error: String? = null
)

// ViewModel
class UserViewModel(
    private val userRepository: UserRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(UserUiState())
    val uiState: StateFlow<UserUiState> = _uiState.asStateFlow()

    fun loadUser(userId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            userRepository.getUser(userId)
                .onSuccess { user ->
                    _uiState.update { it.copy(user = user, isLoading = false) }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(error = error.message, isLoading = false) }
                }
        }
    }
}

// Composable
@Composable
fun UserScreen(viewModel: UserViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    when {
        uiState.isLoading -> LoadingIndicator()
        uiState.error != null -> ErrorMessage(uiState.error!!)
        uiState.user != null -> UserContent(uiState.user!!)
    }
}
```

### Clean Architecture Layers

```
app/
 data/
    local/           # Room database, DataStore
       dao/
       entities/
    remote/          # Retrofit, network
       api/
       dto/
    repository/      # Repository implementations
 domain/
    model/           # Domain models
    repository/      # Repository interfaces
    usecase/         # Business logic
 presentation/
     ui/              # Composables
     viewmodel/       # ViewModels
```

### Repository Pattern

```kotlin
// Domain layer - interface
interface UserRepository {
    fun getUser(id: String): Flow<User>
    suspend fun saveUser(user: User): Result<Unit>
    suspend fun deleteUser(id: String): Result<Unit>
}

// Data layer - implementation
class UserRepositoryImpl(
    private val userApi: UserApi,
    private val userDao: UserDao
) : UserRepository {

    override fun getUser(id: String): Flow<User> = flow {
        // Emit cached data first
        userDao.getUser(id)?.let { emit(it.toDomain()) }

        // Fetch fresh data
        try {
            val remoteUser = userApi.getUser(id)
            userDao.insertUser(remoteUser.toEntity())

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)