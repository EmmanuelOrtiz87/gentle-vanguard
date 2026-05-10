---
name: typescript-skill
description: >
  TypeScript strict patterns: types, interfaces, generics, utility types. Trigger: "TypeScript",
  "interface", "type", "generic", "utility types", "typescript strict".
---

## When to Use

- TypeScript projects
- Type safety implementation
- API type definitions
- Generic utilities

## Core Types

```typescript
// Primitives
type String = string;
type Number = number;
type Boolean = boolean;

// Arrays
type StringArray = string[];
type NumberArray = Array<number>;

// Objects
type User = {
  id: number;
  name: string;
  email: string;
  createdAt: Date;
};
```

## Interfaces vs Types

```typescript
// Interface - for object shapes
interface User {
  id: number;
  name: string;
}

// Can be extended
interface AdminUser extends User {
  permissions: string[];
}

// Type - for unions, intersections, aliases
type Status = 'pending' | 'active' | 'deleted';
type UserOrAdmin = User | AdminUser;
```

## Generics

```typescript
// Generic function
function first<T>(arr: T[]): T | undefined {
  return arr[0];
}

// Generic interface
interface Repository<T> {
  findById(id: number): Promise<T | null>;
  findAll(): Promise<T[]>;
  create(data: Omit<T, 'id'>): Promise<T>;
  update(id: number, data: Partial<T>): Promise<T>;
  delete(id: number): Promise<void>;
}

// Generic constraint
function longestItem<T extends { length: number }>(a: T, b: T): T {
  return a.length > b.length ? a : b;
}
```

## Utility Types

```typescript
interface User {
  id: number;
  name: string;
  email: string;
  password: string;
}

// Partial - all properties optional
type PartialUser = Partial<User>;

// Required - all properties required
type RequiredUser = Required<Partial<User>>;

// Pick - select properties
type UserPreview = Pick<User, 'id' | 'name'>;

// Omit - remove properties
type UserWithoutPassword = Omit<User, 'password'>;

// Record - key-value object
type UserMap = Record<string, User>;

// NonNullable - remove null/undefined
type NonNullEmail = NonNullable<User['email']>;

// ReturnType - get function return type
function createUser() {
  return { id: 1, name: 'John' };
}
type CreatedUser = ReturnType<typeof createUser>;
```

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
```

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
