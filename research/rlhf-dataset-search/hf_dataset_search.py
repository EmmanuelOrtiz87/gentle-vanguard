#!/usr/bin/env python3
"""
HuggingFace Dataset Search Script for OpenAssistant/OASST Research
====================================================================
This script searches HuggingFace for datasets related to OpenAssistant, 
OASST, or Open Assistant for LLM alignment and human feedback.

Usage:
    python hf_dataset_search.py

Requirements:
    pip install huggingface_hub

Author: Research Script
Date: 2026-06-10
"""

import os
import json
from datetime import datetime
from huggingface_hub import HfApi, list_datasets

# Configuration
SEARCH_QUERIES = [
    "openassistant",
    "OASST", 
    "open-assistant",
    "OpenAssistant"
]

# Output file
OUTPUT_FILE = "hf_openasst_datasets_results.json"


def search_datasets(query: str, limit: int = 100):
    """
    Search HuggingFace datasets with a given query.
    
    Args:
        query: The search query
        limit: Maximum number of results to fetch
    
    Returns:
        List of matching dataset info dictionaries
    """
    print(f"\n{'='*60}")
    print(f"Searching for: '{query}'")
    print(f"{'='*60}")
    
    try:
        # Use list_datasets with search query
        datasets = list(list_datasets(search=query, limit=limit))
        
        results = []
        for i, dataset in enumerate(datasets):
            print(f"  [{i+1}] {dataset.id}")
            results.append({
                "id": dataset.id,
                "name": dataset.id.split("/")[-1] if "/" in dataset.id else dataset.id,
                "owner": dataset.id.split("/")[0] if "/" in dataset.id else None,
            })
        
        print(f"  Found {len(results)} datasets")
        return results
        
    except Exception as e:
        print(f"  ERROR: {e}")
        return []


def get_dataset_details(dataset_id: str):
    """
    Get detailed information about a specific dataset.
    
    Args:
        dataset_id: The HuggingFace dataset ID (owner/name)
    
    Returns:
        Dictionary with detailed dataset information
    """
    api = HfApi()
    
    try:
        # Get dataset info
        dataset_info = api.dataset_info(repo_id=dataset_id, repo_type="dataset")
        
        # Extract relevant information
        details = {
            "url": f"https://huggingface.co/datasets/{dataset_id}",
            "id": dataset_info.id,
            "sha": dataset_info.sha,
            "last_modified": str(dataset_info.last_modified) if dataset_info.last_modified else None,
            "private": dataset_info.private,
            "downloads": getattr(dataset_info, 'downloads', None),
            "likes": getattr(dataset_info, 'likes', None),
            "tags": getattr(dataset_info, 'tags', []),
        }
        
        # Get sibling files (to see dataset structure)
        try:
            files = api.list_repo_files(repo_id=dataset_id, repo_type="dataset")
            details["files"] = files[:50]  # First 50 files
            details["total_files"] = len(files)
        except:
            details["files"] = []
        
        return details
        
    except Exception as e:
        return {
            "id": dataset_id,
            "error": str(e)
        }


def get_dataset_card(dataset_id: str):
    """
    Read the dataset card (README.md) from HuggingFace.
    
    Args:
        dataset_id: The HuggingFace dataset ID
    
    Returns:
        Dictionary with card content and metadata
    """
    api = HfApi()
    
    try:
        # Try to get the README
        files = api.list_repo_files(repo_id=dataset_id, repo_type="dataset")
        
        card_info = {
            "has_readme": False,
            "has_yaml": False,
            "config_files": []
        }
        
        for f in files:
            if f.lower() == "readme.md":
                card_info["has_readme"] = True
            elif f.lower() in ["dataset_infos.json", "dataset_info.yaml", "meta.json"]:
                card_info["config_files"].append(f)
            elif f.endswith((".yaml", ".yml", ".json")) and "dataset" in f.lower():
                card_info["config_files"].append(f)
        
        return card_info
        
    except Exception as e:
        return {"error": str(e)}


def main():
    """Main execution function."""
    print("="*70)
    print("HUGGINGFACE DATASET SEARCH: OpenAssistant/OASST Research")
    print("="*70)
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Search queries: {SEARCH_QUERIES}")
    
    # Initialize results structure
    all_results = {
        "search_metadata": {
            "timestamp": datetime.now().isoformat(),
            "queries": SEARCH_QUERIES,
        },
        "datasets_found": [],
        "detailed_info": {}
    }
    
    # Track unique datasets across all searches
    all_dataset_ids = set()
    search_results_by_query = {}
    
    # Perform searches for each query
    for query in SEARCH_QUERIES:
        results = search_datasets(query, limit=100)
        search_results_by_query[query] = results
        
        for dataset in results:
            all_dataset_ids.add(dataset["id"])
    
    print(f"\n{'='*60}")
    print(f"UNIQUE DATASETS FOUND: {len(all_dataset_ids)}")
    print(f"{'='*60}")
    
    # Get detailed info for each unique dataset
    for i, dataset_id in enumerate(sorted(all_dataset_ids)):
        print(f"\n[{i+1}/{len(all_dataset_ids)}] Getting details for: {dataset_id}")
        
        try:
            # Get basic details
            details = get_dataset_details(dataset_id)
            
            # Get card info
            card_info = get_dataset_card(dataset_id)
            details["card_info"] = card_info
            
            all_results["detailed_info"][dataset_id] = details
            
            # Print summary
            print(f"  URL: {details.get('url', 'N/A')}")
            print(f"  Last Modified: {details.get('last_modified', 'N/A')}")
            print(f"  Downloads: {details.get('downloads', 'N/A')}")
            print(f"  Likes: {details.get('likes', 'N/A')}")
            
        except Exception as e:
            print(f"  ERROR getting details: {e}")
            all_results["detailed_info"][dataset_id] = {"error": str(e)}
    
    # Save results
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(all_results, f, indent=2, ensure_ascii=False)
    
    print(f"\n{'='*70}")
    print(f"RESULTS SAVED TO: {OUTPUT_FILE}")
    print(f"Total datasets found: {len(all_dataset_ids)}")
    print(f"Completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*70}")
    
    # Print summary table
    print("\n" + "="*70)
    print("SUMMARY TABLE")
    print("="*70)
    print(f"{'Dataset ID':<50} {'Downloads':<15} {'Likes':<10}")
    print("-"*70)
    
    for dataset_id in sorted(all_dataset_ids):
        details = all_results["detailed_info"].get(dataset_id, {})
        downloads = details.get('downloads', 'N/A')
        likes = details.get('likes', 'N/A')
        print(f"{dataset_id:<50} {str(downloads):<15} {str(likes):<10}")


if __name__ == "__main__":
    main()