# Flutter Project Structure

```
{{project-name}}/
 lib/
    main.dart           # Entry point
    app.dart            # App configuration
    core/               # Core utilities
       constants/      # App constants
       theme/          # Theme configuration
       utils/          # Utility functions
    data/               # Data layer
       models/         # Data models
       repositories/   # Repository implementations
       sources/        # Data sources (API, local)
    domain/             # Domain layer
       entities/       # Business entities
       repositories/   # Repository interfaces
       usecases/       # Use cases
    presentation/       # Presentation layer
       pages/          # Screen widgets
       widgets/        # Reusable widgets
       providers/     # State providers
    routes/             # Navigation routes
 test/                   # Test files
 android/               # Android native code
 ios/                   # iOS native code
 pubspec.yaml
```

## Widget Example

```dart
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final String title;
  
  const MyWidget({Key? key, required this.title}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(title),
      ),
    );
  }
}
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```
