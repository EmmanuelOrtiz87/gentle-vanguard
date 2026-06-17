#!/usr/bin/env python3
"""
Fetch Dataset README Content for Key OpenAssistant Datasets
============================================================
"""

import json
from huggingface_hub import HfApi, hf_hub_download

OUTPUT_FILE = "hf_dataset_readmes.json"

def get_readme_content(dataset_id: str):
    """Try to get README content for a dataset."""
    api = HfApi()
    
    try:
        # Get file list
        files = api.list_repo_files(repo_id=dataset_id, repo_type="dataset")
        
        readme_file = None
        for f in files:
            if f.lower() == "readme.md":
                readme_file = f
                break
        
        if readme_file:
            # Download README
            path = hf_hub_download(
                repo_id=dataset_id,
                filename="README.md",
                repo_type="dataset"
            )
            
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Return first 3000 characters
            return {
                "has_readme": True,
                "readme_preview": content[:3000],
                "full_length": len(content)
            }
        else:
            return {"has_readme": False, "files": files[:10]}
            
    except Exception as e:
        return {"error": str(e)}

# Key datasets to get README for
KEY_DATASETS = [
    "OpenAssistant/oasst1",
    "OpenAssistant/oasst2",
    "timdettmers/openassistant-guanaco",
    "OpenAssistant/oasst_top1_2023-08-25",
    "h2oai/openassistant_oasst1",
]

print("="*70)
print("FETCHING README CONTENT FOR KEY DATASETS")
print("="*70)

results = {}

for dataset_id in KEY_DATASETS:
    print(f"\nFetching README for: {dataset_id}")
    result = get_readme_content(dataset_id)
    results[dataset_id] = result
    
    if "error" in result:
        print(f"  ERROR: {result['error']}")
    elif result.get("has_readme"):
        print(f"  README Length: {result.get('full_length', 'N/A')} chars")
        # Print first 500 chars
        preview = result.get("readme_preview", "")[:500]
        print(f"  Preview: {preview}...")
    else:
        print(f"  No README found, files: {result.get('files', [])}")

# Save results
with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
    json.dump(results, f, indent=2, ensure_ascii=False)

print(f"\n{'='*70}")
print(f"Results saved to: {OUTPUT_FILE}")
print(f"{'='*70}")