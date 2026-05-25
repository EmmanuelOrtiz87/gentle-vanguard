function createUser() { return { id: 1, name: 'John' }; } type CreatedUser =
ReturnType<typeof createUser>;

````

## Type Guards

```typescript
// typeof
if (typeof x === 'string') {
  x.toUpperCase();
}

// instanceof
if (x instanceof Error) {
  x.message;
}

// Custom type guard
function isUser(obj: unknown): obj is User {
  return typeof obj === 'object' && obj !== null && 'id' in obj && 'name' in obj;
}

// Assertion function
function assertIsString(val: unknown): asserts val is string {
  if (typeof val !== 'string') {
    throw new Error('Not a string');
  }
}
````

## Discriminated Unions

```typescript
type Action =
  | { type: 'increment'; amount: number }
  | { type: 'decrement'; amount: number }
  | { type: 'reset' };

function reducer(state: number, action: Action): number {
  switch (action.type) {
    case 'increment':
      return state + action.amount;
    case 'decrement':
      return state - action.amount;
    case 'reset':
      return 0;
  }
}
```

## Async Types

```typescript
// Promise type
async function fetchUser(): Promise<User> {
  const res = await fetch('/api/user');
  return res.json();
}

// Awaited type
type UserData = Awaited<ReturnType<typeof fetchUser>>;

// Result type pattern
type Result<T, E = Error> = { success: true; data: T } | { success: false; error: E };

async function safeFetch<T>(url: string): Promise<Result<T>> {
  try {
    const res = await fetch(url);
    const data = await res.json();
    return { success: true, data };
  } catch (error) {
    return { success: false, error };
  }
}
```

## Module Types

```typescript
// Export
export interface User {
  id: number;
}

// Export type alias
export type UserId = number;

// Import
import { User, UserId } from './types';

// Re-export
export { User } from './types';
export type { AdminUser } from './admin';
```

## Declaration Merging

```typescript
// Extend existing interface
interface Window {
  analytics: Analytics;
}

// Extend module
declare module '*.svg' {
  const content: string;
  export default content;
}
```

## Quick Reference

| Pattern       | Example                    |
| ------------- | -------------------------- |
| Generic       | `Array<T>`, `Promise<T>`   |
| Optional      | `T?`, `Partial<T>`         |
| Union         | `A \| B`                   |
| Intersection  | `A & B`                    |
| Key selection | `Pick<T, K>`, `Omit<T, K>` |
| Type guard    | `x is Type`                |
