---
name: zod-4-skill
description: >
  Zod 4 schema validation: schemas, parsing, transformations, error handling. Trigger: "Zod",
  "schema validation", "input validation", "type safety".
metadata:
  source: GV-native
---

## When to Use

- API input validation
- Form data validation
- Type inference from schemas
- Environment variable validation

## Basic Schemas

```typescript
import { z } from 'zod';

// Primitives
const stringSchema = z.string();
const numberSchema = z.number();
const booleanSchema = z.boolean();
const dateSchema = z.date();

// Optional
const optionalString = z.string().optional();

// Nullable
const nullableString = z.string().nullable();

// With default
const withDefault = z.string().default('hello');

// With coercion
const coercedNumber = z.coerce.number();
```

## Object Schemas

```typescript
const UserSchema = z.object({
  id: z.number(),
  name: z.string().min(2).max(100),
  email: z.string().email(),
  age: z.number().min(18).optional(),
  role: z.enum(['admin', 'user', 'guest']),
  createdAt: z.coerce.date(),
});

// Partial (all optional)
const PartialUser = UserSchema.partial();

// Pick specific fields
const UserPreview = UserSchema.pick({ id: true, name: true });

// Omit specific fields
const UserWithoutPassword = UserSchema.omit({ password: true });

// Extend
const AdminUser = UserSchema.extend({
  permissions: z.array(z.string()),
});
```

## Array Schemas

```typescript
const StringArray = z.array(z.string());
const NumberArray = z.array(z.number()).min(1).max(100);
const TupleSchema = z.tuple([z.string(), z.number()]);
```

## Union & Intersection

```typescript
// Union
const StatusSchema = z.union([
  z.object({ type: z.literal('success'), data: z.string() }),
  z.object({ type: z.literal('error'), error: z.string() }),
]);

// Discriminated union
const ActionSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('click'), x: z.number(), y: z.number() }),
  z.object({ type: z.literal('keypress'), key: z.string() }),
]);

// Intersection
const CombinedSchema = BaseSchema.merge(ExtraSchema);
```

## Transformations

```typescript
const UserInput = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

// Transform on parse
const UserOutput = UserInput.transform((data) => ({
  ...data,
  id: crypto.randomUUID(),
  createdAt: new Date(),
}));

---

> **Referencia detallada**: [
eferences/detail.md](references/detail.md)
```
