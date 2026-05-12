---
name: firecrawl-web-skill
description: >
  Web scraping, data extraction, and browser automation using Firecrawl. Trigger: "web scrape",
  "extract data", "crawl website", "markdown", "screenshot", "web search", "scrape docs",
  "competitive analysis", "firecrawl"
license: Apache-2.0
metadata:
  author: foundation
  versión: '1.0'
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, Task, webfetch, websearch
---

# Firecrawl Web Skill

Web scraping and data extraction capabilities using Firecrawl for AI agent workflows.

## When to Use

**USE this skill when:**

- Extracting content from websites for analysis
- Converting web pages to markdown for processing
- Taking screenshots of web pages
- Competitive analysis and research
- Documentation crawling
- URL metadata extraction
- Web search for current information

**DON'T use when:**

- Accessing authenticated routes (use dedicated MCP)
- Scraping at scale (consider dedicated service)
- Legal restrictions apply

---

## Firecrawl Features

### 1. Markdown Extraction

Convert web pages to clean markdown:

```python
# Via Firecrawl API
import firecrawl

app = firecrawl.FirecrawlApp(api_key="fc-key")
result = app.scrape_url(
    url="https://docs.example.com",
    formats=["markdown"]
)
print(result.markdown)
```

### 2. Screenshot Capture

Capture full-page screenshots:

```python
result = app.scrape_url(
    url="https://example.com",
    formats=["screenshot", "markdown"]
)
# result.screenshot contains base64 image
```

### 3. Structured Data

Extract to JSON schema:

```python
from pydantic import BaseModel

class Product(BaseModel):
    name: str
    price: float
    in_stock: bool

result = app.scrape_url(
    url="https://shop.example.com",
    schema=Product,
    formats=["json"]
)
products = result.json
```

### 4. Web Search

Search and extract from results:

```python
result = app.search(
    query="Next.js 15 app router best practices",
    limit=5
)
for item in result.data:
    print(item.url, item.title)
```

### 5. Batch Crawling

Crawl multiple URLs:

```python
urls = [
    "https://docs.example.com/intro",
    "https://docs.example.com/advanced",
    "https://docs.example.com/api"
]
result = app.crawl_urls(urls, limit=10)
```

---

## Integration with Foundation

### Environment Variables

```
FIRECRAWL_API_KEY=fc-...  # Get from firecrawl.ai
```

### MCP Integration

Add to `config/workspace.config.json`:

```json
{
  "mcpIntegrations": {
    "firecrawl": {
      "enabled": false,
      "serverName": "firecrawl",
      "command": "npx",
      "args": ["-y", "@mendable/firecrawl-mcp"],
      "requiredEnv": ["FIRECRAWL_API_KEY"]
    }
  }
}
```

### Foundation wf.ps1 Integration

```powershell
# Scrape URL
.\wf.ps1 scrape "https://example.com" --format markdown

# Batch scrape
.\wf.ps1 scrape urls.txt --output content/

# Web search
.\wf.ps1 search "Next.js best practices" --limit 5
```

---

## Use Cases

### 1. Competitive Analysis

```python
competitors = ["https://vercel.com", "https://netlify.com", "https://cloudflare.com"]
results = []
for url in competitors:
    result = app.scrape_url(url, formats=["markdown", "metadata"])
    results.append({
        "url": url,
        "title": result.metadata.title,
        "description": result.metadata.description,
        "content": result.markdown[:5000]
    })
# Analyze differences
```

### 2. Documentation Sync

```python
docs_urls = get_all_docs_urls()  # Your docs
result = app.crawl_urls(docs_urls, limit=20)
save_markdown_files(result.data, "docs/sync/")
```

### 3. Research

```python
query = "Claude Code skills best practices 2026"
result = app.search(query, limit=10)
extract_insights(result.data)
```

---

## Error Handling

```python
try:
    result = app.scrape_url(url, formats=["markdown"])
except RateLimitError:
    wait_and_retry()
except ExtractionError:
    fallback_to_browser()
```

---

## Best Practices

1. **Respect robots.txt** - Check before scraping
2. **Rate limiting** - Add delays between requests
3. **Caching** - Store results for future use
4. **Error handling** - Plan for failures
5. **Token efficient** - Trim unnecessary content
