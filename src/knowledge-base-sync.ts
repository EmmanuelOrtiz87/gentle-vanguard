#!/usr/bin/env node
/**
 * Knowledge Base Sync — syncs engram, sessions, documents, and backups.
 * TS migration of scripts/utilities/knowledge-base/knowledge-base-sync.ps1
 */

import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  copyFileSync,
  writeFileSync,
  rmSync,
  statSync,
} from 'fs';
import { join, resolve, relative, dirname } from 'path';
import { execSync, spawnSync } from 'child_process';
import { pathToFileURL } from 'url';

type SyncMode = 'full' | 'engram' | 'sessions' | 'documents' | 'backup';

interface CliArgs {
  mode: SyncMode;
  dryRun: boolean;
  quiet: boolean;
}

interface FolderConfig {
  inbox: string;
  projects: string;
  architecture: string;
  skills: string;
  sessions: string;
  research: string;
  templates: string;
  archive: string;
}

interface SyncConfig {
  folders: FolderConfig;
  backup: { path: string; enabled: boolean };
}

const validModes: SyncMode[] = ['full', 'engram', 'sessions', 'documents', 'backup'];

function findProjectRoot(dir: string): string {
  let current = resolve(dir);
  for (let i = 0; i < 8; i++) {
    if (existsSync(join(current, '.git'))) return current;
    const parent = resolve(current, '..');
    if (!parent || parent === current) break;
    current = parent;
  }
  return dir;
}

const projectRoot = findProjectRoot(process.cwd());
const vaultPath = join(projectRoot, 'knowledge-base');
const configPath = join(projectRoot, 'config', 'knowledge-base-config.json');
let _quiet = false;
let _dryRun = false;

function log(msg: string, level: string = 'INFO'): void {
  if (_quiet) return;
  const prefix = `[${level}]`;
  if (level === 'ERROR') console.error(`${prefix} ${msg}`);
  else console.log(`${prefix} ${msg}`);
}

function getConfig(): SyncConfig | null {
  if (existsSync(configPath)) {
    try {
      return JSON.parse(readFileSync(configPath, 'utf-8')) as SyncConfig;
    } catch {
      return null;
    }
  }
  return null;
}

function syncEngramToVault(): void {
  const engramCheck = spawnSync('where', ['engram'], { encoding: 'utf-8', windowsHide: true });

  if (engramCheck.status !== 0) {
    log('Engram not found - skipping Engram sync', 'WARN');
    return;
  }

  const config = getConfig();
  if (!config) {
    log('Config not found - skipping Engram sync', 'WARN');
    return;
  }

  const sessionsFolder = join(vaultPath, config.folders.sessions);
  if (!existsSync(sessionsFolder)) {
    mkdirSync(sessionsFolder, { recursive: true });
  }

  try {
    const result1 = execSync('engram search "session_summary" --project gentle-vanguard --limit 100', {
      encoding: 'utf-8',
      timeout: 30000,
      windowsHide: true,
    });

    if (/\d+\s+observations/.test(result1)) {
      log('Found session summaries in Engram', 'OK');
    }

    const result2 = execSync('engram search "architecture" --project gentle-vanguard --limit 50', {
      encoding: 'utf-8',
      timeout: 30000,
      windowsHide: true,
    });

    if (/\d+\s+observations/.test(result2)) {
      log('Found architecture notes in Engram', 'OK');
    }

    log('Engram sync completed', 'OK');
  } catch (e: unknown) {
    log(`Engram sync failed: ${e instanceof Error ? e.message : String(e)}`, 'ERROR');
  }
}

function syncSessionsToVault(): void {
  const config = getConfig();
  if (!config) {
    log('Config not found - skipping session sync', 'WARN');
    return;
  }

  const sessionDir = join(projectRoot, '.session');
  const sessionsFolder = join(vaultPath, config.folders.sessions);

  if (!existsSync(sessionDir)) {
    log('Session directory not found - skipping session sync', 'WARN');
    return;
  }

  const contextLogPath = join(sessionDir, 'context-log');
  if (!existsSync(contextLogPath)) {
    log('Context log not found - skipping session sync', 'WARN');
    return;
  }

  const entries = readdirSync(contextLogPath, { withFileTypes: true });
  const sessionDirs = entries
    .filter(e => e.isDirectory())
    .map(e => ({
      name: e.name,
      path: join(contextLogPath, e.name),
      mtime: existsSync(join(contextLogPath, e.name)) ? (() => {
        try {
          const s = readdirSync(join(contextLogPath, e.name));
          return s.length;
        } catch { return 0; }
      })() : 0,
    }))
    .sort((a, b) => {
      const aStat = statSyncSafe(a.path);
      const bStat = statSyncSafe(b.path);
      return Number(bStat?.mtimeMs ?? 0) - Number(aStat?.mtimeMs ?? 0);
    })
    .slice(0, 10);

  let synced = 0;
  for (const session of sessionDirs) {
    const summaryFile = join(session.path, 'context-summary.md');
    if (!existsSync(summaryFile)) continue;

    const content = readFileSync(summaryFile, 'utf-8');
    const sessionId = session.name;
    const targetFile = join(sessionsFolder, `${sessionId}-summary.md`);

    if (!existsSync(targetFile)) {
      if (!_dryRun) {
        const sStat = statSyncSafe(session.path);
        const createdDate = sStat ? sStat.mtime.toISOString().slice(0, 10) : new Date().toISOString().slice(0, 10);
        const frontmatter = [
          '---',
          `created: ${createdDate}`,
          `tags: [session, #${sessionId}]`,
          `session_id: ${sessionId}`,
          '---',
          '',
        ].join('\n');
        writeFileSync(targetFile, frontmatter + content, 'utf-8');
      }
      synced++;
      log(`Synced session: ${sessionId}`, 'OK');
    }
  }

  log(`Synced ${synced} sessions to vault`, 'OK');
}

function statSyncSafe(p: string): ReturnType<typeof statSync> | null {
  try {
    return statSync(p);
  } catch {
    return null;
  }
}

function syncDocumentsToVault(): void {
  const config = getConfig();
  if (!config) {
    log('Config not found - skipping document sync', 'WARN');
    return;
  }

  const docsArchive = join(projectRoot, 'docs-archive');
  const researchFolder = join(vaultPath, config.folders.research);

  if (!existsSync(docsArchive)) {
    log('docs-archive not found - skipping document sync', 'WARN');
    return;
  }

  const mdFiles: string[] = [];
  function walkDir(dir: string): void {
    const entries = readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const full = join(dir, entry.name);
      if (entry.isDirectory()) walkDir(full);
      else if (entry.name.endsWith('.md')) mdFiles.push(full);
    }
  }
  walkDir(docsArchive);

  let synced = 0;
  for (const filePath of mdFiles) {
    const relPath = relative(docsArchive, filePath);
    const targetPath = join(researchFolder, relPath);
    const targetDir = dirname(targetPath);

    if (!existsSync(targetDir)) {
      mkdirSync(targetDir, { recursive: true });
    }

    if (!existsSync(targetPath)) {
      if (!_dryRun) {
        copyFileSync(filePath, targetPath);
      }
      synced++;
    }
  }

  log(`Synced ${synced} documents to vault`, 'OK');
}

function backupVault(): void {
  const config = getConfig();
  if (!config || !config.backup) {
    log('Backup config not found - skipping backup', 'WARN');
    return;
  }

  const backupDir = join(projectRoot, config.backup.path);
  if (!existsSync(backupDir)) {
    mkdirSync(backupDir, { recursive: true });
  }

  const now = new Date();
  const timestamp = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}_${String(now.getHours()).padStart(2, '0')}-${String(now.getMinutes()).padStart(2, '0')}-${String(now.getSeconds()).padStart(2, '0')}`;
  const backupFile = join(backupDir, `knowledge-base-${timestamp}.zip`);

  if (!_dryRun) {
    try {
      execSync(
        `powershell -NoProfile -Command "Compress-Archive -Path '${vaultPath}\\*' -DestinationPath '${backupFile}' -Force"`,
        { timeout: 60000, windowsHide: true },
      );
      log(`Backup created: ${backupFile}`, 'OK');
    } catch (e: unknown) {
      log(`Backup failed: ${e instanceof Error ? e.message : String(e)}`, 'ERROR');
    }
  } else {
    log(`Would create backup: ${backupFile}`, 'OK');
  }

  // clean up old backups — keep last 7
  if (existsSync(backupDir)) {
    const backupFiles = readdirSync(backupDir)
      .filter(f => f.startsWith('knowledge-base-') && f.endsWith('.zip'))
      .map(f => ({
        name: f,
        path: join(backupDir, f),
        mtime: Number(statSyncSafe(join(backupDir, f))?.mtimeMs ?? 0),
      }))
      .sort((a, b) => b.mtime - a.mtime);

    const toRemove = backupFiles.slice(7);
    for (const old of toRemove) {
      if (!_dryRun) {
        rmSync(old.path, { force: true });
        log(`Removed old backup: ${old.name}`, 'OK');
      }
    }
  }
}

function invokeFullSync(mode: SyncMode): void {
  log('Starting full knowledge base sync...', 'INFO');

  if (mode === 'full' || mode === 'engram') syncEngramToVault();
  if (mode === 'full' || mode === 'sessions') syncSessionsToVault();
  if (mode === 'full' || mode === 'documents') syncDocumentsToVault();

  if (mode === 'full' || mode === 'backup') {
    const config = getConfig();
    if (config?.backup?.enabled) {
      backupVault();
    }
  }

  log('Sync completed successfully', 'OK');
}

function main(): void {
  const args = process.argv.slice(2);

  const parsed: CliArgs = {
    mode: 'full',
    dryRun: false,
    quiet: false,
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--mode': case '-m': {
        const val = args[++i] as SyncMode;
        if (validModes.includes(val)) parsed.mode = val;
        break;
      }
      case '--dry-run': parsed.dryRun = true; break;
      case '--quiet': parsed.quiet = true; break;
    }
  }

  _quiet = parsed.quiet;
  _dryRun = parsed.dryRun;

  if (parsed.dryRun) {
    log('Running in DRY-RUN mode - no changes will be made', 'WARN');
  }

  invokeFullSync(parsed.mode);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
