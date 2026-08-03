# Structured Output Formats

## Why Structured Outputs Matter

Unstructured text is hard to parse programmatically. Structured outputs (JSON, XML, markdown tables)
enable reliable downstream processing, validation, and integration.

## JSON Output

The most common structured format for programmatic consumption.

```
You are a data extraction assistant. Extract information from the following
text and return ONLY valid JSON with this schema:
{
  "name": "string",
  "age": "number",
  "occupation": "string",
  "skills": ["string"]
}

Text: John is a 34-year-old software engineer who knows Python, Go, and Kubernetes.
```

## XML Output

Useful for hierarchical data or when the output itself contains JSON-like structures.

```
Format your response as XML:
<analysis>
  <sentiment>positive|negative|neutral</sentiment>
  <key_topics>
    <topic>...</topic>
  </key_topics>
  <summary>...</summary>
</analysis>
```

## Markdown Tables

Best for human-readable comparison data.

```
Format your response as a markdown table:
| Model | Accuracy | Latency | Parameters |
|-------|----------|---------|------------|
| ...   | ...      | ...     | ...        |
```

## Ensuring Valid JSON

```python
# Always validate structured output
import json

def extract_json(text: str) -> dict:
    """Extract and validate JSON from model output."""
    if "```json" in text:
        text = text.split("```json")[1].split("```")[0]
    elif "```" in text:
        text = text.split("```")[1].split("```")[0]

    try:
        return json.loads(text.strip())
    except json.JSONDecodeError as e:
        print(f"Invalid JSON: {e}")
        import re
        match = re.search(r'\{.*\}', text, re.DOTALL)
        if match:
            return json.loads(match.group())
        raise
```
