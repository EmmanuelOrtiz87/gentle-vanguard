  const [optimisticComments, addOptimistic] = useOptimistic(comments, (state, newComment) => [
    ...state,
    newComment,
  ]);

  async function handleAdd(text: string) {
    const tempComment = { id: 'temp', text, pending: true };
    addOptimistic(tempComment);

    await addComment(postId, text);
  }

  return (
    <ul>
      {optimisticComments.map((c) => (
        <li key={c.id} style={{ opacity: c.pending ? 0.5 : 1 }}>
          {c.text}
        </li>
      ))}
    </ul>
  );
}
```

## Component Patterns

```tsx
// Composition pattern
function Card({ children, title }) {
  return (
    <div className="card">
      {title && <h3>{title}</h3>}
      {children}
    </div>
  );
}

// Render props pattern
function DataFetcher({ render, url }) {
  const [data, setData] = useState(null);

  useEffect(() => {
    fetch(url)
      .then((r) => r.json())
      .then(setData);
  }, [url]);

  return render(data);
}

// Usage
<DataFetcher
  url="/api/users"
  render={(data) => (
    <ul>
      {data?.map((u) => (
        <li key={u.id}>{u.name}</li>
      ))}
    </ul>
  )}
/>;
```

## Custom Hooks

```tsx
function useLocalStorage<T>(key: string, initialValue: T) {
  const [value, setValue] = useState<T>(() => {
    if (typeof window === 'undefined') return initialValue;
    const stored = localStorage.getItem(key);
    return stored ? JSON.parse(stored) : initialValue;
  });

  useEffect(() => {
    localStorage.setItem(key, JSON.stringify(value));
  }, [key, value]);

  return [value, setValue] as const;
}
```

## Error Boundaries

```tsx
class ErrorBoundary extends Component {
  state = { hasError: false };

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  render() {
    if (this.state.hasError) {
      return <h1>Something went wrong</h1>;
    }
    return this.props.children;
  }
}

// Usage
<ErrorBoundary>
  <MyComponent />
</ErrorBoundary>;
```

## Quick Reference

| Feature        | Usage                         |
| -------------- | ----------------------------- |
| useActionState | Form state with async actions |
| useFormStatus  | Submit button pending state   |
| useOptimistic  | Optimistic UI updates         |
| React Compiler | No useMemo/useCallback        |