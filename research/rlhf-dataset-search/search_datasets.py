#!/usr/bin/env python3
"""
Consolidated Multi-Source Dataset Search Script
================================================
Replaces ~20 individual Python scripts for searching HuggingFace datasets,
arXiv papers, GitHub repositories, and HuggingFace Spaces.

Usage:
    python search_datasets.py --source huggingface --query "rlhf"
    python search_datasets.py --source arxiv --query "preference optimization" --max-results 50
    python search_datasets.py --source github --query "RLHF" --language python
    python search_datasets.py --source spaces --query "benchmark"
    python search_datasets.py --source all --query "reward model" --max-results 10
    python search_datasets.py --source huggingface --action details --dataset "Anthropic/hh-rlhf"
    python search_datasets.py --source huggingface --action readme --dataset "OpenAssistant/oasst1"
    python search_datasets.py --source github --action details --owner "princeton-nlp" --repo "SimPO"

Requirements:
    pip install huggingface_hub requests
"""

import argparse
import json
import os
import sys
import time
import xml.etree.ElementTree as ET
import urllib.parse
import urllib.request
import csv
from collections import defaultdict
from datetime import datetime

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

HF_API_URL = "https://huggingface.co/api/datasets"
ARXIV_API_URL = "http://export.arxiv.org/api/query"
GITHUB_API_URL = "https://api.github.com"


# ── GitHub ──────────────────────────────────────────────────────────────────

def search_github_repos(query, max_results=50, language=None):
    parts = [query.replace(" ", "+")]
    if language:
        parts.append(f"language:{language}")
    q = "+".join(parts)
    url = f"{GITHUB_API_URL}/search/repositories?q={q}&sort=stars&order=desc&per_page={min(max_results, 100)}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        response = urllib.request.urlopen(req, timeout=30)
        data = json.loads(response.read().decode())
        return data.get('items', [])[:max_results]
    except Exception as e:
        print(f"GitHub search error: {e}", file=sys.stderr)
        return []


def print_github_results(title, items):
    print(f"\n{'='*80}")
    print(f"{title}")
    print(f"{'='*80}")
    if not items:
        print("No results found")
        return
    for item in items:
        desc = (item.get('description') or 'N/A').replace('\n', ' ').replace('\r', '')[:200]
        lang = item.get('language') or 'N/A'
        print(f"{item['full_name']}|{item.get('stargazers_count', 0)}|{item.get('updated_at', '')[:10]}|{lang}|{desc}")


def get_github_repo_details(owner, repo):
    url = f"{GITHUB_API_URL}/repos/{owner}/{repo}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        response = urllib.request.urlopen(req, timeout=30)
        return json.loads(response.read().decode())
    except Exception as e:
        print(f"Error fetching {owner}/{repo}: {e}", file=sys.stderr)
        return {}


def get_github_contributors(owner, repo, limit=10):
    url = f"{GITHUB_API_URL}/repos/{owner}/{repo}/contributors?per_page={limit}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        response = urllib.request.urlopen(req, timeout=30)
        data = json.loads(response.read().decode())
        return [c['login'] for c in data[:limit]]
    except:
        return []


def print_github_details(owner, repo, details):
    print(f"{'='*80}")
    print(f"REPO: {owner}/{repo}")
    print(f"{'='*80}")
    if not details or not details.get('full_name'):
        print("No details available")
        return
    print(f"Name: {details.get('full_name', 'N/A')}")
    print(f"Stars: {details.get('stargazers_count', 'N/A')}")
    print(f"Forks: {details.get('forks_count', 'N/A')}")
    print(f"Updated: {details.get('updated_at', 'N/A')}")
    print(f"Language: {details.get('language', 'N/A')}")
    license_info = details.get('license')
    print(f"License: {license_info.get('name', 'N/A') if license_info else 'N/A'}")
    print(f"Description: {details.get('description', 'N/A')}")
    print(f"Topics: {', '.join(details.get('topics', []))}")
    print(f"URL: {details.get('html_url', 'N/A')}")
    print(f"Default branch: {details.get('default_branch', 'N/A')}")
    contributors = get_github_contributors(owner, repo)
    print(f"Top contributors: {', '.join(contributors) if contributors else 'N/A'}")


# ── arXiv ────────────────────────────────────────────────────────────────────

def search_arxiv(query, max_results=50, start=0):
    params = {
        'search_query': query,
        'start': start,
        'max_results': max_results,
        'sortBy': 'submittedDate',
        'sortOrder': 'descending'
    }
    url = f"{ARXIV_API_URL}?{urllib.parse.urlencode(params)}"
    try:
        import requests
        response = requests.get(url, timeout=30)
        return response.text
    except ImportError:
        req = urllib.request.Request(url)
        try:
            response = urllib.request.urlopen(req, timeout=30)
            return response.read().decode()
        except Exception as e:
            print(f"arXiv request error: {e}", file=sys.stderr)
            return None
    except Exception as e:
        print(f"arXiv request error: {e}", file=sys.stderr)
        return None


def parse_arxiv_response(xml_text):
    if not xml_text:
        return {}
    papers = {}
    try:
        root = ET.fromstring(xml_text)
        ns = {'atom': 'http://www.w3.org/2005/Atom', 'arxiv': 'http://arxiv.org/schemas/atom'}
        for entry in root.findall('.//atom:entry', ns):
            id_elem = entry.find('atom:id', ns)
            if id_elem is None:
                continue
            arxiv_id = id_elem.text.split('/')[-1]
            title_elem = entry.find('atom:title', ns)
            summary_elem = entry.find('atom:summary', ns)
            author_elem = entry.findall('atom:author/atom:name', ns)
            published_elem = entry.find('atom:published', ns)
            updated_elem = entry.find('atom:updated', ns)
            link_elem = entry.find('atom:link[@title="pdf"]', ns)
            papers[arxiv_id] = {
                'id': arxiv_id,
                'url': id_elem.text,
                'pdf_url': link_elem.get('href') if link_elem is not None else '',
                'title': title_elem.text.strip().replace('\n', ' ') if title_elem is not None else '',
                'summary': summary_elem.text.strip() if summary_elem is not None else '',
                'authors': [a.text for a in author_elem] if author_elem else [],
                'published': published_elem.text[:10] if published_elem is not None else '',
                'updated': updated_elem.text[:10] if updated_elem is not None else ''
            }
    except Exception as e:
        print(f"arXiv parse error: {e}", file=sys.stderr)
    return papers


def print_arxiv_results(papers):
    print(f"\n{'='*80}")
    print(f"ARXIV PAPERS FOUND: {len(papers)}")
    print(f"{'='*80}")
    for arxiv_id in sorted(papers.keys(), reverse=True):
        p = papers[arxiv_id]
        print(f"\narXiv: {p['id']}")
        print(f"  Title: {p['title']}")
        authors_str = ', '.join(p['authors'][:5])
        if len(p['authors']) > 5:
            authors_str += f' + {len(p["authors"]) - 5} more'
        print(f"  Authors: {authors_str}")
        print(f"  Date: {p['published']}")
        print(f"  URL: {p['url']}")
        print(f"  PDF: {p['pdf_url']}")
        summary = p['summary'][:500] + '...' if len(p['summary']) > 500 else p['summary']
        print(f"  Summary: {summary}")


# ── HuggingFace Datasets ────────────────────────────────────────────────────

def search_hf_datasets(query, max_results=100):
    try:
        from huggingface_hub import HfApi, list_datasets
        datasets = list(list_datasets(search=query, limit=max_results))
        results = []
        for ds in datasets:
            results.append({
                "id": ds.id,
                "name": ds.id.split("/")[-1] if "/" in ds.id else ds.id,
                "owner": ds.id.split("/")[0] if "/" in ds.id else None,
            })
        return results
    except Exception as e:
        print(f"HF API list_datasets error: {e}", file=sys.stderr)
        return []


def print_hf_search_results(results, query):
    print(f"\n{'='*60}")
    print(f"HUGGINGFACE DATASETS for '{query}': {len(results)}")
    print(f"{'='*60}")
    for i, ds in enumerate(results):
        print(f"  [{i+1}] {ds['id']}")


def get_hf_dataset_details(dataset_id):
    try:
        from huggingface_hub import HfApi
        api = HfApi()
        info = api.dataset_info(repo_id=dataset_id)
        result = {
            "id": info.id,
            "url": f"https://huggingface.co/datasets/{dataset_id}",
            "sha": info.sha,
            "last_modified": str(info.last_modified) if info.last_modified else None,
            "private": info.private,
            "downloads": getattr(info, 'downloads', None),
            "likes": getattr(info, 'likes', None),
            "tags": getattr(info, 'tags', []),
            "gated": getattr(info, 'gated', None),
        }
        try:
            files = api.list_repo_files(repo_id=dataset_id, repo_type="dataset")
            result["files"] = files[:50]
            result["total_files"] = len(files)
        except:
            result["files"] = []
        return result
    except Exception as e:
        return {"id": dataset_id, "error": str(e)}


def print_hf_details(dataset_id, details):
    print(f"{'='*70}")
    print(f"DATASET: {dataset_id}")
    print(f"{'='*70}")
    if "error" in details:
        print(f"  ERROR: {details['error']}")
        return
    print(f"  URL: {details.get('url', 'N/A')}")
    print(f"  Last Modified: {details.get('last_modified', 'N/A')}")
    print(f"  Downloads: {details.get('downloads', 'N/A')}")
    print(f"  Likes: {details.get('likes', 'N/A')}")
    print(f"  Gated: {details.get('gated', 'N/A')}")
    print(f"  Tags: {', '.join(details.get('tags', [])[:10])}")
    print(f"  Total Files: {details.get('total_files', 'N/A')}")


def get_hf_readme(dataset_id):
    try:
        from huggingface_hub import HfApi, hf_hub_download
        api = HfApi()
        files = api.list_repo_files(repo_id=dataset_id, repo_type="dataset")
        readme_file = None
        for f in files:
            if f.lower() == "readme.md":
                readme_file = f
                break
        if readme_file:
            path = hf_hub_download(repo_id=dataset_id, filename="README.md", repo_type="dataset")
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            return {
                "has_readme": True,
                "readme_preview": content[:3000],
                "full_length": len(content),
                "full_content": content
            }
        else:
            return {"has_readme": False, "files": files[:10]}
    except Exception as e:
        return {"error": str(e)}


def print_hf_readme(dataset_id, result):
    print(f"{'='*70}")
    print(f"README FOR: {dataset_id}")
    print(f"{'='*70}")
    if "error" in result:
        print(f"  ERROR: {result['error']}")
    elif result.get("has_readme"):
        print(f"  README Length: {result.get('full_length', 'N/A')} chars")
        preview = result.get("readme_preview", "")[:500]
        print(f"  Preview: {preview}...")
    else:
        print(f"  No README found")


def fetch_hf_via_rest(dataset_id):
    url = f"{HF_API_URL}/{dataset_id}"
    try:
        import requests
        response = requests.get(url, timeout=30)
        if response.status_code == 200:
            return response.json()
        return None
    except ImportError:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        try:
            response = urllib.request.urlopen(req, timeout=30)
            return json.loads(response.read().decode())
        except:
            return None
    except:
        return None


# ── HuggingFace Spaces ──────────────────────────────────────────────────────

def search_hf_spaces(query, max_results=30):
    try:
        from huggingface_hub import HfApi
        api = HfApi()
        results = api.list_spaces(search=query, limit=max_results)
        spaces = []
        for space in results:
            spaces.append({
                'name': space.id,
                'url': f"https://huggingface.co/spaces/{space.id}",
                'query': query,
                'likes': getattr(space, 'likes', None),
                'author': space.id.split('/')[0] if '/' in space.id else None
            })
        return spaces
    except Exception as e:
        print(f"HF Spaces search error: {e}", file=sys.stderr)
        return []


def print_hf_spaces_results(spaces, query):
    print(f"\n{'='*80}")
    print(f"HUGGINGFACE SPACES for '{query}': {len(spaces)}")
    print(f"{'='*80}")
    for s in spaces:
        print(f"  - {s['name']}")
        print(f"    URL: {s['url']}")


# ── Popular / Batch Dataset Fetcher ─────────────────────────────────────────

def format_size(num_bytes):
    if not num_bytes:
        return 'N/A'
    if num_bytes < 1024:
        return f"{num_bytes} B"
    elif num_bytes < 1024**2:
        return f"{num_bytes/1024:.1f} KB"
    elif num_bytes < 1024**3:
        return f"{num_bytes/(1024**2):.1f} MB"
    else:
        return f"{num_bytes/(1024**3):.1f} GB"


def print_hf_dataset_summary(info):
    ds_id = info.get('id', 'N/A')
    print(f"\n--- {ds_id} ---")
    print(f"  Owner/Author: {info.get('author', 'N/A')}")
    print(f"  URL: https://huggingface.co/datasets/{ds_id}")
    print(f"  Last Updated: {info.get('lastModified', 'N/A')}")
    downloads = info.get('downloads', 'N/A')
    if isinstance(downloads, int):
        print(f"  Downloads: {downloads:,}")
    else:
        print(f"  Downloads: {downloads}")
    print(f"  Likes: {info.get('likes', 0)}")
    print(f"  Gated: {info.get('gated', False)}")
    if 'description' in info:
        desc = info.get('description', '')[:200]
        if desc:
            print(f"  Description: {desc}...")


# ── RLHF/Alignment Batch Search ───────────────────────────────────────────────

HF_SEARCH_TERMS = [
    "SFT preference", "instruction tuning", "alignment dataset", "DPO dataset",
    "RLHF dataset", "preference data", "SFT dataset", "supervised fine-tuning",
    "direct preference optimization", "preference model", "hh-rlhf",
    "anthropic hh", "stack-llama", "orca", "flan", "alpaca", "gpt4all",
    "open assistant", "lmsys chatbot arena", "vicuna", "beluga", "ultrachat",
    "camel ai",
]


def search_hf_datasets_rest(query, limit=100):
    """Search HuggingFace datasets via REST API (no huggingface_hub dependency)"""
    params = {"search": query, "full": "true", "limit": limit, "direction": -1}
    try:
        import requests
        response = requests.get(HF_API_URL, params=params, timeout=30)
        if response.status_code == 200:
            return response.json()
        return []
    except Exception as e:
        print(f"REST search error for '{query}': {e}", file=sys.stderr)
        return []


def search_hf_datasets_batch(terms=None, limit=50):
    """Search using multiple predefined terms, deduplicate results"""
    if terms is None:
        terms = HF_SEARCH_TERMS
    all_results = {}
    for i, term in enumerate(terms, 1):
        print(f"  [{i}/{len(terms)}] Searching: '{term}'")
        results = search_hf_datasets_rest(term, limit=limit)
        for ds in results:
            ds_id = ds.get('id', '')
            if ds_id and ds_id not in all_results:
                all_results[ds_id] = ds
        print(f"      Found {len(results)} results, {len(all_results)} unique so far")
        time.sleep(0.5)
    return all_results


def filter_relevant_hf_datasets(datasets):
    """Filter to keep only SFT/preference/alignment-relevant datasets"""
    filtered = {}
    for ds_id, ds in datasets.items():
        tags_str = ' '.join(ds.get('tags', []))
        search_text = (ds_id + ' ' + tags_str + ' ' + str(ds.get('cardData', {}))).lower()
        has_preference = any(kw in search_text for kw in ['preference', 'rating', 'choice', 'chosen', 'rejected'])
        has_sft = any(kw in search_text for kw in ['sft', 'instruction', 'tuning', 'fine-tune', 'finetune', 'alignment'])
        has_chat = any(kw in search_text for kw in ['chat', 'conversation', 'dialogue', 'qa', 'question answer'])
        if has_preference or (has_sft and has_chat):
            filtered[ds_id] = ds
    return filtered


def categorize_hf_dataset(ds_id, ds):
    """Categorize a dataset based on keywords in its metadata"""
    categories = []
    text = (ds_id + ' ' + str(ds.get('tags', [])) + ' ' + str(ds.get('cardData', {}))).lower()
    if any(k in text for k in ['dpo', 'direct preference']):
        categories.append('DPO')
    if any(k in text for k in ['rlhf', 'reinforcement']):
        categories.append('RLHF')
    if any(k in text for k in ['sft', 'supervised', 'fine-tune', 'finetune']):
        categories.append('SFT')
    if any(k in text for k in ['preference', 'choice', 'rating', 'chosen', 'rejected']):
        categories.append('Preference Data')
    if any(k in text for k in ['instruction', 'tuning']):
        categories.append('Instruction Tuning')
    if any(k in text for k in ['alignment']):
        categories.append('Alignment')
    if any(k in text for k in ['chat', 'conversation', 'dialogue']):
        categories.append('Chat/Conversation')
    return categories if categories else ['Other']


def extract_hf_use_cases(ds_id, ds):
    """Extract potential use cases from dataset metadata"""
    use_cases = []
    text = (ds_id + ' ' + str(ds.get('tags', [])) + ' ' + str(ds.get('cardData', {}))).lower()
    if any(k in text for k in ['alignment', 'rlhf', 'preference']):
        use_cases.append('LLM Alignment')
    if any(k in text for k in ['instruction', 'tuning']):
        use_cases.append('Instruction Following')
    if any(k in text for k in ['chat', 'conversation']):
        use_cases.append('Chatbot Training')
    if any(k in text for k in ['reasoning', 'math', 'code']):
        use_cases.append('Reasoning/Code')
    if any(k in text for k in ['preference', 'dpo']):
        use_cases.append('Preference Optimization')
    return use_cases if use_cases else ['General NLP']


def print_hf_categorized_results(datasets, title):
    """Print datasets grouped by category"""
    by_category = defaultdict(list)
    for ds_id, ds in datasets.items():
        cats = categorize_hf_dataset(ds_id, ds)
        for cat in cats:
            by_category[cat].append((ds_id, ds))

    print(f"\n{'='*80}")
    print(title)
    print(f"{'='*80}")
    for category, items in sorted(by_category.items()):
        print(f"\n{'='*40}")
        print(f"CATEGORY: {category} ({len(items)} datasets)")
        print(f"{'='*40}")
        for ds_id, ds in sorted(items, key=lambda x: x[0]):
            print(f"\n--- {ds_id} ---")
            owner, name = ds_id.split('/') if '/' in ds_id else ('', ds_id)
            print(f"  URL: https://huggingface.co/datasets/{ds_id}")
            print(f"  Owner: {owner}")
            print(f"  Name: {name}")
            desc = ds.get('cardData', {}).get('annotations', {}).get('description', [])
            if desc:
                print(f"  Description: {desc[0]}")
            tags = ds.get('tags', [])
            if tags:
                print(f"  Tags: {', '.join(tags[:10])}")
            use_cases = ' '.join(extract_hf_use_cases(ds_id, ds))
            if use_cases:
                print(f"  Use Cases: {use_cases}")
            if 'lastModified' in ds:
                print(f"  Last Updated: {ds['lastModified']}")
            if 'downloads' in ds:
                print(f"  Downloads: {ds['downloads']:,}")
            if ds.get('gated'):
                print(f"  Gated: Yes")


def save_hf_csv(datasets, filename="hf_datasets.csv"):
    """Save dataset results to CSV"""
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['URL', 'Owner', 'Name', 'Description', 'Categories',
                         'Use Cases', 'Tags', 'Last Updated', 'Downloads', 'Gated'])
        for ds_id, ds in sorted(datasets.items()):
            owner, name = ds_id.split('/') if '/' in ds_id else ('', ds_id)
            desc = ds.get('cardData', {}).get('annotations', {}).get('description', [])
            desc = desc[0] if desc else ''
            cats = ', '.join(categorize_hf_dataset(ds_id, ds))
            uses = ', '.join(extract_hf_use_cases(ds_id, ds))
            tags = ', '.join(ds.get('tags', [])[:10])
            last_mod = ds.get('lastModified', '')
            downloads = ds.get('downloads', '')
            gated = 'Yes' if ds.get('gated') else 'No'
            writer.writerow([f"https://huggingface.co/datasets/{ds_id}",
                             owner, name, desc, cats, uses, tags, last_mod, downloads, gated])
    print(f"Saved CSV to {filename}")


# ── Main CLI ─────────────────────────────────────────────────────────────────

def build_parser():
    p = argparse.ArgumentParser(
        description="Multi-source search for datasets, papers, repos, and spaces",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    p.add_argument('--source', '-s', default='all',
                   choices=['huggingface', 'arxiv', 'github', 'spaces', 'all'],
                   help='Source to search (default: all)')
    p.add_argument('--query', '-q', help='Search query')
    p.add_argument('--max-results', '-n', type=int, default=20, help='Max results per source (default: 20)')
    p.add_argument('--output', '-o', help='Save results to JSON file')
    p.add_argument('--language', '-l', help='Filter GitHub repos by language')
    p.add_argument('--action', '-a', default='search',
                   choices=['search', 'details', 'readme', 'batch'],
                   help='Action: search, details, readme, or batch (default: search)')
    p.add_argument('--dataset', '-d', help='Dataset ID for details/readme actions (e.g. Anthropic/hh-rlhf)')
    p.add_argument('--owner', help='GitHub owner for repo details')
    p.add_argument('--repo', '-r', help='GitHub repo name for details')
    p.add_argument('--categorize', '-c', action='store_true',
                   help='Categorize and filter huggingface results (RLHF/alignment domain)')
    p.add_argument('--csv', action='store_true',
                   help='Output batch results as CSV (instead of categorized text)')
    return p


def main():
    parser = build_parser()
    args = parser.parse_args()

    if args.action == 'search' and not args.query:
        parser.error("--query is required for search action")

    # ── Batch action ───────────────────────────────────────────────────────────
    if args.action == 'batch':
        if args.source not in ('huggingface', 'all'):
            parser.error("--action batch only works with --source huggingface")
        print("HuggingFace Batch Search for SFT/Preference/Alignment Datasets")
        print("=" * 60)
        datasets = search_hf_datasets_batch(limit=args.max_results)
        print(f"\nTotal unique datasets found: {len(datasets)}")
        if datasets:
            if args.categorize:
                datasets = filter_relevant_hf_datasets(datasets)
                print(f"Relevant datasets after filtering: {len(datasets)}")
            if args.csv or (args.output and args.output.lower().endswith('.csv')):
                csv_file = args.output if args.output else "hf_batch_datasets.csv"
                save_hf_csv(datasets, csv_file)
            else:
                title = f"HF BATCH RESULTS: {len(datasets)} datasets"
                print_hf_categorized_results(datasets, title)
            if args.output and not args.output.lower().endswith('.csv'):
                serializable = {}
                for ds_id, ds in datasets.items():
                    serializable[ds_id] = {k: v for k, v in ds.items()
                                           if isinstance(v, (str, int, float, bool, list, dict)) or v is None}
                with open(args.output, 'w', encoding='utf-8') as f:
                    json.dump(serializable, f, indent=2, ensure_ascii=False)
                print(f"Saved JSON to {args.output}")
        return

    sources = ['huggingface', 'arxiv', 'github', 'spaces'] if args.source == 'all' else [args.source]
    results = {}
    timestamp = datetime.now().isoformat()

    if args.action == 'details':
        if args.source == 'huggingface' and args.dataset:
            details = get_hf_dataset_details(args.dataset)
            print_hf_details(args.dataset, details)
            results['details'] = details
        elif args.source == 'github' and args.owner and args.repo:
            details = get_github_repo_details(args.owner, args.repo)
            print_github_details(args.owner, args.repo, details)
            results['details'] = details
        else:
            parser.error("--dataset required for huggingface details; --owner and --repo for github details")
    elif args.action == 'readme':
        if args.source != 'huggingface':
            parser.error("--action readme only works with --source huggingface")
        if not args.dataset:
            parser.error("--dataset is required for readme action")
        readme = get_hf_readme(args.dataset)
        print_hf_readme(args.dataset, readme)
        results['readme'] = readme
    else:
        for source in sources:
            if source == 'github':
                items = search_github_repos(args.query, args.max_results, args.language)
                print_github_results(f"GITHUB: {args.query}", items)
                results['github'] = items
            elif source == 'arxiv':
                xml_text = search_arxiv(args.query, args.max_results)
                papers = parse_arxiv_response(xml_text)
                print_arxiv_results(papers)
                results['arxiv'] = papers
                time.sleep(3)
            elif source == 'huggingface':
                datasets = search_hf_datasets(args.query, args.max_results)
                print_hf_search_results(datasets, args.query)
                results['huggingface'] = datasets
            elif source == 'spaces':
                spaces = search_hf_spaces(args.query, args.max_results)
                print_hf_spaces_results(spaces, args.query)
                results['spaces'] = spaces

    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump({
                'metadata': {
                    'timestamp': timestamp,
                    'source': args.source,
                    'query': args.query,
                    'action': args.action,
                },
                'results': results
            }, f, indent=2, ensure_ascii=False)
        print(f"\nResults saved to: {args.output}")


if __name__ == "__main__":
    main()
