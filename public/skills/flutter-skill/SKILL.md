---
name: flutter
description:
  Flutter development with Riverpod state management, Freezed, go_router, and mocktail testing
when-to-use: When working on Flutter/Dart code
user-invocable: false
paths: ['**/*.dart', 'pubspec.yaml', 'lib/**', 'test/**']
effort: medium
metadata:
  source: GV-native
---

# Flutter Skill

---

## Project Structure

```
project/
 lib/
    core/                           # Core utilities
       constants/                  # App constants
       extensions/                 # Dart extensions
       router/                     # go_router configuration
          app_router.dart
       theme/                      # App theme
           app_theme.dart
    data/                           # Data layer
       models/                     # Freezed data models
       repositories/               # Repository implementations
       services/                   # API services
    domain/                         # Domain layer
       entities/                   # Business entities
       repositories/               # Repository interfaces
    presentation/                   # UI layer
       common/                     # Shared widgets
       features/                   # Feature modules
          feature_name/
              providers/          # Riverpod providers
              widgets/            # Feature-specific widgets
              feature_screen.dart
       providers/                  # Global providers
    main.dart
    app.dart
 test/
    unit/                           # Unit tests
    widget/                         # Widget tests
    integration/                    # Integration tests
 pubspec.yaml
 analysis_options.yaml
 CLAUDE.md
```

---

## Riverpod State Management

### Provider Types

```dart
// Simple value provider
final appNameProvider = Provider<String>((ref) => 'My App');

// StateProvider for simple mutable state
final counterProvider = StateProvider<int>((ref) => 0);

// NotifierProvider for complex state logic
final userProvider = NotifierProvider<UserNotifier, User?>(() => UserNotifier());

// AsyncNotifierProvider for async operations
final usersProvider = AsyncNotifierProvider<UsersNotifier, List<User>>(
  () => UsersNotifier(),
);

// FutureProvider for simple async data
final configProvider = FutureProvider<Config>((ref) async {
  return await ref.watch(configServiceProvider).loadConfig();
});

// StreamProvider for real-time data
final messagesProvider = StreamProvider<List<Message>>((ref) {
  return ref.watch(messageServiceProvider).watchMessages();
});

// Family providers for parameterized data
final userByIdProvider = FutureProvider.family<User, String>((ref, userId) async {
  return await ref.watch(userRepositoryProvider).getUser(userId);
});
```

### Notifier Pattern

```dart
@riverpod
class Users extends _$Users {
  @override
  Future<List<User>> build() async {
    return await _fetchUsers();
  }

  Future<List<User>> _fetchUsers() async {
    final repository = ref.read(userRepositoryProvider);
    return await repository.getUsers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchUsers());
  }


---

> **Referencia detallada**: [
eferences/detail.md](references/detail.md)
```
