setUser: (user) => set({ user }), logout: () => set({ user: null }), });

// Combine slices const useStore = create((...a) => ({ ...createCounterSlice(...a),
...createUserSlice(...a), }));

````

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
````

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
