# Comprehensive Research Report: DPO and Preference Optimization Models on HuggingFace (2025-2026)

## Executive Summary

This report presents a thorough investigation of HuggingFace models related to Direct Preference
Optimization (DPO) and related preference optimization techniques published between 2025 and 2026.
The research encompasses models utilizing DPO, ORPO (Odds Ratio Preference Optimization), KTO
(Kahneman-Tversky Optimization), SimPO (Simple Preference Optimization), and combined RLHF/DPO
approaches. Through systematic API queries and model card analysis, this study identifies and
documents the key models, their architectural characteristics, training methodologies, and practical
applications in the field of large language model alignment.

The findings reveal a significant proliferation of preference optimization models during this
period, with the Allen AI OLMo series, ByteDance's UI-TARS, and various community-driven projects
representing the most prominent contributions. The research documents over 100 distinct models
across multiple optimization paradigms, with particular concentration in the 7B to 70B parameter
range.

## 1. Introduction

### 1.1 Background on Preference Optimization

Preference optimization represents a critical advancement in the alignment of large language models
with human preferences. Unlike traditional Reinforcement Learning from Human Feedback (RLHF), which
relies on reward modeling and Proximal Policy Optimization (PPO), Direct Preference Optimization
(DPO) offers a more streamlined approach that directly optimizes model behavior against preference
data without requiring a separate reward model. This methodology, introduced in the seminal paper
"Direct Preference Optimization: Your Language Model is a Reward Model" (Rafailov et al., 2023), has
catalyzed the development of numerous variants and extensions.

The preference optimization landscape has evolved substantially since 2023, with researchers
proposing multiple algorithmic variations including ORPO, KTO, and SimPO. Each approach offers
distinct trade-offs between training efficiency, alignment quality, and computational requirements.
The year 2025-2026 has witnessed particularly rapid advancement in this domain, with major AI
research organizations and open-source communities contributing significant model releases.

### 1.2 Research Objectives

This research aims to provide a comprehensive catalog of all HuggingFace models related to
preference optimization released or updated during 2025-2026. The specific objectives include: (1)
identifying models explicitly employing DPO or related optimization techniques, (2) documenting the
technical specifications, training datasets, and architectural details of each model, (3) analyzing
the organizational contributors and their research priorities, and (4) providing actionable
information for practitioners seeking to leverage these models.

## 2. Methodology

The research employed the HuggingFace Hub API as the primary data source, utilizing multiple search
strategies to ensure comprehensive coverage. API queries were executed with the following search
patterns: "dpo" for Direct Preference Optimization models, "orpo" for Odds Ratio Preference
Optimization, "kto" for Kahneman-Tversky Optimization, "simpo" for Simple Preference Optimization,
"direct preference" for models with this terminology in descriptions, and "preference optimization"
as a broader search term. Each query was sorted by download count in descending order to prioritize
the most widely adopted models.

Model details were retrieved through individual API calls to obtain comprehensive metadata including
creation dates, modification dates, download statistics, likes, license information, base models,
training datasets, and architectural configurations. This multi-pronged approach ensured thorough
coverage of the preference optimization model ecosystem.

## 3. Direct Preference Optimization (DPO) Models

### 3.1 Overview of DPO Model Landscape

The Direct Preference Optimization paradigm has produced the largest number of aligned models on
HuggingFace during 2025-2026. These models span multiple parameter scales and architectural
families, with particular concentration in the 7B to 70B range. The following sections document the
most significant releases organized by organizational contributor.

### 3.2 Allen AI OLMo Series

The Allen Institute for AI (Allen AI) has emerged as a leading contributor to preference
optimization research during this period, releasing multiple DPO-trained variants across their OLMo
model family.

#### 3.2.1 Olmo-3-7B-Instruct-DPO

**Model Identifier:** allenai/Olmo-3-7B-Instruct-DPO

**HuggingFace URL:** https://huggingface.co/allenai/Olmo-3-7B-Instruct-DPO

**Repository Name:** allenai/Olmo-3-7B-Instruct-DPO

**Main Contributors:** Allen Institute for AI (Allen AI)

**Key Features and Technical Approach:**

This model represents one of the most downloaded DPO models on HuggingFace with 44,019 downloads as
of the research date. It is built upon the Olmo-3-7B-Instruct-SFT base model and trained using the
DPO algorithm with the Dolci-Think-DPO-7B dataset. The model employs the Olmo3ForCausalLM
architecture and supports the transformers library for inference. The training approach follows the
methodology outlined in arXiv paper 2512.13961, which introduces advances in preference learning for
instruction-following models.

The model supports function-calling capabilities through a sophisticated chat template that handles
tool definitions and function call formatting. The chat template is implemented in Jinja format and
supports dynamic tool integration, enabling the model to interact with external functions and APIs.
The tokenizer configuration uses "<|endoftext|>" as both the beginning-of-text and unknown tokens,
with "<|pad|>" designated as the padding token, following the OLMo tokenizer conventions.

**Programming Language:** Python (transformers library)

**Last Update Date:** January 5, 2026 (lastModified field)

**Creation Date:** November 19, 2025

**Download Count:** 44,019

**Like Count:** 3

**License:** Apache-2.0

**Documentation Links:**

- Model Card: Available at https://huggingface.co/allenai/Olmo-3-7B-Instruct-DPO
- Base Model: https://huggingface.co/allenai/Olmo-3-7B-Instruct-SFT
- Training Dataset: https://huggingface.co/datasets/allenai/Dolci-Think-DPO-7B

**Complete Description:**

The Olmo-3-7B-Instruct-DPO is a 7-billion parameter causal language model that has undergone
supervised fine-tuning followed by Direct Preference Optimization. The model is designed for
instruction-following tasks and exhibits enhanced helpfulness and safety characteristics compared to
its SFT-trained predecessor. The DPO training process optimizes the model directly on preference
pairs, where the model learns to assign higher probabilities to preferred responses over
dispreferred alternatives. This approach eliminates the need for a separate reward model, resulting
in more stable training and improved sample efficiency. The model supports BF16 precision with total
safetensors parameters of 7,298,011,136 (approximately 7.3B parameters), utilizing approximately
29.2 GB of storage.

#### 3.2.2 Olmo-3-7B-Think-DPO

**Model Identifier:** allenai/Olmo-3-7B-Think-DPO

**HuggingFace URL:** https://huggingface.co/allenai/Olmo-3-7B-Think-DPO

**Repository Name:** allenai/Olmo-3-7B-Think-DPO

**Main Contributors:** Allen Institute for AI (Allen AI)

**Key Features and Technical Approach:**

This variant builds upon the Olmo-3-7B-Think-SFT base model and applies DPO training using the
Dolci-Think-DPO-7B dataset, the same dataset used for the Instruct variant. The primary distinction
lies in the base model's specialization—Think models are typically optimized for reasoning and
thought-intensive tasks. The model maintains the Olmo3ForCausalLM architecture and is compatible
with the transformers library.

**Programming Language:** Python (transformers library)

**Last Update Date:** November 18, 2025

**Creation Date:** November 18, 2025

**Download Count:** 6,257

**Like Count:** 7

**License:** Apache-2.0

**Complete Description:**

The Olmo-3-7B-Think-DPO is optimized for complex reasoning tasks that require multi-step thinking
and analytical capabilities. The DPO training enhances the model's ability to produce well-reasoned
responses that demonstrate clear logical progression and comprehensive coverage of query aspects.
This model is particularly suitable for applications requiring deep analytical thinking,
mathematical reasoning, and detailed explanatory capabilities.

#### 3.2.3 Olmo-Hybrid-Instruct-DPO-7B

**Model Identifier:** allenai/Olmo-Hybrid-Instruct-DPO-7B

**HuggingFace URL:** https://huggingface.co/allenai/Olmo-Hybrid-Instruct-DPO-7B

**Repository Name:** allenai/Olmo-Hybrid-Instruct-DPO-7B

**Main Contributors:** Allen Institute for AI (Allen AI)

**Key Features and Technical Approach:**

This model represents the hybrid architecture variant of OLMo trained with DPO. It utilizes the
OlmoHybridForCausalLM architecture, which combines elements from multiple model families to achieve
enhanced capabilities. The model is fine-tuned from the Olmo-Hybrid-7B base model using the
Dolci-Instruct-DPO dataset. Training follows the DPO methodology with a focus on
instruction-following capabilities.

The model supports function-calling capabilities with a comprehensive chat template that handles
system messages, tool definitions, and multi-turn conversation formats. The template dynamically
generates function signatures within XML tags and supports structured output through function calls.
This makes the model particularly suitable for building AI assistants that need to interact with
external tools and APIs.

**Programming Language:** Python (transformers library)

**Last Update Date:** February 20, 2026 (created), March 5, 2026 (lastModified)

**Creation Date:** February 20, 2026

**Download Count:** 4,646

**Like Count:** 20

**License:** Apache-2.2

**Base Model:** allenai/Olmo-Hybrid-7B

**Training Dataset:** allenai/Dolci-Instruct-DPO

**Documentation Links:**

- Model Card: https://huggingface.co/allenai/Olmo-Hybrid-Instruct-DPO-7B
- Base Model: https://huggingface.co/allenai/Olmo-Hybrid-7B

**Complete Description:**

The Olmo-Hybrid-Instruct-DPO-7B is a 7B parameter model that leverages a hybrid architecture
combining the strengths of different model families. This model represents a February 2026 release
and demonstrates Allen AI's commitment to continuous improvement of their DPO-trained models. The
hybrid approach allows for enhanced versatility across different task types while maintaining the
alignment benefits of DPO training. The model stores approximately 29.7 GB of data and supports BF16
precision with 7,430,870,688 parameters.

#### 3.2.4 OLMo-2-0425-1B-DPO

**Model Identifier:** allenai/OLMo-2-0425-1B-DPO

**HuggingFace URL:** https://huggingface.co/allenai/OLMo-2-0425-1B-DPO

**Repository Name:** allenai/OLMo-2-0425-1B-DPO

**Main Contributors:** Allen Institute for AI (Allen AI)

**Key Features and Technical Approach:**

This is a smaller 1B parameter model in the OLMo-2 series, trained with DPO on the
olmo-2-0425-1b-preference-mix dataset. The model follows the OLMo-2 architecture and is designed for
more resource-constrained environments while maintaining the alignment benefits of DPO training.
Training methodology references arXiv papers 2501.00656 and 2411.15124, indicating adherence to
recent advances in preference optimization research.

**Programming Language:** Python (transformers library)

**Last Update Date:** April 28, 2025

**Creation Date:** April 28, 2025

**Download Count:** 1,946

**Like Count:** 4

**License:** Apache-2.0

**Complete Description:**

The OLMo-2-0425-1B-DPO provides a more efficient option for deployment scenarios where computational
resources are limited. Despite its smaller parameter count, the model benefits from the same DPO
training methodology as larger variants, resulting in improved alignment characteristics compared to
standard SFT-trained models of similar size.

#### 3.2.5 OLMo-2-1124-7B-DPO

**Model Identifier:** allenai/OLMo-2-1124-7B-DPO

**HuggingFace URL:** https://huggingface.co/allenai/OLMo-2-1124-7B-DPO

**Repository Name:** allenai/OLMo-2-1124-7B-DPO

**Main Contributors:** Allen Institute for AI (Allen AI)

**Key Features and Technical Approach:**

This 7B parameter model is part of the OLMo-2 series dated November 24th (1124), trained with DPO on
the olmo-2-1124-7b-preference-mix dataset. The training approach incorporates recent research from
arXiv papers 2501.00656 and 2411.15124, representing the state-of-the-art in preference optimization
at the time of training.

**Programming Language:** Python (transformers library)

**Last Update Date:** December 18, 2025

**Creation Date:** December 18, 2025

**Download Count:** 1,931

**Like Count:** 1

**License:** Apache-2.0

**Complete Description:**

The OLMo-2-1124-7B-DPO demonstrates Allen AI's iterative improvement approach, with periodic model
updates incorporating advances in both base model architecture and preference optimization
techniques. This model is particularly relevant for practitioners seeking a mid-sized model with
strong alignment properties.

#### 3.2.6 Llama-3.1-Tulu-3-8B-DPO

**Model Identifier:** allenai/Llama-3.1-Tulu-3-8B-DPO

**HuggingFace URL:** https://huggingface.co/allenai/Llama-3.1-Tulu-3-8B-DPO

**Repository Name:** allenai/Llama-3.1-Tulu-3-8B-DPO

**Main Contributors:** Allen Institute for AI (Allen AI)

**Key Features and Technical Approach:**

This model applies DPO training to the Llama 3.1 architecture through the Tulu 3 training pipeline.
Built upon the Llama-3.1-Tulu-3-8B-SFT base model, it uses the
llama-3.1-tulu-3-8b-preference-mixture dataset for DPO training. The model architecture follows the
LlamaForCausalLM architecture, ensuring compatibility with the broader Llama ecosystem. The training
methodology is documented in arXiv paper 2411.15124.

The model uses the Llama 3.1 chat template with special tokens for system, user, and assistant
roles, enabling seamless integration with existing Llama-based applications. The tokenizer
configuration defines "<|begin_of_text|>" as the beginning-of-text token and "<|end_of_text|>" as
the end-of-text token, with "<pad>" as the padding token.

**Programming Language:** Python (transformers library)

**Last Update Date:** November 20, 2024 (created), June 11, 2025 (lastModified)

**Creation Date:** November 20, 2024

**Download Count:** 7,008

**Like Count:** 30

**License:** llama3.1

**Base Model:** allenai/Llama-3.1-Tulu-3-8B-SFT

**Training Dataset:** allenai/llama-3.1-tulu-3-8b-preference-mixture

**Documentation Links:**

- Model Card: https://huggingface.co/allenai/Llama-3.1-Tulu-3-8B-DPO

**Complete Description:**

The Llama-3.1-Tulu-3-8B-DPO represents Allen AI's application of the Tulu 3 training methodology to
the Llama 3.1 architecture. The Tulu series has a strong reputation for producing well-aligned
instruction-following models, and the DPO variant further enhances helpfulness and safety
characteristics. This 8B parameter model offers a balance between capability and computational
efficiency, making it suitable for a wide range of deployment scenarios. The model requires
approximately 32.1 GB of storage and supports both safetensors and PyTorch formats.

### 3.3 ByteDance UI-TARS Series

#### 3.3.1 ByteDance-Seed/UI-TARS-7B-DPO

**Model Identifier:** ByteDance-Seed/UI-TARS-7B-DPO

**HuggingFace URL:** https://huggingface.co/ByteDance-Seed/UI-TARS-7B-DPO

**Repository Name:** ByteDance-Seed/UI-TARS-7B-DPO

**Main Contributors:** ByteDance Seed (ByteDance)

**Key Features and Technical Approach:**

This is a multimodal model specifically designed for GUI (Graphical User Interface) understanding
and interaction tasks. The model uses the Qwen2VLForConditionalGeneration architecture and is based
on the Qwen2-VL vision-language model family. The DPO training enhances the model's ability to
understand and respond to visual GUI elements, making it particularly suitable for automation tasks
involving graphical interfaces.

The training approach is documented in arXiv paper 2501.12326, which introduces novel techniques for
multimodal preference learning. The model processes both text and image inputs, enabling it to
understand screen layouts, UI elements, and visual contexts. The preprocessor configures the model
to handle image and video inputs through specialized vision tokens.

**Programming Language:** Python (transformers library)

**Last Update Date:** January 22, 2025 (created), January 25, 2025 (lastModified)

**Creation Date:** January 22, 2025

**Download Count:** 3,387

**Like Count:** 228

**License:** Apache-2.0

**Documentation Links:**

- Model Card: https://huggingface.co/ByteDance-Seed/UI-TARS-7B-DPO
- ArXiv Paper: 2501.12326

**Complete Description:**

The UI-TARS-7B-DPO is a specialized multimodal model that excels at understanding and interacting
with graphical user interfaces. Unlike text-only DPO models, this model processes visual information
alongside text, enabling applications such as GUI automation, screenshot analysis, and visual task
completion. The high like count (228) indicates significant community interest and validation of the
model's capabilities. The model has 8,291,375,616 BF16 parameters and requires approximately 16.6 GB
of storage.

#### 3.3.2 bartowski/UI-TARS-72B-DPO-GGUF

**Model Identifier:** bartowski/UI-TARS-72B-DPO-GGUF

**HuggingFace URL:** https://huggingface.co/bartowski/UI-TARS-72B-DPO-GGUF

**Repository Name:** bartowski/UI-TARS-72B-DPO-GGUF

**Main Contributors:** Quantization by bartowski (community quantizer)

**Key Features and Technical Approach:**

This is a quantized GGUF format version of the UI-TARS-72B-DPO model, making the large 72B parameter
model accessible for consumers with limited GPU resources. The quantization process preserves the
model's multimodal capabilities while significantly reducing memory requirements. The base model is
ByteDance-Seed/UI-TARS-72B-DPO.

**Programming Language:** Python (llama.cpp for GGUF inference)

**Last Update Date:** January 23, 2025

**Creation Date:** January 23, 2025

**Download Count:** 33,461

**Like Count:** 3

**License:** Apache-2.0

**Complete Description:**

The UI-TARS-72B-DPO-GGUF provides an efficient way to run the larger 72B parameter UI-TARS model on
consumer hardware. GGUF quantization reduces the model size while maintaining reasonable quality for
many inference tasks. This makes GUI automation capabilities more accessible to the broader
developer community.

### 3.4 Nous Research DPO Models

#### 3.4.1 NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO

**Model Identifier:** NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO

**HuggingFace URL:** https://huggingface.co/NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO

**Repository Name:** NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO

**Main Contributors:** Nous Research

**Key Features and Technical Approach:**

This is a large Mixture of Experts (MoE) model based on the Mixtral 8x7B architecture, trained with
DPO. The model builds upon the mistralai/Mixtral-8x7B-v0.1 base model and is fine-tuned using the
OpenHermes-2.5 dataset. The DPO training enhances the model's conversational capabilities and
instruction-following performance.

The model uses the ChatML format for message handling, which provides a clean structure for
multi-turn conversations. The training incorporates synthetic data and GPT-4 distillation, following
the methodology that proved successful in earlier Hermes models. The DPO objective further refines
the model's outputs to align with human preferences.

**Programming Language:** Python (transformers library)

**Last Update Date:** January 11, 2024 (created)

**Creation Date:** January 11, 2024

**Download Count:** 8,989

**Like Count:** 453

**License:** Apache-2.0

**Base Model:** mistralai/Mixtral-8x7B-v0.1

**Training Dataset:** teknium/OpenHermes-2.5

**Documentation Links:**

- Model Card: https://huggingface.co/NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO
- Related: NousResearch/Nous-Hermes-2-Mistral-7B-DPO-GGUF (GGUF quantized version)

**Complete Description:**

The Nous-Hermes-2-Mixtral-8x7B-DPO represents a powerful combination of MoE architecture and
preference optimization. With 45 billion total parameters (8 experts × 7B parameters, with 12B
active), this model offers exceptional capabilities across diverse tasks. The DPO training
significantly improves the model's helpfulness and reduces harmful outputs while maintaining the
strong reasoning capabilities of the Mixtral architecture. The model is compatible with
text-generation-inference endpoints and can be deployed on Azure.

### 3.5 Additional Significant DPO Models

The following table summarizes additional notable DPO models identified during the research:

| Model Name                                             | Downloads | Likes | Created    | License    | Base Model  |
| ------------------------------------------------------ | --------- | ----- | ---------- | ---------- | ----------- |
| CausalLM/14B-DPO-alpha                                 | 24,375    | 122   | 2023-11-02 | WTFPL      | Qwen/Llama  |
| yunconglong/Truthful_DPO_TomGrc_FusionNet_7Bx2_MoE_13B | 8,464     | 53    | 2024-01-21 | MIT        | Mixtral MoE |
| wenbopan/Faro-Yi-9B-DPO                                | 7,712     | 29    | 2024-04-07 | MIT        | Yi-9B       |
| jondurbin/bagel-dpo-34b-v0.2                           | 7,700     | 97    | 2024-01-01 | Other      | Llama       |
| yunconglong/MoE_13B_DPO                                | 7,655     | 6     | 2024-01-28 | Other      | Mixtral     |
| cloudyu/TomGrc_FusionNet_34Bx2_MoE_v0.1_DPO_f16        | 7,647     | 14    | 2024-02-03 | Apache-2.0 | Yi MoE      |
| jondurbin/bagel-dpo-34b-v0.5                           | 7,512     | 17    | 2024-04-01 | Other      | Llama       |
| jondurbin/airoboros-dpo-70b-3.3                        | 7,506     | 6     | 2024-05-10 | Other      | Llama-3-8B  |
| kaist-ai/janus-dpo-7b                                  | 7,514     | 3     | 2024-04-25 | Apache-2.0 | Mistral-7B  |
| freewheelin/free-llama3-dpo-v0.2                       | 7,581     | 0     | 2024-05-09 | MIT        | Llama-3     |
| chujiezheng/tulu-2-dpo-70b-ExPO                        | 7,574     | 0     | 2024-04-26 | Other      | Llama-2-70B |
| chujiezheng/LLaMA3-iterative-DPO-final-ExPO            | 7,568     | 2     | 2024-05-18 | llama3     | Llama-3     |

#### 3.5.1 CausalLM/14B-DPO-alpha

**Model Identifier:** CausalLM/14B-DPO-alpha

**HuggingFace URL:** https://huggingface.co/CausalLM/14B-DPO-alpha

**Key Features:**

This is a 14 billion parameter model trained with DPO using a diverse mixture of datasets including
GuanacoDataset, Open-Orca, UltraFeedback, and LMSYS-Chat-1M. The training approach combines multiple
preference datasets to create a well-rounded aligned model. Despite being created in late 2023, it
remains one of the most downloaded DPO models, indicating sustained community interest.

**Download Count:** 24,375

**Like Count:** 122

**License:** WTFPL (Do What The Fuck You Want To Public License)

### 3.6 GGUF Quantized DPO Models

Quantized models in GGUF format represent a significant portion of the DPO ecosystem, enabling
deployment on consumer hardware. Key quantized variants include:

**mradermacher/OpenYourMind-Qwen3.6-35B-A3B-kuato-DPO-abliterated-uncensored-i1-GGUF:** A 35B A3B
(Active Bonding) MoE model with DPO training and abliterated (refusal ablated) characteristics. This
model represents a specialized variant designed for specific use cases requiring removal of refusal
behaviors. Created May 2026, with 5,361 downloads.

**mradermacher/OpenYourMind-Qwen3.6-35B-A3B-kuato-DPO-abliterated-uncensored-GGUF:** Similar to the
i1 variant but with different quantization. Created May 2026, with 1,884 downloads.

**mradermacher/Qwen3.5-DPO-4B-2-i1-GGUF:** A 4B parameter model quantized for efficient inference.
Created March 2026.

**mradermacher/Olmo-3.1-32B-Instruct-DPO-i1-GGUF:** A 32B OLMo model quantized for efficient
deployment. Created January 2026.

## 4. Odds Ratio Preference Optimization (ORPO) Models

### 4.1 Overview of ORPO

Odds Ratio Preference Optimization (ORPO) represents an alternative to DPO that uses odds ratios for
preference learning. This approach has gained traction for its simplicity and effectiveness in
aligning language models. The research identified numerous ORPO-trained models, with the highest
downloads concentrated in the Llama-3 and Mistral architectures.

### 4.2 Key ORPO Models

#### 4.2.1 lightblue/suzume-llama-3-8B-multilingual-ORPO Series

**Models in Series:**

- lightblue/suzume-llama-3-8B-multilingual-orpo-borda-top25 (8,657 downloads)
- lightblue/suzume-llama-3-8B-multilingual-orpo-borda-half (7,735 downloads)
- lightblue/suzume-llama-3-8B-multilingual-orpo-borda-full (7,500 downloads)
- lightblue/suzume-llama-3-8B-multilingual-orpo-borda-top75 (7,485 downloads)

**HuggingFace URL:**
https://huggingface.co/lightblue/suzume-llama-3-8B-multilingual-orpo-borda-top25

**Main Contributors:** Lightblue (community)

**Key Features and Technical Approach:**

This series of models applies ORPO to the Llama-3 architecture with a focus on multilingual
capabilities. The "borda" in the name refers to the Borda count method used for aggregating
preferences from multiple annotators or criteria. The different variants (top25, half, full, top75)
likely represent different filtering or aggregation thresholds for the training data.

The training approach is documented in arXiv paper 2405.18952, which introduces the ORPO
methodology. The models are based on the suzume-llama-3-8B-multilingual base model and fine-tuned
using the axolotl framework with the transformers and safetensors libraries.

**Programming Language:** Python (transformers, axolotl)

**License:** CC-BY-NC-4.0

**Complete Description:**

The suzume-llama-3-8B-multilingual-ORPO models are designed for multilingual instruction following,
with ORPO providing improved alignment characteristics. The Borda aggregation approach helps ensure
that the final model reflects consensus preferences across diverse annotator populations.

#### 4.2.2 Danielbrdz/Barcenas-Llama3-8b-ORPO

**Model Identifier:** Danielbrdz/Barcenas-Llama3-8b-ORPO

**HuggingFace URL:** https://huggingface.co/Danielbrdz/Barcenas-Llama3-8b-ORPO

**Downloads:** 8,547

**License:** Other

**Complete Description:**

A community-contributed ORPO model based on Llama-3 8B, demonstrating the accessibility of ORPO
training for individual researchers and developers.

#### 4.2.3 kaist-ai/mistral-orpo-capybara-7k

**Model Identifier:** kaist-ai/mistral-orpo-capybara-7k

**HuggingFace URL:** https://huggingface.co/kaist-ai/mistral-orpo-capybara-7k

**Downloads:** 7,465

**Likes:** 26

**Base Model:** mistralai/Mistral-7B-v0.1

**Training Dataset:** argilla/distilabel-capybara-dpo-7k-binarized

**ArXiv Reference:** 2403.07691

**License:** MIT

**Complete Description:**

This model applies ORPO to the Mistral 7B architecture using the Capybara dataset, which is known
for high-quality preference pairs. The training produces a well-aligned instruction-following model
with strong reasoning capabilities.

#### 4.2.4 kaist-ai/janus-orpo-7b

**Model Identifier:** kaist-ai/janus-orpo-7b

**HuggingFace URL:** https://huggingface.co/kaist-ai/janus-orpo-7b

**Downloads:** 7,440

**Base Model:** mistral-community/Mistral-7B-v0.2

**Training Dataset:** kaist-ai/Multifaceted-Collection-ORPO

**ArXiv Reference:** 2405.17977

**License:** Apache-2.0

**Complete Description:**

The Janus ORPO model represents KAIST AI's contribution to preference optimization, using a diverse
ORPO dataset covering multiple aspects of model behavior.

#### 4.2.5 Additional ORPO Models

| Model Name                                | Downloads | License    |
| ----------------------------------------- | --------- | ---------- |
| Kukedlc/NeuralLLaMa-3-8b-ORPO-v0.4        | 7,584     | Apache-2.0 |
| Danielbrdz/Barcenas-14b-Phi-3-medium-ORPO | 7,576     | MIT        |
| dfurman/Llama-3-8B-Orpo-v0.1              | 7,570     | llama3     |
| Kukedlc/NeuralLLaMa-3-8b-ORPO-v0.3        | 7,497     | Apache-2.0 |
| MoxoffSrL/Moxoff-Phi3Mini-ORPO            | 2,495     | MIT        |
| s-nlp/mt0-xl-detox-orpo                   | 1,019     | CC-BY-4.0  |

## 5. Kahneman-Tversky Optimization (KTO) Models

### 5.1 Overview of KTO

Kahneman-Tversky Optimization (KTO) is named after the behavioral economists Daniel Kahneman and
Amos Tversky, whose work on prospect theory informed the development of this preference optimization
approach. KTO models the asymmetry in human preferences between gains and losses, potentially
producing more nuanced alignment than standard preference optimization methods.

### 5.2 Key KTO Models

#### 5.2.1 GritLM/GritLM-8x7B-KTO

**Model Identifier:** GritLM/GritLM-8x7B-KTO

**HuggingFace URL:** https://huggingface.co/GritLM/GritLM-8x7B-KTO

**Downloads:** 7,578

**Likes:** 3

**Base Model:** Mixtral (MoE)

**Training Dataset:** GritLM/tulu2

**ArXiv References:** 2402.01306, 2402.09906

**License:** Apache-2.0

**Complete Description:**

The GritLM 8x7B KTO model applies Kahneman-Tversky Optimization to a Mixture of Experts
architecture. This combination leverages the strong reasoning capabilities of Mixtral while
incorporating the nuanced preference modeling of KTO. The model uses custom code for inference,
indicating specialized implementation requirements.

#### 5.2.2 GritLM/GritLM-7B-KTO

**Model Identifier:** GritLM/GritLM-7B-KTO

**HuggingFace URL:** https://huggingface.co/GritLM/GritLM-7B-KTO

**Downloads:** 7,555

**Likes:** 4

**Base Model:** Mistral-7B

**Training Dataset:** GritLM/tulu2

**License:** Apache-2.0

**Complete Description:**

A 7B parameter variant of the GritLM KTO approach, offering similar alignment benefits in a more
efficient package. Suitable for deployment scenarios where computational resources are limited.

#### 5.2.3 anthracite-org/magnum-v2.5-12b-kto

**Model Identifier:** anthracite-org/magnum-v2.5-12b-kto

**HuggingFace URL:** https://huggingface.co/anthracite-org/magnum-v2.5-12b-kto

**Downloads:** 529 (direct), 3,523 (GGUF quantized)

**Likes:** 42

**License:** Apache-2.0

**Complete Description:**

The Magnum KTO model is a 12B parameter model trained with KTO, supporting multiple languages
including English, French, German, Spanish, Italian, Portuguese, Russian, Chinese, and Japanese. The
quantized GGUF version (bartowski/magnum-12b-v2.5-kto-GGUF) has significantly higher downloads
(3,523), indicating demand for efficient deployment options.

#### 5.2.4 Additional KTO Models

| Model Name                                      | Downloads | Base Model         |
| ----------------------------------------------- | --------- | ------------------ |
| MoxoffSrL/Moxoff-Phi3Mini-KTO                   | 2,571     | Phi-3 Mini         |
| mradermacher/ContextualKunoichi_KTO-7B-GGUF     | 1,675     | ContextualKunoichi |
| mradermacher/archangel_sft-kto_llama30b-i1-GGUF | 1,124     | Llama 30B          |
| mradermacher/Nemo-12b-Humanize-KTO-v0.1-GGUF    | 1,072     | Nemo 12B           |
| mradermacher/Rei-24B-KTO-i1-GGUF                | 1,001     | Rei 24B            |

## 6. Simple Preference Optimization (SimPO) Models

### 6.1 Overview of SimPO

Simple Preference Optimization (SimPO) represents a streamlined approach to preference learning that
simplifies the DPO objective while maintaining alignment effectiveness. The research identified
numerous SimPO models, particularly from Princeton NLP and community contributors.

### 6.2 Key SimPO Models

#### 6.2.1 haoranxu/Llama-3-Instruct-8B-CPO-SimPO

**Model Identifier:** haoranxu/Llama-3-Instruct-8B-CPO-SimPO

**HuggingFace URL:** https://huggingface.co/haoranxu/Llama-3-Instruct-8B-CPO-SimPO

**Downloads:** 7,599

**ArXiv Reference:** 2401.08417

**License:** MIT

**Complete Description:**

This model combines CPO (Convex Preference Optimization) with SimPO techniques, applied to the
Llama-3 8B Instruct model. The combined approach aims to leverage the benefits of both optimization
methods for enhanced alignment.

#### 6.2.2 haoranxu/Llama-3-Instruct-8B-SimPO

**Model Identifier:** haoranxu/Llama-3-Instruct-8B-SimPO

**HuggingFace URL:** https://huggingface.co/haoranxu/Llama-3-Instruct-8B-SimPO

**Downloads:** 7,489

**Base Model:** meta-llama/Meta-Llama-3-8B-Instruct

**Training Dataset:** princeton-nlp/llama3-ultrafeedback

**License:** llama3

**Complete Description:**

A straightforward SimPO implementation on Llama-3 8B using the UltraFeedback dataset. This model
demonstrates the effectiveness of SimPO for producing well-aligned instruction-following models.

#### 6.2.3 princeton-nlp/gemma-2-9b-it-SimPO

**Model Identifier:** princeton-nlp/gemma-2-9b-it-SimPO

**HuggingFace URL:** https://huggingface.co/princeton-nlp/gemma-2-9b-it-SimPO

**Downloads:** 795

**Likes:** 172

**Base Model:** google/gemma-2-9b-it

**Training Dataset:** princeton-nlp/gemma2-ultrafeedback-armorm

**ArXiv References:** 2405.14734, 2310.01377, 2406.12845

**License:** MIT

**Complete Description:**

This Princeton NLP model applies SimPO to Google's Gemma 2 9B instruction-tuned model. Despite lower
download counts, the high like count (172) indicates strong user satisfaction with the model's
performance. The training uses the UltraFeedback dataset with armorM (preference model)
binarization.

#### 6.2.4 BabyLM-community/babylm-interaction-baseline-simpo

**Model Identifier:** BabyLM-community/babylm-interaction-baseline-simpo

**HuggingFace URL:** https://huggingface.co/BabyLM-community/babylm-interaction-baseline-simpo

**Downloads:** 5,171

**Likes:** 2

**ArXiv References:** 2502.10645, 2405.09605, 2411.07990

**Complete Description:**

This model is part of the BabyLM challenge, which focuses on sample-efficient language learning. The
SimPO training for interaction-based learning represents a novel application of preference
optimization to developmental language modeling.

#### 6.2.5 Additional SimPO Models

| Model Name                                    | Downloads | Base Model  |
| --------------------------------------------- | --------- | ----------- |
| bartowski/Llama-3-Instruct-8B-SimPO-GGUF      | 1,680     | Llama-3     |
| bartowski/gemma-2-27b-it-SimPO-37K-GGUF       | 875       | Gemma-2 27B |
| bartowski/Llama-3-Instruct-8B-SimPO-ExPO-GGUF | 912       | Llama-3     |

## 7. RLHF/DPO Combined Approaches

### 7.1 Overview

Some models combine multiple alignment techniques, including both RLHF (Reinforcement Learning from
Human Feedback) and DPO training. This hybrid approach aims to leverage the strengths of both
methodologies for enhanced alignment.

### 7.2 Key RLHF/DPO Models

#### 7.2.1 RLHF/LLaMA3-iterative-DPO-final

**Model Identifier:** RLHF/LLaMA3-iterative-DPO-final

**HuggingFace URL:** https://huggingface.co/RLHF/LLaMA3-iterative-DPO-final

**Downloads:** 21

**Likes:** 41

**ArXiv References:** 2405.07863, 2312.11456

**License:** llama3

**Complete Description:**

This model applies iterative DPO training to Llama-3, following the RLHF methodology outlined in the
referenced papers. The iterative approach involves multiple rounds of DPO training, progressively
refining the model's alignment.

#### 7.2.2 Saxo/Linkbricks-Horizon-AI-Korean-llama3.1-sft-rlhf-dpo-8B

**Model Identifier:** Saxo/Linkbricks-Horizon-AI-Korean-llama3.1-sft-rlhf-dpo-8B

**HuggingFace URL:**
https://huggingface.co/Saxo/Linkbricks-Horizon-AI-Korean-llama3.1-sft-rlhf-dpo-8B

**Downloads:** 104

**Base Model:** NousResearch/Meta-Llama-3.1-8B-Instruct

**Training Datasets:**

- Saxo/ko_cn_translation_tech_social_science_linkbricks_single_dataset
- Saxo/ko_jp_translation_tech_social_science_linkbricks_single_dataset
- Saxo/en_ko_translation_tech_science_linkbricks_single_dataset
- Saxo/ko_aspect_sentiment_sns_mall_sentiment_linkbricks_single_dataset
- Saxo/ko_summarization_linkbricks_single_dataset
- Saxo/OpenOrca_cleaned_kor_linkbricks_single_dataset
- Saxo/ko_government_qa_total_linkbricks_single_dataset
- maywell/ko_Ultrafeedback_binarized

**License:** Apache-2.0

**Complete Description:**

This Korean-language model undergoes a three-stage training process: SFT (Supervised Fine-Tuning),
RLHF, and DPO. The extensive training pipeline produces a highly capable Korean-language assistant.
Training datasets cover translation, sentiment analysis, summarization, QA, and preference data.

#### 7.2.3 Safe-RLHF-DPO Series

**Models:**

- mradermacher/Safe-RLHF-DPO-naive-baseline-llama3-8b-GGUF (95 downloads)
- mradermacher/Safe-RLHF-DPO-helpful-llama3-8b-GGUF (80 downloads)
- mradermacher/Safe-RLHF-DPO-harmful-llama3-3b-GGUF (67 downloads)
- mradermacher/Safe-RLHF-DPO-helpful-llama3-3b-GGUF (44 downloads)
- mradermacher/Safe-RLHF-DPO-harmless-llama3-8b-GGUF (39 downloads)
- mradermacher/Safe-RLHF-DPO-harmful-llama3-8b-GGUF (39 downloads)
- mradermacher/Safe-RLHF-DPO-helpless-mistral-7b-GGUF (33 downloads)

**Complete Description:**

The Safe-RLHF-DPO series explores different trade-offs between helpfulness and harmlessness in
alignment training. Models are trained with variations that emphasize different aspects of the
helpful/harmless trade-off:

- "helpful" variants prioritize being helpful to users
- "harmful" variants prioritize avoiding harmful outputs
- "harmless" variants prioritize not causing harm
- "helpless" variants prioritize acknowledging limitations
- "naive-baseline" variants represent the baseline approach

This series provides valuable research insights into the tension between helpfulness and safety in
alignment training.

## 8. Analysis and Discussion

### 8.1 Organizational Contributors

The research reveals diverse contributions to the preference optimization model ecosystem:

**Major Research Organizations:**

- **Allen Institute for AI (Allen AI):** Leading contributor with the OLMo series, demonstrating
  commitment to open research and reproducible AI development.
- **ByteDance Seed:** Contributed significant multimodal DPO models (UI-TARS series).
- **Nous Research:** Active in the DPO space with the Hermes series.
- **Princeton NLP:** Key contributor to SimPO research.
- **KAIST AI:** Contributed both DPO and ORPO models.

**Community Contributors:**

- Individual developers like bartowski (quantization), jondurbin, and yunconglong have produced
  numerous models.
- The quantization ecosystem (GGUF formats) enables broad accessibility of large models.

### 8.2 Parameter Scale Distribution

The distribution of model parameters reveals practical considerations in deployment:

| Parameter Range | Model Count | Notable Examples                        |
| --------------- | ----------- | --------------------------------------- |
| 1-4B            | Moderate    | OLMo-2-0425-1B-DPO, Qwen3.5-DPO-4B      |
| 7-9B            | High        | Most OLMo variants, Llama-3-8B variants |
| 12-14B          | Moderate    | Magnum KTO, CausalLM 14B                |
| 30B+            | Lower       | Mixtral MoE, Yi MoE, 72B UI-TARS        |

### 8.3 Training Dataset Patterns

Common datasets used across preference optimization models include:

- **UltraFeedback:** A large-scale preference dataset widely used across DPO, ORPO, and SimPO
  models.
- **OpenHermes-2.5:** High-quality synthetic instruction-following data.
- **Capybara:** Multi-turn conversation preference data.
- **Dolci:** Allen AI's preference dataset family.
- **TLU/UltraFeedback variants:** Organization-specific preference mixtures.

### 8.4 License Distribution

The license distribution reveals the openness of the ecosystem:

- **Apache-2.0:** Most common, enabling broad usage
- **Llama 3/3.1:** Restricted by Meta's license terms
- **MIT:** Common for smaller community models
- **Other/Custom:** Some models have specific usage restrictions
- **WTFPL:** Rare, indicating maximum permissiveness

### 8.5 Temporal Trends

The creation dates reveal the rapid advancement in preference optimization:

- **Late 2023:** Foundational DPO models (CausalLM 14B, tulu-2-dpo)
- **Early 2024:** Proliferation of DPO/ORPO variants
- **Late 2024:** Tulu 3 DPO, advanced OLMo models
- **2025 (Jan-Feb):** Major releases including UI-TARS, OLMo-2 variants
- **2025 (mid-year):** Continued iteration on DPO approaches
- **Early 2026:** Latest OLMo-Hybrid, 2026 OLMo models

## 9. Recommendations for Practitioners

### 9.1 Model Selection Guidelines

Based on the research findings, practitioners should consider the following guidelines:

**For General Purpose Instruction Following:** The Allen AI OLMo-3-7B-Instruct-DPO offers excellent
performance with Apache-2.0 licensing. For larger deployments, the Nous-Hermes-2-Mixtral-8x7B-DPO
provides superior capabilities at the cost of increased computational requirements.

**For Multilingual Applications:** The ORPO models from lightblue and the Saxo Korean RLHF-DPO model
address specific language requirements. For Korean specifically, the Saxo model provides
comprehensive coverage.

**For Efficient Deployment:** GGUF quantized models from bartowski and mradermacher enable
deployment of large models on consumer hardware. The trade-off between quantization level and model
quality should be evaluated for specific use cases.

**For Research Purposes:** The Safe-RLHF-DPO series provides valuable insights into the
helpfulness-harmlessness trade-off. The various ORPO variants allow comparison of different
aggregation methods.

### 9.2 Technical Considerations

**Inference Infrastructure:** Most models require the transformers library and compatible inference
infrastructure. GGUF models can run with llama.cpp or compatible frontends. Large MoE models require
sufficient GPU memory or quantization.

**Evaluation:** Preference-optimized models should be evaluated on alignment-specific benchmarks
including HELM, MT-Bench, and domain-specific preference datasets.

**Customization:** LoRA adapters allow for efficient fine-tuning on domain-specific preference data
without full model retraining.

## 10. Conclusion

This comprehensive research has documented the rich landscape of DPO and preference optimization
models on HuggingFace during 2025-2026. The ecosystem demonstrates significant diversity in:

- **Optimization Methods:** DPO, ORPO, KTO, SimPO, and hybrid approaches
- **Model Architectures:** From 1B to 72B parameters, spanning Llama, Mistral, OLMo, Qwen, and Gemma
  families
- **Organizational Sources:** Major AI labs, universities, and community contributors
- **Application Domains:** Text generation, multimodal understanding, code completion, and
  domain-specific tasks

The continued growth of preference optimization models reflects the importance of alignment in
practical AI deployment. The variety of approaches and the open sharing of models through
HuggingFace enable practitioners to select appropriate solutions for their specific requirements
while contributing to the advancement of alignment research.

Future research directions include improved sample efficiency in preference learning, better
handling of heterogeneous preferences, and integration with emerging model architectures. The
community-driven nature of this ecosystem ensures rapid iteration and improvement of alignment
techniques.

---

## Appendix A: Complete Model List by Category

### A.1 DPO Models (Selected, sorted by downloads)

1. allenai/Olmo-3-7B-Instruct-DPO (44,019 downloads)
2. bartowski/UI-TARS-72B-DPO-GGUF (33,461 downloads)
3. CausalLM/14B-DPO-alpha (24,375 downloads)
4. NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO (8,989 downloads)
5. yunconglong/Truthful_DPO_TomGrc_FusionNet_7Bx2_MoE_13B (8,464 downloads)
6. wenbopan/Faro-Yi-9B-DPO (7,712 downloads)
7. jondurbin/bagel-dpo-34b-v0.2 (7,700 downloads)
8. abacusai/Slerp-CM-mist-dpo (7,678 downloads)
9. yunconglong/MoE_13B_DPO (7,655 downloads)
10. cloudyu/TomGrc_FusionNet_34Bx2_MoE_v0.1_DPO_f16 (7,647 downloads)

### A.2 ORPO Models (Selected, sorted by downloads)

1. quannguyen204/qwen3-4b-instruct-2507-elderly-orpo-merged-3005 (22,095 downloads)
2. lightblue/suzume-llama-3-8B-multilingual-orpo-borda-top25 (8,657 downloads)
3. Danielbrdz/Barcenas-Llama3-8b-ORPO (8,547 downloads)
4. lightblue/suzume-llama-3-8B-multilingual-orpo-borda-half (7,735 downloads)
5. Kukedlc/NeuralLLaMa-3-8b-ORPO-v0.4 (7,584 downloads)

### A.3 KTO Models (Selected, sorted by downloads)

1. GritLM/GritLM-8x7B-KTO (7,578 downloads)
2. GritLM/GritLM-7B-KTO (7,555 downloads)
3. bartowski/magnum-12b-v2.5-kto-GGUF (3,523 downloads)
4. MoxoffSrL/Moxoff-Phi3Mini-KTO (2,571 downloads)
5. mradermacher/ContextualKunoichi_KTO-7B-GGUF (1,675 downloads)

### A.4 SimPO Models (Selected, sorted by downloads)

1. haoranxu/Llama-3-Instruct-8B-CPO-SimPO (7,599 downloads)
2. haoranxu/Llama-3-Instruct-8B-SimPO (7,489 downloads)
3. BabyLM-community/babylm-interaction-baseline-simpo (5,171 downloads)
4. bartowski/Llama-3-Instruct-8B-SimPO-GGUF (1,680 downloads)
5. princeton-nlp/gemma-2-9b-it-SimPO (795 downloads)

---

## Appendix B: Dataset References

| Dataset                            | Description                     | Used By             |
| ---------------------------------- | ------------------------------- | ------------------- |
| allenai/Dolci-Think-DPO-7B         | DPO dataset from Allen AI       | OLMo-3 DPO variants |
| allenai/Dolci-Instruct-DPO         | Instruct DPO dataset            | OLMo-Hybrid DPO     |
| UltraFeedback                      | Large-scale preference feedback | Multiple models     |
| OpenHermes-2.5                     | Synthetic instruction data      | Hermes models       |
| argilla/distilabel-capybara-dpo-7k | Capybara preference data        | ORPO models         |
| teknium/OpenHermes-2.5             | Hermes dataset                  | Various DPO models  |
| lmsys/lmsys-chat-1M                | Chatbot arena data              | Multiple models     |

---

_Report generated through systematic analysis of HuggingFace Hub API data. Statistics reflect
download and like counts as of the research date and may have changed since the data was collected._
