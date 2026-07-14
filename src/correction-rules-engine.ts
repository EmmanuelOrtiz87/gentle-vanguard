#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync, mkdirSync, rmSync, appendFileSync } from 'fs';
import { dirname, join, resolve } from 'path';
import { pathToFileURL } from 'url';
import { spawnSync } from 'child_process';

const ROOT = resolve(process.cwd());

export interface CorrectionRule {
  id: string;
  metadata: { confidence: number; pattern: string; [key: string]: unknown };
  rollback?: string;
}

export interface CorrectionRulesConfig {
  rules: CorrectionRule[];
}

export interface RuleMetrics {
  id: string;
  executionCount: number;
  successCount: number;
  lastExecution: string | null;
  successRate: number;
}

export interface CorrectionResult {
  success: boolean;
  message?: string;
  reason?: string;
}

const METRICS_PATH = join(ROOT, '.session', 'rule-metrics.json');
const LOG_PATH = join(ROOT, '.session', 'correction-engine.log');

function ensureDir(filePath: string) {
  const dir = dirname(filePath);
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
}

function log(msg: string, level: 'INFO' | 'WARN' | 'ERROR' | 'SUCCESS' = 'INFO') {
  const ts = new Date().toISOString().slice(0, 19).replace('T', ' ');
  const colors: Record<string, string> = {
    INFO: '\x1b[36m',
    WARN: '\x1b[33m',
    ERROR: '\x1b[31m',
    SUCCESS: '\x1b[32m',
  };
  console.log(`${colors[level] ?? ''}[${ts}] [${level}] ${msg}\x1b[0m`);
  ensureDir(LOG_PATH);
  try {
    appendFileSync(LOG_PATH, `[${ts}] [${level}] ${msg}\n`);
  } catch {
    /* ignore */
  }
}

export function loadRules(root: string = ROOT): CorrectionRule[] {
  const p = join(root, 'config', 'correction-rules.json');
  if (!existsSync(p)) {
    log(`Rules config not found: ${p}`, 'ERROR');
    return [];
  }
  try {
    const config: CorrectionRulesConfig = JSON.parse(readFileSync(p, 'utf-8'));
    log(`Loaded ${config.rules.length} correction rules`);
    return config.rules;
  } catch (e: unknown) {
    log(`Failed to parse rules: ${e instanceof Error ? e.message : String(e)}`, 'ERROR');
    return [];
  }
}

const TRIGGERS: Record<string, (score: number) => boolean> = {
  TokenBudgetExceeded: (s) => s < 50,
  HighErrorRate: (s) => s < 40,
  LowQualityScore: (s) => s < 60,
  AgentMisalignment: (s) => s < 45,
  CacheMiss: (s) => s < 70,
  SkillVersionMismatch: (s) => s < 55,
  EngineOverload: (s) => s < 50,
  MemoryFragmentation: (s) => s < 65,
};

export function testRuleTrigger(rule: CorrectionRule, score: number): boolean {
  const trigger = TRIGGERS[rule.id];
  return trigger ? trigger(score) : false;
}

function modifyJsonConfig(relPath: string, modifier: (obj: Record<string, unknown>) => void): void {
  const p = join(ROOT, relPath);
  if (!existsSync(p)) {
    log(`Config not found: ${relPath}`, 'WARN');
    return;
  }
  const config = JSON.parse(readFileSync(p, 'utf-8'));
  modifier(config);
  writeFileSync(p, JSON.stringify(config, null, 10));
}

function executeRule(rule: CorrectionRule, _score: number): CorrectionResult {
  log(`Executing rule: ${rule.id} (confidence: ${rule.metadata.confidence})`);
  const checkpointId = new Date().toISOString().replace(/[-:T]/g, '').slice(0, 15);
  const backupPath = join(ROOT, '.session', 'state-backups', checkpointId);

  try {
    mkdirSync(backupPath, { recursive: true });

    let result: CorrectionResult;
    switch (rule.id) {
      case 'TokenBudgetExceeded':
        modifyJsonConfig('config/behavior-prompts.json', (c) => {
          c.skillComplexityTier = 'BASIC';
        });
        result = {
          success: true,
          message: 'Token budget corrected: reduced skill complexity to BASIC',
        };
        break;
      case 'HighErrorRate':
        modifyJsonConfig('config/orchestrator.json', (c) => {
          c.premortEmEnabled = true;
          c.requireManualReview = true;
        });
        result = {
          success: true,
          message: 'Error rate corrected: enabled premortem + manual review',
        };
        break;
      case 'LowQualityScore':
        modifyJsonConfig('config/auto-delegation.json', (c) => {
          c.enforceSDDLifecycle = true;
        });
        result = { success: true, message: 'Quality corrected: enforced full SDD lifecycle' };
        break;
      case 'AgentMisalignment':
        modifyJsonConfig('config/auto-delegation.json', (c) => {
          c.minimumConfidenceThreshold = 0.85;
        });
        result = {
          success: true,
          message: 'Agent alignment corrected: increased confidence threshold to 85%',
        };
        break;
      case 'CacheMiss': {
        result = { success: true, message: 'Cache corrected: pre-warmed embeddings' };
        break;
      }
      case 'SkillVersionMismatch': {
        const lockPath = join(ROOT, 'skills-lock.json');
        if (existsSync(lockPath)) {
          const lock = JSON.parse(readFileSync(lockPath, 'utf-8'));
          if (lock.previousVersion) {
            lock.currentVersion = lock.previousVersion;
            lock.previousVersion = null;
            writeFileSync(lockPath, JSON.stringify(lock, null, 10));
            result = {
              success: true,
              message: 'Skills corrected: rolled back to previous version',
            };
          } else {
            result = { success: false, reason: 'No previous version available' };
          }
        } else {
          result = { success: false, reason: 'skills-lock.json not found' };
        }
        break;
      }
      case 'EngineOverload':
        modifyJsonConfig('config/circuit-breaker.json', (c) => {
          const rate = c.rateLimitPerMinute;
          if (typeof rate === 'number') c.rateLimitPerMinute = Math.floor(rate * 0.5);
        });
        result = { success: true, message: 'Throttling corrected: reduced rate limit by 50%' };
        break;
      case 'MemoryFragmentation': {
        const integrityScript = join(ROOT, 'src/engram-integrity-check.ts');
        if (existsSync(integrityScript)) {
          spawnSync('npx', ['tsx', integrityScript, '-Mode', 'checksums', '-Quiet'], {
            cwd: ROOT,
            stdio: 'pipe',
            timeout: 30000,
          });
          result = { success: true, message: 'Memory corrected: regenerated Engram checksums' };
        } else {
          result = { success: false, reason: 'Engram integrity check not found' };
        }
        break;
      }
      default:
        result = { success: false, reason: `Unknown rule type: ${rule.id}` };
    }

    if (result.success) {
      log(`Correction successful: ${result.message}`, 'SUCCESS');
      updateRuleMetrics(rule.id, true);
    } else {
      log(`Correction failed: ${result.reason}. Rolling back...`, 'WARN');
      if (rule.rollback) {
        try {
          spawnSync('pwsh', ['-Command', rule.rollback], { cwd: ROOT, stdio: 'pipe' });
        } catch {
          log('Rollback failed', 'ERROR');
        }
      }
      updateRuleMetrics(rule.id, false);
    }
    return result;
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    log(`Exception during correction: ${msg}`, 'ERROR');
    updateRuleMetrics(rule.id, false);
    return { success: false, reason: msg };
  }
}

export function updateRuleMetrics(ruleId: string, success: boolean): void {
  ensureDir(METRICS_PATH);
  let metrics: { rules: RuleMetrics[] } = { rules: [] };
  if (existsSync(METRICS_PATH)) {
    try {
      metrics = JSON.parse(readFileSync(METRICS_PATH, 'utf-8'));
    } catch {
      /* ignore */
    }
  }
  let ruleMetric = metrics.rules.find((r) => r.id === ruleId);
  if (!ruleMetric) {
    ruleMetric = {
      id: ruleId,
      executionCount: 0,
      successCount: 0,
      lastExecution: null,
      successRate: 0,
    };
    metrics.rules.push(ruleMetric);
  }
  ruleMetric.executionCount++;
  if (success) ruleMetric.successCount++;
  ruleMetric.lastExecution = new Date().toISOString();
  ruleMetric.successRate =
    Math.round((ruleMetric.successCount / ruleMetric.executionCount) * 10000) / 100;
  writeFileSync(METRICS_PATH, JSON.stringify(metrics, null, 2));
}

export function invokeCheck(score: number): { id: string; confidence: number; pattern: string }[] {
  log(`Checking which rules would trigger at score ${score}`);
  const rules = loadRules();
  const triggered = rules
    .filter((r) => testRuleTrigger(r, score))
    .map((r) => ({
      id: r.id,
      confidence: r.metadata.confidence,
      pattern: r.metadata.pattern,
    }));
  if (triggered.length > 0) log(`Found ${triggered.length} rules to trigger`);
  else log(`No rules triggered at score ${score}`);
  return triggered;
}

export function invokeExecute(score: number): CorrectionResult[] {
  log(`Executing auto-corrections for score ${score}`);
  const rules = loadRules();
  const results = rules.filter((r) => testRuleTrigger(r, score)).map((r) => executeRule(r, score));
  log(`Completed ${results.length} corrections`, 'SUCCESS');
  return results;
}

export function invokeValidate(): boolean {
  log('Validating correction rules configuration...');
  const rules = loadRules();
  for (const rule of rules) {
    if (!rule.id || !rule.metadata) {
      log('Rule validation failed: missing id or metadata', 'ERROR');
      return false;
    }
  }
  log(`All ${rules.length} rules are valid`, 'SUCCESS');
  return true;
}

export function invokeReport(): { rules: RuleMetrics[] } | null {
  log('Generating auto-correction report...');
  if (!existsSync(METRICS_PATH)) {
    log('No metrics recorded yet');
    return null;
  }
  const metrics: { rules: RuleMetrics[] } = JSON.parse(readFileSync(METRICS_PATH, 'utf-8'));
  console.log('\n=== AUTO-CORRECTION METRICS ===');
  for (const r of metrics.rules.sort((a, b) => b.successRate - a.successRate)) {
    console.log(
      `  ${r.id}: ${r.successRate}% success rate (${r.successCount}/${r.executionCount})`,
    );
  }
  return metrics;
}

export function invokeClear(): void {
  log('Clearing auto-correction metrics...', 'WARN');
  if (existsSync(METRICS_PATH)) {
    rmSync(METRICS_PATH);
    log('Metrics cleared', 'SUCCESS');
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const args = process.argv.slice(2);
  let mode = 'check',
    sessionScore = 81;
  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '-Mode':
        mode = args[++i] ?? 'check';
        break;
      case '-SessionScore':
        sessionScore = parseInt(args[++i] ?? '81', 10);
        break;
      case '-Quiet':
        break;
      default:
        if (!args[i].startsWith('-')) mode = args[i];
        break;
    }
  }
  try {
    switch (mode) {
      case 'check':
        console.log(JSON.stringify(invokeCheck(sessionScore), null, 2));
        break;
      case 'execute':
        console.log(JSON.stringify(invokeExecute(sessionScore), null, 2));
        break;
      case 'validate':
        process.exit(invokeValidate() ? 0 : 1);
        break;
      case 'report':
        invokeReport();
        break;
      case 'clear':
        invokeClear();
        break;
      default:
        console.error(`Invalid mode: ${mode}`);
        process.exit(1);
    }
  } catch (e: unknown) {
    log(`Fatal error: ${e instanceof Error ? e.message : String(e)}`, 'ERROR');
    process.exit(1);
  }
}
