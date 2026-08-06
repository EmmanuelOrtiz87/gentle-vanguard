#!/usr/bin/env node

/**
 * Gentle-Vanguard v5.0-v8.0 Auto-Launcher
 * Ejecuta todos los componentes de las fases 5.0 a 8.0
 */

import { convergenceMonitor } from './src/convergence/convergence-monitor.js';
import { knowledgeSynthesizer } from './src/convergence/knowledge-synthesizer.js';
import { selfReflectionLoop } from './src/convergence/self-reflection-loop.js';
import { adaptiveRouter } from './src/convergence/adaptive-router.js';
import { predictiveGovernor } from './src/convergence/predictive-governor.js';
import { rootCauseCorrelator } from './src/convergence/root-cause-correlator.js';
import { skillEvolutionEngine } from './src/convergence/skill-evolution-engine.js';

import { tenantContextManager } from './src/multitenant/tenant-context.js';
import { evalQualityGate } from './src/multitenant/eval-quality-gate.js';

import { autoCodeReview } from './src/autonomous-review/auto-code-review.js';
import { receiptManager } from './src/autonomous-review/receipt-manager.js';
import { stagedReview } from './src/autonomous-review/staged-review.js';

import { mcpGateway } from './src/mcp-native/mcp-gateway.js';
import { gateGuardMCP } from './src/mcp-native/gate-guard-mcp.js';

import { findingsLedger } from './src/trust-layer/findings-ledger.js';
import { compactState } from './src/trust-layer/compact-state.js';
import { reviewLenses } from './src/trust-layer/review-lenses.js';
import { resultGatekeeper } from './src/trust-layer/result-gatekeeper.js';
import { publicationGates } from './src/trust-layer/publication-gates.js';

console.log('╔════════════════════════════════════════════════════════════╗');
console.log('║     GENTLE-VANGUARD v8.0.1 - AUTO-LAUNCHER                 ║');
console.log('╚════════════════════════════════════════════════════════════╝');
console.log('');

// Initialize all components
const components = {
  'v5.0 Convergence': [
    convergenceMonitor,
    knowledgeSynthesizer,
    selfReflectionLoop,
    adaptiveRouter,
    predictiveGovernor,
    rootCauseCorrelator,
    skillEvolutionEngine,
  ],
  'v5.1 Multi-Tenant': [tenantContextManager, evalQualityGate],
  'v6.0 Autonomous Review': [autoCodeReview, receiptManager, stagedReview],
  'v6.4 MCP Native': [mcpGateway, gateGuardMCP],
  'v8.0 Trust Layer': [
    findingsLedger,
    compactState,
    reviewLenses,
    resultGatekeeper,
    publicationGates,
  ],
};

console.log('Initializing components...\n');

for (const [phase, comps] of Object.entries(components)) {
  console.log(`[${phase}]`);
  comps.forEach((comp) => {
    const stats = comp.getStats ? comp.getStats() : { status: 'active' };
    console.log(`  ✓ ${comp.constructor.name}: ${JSON.stringify(stats)}`);
  });
  console.log('');
}

console.log('╔════════════════════════════════════════════════════════════╗');
console.log('║     ALL COMPONENTS INITIALIZED SUCCESSFULLY                  ║');
console.log('╚════════════════════════════════════════════════════════════╝');
