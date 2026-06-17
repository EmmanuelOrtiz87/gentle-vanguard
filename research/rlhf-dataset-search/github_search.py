import urllib.request
import json
import sys
import os

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
    print(f"\n{'='*80}")
    print(f"{title}")
    print(f"{'='*80}")
    if not items:
        print("No results found")
        return
    
    for item in items[:50]:
        desc = item.get('description', 'N/A') or 'N/A'
        desc = desc.replace('\n', ' ').replace('\r', '')[:200]
        print(f"{item['full_name']}|{item.get('stargazers_count', 0)}|{item.get('updated_at', '')[:10]}|{desc}")

# Search 1: CPO
print_results("SEARCH: CPO", search_repos("CPO"))

# Search 2: SimPO
print_results("SEARCH: SimPO", search_repos("SimPO"))

# Search 3: reference-free preference
print_results("SEARCH: reference-free preference optimization", search_repos("\"reference-free\" preference"))

# Search 4: reference-free alignment
print_results("SEARCH: reference-free alignment", search_repos("\"reference-free\" alignment"))

# Search 5: preference optimization 2025
print_results("SEARCH: preference optimization 2025", search_repos("preference optimization 2025"))

# Search 6: alignment lora reference
print_results("SEARCH: alignment lora reference", search_repos("alignment lora reference"))

# Search 7: DPO reference-free
print_results("SEARCH: DPO reference-free", search_repos("DPO reference-free"))

# Search 8: ICLR 2025 preference
print_results("SEARCH: ICLR 2025 preference", search_repos("ICLR 2025 preference"))

# Search 9: NeurIPS 2025 preference
print_results("SEARCH: NeurIPS 2025 preference", search_repos("NeurIPS 2025 preference"))

# Search 10: arxiv 2025 preference optimization
print_results("SEARCH: arxiv 2025 preference optimization", search_repos("arxiv 2025 preference optimization"))