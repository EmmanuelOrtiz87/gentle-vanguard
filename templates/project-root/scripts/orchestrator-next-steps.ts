#!/usr/bin/env node

/**
 * orchestrator-next-steps.ts — Orchestrator guidance for template projects
 *
 * Checks orchestrator activation status and recommends next development actions.
 *
 * Usage:
 *   npx tsx templates/project-root/scripts/orchestrator-next-steps.ts
 *   npx tsx templates/project-root/scripts/orchestrator-next-steps.ts --detailed
 */

import { existsSync, readFileSync } from 'fs';
import { join, resolve } from 'path';

const SCRIPT_DIR = resolve(__dirname);
let projectRoot = resolve(join(SCRIPT_DIR, '..'));

// If README.md doesn't exist here, go up one more level
if (!existsSync(join(projectRoot, 'README.md'))) {
  const parent = resolve(join(projectRoot, '..'));
  if (existsSync(join(parent, 'README.md'))) projectRoot = parent;
}

const args = process.argv.slice(2);
const detailed = args.includes('--detailed') || args.includes('-Detailed');

function step(msg: string): void {
  console.log(`\n=== ${msg} ===`);
}
function info(msg: string): void {
  console.log(`[INFO] ${msg}`);
}
function action(msg: string): void {
  console.log(`  - ${msg}`);
}
function ok(msg: string): void {
  console.log(`[OK] ${msg}`);
}

function resolveSkillPath(candidate: string): string | null {
  if (existsSync(candidate)) return resolve(candidate);
  return null;
}

const activationFile = join(projectRoot, '.orchestrator-active');
const configFile = join(projectRoot, 'config', 'orchestrator.json');

step('Project Orchestrator - Next Steps');

if (!existsSync(activationFile)) {
  console.log('The orchestrator does not appear to be active in this project.');
  console.log(
    'Run project setup or create a new project from the Gentle-Vanguard template to activate it.',
  );
  process.exit(1);
}

if (!existsSync(configFile)) {
  console.log(`Orchestrator configuration file is missing: ${configFile}`);
}

// Find orchestrator skill
let orchestratorPath: string | null = null;

const skillCandidates = [
  join(projectRoot, '.skills', 'project-orchestrator-skill'),
  join(projectRoot, '.gentle-vanguard', 'skills', 'project-orchestrator-skill'),
  join(projectRoot, 'skills', 'project-orchestrator-skill'),
];

for (const candidate of skillCandidates) {
  orchestratorPath = resolveSkillPath(candidate);
  if (orchestratorPath) break;
}

if (!orchestratorPath && existsSync(configFile)) {
  try {
    const configData = JSON.parse(readFileSync(configFile, 'utf-8'));
    if (configData.skill_path) {
      const candidate = join(projectRoot, configData.skill_path);
      orchestratorPath = resolveSkillPath(candidate);
    }
  } catch {
    console.log('Unable to parse orchestrator configuration.');
  }
}

step('Activation Status');
if (orchestratorPath) {
  ok(`Orchestrator skill found: ${orchestratorPath}`);
} else {
  console.log('Orchestrator skill not found in expected locations.');
  console.log("Check '.skills/' or '.gentle-vanguard/skills/' and validate the project setup.");
}

if (existsSync(activationFile)) {
  try {
    const activationData = JSON.parse(readFileSync(activationFile, 'utf-8'));
    info(`Activated: ${activationData.activated}`);
    info(`Skill: ${activationData.skill}`);
    info(`Project: ${activationData.project}`);
  } catch {
    info('Could not parse activation data');
  }
}

if (existsSync(configFile)) {
  try {
    const configData = JSON.parse(readFileSync(configFile, 'utf-8'));
    info(`Workflow mode: ${configData.workflow_mode}`);
    info(`Auto detect: ${configData.auto_detect}`);
    info(`Memory integration: ${configData.memory_integration}`);
    info(`Quality gates: ${configData.quality_gates}`);
  } catch {
    console.log('Unable to read orchestrator configuration details.');
  }
}

step('Recommended Next Activities');
action('Validate the project and orchestrator configuration with the Gentle-Vanguard tools.');
action('Inspect docs/project-context.md and ARCHITECTURE.md to confirm scope and architecture.');
action('Use the orchestrator to guide analysis, design, architecture, and testing.');
action('Ensure the AI workflow is ready and the required skills are available.');

if (detailed) {
  step('Detailed Guidance');
  action('Apply testing-strategy and testing-skill to improve test coverage.');
  action('Use architecture-governance for architecture decisions and documentation.');
  action(
    'Use security-expert and code-review-orchestrator for quality and vulnerability analysis.',
  );
  action('Use ai-sdk-5 and mcp-skill for AI-assisted modeling and session memory.');
}

step('Orchestrator Ready');
console.log('The Project Orchestrator is active and ready to guide the development lifecycle.');
console.log('Run this script again with --detailed for extra guidance.');
