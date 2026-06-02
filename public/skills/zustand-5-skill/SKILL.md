---
name: zustand-5-skill
description: >
  Zustand 5 state management: create store, actions, slices, persistence. Trigger: "Zustand", "state
  management", "store", "useStore", "persistence".
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
  setUser: (user) => set({ user }),
  logout: () => set({ user: null }),
});

// Combine slices
const useStore = create((...a) => ({
  ...createCounterSlice(...a),
  ...createUserSlice(...a),
}));
```

## Persistence

```typescript
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

const useSettingsStore = create(
  persist(
    (set) => ({
      theme: 'light',
      language: 'en',
      setTheme: (theme) => set({ theme }),
      setLanguage: (language) => set({ language }),
    }),
    {
      name: 'settings-storage', // localStorage key
      partialize: (state) => ({ theme: state.theme }), // only persist theme
    },
  ),
);
```

## Async Actions

```typescript
interface TodoStore {
  todos: Todo[];
  isLoading: boolean;
  fetchTodos: () => Promise<void>;
  addTodo: (title: string) => Promise<void>;
  toggleTodo: (id: string) => void;
  deleteTodo: (id: string) => void;
}

const useTodoStore = create<TodoStore>((set, get) => ({
  todos: [],
  isLoading: false,

  fetchTodos: async () => {
    set({ isLoading: true });
    const todos = await api.getTodos();
    set({ todos, isLoading: false });
  },

  addTodo: async (title) => {
    const todo = await api.createTodo({ title, completed: false });
    set((state) => ({ todos: [...state.todos, todo] }));
  },

  toggleTodo: (id) => {
    set((state) => ({
      todos: state.todos.map((t) => (t.id === id ? { ...t, completed: !t.completed } : t)),
    }));
  },

  deleteTodo: (id) => {
    set((state) => ({
      todos: state.todos.filter((t) => t.id !== id),
    }));
  },
}));
```

## Selectors

```typescript
// Select single value
const count = useCounterStore((state) => state.count);

// Select multiple values
const { count, user } = useStore((state) => ({ count: state.count, user: state.user }));

// Derived value
const doubleCount = useCounterStore((state) => state.count * 2);

// Selector with equality check
const userName = useUserStore(
  (state) => state.user?.name,
  (prev, next) => prev === next, // custom equality
);
```

## Quick Reference

| Pattern     | Code                                          |
| ----------- | --------------------------------------------- |
| Basic store | `create<Store>((set) => ({ ... }))`           |
| Action      | `set((state) => ({ ... }))`                   |
| Selector    | `useStore((s) => s.property)`                 |
| Persist     | `persist(store, { name: 'key' })`             |
| Async       | `async (...) => { set({loading:true}); ... }` |
