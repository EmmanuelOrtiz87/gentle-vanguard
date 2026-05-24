# Jetpack Compose — Reference Patterns

## Navigation Compose

`rememberNavController()`, `NavHost(startDestination)`, `composable(route)`, `navArgument`, `navController.navigate()`. StringType args extracted from `backStackEntry.arguments`.

## Material 3 Theming

`darkColorScheme()`/`lightColorScheme()`, `MaterialTheme(colorScheme, typography)`. Access via `MaterialTheme.colorScheme.primary`, `.onSurfaceVariant`, `.surfaceVariant`, etc.

## Lists & Grids

`LazyVerticalGrid(columns = GridCells.Adaptive(minSize))`, `stickyHeader {}` with `Modifier.background(MaterialTheme.colorScheme.surface)`.

## Anti-Patterns

- `viewModel.loadData()` in composition → `LaunchedEffect(Unit) { vm.loadData() }`
- `remember { mutableStateOf(initial) }` without key → `remember(initial) { mutableStateOf(initial) }`
- Heavy computation in composition body → `derivedStateOf` with `remember(items)`
