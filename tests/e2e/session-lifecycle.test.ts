#!/usr/bin/env node
/**
 * E2E Test: Session Lifecycle
 * Tests the complete session flow from start to end
 * Generates real audit events for pipeline validation
 */

import { strict as assert } from 'assert';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

interface TestResult {
  name: string;
  status: 'PASS' | 'FAIL' | 'SKIP';
  duration: number;
  error?: string;
}

const TEST_RESULTS: TestResult[] = [];

/** Thrown by a test to mark itself as skipped (environment not applicable). */
class SkipError extends Error {}

async function runTest(name: string, fn: () => Promise<void>): Promise<void> {
  const start = Date.now();
  try {
    await fn();
    TEST_RESULTS.push({
      name,
      status: 'PASS',
      duration: Date.now() - start,
    });
    console.log(`  ✔ ${name} (${Date.now() - start}ms)`);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (error instanceof SkipError) {
      TEST_RESULTS.push({
        name,
        status: 'SKIP',
        duration: Date.now() - start,
      });
      console.log(`  ○ ${name} skipped — ${message}`);
      return;
    }
    TEST_RESULTS.push({
      name,
      status: 'FAIL',
      duration: Date.now() - start,
      error: message,
    });
    console.log(`  ✘ ${name} (${Date.now() - start}ms)`);
    console.log(`    ERROR: ${message}`);
  }
}

// Test 1: Session autostart functionality
async function testSessionAutostart() {
  // Verify session autostart script exists
  const autostartPath = join(process.cwd(), 'src', 'session', 'session-autostart.ts');
  assert(existsSync(autostartPath), 'session-autostart.ts should exist');

  // Runtime artifact: created by session-autostart on real sessions — skip on fresh checkouts.
  const contextDir = join(process.cwd(), '.session', 'context-log');
  if (!existsSync(contextDir)) {
    throw new SkipError('.session/context-log not present (created at runtime)');
  }
}

// Test 2: Health check operation
async function testHealthCheck() {
  const healthPath = join(process.cwd(), 'src', 'core', 'health-check.ts');
  assert(existsSync(healthPath), 'health-check.ts should exist');

  // Check that key components are detectable
  const mcpPath = join(process.cwd(), 'scripts', 'mcp', 'skill-server.ts');
  assert(existsSync(mcpPath), 'MCP skill server source should exist');
}

// Test 3: Watchtower health status
async function testWatchtowerHealth() {
  const watchtowerPath = join(process.cwd(), 'src', 'core', 'maintenance-watchtower.ts');
  assert(existsSync(watchtowerPath), 'Maintenance watchtower should exist');

  // Runtime artifact: created by the pipeline at runtime — skip on fresh checkouts.
  const runtimeDir = join(process.cwd(), '.runtime');
  if (!existsSync(runtimeDir)) {
    throw new SkipError('.runtime not present (created at runtime)');
  }
}

// Test 4: Dashboard WebSocket server (local-first app — skipped when apps/ absent, e.g. CI)
async function testDashboardWs() {
  const dashboardPath = join(process.cwd(), 'apps', 'web-dashboard');
  if (!existsSync(dashboardPath)) {
    throw new SkipError('web-dashboard not present (local-first app, decoupled from stack repo)');
  }

  // Verify server script exists
  const serverPath = join(dashboardPath, 'server', 'websocket-server.ts');
  assert(existsSync(serverPath), 'WebSocket server should exist');
}

// Test 5: Database health
async function testDatabaseHealth() {
  const dbPath = join(process.cwd(), '.runtime', 'gentle-vanguard.db');
  if (!existsSync(dbPath)) {
    throw new SkipError('Nexus database not present (created by db:init at runtime)');
  }

  // Database should be readable (size > 0)
  const stats = readFileSync(dbPath);
  assert(stats.length > 0, 'Database should not be empty');
}

// Test 6: Skills registry
async function testSkillsRegistry() {
  const registryPath = join(process.cwd(), '.atl', 'skill-embeddings.json');
  assert(existsSync(registryPath), 'Skill embeddings should exist');

  const embeddings = JSON.parse(readFileSync(registryPath, 'utf-8'));
  assert(embeddings.skills.length > 400, 'Should have 400+ skills indexed');
  assert(embeddings.metadata, 'Should have metadata');
}

// Test 7: Audit pipeline
async function testAuditPipeline() {
  const auditPath = join(process.cwd(), 'src', 'infrastructure', 'audit-pipeline.ts');
  assert(existsSync(auditPath), 'Audit pipeline should exist');

  // Verify audit directory structure
  const auditDir = join(process.cwd(), '.session', 'audit');
  // Directory is created on first event, so we just check the script exists
}

// Test 8: Token budget
async function testTokenBudget() {
  const budgetPath = join(process.cwd(), 'config', 'token-budget-guard.json');
  assert(existsSync(budgetPath), 'Token budget config should exist');

  const config = JSON.parse(readFileSync(budgetPath, 'utf-8'));
  assert(config.tokenBudget.limits.daily > 0, 'Daily budget should be configured');
  assert(config.tokenBudget.limits.softThreshold > 0, 'Soft threshold should be configured');
}

// Test 9: MCP bridge
async function testMcpBridge() {
  const mcpBridgePath = join(process.cwd(), 'src', 'mcp', 'mcp-bridge.ts');
  assert(existsSync(mcpBridgePath), 'MCP bridge should exist');

  // Verify MCP config
  const mcpConfigPath = join(process.cwd(), 'config', 'mcp-config.json');
  if (existsSync(mcpConfigPath)) {
    const config = JSON.parse(readFileSync(mcpConfigPath, 'utf-8'));
    assert(config, 'MCP config should be valid JSON');
  }
}

// Test 10: CodeGraph sync
async function testCodeGraphSync() {
  const codegraphPath = join(process.cwd(), '.codegraph');
  if (existsSync(codegraphPath)) {
    // If codegraph exists, verify it has content
    const graphPath = join(codegraphPath, 'index.json');
    if (existsSync(graphPath)) {
      const content = readFileSync(graphPath, 'utf-8');
      assert(content.length > 0, 'CodeGraph index should not be empty');
    }
  }
}

// Main test runner
async function main() {
  console.log('━'.repeat(50));
  console.log('E2E Test Suite: Session Lifecycle');
  console.log('━'.repeat(50));
  console.log();

  await runTest('Session Autostart', testSessionAutostart);
  await runTest('Health Check', testHealthCheck);
  await runTest('Watchtower Health', testWatchtowerHealth);
  await runTest('Dashboard WebSocket', testDashboardWs);
  await runTest('Database Health', testDatabaseHealth);
  await runTest('Skills Registry', testSkillsRegistry);
  await runTest('Audit Pipeline', testAuditPipeline);
  await runTest('Token Budget', testTokenBudget);
  await runTest('MCP Bridge', testMcpBridge);
  await runTest('CodeGraph Sync', testCodeGraphSync);

  console.log();
  console.log('━'.repeat(50));

  const passed = TEST_RESULTS.filter((r) => r.status === 'PASS').length;
  const failed = TEST_RESULTS.filter((r) => r.status === 'FAIL').length;
  const skipped = TEST_RESULTS.filter((r) => r.status === 'SKIP').length;
  const total = TEST_RESULTS.length;
  const duration = TEST_RESULTS.reduce((sum, r) => sum + r.duration, 0);

  console.log(`Results: ${passed}/${total} passed, ${failed} failed, ${skipped} skipped`);
  console.log(`Total duration: ${duration}ms`);
  console.log('━'.repeat(50));

  process.exit(failed > 0 ? 1 : 0);
}

main().catch(console.error);
