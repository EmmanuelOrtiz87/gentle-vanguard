import requests
import urllib.parse
import time
import re
import json

# Search queries for RLHF papers
queries = [
    'site:arxiv.org "Reinforcement Learning from Human Feedback" 2025',
    'site:arxiv.org RLHF LLM 2025 OR 2026',
    'site:arxiv.org "PPO" "Reinforcement Learning from Human Feedback" 2025',
    'site:arxiv.org RLHF alignment LLM 2025',
    'site:arxiv.org "actor-critic" RLHF 2025',
    'site:arxiv.org "Direct Preference Optimization" 2025',
    'site:arxiv.org "KTO" "Kahneman-Tversky" alignment 2025',
    'site:arxiv.org "GRPO" "Group Relative Policy Optimization" 2025'
]

def search_arxiv(query, max_results=10):
    url = f'https://www.google.com/search?q={urllib.parse.quote(query)}&num={max_results}'
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    try:
        response = requests.get(url, headers=headers, timeout=10)
        return response.text
    except Exception as e:
        return f'Error: {e}'

all_arxiv_links = set()

for q in queries:
    print(f'\n=== Searching: {q} ===\n')
    result = search_arxiv(q)
    # Extract arxiv links
    arxiv_links = re.findall(r'https://arxiv\.org/abs/[0-9]+\.[0-9v]+', result)
    for link in arxiv_links[:5]:
        print(link)
        all_arxiv_links.add(link)
    time.sleep(1)

print('\n\n=== All unique arXiv links found ===')
for link in sorted(all_arxiv_links):
    print(link)