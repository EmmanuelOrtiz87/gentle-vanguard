#!/usr/bin/env node
/**
 * Validate opencode.json for unrecognized properties.
 * TS migration of scripts/utilities/config/validate-opencode-config.ps1
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { resolve } from 'path';
import { pathToFileURL } from 'url';

const VALID_PROPS = new Set([
  '$schema', 'agent', 'attachment', 'autoshare', 'autoupdate',
  'command', 'compaction', 'default_agent',
  'disabled_providers', 'enabled_providers', 'enterprise', 'experimental',
  'formatter', 'instructions', 'layout', 'logLevel', 'lsp',
  'mcp', 'mode', 'model',
  'permission', 'plugin', 'provider',
  'reference', 'references', 'server', 'share', 'shell', 'skills',
  'small_model', 'snapshot',
  'tools', 'tool_output',
  'username', 'watcher',
]);

function main(): void {
  const args = process.argv.slice(2);
  const configPath = resolve(args.includes('--config') ? args[args.indexOf('--config') + 1] : 'opencode.json');
  const fix = args.includes('--fix') || args.includes('-Fix');

  if (!existsSync(configPath)) {
    console.error(`ERROR: ${configPath} not found`);
    process.exit(1);
  }

  const raw = readFileSync(configPath, 'utf-8');
  let config: Record<string, unknown>;
  try {
    config = JSON.parse(raw);
  } catch {
    console.error('ERROR: opencode.json is not valid JSON');
    process.exit(1);
  }

  const unknown = Object.keys(config).filter((k) => !VALID_PROPS.has(k));

  if (unknown.length > 0) {
    console.log(`FAIL: opencode.json contiene propiedades NO reconocidas por OpenCode:`);
    for (const u of unknown) {
      console.log(`  - ${u}`);
    }
    console.log('');
    console.log('OpenCode rechaza propiedades desconocidas al iniciar. Mover a config/ separado.');

    if (fix) {
      const lines = raw.split('\n');
      const filtered = lines.filter((line) => {
        const trimmed = line.trim();
        return !unknown.some((u) => trimmed.startsWith(`"${u}"`));
      });
      writeFileSync(configPath, filtered.join('\n'), 'utf-8');
      console.log(`FIXED: Removed unknown properties from ${configPath}`);
    }

    process.exit(1);
  } else {
    console.log('PASS: opencode.json solo contiene propiedades válidas');
    process.exit(0);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
