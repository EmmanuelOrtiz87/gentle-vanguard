### Use Cases for Business Logic

```kotlin
class GetUserUseCase @Inject constructor(
    private val userRepository: UserRepository,
    private val analyticsTracker: AnalyticsTracker
) {
    operator fun invoke(userId: String): Flow<Result<User>> = flow {
        emit(Result.Loading)

        userRepository.getUser(userId)
            .catch { e ->
                analyticsTracker.trackError("get_user_failed", e)
                emit(Result.Error(e))
            }
            .collect { user ->
                emit(Result.Success(user))
            }
    }
}

// Sealed class for results
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error(val exception: Throwable) : Result<Nothing>()
    object Loading : Result<Nothing>()
}
```

### Room Database Setup

```kotlin
@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: String,
    val name: String,
    val email: String,
    @ColumnInfo(name = "created_at") val createdAt: Long
)

@Dao
interface UserDao {
    @Query("SELECT * FROM users WHERE id = :id")
    suspend fun getUser(id: String): UserEntity?

    @Query("SELECT * FROM users ORDER BY name ASC")
    fun getAllUsers(): Flow<List<UserEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: UserEntity)

    @Delete
    suspend fun deleteUser(user: UserEntity)
}

@Database(entities = [UserEntity::class], versión = 1)
abstract class AppDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
}

// Hilt module
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "app_database"
        ).build()
    }

    @Provides
    fun provideUserDao(database: AppDatabase): UserDao {
        return database.userDao()
    }
}
```

### Data Mapping

```kotlin
// DTO (Data Transfer Object) - from API
data class UserDto(
    @Json(name = "id") val id: String,
    @Json(name = "full_name") val fullName: String,
    @Json(name = "email_address") val email: String
)

// Entity - for Room
@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: String,
    val name: String,
    val email: String
)

// Domain model
data class User(
    val id: String,
    val name: String,
    val email: String
)

// Mappers
fun UserDto.toEntity() = UserEntity(
    id = id,
    name = fullName,
    email = email
)

fun UserDto.toDomain() = User(
    id = id,
    name = fullName,
    email = email
)

fun UserEntity.toDomain() = User(
    id = id,
    name = name,
    email = email
)

fun User.toEntity() = UserEntity(
    id = id,
    name = name,
    email = email
)
```

## Common Patterns

### Single Source of Truth

```kotlin
class OfflineFirstRepository @Inject constructor(
    private val api: ItemApi,
    private val dao: ItemDao
) : ItemRepository {

    override fun getItems(): Flow<List<Item>> {
        return dao.getAllItems()
            .map { entities -> entities.map { it.toDomain() } }
            .onStart {
                // Refresh from network in background
                refreshItems()
            }
    }

    private suspend fun refreshItems() {
        try {
            val remoteItems = api.getItems()
            dao.deleteAll()
            dao.insertAll(remoteItems.map { it.toEntity() })
        } catch (e: Exception) {
            // Log error, local data still available
        }
    }
}
```

### Navigation with Type-Safe Args

```kotlin
// Define routes
sealed class Screen(val route: String) {
    object Home : Screen("home")
    object Detail : Screen("detail/{itemId}") {
        fun createRoute(itemId: String) = "detail/$itemId"
    }
    object Settings : Screen("settings")
}

// Navigation setup
@Composable
fun AppNavigation(navController: NavHostController) {
    NavHost(navController = navController, startDestination = Screen.Home.route) {
        composable(Screen.Home.route) {
            HomeScreen(
                onItemClick = { itemId ->
                    navController.navigate(Screen.Detail.createRoute(itemId))
                }
            )
        }
        composable(
            route = Screen.Detail.route,
            arguments = listOf(navArgument("itemId") { type = NavType.StringType })
        ) { backStackEntry ->
            DetailScreen(
                itemId = backStackEntry.arguments?.getString("itemId") ?: return@composable
            )
        }
    }
}
```

### Error Handling

```kotlin
sealed class UiState<out T> {
    object Loading : UiState<Nothing>()
    data class Success<T>(val data: T) : UiState<T>()
    data class Error(val message: String, val retry: (() -> Unit)? = null) : UiState<Nothing>()
}

@Composable
fun <T> StateHandler(
    state: UiState<T>,
    onRetry: () -> Unit = {},
    content: @Composable (T) -> Unit
) {
    when (state) {
        is UiState.Loading -> {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        }
        is UiState.Error -> {
            Column(
                modifier = Modifier.fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(state.message)
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = onRetry) {
                    Text("Retry")
                }
            }
        }
        is UiState.Success -> content(state.data)
    }
}
```

## Anti-Patterns

### God Activity/Fragment

Bad: All logic in one Activity.

Good: Use MVVM with clear separation of concerns.

### Network Calls in ViewModel

Bad:

```kotlin
class BadViewModel : ViewModel() {
    fun loadData() {
        val client = OkHttpClient()  // Direct network dependency
        // ...
    }
}
```

Good: Inject repository through constructor.

### Exposing Mutable State

Bad:

```kotlin
class BadViewModel : ViewModel() {
    val uiState = MutableStateFlow(UiState())  // Mutable exposed!
}
```

Good:

```kotlin
class GoodViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()
}
```

## Related Skills

- **android-jetpack-compose**: UI layer patterns
- **android-kotlin-coroutines**: Async operations
