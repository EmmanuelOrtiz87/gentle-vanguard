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

# More specific searches
print_results("SEARCH: CPO conditional preference (image generation)", search_repos("CPO condition preference optimization image"))

print_results("SEARCH: SimPO复旦大学", search_repos("SimPO 复旦大学"))

print_results("SEARCH: Princeton NLP preference", search_repos("Princeton NLP preference optimization"))

print_results("SEARCH: reward-free alignment", search_repos("reward-free alignment LLM"))

print_results("SEARCH: Kahneman Tversky optimization", search_repos("Kahneman Tversky optimization"))

print_results("SEARCH: ORPO implementation", search_repos("ORPO implementation"))

print_results("SEARCH: GRPO implementation", search_repos("GRPO group relative policy"))

print_results("SEARCH: margin-based preference optimization", search_repos("margin preference optimization"))

print_results("SEARCH: self-rewarding LLM", search_repos("self-rewarding LLM"))

print_results("SEARCH: direct alignment without reference model", search_repos("direct alignment without reference model"))