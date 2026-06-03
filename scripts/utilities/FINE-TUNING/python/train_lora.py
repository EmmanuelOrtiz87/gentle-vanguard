#!/usr/bin/env python3
"""
train_lora.py — LoRA fine-tuning for Gentle-Vanguard domain agents.

Usage:
    python train_lora.py --domain BA --dataset .ft/dataset/train/BA.jsonl --output .ft/adapters/BA

Requirements (optional, only for actual training):
    pip install unsloth transformers datasets torch accelerate
"""

import argparse
import json
import os
import sys
from datetime import datetime


def main():
    parser = argparse.ArgumentParser(description="LoRA fine-tuning for GV domain agents")
    parser.add_argument("--domain", required=True, choices=["BA", "SAD", "DEV", "QA"],
                        help="Agent domain to train")
    parser.add_argument("--dataset", required=True,
                        help="Path to training JSONL file")
    parser.add_argument("--output", required=True,
                        help="Output directory for LoRA adapter")
    parser.add_argument("--base-model", default="mistralai/Mistral-7B-v0.1",
                        help="Base model (default: Mistral-7B)")
    parser.add_argument("--epochs", type=int, default=3,
                        help="Number of training epochs")
    parser.add_argument("--lr", type=float, default=2e-4,
                        help="Learning rate")
    parser.add_argument("--rank", type=int, default=8,
                        help="LoRA rank")
    parser.add_argument("--dry-run", action="store_true",
                        help="Validate setup without training")
    args = parser.parse_args()

    dataset_path = os.path.abspath(args.dataset)
    output_path = os.path.abspath(args.output)

    if not os.path.exists(dataset_path):
        print(f"[ERROR] Dataset not found: {dataset_path}")
        sys.exit(1)

    with open(dataset_path) as f:
        records = [json.loads(line) for line in f if line.strip()]

    print(f"=== LoRA Trainer ===")
    print(f"Domain: {args.domain}")
    print(f"Dataset: {dataset_path} ({len(records)} records)")
    print(f"Base model: {args.base_model}")
    print(f"Output: {output_path}")
    print(f"Epochs: {args.epochs} | LR: {args.lr} | Rank: {args.rank}")

    if args.dry_run:
        print(f"\n[DRY-RUN] Setup validated. Use --dry-run=False to train.")
        sample = records[0] if records else {}
        print(f"Sample record: {json.dumps(sample, indent=2)[:200]}...")
        return

    # Actual training code (requires unsloth + transformers)
    try:
        from unsloth import FastLanguageModel
        import torch
        from datasets import load_dataset
        from transformers import TrainingArguments
        from trl import SFTTrainer

        print("[TRAIN] Loading base model...")
        model, tokenizer = FastLanguageModel.from_pretrained(
            model_name=args.base_model,
            max_seq_length=2048,
            dtype=None,
            load_in_4bit=True,
        )

        print("[TRAIN] Adding LoRA adapters...")
        model = FastLanguageModel.get_peft_model(
            model,
            r=args.rank,
            target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                            "gate_proj", "up_proj", "down_proj"],
            lora_alpha=16,
            lora_dropout=0,
            bias="none",
            use_gradient_checkpointing="unsloth",
            random_state=42,
        )

        print("[TRAIN] Loading dataset...")
        dataset = load_dataset("json", data_files=dataset_path, split="train")

        print("[TRAIN] Configuring trainer...")
        trainer = SFTTrainer(
            model=model,
            tokenizer=tokenizer,
            train_dataset=dataset,
            dataset_text_field="instruction",
            max_seq_length=2048,
            args=TrainingArguments(
                per_device_train_batch_size=2,
                gradient_accumulation_steps=4,
                warmup_steps=5,
                num_train_epochs=args.epochs,
                learning_rate=args.lr,
                fp16=not torch.cuda.is_bf16_supported(),
                bf16=torch.cuda.is_bf16_supported(),
                logging_steps=1,
                output_dir=output_path,
                save_strategy="epoch",
            ),
        )

        print("[TRAIN] Starting training...")
        trainer.train()

        print(f"[TRAIN] Saving adapter to {output_path}...")
        trainer.model.save_pretrained(output_path)
        tokenizer.save_pretrained(output_path)

        print("[TRAIN] Training complete!")

    except ImportError as e:
        print(f"[ERROR] Missing dependency: {e}")
        print("[HINT] Install: pip install unsloth transformers datasets torch accelerate")
        sys.exit(1)


if __name__ == "__main__":
    main()
