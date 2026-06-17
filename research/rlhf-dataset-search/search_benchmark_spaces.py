#!/usr/bin/env python3
"""Search HuggingFace Spaces for benchmarks and evaluation."""

from huggingface_hub import HfApi
import json

api = HfApi()

# Search queries for benchmarks and evaluation
search_queries = [
    "benchmark",
    "evaluation", 
    "leaderboard",
    "mmlu",
    "humaneval",
    "llm evaluation",
    "model benchmark",
    "eval harness",
    "lm evaluation",
    "reward model evaluation",
    "instruction following",
    "code generation benchmark",
    "math benchmark",
    "multimodal benchmark",
    "vision benchmark",
    "audio benchmark",
    "text generation evaluation",
    "chatbot arena",
    "model grading",
    "model testing"
]

print("=" * 80)
print("SEARCHING HUGGINGFACE SPACES FOR BENCHMARKS AND EVALUATION")
print("=" * 80)

all_results = []

for query in search_queries:
    print(f"\n--- Searching for: '{query}' ---")
    try:
        results = api.list_spaces(search=query, limit=30)
        count = 0
        for space in results:
            # Get Space info
            space_info = {
                'name': space.id,
                'url': f"https://huggingface.co/spaces/{space.id}",
                'query': query,
                'likes': getattr(space, 'likes', None),
                'author': space.id.split('/')[0] if '/' in space.id else None
            }
            print(f"  - {space.id}")
            print(f"    URL: {space_info['url']}")
            all_results.append(space_info)
            count += 1
        
        if count == 0:
            print("  (no results)")
        print(f"  Total found for '{query}': {count}")
    except Exception as e:
        print(f"  Error: {e}")

print("\n" + "=" * 80)
print(f"TOTAL SPACES FOUND: {len(all_results)}")
print("=" * 80)

# Remove duplicates based on name
unique_spaces = {}
for space in all_results:
    name = space['name']
    if name not in unique_spaces:
        unique_spaces[name] = space

print(f"\nUnique Spaces: {len(unique_spaces)}")

# Save results to JSON
with open('hf_benchmark_spaces.json', 'w') as f:
    json.dump(list(unique_spaces.values()), f, indent=2)

print("\nResults saved to hf_benchmark_spaces.json")

# Also print grouped by author/organization
authors = {}
for space in unique_spaces.values():
    author = space['author'] or 'unknown'
    if author not in authors:
        authors[author] = []
    authors[author].append(space['name'])

print("\n" + "=" * 80)
print("SPACES BY AUTHOR/ORGANIZATION")
print("=" * 80)
for author in sorted(authors.keys()):
    print(f"\n{author}:")
    for name in sorted(authors[author]):
        print(f"  - {name}")