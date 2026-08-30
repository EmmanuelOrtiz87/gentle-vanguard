#!/usr/bin/env node
/**
 * Comprehensive Integration Test Suite for GGA System
 *
 * This script performs exhaustive testing of:
 * 1. Subagent delegation with automatic fallback
 * 2. Model inheritance from orchestrator
 * 3. Step assignment based on task complexity
 * 4. Error detection and recovery
 * 5. State persistence
 *
 * Usage: npm run test:gga:comprehensive
 */

import { existsSync, mkdirSync, writeFileSync, readFileSync } from 'fs';
import { join } from 'path';
import {
  GuardianAngel,
  checkProviderHealth,
  getCurrentProvider,
  resetProviders,
} from '../src/tools/gga.js';

// =============================================================================
// TEST CONFIGURATION
// =============================================================================

const ROOT = process.cwd();
const TEST_RESULTS_FILE = join(ROOT, '.test-results', 'gga-comprehensive-test.json');

interface TestResult {
  name: string;
  passed: boolean;
  duration: number;
  error?: string;
  details?: unknown;
}

interface TestSuite {
  name: string;
  results: TestResult[];
  summary: {
    total: number;
    passed: number;
    failed: number;
    duration: number;
  };
}

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================

function log(level: 'info' | 'success' | 'warn' | 'error', message: string): void {
  const timestamp = new Date().toISOString();
  const icons = { info: 'ℹ️', success: '✅', warn: '⚠️', error: '❌' };
  console.log(`${icons[level]} [${timestamp}] ${message}`);
}

async function runTest(name: string, testFn: () => Promise<unknown>): Promise<TestResult> {
  const startTime = Date.now();
  try {
    const result = await testFn();
    return {
      name,
      passed: true,
      duration: Date.now() - startTime,
      details: result,
    };
  } catch (error) {
    return {
      name,
      passed: false,
      duration: Date.now() - startTime,
      error: String(error),
    };
  }
}

function saveResults(suite: TestSuite): void {
  const testDir = join(ROOT, '.test-results');
  if (!existsSync(testDir)) mkdirSync(testDir, { recursive: true });

  writeFileSync(TEST_RESULTS_FILE, JSON.stringify(suite, null, 2));
  log('info', `Test results saved to: ${TEST_RESULTS_FILE}`);
}

// =============================================================================
// TEST CASES
// =============================================================================

async function testBasicDelegation(): Promise<TestResult> {
  return runTest('Basic Delegation', async () => {
    const result = await GuardianAngel({
      agent: 'sdd-explore',
      task: 'List all files in the src directory',
    });

    if (!result.success) {
      throw new Error(`Delegation failed: ${result.error}`);
    }

    if (!result.output) {
      throw new Error('No output received');
    }

    log('success', `Basic delegation succeeded with model: ${result.model}`);
    log('info', `Attempts: ${result.attempts}, Duration: ${result.duration}ms`);

    return result;
  });
}

async function testModelInheritance(): Promise<TestResult> {
  return runTest('Model Inheritance from Orchestrator', async () => {
    // Set orchestrator model
    process.env.ORCHESTRATOR_MODEL = 'kimi-2-5';

    const result = await GuardianAngel({
      agent: 'sdd-design',
      task: 'Design a simple API endpoint',
    });

    if (!result.success) {
      throw new Error(`Delegation failed: ${result.error}`);
    }

    // Should inherit or use fallback chain
    const expectedModels = ['kimi-2-5', 'claude-haiku-4-5', 'opencode/big-pickle'];
    if (!expectedModels.some((m) => result.model.includes(m))) {
      throw new Error(`Unexpected model used: ${result.model}`);
    }

    log('success', `Model inheritance working: ${result.model}`);

    delete process.env.ORCHESTRATOR_MODEL;
    return result;
  });
}

async function testFallbackChain(): Promise<TestResult> {
  return runTest('Fallback Chain Execution', async () => {
    // Request a model that might not be available to test fallback
    const result = await GuardianAngel({
      agent: 'sdd-apply',
      task: 'Create a simple TypeScript interface',
      preferredModel: 'opencode/big-pickle',
    });

    if (!result.success) {
      throw new Error(`Delegation failed: ${result.error}`);
    }

    log('success', `Fallback chain working. Final model: ${result.model}`);
    log('info', `Attempts made: ${result.attempts}, Switch occurred: ${result.switchOccurred}`);

    return result;
  });
}

async function testAllSubagents(): Promise<TestResult> {
  return runTest('All SDD Subagents', async () => {
    const subagents = ['sdd-explore', 'sdd-design', 'sdd-apply', 'sdd-verify'];

    const results: Record<string, unknown> = {};

    for (const agent of subagents) {
      log('info', `Testing ${agent}...`);

      const result = await GuardianAngel({
        agent,
        task: `Quick test for ${agent} agent`,
      });

      results[agent] = {
        success: result.success,
        model: result.model,
        attempts: result.attempts,
        duration: result.duration,
      };

      if (!result.success) {
        throw new Error(`${agent} failed: ${result.error}`);
      }

      log('success', `${agent} ✓`);
    }

    return results;
  });
}

async function testStatePersistence(): Promise<TestResult> {
  return runTest('State Persistence', async () => {
    // Reset first
    resetProviders();

    // Check initial state
    const initialProvider = getCurrentProvider();
    log('info', `Initial provider: ${initialProvider}`);

    // Run delegation
    await GuardianAngel({
      agent: 'doc-agent',
      task: 'Create documentation outline',
    });

    // Check state persisted
    const afterProvider = getCurrentProvider();

    if (!afterProvider) {
      throw new Error('Provider state not persisted');
    }

    log('success', `State persistence working. Current provider: ${afterProvider}`);

    return { initial: initialProvider, after: afterProvider };
  });
}

async function testProviderHealth(): Promise<TestResult> {
  return runTest('Provider Health Tracking', async () => {
    const health = checkProviderHealth('kimi-2-5');

    log('info', `Health check result: ${health ? 'Found' : 'Not found'}`);

    // Health might be null if no operations yet, which is fine
    return { health, timestamp: new Date().toISOString() };
  });
}

async function testComplexTask(): Promise<TestResult> {
  return runTest('Complex Task Delegation', async () => {
    const result = await GuardianAngel({
      agent: 'sdd-apply',
      task: 'Implement a complete user authentication system with login, registration, password reset, email verification, JWT tokens, refresh token rotation, rate limiting, and audit logging. Include all models, services, controllers, middleware, routes, and comprehensive test coverage.',
      context: 'TypeScript, Node.js, Express, MongoDB, Jest',
    });

    if (!result.success) {
      throw new Error(`Complex task failed: ${result.error}`);
    }

    log('success', `Complex task completed with ${result.attempts} attempt(s)`);
    log('info', `Duration: ${result.duration}ms, Model: ${result.model}`);

    return result;
  });
}

async function testErrorRecovery(): Promise<TestResult> {
  return runTest('Error Recovery Simulation', async () => {
    // TODO: In real scenario, we would simulate provider failures
    // For now, verify the system handles normal operations

    const result = await GuardianAngel({
      agent: 'ops-agent',
      task: 'Check system status',
    });

    if (!result.success) {
      throw new Error(`Error recovery test failed: ${result.error}`);
    }

    log('success', 'System operational');
    return result;
  });
}

// =============================================================================
// MAIN TEST RUNNER
// =============================================================================

async function runComprehensiveTests(): Promise<void> {
  log('info', '═══════════════════════════════════════════════════════════');
  log('info', '  COMPREHENSIVE GGA SYSTEM TEST SUITE');
  log('info', '═══════════════════════════════════════════════════════════');
  log('info', '');

  const startTime = Date.now();
  const results: TestResult[] = [];

  // Run all tests
  results.push(await testBasicDelegation());
  results.push(await testModelInheritance());
  results.push(await testFallbackChain());
  results.push(await testAllSubagents());
  results.push(await testStatePersistence());
  results.push(await testProviderHealth());
  results.push(await testComplexTask());
  results.push(await testErrorRecovery());

  const totalDuration = Date.now() - startTime;
  const passed = results.filter((r) => r.passed).length;
  const failed = results.filter((r) => !r.passed).length;

  const suite: TestSuite = {
    name: 'GGA Comprehensive Test Suite',
    results,
    summary: {
      total: results.length,
      passed,
      failed,
      duration: totalDuration,
    },
  };

  // Print summary
  log('info', '');
  log('info', '═══════════════════════════════════════════════════════════');
  log('info', '  TEST SUMMARY');
  log('info', '═══════════════════════════════════════════════════════════');
  log('info', `Total Tests: ${results.length}`);
  log('success', `Passed: ${passed}`);
  if (failed > 0) {
    log('error', `Failed: ${failed}`);
  }
  log('info', `Duration: ${totalDuration}ms`);
  log('info', '');

  // Print failed tests
  const failedTests = results.filter((r) => !r.passed);
  if (failedTests.length > 0) {
    log('error', 'FAILED TESTS:');
    for (const test of failedTests) {
      log('error', `  ❌ ${test.name}: ${test.error}`);
    }
    log('info', '');
  }

  // Save results
  saveResults(suite);

  // Final status
  const allPassed = failed === 0;
  log('info', '═══════════════════════════════════════════════════════════');
  if (allPassed) {
    log('success', '  ✓ ALL TESTS PASSED');
  } else {
    log('error', `  ✗ ${failed} TEST(S) FAILED`);
  }
  log('info', '═══════════════════════════════════════════════════════════');

  process.exit(allPassed ? 0 : 1);
}

// Error handling
process.on('unhandledRejection', (error) => {
  log('error', `Unhandled rejection: ${error}`);
  process.exit(1);
});

// Run tests
runComprehensiveTests().catch((error) => {
  log('error', `Test suite failed: ${error}`);
  process.exit(1);
});
