---
name: react-19-skill
description: >
  React 19 patterns with React Compiler: no useMemo/useCallback needed, useActionState, useFormStatus.
  Trigger: "React", "React 19", "useActionState", "useFormStatus", "React Compiler".
---

## When to Use

- Building React applications
- Using React 19 features
- React Compiler optimization
- Form handling patterns

## Project Structure

```
src/
├── components/       # Components
├── hooks/           # Custom hooks
├── lib/             # Utilities
└── app/             # Next.js (if using Next)
```

## React Compiler

React Compiler automatically optimizes:
- useMemo -> automatic
- useCallback -> automatic
- React.memo -> automatic

```tsx
// No manual memoization needed!
function ExpensiveComponent({ data }) {
  // React Compiler handles optimization
  const sorted = [...data].sort();
  return <List items={sorted} />;
}
```

## useActionState (React 19)

```tsx
import { useActionState } from 'react';
import { submitForm } from './actions';

function Form() {
  const [state, action, isPending] = useActionState(submitForm, null);
  
  return (
    <form action={action}>
      <input name="email" type="email" required />
      <button type="submit" disabled={isPending}>
        {isPending ? 'Submitting...' : 'Submit'}
      </button>
      {state?.error && <p error>{state.error}</p>}
    </form>
  );
}

// actions.ts
async function submitForm(prevState: any, formData: FormData) {
  const email = formData.get('email') as string;
  
  if (!email.includes('@')) {
    return { error: 'Invalid email' };
  }
  
  await saveEmail(email);
  return { success: true };
}
```

## useFormStatus (React 19)

```tsx
import { useFormStatus } from 'react-dom';

function SubmitButton() {
  const { pending } = useFormStatus();
  
  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Saving...' : 'Save'}
    </button>
  );
}

function Form() {
  return (
    <form>
      <input name="title" />
      <SubmitButton />
    </form>
  );
}
```

## useOptimistic (React 19)

```tsx
import { useOptimistic, startTransition } from 'react';
import { addComment, deleteComment } from './actions';

function Comments({ comments, postId }) {
  const [optimisticComments, addOptimistic] = useOptimistic(
    comments,
    (state, newComment) => [...state, newComment]
  );
  
  async function handleAdd(text: string) {
    const tempComment = { id: 'temp', text, pending: true };
    addOptimistic(tempComment);
    
    await addComment(postId, text);
  }
  
  return (
    <ul>
      {optimisticComments.map(c => (
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
    fetch(url).then(r => r.json()).then(setData);
  }, [url]);
  
  return render(data);
}

// Usage
<DataFetcher url="/api/users" render={data => (
  <ul>{data?.map(u => <li key={u.id}>{u.name}</li>)}</ul>
)} />
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
</ErrorBoundary>
```

## Quick Reference

| Feature | Usage |
|---------|-------|
| useActionState | Form state with async actions |
| useFormStatus | Submit button pending state |
| useOptimistic | Optimistic UI updates |
| React Compiler | No useMemo/useCallback |
