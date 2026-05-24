  Future<void> addUser(User user) async {
    final repository = ref.read(userRepositoryProvider);
    await repository.addUser(user);
    ref.invalidateSelf();
  }
}
```

### AsyncValue Handling

```dart
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return usersAsync.when(
      data: (users) => UsersList(users: users),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplay(
        error: error,
        onRetry: () => ref.invalidate(usersProvider),
      ),
    );
  }
}

// Pattern matching alternative
Widget build(BuildContext context, WidgetRef ref) {
  final usersAsync = ref.watch(usersProvider);

  return switch (usersAsync) {
    AsyncData(:final value) => UsersList(users: value),
    AsyncLoading() => const LoadingIndicator(),
    AsyncError(:final error) => ErrorDisplay(error: error),
  };
}
```

---

## References

See `references/patterns.md` for detailed patterns and code examples.