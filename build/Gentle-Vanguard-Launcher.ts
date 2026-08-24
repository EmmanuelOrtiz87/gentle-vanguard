#!/usr/bin/env node

/**
 * Gentle-Vanguard-Launcher.ts — Setup wizard + script launcher for Gentle-Vanguard
 *
 * Handles:
 *   - First-run setup wizard (full/minimal/reconfigure/environment check)
 *   - Embedded script archive extraction and AES-256-GCM decryption
 *   - Script caching to %LOCALAPPDATA%\Gentle-Vanguard
 *   - Delegating to gv.ts after installation
 *
 * Usage:
 *   npx tsx build/Gentle-Vanguard-Launcher.ts          # Interactive wizard (first run)
 *   npx tsx build/Gentle-Vanguard-Launcher.ts --launch # Launch installed CLI
 *   npx tsx build/Gentle-Vanguard-Launcher.ts --check  # Environment check
 */

import { createDecipheriv } from 'crypto';
import {
  readFileSync,
  writeFileSync,
  existsSync,
  mkdirSync,
  rmSync,
  readdirSync,
  statSync,
} from 'fs';
import { join, resolve, relative, extname, basename, dirname } from 'path';
import * as readline from 'readline';
import { execSync, spawn } from 'child_process';

const LAUNCHER_VERSION = '3.3.3';

const args = process.argv.slice(2);
const launchMode = args.includes('--launch') || args.includes('-Launch');
const checkMode = args.includes('--check') || args.includes('-Check');
const nonInteractive = args.includes('--non-interactive') || args.includes('-NonInteractive');

// Paths
const ROOT = resolve(process.cwd());
const appDataDir = join(
  process.env.LOCALAPPDATA || join(process.env.HOME || '', '.local', 'share'),
  'Gentle-Vanguard',
  'scripts',
);
const dataDir = join(
  process.env.LOCALAPPDATA || join(process.env.HOME || '', '.local', 'share'),
  'Gentle-Vanguard',
  'data',
);
const stateFile = join(dataDir, 'setup-state.json');
const cacheKeyPath = join(dataDir, 'master.key');
const cacheScript = join(appDataDir, 'scripts', 'utilities', 'WORKFLOW-ORCHESTRATION', 'gv.ps1');
const embeddedTempDir = join(process.env.TEMP || '/tmp', 'Gentle-Vanguard', 'embedded');

const ALGORITHM = 'aes-256-gcm';

// ─── I/O helpers ───────────────────────────────────────────────────────────────

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
function prompt(q: string): Promise<string> {
  return new Promise((resolve) => rl.question(q, resolve));
}

function log(msg: string): void {
  console.log(msg);
}
function step(label: string, msg: string): void {
  console.log(`  [${label}] ${msg}`);
}
function ok(msg: string): void {
  console.log(`  [OK] ${msg}`);
}
function warn(msg: string): void {
  console.log(`  [WARN] ${msg}`);
}
function fail(msg: string): void {
  console.error(`  [FAIL] ${msg}`);
}

function clearScreen(): void {
  console.clear();
}

function showBanner(): void {
  clearScreen();
  log('╔══════════════════════════════════════════════════╗');
  log('║         GENTLE-VANGUARD SETUP WIZARD v3.0       ║');
  log('║     AI-First Development Workspace Launcher     ║');
  log('╚══════════════════════════════════════════════════╝');
  log('');
}

// ─── Prerequisites ─────────────────────────────────────────────────────────────

interface PrereqIssue {
  name: string;
  message: string;
}

function checkPrerequisites(): PrereqIssue[] {
  const issues: PrereqIssue[] = [];

  // Check Node.js (we need it for tsx)
  const nodeVer = process.version;
  const major = parseInt(nodeVer.slice(1).split('.')[0], 10);
  if (major < 18) {
    issues.push({ name: 'Node.js', message: `Node.js 18+ required (found ${nodeVer})` });
  }

  // Check Git
  try {
    execSync('git --version', { stdio: 'pipe', timeout: 5000, windowsHide: true });
  } catch {
    issues.push({ name: 'Git', message: 'Git not found in PATH' });
  }

  return issues;
}

function showEnvironmentCheck(): void {
  showBanner();
  log('  ENVIRONMENT CHECK');
  log('  ==================');
  log('');

  const issues = checkPrerequisites();
  if (issues.length === 0) {
    ok('All prerequisites satisfied');
  } else {
    for (const issue of issues) {
      fail(`${issue.name}: ${issue.message}`);
    }
  }

  log(`  [INFO] Node.js: ${process.version}`);
  log(`  [INFO] Platform: ${process.platform} ${process.arch}`);
  log(`  [INFO] AppData: ${appDataDir}`);
  log(`  [INFO] Cache key: ${existsSync(cacheKeyPath) ? 'Present' : 'Not found'}`);
  log(`  [INFO] Installation: ${existsSync(stateFile) ? 'Configured' : 'Not configured'}`);

  log('');
  log('  Detected AI tools:');
  const tools: string[] = [];
  if (process.env.OPENCODE_SERVER_USERNAME) tools.push('OpenCode');
  if (process.env.CLAUDE_VSCODE_VERSION) tools.push('Claude Code');
  if (existsSync(join(ROOT, '.clinerules'))) tools.push('Cline');
  if (existsSync(join(ROOT, '.cursorrules'))) tools.push('Cursor');
  if (existsSync(join(ROOT, '.windsurf'))) tools.push('Windsurf');
  if (tools.length === 0) tools.push('None detected');
  for (const t of tools) log(`    - ${t}`);

  log('');
  log('Press Enter to continue...');
}

// ─── Key Management ────────────────────────────────────────────────────────────

function resolveMasterKey(): Buffer | null {
  const keyPaths = [
    cacheKeyPath,
    join(ROOT, 'master.key'),
    join(ROOT, 'keys', 'master.key'),
    join(dirname(ROOT), 'keys', 'master.key'),
  ];
  for (const p of keyPaths) {
    if (existsSync(p)) {
      const bytes = readFileSync(p);
      if (bytes.length === 32) return bytes;
    }
  }
  return null;
}

async function promptForKey(): Promise<Buffer | null> {
  log('');
  log('  MASTER KEY REQUIRED');
  log('  Encrypted scripts require a 32-byte master.key (Base64).');
  log('  Enter the key contents below:');
  const input = (await prompt('  > ')).trim();
  if (!input) return null;

  try {
    const bytes = Buffer.from(input, 'base64');
    if (bytes.length !== 32) {
      fail(`Invalid key: expected 32 bytes, got ${bytes.length}`);
      return null;
    }
    if (!existsSync(dataDir)) mkdirSync(dataDir, { recursive: true });
    writeFileSync(cacheKeyPath, bytes);
    ok(`Key cached to ${cacheKeyPath}`);
    return bytes;
  } catch (e) {
    fail(`Invalid Base64: ${(e as Error).message}`);
    return null;
  }
}

// ─── Encryption Helpers ────────────────────────────────────────────────────────

function decryptBytes(data: Buffer, key: Buffer): Buffer {
  const iv = data.subarray(0, 16);
  const authTag = data.subarray(16, 32);
  const encrypted = data.subarray(32);
  const decipher = createDecipheriv(ALGORITHM, key, iv);
  decipher.setAuthTag(authTag);
  return Buffer.concat([decipher.update(encrypted), decipher.final()]);
}

function decryptFile(encPath: string, key: Buffer): string {
  const data = readFileSync(encPath);
  const decrypted = decryptBytes(data, key);
  return decrypted.toString('utf-8');
}

function extractEmbeddedArchive(base64: string, outDir: string): number {
  const zipBytes = Buffer.from(base64, 'base64');
  const { execSync: exec } = require('child_process');
  // Write temp zip and extract
  const tmpZip = join(outDir, 'archive.zip');
  if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true });
  writeFileSync(tmpZip, zipBytes);

  const count = execSync(
    `powershell -NoProfile -Command "Expand-Archive -Path '${tmpZip}' -DestinationPath '${outDir}' -Force; (Get-ChildItem -Path '${outDir}' -Recurse -File).Count"`,
    { encoding: 'utf8', timeout: 30000, windowsHide: true },
  ).trim();

  rmSync(tmpZip, { force: true });
  return parseInt(count, 10) || 0;
}

// ─── Installation ──────────────────────────────────────────────────────────────

async function installScripts(mode: string): Promise<boolean> {
  let encBasePath: string | null = null;

  // Look for embedded archive (would be injected at build time)
  // For now, look for protected/ directory
  const candidates = [join(ROOT, 'build', 'protected'), join(ROOT, 'protected'), ROOT];

  for (const p of candidates) {
    if (existsSync(join(p, 'scripts', 'utilities', 'WORKFLOW-ORCHESTRATION', 'gv.ps1.enc'))) {
      encBasePath = p;
      break;
    }
  }

  if (!encBasePath) {
    warn('No protected scripts found. Using source scripts directly.');
    // Fall back to copying TS source files
    return installFromSource(mode);
  }

  const key = resolveMasterKey() || (await promptForKey());
  if (!key) {
    fail('Master key required to decrypt scripts.');
    return false;
  }

  try {
    const encFiles = readdirSync(encBasePath, { recursive: true }).filter((f) =>
      f.endsWith('.enc'),
    );
    let decryptedCount = 0;

    for (const relPath of encFiles) {
      const inputFile = join(encBasePath, relPath);
      const outputRel = relPath.replace(/\.enc$/, '');
      const outputFile = join(appDataDir, outputRel);
      const outputDir = dirname(outputFile);

      if (!existsSync(outputDir)) mkdirSync(outputDir, { recursive: true });

      const decrypted = decryptFile(inputFile, key);
      writeFileSync(outputFile, decrypted, 'utf-8');
      decryptedCount++;
    }

    ok(`Decrypted ${decryptedCount} scripts to AppData cache`);

    process.env.GENTLE_VANGUARD_BASE_DIR = ROOT;
    process.env.GENTLE_VANGUARD_APPDATA_DIR = appDataDir;
    process.env.GENTLE_VANGUARD_DATA_DIR = dataDir;

    const state = {
      version: LAUNCHER_VERSION,
      installMode: mode,
      timestamp: new Date().toISOString(),
      appDataDir,
      baseDir: ROOT,
    };

    if (!existsSync(dataDir)) mkdirSync(dataDir, { recursive: true });
    writeFileSync(stateFile, JSON.stringify(state, null, 2), 'utf-8');
    return true;
  } catch (e) {
    fail(`Failed to decrypt and install scripts: ${(e as Error).message}`);
    return false;
  }
}

async function installFromSource(mode: string): Promise<boolean> {
  ok('Copying source TS files as fallback...');
  const srcDirs = ['src', 'scripts'];
  let count = 0;

  for (const dir of srcDirs) {
    const srcPath = join(ROOT, dir);
    if (!existsSync(srcPath)) continue;
    copyDirSync(srcPath, join(appDataDir, dir));
    count++;
  }

  process.env.GENTLE_VANGUARD_BASE_DIR = ROOT;
  process.env.GENTLE_VANGUARD_APPDATA_DIR = appDataDir;
  process.env.GENTLE_VANGUARD_DATA_DIR = dataDir;

  const state = {
    version: LAUNCHER_VERSION,
    installMode: mode,
    timestamp: new Date().toISOString(),
    appDataDir,
    baseDir: ROOT,
  };

  if (!existsSync(dataDir)) mkdirSync(dataDir, { recursive: true });
  writeFileSync(stateFile, JSON.stringify(state, null, 2), 'utf-8');
  ok(`Installed from source (${count} directories)`);
  return true;
}

function copyDirSync(src: string, dest: string): void {
  if (!existsSync(dest)) mkdirSync(dest, { recursive: true });
  for (const entry of readdirSync(src, { withFileTypes: true })) {
    const s = join(src, entry.name);
    const d = join(dest, entry.name);
    if (entry.isDirectory()) {
      if (!['node_modules', '.git'].includes(entry.name)) copyDirSync(s, d);
    } else {
      writeFileSync(d, readFileSync(s));
    }
  }
}

// ─── UI Modes ──────────────────────────────────────────────────────────────────

async function doFullInstall(): Promise<void> {
  showBanner();
  log('  FULL INSTALLATION');
  log('  =================');
  log('');

  const issues = checkPrerequisites();
  if (issues.length > 0) {
    warn('Prerequisite issues detected:');
    for (const issue of issues) fail(`${issue.name}: ${issue.message}`);
    log('');
    const cont = await prompt('Continue anyway? (y/N): ');
    if (cont.toLowerCase() !== 'y') {
      log('Installation cancelled.');
      return;
    }
  }

  log('');
  const success = await installScripts('full');
  if (success) {
    log('');
    ok('Gentle-Vanguard installed successfully!');
    log('');
    log('  Next steps:');
    log('  1. Run "npx tsx build/Gentle-Vanguard-Launcher.ts --launch" to launch CLI');
    log('  2. Or run "npx tsx src/cli/gv.ts" for the Gentle-Vanguard CLI');
    log('');
    log(`  Scripts cached to: ${appDataDir}`);
    log(`  State saved to: ${stateFile}`);
  }
  log('');
  await prompt('Press Enter to continue...');
}

async function doMinimalInstall(): Promise<void> {
  showBanner();
  log('  MINIMAL INSTALLATION');
  log('  ====================');
  log('');
  warn('Minimal mode installs only the core launcher.');
  warn('Skills, tools, and extras are NOT included.');
  log('');
  const cont = await prompt('Proceed with minimal installation? (y/N): ');
  if (cont.toLowerCase() !== 'y') {
    log('Installation cancelled.');
    return;
  }

  const success = await installScripts('minimal');
  if (success) {
    log('');
    ok('Gentle-Vanguard (minimal) installed successfully!');
  }
  log('');
  await prompt('Press Enter to continue...');
}

async function doReconfigure(): Promise<void> {
  showBanner();
  log('  RECONFIGURE');
  log('  ===========');
  log('');

  if (!existsSync(stateFile)) {
    warn('No existing installation found. Run Full or Minimal installation first.');
    log('');
    await prompt('Press Enter to continue...');
    return;
  }

  const state = JSON.parse(readFileSync(stateFile, 'utf-8'));
  log('Current configuration:');
  log(JSON.stringify(state, null, 2));
  log('');
  log('Options:');
  log('  1. Re-install scripts (decrypt again)');
  log('  2. Clear cache and re-install');
  log('  3. Update master.key');
  log('  4. Reset everything (clear all cached data)');
  log('');

  const opt = (await prompt('Selection [1-4]: ')).trim();
  switch (opt) {
    case '1': {
      const s = await installScripts('reinstall');
      if (s) ok('Re-installation complete');
      break;
    }
    case '2': {
      rmSync(appDataDir, { recursive: true, force: true });
      const s = await installScripts('reinstall');
      if (s) ok('Re-installation complete');
      break;
    }
    case '3': {
      rmSync(cacheKeyPath, { force: true });
      const key = await promptForKey();
      if (key) {
        rmSync(appDataDir, { recursive: true, force: true });
        const s = await installScripts('reinstall');
        if (s) ok('Key updated, scripts re-installed');
      }
      break;
    }
    case '4': {
      const confirm = await prompt('This will remove ALL cached data. Continue? (y/N): ');
      if (confirm.toLowerCase() === 'y') {
        rmSync(appDataDir, { recursive: true, force: true });
        rmSync(dataDir, { recursive: true, force: true });
        ok('All cached data cleared');
      }
      break;
    }
  }
  log('');
  await prompt('Press Enter to continue...');
}

function doLaunch(): void {
  const gvScript = join(ROOT, 'src', 'cli', 'gv.ts');
  if (!existsSync(gvScript)) {
    fail('gv.ts not found. Cannot launch CLI.');
    process.exit(1);
  }

  process.env.GENTLE_VANGUARD_BASE_DIR = ROOT;
  process.env.GENTLE_VANGUARD_APPDATA_DIR = appDataDir;
  process.env.GENTLE_VANGUARD_DATA_DIR = dataDir;

  // Delegate to gv.ts. Preferred: node-direct via in-process tsx loader
  // (hidden on Windows, no npx.cmd chain). Fallback: `npx --yes tsx` (shell)
  // when tsx is not installed yet (fresh minimal install).
  let child: ReturnType<typeof spawn>;
  let tsxInstalled = false;
  try {
    require.resolve('tsx/package.json', { paths: [ROOT] });
    tsxInstalled = true;
  } catch {
    tsxInstalled = false;
  }
  const passArgs = args.filter((a) => a !== '--launch');
  if (tsxInstalled) {
    child = spawn(process.execPath, ['--import', 'tsx', gvScript, ...passArgs], {
      stdio: 'inherit',
      cwd: ROOT,
      windowsHide: true,
    });
  } else {
    child = spawn(`npx --yes tsx "${gvScript}" ${passArgs.join(' ')}`, {
      stdio: 'inherit',
      shell: true,
      cwd: ROOT,
      windowsHide: true,
    });
  }
  child.on('close', (code) => process.exit(code ?? 0));
}

// ─── Main Menu ─────────────────────────────────────────────────────────────────

async function showMainMenu(): Promise<string> {
  showBanner();
  log('  SELECT INSTALLATION MODE:');
  log('');
  log('  1. Full Installation (recommended)');
  log('     Install all components: core, skills, configs, tools');
  log('');
  log('  2. Minimal Installation');
  log('     Core launcher only: essential scripts');
  log('');
  log('  3. Reconfigure');
  log('     Re-run configuration, fix paths, update settings');
  log('');
  log('  4. Environment Check');
  log('     Verify prerequisites, detect installed tools');
  log('');
  log('  5. Help / About');
  log('     Version info, key management, documentation links');
  log('');
  log('  6. Exit');
  log('');
  return (await prompt('  Selection [1-6]: ')).trim();
}

function showHelp(): void {
  showBanner();
  log('  HELP / ABOUT');
  log('  ============');
  log('');
  log(`  Gentle-Vanguard v${LAUNCHER_VERSION} — AI-First Development Workspace`);
  log('');
  log('  What this does:');
  log('  Decrypts and runs the Gentle-Vanguard AI orchestration stack.');
  log('  Encrypted scripts are embedded for secure distribution.');
  log('');
  log('  First-time setup:');
  log('  1. Run this launcher — the wizard will guide you through setup');
  log('  2. You need a master.key (32 bytes, Base64) to decrypt scripts');
  log('  3. Scripts are cached to %LOCALAPPDATA%\\Gentle-Vanguard\\scripts');
  log('  4. After setup, run again with --launch to launch the CLI');
  log('');
  log('  Commands:');
  log('    --launch       Launch workspace CLI');
  log('    --check        Environment check');
  log('    --help         Show this help');
  log('');
  log('  Documentation: docs/AGENTS.md');
  log('');
}

async function main(): Promise<void> {
  if (checkMode) {
    showEnvironmentCheck();
    rl.close();
    return;
  }

  if (launchMode) {
    doLaunch();
    return;
  }

  if (args.includes('--help') || args.includes('-Help') || args.includes('/?')) {
    showHelp();
    rl.close();
    return;
  }

  const isFirstRun = !existsSync(stateFile);

  if (isFirstRun) {
    while (true) {
      const choice = await showMainMenu();
      switch (choice) {
        case '1':
          await doFullInstall();
          break;
        case '2':
          await doMinimalInstall();
          break;
        case '3':
          await doReconfigure();
          break;
        case '4':
          showEnvironmentCheck();
          break;
        case '5':
          showHelp();
          await prompt('Press Enter to continue...');
          break;
        case '6':
          log('Exiting...');
          rl.close();
          return;
        default:
          warn('Invalid selection. Choose 1-6.');
      }
    }
  } else {
    doLaunch();
  }
}

main().catch((err) => {
  console.error('FATAL:', err.message);
  process.exit(1);
});
