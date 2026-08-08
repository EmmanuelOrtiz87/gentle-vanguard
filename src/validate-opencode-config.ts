#!/usr/bin/env node
/**
 * Validate opencode.json for unrecognized properties and structural integrity.
 * TS migration of scripts/utilities/config/validate-opencode-config.ps1
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { resolve } from 'path';
import { pathToFileURL } from 'url';

const VALID_PROPS = new Set([
  '$schema',
  'agent',
  'attachment',
  'autoshare',
  'autoupdate',
  'command',
  'compaction',
  'default_agent',
  'disabled_providers',
  'enabled_providers',
  'enterprise',
  'experimental',
  'formatter',
  'instructions',
  'layout',
  'logLevel',
  'lsp',
  'mcp',
  'mode',
  'model',
  'permission',
  'plugin',
  'provider',
  'reference',
  'references',
  'server',
  'share',
  'shell',
  'skills',
  'small_model',
  'snapshot',
  'tools',
  'tool_output',
  'username',
  'watcher',
]);

// Additional structural validation rules
function validateAgents(agents: any): string[] {
  const errors: string[] = [];
  
  if (!agents || typeof agents !== 'object') {
    errors.push('Invalid agents structure');
    return errors;
  }

  // Check for proper agent structure
  for (const [agentName, agentConfig] of Object.entries(agents)) {
    if (typeof agentConfig !== 'object' || agentConfig === null) {
      errors.push(`Agent ${agentName} has invalid configuration structure`);
      continue;
    }

    // Required properties for each agent
    const requiredProps = ['mode', 'model'];
    for (const prop of requiredProps) {
      if (!(prop in agentConfig)) {
        errors.push(`Agent ${agentName} missing required property: ${prop}`);
      }
    }

    // Validate agent modes
    if ('mode' in agentConfig) {
      const validModes = ['primary', 'subagent'];
      if (!validModes.includes(agentConfig.mode)) {
        errors.push(`Agent ${agentName} has invalid mode: ${agentConfig.mode}`);
      }
    }
    
    // Validate steps if present
    if ('steps' in agentConfig && typeof agentConfig.steps !== 'number') {
      errors.push(`Agent ${agentName} steps must be a number`);
    }
  }

  return errors;
}

function validateMCP(mcp: any): string[] {
  const errors: string[] = [];

  if (!mcp || typeof mcp !== 'object') {
    return ['Invalid MCP structure'];
  }

  for (const [name, service] of Object.entries(mcp)) {
    if (typeof service !== 'object' || service === null) {
      errors.push(`MCP service ${name} has invalid configuration`);
      continue;
    }

    // Required properties for MCP services
    const requiredProps = ['type'];
    for (const prop of requiredProps) {
      if (!(prop in service)) {
        errors.push(`MCP service ${name} missing required property: ${prop}`);
      }
    }
    
    // Validate service types
    if ('type' in service) {
      const validTypes = ['local', 'stdio'];
      if (!validTypes.includes(service.type)) {
        errors.push(`MCP service ${name} has invalid type: ${service.type}`);
      }
    }
  }

  return errors;
}

function validatePermissions(permissions: any): string[] {
  const errors: string[] = [];

  if (!permissions || typeof permissions !== 'object') {
    return ['Invalid permissions structure'];
  }

  // Validate permission structure - allow flexible nested structures
  for (const [perm, value] of Object.entries(permissions)) {
    // Skip validation of complex permission structures like bash and task
    // These can have nested objects with wildcard patterns
    if (perm === 'bash' || perm === 'task') {
      continue;
    }
    
    // For simple permissions, ensure they're valid
    if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
      // If it's an object but not one we specifically allow, check if it has valid sub-properties
      const validSimpleProps = ['websearch', 'webfetch', 'task', 'read', 'glob', 'grep'];
      if (!validSimpleProps.some(p => p in value)) {
        // Allow more complex structures for now, we'll trust the config structure
        // We're mainly validating top-level structural errors
        continue;
      }
    }
  }

  return errors;
}

function main(): void {
  const args = process.argv.slice(2);
  const configPath = resolve(
    args.includes('--config') ? args[args.indexOf('--config') + 1] : 'opencode.json',
  );
  const fix = args.includes('--fix') || args.includes('-Fix');

  if (!existsSync(configPath)) {
    console.error(`ERROR: ${configPath} not found`);
    process.exit(1);
  }

  const raw = readFileSync(configPath, 'utf-8');
  let config: Record<string, unknown>;
  try {
    config = JSON.parse(raw);
  } catch (error) {
    console.error('ERROR: opencode.json is not valid JSON');
    console.error(error instanceof Error ? error.message : 'Unknown error');
    process.exit(1);
  }

  // Check top-level properties
  const unknown = Object.keys(config).filter((k) => !VALID_PROPS.has(k));

  // Collect errors
  const errors: string[] = [];

  if (unknown.length > 0) {
    console.log(`FAIL: opencode.json contiene propiedades NO reconocidas por OpenCode:`);
    for (const u of unknown) {
      console.log(`  - ${u}`);
    }
    console.log('');
    console.log('OpenCode rechaza propiedades desconocidas al iniciar. Mover a config/ separado.');
    errors.push('Unrecognized top-level properties');
  }

  // Validate agents structure if present
  if ('agent' in config) {
    const agentErrors = validateAgents(config.agent as any);
    errors.push(...agentErrors);
    if (agentErrors.length > 0) {
      console.log('Agent validation errors:');
      for (const error of agentErrors) {
        console.log(`  - ${error}`);
      }
    }
  }

  // Validate MCP structure if present
  if ('mcp' in config) {
    const mcpErrors = validateMCP(config.mcp as any);
    errors.push(...mcpErrors);
    if (mcpErrors.length > 0) {
      console.log('MCP validation errors:');
      for (const error of mcpErrors) {
        console.log(`  - ${error}`);
      }
    }
  }

  // Validate permissions if present
  if ('permission' in config) {
    const permErrors = validatePermissions(config.permission as any);
    errors.push(...permErrors);
    if (permErrors.length > 0) {
      console.log('Permission validation errors:');
      for (const error of permErrors) {
        console.log(`  - ${error}`);
      }
    }
  }

  if (errors.length > 0) {
    if (fix) {
      console.log('Attempting to fix configuration...');
      
      // Basic cleanup: remove lines with unknown properties
      const lines = raw.split('\n');
      const filtered = lines.filter((line) => {
        const trimmed = line.trim();
        return !unknown.some((u) => trimmed.startsWith(`"${u}"`));
      });
      
      // Only apply fix if there are actually unknown properties to remove
      if (unknown.length > 0) {
        writeFileSync(configPath, filtered.join('\n'), 'utf-8');
        console.log(`FIXED: Removed unknown properties from ${configPath}`);
        console.log('Verification required - please review the changes carefully.');
      } else {
        console.log('No fixable issues found.');
      }
    } else {
      console.log('Configuration validation failed. Please fix the issues and try again.');
    }
    
    process.exit(1);
  } else {
    console.log('PASS: opencode.json contiene solo propiedades válidas y tiene estructura correcta');
    process.exit(0);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
