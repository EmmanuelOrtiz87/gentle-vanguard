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
        print(f"Error for query '{query}': {e}", file=sys.stderr)
        return []

def print_results(title, items):
    print(f"\n{'='*100}")
    print(f"{title}")
    print(f"{'='*100}")
    if not items:
        print("No results found")
        return
    
    for item in items[:20]:
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

# Additional searches for well-known RLHF/PPO repos
search_queries = [
    "huggingface TRL",
    "DeepSpeed-Chat",
    "trlx RLHF",
    "CARP",
    "instructGPT",
    "Anthropic HH-RLHF",
    "RLHF reward model",
    "alignment handbooks"
]

for query in search_queries:
    print_results(f"SEARCH: {query}", search_repos(query))