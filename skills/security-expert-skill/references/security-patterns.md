# Security Patterns Reference

## Authentication & Authorization

### JWT Implementation

**DO:**
```typescript
import jwt from 'jsonwebtoken';

const SECRET = process.env.JWT_SECRET;
const options = {
  expiresIn: '1h',
  algorithm: 'HS256'
};

const token = jwt.sign(payload, SECRET, options);

// Verify with proper error handling
try {
  const decoded = jwt.verify(token, SECRET, { algorithms: ['HS256'] });
} catch (err) {
  if (err.name === 'TokenExpiredError') {
    // Handle expired token
  }
}
```

**DON'T:**
```typescript
// No expiration
jwt.sign(payload, secret);

// Weak algorithm
jwt.sign(payload, secret, { algorithm: 'HS256' }); // OK
jwt.sign(payload, secret, { algorithm: 'none' }); // VULNERABLE

// No verification
const decoded = jwt.decode(token); // Just decode, don't verify!
```

### Password Hashing

**DO (bcrypt):**
```typescript
import bcrypt from 'bcrypt';
const saltRounds = 12;
const hash = await bcrypt.hash(password, saltRounds);
const match = await bcrypt.compare(password, hash);
```

**DO (Argon2):**
```python
from argon2 import PasswordHasher
ph = PasswordHasher()
hash = ph.hash(password)
ph.verify(hash, password)
```

**DON'T:**
```python
# Never use these
import hashlib
hashlib.md5(password)     # Weak
hashlib.sha1(password)   # Weak
hashlib.sha256(password) # Better but no salt
```

## Input Validation

### SQL Injection Prevention

**DO (Parameterized Queries):**
```typescript
// Node.js with pg
const query = 'SELECT * FROM users WHERE id = $1';
const result = await pool.query(query, [userId]);

// Python with psycopg2
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
```

**DON'T:**
```typescript
// String concatenation - SQL INJECTION
const query = `SELECT * FROM users WHERE id = ${userId}`;
const query = `SELECT * FROM users WHERE name = '${name}'`;
```

### XSS Prevention

**DO:**
```typescript
// React (auto-escapes)
return <div>{userInput}</div>;

// Express with helmet
import helmet from 'helmet';
app.use(helmet.xssFilter());

// Template engines (Handlebars)
{{{unescaped}}}  // VULNERABLE
{{escaped}}      // Safe
```

**DON'T:**
```typescript
// Direct innerHTML
element.innerHTML = userInput;  // VULNERABLE

// jQuery
$(selector).html(userInput);    // VULNERABLE
```

## API Security

### CORS Configuration

**DO:**
```typescript
import cors from 'cors';

app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(','),
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

**DON'T:**
```typescript
// Allow all origins
app.use(cors({ origin: '*' }));  // VULNERABLE

// Allow credentials with wildcard
app.use(cors({ origin: '*', credentials: true }));  // VULNERABLE
```

### Rate Limiting

**DO:**
```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per window
  message: 'Too many requests',
  standardHeaders: true,
  legacyHeaders: false
});

app.use('/api', limiter);
```

### Security Headers

```typescript
import helmet from 'helmet';

app.use(helmet());

// Specific headers
app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    scriptSrc: ["'self'", "'strict-dynamic'"],
    styleSrc: ["'self'", "https://fonts.googleapis.com"],
    fontSrc: ["'self'", "https://fonts.gdn" ],
    imgSrc: ["'self'", "data:"],
    connectSrc: ["'self'"],
    frameAncestors: ["'none'"],
    upgradeInsecureRequests: []
  }
}));
```

## Secrets Management

### DO:
```typescript
// .env file (not committed)
DATABASE_URL=postgres://user:password@host:5432/db
API_KEY=your-secret-key

// Load securely
import dotenv from 'dotenv';
dotenv.config();

const dbUrl = process.env.DATABASE_URL;
```

### Environment Variables:
```bash
# .gitignore
.env
.env.local
.env.*.local

# .gitignore examples (to commit)
.env.example
.env.template
```

### DON'T:
```typescript
// Hardcoded secrets
const API_KEY = "sk_live_1234567890abcdef";
const DB_PASSWORD = "mySecretPassword123";

// In code comments
// API Key: sk_live_1234567890abcdef

// In URLs
fetch('https://api.example.com?key=sk_live_1234567890');
```

## Cryptography

### DO:
```typescript
import crypto from 'crypto';

function encrypt(text, key) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-gcm', Buffer.from(key, 'hex'), iv);
  
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  
  const authTag = cipher.getAuthTag().toString('hex');
  
  return iv.toString('hex') + ':' + encrypted + ':' + authTag;
}
```

### DON'T:
```javascript
// Weak algorithms
crypto.createCipher('aes128', key);  // Weak
crypto.createHash('md5');            // Weak
crypto.createHash('sha1');           // Deprecated
```

## Command Injection Prevention

### DO:
```typescript
import { execFile } from 'child_process';
import { validateInput } from './validators';

// Use execFile with array args
execFile('node', ['--versión'], (error, stdout) => {
  // Safe
});

// Or use libraries designed for safe command execution
```

### DON'T:
```typescript
const { exec } = require('child_process');

// VULNERABLE - Command Injection
exec(`ls ${userInput}`, (err, data) => {});

// VULNERABLE
exec(`git commit -m "${message}"`, (err, data) => {});
```

## File Upload Security

```typescript
import multer from 'multer';
import path from 'path';

const storage = multer.diskStorage({
  destination: './uploads',
  filename: (req, file, cb) => {
    // Generate random filename
    const uniqueSuffix = crypto.randomBytes(16).toString('hex');
    cb(null, uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    // Validate file types
    const allowedTypes = ['image/jpeg', 'image/png', 'application/pdf'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'));
    }
  }
});
```

## Logging Security

### DON'T Log:
```typescript
// Never log these
console.log(req.body.password);
console.log(req.headers.authorization);
console.log(`API Key: ${apiKey}`);
console.log(userCreditCardNumber);
```

### DO Log (Sanitized):
```typescript
// Log safely
logger.info('User login attempt', {
  userId: user.id,
  email: sanitize(user.email), // Remove sensitive parts
  ip: req.ip,
  timestamp: new Date()
});
```

## Dependency Security

### npm:
```bash
# Audit before install
npm audit

# Check for outdated packages
npm outdated

# Use package-lock.json
npm ci  # Clean install from lock file
```

### Python:
```bash
# Check for vulnerabilities
pip audit
safety check

# Use requirements.txt with pinned versións
pip freeze > requirements.lock
```

### Go:
```bash
# Vulnerability scanning
govulncheck ./...

# Verify dependencies
go mod verify
```

## OWASP Top 10 (2021)

1. **Broken Access Control** - Implement proper authorization
2. **Cryptographic Failures** - Use strong encryption, proper key management
3. **Injection** - Validate and sanitize all input
4. **Insecure Design** - Threat modeling, secure architecture
5. **Security Misconfiguration** - Hardened defaults, minimal attack surface
6. **Vulnerable Components** - Keep dependencies updated
7. **Authentication Failures** - Strong password policies, MFA
8. **Software Integrity Failures** - Verify integrity of components
9. **Logging & Monitoring** - Proper logging without sensitive data
10. **SSRF** - Validate and sanitize URLs

## Security Checklist

- [ ] All user input validated and sanitized
- [ ] Parameterized queries for all database operations
- [ ] No hardcoded secrets in code
- [ ] Secrets in environment variables
- [ ] HTTPS enforced
- [ ] Security headers configured
- [ ] Rate limiting implemented
- [ ] Authentication tokens have expiration
- [ ] Passwords hashed with bcrypt/argon2
- [ ] Dependencies audited and updated
- [ ] No sensitive data in logs
- [ ] CORS properly configured
- [ ] File uploads validated
- [ ] Error messages don't leak information
- [ ] Security headers set

