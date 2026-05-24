---
name: react-native
description: React Native mobile patterns, platform-specific code
when-to-use: When working on React Native mobile app code
user-invocable: false
paths: ['**/*.tsx', '**/*.jsx', 'ios/**', 'android/**', 'app.json']
effort: medium
---

# React Native Skill

---

## Project Structure

```
project/
 src/
    core/                   # Pure business logic (no React)
       types.ts
       services/
    components/             # Reusable UI components
       Button/
          Button.tsx
          Button.test.tsx
          index.ts
       index.ts            # Barrel export
    screens/                # Screen components
       Home/
          HomeScreen.tsx
          useHome.ts      # Screen-specific hook
          index.ts
       index.ts
    navigation/             # Navigation configuration
    hooks/                  # Shared custom hooks
    store/                  # State management
    utils/                  # Utilities
 __tests__/
 android/
 ios/
 CLAUDE.md
```

---

## Component Patterns

### Functional Components Only

```typescript
// Good - simple, testable
interface ButtonProps {
  label: string;
  onPress: () => void;
  disabled?: boolean;
}

export function Button({ label, onPress, disabled = false }: ButtonProps): JSX.Element {
  return (
    <Pressable onPress={onPress} disabled={disabled}>
      <Text>{label}</Text>
    </Pressable>
  );
}
```

### Extract Logic to Hooks

```typescript
// useHome.ts - all logic here
export function useHome() {
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    setLoading(true);
    const data = await fetchItems();
    setItems(data);
    setLoading(false);
  }, []);

  return { items, loading, refresh };
}

// HomeScreen.tsx - pure presentation
export function HomeScreen(): JSX.Element {
  const { items, loading, refresh } = useHome();

  return (
    <ItemList items={items} loading={loading} onRefresh={refresh} />
  );
}
```

### Props Interface Always Explicit

```typescript
// Always define props interface, even if simple
interface ItemCardProps {
  item: Item;
  onPress: (id: string) => void;
}

export function ItemCard({ item, onPress }: ItemCardProps): JSX.Element {
  ...
}
```


---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)