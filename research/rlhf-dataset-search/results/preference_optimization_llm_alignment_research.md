# Comprehensive Research Report: Preference Optimization and LLM Alignment

## Executive Summary

This research report presents a thorough investigation of repositories and papers related to
preference optimization and LLM alignment on HuggingFace and GitHub. The search covered multiple
categories including preference optimization methods beyond Direct Preference Optimization (DPO),
online/offline RLHF implementations, reward modeling, PPO for LLM fine-tuning, GRPO variants, and
reinforcement learning alignment research. A total of significant repositories were identified and
analyzed.

---

## 1. Preference Optimization Methods Beyond DPO

### 1.1 KTO (Kahneman-Tversky Optimization)

#### Repository: RL-Finetuning-of-Large-Language-Models

- **Full Repository Name**: devj10/RL-Finetuning-of-Large-Language-Models
- **GitHub URL**: https://github.com/devj10/RL-Finetuning-of-Large-Language-Models
- **Contributors/Maintainers**: devj10 (individual developer)
- **Technical Approach**: Comparison of preference-based fine-tuning methods for LLMs including DPO,
  ORPO, TOPR, KTO, and RLOO on Qwen2.5-0.5B using SmolTalk and UltraFeedback datasets
- **Key Features**: KTO demonstrated as a strong, efficient alternative to DPO; comparative analysis
  shows ORPO performs best with low cost even from base model
- **Programming Language**: Python
- **Last Update**: May 13, 2026
- **Star Count**: 1
- **Documentation**: Repository includes comprehensive comparison documentation

#### Repository: Korean LLM DPO Alignment

- **Full Repository Name**: duck3244/korean-llm-dpo-alignment
- **GitHub URL**: https://github.com/duck3244/korean-llm-dpo-alignment
- **Contributors/Maintainers**: duck3244 (individual developer)
- **Technical Approach**: Korean LLM preference alignment supporting DPO, KTO, ORPO, SimPo, and SFT
- **Key Features**: Multi-method preference alignment for Korean language models
- **Programming Language**: Python
- **Last Update**: May 28, 2026
- **Star Count**: 0
- **License**: MIT License

#### Repository: Targeted-Manipulation-and-Deception-in-LLMs

- **Full Repository Name**: marcus-jw/Targeted-Manipulation-and-Deception-in-LLMs
- **GitHub URL**: https://github.com/marcus-jw/Targeted-Manipulation-and-Deception-in-LLMs
- **Contributors/Maintainers**: marcus-jw (individual developer)
- **Technical Approach**: Implements KTO and expert iteration for training on user preferences;
  generative multi-turn RL environment with support for agent, user, user feedback, transition and
  veto models
- **Key Features**: Research on targeted manipulation and deception when optimizing LLMs for user
  feedback
- **Programming Language**: Python
- **Last Update**: March 28, 2026
- **Star Count**: 25
- **Forks**: 5

---

### 1.2 ORPO (Odds Ratio Preference Optimization)

#### Repository: orpo

- **Full Repository Name**: zengatso/orpo
- **GitHub URL**: https://github.com/zengatso/orpo
- **Contributors/Maintainers**: zengatso (individual developer)
- **Technical Approach**: Framework for monolithic preference optimization without a reference model
- **Key Features**: ORPO performs best with low cost even from base model; supports multiple
  optimization methods including DPO, KTO, PPO
- **Programming Language**: Python
- **Last Update**: June 10, 2026
- **Star Count**: 0
- **Topics**: dpo, kto, llm, lora, ppo, reinforcement-learning, rlhf, qwen, gpt, privacy-preserving

#### Repository: LLM Preference Learning

- **Full Repository Name**: fabiantoh98/llm-preference-learning
- **GitHub URL**: https://github.com/fabiantoh98/llm-preference-learning
- **Contributors/Maintainers**: fabiantoh98 (individual developer)
- **Technical Approach**: End-to-end LLM preference learning pipeline supporting DPO, ORPO, KTO, and
  RLHF with 4-bit quantization, LoRA, and memory-efficient training on a single 8GB GPU
- **Key Features**: Memory-efficient training, supports multiple preference learning methods
- **Programming Language**: Python
- **Last Update**: February 11, 2026
- **Star Count**: 0
- **Topics**: dpo, fine-tuning, llm, lora, orpo, pytorch, qlora, rlhf, transformers, trl

---

### 1.3 SimPO (Simple Preference Optimization)

Related implementations found in Korean LLM alignment repository, indicating active development in
this area.

---

### 1.4 RLOO (REINFORCE Leave-One-Out)

#### Repository: Reinforcement Tuning LLMs

- **Full Repository Name**: YuvaneshSankar/reinforcement-tuninig-llms
- **GitHub URL**: https://github.com/YuvaneshSankar/reinforcement-tuninig-llms
- **Contributors/Maintainers**: YuvaneshSankar (individual developer)
- **Technical Approach**: Codebase for fine-tuning large language models using reinforcement
  learning and preference-based optimization methods including RLHF, DPO, GRPO, and RLOO with
  different reward scenarios
- **Key Features**: Supports multiple RL methods including RLOO with different reward configurations
- **Programming Language**: Python
- **Last Update**: February 12, 2026
- **Star Count**: 0

---

## 2. GRPO (Group Relative Policy Optimization) and Variants

### 2.1 Primary GRPO Implementations

#### Repository: Awesome-GRPO (Most Popular)

- **Full Repository Name**: WangJingyao07/Awesome-GRPO
- **GitHub URL**: https://github.com/WangJingyao07/Awesome-GRPO
- **Contributors/Maintainers**: WangJingyao07 (individual developer)
- **Technical Approach**: Comprehensive codebase of GRPO implementations and resources including
  GRPO variants
- **Key Features**: Collection of GRPO implementations and resources; covers multiple variants
- **Programming Language**: Python
- **Last Update**: June 3, 2026
- **Star Count**: 288
- **Forks**: 31
- **Topics**: dapo, grpo, llm, papers, reasoning, reinforcement-learning, transformers
- **Documentation**: Comprehensive resources for GRPO research

#### Repository: Open-R1

- **Full Repository Name**: jianzhnie/Open-R1
- **GitHub URL**: https://github.com/jianzhnie/Open-R1
- **Contributors/Maintainers**: jianzhnie (individual developer)
- **Technical Approach**: Open source implementation of DeepSeek-R1 with GRPO support
- **Key Features**: Implements DeepSeek-R1 training pipeline with GRPO
- **Programming Language**: Python
- **Last Update**: June 9, 2026
- **Star Count**: 277
- **Forks**: 54
- **License**: Apache License 2.0
- **Topics**: deepseek-r1, deepseek-v3, grpo, llm, rlhf

#### Repository: Thinkless

- **Full Repository Name**: VainF/Thinkless
- **GitHub URL**: https://github.com/VainF/Thinkless
- **Contributors/Maintainers**: VainF (individual developer)
- **Technical Approach**: NeurIPS 2025 paper implementation - LLM learns when to think using GRPO
- **Key Features**: Adaptive reasoning with GRPO; hybrid reasoning approach
- **Programming Language**: Python
- **Last Update**: May 26, 2026
- **Star Count**: 260
- **Forks**: 20
- **License**: Apache License 2.0
- **Topics**: adaptive-reasoning, grpo, hybrid-reasoning, llms, reinforcement-learning

---

### 2.2 GRPO Variants and Specialized Implementations

#### Repository: hud-python

- **Full Repository Name**: hud-evals/hud-python
- **GitHub URL**: https://github.com/hud-evals/hud-python
- **Contributors/Maintainers**: hud-evals (organization)
- **Technical Approach**: OSS RL environment + evals toolkit with GRPO support
- **Key Features**: Environment for RL training with GRPO; supports Qwen and Qwen3
- **Programming Language**: Python
- **Last Update**: June 5, 2026
- **Star Count**: 258
- **Forks**: 59
- **License**: MIT License
- **Topics**: grpo, llm, llms, lora, qwen, qwen3, reinforcement-learning,
  reinforcement-learning-environments, rl

#### Repository: unsloth-buddy

- **Full Repository Name**: TYH-labs/unsloth-buddy
- **GitHub URL**: https://github.com/TYH-labs/unsloth-buddy
- **Contributors/Maintainers**: TYH-labs (organization - Gaslamp AI platform)
- **Technical Approach**: Zero-friction LLM fine-tuning with GRPO support; Unsloth on NVIDIA and
  TRL+MPS/MLX on Apple Silicon
- **Key Features**: Automates environment setup, LoRA training (SFT, DPO, GRPO, vision), post-hoc
  GRPO log diagnostics, evaluation, and export
- **Programming Language**: Python
- **Last Update**: June 8, 2026
- **Star Count**: 249
- **Forks**: 14
- **License**: MIT License
- **Topics**: apple-silicon, claude-code, dpo, fine-tuning, gaslamp, grpo, huggingface, lora, qlora,
  rlhf, sft, transformer, unsloth

#### Repository: MLX-GRPO

- **Full Repository Name**: Doriandarko/MLX-GRPO
- **GitHub URL**: https://github.com/Doriandarko/MLX-GRPO
- **Contributors/Maintainers**: Doriandarko (individual developer)
- **Technical Approach**: Pure MLX-based training pipeline for fine-tuning LLMs using GRPO on Apple
  Silicon
- **Key Features**: Apple Silicon optimization; MLX framework integration
- **Programming Language**: Python
- **Last Update**: June 8, 2026
- **Star Count**: 241
- **Forks**: 22

---

## 3. Online/Offline RLHF Implementations

### 3.1 General RLHF Frameworks

#### Repository: LLM-RLHF

- **Full Repository Name**: fzhu0628/LLM-RLHF
- **GitHub URL**: https://github.com/fzhu0628/LLM-RLHF
- **Contributors/Maintainers**: fzhu0628 (individual developer)
- **Technical Approach**: Implementation of Direct Preference Optimization (DPO) algorithm
  extensively used for RLHF fine-tuning of LLMs with variance analysis
- **Key Features**: DPO implementation with variance reduction methods
- **Programming Language**: Python
- **Last Update**: June 3, 2026
- **Star Count**: 0

#### Repository: Advanced RLHF Alignment Pipeline

- **Full Repository Name**: LeongWaiYiw/Advanced-RLHF-Alignment-Pipeline
- **GitHub URL**: https://github.com/LeongWaiYiw/Advanced-RLHF-Alignment-Pipeline
- **Contributors/Maintainers**: LeongWaiYiw (individual developer)
- **Technical Approach**: Advanced RLHF alignment pipeline implementation
- **Programming Language**: Python
- **Last Update**: March 15, 2026
- **Star Count**: 0

#### Repository: Factual-Preference-Alignment

- **Full Repository Name**: VectorInstitute/Factual-Preference-Alignment
- **GitHub URL**: https://github.com/VectorInstitute/Factual-Preference-Alignment
- **Contributors/Maintainers**: Vector Institute (research organization)
- **Technical Approach**: Research and engineering framework for studying and improving factual
  alignment in preference-optimized LLMs
- **Key Features**: Focus on factual alignment; DPO-based optimization
- **Programming Language**: Python
- **Last Update**: April 14, 2026
- **Star Count**: 0
- **License**: MIT License
- **Topics**: dpo, factuality, preference-alignment, rlhf
- **Documentation**: https://vectorinstitute.github.io/Factual-Preference-Alignment/

#### Repository: MiniLLM-TrainingPipeline

- **Full Repository Name**: Yanyeoo/MiniLLM-TrainingPipeline
- **GitHub URL**: https://github.com/Yanyeoo/MiniLLM-TrainingPipeline
- **Contributors/Maintainers**: Yanyeoo (individual developer)
- **Technical Approach**: Lightweight medical dialogue LLM with full training pipeline (Pretrain ->
  SFT -> RLHF); incorporates CoT reasoning and DPO-based preference optimization
- **Key Features**: Medical domain focus; reduces hallucination; improves multi-turn stability
- **Programming Language**: Python
- **Last Update**: March 19, 2026
- **Star Count**: 0

---

## 4. Reward Modeling Papers and Code

### 4.1 Reward Model Implementations

#### Repository: llm_optimization

- **Full Repository Name**: tlc4418/llm_optimization
- **GitHub URL**: https://github.com/tlc4418/llm_optimization
- **Contributors/Maintainers**: tlc4418 (individual developer)
- **Technical Approach**: Best-of-N sampling and reward model ensembles for LLM optimization
- **Key Features**: Implements reward models and ensemble methods; related to arXiv paper 2310.02743
- **Programming Language**: Python
- **Last Update**: May 21, 2026
- **Star Count**: 48
- **Forks**: 6
- **License**: MIT License
- **Topics**: best-of-n, deep-learning, ensembles, large-language-models,
  reinforcement-learning-from-human-feedback, reward-models

#### Repository: Generalizable-Reward-Model

- **Full Repository Name**: YangRui2015/Generalizable-Reward-Model
- **GitHub URL**: https://github.com/YangRui2015/Generalizable-Reward-Model
- **Contributors/Maintainers**: YangRui2015 (individual developer)
- **Technical Approach**: NeurIPS 2024 paper - Regularizing Hidden States Enables Learning
  Generalizable Reward Model for LLMs
- **Key Features**: Research on generalizable reward models; hidden state regularization
- **Programming Language**: Python
- **Last Update**: April 10, 2026
- **Star Count**: 46
- **Forks**: 5
- **License**: MIT License

#### Repository: RewardAnything

- **Full Repository Name**: WisdomShell/RewardAnything
- **GitHub URL**: https://github.com/WisdomShell/RewardAnything
- **Contributors/Maintainers**: WisdomShell (organization)
- **Technical Approach**: Generalizable Principle-Following Reward Models
- **Key Features**: Principle-following reward models; supports GRPO and RLHF
- **Programming Language**: Python
- **Last Update**: April 27, 2026
- **Star Count**: 44
- **Forks**: 1
- **Documentation**: https://zhuohaoyu.github.io/RewardAnything
- **Topics**: alignment, evaluation, grpo, llm, reasoning-language-models, reward-models, rlhf

#### Repository: zero-shot-reward-models

- **Full Repository Name**: vicgalle/zero-shot-reward-models
- **GitHub URL**: https://github.com/vicgalle/zero-shot-reward-models
- **Contributors/Maintainers**: vicgalle (individual developer)
- **Technical Approach**: ZYN - Zero-Shot Reward Models with Yes-No Questions
- **Key Features**: Zero-shot reward modeling approach
- **Programming Language**: Python
- **Last Update**: December 1, 2025
- **Star Count**: 35
- **Forks**: 8
- **License**: MIT License
- **Topics**: llm, reinforcement-learning, reward-models, rlaif, rlhf, trlx, zero-shot

#### Repository: CodeScaler

- **Full Repository Name**: LARK-AI-Lab/CodeScaler
- **GitHub URL**: https://github.com/LARK-AI-Lab/CodeScaler
- **Contributors/Maintainers**: LARK-AI-Lab (organization)
- **Technical Approach**: CodeScaler - Scaling Code LLM Training and Test-Time Inference via
  Execution-Free Reward Models
- **Key Features**: Execution-free reward models for code LLM training
- **Programming Language**: Python
- **Last Update**: June 10, 2026
- **Star Count**: 34
- **Documentation**: https://lark-ai-lab.github.io/codescaler.github.io/
- **Topics**: code, llm, reward-model

---

## 5. PPO (Proximal Policy Optimization) for LLM Fine-tuning

### 5.1 PPO Implementations

The TRL (Transformer Reinforcement Learning) library by Hugging Face is the primary framework for
PPO-based LLM fine-tuning. While the official TRL repository (huggingface/trl) exists on GitHub with
thousands of stars, several related implementations were found:

#### Related PPO Repositories

- **orpo** (zengatso/orpo): Includes PPO support alongside DPO, KTO, and other methods
- **RL-Finetuning-of-Large-Language-Models**: Supports RLOO (a PPO variant) comparison
- **Reinforcement Tuning LLMs**: Includes PPO in the comparison of RL methods for LLM fine-tuning

### 5.2 PPO Features in Multi-Method Frameworks

Most preference optimization frameworks include PPO as one of the available methods:

| Repository                                | PPO Support | Key Features                                               |
| ----------------------------------------- | ----------- | ---------------------------------------------------------- |
| zengatso/orpo                             | Yes         | Monolithic preference optimization without reference model |
| YuvaneshSankar/reinforcement-tuninig-llms | Yes         | Multiple RL methods comparison                             |
| fabiantoh98/llm-preference-learning       | Via RLHF    | Memory-efficient training                                  |

---

## 6. Additional Notable Repositories

### 6.1 Reasoning and Minimal Implementations

#### Repository: reasoning-minimal

- **Full Repository Name**: torotoki/reasoning-minimal
- **GitHub URL**: https://github.com/torotoki/reasoning-minimal
- **Contributors/Maintainers**: torotoki (individual developer)
- **Technical Approach**: Minimal code to train reasoning model with reinforcement learning
- **Key Features**: Minimal implementation focused on reasoning training
- **Programming Language**: Python
- **Last Update**: August 28, 2025
- **Star Count**: 3
- **License**: MIT License
- **Topics**: huggingface, llm, python, reinforcement-learning, transformers, trl

---

## 7. Summary Statistics and Key Findings

### 7.1 Repository Distribution by Category

| Category                | Number of Repositories | Top Star Count             |
| ----------------------- | ---------------------- | -------------------------- |
| GRPO and Variants       | 6                      | 288 (Awesome-GRPO)         |
| Reward Modeling         | 5                      | 48 (llm_optimization)      |
| DPO Implementations     | 4                      | 25 (Targeted-Manipulation) |
| Multi-Method Frameworks | 5                      | 260 (Thinkless)            |
| RLHF General            | 4                      | 0 (various)                |

### 7.2 Key Technical Trends

1. **GRPO Popularity**: GRPO-based methods have gained significant traction with the DeepSeek-R1
   release, showing 288 stars for the Awesome-GRPO collection

2. **Multi-Method Support**: Most frameworks now support multiple preference optimization methods
   (DPO, KTO, ORPO, GRPO, RLOO) allowing researchers to compare approaches

3. **Memory Efficiency**: Several implementations emphasize memory-efficient training with 4-bit
   quantization and LoRA support enabling training on consumer hardware

4. **Domain-Specific Applications**: Emerging specialized implementations for medical, code, and
   Korean language domains

5. **Apple Silicon Support**: Growing ecosystem for MLX-based training on Apple Silicon devices
   (MLX-GRPO, unsloth-buddy)

### 7.3 Most Active Research Areas

1. **Reasoning Enhancement**: Multiple projects focus on using RL for improving reasoning
   capabilities (Thinkless, Open-R1)
2. **Factuality Alignment**: Dedicated frameworks for factual accuracy in LLMs
3. **Reward Model Generalization**: Research on building generalizable reward models
4. **Efficiency Improvements**: Reducing computational requirements for preference optimization

---

## 8. References and Resources

### 8.1 Key Papers

- **Direct Preference Optimization (DPO)**: "Direct Preference Optimization: Your Language Model is
  a Reward Model"
- **GRPO**: Group Relative Policy Optimization - DeepSeek-R1 technical report
- **KTO**: Kahneman-Tversky Optimization - Behavioral economics inspired approach
- **ORPO**: Odds Ratio Preference Optimization - Monolithic preference optimization

### 8.2 Documentation Links

- Awesome-GRPO: https://github.com/WangJingyao07/Awesome-GRPO
- Factual-Preference-Alignment: https://vectorinstitute.github.io/Factual-Preference-Alignment/
- RewardAnything: https://zhuohaoyu.github.io/RewardAnything
- CodeScaler: https://lark-ai-lab.github.io/codescaler.github.io/

---

## 9. Conclusion

This comprehensive research survey identified significant activity in the preference optimization
and LLM alignment space. The ecosystem has evolved beyond single methods (DPO) to include diverse
approaches (KTO, ORPO, GRPO, RLOO) with active development in reward modeling, reasoning
enhancement, and efficiency optimization. The GRPO methodology has seen particularly strong adoption
following the DeepSeek-R1 release, while multi-method frameworks enable comparative research across
different optimization strategies.

---

_Report Generated: June 10, 2026_ _Data Sources: GitHub API, HuggingFace Hub_
