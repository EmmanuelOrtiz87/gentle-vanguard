import urllib.request
import json
import sys
import os
from datetime import datetime

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

def search_repos(query, per_page=100):
    url = f'https://api.github.com/search/repositories?q={query.replace(" ", "+")}&sort=stars&order=desc&per_page={per_page}'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        response = urllib.request.urlopen(req, timeout=30)
        data = json.loads(response.read().decode())
        return data.get('items', [])
    except Exception as e:
        print(f"Error for query '{query}': {e}", file=sys.stderr)
        return []

def print_results(title, items):
    print(f"\n{'='*100}")
    print(f"{title}")
    print(f"{'='*100}")
    if not items:
        print("No results found")
        return
    
    for item in items[:30]:
        desc = item.get('description', 'N/A') or 'N/A'
        desc = desc.replace('\n', ' ').replace('\r', '')[:150]
        lang = item.get('language', 'N/A') or 'N/A'
        stars = item.get('stargazers_count', 0)
        updated = item.get('updated_at', '')[:10]
        html_url = item.get('html_url', '')
        print(f"NAME: {item['full_name']}")
        print(f"  URL: {html_url}")
        print(f"  STARS: {stars}")
        print(f"  UPDATED: {updated}")
        print(f"  LANGUAGE: {lang}")
        print(f"  DESC: {desc}")
        print()

search_queries = [
    "PPO reinforcement learning human feedback",
    "PPO RLHF training pipeline",
    "PPO RLHF implementation",
    "proximal policy optimization RLHF",
    "TRL PPO RLHF",
    "DeepSpeed RLHF PPO",
    "transformers PPO training",
    "LLaMA PPO RLHF",
    "RLHF PPO fine-tuning",
    "PPO human feedback"
]

for query in search_queries:
    print_results(f"SEARCH: {query}", search_repos(query))