#!/usr/bin/env python3
"""
Targeted SIMPO (Simplified Preference Optimization) search script
Searches GitHub for SIMPO-related repositories using specific query variations
"""

import urllib.request
import json
import sys
import os
from datetime import datetime

# Set output to UTF-8
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

def search_repos(query, per_page=100):
    """Search GitHub repositories"""
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
        desc = desc.replace('\n', ' ').replace('\r', '')[:200]
        print(f"NAME: {item['full_name']}")
        print(f"  URL: {item.get('html_url', 'N/A')}")
        print(f"  Stars: {item.get('stargazers_count', 0)}")
        print(f"  Forks: {item.get('forks_count', 0)}")
        print(f"  Updated: {item.get('updated_at', '')[:10]}")
        print(f"  Language: {item.get('language', 'N/A')}")
        print(f"  Description: {desc}")
        print(f"  Topics: {', '.join(item.get('topics', []))}")
        print()

# Run searches with specific query variations
print(f"Search executed at: {datetime.now().isoformat()}")
print("=" * 100)
print("TARGETED SIMPO SEARCH - Multiple Query Variations")
print("=" * 100)

# Query 1: SIMPO alone
print_results("QUERY 1: 'SIMPO' (Simplified Preference Optimization)", search_repos("SIMPO"))

# Query 2: Simplified Preference Optimization
print_results("QUERY 2: 'Simplified Preference Optimization'", search_repos("Simplified Preference Optimization"))

# Query 3: SIMPO LLM
print_results("QUERY 3: 'SIMPO LLM'", search_repos("SIMPO LLM"))

# Query 4: SIMPO alignment
print_results("QUERY 4: 'SIMPO alignment'", search_repos("SIMPO alignment"))

# Query 5: SIMPO reinforcement learning
print_results("QUERY 5: 'SIMPO reinforcement learning'", search_repos("SIMPO reinforcement learning"))

# Additional related searches to be thorough
print_results("QUERY 6: 'SimPO' (lowercase)", search_repos("SimPO"))

print_results("QUERY 7: 'Simple Preference Optimization'", search_repos("Simple Preference Optimization"))

print_results("QUERY 8: 'SIMPO NeurIPS'", search_repos("SIMPO NeurIPS"))

print_results("QUERY 9: 'SIMPO reference-free'", search_repos("SIMPO reference-free"))

print_results("QUERY 10: 'SimPO training'", search_repos("SimPO training"))

print("\n" + "=" * 100)
print("SEARCH COMPLETE")
print("=" * 100)