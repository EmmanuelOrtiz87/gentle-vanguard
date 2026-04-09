# Mobile Templates

This directory contains mobile app framework templates.

## Available Templates

| Framework | Package File | Description |
|-----------|--------------|-------------|
| React Native | `package.react-native.json` | React Native with TypeScript |
| Flutter | `package.flutter.json` | Flutter with Dart |

## React Native

```bash
# Copy template
cp package.react-native.json package.json
npm install

# Run on Android
npm run android

# Run on iOS
npm run ios

# Start Metro bundler
npm start
```

## Flutter

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Build release APK
flutter build apk --release

# Build release IPA
flutter build ios --release
```

## Expo (Alternative)

For React Native with Expo:

```bash
npx create-expo-app {{project-name}}
```

## Structure

```
mobile/
├── src/                   # Source code
│   ├── components/         # Reusable components
│   ├── screens/           # Screen/page components
│   ├── navigation/        # Navigation configuration
│   ├── services/          # API clients, services
│   ├── hooks/             # Custom hooks
│   ├── utils/             # Utilities
│   └── types/             # Type definitions
├── android/               # Android native code
├── ios/                   # iOS native code
└── package.*.json         # Framework-specific packages
```
