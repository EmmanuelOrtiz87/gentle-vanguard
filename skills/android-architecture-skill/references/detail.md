            emit(remoteUser.toDomain())
        } catch (e: Exception) {
            // Network error, cached data already emitted
        }
    }

    override suspend fun saveUser(user: User): Result<Unit> = runCatching {
        userApi.updateUser(user.toDto())
        userDao.insertUser(user.toEntity())
    }

}

````

## Best Practices

### Dependency Injection with Hilt

```kotlin
// Module definition
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideRetrofit(): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BuildConfig.API_BASE_URL)
            .addConverterFactory(MoshiConverterFactory.create())
            .build()
    }

    @Provides
    @Singleton
    fun provideUserApi(retrofit: Retrofit): UserApi {
        return retrofit.create(UserApi::class.java)
    }
}

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindUserRepository(impl: UserRepositoryImpl): UserRepository
}

// ViewModel injection
@HiltViewModel
class UserViewModel @Inject constructor(
    private val getUserUseCase: GetUserUseCase,
    private val savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val userId: String = savedStateHandle.get<String>("userId")
        ?: throw IllegalArgumentException("userId required")

    // ViewModel implementation
}
}
````

---

## References

See `references/patterns.md` for detailed patterns and code examples.
