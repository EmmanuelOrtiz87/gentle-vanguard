#!/usr/bin/env python3
"""
HuggingFace Dataset Search Script for SFT/Preference/Alignment Datasets
This script searches HuggingFace Hub for datasets related to LLM alignment training.
"""

import requests
import json
import time
from datetime import datetime
import csv
from collections import defaultdict

# Search terms to use
SEARCH_TERMS = [
    "SFT preference",
    "instruction tuning",
    "alignment dataset",
    "DPO dataset",
    "RLHF dataset",
    "preference data",
    "SFT dataset",
    "supervised fine-tuning",
    "direct preference optimization",
    "preference model",
    "hh-rlhf",
    "anthropic hh",
    "stack-llama",
    "orca",
    "flan",
    "alpaca",
    "gpt4all",
    "open assistant",
    "lmsys chatbot arena",
    "vicuna",
    "beluga",
    "ultrachat",
    "camel ai",
]

# Base API URL
HF_API_URL = "https://huggingface.co/api/datasets"

def search_datasets(query, limit=100):
    """Search HuggingFace datasets by query"""
    params = {
        "search": query,
        "full": "true",
        "limit": limit,
        "direction": -1  # Most recently updated first
    }
    try:
        response = requests.get(HF_API_URL, params=params, timeout=30)
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Error searching '{query}': {response.status_code}")
            return []
    except Exception as e:
        print(f"Exception searching '{query}': {e}")
        return []

def get_dataset_info(dataset_id):
    """Get detailed info for a specific dataset"""
    url = f"{HF_API_URL}/{dataset_id}"
    try:
        response = requests.get(url, timeout=30)
        if response.status_code == 200:
            return response.json()
        return None
    except:
        return None

def search_all_terms():
    """Search using all terms and collect results"""
    all_results = {}
    
    print(f"Searching HuggingFace with {len(SEARCH_TERMS)} terms...")
    print("=" * 60)
    
    for i, term in enumerate(SEARCH_TERMS, 1):
        print(f"[{i}/{len(SEARCH_TERMS)}] Searching: '{term}'")
        results = search_datasets(term, limit=50)
        
        for dataset in results:
            ds_id = dataset.get('id', '')
            if ds_id and ds_id not in all_results:
                all_results[ds_id] = dataset
        
        print(f"    Found {len(results)} results, {len(all_results)} unique so far")
        time.sleep(0.5)  # Rate limiting
    
    return all_results

def filter_relevant_datasets(datasets):
    """Filter datasets to keep only relevant ones for SFT/preference/alignment"""
    relevant_keywords = [
        'sft', 'preference', 'alignment', 'instruction', 'tuning', 'dpo', 
        'rlhf', 'reward', 'chat', 'conversation', 'feedback', 'rating',
        'human feedback', 'direct preference', 'orca', 'alpaca', 'flan',
        'gpt4', 'gpt-4', 'llama', 'vicuna', 'sharegpt', 'ultrachat',
        'anthropic', 'hh-rlhf', 'helpfulness', 'harmlessness', 'honesty',
        'oasst', 'open assistant', 'lmsys', 'arena', 'beluga', 'camel'
    ]
    
    filtered = {}
    for ds_id, ds in datasets.items():
        # Check id and description - fix: convert tags list to string
        tags_str = ' '.join(ds.get('tags', []))
        search_text = (ds_id + ' ' + tags_str + ' ' + str(ds.get('cardData', {}))).lower()
        
        # Also check if it has preference-related data
        has_preference = any(kw in search_text for kw in ['preference', 'rating', 'choice', 'chosen', 'rejected'])
        has_sft_related = any(kw in search_text for kw in ['sft', 'instruction', 'tuning', 'fine-tune', 'finetune', 'alignment'])
        has_chat = any(kw in search_text for kw in ['chat', 'conversation', 'dialogue', 'qa', 'question answer'])
        
        # Include if it has preference OR (SFT related AND chat-related)
        if has_preference or (has_sft_related and has_chat):
            filtered[ds_id] = ds
    
    return filtered

def get_detailed_info(datasets):
    """Get more detailed information for each dataset"""
    detailed = {}
    
    print("\nFetching detailed information for each dataset...")
    for i, (ds_id, ds) in enumerate(datasets.items(), 1):
        print(f"[{i}/{len(datasets)}] Getting details: {ds_id}")
        
        info = get_dataset_info(ds_id)
        if info:
            detailed[ds_id] = {**ds, **info}
        else:
            detailed[ds_id] = ds
        
        time.sleep(0.3)
    
    return detailed

def categorize_dataset(ds_id, ds):
    """Categorize a dataset based on its properties"""
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

def extract_use_cases(ds_id, ds):
    """Extract potential use cases"""
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

def format_output(datasets):
    """Format the results for display"""
    output = []
    output.append("=" * 80)
    output.append("HUGGINGFACE SFT/PREFERENCE/ALIGNMENT DATASETS - COMPREHENSIVE LIST")
    output.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    output.append("=" * 80)
    output.append("")
    
    # Group by category
    by_category = defaultdict(list)
    for ds_id, ds in datasets.items():
        cats = categorize_dataset(ds_id, ds)
        for cat in cats:
            by_category[cat].append((ds_id, ds))
    
    for category, items in sorted(by_category.items()):
        output.append(f"\n{'=' * 40}")
        output.append(f"CATEGORY: {category} ({len(items)} datasets)")
        output.append("=" * 40)
        
        for ds_id, ds in sorted(items, key=lambda x: x[0]):
            output.append(f"\n--- {ds_id} ---")
            
            # URL
            owner, name = ds_id.split('/') if '/' in ds_id else ('', ds_id)
            output.append(f"URL: https://huggingface.co/datasets/{ds_id}")
            output.append(f"Owner: {owner}")
            output.append(f"Name: {name}")
            
            # Description
            desc = ds.get('cardData', {}).get('annotations', {}).get('description', [])
            if desc:
                output.append(f"Description: {desc[0] if desc else 'N/A'}")
            else:
                # Try to get from siblings
                siblings = ds.get('siblings', [])
                if siblings:
                    output.append(f"Description: (See dataset card)")
            
            # Tags
            tags = ds.get('tags', [])
            if tags:
                output.append(f"Tags: {', '.join(tags[:10])}")
            
            # Use cases
            use_cases = extract_use_cases(ds_id, ds)
            output.append(f"Use Cases: {', '.join(use_cases)}")
            
            # Last updated
            if 'lastModified' in ds:
                output.append(f"Last Updated: {ds['lastModified']}")
            
            # Downloads (if available)
            if 'downloads' in ds:
                output.append(f"Downloads: {ds['downloads']:,}")
            
            # Gated
            if ds.get('gated'):
                output.append(f"Gated: Yes")
            
            # Library
            if 'library_name' in ds:
                output.append(f"Library: {ds['library_name']}")
    
    return "\n".join(output)

def save_json(datasets, filename="hf_sft_datasets.json"):
    """Save results to JSON"""
    # Convert to serializable format
    serializable = {}
    for ds_id, ds in datasets.items():
        serializable[ds_id] = {}
        for k, v in ds.items():
            if isinstance(v, (str, int, float, bool, list, dict)) or v is None:
                serializable[ds_id][k] = v
    
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(serializable, f, indent=2, ensure_ascii=False)
    print(f"\nSaved JSON to {filename}")

def save_csv(datasets, filename="hf_sft_datasets.csv"):
    """Save results to CSV"""
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow([
            'URL', 'Owner', 'Name', 'Description', 'Categories', 
            'Use Cases', 'Tags', 'Last Updated', 'Downloads', 'Gated'
        ])
        
        for ds_id, ds in sorted(datasets.items()):
            owner, name = ds_id.split('/') if '/' in ds_id else ('', ds_id)
            
            desc = ds.get('cardData', {}).get('annotations', {}).get('description', [])
            desc = desc[0] if desc else ''
            
            cats = ', '.join(categorize_dataset(ds_id, ds))
            uses = ', '.join(extract_use_cases(ds_id, ds))
            
            tags = ', '.join(ds.get('tags', [])[:10])
            
            last_mod = ds.get('lastModified', '')
            downloads = ds.get('downloads', '')
            gated = 'Yes' if ds.get('gated') else 'No'
            
            writer.writerow([
                f"https://huggingface.co/datasets/{ds_id}",
                owner, name, desc, cats, uses, tags, last_mod, downloads, gated
            ])
    
    print(f"Saved CSV to {filename}")

def main():
    print("HuggingFace Dataset Search for SFT/Preference/Alignment")
    print("=" * 60)
    
    # Step 1: Search all terms
    all_datasets = search_all_terms()
    print(f"\nTotal unique datasets found: {len(all_datasets)}")
    
    # Step 2: Filter to relevant ones
    relevant = filter_relevant_datasets(all_datasets)
    print(f"Relevant datasets after filtering: {len(relevant)}")
    
    # Step 3: Get detailed info (optional - can be slow)
    # detailed = get_detailed_info(relevant)
    detailed = relevant  # Skip for speed
    
    # Step 4: Output results
    output = format_output(detailed)
    print(output)
    
    # Step 5: Save to files
    save_json(detailed)
    save_csv(detailed)
    
    print("\n" + "=" * 60)
    print("SEARCH COMPLETE")
    print("=" * 60)

if __name__ == "__main__":
    main()