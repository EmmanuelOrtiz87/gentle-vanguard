#!/usr/bin/env npx tsx
/**
 * Validate Provider Config
 *
 * Checks the global OpenCode provider config without printing secrets. This is
 * intentionally local and read-only: it validates shape/capability metadata so
 * custom providers do not enter the selector as ambiguous "name only" models.
 */

import { existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';

const GLOBAL_OPENCODE_CONFIG = join(homedir(), '.config', 'opencode', 'opencode.json');

interface ProviderModel {
  id?: string;
  name?: string;
  tool_call?: boolean;
  temperature?: boolean;
}

interface ProviderConfig {
  id?: string;
  name?: string;
  api?: string;
  npm?: string;
  options?: {
    baseURL?: string;
    apiKey?: string;
    headers?: Record<string, string>;
  };
  models?: Record<string, ProviderModel>;
}

interface OpenCodeConfig {
  model?: string;
  small_model?: string;
  provider?: Record<string, ProviderConfig>;
}

function loadConfig(): OpenCodeConfig {
  if (!existsSync(GLOBAL_OPENCODE_CONFIG)) {
    throw new Error(`Global OpenCode config not found: ${GLOBAL_OPENCODE_CONFIG}`);
  }
  return JSON.parse(readFileSync(GLOBAL_OPENCODE_CONFIG, 'utf-8')) as OpenCodeConfig;
}

function hasCredential(provider: ProviderConfig): boolean {
  if (provider.options?.apiKey) return true;
  const headers = provider.options?.headers ?? {};
  return Object.values(headers).some((value) => String(value).trim().length > 0);
}

function main(): void {
  const config = loadConfig();
  const issues: string[] = [];
  const warnings: string[] = [];
  const providers = config.provider ?? {};

  if (!config.model) issues.push('global model is missing');
  if (!config.small_model) issues.push('global small_model is missing');
  if (config.model && config.small_model && config.model !== config.small_model) {
    warnings.push(`model and small_model differ (${config.model} vs ${config.small_model})`);
  }

  for (const [key, provider] of Object.entries(providers)) {
    const label = provider.name ?? key;
    const openAiCompatible =
      provider.npm === '@ai-sdk/openai-compatible' || provider.api === 'openai';
    if (!provider.id) warnings.push(`${key}: provider id is missing`);
    if (!provider.api && openAiCompatible)
      warnings.push(`${key}: api should be explicit ("openai")`);
    if (!provider.options?.baseURL) issues.push(`${key}: options.baseURL is missing`);
    if (!hasCredential(provider) && !provider.options?.baseURL?.includes('localhost')) {
      warnings.push(`${key}: no apiKey/header credential found`);
    }
    const models = provider.models ?? {};
    if (Object.keys(models).length === 0) issues.push(`${key}: no models configured`);
    for (const [modelKey, model] of Object.entries(models)) {
      if (!model.id && !model.name) issues.push(`${key}/${modelKey}: model id/name is missing`);
      if (!model.id)
        warnings.push(
          `${key}/${modelKey}: model id is missing; selector will fall back to name/key`,
        );
      if (model.tool_call !== true)
        warnings.push(`${key}/${modelKey}: tool_call is not explicitly true`);
      if (model.temperature !== true)
        warnings.push(`${key}/${modelKey}: temperature is not explicitly true`);
    }
    if (/lite|litellm|bedrock/i.test(`${key} ${label} ${provider.options?.baseURL ?? ''}`)) {
      warnings.push(
        `${key}: if this routes to Bedrock through LiteLLM, set litellm_settings.modify_params=true on the proxy`,
      );
    }
  }

  console.log(
    JSON.stringify(
      {
        status: issues.length === 0 ? 'ok' : 'fail',
        config: GLOBAL_OPENCODE_CONFIG,
        activeModel: config.model ?? null,
        activeSmallModel: config.small_model ?? null,
        providers: Object.keys(providers).length,
        issues,
        warnings,
      },
      null,
      2,
    ),
  );

  if (issues.length > 0) process.exit(1);
}

main();
