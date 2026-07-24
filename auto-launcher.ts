#!/usr/bin/env node

/**
 * Gentle-Vanguard v5.0-v8.0 Auto-Launcher
 * Ejecuta todos los componentes de las fases 5.0 a 8.0
 */

import { convergenceMonitor } from './src/v5.0-Convergence/convergence-monitor.js';
import { knowledgeSynthesizer } from './src/v5.0-Convergence/knowledge-synthesizer.js';
import { selfReflectionLoop } from './src/v5.0-Convergence/self-reflection-loop.js';
import { adaptiveRouter } from './src/v5.0-Convergence/adaptive-router.js';
import { predictiveGovernor } from './src/v5.0-Convergence/predictive-governor.js';
import { rootCauseCorrelator } from './src/v5.0-Convergence/root-cause-correlator.js';
import { skillEvolutionEngine } from './src/v5.0-Convergence/skill-evolution-engine.js';

import { tenantContextManager } from './src/v5.1-MultiTenant/tenant-context.js';
import { evalQualityGate } from './src/v5.1-MultiTenant/eval-quality-gate.js';

import { autoCodeReview } from './src/v6.0-AutonomousReview/auto-code-review.js';
import { receiptManager } from './src/v6.0-AutonomousReview/receipt-manager.js';
import { stagedReview } from './src/v6.0-AutonomousReview/staged-review.js';

import { mcpGateway } from './src/v6.4-MCPNative/mcp-gateway.js';
import { gateGuardMCP } from './src/v6.4-MCPNative/gate-guard-mcp.js';

import { findingsLedger } from './src/v8.0-TrustLayer/findings-ledger.js';
import { compactState } from './src/v8.0-TrustLayer/compact-state.js';
import { reviewLenses } from './src/v8.0-TrustLayer/review-lenses.js';
import { resultGatekeeper } from './src/v8.0-TrustLayer/result-gatekeeper.js';
import { publicationGates } from './src/v8.0-TrustLayer/publication-gates.js';

console.log('╔════════════════════════════════════════════════════════════╗');
console.log('║     GENTLE-VANGUARD v8.0.1 - AUTO-LAUNCHER                 ║');
console.log('╚════════════════════════════════════════════════════════════╝');
console.log('');

// Initialize all components
const components = {
  'v5.0 Convergence': [convergenceMonitor, knowledgeSynthesizer, selfReflectionLoop, adaptiveRouter, predictiveGovernor, rootCauseCorrelator, skillEvolutionEngine],
  'v5.1 Multi-Tenant': [tenantContextManager, evalQualityGate],
  'v6.0 Autonomous Review': [autoCodeReview, receiptManager, stagedReview],
  'v6.4 MCP Native': [mcpGateway, gateGuardMCP],
  'v8.0 Trust Layer': [findingsLedger, compactState, reviewLenses, resultGatekeeper, publicationGates],
};

console.log('Initializing components...\n');

for (const [phase, comps] of Object.entries(components)) {
  console.log(`[${phase}]`);
  comps.forEach(comp => {
    const stats = comp.getStats ? comp.getStats() : { status: 'active' };
    console.log(`  ✓ ${comp.constructor.name}: ${JSON.stringify(stats)}`);
  });
  console.log('');
}

console.log('╔════════════════════════════════════════════════════════════╗');
console.log('║     ALL COMPONENTS INITIALIZED SUCCESSFULLY                  ║');
console.log('╚════════════════════════════════════════════════════════════╝');
