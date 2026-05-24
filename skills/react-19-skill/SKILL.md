---
name: react-19-skill
description: >
  React 19 patterns with React Compiler: no useMemo/useCallback needed, useActionState,
  useFormStatus. Trigger: "React", "React 19", "useActionState", "useFormStatus", "React Compiler".
---

## When to Use

- Building React applications
- Using React 19 features
- React Compiler optimization
- Form handling patterns

## Project Structure

```
src/
 components/       # Components
 hooks/           # Custom hooks
 lib/             # Utilities
 app/             # Next.js (if using Next)
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

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)