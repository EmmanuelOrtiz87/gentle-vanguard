import urllib.request
import json
import sys
import time

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

def get_repo_details(owner, repo):
    url = f'https://api.github.com/repos/{owner}/{repo}'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        response = urllib.request.urlopen(req, timeout=30)
        data = json.loads(response.read().decode())
        return data
    except Exception as e:
        print(f"Error fetching {owner}/{repo}: {e}", file=sys.stderr)
        return {}

def get_contributors(owner, repo):
    url = f'https://api.github.com/repos/{owner}/{repo}/contributors?per_page=10'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        response = urllib.request.urlopen(req, timeout=30)
        data = json.loads(response.read().decode())
        return [c['login'] for c in data[:10]]
    except:
        return []

# List of key repos to analyze
repos = [
    ("princeton-nlp", "SimPO"),
    ("fe1ixxu", "CPO_SIMPO"),
    ("sail-sg", "CPO"),
    ("ZonglinL", "CPO"),
    ("XiaoyuYoung", "CPO"),
    ("eric-mitchell", "direct-preference-optimization"),
    ("ContextualAI", "HALOs"),
    ("JIA-Lab-research", "Step-DPO"),
    ("zht8506", "Easy-LLM-Post-Training"),
    ("joey00072", "nanoGRPO"),
    ("holarissun", "RewardModelingBeyondBradleyTerry"),
    ("LVUGAI", "CHiP"),
    ("DAMO-NLP-SG", "LongPO"),
    ("G-U-N", "Diffusion-NPO"),
    ("princeton-nlp", "unintentional-unalignment"),
    ("junkangwu", "alpha-DPO"),
    ("JaydenLyh", "InPO"),
    ("Xiaofeng-Tan", "SoPo"),
    ("mapo-t2i", "mapo"),
    ("KbsdJames", "Awesome-LLM-Preference-Learning"),
    ("sail-sg", "oat"),
    ("BrendanJamesLynskey", "FT_04_DPO_and_Cousins"),
    ("MCG-NJU", "LongVPO"),
    ("pritamqu", "RRPO"),
    ("exlaw", "TIS-DPO"),
    ("aailab-kaist", "BPO"),
    ("zwhong714", "weak-to-strong-preference-optimization"),
    ("cswry", "DP2O-SR"),
    ("hzx122", "SamS"),
    ("Mael-zys", "PhysMoDPO"),
    ("WeiXiongUST", "Building-Math-Agents-with-Multi-Turn-Iterative-Preference-Learning"),
]

# Get details for key repos
for owner, repo in repos:
    print(f"\n{'='*80}")
    print(f"REPO: {owner}/{repo}")
    print(f"{'='*80}")
    details = get_repo_details(owner, repo)
    if details and details.get('full_name'):
        print(f"Name: {details.get('full_name', 'N/A')}")
        print(f"Stars: {details.get('stargazers_count', 'N/A')}")
        print(f"Forks: {details.get('forks_count', 'N/A')}")
        print(f"Updated: {details.get('updated_at', 'N/A')}")
        print(f"Language: {details.get('language', 'N/A')}")
        license_info = details.get('license')
        if license_info:
            print(f"License: {license_info.get('name', 'N/A')}")
        else:
            print(f"License: N/A")
        print(f"Description: {details.get('description', 'N/A')}")
        print(f"Topics: {', '.join(details.get('topics', []))}")
        print(f"URL: {details.get('html_url', 'N/A')}")
        print(f"Default branch: {details.get('default_branch', 'N/A')}")
        contributors = get_contributors(owner, repo)
        print(f"Top contributors: {', '.join(contributors) if contributors else 'N/A'}")
    time.sleep(0.5)