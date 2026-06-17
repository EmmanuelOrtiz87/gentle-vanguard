#!/usr/bin/env python3
"""Search HuggingFace for OpenAI-related datasets."""

from huggingface_hub import HfApi
import json

api = HfApi()

# Search for various OpenAI-related datasets
search_queries = [
    "openai",
    "openai/summarize_from_feedback",
    "openai tldr",
    "openai rlhf",
    "openai reward model",
    "openai human feedback",
    "summarize from feedback",
    "tldr summarization",
    "helpful harmless",
    "chain of thought openai",
    "gpt preference",
    "openai organization",
]

all_results = []

print("=" * 80)
print("SEARCHING HUGGINGFACE FOR OPENAI-RELATED DATASETS")
print("=" * 80)

# Search for datasets with each query
for query in search_queries:
    print(f"\n--- Searching for: '{query}' ---")
    try:
        results = api.list_datasets(search=query, limit=20)
        count = 0
        for dataset in results:
            print(f"  - {dataset.id}")
            print(f"    URL: https://huggingface.co/datasets/{dataset.id}")
            all_results.append({
                'name': dataset.id,
                'url': f"https://huggingface.co/datasets/{dataset.id}",
                'query': query
            })
            count += 1
        if count == 0:
            print("  (no results)")
        print(f"  Total found for '{query}': {count}")
    except Exception as e:
        print(f"  Error: {e}")

print("\n" + "=" * 80)
print(f"TOTAL DATASETS FOUND: {len(all_results)}")
print("=" * 80)

# Save results to JSON
with open('hf_openai_datasets.json', 'w') as f:
    json.dump(all_results, f, indent=2)

print("\nResults saved to hf_openai_datasets.json")