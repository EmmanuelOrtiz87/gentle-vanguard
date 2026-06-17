#!/usr/bin/env python3
"""Get detailed information about key OpenAI-related datasets."""

from huggingface_hub import HfApi

api = HfApi()

# Key datasets to get detailed info for
key_datasets = [
    # Original OpenAI datasets
    "openai/summarize_from_feedback",
    "openai/gsm8k", 
    "openai/gdpval",
    "openai/healthbench",
    "openai/openai_humaneval",
    
    # TLDR/ Summarization datasets
    "CarperAI/openai_summarize_tldr",
    "Dahoas/openai_summarize_tldr_human_eval",
    "UCL-DARK/openai-tldr-summarisation-preferences",
    "UCL-DARK/openai-tldr-filtered",
    "mnoukhov/openai_summarize_comparisons_tldrprompt",
    
    # Anthropic HH-RLHF datasets (related to OpenAI RLHF work)
    "Anthropic/hh-rlhf",
    "Dahoas/full-hh-rlhf",
    "Dahoas/rm-hh-rlhf",
    "HuggingFaceH4/hh-rlhf",
    
    # Reward modeling datasets
    "HumanDynamics/reward_modeling_dataset",
    "andersonbcdefg/reward-modeling-short-tokenized",
    "nvidia/Nemotron-RLHF-GenRM-v1",
    
    # Preference datasets
    "HuggingFaceH4/summarize-from-feedback",
    "TianqiLiuAI/pair_preference_model_dataset_rrm",
    "RLHFlow/pair_preference_model_dataset",
    
    # DPO datasets
    "HuggingFaceH4/h4-tests-format-dpo-dataset",
    "snorkelai/Snorkel-Mistral-PairRM-DPO-Dataset",
    
    # Constitutional AI
    "edpowers/constitutional_ai_data",
]

print("=" * 100)
print("DETAILED INFORMATION ABOUT KEY OPENAI-RELATED DATASETS")
print("=" * 100)

import json

results = []

for dataset_id in key_datasets:
    print(f"\n{'='*80}")
    print(f"Dataset: {dataset_id}")
    print(f"{'='*80}")
    
    try:
        # Get dataset info
        info = api.dataset_info(repo_id=dataset_id)
        
        # Try to get the README description
        try:
            # Check for README files
            readme_content = None
            for sibling in info.siblings:
                if 'readme' in sibling.rfilename.lower():
                    # Would need to read the file content
                    pass
        except:
            pass
        
        url = f"https://huggingface.co/datasets/{dataset_id}"
        print(f"URL: {url}")
        print(f"Downloads: {getattr(info, 'downloads', 'N/A')}")
        print(f"Last modified: {getattr(info, 'last_modified', 'N/A')}")
        
        results.append({
            'dataset_id': dataset_id,
            'url': url,
            'downloads': getattr(info, 'downloads', None),
            'last_modified': str(getattr(info, 'last_modified', None))
        })
        
    except Exception as e:
        print(f"Error: {e}")
        results.append({
            'dataset_id': dataset_id,
            'error': str(e)
        })

# Save results
with open('dataset_details.json', 'w') as f:
    json.dump(results, f, indent=2)

print("\n\n" + "=" * 100)
print("DATASET DETAILS SAVED TO dataset_details.json")
print("=" * 100)