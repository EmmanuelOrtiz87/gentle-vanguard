---

## State Management

### Local State First

```typescript
// Start with useState, escalate only when needed
const [value, setValue] = useState('');
```

### Zustand for Global State (if needed)

```typescript
// store/useAppStore.ts
import { create } from 'zustand';

interface AppState {
  user: User | null;
  setUser: (user: User | null) => void;
}

export const useAppStore = create<AppState>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
}));
```

### React Query for Server State

```typescript
// hooks/useItems.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

export function useItems() {
  return useQuery({
    queryKey: ['items'],
    queryFn: fetchItems,
  });
}

export function useCreateItem() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: createItem,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['items'] });
    },
  });
}
```

---

## Testing

### Component Testing with React Native Testing Library

```typescript
import { render, fireEvent } from '@testing-library/react-native';
import { Button } from './Button';

describe('Button', () => {
  it('calls onPress when pressed', () => {
    const onPress = jest.fn();
    const { getByText } = render(<Button label="Click me" onPress={onPress} />);

    fireEvent.press(getByText('Click me'));

    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('does not call onPress when disabled', () => {
    const onPress = jest.fn();
    const { getByText } = render(<Button label="Click me" onPress={onPress} disabled />);

    fireEvent.press(getByText('Click me'));

    expect(onPress).not.toHaveBeenCalled();
  });
});
```

### Hook Testing

```typescript
import { renderHook, act } from '@testing-library/react-hooks';
import { useCounter } from './useCounter';

describe('useCounter', () => {
  it('increments counter', () => {
    const { result } = renderHook(() => useCounter());

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });
});
```

---

## Platform-Specific Code

### Use Platform.select Sparingly

```typescript
import { Platform } from 'react-native';

const styles = StyleSheet.create({
  shadow: Platform.select({
    ios: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.1,
    },
    android: {
      elevation: 2,
    },
  }),
});
```

### Separate Files for Complex Differences

```
Component/
 Component.tsx          # Shared logic
 Component.ios.tsx      # iOS-specific
 Component.android.tsx  # Android-specific
 index.ts
```

---

## React Native Anti-Patterns

- Inline styles - use StyleSheet.create
- Logic in render - extract to hooks
- Deep component nesting - flatten hierarchy
- Anonymous functions in props - use useCallback
- Index as key in lists - use stable IDs
- Direct state mutation - always use setter
- Mixing business logic with UI - keep core/ pure
- Ignoring TypeScript errors - fix them
- Large components - split into smaller pieces
