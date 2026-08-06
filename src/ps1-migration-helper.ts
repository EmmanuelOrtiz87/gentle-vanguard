#!/usr/bin/env node
/**
 * PS1 Migration Script - Reemplaza referencias masivamente
 */

import { existsSync } from 'fs';

const patterns = [
  { from: /pwsh hooks\/([\w-]+)\.ps1/g, to: 'npx tsx src/hooks/$1.ts' },
  { from: /pwsh scripts\/hooks\/([\w-]+)\.ps1/g, to: 'npx tsx src/hooks/$1.ts' },
  { from: /hooks\/([\w-]+)\.ps1/g, to: 'src/hooks/$1.ts' },
  { from: /scripts\/([\w/-]+)\/([\w-]+)\.ps1/g, to: 'src/$2.ts' },
];

// Solo verificación por ahora
console.log('Análisis de referencias PS1 para migración:');
console.log('==========================================\n');

// Buscar archivos con referencias...
const files = [
  'config/quality-gates.json',
  'config/cline-dify.config.json',
  'config/continue-project-settings.json',
  'docs/agents/AGENTS.md',
];

for (const file of files) {
  if (existsSync(file)) {
    console.log(`✓ ${file} - pendiente de migración`);
  }
}

console.log('\nPara migrar, editar manualmente o usar sed/awk con cuidado.');
console.log('Reemplazar: pwsh path/script.ps1 → npx tsx src/script.ts');
