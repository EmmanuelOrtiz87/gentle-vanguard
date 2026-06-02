---
name: zustand-5-skill
description: >
  Zustand 5 state management: create store, actions, slices, persistence. Trigger: "Zustand", "state
  management", "store", "useStore", "persistence".
metadata:
  source: GV-native
---

## When to Use

- React state management
- Global state needs
- Simple state without Redux boilerplate
- Persistence requirements

## Basic Store

```typescript
import { create } from 'zustand';

interface CounterStore {
  count: number;
  increment: () => void;
  decrement: () => void;
  reset: () => void;
}

const useCounterStore = create<CounterStore>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}));

// Usage
function Counter() {
  const { count, increment, decrement, reset } = useCounterStore();

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={increment}>+</button>
      <button onClick={decrement}>-</button>
      <button onClick={reset}>Reset</button>
    </div>
  );
}
```

## Store with Actions Object

```typescript
interface UserStore {
  user: User | null;
  isLoading: boolean;
  error: string | null;
  actions: {
    fetchUser: (id: string) => Promise<void>;
    updateUser: (data: Partial<User>) => void;
    logout: () => void;
  };
}

const useUserStore = create<UserStore>((set, get) => ({
  user: null,
  isLoading: false,
  error: null,
  actions: {
    fetchUser: async (id) => {
      set({ isLoading: true, error: null });
      try {
        const user = await api.getUser(id);
        set({ user, isLoading: false });
      } catch (error) {
        set({ error: error.message, isLoading: false });
      }
    },
    updateUser: (data) => {
      set((state) => ({
        user: state.user ? { ...state.user, ...data } : null,
      }));
    },
    logout: () => set({ user: null }),
  },
}));

// Usage
function Profile() {
  const { user, isLoading, actions } = useUserStore();
  const { fetchUser, updateUser, logout } = actions;
  // ...
}
```

## Slices Pattern

```typescript
// Counter slice
const createCounterSlice = (set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
});

// User slice
const createUserSlice = (set) => ({
  user: null,

---

> **Referencia detallada**: [
eferences/detail.md](references/detail.md)
```
