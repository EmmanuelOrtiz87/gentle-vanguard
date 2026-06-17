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
    for item in items[:30]:
        desc = item.get('description', 'N/A') or 'N/A'
        desc = desc.replace('\n', ' ').replace('\r', '')[:200]
        print(f"{item['full_name']}|{item.get('stargazers_count', 0)}|{item.get('updated_at', '')[:10]}|{desc}")

# Final searches
print_results("SEARCH: MaPO", search_repos("MaPO margin-aware preference"))

print_results("SEARCH: SimPO implementation pytorch", search_repos("SimPO pytorch"))

print_results("SEARCH: DAPO", search_repos("DAPO dynamic sampling"))

print_results("SEARCH: RLHF alternative", search_repos("RLHF alternative direct"))

print_results("SEARCH: alignment training code", search_repos("alignment training code LLM"))