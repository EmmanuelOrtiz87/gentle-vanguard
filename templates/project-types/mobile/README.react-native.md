# React Native Project Structure

```
{{project-name}}/
 src/
    components/      # Reusable UI components
    screens/         # Screen components
    navigation/      # Navigation configuration
    services/        # API clients, services
    hooks/           # Custom hooks
    utils/           # Utility functions
    types/           # TypeScript types
    store/           # State management
    constants/       # Constants, theme
 __tests__/           # Test files
 android/             # Android native code
 ios/                 # iOS native code
 index.js             # Entry point
 App.tsx              # Root component
 package.json
```

## Navigation Structure

```typescript
// Stack Navigator
const Stack = createNativeStackNavigator();

// Tab Navigator
const Tab = createBottomTabNavigator();

// Root Navigator
function AppNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen name="Home" component={HomeScreen} />
      <Stack.Screen name="Profile" component={ProfileScreen} />
    </Stack.Navigator>
  );
}
```

## Components

```typescript
// Example component
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

interface Props {
  title: string;
}

export const Card: React.FC<Props> = ({ title }) => {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>{title}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    padding: 16,
    backgroundColor: '#fff',
    borderRadius: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  title: {
    fontSize: 18,
    fontWeight: 'bold',
  },
});
```

## Testing

```bash
# Run tests
npm test

# Run with coverage
npm test -- --coverage

# Run specific test
npm test -- --testPathPattern="components"
```
