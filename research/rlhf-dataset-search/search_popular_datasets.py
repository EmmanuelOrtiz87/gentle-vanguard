#!/usr/bin/env python3
"""
Additional HuggingFace Dataset Search - Popular Alignment Datasets
Search for specific known datasets and get detailed information
"""

import requests
import json
import time

# Specific popular datasets to look up
POPULAR_DATASETS = [
    # Anthropic HH-RLHF
    "Anthropic/hh-rlhf",
    "Dahoas/full-hh-rlhf",
    "Dahoas/synthetic-instruct-gptj-pairwise",
    
    # UltraFeedback
    "openbmb/UltraFeedback",
    "openbmb/UltraFeedback-Binarized-Preferences",
    
    # Open Assistant
    "OpenAssistant/oasst1",
    "OpenAssistant/oasst2",
    "OpenAssistant/oasst_all",
    
    # LMSYS
    "lmsys/chatbot_arena_conversations",
    "lmsys/arena-human-preference-50k",
    
    # Stanford
    "stanfordnlp/SHP",
    "stanfordnlp/ HH-RLHF",
    
    # ShareGPT
    "raphaelph/startups-eval-poc",
    "jeff911/ShareGPT_Vicuna_unfiltered",
    "RyotaAI/ShareGPT-10M",
    
    # Alpaca
    "tatsu-lab/alpaca",
    "yahma/alpaca-cleaned",
    "cognitive computations/ Alpaca-Data-Instruct",
    
    # FLAN
    "google/flan",
    "google/flan-collection",
    
    # Vicuna
    "lmsys/vicuna-80k",
    "anon8231489123/ShareGPT_Vicuna_unfiltered",
    
    # Beaver
    "PKU-Alignment/BeaverTails",
    "PKU-Alignment/BeaverDam",
    
    # HelpSteer
    "nvidia/HelpSteer",
    "nvidia/HelpSteer2",
    
    # Other popular
    "HuggingFaceH4/ultrachat_200k",
    "HuggingFaceH4/alignment-sft",
    "HuggingFaceH4/preference_dataset",
    
    # Camel
    "camel-ai/math_category",
    "camel-ai/science",
    
    # Orca
    "Microsoft/orca",
    "Open-Orca/OpenOrca",
    
    # Others
    "meta-math/MetaMathQA",
    "meta-math/MetaMath-400K",
    "open-internLM/InternLM-Medium-20k-chat",
    "BAAI/Infinity-Instruct",
    "BAAI/InfiInstruction",
    
    # BELUGA
    "FreeWeel/beluga-release",
    "paust/chatdoctor",
    
    # Code
    "openai/gsm8k",
    "openai/MATH",
    "bigcode/the-stack",
    "codeparrot/github-jupyter-pairs",
    
    # StackLlama
    "trl-internal-testing/stack-llama-2 preference",
    "argilla/argilla-preference-datasets",
    
    # Others
    "jondurbin/airoboros-3.2",
    "ManifestAI/magical-cake",
    "Narsil/instruction-dataset",
    "databricks/databricks-dolly-15k",
    "LAION/OIG",
]

HF_API_URL = "https://huggingface.co/api/datasets"

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

def format_size(num_bytes):
    """Format size in bytes"""
    if num_bytes < 1024:
        return f"{num_bytes} B"
    elif num_bytes < 1024**2:
        return f"{num_bytes/1024:.1f} KB"
    elif num_bytes < 1024**3:
        return f"{num_bytes/(1024**2):.1f} MB"
    else:
        return f"{num_bytes/(1024**3):.1f} GB"

def main():
    print("=" * 80)
    print("POPULAR SFT/PREFERENCE/ALIGNMENT DATASETS - DETAILED SEARCH")
    print("=" * 80)
    print()
    
    results = []
    
    for i, ds_id in enumerate(POPULAR_DATASETS, 1):
        print(f"[{i}/{len(POPULAR_DATASETS)}] Fetching: {ds_id}")
        info = get_dataset_info(ds_id)
        
        if info and info.get('id'):
            print(f"    Found: {info.get('id')}")
            results.append(info)
        else:
            print(f"    Not found")
        
        time.sleep(0.3)
    
    # Save results
    with open("hf_popular_datasets.json", "w", encoding="utf-8") as f:
        # Make serializable
        serializable = []
        for ds in results:
            item = {}
            for k, v in ds.items():
                if isinstance(v, (str, int, float, bool, list, dict)) or v is None:
                    item[k] = v
            serializable.append(item)
        
        json.dump(serializable, f, indent=2, ensure_ascii=False)
    
    # Print detailed summary
    print("\n" + "=" * 80)
    print("POPULAR DATASETS FOUND")
    print("=" * 80)
    
    for ds in results:
        ds_id = ds.get('id', 'N/A')
        author = ds.get('author', 'N/A')
        last_mod = ds.get('lastModified', 'N/A')
        downloads = ds.get('downloads', 'N/A')
        likes = ds.get('likes', 0)
        gated = ds.get('gated', False)
        
        # Get size info
        card_data = ds.get('cardData', {})
        dataset_info = card_data.get('dataset_info', {})
        splits = dataset_info.get('splits', [])
        
        num_examples = 0
        for split in splits:
            num_examples += split.get('num_examples', 0)
        
        # Get format
        tags = ds.get('tags', [])
        format_tag = [t for t in tags if t.startswith('format:')]
        format_str = format_tag[0].replace('format:', '') if format_tag else 'N/A'
        
        # Get language
        language = card_data.get('language', ['en'])
        
        print(f"\n--- {ds_id} ---")
        print(f"  Owner/Author: {author}")
        print(f"  URL: https://huggingface.co/datasets/{ds_id}")
        print(f"  Size: {num_examples:,} examples")
        print(f"  Format: {format_str}")
        print(f"  Language: {language}")
        print(f"  Last Updated: {last_mod}")
        print(f"  Downloads: {downloads:,}" if isinstance(downloads, int) else f"  Downloads: {downloads}")
        print(f"  Likes: {likes}")
        print(f"  Gated: {gated}")
        
        # Try to get description
        if 'description' in ds:
            desc = ds.get('description', '')[:200]
            if desc:
                print(f"  Description: {desc}...")
    
    print("\n" + "=" * 80)
    print(f"Total datasets found: {len(results)}")
    print("=" * 80)
    
    print(f"\nSaved to: hf_popular_datasets.json")

if __name__ == "__main__":
    main()