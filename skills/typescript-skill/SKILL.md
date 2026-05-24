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

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)