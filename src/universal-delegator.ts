#!/usr/bin/env npx tsx
/**
 * Universal Delegator with GGA Fallback
 * 
 * Drop-in replacement for opencode's task() that uses GGA (Guardian Angel)
 * for automatic model fallback on quota/credit errors.
 * 
 * Usage:
 *   npx tsx src/universal-delegator.ts --agent sdd-apply --task "implement feature"
 *   npx tsx src/universal-delegator.ts --agent sdd-explore --task "analyze requirements"
 * 
 * This script integrates GGA into the real orchestrator delegation flow.
 */

import { spawn } from 'child_process';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

// =============================================================================
// CONSTANTS
// =============================================================================

const ROOT = process.cwd();
const AGENTS_DIR = join(ROOT, 'src', 'agents');

// Legacy: fallback chain for when GGA health is not available
const FALLBACK_CHAIN = [
  'kimi-2-5',
  'claude-haiku-4-5',
  'opencode/deepseek-v4-flash-free',
  'ollama/qwen2.5-coder:14b',
];

// Error patterns that trigger fallback
const FALLBACK_ERRORS = [
  'Free usage exceeded',
  'subscribe to Go',
  'quota exceeded',
  'credits exhausted',
  'rate limit exceeded',
  '429 Too Many Requests',
  'insufficient_quota',
  'Model not found',
  'ProviderModelNotFoundError',
  'AuthenticationError',
  'unauthorized',
  'invalid api key',
  'APIConnectionError',
  'inherit-from-session',
  'timeout',
];

// =============================================================================
// TYPES
// =============================================================================

interface DelegationOptions {
  agent: string;
  task: string;
  context?: string;
  model?: string;
  temperature?: number;
}

interface DelegationResult {
  success: boolean;
  output?: string;
  error?: string;
  duration: number;
  model: string;
  fallbackUsed: boolean;
  attempts: number;
}

// =============================================================================
// GGA INTEGRATION
// =============================================================================

function loadGGAState(): { currentProvider: string; exhaustedProviders: string[] } | null {
  const ggaStateFile = join(ROOT, '.runtime', 'gga-state.json');
  try {
    if (existsSync(ggaStateFile)) {
      return JSON.parse(readFileSync(ggaStateFile, 'utf-8'));
    }
  } catch {
    console.log('[WARNING] Could not load GGA state, using defaults');
  }
  return null;
}

function getOrchestratorModel(): string {
  // Priority order:
  // 1. Environment variable
  // 2. GGA state
  // 3. model-active.json
  // 4. Default: kimi-2-5
  
  const envModel = process.env.ORCHESTRATOR_MODEL || process.env.SESSION_MODEL || process.env.AGENT_MODEL;
  if (envModel) return envModel;
  
  const ggaState = loadGGAState();
  if (ggaState?.currentProvider) return ggaState.currentProvider;
  
  const activeModelFile = join(ROOT, '.runtime', 'model-active.json');
  try {
    if (existsSync(activeModelFile)) {
      const content = JSON.parse(readFileSync(activeModelFile, 'utf-8'));
      if (content.model) return content.model;
    }
  } catch {
    // Fall through
  }
  
  return 'kimi-2-5'; // Updated default after configuration changes
}

function shouldFallback(error: string): boolean {
  const normalized = error.toLowerCase();
  return FALLBACK_ERRORS.some(pattern => normalized.includes(pattern.toLowerCase()));
}

function buildFallbackChain(): string[] {
  const orchestratorModel = getOrchestratorModel();
  const chain: string[] = [];
  
  // Priority 1: Orchestrator model
  if (orchestratorModel) chain.push(orchestratorModel);
  
  // Priority 2: Legacy fallback chain (excluding orchestrator if already present)
  for (const model of FALLBACK_CHAIN) {
    if (!chain.includes(model)) chain.push(model);
  }
  
  return chain;
}

// =============================================================================
// CORE DELEGATION
// =============================================================================

function getAgentScriptPath(agentName: string): string | null {
  const scriptPath = join(AGENTS_DIR, `${agentName}.ts`);
  return existsSync(scriptPath) ? scriptPath : null;
}

async function delegateWithModel(
  options: DelegationOptions,
  model: string
): Promise<DelegationResult> {
  const startTime = Date.now();
  
  const scriptPath = getAgentScriptPath(options.agent);
  
  if (!scriptPath) {
    return {
      success: false,
      error: `Agent not found: ${options.agent}. Create src/agents/${options.agent}.ts`,
      duration: Date.now() - startTime,
      model,
      fallbackUsed: false,
      attempts: 1,
    };
  }
  
  return new Promise((resolve) => {
    const args = [
      'tsx',
      scriptPath,
      '--task', options.task,
      '--model', model,
    ];
    
    if (options.context) {
      args.push('--context', options.context);
    }
    
    const child = spawn('npx.cmd', args, {
      cwd: ROOT,
      shell: true,
      windowsHide: true,
      env: {
        ...process.env,
        AGENT_MODEL: model,
        FORCE_MODEL: model,
        AGENT_TEMPERATURE: String(options.temperature || 0.3),
        DELEGATION_MODE: 'universal',
      },
      timeout: 300000, // 5 minutes
    });
    
    let stdout = '';
    let stderr = '';
    
    child.stdout.on('data', (data) => {
      stdout += data.toString();
    });
    
    child.stderr.on('data', (data) => {
      stderr += data.toString();
    });
    
    child.on('close', (code) => {
      const duration = Date.now() - startTime;
      
      if (code === 0) {
        resolve({
          success: true,
          output: stdout.trim(),
          duration,
          model,
          fallbackUsed: false,
          attempts: 1,
        });
      } else {
        const error = stderr.trim() || stdout.trim() || `Exit code: ${code}`;
        // Check if it's a fallback-triggering error
        if (shouldFallback(error)) {
          // Return a special marker so caller knows to retry
          resolve({
            success: false,
            error: `FALLBACK_TRIGGERED: ${error}`,
            duration,
            model,
            fallbackUsed: false,
            attempts: 1,
          });
        } else {
          resolve({
            success: false,
            error,
            duration,
            model,
            fallbackUsed: false,
            attempts: 1,
          });
        }
      }
    });
    
    child.on('error', (error) => {
      resolve({
        success: false,
        error: error.message,
        duration: Date.now() - startTime,
        model,
        fallbackUsed: false,
        attempts: 1,
      });
    });
  });
}

/**
 * Main delegation function with automatic model fallback.
 * This is the function the orchestrator should call instead of raw task().
 */
export async function delegateWithFallback(options: DelegationOptions): Promise<DelegationResult> {
  const startTime = Date.now();
  const fallbackChain = buildFallbackChain();
  
  console.log(`[Universal Delegator] Agent: ${options.agent}`);
  console.log(`[Universal Delegator] Task: ${options.task.substring(0, 50)}...`);
  console.log(`[Universal Delegator] Fallback chain: ${fallbackChain.join(' → ')}`);
  
  for (let i = 0; i < fallbackChain.length; i++) {
    const model = fallbackChain[i];
    const isRetry = i > 0;
    
    if (isRetry) {
      console.log(`[Universal Delegator] Retrying with fallback model: ${model}...`);
    } else {
      console.log(`[Universal Delegator] Attempting with primary model: ${model}...`);
    }
    
    const result = await delegateWithModel(options, model);
    
    if (result.success) {
      console.log(`[Universal Delegator] ✓ Success with model: ${model}`);
      return {
        ...result,
        fallbackUsed: isRetry,
        attempts: i + 1,
      };
    }
    
    // If it's a fallback-triggering error, continue to next model
    if (result.error?.startsWith('FALLBACK_TRIGGERED:')) {
      console.log(`[Universal Delegator] Model ${model} failed (quota/limit). Trying next...`);
      continue;
    }
    
    // Non-fallback error (e.g., code error, logic error)
    console.log(`[Universal Delegator] Model ${model} failed (non-retriable): ${result.error}`);
    return {
      ...result,
      fallbackUsed: isRetry,
      attempts: i + 1,
    };
  }
  
  // All models exhausted
  const finalError = `[Universal Delegator] All models exhausted. Chain: ${fallbackChain.join(' → ')}`;
  console.error(finalError);
  
  return {
    success: false,
    error: finalError,
    duration: Date.now() - startTime,
    model: 'none',
    fallbackUsed: true,
    attempts: fallbackChain.length,
  };
}

// =============================================================================
// CLI
// =============================================================================

function printUsage(): void {
  console.log(`
Universal Delegator with GGA Fallback
=====================================

Usage:
  npx tsx src/universal-delegator.ts --agent <name> --task "<description>"

Options:
  --agent <name>      Agent to delegate to (sdd-apply, sdd-explore, etc.)
  --task "..."        Task description
  --context "..."     Optional additional context
  --model <model>     Force specific model (skip fallback)
  --temperature N     Temperature for generation (default: 0.3)

Examples:
  npx tsx src/universal-delegator.ts --agent sdd-apply --task "fix bug in auth"
  npx tsx src/universal-delegator.ts --agent sdd-explore --task "analyze requirements" --context "legacy system"

Model Fallback Chain:
  1. Current orchestrator model (e.g., kimi-2-5)
  2. claude-haiku-4-5
  3. opencode/deepseek-v4-flash-free
  4. ollama/qwen2.5-coder:14b

Integration:
  Import and use delegateWithFallback() instead of task():
  
  import { delegateWithFallback } from './universal-delegator.js';
  
  const result = await delegateWithFallback({
    agent: 'sdd-apply',
    task: 'implement feature',
  });
`);
}

// =============================================================================
// MAIN
// =============================================================================

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  
  // Parse arguments
  let agentName: string | undefined;
  let task: string | undefined;
  let context: string | undefined;
  let temperature: number | undefined;
  
  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--agent':
        agentName = args[++i];
        break;
      case '--task':
        task = args[++i];
        break;
      case '--context':
        context = args[++i];
        break;
      case '--temperature':
        temperature = parseFloat(args[++i]);
        break;
      case '--help':
      case '-h':
        printUsage();
        process.exit(0);
        break;
    }
  }
  
  if (!agentName || !task) {
    console.error('Error: Both --agent and --task are required');
    printUsage();
    process.exit(1);
  }
  
  void (async () => {
    const result = await delegateWithFallback({
      agent: agentName,
      task,
      context,
      temperature,
    });
    
    console.log('\n=== RESULT ===\n');
    console.log(JSON.stringify(result, null, 2));
    
    if (!result.success) {
      process.exit(1);
    }
  })();
}
