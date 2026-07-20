# Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

// General API rate limit
app.use(
  '/api/',
  rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // 100 requests per window
    standardHeaders: true,
    legacyHeaders: false,
  }),
);

// Stricter limit for auth endpoints
app.use(
  '/api/auth/',
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 10, // 10 attempts per 15 minutes
  }),
);
```
