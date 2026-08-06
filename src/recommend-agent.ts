#!/usr/bin/env node
/**
 * Recommend Agent — Auto-reassignment bridge for the orchestrator.
 *
 * Consults the adaptive routing table (.session/routing/routing-table.json),
 * built by src/adaptive-router.ts from historical execution data, and returns
 * the best agent for a task domain. Enables AUTOMATIC reassignment based on
 * learned performance instead of static/manual routing.
 *
 * Usage:
 *   npx tsx src/recommend-agent.ts --domain "code-review"
 *   npx tsx src/recommend-agent.ts --task "fix broken ps1 references" --topn 3
 *   npx tsx src/recommend-agent.ts --refresh        # rebuild routing table first
 *   npx tsx src/recommend-agent.ts --fallback-check # verify fallback logic
 *
 * Output (JSON): { domain, recommended, confidence, alternatives[], source }
 */

import { existsSync, readFileSync } from 'fs';
import { join, resolve } from 'path';
import { pathToFileURL } from 'url';
import { runNpxTsxSync } from './core/run-command.js';

const ROOT = resolve(process.cwd());
const ROUTING_TABLE = join(ROOT, '.session', 'routing', 'routing-table.json');
const STATIC_MAP: Record<string, string[]> = {
  'code-review': ['sdd-verify', 'gov-agent', 'sdd-apply'],
  'code-apply': ['sdd-apply', 'sdd-design', 'sdd-verify'],
  requirements: ['sdd-explore', 'session-agent', 'knowledge-agent'],
  architecture: ['sdd-design', 'sdd-explore', 'premortem-agent'],
  testing: ['sdd-verify', 'sdd-apply', 'self-diag-agent'],
  docs: ['doc-agent', 'technical-writer', 'knowledge-agent'],
  ops: ['ops-agent', 'maintenance-agent', 'self-diag-agent'],
  security: ['gov-agent', 'legal-agent', 'premortem-agent'],
  governance: ['gov-agent', 'legal-agent', 'doc-agent'],
  session: ['session-agent', 'maintenance-agent', 'sdd-verify'],
  general: ['sdd-apply', 'explore', 'general'],
};

interface RoutingTable {
  domainEntries?: Array<{
    domain: string;
    bestAgent: string;
    alternatives?: Array<{ agentId: string; successRate: number }>;
    confidence: number;
  }>;
  overrides?: Array<{
    domainPattern: string;
    targetAgent: string;
    confidence: number;
  }>;
}

function loadRoutingTable(): RoutingTable | null {
  try {
    if (!existsSync(ROUTING_TABLE)) return null;
    return JSON.parse(readFileSync(ROUTING_TABLE, 'utf-8')) as RoutingTable;
  } catch {
    return null;
  }
}

function matchDomain(task: string, domainHint: string): string {
  const normalized = task.toLowerCase();
  const pairs: Array<[string, string]> = [
    ['review', 'code-review'],
    ['refactor', 'code-apply'],
    ['implement', 'code-apply'],
    ['feature', 'code-apply'],
    ['requirement', 'requirements'],
    ['analy', 'requirements'],
    ['architect', 'architecture'],
    ['design', 'architecture'],
    ['test', 'testing'],
    ['doc', 'docs'],
    ['deploy', 'ops'],
    ['infra', 'ops'],
    ['secur', 'security'],
    ['audit', 'governance'],
    ['compliance', 'governance'],
    ['session', 'session'],
  ];
  if (domainHint) return domainHint;
  for (const [kw, domain] of pairs) {
    if (normalized.includes(kw)) return domain;
  }
  return 'general';
}

function recommend(task: string, domainHint: string, topN: number): unknown {
  const domain = matchDomain(task, domainHint);
  const table = loadRoutingTable();

  // 1. Check overrides (highest priority — learned routing)
  if (table?.overrides) {
    for (const o of table.overrides) {
      if (
        domain.toLowerCase().includes(o.domainPattern.toLowerCase()) ||
        o.domainPattern.toLowerCase().includes(domain.toLowerCase())
      ) {
        return {
          domain,
          recommended: o.targetAgent,
          confidence: o.confidence,
          alternatives: [],
          source: 'override',
        };
      }
    }
  }

  // 2. Check domain entries (learned performance)
  if (table?.domainEntries) {
    const entry = table.domainEntries.find((d) => d.domain.toLowerCase() === domain.toLowerCase());
    if (entry && entry.bestAgent) {
      return {
        domain,
        recommended: entry.bestAgent,
        confidence: entry.confidence,
        alternatives: (entry.alternatives || []).map((a) => a.agentId).slice(0, topN - 1),
        source: 'routing-table',
      };
    }
  }

  // 3. Fallback: static map (cold start)
  const candidates = STATIC_MAP[domain] || STATIC_MAP.general;
  return {
    domain,
    recommended: candidates[0],
    confidence: 0.3,
    alternatives: candidates.slice(1, topN),
    source: 'static-fallback',
  };
}

function parseArgs(argv: string[]): {
  task: string;
  domain: string;
  topN: number;
  refresh: boolean;
} {
  const args = { task: '', domain: '', topN: 3, refresh: false };
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === '--task' && argv[i + 1]) args.task = argv[++i];
    else if (argv[i] === '--domain' && argv[i + 1]) args.domain = argv[++i];
    else if (argv[i] === '--topn' && argv[i + 1]) args.topN = Number(argv[++i]);
    else if (argv[i] === '--refresh') args.refresh = true;
  }
  return args;
}

function main(): void {
  const { task, domain, topN, refresh } = parseArgs(process.argv);

  if (refresh) {
    try {
      runNpxTsxSync('src/adaptive-router.ts', ['--build', '--quiet'], {
        cwd: ROOT,
        stdio: 'pipe',
        timeout: 30000,
      });
    } catch {
      // refresh failure is non-blocking
    }
  }

  const result = recommend(task, domain, topN);
  console.log(JSON.stringify(result, null, 2));
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}

export { recommend };
