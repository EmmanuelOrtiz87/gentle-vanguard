---
name: seo-audit-skill
description: >
  SEO audit, technical SEO, meta tags, structured data, performance.
  Trigger: "SEO", "audit SEO", "meta tags", "structured data", "sitemap",
  "robots.txt", "canonical", "keywords", "ranking", "search engine"
license: Apache-2.0
metadata:
  author: workspace-foundation
  versión: "1.0"
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
  <meta name="description" content="Description under 160 chars">
  <meta name="keywords" content="keyword1, keyword2">
  <meta name="author" content="Brand Name">
  
  <!-- Open Graph -->
  <meta property="og:title" content="Share Title">
  <meta property="og:description" content="Share Description">
  <meta property="og:image" content="https://example.com/image.jpg">
  <meta property="og:url" content="https://example.com/page">
  <meta property="og:type" content="website">
  
  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Tweet Title">
  <meta name="twitter:description" content="Tweet Description">
  <meta name="twitter:image" content="https://example.com/image.jpg">
  
  <!-- Canonical -->
  <link rel="canonical" href="https://example.com/page">
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
    "priceCurrency": "USD",
    "availability": "https://schema.org/InStock"
  }
}
</script>
```

#### FAQ

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "Question?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Answer."
      }
    }
  ]
}
</script>
```

### 3. Sitemap.xml

```xml
<?xml versión="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <changefreq>daily</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://example.com/about</loc>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
</urlset>
```

### 4. Robots.txt

```
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /private/

Sitemap: https://example.com/sitemap.xml
```

### 5. Performance

```html
<!-- Preload critical assets -->
<link rel="preload" href="/fonts/main.woff2" as="font" type="font/woff2" crossorigin>

<!-- Prefetch next page -->
<link rel="prefetch" href="/next-page">

<!-- Async non-critical CSS -->
<link rel="preload" href="/styles/non-critical.css" as="style" media="print" onload="this.media='all'">
```

### 6. hreflang (Multilingual)

```html
<link rel="alternate" hreflang="es" href="https://example.com/es/">
<link rel="alternate" hreflang="en" href="https://example.com/en/">
<link rel="alternate" hreflang="x-default" href="https://example.com/">
```

---

## Audit Checklist

| Category | Check | Priority |
|----------|-------|----------|
| Meta | Title < 60 chars | Critical |
| Meta | Description < 160 chars | Critical |
| Meta | Open Graph tags | High |
| Meta | Twitter Card | High |
| Schema | JSON-LD valid | High |
| Schema | Organization schema | High |
| Schema | Product/FAQ schem | Medium |
| Technical | Sitemap.xml | Critical |
| Technical | Robots.txt | High |
| Technical | Canonical URLs | High |
| Performance | Font preloading | Medium |
| Performance | Image optimization | High |
| Links | Internal linking | Medium |
| Links | External nofollow | Low |

---

## Common Issues

### 1. Missing Meta Description

```html
<!-- Wrong -->
<meta name="description">

<!-- Right -->
<meta name="description" content="Comprehensive guide to...">
```

### 2. Duplicate Titles

```html
<!-- Use unique titles per page -->
<title>Home | Brand</title>
<title>About | Brand</title>
<title>Contact | Brand</title>
```

### 3. Missing Canonical

```html
<link rel="canonical" href="https://example.com/page">
```

### 4. Invalid JSON-LD

```html
<!-- Validate with Google Rich Results Test -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "WebPage",
  "name": "Page Name"
}
</script>
```

---

## Foundation Integration

```powershell
# Run SEO audit
.\wf.ps1 audit seo

# Fix common issues
.\wf.ps1 fix seo --dry-run

# Add structured data
.\wf.ps1 schema add organization
```

---

## Tools

- [Google Rich Results Test](https://search.google.com/test/rich-results)
- [Schema Markup Validator](https://validator.schema.org)
- [Google PageSpeed Insights](https://pagespeed.web.dev)
- [Sitemap Generator](https://www.xml-sitemaps.com)

