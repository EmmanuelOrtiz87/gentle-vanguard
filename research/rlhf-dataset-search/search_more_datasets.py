#!/usr/bin/env python3
"""
Additional HuggingFace Dataset Search - Even more datasets
"""

import requests
import json
import time

# More specific datasets
MORE_DATASETS = [
    # RLHF/Preference
    "HuggingFaceH4/rlhf-preference-data",
    "HuggingFaceH4/rlhf-10k-preference-samples",
    "HuggingFaceH4/helpful-base-demographics",
    "HuggingFaceH4/helpful-instruction-following",

    # More instruction datasets
    "lamini/lamini-docs",
    "samsum",
    "multi_woz_v22",
    "deepset/german-ner",
    "glue",
    "snips",

    # More alignment
    "Anthropic/hh-rlhf",
    "Anthropic/hh-rlhf-harmless-base",
    "Anthropic/hh-rlhf-helpful-base",
    "PKU-Alignment/PKU-SafeRLHF",

    # More preference
    "Intel/dromedary-65b-instruct-experimental",
    "lnicals/prime-nlp-preference",

    # Code
    "bigcode/bigcodebench",
    "openai/openai-python",
    "anthropic/hh-rlhf",

    # Math
    "mslmath/grade-school-math",
    "chalkgpt/math_qa",

    # Medical
    "medalpaca/medical-oqa",
    "meditron/meditron",

    # More
    "deepmind/mathematics_dataset",
    "EleutherAI/the_pile",
    "EleutherAI/pile_extra",

    # TRL examples
    "trl-internal-testing/tldr-preference-sft-trl-style",
    "trl-lib/ultrafeedback-sft",
    "trl-lib/dpo-mix-10k",

    # More specific ones
    "argilla/distilabel-capybara-dpo-merge",
    "argilla/ultrafeedback-cmp",
    "argilla/ultrafeedback-binarized-preferences",

    # KTO
    "Intel/orca_dpo_pairs",
    "HuggingFaceH4/chosen-rejected-samples",

    # More recent
    "allenai/olmes",
    "allenai/rl4lme",

    # More
    "google/boolq",
    "google/c4",
    "c4_200m",
    "togethercomputer/RedPajama-Data",
    "togethercomputer/RedPajama-Data-1T",

    # More alignment
    "AlignmentLegibility/Alignment_Dataset",
    "AlignmentLegibility/ConstitutionalAI",

    # More DPO
    "cjwbw/DPO_SFT_Dataset",
    "cogsway/cleaned-dpo-pairs-sharegpt",

    # More SFT
    "BAAI/baai/InfiInstruction",
    "BAAI/baai/Infinity-Instruct",

    # More
    "mbpp",
    "humaneval",
    "APPS",
    "codegen_nl/codegen_nl",

    # More
    "K Obracz/not-alt-260k",
    "v2-ocr/mtp_2023_06_12",

    # More
    "infinite-llm/instruct",
    "GAIR/primera",

    # More
    "nlpcloud/assistant-conversations",
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

def main():
    print("=" * 80)
    print("ADDITIONAL DATASETS - SEARCH ROUND 2")
    print("=" * 80)
    print()

    results = []

    for i, ds_id in enumerate(MORE_DATASETS, 1):
        print(f"[{i}/{len(MORE_DATASETS)}] Fetching: {ds_id}")
        info = get_dataset_info(ds_id)

        if info and info.get('id'):
            print(f"    Found: {info.get('id')}")
            results.append(info)
        else:
            print(f"    Not found")

        time.sleep(0.3)

    # Save results
    with open("hf_more_datasets.json", "w", encoding="utf-8") as f:
        serializable = []
        for ds in results:
            item = {}
            for k, v in ds.items():
                if isinstance(v, (str, int, float, bool, list, dict)) or v is None:
                    item[k] = v
            serializable.append(item)

        json.dump(serializable, f, indent=2, ensure_ascii=False)

    print(f"\nTotal found: {len(results)}")
    print(f"Saved to: hf_more_datasets.json")

if __name__ == "__main__":
    main()