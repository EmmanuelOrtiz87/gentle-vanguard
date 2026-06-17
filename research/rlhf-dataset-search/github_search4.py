import urllib.request
import json
import sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

def search_repos(query, per_page=100):
    url = f'https://api.github.com/search/repositories?q={query.replace(" ", "+")}&sort=stars&order=desc&per_page={per_page}'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        response = urllib.request.urlopen(req, timeout=30)
        data = json.loads(response.read().decode())
        return data.get('items', [])
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
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

# Additional searches
print_results("SEARCH: Chain of Preference Optimization", search_repos("Chain of Preference Optimization"))

print_results("SEARCH: CPO NeurIPS", search_repos("CPO NeurIPS"))

print_results("SEARCH: InPO preference", search_repos("InPO preference"))

print_results("SEARCH: diffusion NPO", search_repos("diffusion NPO negative preference"))

print_results("SEARCH: RRPO", search_repos("RRPO regularized preference"))

print_results("SEARCH: TIS-DPO", search_repos("TIS-DPO token importance"))

print_results("SEARCH: alpha DPO", search_repos("alpha DPO margin"))

print_results("SEARCH: LongVPO", search_repos("LongVPO long video"))

print_results("SEARCH: BPO preference", search_repos("BPO distribution ratio"))

print_results("SEARCH: weak-to-strong preference", search_repos("weak-to-strong preference"))