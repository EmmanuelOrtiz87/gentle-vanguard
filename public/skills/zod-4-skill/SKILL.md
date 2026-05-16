---
name: zod-4-skill
description: >
  Zod 4 schema validation: schemas, parsing, transformations, error handling. Trigger: "Zod",
  "schema validation", "input validation", "type safety".
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
```

## Parsing vs Safe Parse

```typescript
// Throws on error
const user = UserSchema.parse(data);

// Returns result object
const result = UserSchema.safeParse(data);
if (!result.success) {
  console.log(result.error.issues);
} else {
  console.log(result.data);
}
```

## Error Handling

```typescript
const result = UserSchema.safeParse(data);

if (!result.success) {
  // Format errors
  const errors = result.error.flatten().fieldErrors;
  // { email: ['Invalid email'], password: ['Too short'] }
}
```

## Environment Variables

```typescript
const EnvSchema = z.object({
  DATABASE_URL: z.string().url(),
  PORT: z.coerce.number().default(3000),
  NODE_ENV: z.enum(['development', 'production']).default('development'),
  API_KEY: z.string().optional(),
});

const env = EnvSchema.parse(process.env);
```

## API Validation

```typescript
// Next.js API route
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

const CreateUserSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
});

export async function POST(req: NextRequest) {
  const body = await req.json();

  const result = CreateUserSchema.safeParse(body);
  if (!result.success) {
    return NextResponse.json({ error: result.error.flatten() }, { status: 400 });
  }

  // Use result.data (typed)
  const user = await db.user.create({ data: result.data });
  return NextResponse.json(user, { status: 201 });
}
```

## Quick Reference

| Method           | Purpose                           |
| ---------------- | --------------------------------- |
| `.parse()`       | Validate and return data (throws) |
| `.safeParse()`   | Validate, return result object    |
| `.optional()`    | Allow undefined                   |
| `.nullable()`    | Allow null                        |
| `.default()`     | Default value if undefined        |
| `.transform()`   | Transform on parse                |
| `.refine()`      | Custom validation                 |
| `.superRefine()` | Advanced refinement               |
