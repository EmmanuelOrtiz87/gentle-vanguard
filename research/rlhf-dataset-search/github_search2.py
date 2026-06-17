import urllib.request
import json
import sys
import os

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

# Additional searches for comprehensive coverage
print_results("SEARCH: ORPO reference-free", search_repos("ORPO reference-free"))

print_results("SEARCH: GRPO reference-free", search_repos("GRPO reference-free"))

print_results("SEARCH: KTO preference", search_repos("KTO Kahneman Tversky preference"))

print_results("SEARCH: IPO preference optimization", search_repos("IPO preference optimization"))

print_results("SEARCH: RLHF alternative 2025", search_repos("RLHF alternative 2025"))

print_results("SEARCH: LLM alignment reference-free", search_repos("LLM alignment reference-free"))

print_results("SEARCH: DPO implementation 2025", search_repos("DPO implementation"))

print_results("SEARCH: preference learning LLM", search_repos("preference learning LLM"))

print_results("SEARCH: alignment without reference", search_repos("alignment without reference"))

print_results("SEARCH: neural chat preference", search_repos("neural chat preference optimization"))