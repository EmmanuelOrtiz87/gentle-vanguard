#!/usr/bin/env npx tsx
import { readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..', '..', '..');
const opencodePath = join(ROOT, 'opencode.json');

// Leer opencode.json
const config = JSON.parse(readFileSync(opencodePath, 'utf-8'));

// Borrar campo model de TODOS los subagentes
let count = 0;
interface AgentConfig {
  mode?: string;
  model?: string;
  variant?: string;
  [key: string]: unknown;
}
for (const [name, agent] of Object.entries(config.agent as Record<string, AgentConfig>)) {
  if (agent.mode === 'subagent' && agent.model) {
    delete agent.model;
    agent.variant = '';  // Break inheritance
    count++;
    console.log(`Borrado model de: ${name}`);
  }
}

// Guardar
writeFileSync(opencodePath, JSON.stringify(config, null, 2) + '\n', 'utf-8');
console.log(`✅ Borrados ${count} modelos de subagentes`);
