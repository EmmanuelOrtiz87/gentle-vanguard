#!/usr/bin/env node
/**
 * Token Usage Reader — single source of truth for live token budget usage.
 *
 * Centralizes reading of the live token budget so every consumer (output
 * compression, prompt compression, metrics collector, dashboard) reads the
 * SAME authoritative values instead of each guessing its own path/fields.
 *
 * Source of truth: reports/stack-live-observability-latest.json → token
 *   { status, projected_pct, used_today, budget }
 *
 * Fallbacks (in order):
 *   1. reports/stack-live-observability-latest.json  (live observability)
 *   2. .runtime/metrics/token.json                    (metrics collector output)
 *   3. config/token-budget-guard.json                 (limits only, used=0)
 *   4. defaults (used=0, budget=120000, pct=0)
 *
 * Usage:
 *   npx tsx src/token-usage-reader.ts            # human-readable
 *   npx tsx src/token-usage-reader.ts --json     # machine-readable
 */

import { existsSync, readFileSync } from 'fs';
import { join, resolve } from 'path';
import { pathToFileURL } from 'url';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface TokenUsageInfo {
  used: number;
  budget: number;
  percentage: number;
  status: string;
  source: string;
}

// ─── Paths ────────────────────────────────────────────────────────────────────

const ROOT = resolve(process.env.GENTLE_VANGUARD_BASE_DIR ?? process.cwd());

const LIVE_OBS_PATH = join(ROOT, 'reports', 'stack-live-observability-latest.json');
const METRICS_TOKEN_PATH = join(ROOT, '.runtime', 'metrics', 'token.json');
const BUDGET_CONFIG_PATH = join(ROOT, 'config', 'token-budget-guard.json');

const DEFAULT_BUDGET = 120000;

// ─── Helpers ──────────────────────────────────────────────────────────────────

function readJsonSafe(filePath: string): Record<string, unknown> | null {
  try {
    if (!existsSync(filePath)) return null;
    const raw = readFileSync(filePath, 'utf-8');
    const parsed = JSON.parse(raw);
    return parsed && typeof parsed === 'object' ? (parsed as Record<string, unknown>) : null;
  } catch {
    return null;
  }
}

function toNum(value: unknown): number {
  const n = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(n) && n >= 0 ? n : 0;
}

// ─── Core reader ──────────────────────────────────────────────────────────────

/**
 * Read the current live token usage from the single source of truth.
 * Never throws — degrades gracefully through the fallback chain.
 */
export function getTokenUsage(): TokenUsageInfo {
  // 1. Live observability (authoritative)
  const live = readJsonSafe(LIVE_OBS_PATH);
  const token = live?.token as Record<string, unknown> | undefined;
  if (token && typeof token === 'object') {
    const used = toNum(token.used_today);
    const budget = toNum(token.budget) || DEFAULT_BUDGET;
    const pct = toNum(token.projected_pct);
    return {
      used,
      budget,
      percentage: pct > 0 ? pct : budget > 0 ? (used / budget) * 100 : 0,
      status: typeof token.status === 'string' ? token.status : 'unknown',
      source: 'reports/stack-live-observability-latest.json',
    };
  }

  // 2. Metrics collector token output
  const metrics = readJsonSafe(METRICS_TOKEN_PATH);
  if (metrics) {
    const used = toNum(metrics.usedToday);
    const budget = toNum(metrics.budget) || DEFAULT_BUDGET;
    return {
      used,
      budget,
      percentage: budget > 0 ? (used / budget) * 100 : 0,
      status: typeof metrics.status === 'string' ? metrics.status : 'unknown',
      source: '.runtime/metrics/token.json',
    };
  }

  // 3. Budget config (limits only — no live usage available)
  const config = readJsonSafe(BUDGET_CONFIG_PATH);
  const tokenBudgetSection = config?.tokenBudget as
    | { limits?: Record<string, unknown> }
    | undefined;
  const limits = tokenBudgetSection?.limits;
  if (limits) {
    const budget = toNum(limits.daily) || DEFAULT_BUDGET;
    return {
      used: 0,
      budget,
      percentage: 0,
      status: 'unknown',
      source: 'config/token-budget-guard.json (limits only)',
    };
  }

  // 4. Defaults
  return {
    used: 0,
    budget: DEFAULT_BUDGET,
    percentage: 0,
    status: 'unknown',
    source: 'defaults',
  };
}

// ─── Convenience helpers ──────────────────────────────────────────────────────

/** Percentage of daily budget used (0..100). */
export function getTokenBudgetPercentage(): number {
  return getTokenUsage().percentage;
}

/** True when the live token source is actually populated (not a fallback). */
export function isTokenUsageReal(): boolean {
  const usage = getTokenUsage();
  return usage.source === 'reports/stack-live-observability-latest.json';
}

// ─── CLI ──────────────────────────────────────────────────────────────────────

function main(): void {
  const jsonFlag = process.argv.includes('--json');
  const usage = getTokenUsage();

  if (jsonFlag) {
    console.log(JSON.stringify(usage, null, 2));
    return;
  }

  console.log('Token Usage (single source of truth)');
  console.log('-------------------------------------');
  console.log(`  Used:        ${usage.used.toLocaleString()} tokens`);
  console.log(`  Budget:      ${usage.budget.toLocaleString()} tokens`);
  console.log(`  Percentage:  ${usage.percentage.toFixed(2)}%`);
  console.log(`  Status:      ${usage.status}`);
  console.log(`  Source:      ${usage.source}`);
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url) {
  main();
}