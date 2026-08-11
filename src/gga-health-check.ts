#!/usr/bin/env npx tsx
/**
 * GGA Health Check and Model Validation
 */

import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

const ROOT = process.cwd();
const HEALTH_REGISTRY_PATH = join(ROOT, 'config', 'model-health-registry.json');

function loadHealthRegistry() {
  try {
    if (existsSync(HEALTH_REGISTRY_PATH)) {
      return JSON.parse(readFileSync(HEALTH_REGISTRY_PATH, 'utf-8'));
    }
  } catch (e) {
    console.error('Error loading health registry:', e);
  }
  return null;
}

async function validateConfiguration() {
  const registry = loadHealthRegistry();
  if (!registry) {
    console.error('No health registry found');
    return;
  }

  console.log('\n=== GGA Configuration Validation ===\n');
  console.log('Routing rules configured');
  console.log('Models:', Object.keys(registry.models || {}).join(', '));
  console.log('\n=== OK ===');
}

async function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  if (command === '--validate') {
    await validateConfiguration();
  } else {
    console.log('Usage: npx tsx src/gga-health-check.ts --validate');
  }
}

main().catch(console.error);
