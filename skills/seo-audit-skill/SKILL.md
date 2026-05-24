---
name: seo-audit-skill
description: >
  SEO audit, technical SEO, meta tags, structured data, performance. Trigger: "SEO", "audit SEO",
  "meta tags", "structured data", "sitemap", "robots.txt", "canonical", "keywords", "ranking",
  "search engine"
license: Apache-2.0
metadata:
  author: gentle-vanguard
  versión: '1.0'
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, Task
---

# SEO Audit Skill

Comprehensive SEO auditing and optimization for web applications.

## When to Use

**USE this skill when:**

- Auditing website SEO
- Fixing meta tags
- Adding structured data
- Optimizing for search engines
- Technical SEO issues

**DON'T use when:**

- Content SEO (that's copywriting)
- Paid search (that's ads)

---

## Technical SEO Checklist

### 1. Meta Tags

```html
<!DOCTYPE html>
<html lang="es">
  <head>
    <title>Page Title | Brand</title>
    <meta name="description" content="Description under 160 chars" />
    <meta name="keywords" content="keyword1, keyword2" />
    <meta name="author" content="Brand Name" />

    <!-- Open Graph -->
    <meta property="og:title" content="Share Title" />
    <meta property="og:description" content="Share Description" />
    <meta property="og:image" content="https://example.com/image.jpg" />
    <meta property="og:url" content="https://example.com/page" />
    <meta property="og:type" content="website" />

    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content="Tweet Title" />
    <meta name="twitter:description" content="Tweet Description" />
    <meta name="twitter:image" content="https://example.com/image.jpg" />

    <!-- Canonical -->
    <link rel="canonical" href="https://example.com/page" />
  </head>
</html>
```

### 2. Structured Data (JSON-LD)

```html
<script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "Page Name",
    "description": "Page description",
    "url": "https://example.com/page"
  }
</script>
```

#### Organization

```html
<script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Organization",
    "name": "Company Name",
    "url": "https://example.com",
    "logo": "https://example.com/logo.png",
    "sameAs": [
      "https://twitter.com/company",
      "https://facebook.com/company",
      "https://linkedin.com/company"
    ]
  }
</script>
```

#### Product

```html
<script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Product",
    "name": "Product Name",
    "description": "Product description",
    "image": "https://example.com/product.jpg",
    "offers": {
      "@type": "Offer",
      "price": "99.99",

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)