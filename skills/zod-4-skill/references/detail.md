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