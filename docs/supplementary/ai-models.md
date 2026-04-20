# AI Model Setup

This guide explains how to prepare an optional AI model layer for projects that use AI-assisted workflows.

## Start Here

1. Decide whether the project needs a local model, a cloud model, or no model at all.
2. If the project does not use AI assistance, skip this guide.
3. If the project uses AI assistance, choose exactly one primary provider to start.
4. Keep provider-specific credentials and endpoints outside version control.
5. Record the selected provider in `docs/project-context.md` or `ARCHITECTURE.md`.

## Required or Optional

- The workspace foundation does not require a local base model to be installed.
- A model is only required when a specific project, agent workflow, or automation flow depends on it.
- When a model is required, prefer the simplest supported path for the target machine.

## Local Model Path

Use this path when the model should run on the same machine as the developer.

### Common Local Options

- `Ollama`
- a local `Claude` or `Gemini` client when available for the target environment
- a local `Codex` or `GPT` workflow if the selected tool provides a local runtime or launcher

### Generic Steps

1. Install the provider’s official desktop app or CLI for the target operating system.
2. Install any runtime the provider requires.
3. Download or pull the selected local model.
4. Configure the provider with the model name, endpoint, and credentials if required.
5. Verify that the local endpoint or command works before wiring it into the project.
6. Keep the local model configuration outside the repository.

### Example Validation Targets

- command-line health check
- local HTTP endpoint
- provider login or authentication check
- a simple prompt or smoke test

## Cloud Model Path

Use this path when the model runs in a hosted provider environment.

### Common Cloud Providers

- `OpenAI / GPT`
- `Anthropic / Claude`
- `Google / Gemini`
- other managed providers approved by the project owner

### Generic Steps

1. Create or confirm access to the hosted provider account.
2. Create the API key, project key, or equivalent secret.
3. Store the secret in `.env`, encrypted local secrets, or a secret manager.
4. Configure the model name, base URL, and any required organization or project IDs.
5. Verify the connection from the local machine.
6. Document the chosen provider and fallback behavior.

### Example Validation Targets

- an authentication test
- a minimal API request
- a CLI health check
- a smoke test from the agent or automation layer

## Selection Rules

1. Use a local model when data locality, offline use, or predictable latency matters.
2. Use a cloud model when the local machine should stay light and provider features matter more.
3. Prefer one primary provider per project unless there is a clear fallback requirement.
4. If multiple providers are supported, document the default and the fallback explicitly.

## What to Record

1. Provider name.
2. Local or cloud mode.
3. Model name.
4. Required credentials or endpoints.
5. Fallback provider, if any.
6. Validation command or smoke test.
7. OS-specific notes, if the provider behaves differently on Windows, Linux, or macOS.

## Recommended Project Context Fields

When a scaffolded project is created, record the AI choice in `docs/project-context.md` using these fields:

1. `ai-model-mode`
2. `ai-model-provider`
3. `ai-model-name`
4. `ai-model-endpoint`
5. `ai-model-notes`

If the project does not use AI assistance, set `ai-model-mode` to `none` and leave the rest blank.
