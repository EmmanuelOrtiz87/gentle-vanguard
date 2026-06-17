#!/usr/bin/env python3
"""
Enhanced HuggingFace Dataset Search - Get Detailed Info
=========================================================
This script retrieves detailed information for key OpenAssistant datasets.
"""

import json
from huggingface_hub import HfApi, hf_hub_download

# Key datasets to get detailed info for
KEY_DATASETS = [
    "OpenAssistant/oasst1",
    "OpenAssistant/oasst2",
    "timdettmers/openassistant-guanaco",
    "h2oai/openassistant_oasst1",
    "OpenAssistant/oasst_top1_2023-08-25",
    "OpenAssistant/OASST-DE",
    "argilla/oasst_response_comparison",
    "argilla/oasst_response_quality",
    "bigcode/oasst-octopack",
    "tasksource/oasst1_pairwise_rlhf_reward",
    "Intel/openassistant-preprocessed",
    "OpenAssistant/oasst2",
    "laion/OASST2",
]

OUTPUT_FILE = "hf_detailed_dataset_info.json"

def get_dataset_details(dataset_id: str):
    """Get detailed information about a dataset."""
    api = HfApi()
    
    try:
        # Try to get dataset info using correct method
        info = api.dataset_info(repo_id=dataset_id)
        
        result = {
            "id": info.id,
            "url": f"https://huggingface.co/datasets/{dataset_id}",
            "last_modified": str(info.last_modified) if info.last_modified else None,
            "private": info.private,
            "downloads": getattr(info, 'downloads', None),
            "likes": getattr(info, 'likes', None),
            "gated": getattr(info, 'gated', None),
        }
        
        # Get file list
        try:
            files = api.list_repo_files(repo_id=dataset_id, repo_type="dataset")
            result["files"] = files[:30]
            result["total_files"] = len(files)
        except Exception as e:
            result["files_error"] = str(e)
        
        return result
        
    except Exception as e:
        return {
            "id": dataset_id,
            "error": str(e)
        }

def main():
    print("="*70)
    print("GETTING DETAILED INFO FOR KEY DATASETS")
    print("="*70)
    
    results = {}
    
    for dataset_id in KEY_DATASETS:
        print(f"\nFetching: {dataset_id}")
        details = get_dataset_details(dataset_id)
        results[dataset_id] = details
        
        if "error" in details:
            print(f"  ERROR: {details['error']}")
        else:
            print(f"  URL: {details.get('url', 'N/A')}")
            print(f"  Last Modified: {details.get('last_modified', 'N/A')}")
            print(f"  Downloads: {details.get('downloads', 'N/A')}")
            print(f"  Likes: {details.get('likes', 'N/A')}")
            print(f"  Total Files: {details.get('total_files', 'N/A')}")
    
    # Save results
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    
    print(f"\n{'='*70}")
    print(f"Results saved to: {OUTPUT_FILE}")
    print(f"{'='*70}")

if __name__ == "__main__":
    main()