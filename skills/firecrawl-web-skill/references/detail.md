---

## Integration with Gentle-Vanguard

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

### Gentle-Vanguard gv.ps1 Integration

```powershell
# Scrape URL
.\gv.ps1 scrape "https://example.com" --format markdown

# Batch scrape
.\gv.ps1 scrape urls.txt --output content/

# Web search
.\gv.ps1 search "Next.js best practices" --limit 5
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
