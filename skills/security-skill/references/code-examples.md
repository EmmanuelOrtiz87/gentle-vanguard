# Code Examples — Security Skill

## Input Validation

```typescript
// DANGEROUS - SQL Injection
const query = `SELECT * FROM users WHERE id = ${userId}`;

// SAFE - Parameterized Query
const query = `SELECT * FROM users WHERE id = $1`;
await db.query(query, [userId]);
```

```typescript
// DANGEROUS - XSS
const html = `<div>${userInput}</div>`;

// SAFE - Output Encoding
import DOMPurify from 'dompurify';
const html = DOMPurify.sanitize(userInput);
```

## Security Headers

```typescript
// helmet.js for Express
import helmet from 'helmet';

app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'https:'],
        connectSrc: ["'self'"],
        fontSrc: ["'self'"],
        objectSrc: ["'none'"],
        mediaSrc: ["'self'"],
        frameSrc: ["'none'"],
      },
    },
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true,
    },
  }),
);
```

## Secure Coding Patterns

```typescript
// File uploads
const upload = multer({
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/gif'];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'));
    }
  },
});

// Rate limiting
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: 'Too many requests',
});
```

## Dependency Security

```bash
# Audit dependencies
npm audit --audit-level=high

# Update dependencies
npm outdated
npm update

# Lock versions in production
npm ci
```

## Security Testing

```bash
# Dependency audit
npm audit

# OWASP dependency check
npx owasp-dependency-check

# Security headers check
curl -I https://your-site.com

# Secret scanning
gitrob scan

# SAST
semgrep --config=auto .
```

## Workspace Access Control (Gentle-Vanguard)

```powershell
# Check access level
.\scripts\utilities\access-control-middleware.ps1 -CheckOnly

# Authenticate with API key (8hr session)
.\scripts\utilities\auth-session.ps1 -ApiKey "BraianAmir1487!"

# Authenticate via security questions (recovery)
.\scripts\utilities\auth-session.ps1 -UseSecurityQuestions
```
