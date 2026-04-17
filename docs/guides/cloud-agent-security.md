# Cloud Agent Security Guide

## Overview
Foundation allows you to delegate heavy AI tasks to cloud providers (AWS Bedrock, Difi, etc.) while keeping your local environment light.

## 1. Secure Configuration

### Never Commit Secrets
We use a **`.env.local`** file for credentials. This file is **gitignored** by default.

1. Copy `.env.example` to `.env.local`.
2. Fill in your API keys or AWS credentials.

### Principle of Least Privilege
- Create specific IAM users or API keys with **only** the permissions needed (e.g., `bedrock:InvokeModel`).
- Rotate keys every 90 days.

## 2. Manual Setup Steps

### For AWS Bedrock:
1. Install `AWSPowerShell.NetCore`: `Install-Module -Name AWSPowerShell.NetCore`
2. Configure AWS Profile: `Set-AWSCredential -ProfileName default`
3. Update `config/cloud-agents.json` with your region and model ID.

### For Difi / Generic APIs:
1. Obtain your API Key from the provider dashboard.
2. Add it to `.env.local` as `DIFI_API_KEY` or `GENERIC_AI_API_KEY`.
3. Set the `endpoint` in `cloud-agents.json`.

## 3. Preventing "Narration Errors"
When using cloud models for automation, always enable the `-StrictJson` flag in `invoke-cloud-agent.ps1`. This forces the model to return only valid JSON tool calls, preventing parsing errors in your scripts.

## 4. Troubleshooting
- **"Upstream returned workflow narration..."**: The model talked instead of acting. Ensure `temperature` is low (0.1) and `response_format` is set to JSON.
- **Auth Failed**: Check that your `.env.local` variables match the names in `invoke-cloud-agent.ps1`.
