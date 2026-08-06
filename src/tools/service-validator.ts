#!/usr/bin/env node
/**
 * service-validator.ts — Service dependency validator
 *
 * Validates all service dependencies are met:
 * - Node.js version
 * - pnpm/npm installed
 * - Dependencies installed
 * - Required ports available
 * - Environment variables set
 *
 * Usage:
 *   npx tsx src/tools/service-validator.ts
 *   npx tsx src/tools/service-validator.ts --fix
 */

import { execSync } from 'child_process';
import { existsSync, readFileSync } from 'fs';
import { join, resolve } from 'path';
import { runSync } from '../core/run-command.js';

const ROOT = resolve(process.cwd());

interface ValidationResult {
  name: string;
  passed: boolean;
  message: string;
  fixable: boolean;
}

function checkNodeVersion(): ValidationResult {
  try {
    const version = process.version;
    const major = parseInt(version.slice(1).split('.')[0], 10);
    
    if (major >= 20) {
      return { name: 'Node.js', passed: true, message: `v${version}`, fixable: false };
    }
    return { name: 'Node.js', passed: false, message: `v${version} (need >=20)`, fixable: false };
  } catch (e) {
    return { name: 'Node.js', passed: false, message: 'Unknown', fixable: false };
  }
}

function checkPackageManager(): ValidationResult {
  try {
    execSync('pnpm --version', { stdio: 'pipe' });
    return { name: 'pnpm', passed: true, message: 'Installed', fixable: false };
  } catch {
    return { name: 'pnpm', passed: false, message: 'Not installed', fixable: true };
  }
}

function checkDependencies(): ValidationResult {
  const nodeModules = join(ROOT, 'node_modules');
  
  if (!existsSync(nodeModules)) {
    return { name: 'Dependencies', passed: false, message: 'node_modules missing', fixable: true };
  }
  
  // Check if key packages exist
  const keyPackages = [
    '@modelcontextprotocol/sdk',
    'zod',
    'typescript'
  ];
  
  const missing: string[] = [];
  for (const pkg of keyPackages) {
    if (!existsSync(join(nodeModules, pkg))) {
      missing.push(pkg);
    }
  }
  
  if (missing.length > 0) {
    return { name: 'Dependencies', passed: false, message: `${missing.length} packages missing`, fixable: true };
  }
  
  return { name: 'Dependencies', passed: true, message: 'All key packages present', fixable: false };
}

function checkPorts(): ValidationResult {
  const requiredPorts = [8080, 5173, 3000];
  const inUse: number[] = [];
  
  try {
    const result = runSync('netstat', ['-ano'], { timeout: 5000 });
    const output = result.stdout;
    
    for (const port of requiredPorts) {
      if (output.includes(`:${port}`) || output.includes(` ${port} `)) {
        inUse.push(port);
      }
    }
  } catch {}
  
  if (inUse.length > 0) {
    return { name: 'Ports', passed: false, message: `Ports in use: ${inUse.join(', ')}`, fixable: false };
  }
  
  return { name: 'Ports', passed: true, message: 'Required ports available', fixable: false };
}

function checkEnvVariables(): ValidationResult {
  const required = ['PATH'];
  const missing: string[] = [];
  
  for (const env of required) {
    if (!process.env[env]) {
      missing.push(env);
    }
  }
  
  if (missing.length > 0) {
    return { name: 'Environment', passed: false, message: `Missing: ${missing.join(', ')}`, fixable: false };
  }
  
  return { name: 'Environment', passed: true, message: 'All required variables set', fixable: false };
}

function checkGitRemote(): ValidationResult {
  try {
    const result = runSync('git', ['remote', '-v'], { cwd: ROOT, timeout: 5000 });
    if (result.stdout.includes('origin')) {
      return { name: 'Git Remote', passed: true, message: 'origin configured', fixable: false };
    }
  } catch {}
  
  return { name: 'Git Remote', passed: false, message: 'No origin remote', fixable: true };
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const fix = args.includes('--fix');
  
  console.log('🔍 Gentle-Vanguard Service Validator\n');
  
  const checks = [
    checkNodeVersion(),
    checkPackageManager(),
    checkDependencies(),
    checkPorts(),
    checkEnvVariables(),
    checkGitRemote(),
  ];
  
  const failed = checks.filter(c => !c.passed);
  const fixable = failed.filter(c => c.fixable);
  
  // Print results
  for (const check of checks) {
    const icon = check.passed ? '✅' : check.fixable ? '⚠️' : '❌';
    console.log(`${icon} ${check.name.padEnd(20)} ${check.message}`);
  }
  
  console.log('\n' + '='.repeat(50));
  console.log(`Passed: ${checks.length - failed.length}/${checks.length}`);
  console.log(`Failed: ${failed.length} (${fixable.length} auto-fixable)`);
  
  if (fix && fixable.length > 0) {
    console.log('\n🔧 Attempting fixes...\n');
    
    for (const check of fixable) {
      if (check.name === 'pnpm') {
        console.log('Installing pnpm...');
        try {
          execSync('npm install -g pnpm', { stdio: 'inherit' });
          console.log('✅ pnpm installed');
        } catch {
          console.log('❌ Failed to install pnpm');
        }
      }
      
      if (check.name === 'Dependencies') {
        console.log('Installing dependencies...');
        try {
          execSync('pnpm install', { cwd: ROOT, stdio: 'inherit' });
          console.log('✅ Dependencies installed');
        } catch {
          console.log('❌ Failed to install dependencies');
        }
      }
    }
    
    console.log('\n🔄 Re-running validation...\n');
    // Recursive call without --fix
    await main();
    return;
  }
  
  if (failed.length > 0) {
    console.log('\n❌ Some checks failed. Run with --fix to attempt automatic fixes.');
    process.exit(1);
  } else {
    console.log('\n✅ All validations passed!');
  }
}

main().catch(e => {
  console.error('Error:', e);
  process.exit(1);
});
