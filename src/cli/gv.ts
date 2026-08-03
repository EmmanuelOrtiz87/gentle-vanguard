#!/usr/bin/env node

/**
 * gv.ts — Gentle-Vanguard CLI (TS replacement for bin/gv.ps1)
 *
 * Usage:
 *   npx tsx src/cli/gv.ts <command> [options]
 *
 * Commands:
 *   check       Run system checks (watchtower health)
 *   validate    Validate stack installation
 *   info        Show stack information
 *   list        List available skills
 *   health      Show Nexus DB health
 *   prune       Prune old Nexus data
 *   backup      Backup Nexus DB
 *   optimize    Optimize Nexus DB (WAL + VACUUM)
 *   new         Create new project (scaffolding info)
 *   update      Update stack via git pull
 *   update-all  Full stack update
 *   sync        Alias for update
 *   tools       Show optional tools status
 *   secret      Secret management (stub — use engram/vault instead)
 *   cache       Cache management (stub — use Nexus DB instead)
 *   help        Show this help
 */

import { execSync } from 'child_process';
import { existsSync, readdirSync } from 'fs';
import { join, resolve } from 'path';
import { printBanner } from './banner.js';

const ROOT = resolve(process.cwd());
const SKILLS_DIR = join(ROOT, 'skills');
const RULES_DIR = join(ROOT, 'rules');

const args = process.argv.slice(2);
const command = args[0] || 'help';

function header(): void {
  printBanner('CLI v8.0');
}

function footer(): void {
  console.log('');
  console.log("Run 'npx tsx src/cli/gv.ts help' for usage.");
  console.log('');
}

function showHelp(): void {
  header();
  console.log(`
USAGE:
  npx tsx src/cli/gv.ts <command> [options]

COMMANDS:
  check       Run system checks (watchtower health)
  validate    Validate stack installation
  info        Show stack information
  list        List available skills
  health      Show Nexus DB health
  prune       Prune old Nexus data
  backup      Backup Nexus DB
  optimize    Optimize Nexus DB (WAL + VACUUM)
  new         Create new project scaffolding
  update      Update stack via git pull
  update-all  Full stack update (git pull + npm update)
  sync        Alias for update
  tools       Show optional tools status
  secret      Secret management (engram-vault)
  cache       Cache management (Nexus DB)
  help        Show this help

EXAMPLES:
  npx tsx src/cli/gv.ts info
  npx tsx src/cli/gv.ts health
  npx tsx src/cli/gv.ts backup
  npx tsx src/cli/gv.ts check
`);
  footer();
}

function getStackInfo(): Record<string, unknown> {
  const skillsCount = existsSync(SKILLS_DIR)
    ? readdirSync(SKILLS_DIR, { withFileTypes: true }).filter(d => d.isDirectory()).length
    : 0;
  const rulesCount = existsSync(RULES_DIR)
    ? readdirSync(RULES_DIR).filter(f => f.endsWith('.md')).length
    : 0;
  return {
    root: ROOT,
    skills: skillsCount,
    rules: rulesCount,
    tsSource: join(ROOT, 'src'),
  };
}

function showInfo(): void {
  header();
  const info = getStackInfo();
  console.log('Gentle-Vanguard Stack Information');
  console.log('');
  console.log(`  Root:         ${info.root}`);
  console.log(`  Skills:       ${info.skills}`);
  console.log(`  Rules:        ${info.rules}`);
  console.log(`  TS Source:    ${info.tsSource}`);
  console.log(`  Nexus DB:     .runtime/gentle-vanguard.db`);
  console.log('');

  if (existsSync(SKILLS_DIR)) {
    console.log('  Available Skills:');
    const dirs = readdirSync(SKILLS_DIR, { withFileTypes: true })
      .filter(d => d.isDirectory())
      .sort((a, b) => a.name.localeCompare(b.name));
    for (const d of dirs) {
      console.log(`    - ${d.name}`);
    }
    console.log(`  Total: ${dirs.length} skills`);
  }
  footer();
}

function runCommand(cmd: string, label: string): boolean {
  try {
    console.log(`[${label}] Running...`);
    execSync(cmd, { stdio: 'inherit', timeout: 120000 });
    return true;
  } catch (e) {
    console.error(`[${label}] FAILED:`, (e as Error).message);
    return false;
  }
}

// ─── Command Routing ────────────────────────────────────────────────

async function main(): Promise<void> {
  switch (command) {
    case 'help':
    case '--help':
      showHelp();
      process.exit(0);
      break;

    case 'info':
      showInfo();
      process.exit(0);
      break;

    case 'check':
      runCommand('npx tsx src/core/maintenance-watchtower.ts --action health', 'WATCHTOWER');
      break;

    case 'validate': {
      header();
      let ok = true;
      console.log('Validating Gentle-Vanguard Stack...\n');

      // Check root
      if (existsSync(ROOT)) {
        console.log('  [OK] Root exists');
      } else {
        console.log('  [FAIL] Root not found');
        ok = false;
      }

      // Check skills
      if (existsSync(SKILLS_DIR)) {
        const count = readdirSync(SKILLS_DIR, { withFileTypes: true }).filter(d => d.isDirectory()).length;
        console.log(`  [OK] ${count} skills`);
      } else {
        console.log('  [FAIL] Skills directory missing');
        ok = false;
      }

      // Check Nexus DB
      const dbPath = join(ROOT, '.runtime', 'gentle-vanguard.db');
      if (existsSync(dbPath)) {
        console.log('  [OK] Nexus DB present');
      } else {
        console.log('  [WARN] Nexus DB not found (will be created on first use)');
      }

      // Check npm scripts
      try {
        execSync('npm run typecheck', { stdio: 'pipe', timeout: 60000 });
        console.log('  [OK] TypeScript typecheck passes');
      } catch {
        console.log('  [FAIL] TypeScript typecheck failed');
        ok = false;
      }

      // Check git
      try {
        const branch = execSync('git rev-parse --abbrev-ref HEAD', { encoding: 'utf8', timeout: 5000 }).trim();
        console.log(`  [OK] Git branch: ${branch}`);
      } catch {
        console.log('  [WARN] Not a git repository');
      }

      console.log('');
      console.log(ok ? 'Validation PASSED' : 'Validation FAILED');
      if (!ok) process.exit(1);
      break;
    }

    case 'list': {
      header();
      if (existsSync(SKILLS_DIR)) {
        const dirs = readdirSync(SKILLS_DIR, { withFileTypes: true })
          .filter(d => d.isDirectory())
          .sort((a, b) => a.name.localeCompare(b.name));
        console.log('Installed Skills:\n');
        for (const d of dirs) {
          console.log(`  ${d.name}`);
        }
        console.log(`\nTotal: ${dirs.length} skills`);
      } else {
        console.log('No skills directory found');
      }
      footer();
      break;
    }

    case 'health':
      runCommand('npm run db:health', 'NEXUS');
      break;

    case 'prune':
      runCommand('npm run db:prune', 'NEXUS');
      break;

    case 'backup':
      runCommand('npm run db:backup', 'NEXUS');
      break;

    case 'optimize':
      runCommand('npm run db:optimize', 'NEXUS');
      break;

    case 'new':
      header();
      console.log('Project scaffolding:\n');
      console.log('  Use the SDD workflow:');
      console.log('    1. npx tsx src/session-autostart.ts');
      console.log('    2. Load skill: spec-driven-development, planning-and-task-breakdown');
      console.log('    3. Ask the orchestrator to create a new project\n');
      footer();
      break;

    case 'update':
    case 'sync':
      header();
      console.log('Updating stack...\n');
      runCommand('git pull origin develop', 'GIT');
      runCommand('npm update', 'NPM');
      footer();
      break;

    case 'update-all':
      header();
      console.log('Full stack update...\n');
      runCommand('git pull origin develop', 'GIT');
      runCommand('npm update', 'NPM');
      runCommand('npm run db:optimize', 'NEXUS');
      footer();
      break;

    case 'tools': {
      header();
      console.log('Available Tools:\n');
      const tools = [
        { name: 'opencode', desc: 'opencode CLI (code editing)', check: 'opencode --version' },
        { name: 'engram', desc: 'Persistent memory (plugin)', check: 'npx engram --version' },
        { name: 'node', desc: 'Node.js runtime', check: 'node --version' },
        { name: 'npx', desc: 'Node package executor', check: 'npx --version' },
      ];
      for (const t of tools) {
        try {
          const ver = execSync(t.check, { encoding: 'utf8', timeout: 5000 }).trim().split('\n')[0];
          console.log(`  [OK]    ${t.name.padEnd(12)} ${ver}`);
        } catch {
          console.log(`  [MISS]  ${t.name.padEnd(12)} ${t.desc}`);
        }
      }
      console.log('\n  All tools are optional. The stack works without them.');
      footer();
      break;
    }

    case 'secret':
      header();
      console.log('Secret Management:\n');
      console.log('  Secrets are managed via engram memory (secure, persistent).');
      console.log('  Use: npx tsx src/cli/gv.ts info  to check stack status.\n');
      console.log('  For credential storage, use your OS keychain or engram vault.\n');
      footer();
      break;

    case 'cache':
      runCommand('npm run db:health', 'NEXUS (cache lives in Nexus DB)');
      break;

    default:
      console.error(`Unknown command: ${command}`);
      showHelp();
      process.exit(1);
  }
}

main().catch(err => {
  console.error('FATAL:', err.message);
  process.exit(1);
});
