#!/usr/bin/env python3
"""Search HuggingFace for more OpenAI-related datasets - expanded search."""

from huggingface_hub import HfApi

api = HfApi()

# Additional search queries
additional_queries = [
    "rlhf",
    "preference learning",
    "reward modeling",
    "anthropic hh-rlhf",
    "human feedback",
    "chain of thought",
    "cot reasoning",
    "gpt RLHF",
    "dpo dataset",
    "direct preference optimization",
    "constitutional ai",
    "hh-rlhf",
    "instruction tuning",
    "preference model",
]

print("=" * 80)
print("ADDITIONAL SEARCHES FOR RLHF AND RELATED DATASETS")
print("=" * 80)

all_results = []

for query in additional_queries:
    print(f"\n--- Searching for: '{query}' ---")
    try:
        results = api.list_datasets(search=query, limit=15)
        count = 0
        for dataset in results:
            # Filter for relevant datasets (not too generic)
            name_lower = dataset.id.lower()
            relevant = any(kw in name_lower for kw in [
                'rlhf', 'preference', 'reward', 'feedback', 'dpo', 'hh', 
                'anthropic', 'helpful', 'harmless', 'openai', 'gpt', 'chain', 'cot'
            ])
            
            if relevant:
                print(f"  - {dataset.id}")
                print(f"    URL: https://huggingface.co/datasets/{dataset.id}")
                all_results.append({
                    'name': dataset.id,
                    'url': f"https://huggingface.co/datasets/{dataset.id}",
                    'query': query
                })
                count += 1
        
        if count == 0:
            print("  (no relevant results)")
        print(f"  Relevant datasets found for '{query}': {count}")
    except Exception as e:
        print(f"  Error: {e}")

print("\n" + "=" * 80)
print(f"TOTAL ADDITIONAL DATASETS FOUND: {len(all_results)}")
print("=" * 80)

# Print unique results
unique_names = set(r['name'] for r in all_results)
print(f"\nUnique datasets: {len(unique_names)}")
for name in sorted(unique_names):
    print(f"  - {name}")