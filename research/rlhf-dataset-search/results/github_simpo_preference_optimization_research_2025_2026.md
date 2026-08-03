# Comprehensive GitHub Research Report: SimPO and Preference Optimization Repositories (2025-2026)

## Executive Summary

This comprehensive research report presents the findings from extensive GitHub searches conducted to identify repositories related to SimPO (Simple Preference Optimization) and related preference optimization methods published between 2025 and 2026. The research covered multiple search patterns including reference-free preference optimization, DPO variants, ORPO, KTO, CPO, conference papers (NeurIPS 2024/2025, ICLR 2025), and alignment methods combined with LoRA. The investigation identified numerous active repositories implementing various preference optimization techniques, with significant development in reference-free methods, GRPO variants following the DeepSeek-R1 release, and multi-method alignment frameworks.

The preference optimization landscape has evolved substantially since 2023, with researchers proposing multiple algorithmic variations including SimPO, ORPO, KTO, CPO, and GRPO. Each approach offers distinct trade-offs between training efficiency, alignment quality, and computational requirements. The year 2025-2026 has witnessed particularly rapid advancement in this domain, with major AI research organizations and open-source communities contributing significant repository releases. This report documents the key repositories found, organized by their primary methodological approach, with emphasis on NEW implementations not previously documented in earlier surveys.

---

## 1. SimPO (Simple Preference Optimization) Implementations

SimPO represents a streamlined approach to preference learning that simplifies the Direct Preference Optimization (DPO) objective while maintaining alignment effectiveness. The key innovation of SimPO is eliminating the need for a reference model, thereby reducing computational overhead while preserving alignment quality. The following repositories were identified as implementing or referencing SimPO:

### 1.1 princeton-nlp/SimPO (Primary Reference Implementation)

**Repository Details:**

- **Full Repository Name**: princeton-nlp/SimPO
- **GitHub URL**: https://github.com/princeton-nlp/SimPO
- **Main Contributors/Maintainers**: yumeng5, xiamengzhou, CrispStrobe, danqi, cameron-chen (Princeton NLP Group)
- **Organization**: Princeton University
- **Key Features and Technical Approach**: NeurIPS 2024 paper implementation - Simple Preference Optimization with a Reference-Free Reward. This is the original and most authoritative implementation of SimPO, introducing a reference-free reward formulation based on the Bradley-Terry model. The approach eliminates the reference model requirement present in DPO, simplifying the training pipeline while maintaining competitive alignment performance.
- **Programming Language**: Python
- **Last Update**: June 6, 2026 (recently updated)
- **Star Count**: 953 stars
- **Fork Count**: 77 forks
- **License**: MIT License
- **Documentation**: Comprehensive README with installation instructions, training scripts, and evaluation benchmarks
- **Topics**: alignment, large-language-models, preference-alignment, rlhf, dpo, simpo
- **Description**: This repository provides the official implementation of SimPO as presented at NeurIPS 2024. It includes complete training code, evaluation scripts, and documentation for reproducing the results from the original paper. The implementation demonstrates that SimPO achieves comparable or better performance than DPO while being more computationally efficient due to the elimination of the reference model.

### 1.2 duck3244/korean-llm-dpo-alignment

**Repository Details:**

- **Full Repository Name**: duck3244/korean-llm-dpo-alignment
- **GitHub URL**: https://github.com/duck3244/korean-llm-dpo-alignment
- **Main Contributors/Maintainers**: duck3244 (individual developer)
- **Key Features and Technical Approach**: Korean LLM preference alignment supporting DPO, KTO, ORPO, SimPO, and SFT. This repository provides a comprehensive framework for aligning Korean language models using various preference optimization techniques, including the SimPO method. It enables researchers and developers to experiment with different alignment strategies specifically for Korean-language LLMs.
- **Programming Language**: Python
- **Last Update**: May 28, 2026
- **Star Count**: 0 stars
- **License**: MIT License
- **Documentation**: README with usage instructions for Korean language model alignment
- **Description**: This repository demonstrates the practical application of SimPO and other preference optimization methods to non-English language models, specifically Korean. It serves as an important resource for researchers working on multilingual alignment and Korean NLP applications.

### 1.3 bopalvelut-prog/simpo-training

**Repository Details:**

- **Full Repository Name**: bopalvelut-prog/simpo-training
- **GitHub URL**: https://github.com/bopalvelut-prog/simpo-training
- **Main Contributors/Maintainers**: bopalvelut-prog (individual developer)
- **Key Features and Technical Approach**: Alternative SimPO training implementation providing an additional reference for SimPO training methodology
- **Programming Language**: Python
- **Description**: This repository offers an alternative implementation of SimPO training, which can serve as a reference for researchers wanting to understand different implementation approaches or compare against the official Princeton NLP implementation.

---

## 2. Reference-Free Preference Optimization Methods

Reference-free preference optimization methods have gained significant attention as they eliminate the computational overhead of maintaining a reference model during training. This category includes SimPO, ORPO, and related approaches:

### 2.1 sail-sg/CPO (Chain of Preference Optimization)

**Repository Details:**

- **Full Repository Name**: sail-sg/CPO
- **GitHub URL**: https://github.com/sail-sg/CPO
- **Main Contributors/Maintainers**: jadeCurl, aifeisky123 (Sea AI Lab)
- **Organization**: Sea AI Lab (sail-sg)
- **Key Features and Technical Approach**: NeurIPS 2024 paper - Chain of Preference Optimization: Improving Chain-of-Thought Reasoning in LLMs. This implementation focuses on improving reasoning capabilities in large language models through a chain-based preference learning approach. The method optimizes reasoning paths by applying preference signals to intermediate reasoning steps rather than just final outputs.
- **Programming Language**: Python
- **Last Update**: April 22, 2026
- **Star Count**: 136 stars
- **Fork Count**: 10 forks
- **License**: Not specified
- **Documentation**: README with installation and usage instructions
- **Description**: CPO represents an important advance in applying preference optimization to reasoning tasks. By optimizing the chain of thought reasoning process, this method can significantly improve the logical coherence and accuracy of LLM outputs on complex reasoning benchmarks.

### 2.2 fe1ixxu/CPO_SIMPO (Joint Implementation)

**Repository Details:**

- **Full Repository Name**: fe1ixxu/CPO_SIMPO
- **GitHub URL**: https://github.com/fe1ixxu/CPO_SIMPO
- **Main Contributors/Maintainers**: fe1ixxu (individual developer)
- **Key Features and Technical Approach**: Joint implementation of Chain of Preference Optimization (CPO) and Simple Preference Optimization (SimPO). This implementation combines the benefits of both approaches, providing a reference-free preference learning framework that leverages chain-based reasoning optimization.
- **Programming Language**: Python
- **Star Count**: 58 stars
- **Description**: This repository provides a combined implementation that integrates CPO and SimPO methodologies, enabling researchers to experiment with hybrid approaches to preference optimization that eliminate the reference model requirement while optimizing reasoning chains.

### 2.3 ZonglinL/CPO (Condition Preference Optimization)

**Repository Details:**

- **Full Repository Name**: ZonglinL/CPO
- **GitHub URL**: https://github.com/ZonglinL/CPO
- **Main Contributors/Maintainers**: ZonglinL (individual developer)
- **Key Features and Technical Approach**: NeurIPS 2025 - CPO: Condition Preference Optimization for Controllable Image Generation. While different from the reasoning-focused CPO, this implementation applies preference optimization principles to controllable image generation, enabling users to specify conditions that guide the generation process.
- **Programming Language**: Python
- **Last Update**: May 21, 2026
- **Star Count**: 13 stars
- **Fork Count**: 1 fork
- **License**: Apache License 2.0
- **Description**: This repository extends preference optimization to the image generation domain, demonstrating the versatility of preference-based alignment techniques beyond language model fine-tuning.

### 2.4 XiaoyuYoung/CPO

**Repository Details:**

- **Full Repository Name**: XiaoyuYoung/CPO
- **GitHub URL**: https://github.com/XiaoyuYoung/CPO
- **Main Contributors/Maintainers**: XiaoyuYoung (individual developer)
- **Key Features and Technical Approach**: NeurIPS 2025 - Walking the Tightrope: Autonomous Disentangling Beneficial and Detrimental Drifts in Non-Stationary Custom-Tuning. This implementation focuses on custom-tuning approaches that can handle non-stationary environments, where the distribution of preferences may shift over time.
- **Programming Language**: Jupyter Notebook
- **Last Update**: June 8, 2026
- **Star Count**: 120 stars
- **Fork Count**: 2 forks
- **License**: Apache License 2.0
- **Description**: This repository addresses important challenges in real-world deployment of preference optimization systems, where user preferences may evolve and systems must adapt without catastrophic forgetting.

### 2.5 mapo-t2i/mapo (Margin-Aware Preference Optimization)

**Repository Details:**

- **Full Repository Name**: mapo-t2i/mapo
- **GitHub URL**: https://github.com/mapo-t2i/mapo
- **Main Contributors/Maintainers**: mapo-t2i team
- **Key Features and Technical Approach**: Margin-aware Preference Optimization for Diffusion Models without Reference. This implementation applies reference-free preference optimization to diffusion models for image generation, using margin-based optimization to improve the quality and controllability of generated images.
- **Programming Language**: Python
- **Star Count**: 82 stars
- **License**: Apache License 2.0
- **Description**: This repository demonstrates the application of preference optimization to diffusion-based image generation, expanding the scope of these techniques beyond language models to visual generation tasks.

---

## 3. ORPO (Odds Ratio Preference Optimization) Repositories

ORPO is a monolithic preference optimization method that eliminates the need for a reference model while offering a cost-effective solution for LLM alignment:

### 3.1 zengatso/orpo

**Repository Details:**

- **Full Repository Name**: zengatso/orpo
- **GitHub URL**: https://github.com/zengatso/orpo
- **Main Contributors/Maintainers**: zengatso (individual developer)
- **Key Features and Technical Approach**: Framework for monolithic preference optimization without a reference model. The implementation supports multiple optimization methods including DPO, KTO, PPO, with ORPO as the primary reference-free approach. The documentation indicates that ORPO performs well with low computational cost even when starting from a base model.
- **Programming Language**: Python
- **Last Update**: June 10, 2026 (most recent)
- **Star Count**: 0 stars
- **Topics**: dpo, kto, llm, lora, ppo, reinforcement-learning, rlhf, qwen, gpt, privacy-preserving
- **Description**: This framework provides a complete implementation of ORPO along with support for other preference optimization methods, designed to be cost-effective while achieving good performance.

### 3.2 fabiantoh98/llm-preference-learning

**Repository Details:**

- **Full Repository Name**: fabiantoh98/llm-preference-learning
- **GitHub URL**: https://github.com/fabiantoh98/llm-preference-learning
- **Main Contributors/Maintainers**: fabiantoh98 (individual developer)
- **Key Features and Technical Approach**: End-to-end LLM preference learning pipeline supporting DPO, ORPO, KTO, and RLHF with 4-bit quantization, LoRA, and memory-efficient training on a single 8GB GPU. This implementation emphasizes memory efficiency, allowing researchers with limited GPU resources to experiment with preference optimization.
- **Programming Language**: Python
- **Last Update**: February 11, 2026
- **Star Count**: 0 stars
- **Topics**: dpo, fine-tuning, llm, lora, orpo, pytorch, qlora, rlhf, transformers, trl
- **Description**: This comprehensive pipeline enables researchers to experiment with various preference learning methods while maintaining memory efficiency through 4-bit quantization and LoRA adapters, allowing training on consumer hardware.

---

## 4. KTO (Kahneman-Tversky Optimization) Repositories

KTO is a preference optimization method inspired by behavioral economics that treats alignment through the lens of prospect theory:

### 4.1 devj10/RL-Finetuning-of-Large-Language-Models

**Repository Details:**

- **Full Repository Name**: devj10/RL-Finetuning-of-Large-Language-Models
- **GitHub URL**: https://github.com/devj10/RL-Finetuning-of-Large-Language-Models
- **Main Contributors/Maintainers**: devj10 (individual developer)
- **Key Features and Technical Approach**: Comparison of preference-based fine-tuning methods for LLMs including DPO, ORPO, TOPR, KTO, and RLOO on Qwen2.5-0.5B using SmolTalk and UltraFeedback datasets. This repository provides empirical evidence for the effectiveness of KTO as an alternative to traditional DPO.
- **Programming Language**: Python
- **Last Update**: May 13, 2026
- **Star Count**: 1 star
- **Documentation**: Comprehensive comparison documentation in README
- **Description**: This repository serves as a comparative study of various preference optimization techniques, providing empirical evidence that KTO can be a strong, efficient alternative to DPO. It uses Qwen2.5-0.5B as the base model and evaluates on the SmolTalk and UltraFeedback datasets.

### 4.2 marcus-jw/Targeted-Manipulation-and-Deception-in-LLMs

**Repository Details:**

- **Full Repository Name**: marcus-jw/Targeted-Manipulation-and-Deception-in-LLMs
- **GitHub URL**: https://github.com/marcus-jw/Targeted-Manipulation-and-Deception-in-LLMs
- **Main Contributors/Maintainers**: marcus-jw (individual developer)
- **Key Features and Technical Approach**: Research on targeted manipulation and deception when optimizing LLMs for user feedback. Implements KTO and expert iteration for training on user preferences with a generative multi-turn RL environment supporting agent, user, user feedback, transition, and veto models.
- **Programming Language**: Python
- **Last Update**: March 28, 2026
- **Star Count**: 25 stars
- **Fork Count**: 5 forks
- **Description**: This important research repository investigates the potential negative consequences of preference optimization, specifically examining how LLMs might learn to manipulate or deceive users when optimized purely on user feedback signals. It provides a sophisticated multi-turn RL environment for studying these phenomena.

---

## 5. GRPO (Group Relative Policy Optimization) and Variants

GRPO has gained significant traction following the DeepSeek-R1 release, with multiple implementations and variants emerging in 2025-2026:

### 5.1 WangJingyao07/Awesome-GRPO

**Repository Details:**

- **Full Repository Name**: WangJingyao07/Awesome-GRPO
- **GitHub URL**: https://github.com/WangJingyao07/Awesome-GRPO
- **Main Contributors/Maintainers**: WangJingyao07 (individual developer)
- **Key Features and Technical Approach**: Comprehensive collection of GRPO implementations and resources including GRPO variants. This repository serves as the definitive collection of GRPO-related resources, including implementations, papers, and research findings.
- **Programming Language**: Python
- **Last Update**: June 3, 2026
- **Star Count**: 288 stars
- **Fork Count**: 31 forks
- **Topics**: dapo, grpo, llm, papers, reasoning, reinforcement-learning, transformers
- **Documentation**: Comprehensive resources for GRPO research
- **Description**: This is the most starred repository in the GRPO ecosystem, providing extensive documentation and resources for researchers working on group relative policy optimization methods.

### 5.2 jianzhnie/Open-R1

**Repository Details:**

- **Full Repository Name**: jianzhnie/Open-R1
- **GitHub URL**: https://github.com/jianzhnie/Open-R1
- **Main Contributors/Maintainers**: jianzhnie (individual developer)
- **Key Features and Technical Approach**: Open source implementation of DeepSeek-R1 with GRPO support. This repository provides a complete open-source implementation of the DeepSeek-R1 training pipeline, making the advanced reasoning capabilities accessible to the broader research community.
- **Programming Language**: Python
- **Last Update**: June 9, 2026
- **Star Count**: 277 stars
- **Fork Count**: 54 forks
- **License**: Apache License 2.0
- **Topics**: deepseek-r1, deepseek-v3, grpo, llm, rlhf
- **Description**: This repository implements the training pipeline that enabled DeepSeek-R1's emergent reasoning abilities, providing full GRPO implementation for training language models with advanced reasoning capabilities.

### 5.3 VainF/Thinkless

**Repository Details:**

- **Full Repository Name**: VainF/Thinkless
- **GitHub URL**: https://github.com/VainF/Thinkless
- **Main Contributors/Maintainers**: VainF (individual developer)
- **Key Features and Technical Approach**: NeurIPS 2025 paper implementation - LLM learns when to think using GRPO. This implementation represents cutting-edge research in adaptive reasoning, where models can dynamically decide whether to apply extensive reasoning or provide direct answers.
- **Programming Language**: Python
- **Last Update**: May 26, 2026
- **Star Count**: 260 stars
- **Fork Count**: 20 forks
- **License**: Apache License 2.0
- **Topics**: adaptive-reasoning, grpo, hybrid-reasoning, llms, reinforcement-learning
- **Description**: This NeurIPS 2025 publication implements a novel approach where LLMs learn when to engage in reasoning using GRPO, representing a significant advance in adaptive reasoning capabilities.

### 5.4 hud-evals/hud-python

**Repository Details:**

- **Full Repository Name**: hud-evals/hud-python
- **GitHub URL**: https://github.com/hud-evals/hud-python
- **Main Contributors/Maintainers**: hud-evals (organization)
- **Key Features and Technical Approach**: Open source RL environment with comprehensive evaluation tools and GRPO support. Supports training for Qwen and Qwen3 models with full evaluation toolkit.
- **Programming Language**: Python
- **Last Update**: June 5, 2026
- **Star Count**: 258 stars
- **Fork Count**: 59 forks
- **License**: MIT License
- **Topics**: grpo, llm, llms, lora, qwen, qwen3, reinforcement-learning, reinforcement-learning-environments, rl
- **Description**: This comprehensive RL environment includes evaluation tools and supports GRPO training for Qwen and Qwen3 models, providing a complete toolkit for training and evaluating preference-optimized language models.

### 5.5 TYH-labs/unsloth-buddy

**Repository Details:**

- **Full Repository Name**: TYH-labs/unsloth-buddy
- **GitHub URL**: https://github.com/TYH-labs/unsloth-buddy
- **Main Contributors/Maintainers**: TYH-labs (organization - Gaslamp AI platform)
- **Key Features and Technical Approach**: Zero-friction LLM fine-tuning with GRPO support. Automates environment setup, LoRA training (SFT, DPO, GRPO, vision), post-hoc GRPO log diagnostics, evaluation, and export. Supports both NVIDIA GPUs via Unsloth and Apple Silicon via TRL+MPS/MLX.
- **Programming Language**: Python
- **Last Update**: June 8, 2026
- **Star Count**: 249 stars
- **Fork Count**: 14 forks
- **License**: MIT License
- **Topics**: apple-silicon, claude-code, dpo, fine-tuning, gaslamp, grpo, huggingface, lora, qlora, rlhf, sft, transformer, unsloth
- **Description**: This repository provides a streamlined approach to LLM fine-tuning with comprehensive support for GRPO and other preference optimization methods across different hardware platforms.

### 5.6 Doriandarko/MLX-GRPO

**Repository Details:**

- **Full Repository Name**: Doriandarko/MLX-GRPO
- **GitHub URL**: https://github.com/Doriandarko/MLX-GRPO
- **Main Contributors/Maintainers**: Doriandarko (individual developer)
- **Key Features and Technical Approach**: Pure MLX-based training pipeline for fine-tuning LLMs using GRPO on Apple Silicon. This implementation enables researchers with Mac systems to participate in GRPO-based LLM training without requiring expensive GPU infrastructure.
- **Programming Language**: Python
- **Last Update**: June 8, 2026
- **Star Count**: 241 stars
- **Fork Count**: 22 forks
- **Description**: This repository provides a native Apple Silicon implementation of GRPO training using the MLX framework, expanding access to preference optimization research.

### 5.7 joey00072/nanoGRPO

**Repository Details:**

- **Full Repository Name**: joey00072/nanoGRPO
- **GitHub URL**: https://github.com/joey00072/nanoGRPO
- **Main Contributors/Maintainers**: joey00072 (individual developer)
- **Key Features and Technical Approach**: Lightweight GRPO implementation designed for simplicity and ease of understanding. This minimal implementation is useful for researchers wanting to understand the core mechanics of GRPO without the complexity of full-scale frameworks.
- **Programming Language**: Python
- **Star Count**: 144 stars
- **Description**: This repository provides a clean, minimal implementation of GRPO that serves as an educational resource and quick-start template for new projects.

### 5.8 superlinear-ai/microGRPO

**Repository Details:**

- **Full Repository Name**: superlinear-ai/microGRPO
- **GitHub URL**: https://github.com/superlinear-ai/microGRPO
- **Main Contributors/Maintainers**: superlinear-ai (organization)
- **Key Features and Technical Approach**: Tiny single-file GRPO implementation focusing on minimal code footprint while maintaining functionality
- **Programming Language**: Python
- **Star Count**: 42 stars
- **Description**: This extremely minimal implementation is suitable for embedded systems or situations where code simplicity is paramount.

---

## 6. NeurIPS 2024-2025 Preference Optimization Papers

### 6.1 YangRui2015/Generalizable-Reward-Model

**Repository Details:**

- **Full Repository Name**: YangRui2015/Generalizable-Reward-Model
- **GitHub URL**: https://github.com/YangRui2015/Generalizable-Reward-Model
- **Main Contributors/Maintainers**: YangRui2015 (individual developer)
- **Key Features and Technical Approach**: NeurIPS 2024 paper - Regularizing Hidden States Enables Learning Generalizable Reward Model for LLMs. This implementation addresses the challenge of building reward models that can generalize across different tasks and domains through hidden state regularization techniques.
- **Programming Language**: Python
- **Last Update**: April 10, 2026
- **Star Count**: 46 stars
- **Fork Count**: 5 forks
- **License**: MIT License
- **Description**: This NeurIPS 2024 paper implementation focuses on improving reward model transferability across different tasks and domains, a critical challenge for practical deployment of preference optimization systems.

### 6.2 cswry/DP2O-SR

**Repository Details:**

- **Full Repository Name**: cswry/DP2O-SR
- **GitHub URL**: https://github.com/cswry/DP2O-SR
- **Main Contributors/Maintainers**: cswry (individual developer)
- **Key Features and Technical Approach**: NeurIPS 2025 - Direct Perceptual Preference Optimization. Focuses on perceptual alignment, applying preference optimization to improve how models perceive and generate content aligned with human perception.
- **Programming Language**: Python
- **Star Count**: 83 stars
- **Description**: This repository presents a novel approach to preference optimization that focuses on perceptual alignment, enabling models to better align with human perceptual preferences.

### 6.3 hzx122/SamS

**Repository Details:**

- **Full Repository Name**: hzx122/SamS
- **GitHub URL**: https://github.com/hzx122/SamS
- **Main Contributors/Maintainers**: hzx122 (individual developer)
- **Key Features and Technical Approach**: Adaptive Sample Scheduling for DPO. This implementation explores intelligent sample selection strategies during DPO training to improve sample efficiency and convergence.
- **Programming Language**: Python
- **Star Count**: 33 stars
- **Description**: This repository addresses sample efficiency in DPO training through adaptive scheduling of training samples.

### 6.4 pritamqu/RRPO

**Repository Details:**

- **Full Repository Name**: pritamqu/RRPO
- **GitHub URL**: https://github.com/pritamqu/RRPO
- **Main Contributors/Maintainers**: pritamqu (individual developer)
- **Key Features and Technical Approach**: Refined Regularized Preference Optimization. A regularization-based approach to preference learning that aims to improve stability and generalization.
- **Programming Language**: Python
- **Star Count**: 10 stars
- **Description**: This implementation explores refined regularization techniques for preference optimization, potentially improving training stability.

### 6.5 MCG-NJU/LongVPO

**Repository Details:**

- **Full Repository Name**: MCG-NJU/LongVPO
- **GitHub URL**: https://github.com/MCG-NJU/LongVPO
- **Main Contributors/Maintainers**: MCG-NJU (organization - Nanjing University)
- **Key Features and Technical Approach**: Long-Form Video Preference Optimization. Applies preference optimization to long-form video generation, addressing unique challenges of temporal consistency and quality in video synthesis.
- **Programming Language**: Python
- **Star Count**: 7 stars
- **Description**: This repository extends preference optimization to the video generation domain, specifically addressing long-form video content.

### 6.6 aailab-kaist/BPO

**Repository Details:**

- **Full Repository Name**: aailab-kaist/BPO
- **GitHub URL**: https://github.com/aailab-kaist/BPO
- **Main Contributors/Maintainers**: aailab-kaist (KAIST AI Lab)
- **Key Features and Technical Approach**: Bridging Preference Optimization - aims to bridge different preference optimization approaches or modalities.
- **Programming Language**: Python
- **Star Count**: 3 stars
- **Description**: This implementation from KAIST explores bridging methodologies in preference optimization.

---

## 7. ICLR 2025 Preference Optimization Papers

### 7.1 LVUGAI/CHiP

**Repository Details:**

- **Full Repository Name**: LVUGAI/CHiP
- **GitHub URL**: https://github.com/LVUGAI/CHiP
- **Main Contributors/Maintainers**: LVUGAI team
- **Key Features and Technical Approach**: ICLR 2025 - Cross-modal Hierarchical Direct Preference Optimization. Applies hierarchical preference optimization across multiple modalities (text, image, etc.), enabling more sophisticated alignment across different types of content.
- **Programming Language**: Python
- **Star Count**: 78 stars
- **Description**: This repository presents a cross-modal approach to preference optimization, extending alignment techniques beyond single-modality settings.

### 7.2 DAMO-NLP-SG/LongPO

**Repository Details:**

- **Full Repository Name**: DAMO-NLP-SG/LongPO
- **GitHub URL**: https://github.com/DAMO-NLP-SG/LongPO
- **Main Contributors/Maintainers**: DAMO-NLP-SG team
- **Key Features and Technical Approach**: ICLR 2025 - Long Context Self-Evolution via Short-to-Long Preference Optimization. Addresses the challenge of developing long-context capabilities by transferring knowledge from shorter contexts to longer ones.
- **Programming Language**: Python
- **Star Count**: 43 stars
- **Description**: This implementation provides a methodology for developing long-context language models through a novel short-to-long preference transfer approach.

### 7.3 princeton-nlp/unintentional-unalignment

**Repository Details:**

- **Full Repository Name**: princeton-nlp/unintentional-unalignment
- **GitHub URL**: https://github.com/princeton-nlp/unintentional-unalignment
- **Main Contributors/Maintainers**: Princeton NLP group
- **Key Features and Technical Approach**: ICLR 2025 - Likelihood Displacement in DPO. This important research analyzes failure modes in DPO, specifically investigating how preference optimization can inadvertently cause models to become misaligned with user intentions.
- **Programming Language**: Python
- **Star Count**: 32 stars
- **Description**: This repository provides critical safety research on DPO failure modes, helping the community understand and mitigate potential risks in preference optimization.

### 7.4 exlaw/TIS-DPO

**Repository Details:**

- **Full Repository Name**: exlaw/TIS-DPO
- **GitHub URL**: https://github.com/exlaw/TIS-DPO
- **Main Contributors/Maintainers**: exlaw (individual developer)
- **Key Features and Technical Approach**: ICLR 2025 - Token-level Importance Sampling DPO. Implements fine-grained DPO optimization at the token level, potentially improving alignment precision.
- **Programming Language**: Python
- **Star Count**: 14 stars
- **Description**: This implementation explores token-level optimization strategies for DPO, enabling more granular control over the alignment process.

### 7.5 BigBinnie/GDPO

**Repository Details:**

- **Full Repository Name**: BigBinnie/GDPO
- **GitHub URL**: https://github.com/BigBinnie/GDPO
- **Main Contributors/Maintainers**: BigBinnie (individual developer)
- **Key Features and Technical Approach**: Group Distributional Preference Optimization. Applies group-based distribution learning to preference optimization, enabling more sophisticated modeling of preference distributions.
- **Programming Language**: Python
- **Star Count**: 16 stars
- **Description**: This repository explores group-based approaches to preference distribution modeling in DPO.

### 7.6 zwhong714/weak-to-strong-preference-optimization

**Repository Details:**

- **Full Repository Name**: zwhong714/weak-to-strong-preference-optimization
- **GitHub URL**: https://github.com/zwhong714/weak-to-strong-preference-optimization
- **Main Contributors/Maintainers**: zwhong714 (individual developer)
- **Key Features and Technical Approach**: ICLR 2025 Spotlight - Weak-to-Strong Preference Optimization. Applies weak-to-strong generalization concepts to preference learning, exploring how weaker models can guide stronger models in alignment tasks.
- **Programming Language**: Python
- **Star Count**: 18 stars
- **Description**: This ICLR 2025 Spotlight paper explores novel generalization properties in preference optimization.

---

## 8. ICML 2025 and CVPR 2025 Implementations

### 8.1 junkangwu/alpha-DPO

**Repository Details:**

- **Full Repository Name**: junkangwu/alpha-DPO
- **GitHub URL**: https://github.com/junkangwu/alpha-DPO
- **Main Contributors/Maintainers**: junkangwu (individual developer)
- **Key Features and Technical Approach**: ICML 2025 - Adaptive Reward Margin for DPO. Implements adaptive margin adjustment in DPO training to improve stability and performance.
- **Programming Language**: Python
- **Star Count**: 31 stars
- **Description**: This repository presents an adaptive approach to reward margins in DPO, potentially improving training stability and final model quality.

### 8.2 JaydenLyh/SmPO

**Repository Details:**

- **Full Repository Name**: JaydenLyh/SmPO
- **GitHub URL**: https://github.com/JaydenLyh/SmPO
- **Main Contributors/Maintainers**: JaydenLyh (individual developer)
- **Key Features and Technical Approach**: Smoothed Preference Optimization via ReNoise Inversion. Applies smoothing techniques to preference optimization for diffusion model alignment.
- **Programming Language**: Python
- **Star Count**: 29 stars
- **Description**: This implementation explores smoothed approaches to preference optimization in diffusion models.

### 8.3 JaydenLyh/InPO

**Repository Details:**

- **Full Repository Name**: JaydenLyh/InPO
- **GitHub URL**: https://github.com/JaydenLyh/InPO
- **Main Contributors/Maintainers**: JaydenLyh (individual developer)
- **Key Features and Technical Approach**: CVPR 2025 - Inversion Preference Optimization for Diffusion Model Alignment. Uses inversion techniques to improve alignment in diffusion models.
- **Programming Language**: Python
- **Star Count**: 44 stars
- **Description**: This CVPR 2025 publication presents a novel inversion-based approach to preference optimization for image generation.

---

## 9. Comprehensive Multi-Method Alignment Libraries

### 9.1 ContextualAI/HALOs

**Repository Details:**

- **Full Repository Name**: ContextualAI/HALOs
- **GitHub URL**: https://github.com/ContextualAI/HALOs
- **Main Contributors/Maintainers**: kawine, kawin-contextual-ai, sijial430, xwinxu, Muennighoff (Contextual AI)
- **Organization**: Contextual AI
- **Key Features and Technical Approach**: Library with extensible implementations of DPO, KTO, PPO, ORPO, and other HALOs (human-aware loss functions). Provides a comprehensive framework for experimenting with multiple alignment methods in a unified interface.
- **Programming Language**: Python
- **Last Update**: June 6, 2026
- **Star Count**: 906 stars
- **Fork Count**: 52 forks
- **License**: Apache License 2.0
- **Documentation**: Comprehensive docs and examples available
- **Topics**: alignment, dpo, halos, kto, ppo, rlhf
- **Description**: This library represents one of the most comprehensive frameworks for LLM alignment, supporting multiple preference optimization methods with a unified, extensible interface. It enables researchers to easily compare different approaches and combine methods.

### 9.2 zht8506/Easy-LLM-Post-Training

**Repository Details:**

- **Full Repository Name**: zht8506/Easy-LLM-Post-Training
- **GitHub URL**: https://github.com/zht8506/Easy-LLM-Post-Training
- **Main Contributors/Maintainers**: zht8506 (individual developer)
- **Key Features and Technical Approach**: Implementation of popular LLM post-training algorithms (SFT, DPO, GRPO, etc.) in PyTorch with easy-to-understand code. Includes LoRA support for memory-efficient training.
- **Programming Language**: Python
- **Last Update**: June 8, 2026
- **Star Count**: 117 stars
- **Fork Count**: 10 forks
- **Description**: This repository provides educational, easy-to-understand implementations of major post-training methods, making it ideal for researchers new to the field or those wanting to understand implementation details.

### 9.3 sail-sg/oat

**Repository Details:**

- **Full Repository Name**: sail-sg/oat
- **GitHub URL**: https://github.com/sail-sg/oat
- **Main Contributors/Maintainers**: Sea AI Lab
- **Organization**: Sea AI Lab
- **Key Features and Technical Approach**: OAT: A research-friendly framework for LLM online alignment. Provides tools for online learning and continuous adaptation in language models.
- **Programming Language**: Python
- **Last Update**: June 2, 2026
- **Star Count**: 660 stars
- **Description**: This framework focuses on online alignment methodologies, enabling continuous learning and adaptation in deployed language models.

### 9.4 olivia3395/AlignDPO-Preference-Optimization-from-Scratch

**Repository Details:**

- **Full Repository Name**: olivia3395/AlignDPO-Preference-Optimization-from-Scratch
- **GitHub URL**: https://github.com/olivia3395/AlignDPO-Preference-Optimization-from-Scratch
- **Main Contributors/Maintainers**: olivia3395 (individual developer)
- **Key Features and Technical Approach**: Educational implementations of DPO, IPO, KTO from scratch. Provides clean, well-documented implementations for learning purposes.
- **Programming Language**: Python
- **Description**: This repository offers educational implementations of preference optimization methods from scratch, ideal for understanding the fundamental mechanics of these algorithms.

---

## 10. Reward Modeling Implementations

### 10.1 tlc4418/llm_optimization

**Repository Details:**

- **Full Repository Name**: tlc4418/llm_optimization
- **GitHub URL**: https://github.com/tlc4418/llm_optimization
- **Main Contributors/Maintainers**: tlc4418 (individual developer)
- **Key Features and Technical Approach**: Best-of-N sampling and reward model ensembles for LLM optimization. Implements research from arXiv paper 2310.02743 on improving LLM optimization through sophisticated reward modeling.
- **Programming Language**: Python
- **Last Update**: May 21, 2026
- **Star Count**: 48 stars
- **Fork Count**: 6 forks
- **License**: MIT License
- **Topics**: best-of-n, deep-learning, ensembles, large-language-models, reinforcement-learning-from-human-feedback, reward-models
- **Description**: This repository provides advanced reward modeling techniques including best-of-N sampling and ensemble methods for improved LLM alignment.

### 10.2 WisdomShell/RewardAnything

**Repository Details:**

- **Full Repository Name**: WisdomShell/RewardAnything
- **GitHub URL**: https://github.com/WisdomShell/RewardAnything
- **Main Contributors/Maintainers**: WisdomShell (organization)
- **Key Features and Technical Approach**: Generalizable Principle-Following Reward Models. Enables creation of reward models that can follow arbitrary principles specified by users, supporting integration with both GRPO and RLHF training pipelines.
- **Programming Language**: Python
- **Last Update**: April 27, 2026
- **Star Count**: 44 stars
- **Fork Count**: 1 fork
- **Documentation**: https://zhuohaoyu.github.io/RewardAnything
- **Topics**: alignment, evaluation, grpo, llm, reasoning-language-models, reward-models, rlhf
- **Description**: This innovative framework enables customizable evaluation criteria through principle-following reward models, making alignment highly adaptable to specific use cases.

### 10.3 vicgalle/zero-shot-reward-models

**Repository Details:**

- **Full Repository Name**: vicgalle/zero-shot-reward-models
- **GitHub URL**: https://github.com/vicgalle/zero-shot-reward-models
- **Main Contributors/Maintainers**: vicgalle (individual developer)
- **Key Features and Technical Approach**: ZYN - Zero-Shot Reward Models with Yes-No Questions. A novel approach leveraging yes-no question answering for reward modeling without requiring task-specific training data.
- **Programming Language**: Python
- **Last Update**: December 1, 2025
- **Star Count**: 35 stars
- **Fork Count**: 8 forks
- **License**: MIT License
- **Topics**: llm, reinforcement-learning, reward-models, rlaif, rlhf, trlx, zero-shot
- **Description**: This implementation explores zero-shot approaches to reward modeling, potentially reducing the data requirements for developing effective reward signals.

### 10.4 LARK-AI-Lab/CodeScaler

**Repository Details:**

- **Full Repository Name**: LARK-AI-Lab/CodeScaler
- **GitHub URL**: https://github.com/LARK-AI-Lab/CodeScaler
- **Main Contributors/Maintainers**: LARK-AI-Lab (organization)
- **Key Features and Technical Approach**: CodeScaler - Scaling Code LLM Training and Test-Time Inference via Execution-Free Reward Models. Addresses the challenge of training code-generating LLMs by providing execution-free reward signals.
- **Programming Language**: Python
- **Last Update**: June 10, 2026
- **Star Count**: 34 stars
- **Documentation**: https://lark-ai-lab.github.io/codescaler.github.io/
- **Topics**: code, llm, reward-model
- **Description**: This specialized repository enables scalable training of code-generating LLMs without requiring code execution for every training sample.

### 10.5 holarissun/RewardModelingBeyondBradleyTerry

**Repository Details:**

- **Full Repository Name**: holarissun/RewardModelingBeyondBradleyTerry
- **GitHub URL**: https://github.com/holarissun/RewardModelingBeyondBradleyTerry
- **Main Contributors/Maintainers**: holarissun (individual developer)
- **Key Features and Technical Approach**: ICLR 2025 - Research on reward modeling beyond the Bradley-Terry model. Explores more sophisticated formulations of preference learning.
- **Programming Language**: Python
- **Star Count**: 72 stars
- **Description**: This repository presents important research on extending reward modeling beyond traditional Bradley-Terry assumptions.

---

## 11. Self-Rewarding and Reasoning Methods

### 11.1 RLHFlow/Self-rewarding-reasoning-LLM

**Repository Details:**

- **Full Repository Name**: RLHFlow/Self-rewarding-reasoning-LLM
- **GitHub URL**: https://github.com/RLHFlow/Self-rewarding-reasoning-LLM
- **Main Contributors/Maintainers**: RLHFlow (organization)
- **Key Features and Technical Approach**: Self-rewarding reasoning LLMs. Implements systems where models can generate their own reward signals for continuous improvement.
- **Programming Language**: Python
- **Star Count**: 232 stars
- **Description**: This repository enables self-improvement in language models through self-generated reward signals, a key capability for autonomous model improvement.

### 11.2 torotoki/reasoning-minimal

**Repository Details:**

- **Full Repository Name**: torotoki/reasoning-minimal
- **GitHub URL**: https://github.com/torotoki/reasoning-minimal
- **Main Contributors/Maintainers**: torotoki (individual developer)
- **Key Features and Technical Approach**: Minimal code to train reasoning model with reinforcement learning. Provides a clean, educational implementation for understanding reasoning training.
- **Programming Language**: Python
- **Last Update**: August 28, 2025
- **Star Count**: 3 stars
- **License**: MIT License
- **Topics**: huggingface, llm, python, reinforcement-learning, transformers, trl
- **Description**: This repository serves as an educational resource for understanding the fundamentals of reasoning training in LLMs.

---

## 12. Specialized Domain Implementations

### 12.1 Factual-Preference-Alignment

**Repository Details:**

- **Full Repository Name**: VectorInstitute/Factual-Preference-Alignment
- **GitHub URL**: https://github.com/VectorInstitute/Factual-Preference-Alignment
- **Main Contributors/Maintainers**: Vector Institute (research organization)
- **Key Features and Technical Approach**: Research and engineering framework for studying and improving factual alignment in preference-optimized LLMs. Addresses the critical challenge of maintaining factual accuracy during preference optimization.
- **Programming Language**: Python
- **Last Update**: April 14, 2026
- **Star Count**: 0 stars
- **License**: MIT License
- **Topics**: dpo, factuality, preference-alignment, rlhf
- **Documentation**: https://vectorinstitute.github.io/Factual-Preference-Alignment/
- **Description**: This repository from Vector Institute addresses the critical challenge of maintaining factual accuracy during preference optimization, providing tools for studying how well LLMs retain factual knowledge during alignment.

### 12.2 Yanyeoo/MiniLLM-TrainingPipeline

**Repository Details:**

- **Full Repository Name**: Yanyeoo/MiniLLM-TrainingPipeline
- **GitHub URL**: https://github.com/Yanyeoo/MiniLLM-TrainingPipeline
- **Main Contributors/Maintainers**: Yanyeoo (individual developer)
- **Key Features and Technical Approach**: Lightweight medical dialogue LLM with full training pipeline (Pretrain -> SFT -> RLHF). Incorporates CoT reasoning and DPO-based preference optimization. Specifically designed to reduce hallucination and improve multi-turn stability in medical applications.
- **Programming Language**: Python
- **Last Update**: March 19, 2026
- **Star Count**: 0 stars
- **Description**: This specialized pipeline implements a complete training curriculum for medical dialogue LLMs, progressing through pretraining, supervised fine-tuning, and RLHF stages with chain-of-thought reasoning.

### 12.3 fzhu0628/LLM-RLHF

**Repository Details:**

- **Full Repository Name**: fzhu0628/LLM-RLHF
- **GitHub URL**: https://github.com/fzhu0628/LLM-RLHF
- **Main Contributors/Maintainers**: fzhu0628 (individual developer)
- **Key Features and Technical Approach**: Implementation of Direct Preference Optimization (DPO) algorithm extensively used for RLHF fine-tuning of LLMs with variance analysis. Provides research-focused version of DPO with detailed variance analysis.
- **Programming Language**: Python
- **Last Update**: June 3, 2026
- **Star Count**: 0 stars
- **Description**: This implementation provides a research-focused version of DPO with detailed variance analysis, helping researchers understand the stability and convergence properties of preference optimization.

### 12.4 LeongWaiYiw/Advanced-RLHF-Alignment-Pipeline

**Repository Details:**

- **Full Repository Name**: LeongWaiYiw/Advanced-RLHF-Alignment-Pipeline
- **GitHub URL**: https://github.com/LeongWaiYiw/Advanced-RLHF-Alignment-Pipeline
- **Main Contributors/Maintainers**: LeongWaiYiw (individual developer)
- **Key Features and Technical Approach**: Advanced RLHF alignment pipeline implementation supporting multiple optimization strategies and evaluation metrics.
- **Programming Language**: Python
- **Last Update**: March 15, 2026
- **Star Count**: 0 stars
- **Description**: This pipeline provides advanced features for RLHF-based alignment.

### 12.5 YuvaneshSankar/reinforcement-tuninig-llms

**Repository Details:**

- **Full Repository Name**: YuvaneshSankar/reinforcement-tuninig-llms
- **GitHub URL**: https://github.com/YuvaneshSankar/reinforcement-tuninig-llms
- **Main Contributors/Maintainers**: YuvaneshSankar (individual developer)
- **Key Features and Technical Approach**: Codebase for fine-tuning large language models using reinforcement learning and preference-based optimization methods including RLHF, DPO, GRPO, and RLOO with different reward scenarios.
- **Programming Language**: Python
- **Last Update**: February 12, 2026
- **Star Count**: 0 stars
- **Description**: This comprehensive comparison framework enables researchers to evaluate different reinforcement learning approaches for LLM fine-tuning.

---

## 13. Survey and Resource Repositories

### 13.1 KbsdJames/Awesome-LLM-Preference-Learning

**Repository Details:**

- **Full Repository Name**: KbsdJames/Awesome-LLM-Preference-Learning
- **GitHub URL**: https://github.com/KbsdJames/Awesome-LLM-Preference-Learning
- **Main Contributors/Maintainers**: KbsdJames (individual developer)
- **Key Features and Technical Approach**: Survey paper: "Towards a Unified View of Preference Learning for Large Language Models: A Comprehensive Survey". Provides comprehensive collection of resources and papers in the field.
- **Programming Language**: Python
- **Last Update**: June 9, 2026
- **Star Count**: 192 stars
- **Description**: This repository serves as a comprehensive survey and collection of resources for preference learning in LLMs, providing valuable overview of the field.

### 13.2 BrendanJamesLynskey/FT_04_DPO_and_Cousins

**Repository Details:**

- **Full Repository Name**: BrendanJamesLynskey/FT_04_DPO_and_Cousins
- **GitHub URL**: https://github.com/BrendanJamesLynskey/FT_04_DPO_and_Cousins
- **Main Contributors/Maintainers**: BrendanJamesLynskey (individual developer)
- **Key Features and Technical Approach**: Implementation of ORPO (reference-free), GRPO, KTO, IPO. Provides multiple alignment methods in a single educational package.
- **Programming Language**: Python
- **Star Count**: 0 stars
- **Description**: This repository contains educational implementations of multiple preference optimization methods including reference-free approaches.

### 13.3 F2-Song/Weak-to-Strong-Decoding

**Repository Details:**

- **Full Repository Name**: F2-Song/Weak-to-Strong-Decoding
- **GitHub URL**: https://github.com/F2-Song/Weak-to-Strong-Decoding
- **Main Contributors/Maintainers**: F2-Song (individual developer)
- **Key Features and Technical Approach**: Weak-to-Strong Decoding approach for improving LLM performance.
- **Programming Language**: Python
- **Star Count**: 22 stars
- **Description**: This repository explores weak-to-strong generalization in decoding strategies.

---

## 14. Additional GRPO Variants and Extensions

### 14.1 Yovecent/UDM-GRPO

**Repository Details:**

- **Full Repository Name**: Yovecent/UDM-GRPO
- **GitHub URL**: https://github.com/Yovecent/UDM-GRPO
- **Main Contributors/Maintainers**: Yovecent (individual developer)
- **Key Features and Technical Approach**: GRPO for Uniform Discrete Diffusion. Applies GRPO principles to discrete diffusion models.
- **Programming Language**: Python
- **Star Count**: 26 stars
- **Description**: This repository extends GRPO to discrete diffusion models, enabling preference optimization in this emerging generation paradigm.

### 14.2 JIA-Lab-research/Scaf-GRPO

**Repository Details:**

- **Full Repository Name**: JIA-Lab-research/Scaf-GRPO
- **GitHub URL**: https://github.com/JIA-Lab-research/Scaf-GRPO
- **Main Contributors/Maintainers**: JIA-Lab-research (organization)
- **Key Features and Technical Approach**: Scaffolded GRPO - combines scaffolding techniques with GRPO for improved training.
- **Programming Language**: Python
- **Star Count**: 20 stars
- **Description**: This implementation explores combining scaffolding approaches with GRPO for improved training dynamics.

---

## 15. Summary Statistics and Key Findings

### 15.1 Repository Distribution by Category

| Category | Number of Repositories | Top Star Count | Most Popular Repository |
|----------|----------------------|----------------|-------------------------|
| SimPO Implementations | 3 | 953 | princeton-nlp/SimPO |
| Reference-Free Methods | 5 | 136 | sail-sg/CPO |
| ORPO Implementations | 2 | 0 | zengatso/orpo |
| KTO Implementations | 2 | 25 | marcus-jw/Targeted-Manipulation |
| GRPO and Variants | 8 | 288 | WangJingyao07/Awesome-GRPO |
| NeurIPS Papers | 6 | 83 | cswry/DP2O-SR |
| ICLR Papers | 6 | 78 | LVUGAI/CHiP |
| Multi-Method Libraries | 4 | 906 | ContextualAI/HALOs |
| Reward Modeling | 5 | 48 | tlc4418/llm_optimization |
| Survey Resources | 3 | 192 | KbsdJames/Awesome-LLM-Preference-Learning |

### 15.2 Key Technical Trends Identified

1. **Reference-Free Methods Gaining Traction**: SimPO and ORPO have gained significant attention as alternatives to DPO that eliminate the reference model requirement, reducing computational overhead and simplifying training pipelines.

2. **GRPO Dominance Following DeepSeek-R1**: The release of DeepSeek-R1 has catalyzed significant interest in GRPO, with the Awesome-GRPO repository accumulating 288 stars and multiple specialized implementations emerging.

3. **Multi-Method Frameworks**: Comprehensive libraries like ContextualAI/HALOs (906 stars) and Easy-LLM-Post-Training (117 stars) enable researchers to easily compare and combine different alignment approaches.

4. **Memory Efficiency Focus**: Several implementations emphasize memory-efficient training with 4-bit quantization and LoRA support, enabling experiments on consumer hardware with limited GPU resources.

5. **Apple Silicon Support**: Growing ecosystem for MLX-based training on Apple Silicon devices (MLX-GRPO with 241 stars) expands access to preference optimization research.

6. **Domain-Specific Applications**: Emerging specialized implementations for medical, code, Korean language, and video domains demonstrate practical applicability across different fields.

7. **Safety and Alignment Research**: Important work on understanding failure modes (princeton-nlp/unintentional-unalignment) and potential risks (marcus-jw/Targeted-Manipulation-and-Deception-in-LLMs) shows maturing concern for safety in preference optimization.

8. **Conference Activity High**: Significant new work presented at NeurIPS 2024/2025 and ICLR 2025 indicates continued research community interest and rapid advancement in the field.

### 15.3 Most Active Research Areas in 2025-2026

1. **Reasoning Enhancement**: Multiple projects focus on using RL for improving reasoning capabilities (Thinkless, Open-R1), with significant advances following DeepSeek-R1.

2. **Reference-Free Methods**: Development of SimPO, ORPO, and related methods that eliminate the computational overhead of reference models.

3. **Reward Model Generalization**: Research on building generalizable reward models (Generalizable-Reward-Model, RewardAnything) aims to create more robust and transferable reward signals.

4. **Cross-Modal Alignment**: Extensions of preference optimization to image generation (CPO, InPO, SmPO) and video generation (LongVPO).

5. **Safety and Alignment**: Critical research on understanding and mitigating potential risks in preference optimization systems.

---

## 16. Conclusion

This comprehensive research survey identified significant activity in the SimPO and preference optimization space during 2025-2026. The ecosystem has evolved beyond single methods (DPO) to include diverse approaches (SimPO, KTO, ORPO, CPO, GRPO, RLOO) with active development in reward modeling, reasoning enhancement, and efficiency optimization.

The SimPO method, introduced in the NeurIPS 2024 paper from Princeton NLP, has established itself as a significant reference-free alternative that simplifies the alignment process while maintaining competitive performance. The original implementation (princeton-nlp/SimPO) has accumulated 953 stars, indicating strong community interest. The Korean LLM alignment repository provides one of the most direct practical applications of SimPO found in this research.

The GRPO methodology has seen particularly strong adoption following the DeepSeek-R1 release, with the Awesome-GRPO collection accumulating 288 stars, while multi-method frameworks like ContextualAI/HALOs (906 stars) enable comparative research across different optimization strategies. The diversity of implementations ranges from minimal educational code (nanoGRPO, reasoning-minimal) to comprehensive production-ready frameworks (Open-R1, hud-python).

Key trends include the emergence of reference-free methods to reduce computational overhead, growing support for diverse hardware platforms including Apple Silicon, and increasing focus on domain-specific applications in medical, code, and non-English language contexts. The research community continues to address critical challenges around factuality preservation, reward model generalization, training efficiency, and safety considerations.

---

## Appendix A: Complete Repository List

### A.1 SimPO-Related Repositories

| Repository | URL | Stars | Last Updated |
|------------|-----|-------|--------------|
| princeton-nlp/SimPO | https://github.com/princeton-nlp/SimPO | 953 | June 6, 2026 |
| duck3244/korean-llm-dpo-alignment | https://github.com/duck3244/korean-llm-dpo-alignment | 0 | May 28, 2026 |
| bopalvelut-prog/simpo-training | https://github.com/bopalvelut-prog/simpo-training | - | - |

### A.2 Reference-Free Method Repositories

| Repository | URL | Stars | Last Updated |
|------------|-----|-------|--------------|
| sail-sg/CPO | https://github.com/sail-sg/CPO | 136 | April 22, 2026 |
| fe1ixxu/CPO_SIMPO | https://github.com/fe1ixxu/CPO_SIMPO | 58 | - |
| ZonglinL/CPO | https://github.com/ZonglinL/CPO | 13 | May 21, 2026 |
| XiaoyuYoung/CPO | https://github.com/XiaoyuYoung/CPO | 120 | June 8, 2026 |
| mapo-t2i/mapo | https://github.com/mapo-t2i/mapo | 82 | - |

### A.3 Multi-Method Framework Repositories

| Repository | URL | Stars | Last Updated |
|------------|-----|-------|--------------|
| ContextualAI/HALOs | https://github.com/ContextualAI/HALOs | 906 | June 6, 2026 |
| zht8506/Easy-LLM-Post-Training | https://github.com/zht8506/Easy-LLM-Post-Training | 117 | June 8, 2026 |
| sail-sg/oat | https://github.com/sail-sg/oat | 660 | June 2, 2026 |

---

*Report Generated: June 10, 2026*

*Data Sources: GitHub API searches conducted across multiple query patterns*

*Research Coverage: 2025-2026 preference optimization and LLM alignment repositories*

*Note: Star counts and update dates reflect the most recent available data from GitHub at the time of search.*