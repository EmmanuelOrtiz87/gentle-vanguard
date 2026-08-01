#!/usr/bin/env node
/**
 * session-autostart-detached.ts — Fire-and-forget launcher for the autostart pipeline.
 *
 * WHY THIS EXISTS
 * --------------
 * The autostart pipeline spawns lazy background daemons (e.g. ci-rollback-engine
 * with its setInterval health-check timer). On Windows, spawning those via a
 * `shell:true` chain (cmd.exe -> npx.cmd -> node) lets the daemons inherit the
 * calling shell's stdout pipe handles. Even though the autostart process itself
 * now calls `process.exit(0)` (see src/core/session-autostart.ts), the daemons
 * keep the pipe open, so a synchronous caller (CI step, hook, or an agent shell)
 * waits for EOF forever and hits an artificial timeout.
 *
 * This launcher detaches the autostart completely:
 *   - spawn with `detached: true`  -> new console/process group, no pipe shared
 *   - `stdio: 'ignore'`            -> child stdout/stderr go to NUL, never the caller's pipe
 *   - `windowsHide: true`          -> no flashing console window
 *   - `child.unref()`              -> parent can exit immediately
 *
 * It writes nothing to stdout/stderr so callers return instantly. The autostart
 * writes its own logs (session-autostart.log / lazy log) as usual.
 *
 * USAGE
 * -----
 *   npx tsx src/session-autostart-detached.ts
 *   npm run session:autostart:detached
 *
 * To run the autostart synchronously and wait for it, use the normal entry:
 *   npx tsx src/session-autostart.ts
 */

import { spawn } from 'node:child_process';
import * as path from 'node:path';
import * as fs from 'node:fs';

const ROOT = path.resolve(import.meta.dirname, '..');

// Persist the detached autostart stdout/stderr to a log file so the pipeline
// run remains observable even though nothing is written to the caller's pipe.
const LOG_DIR = path.join(ROOT, '.runtime');
fs.mkdirSync(LOG_DIR, { recursive: true });
const LOG_PATH = path.join(LOG_DIR, 'autostart-detached.log');

const args = process.argv.slice(2);

// Spawn the real autostart directly with Node + tsx loader. This avoids the
// cmd.exe/npx.cmd wrapper chain entirely: with `detached: true` and an opened
// file descriptor for stdout/stderr, the child tree writes to the log file
// directly and never inherits the caller's stdout/stderr pipe. This is the
// robust way to fire-and-forget a daemon-spawning pipeline on Windows.
const logFd = fs.openSync(LOG_PATH, 'a');
const child = spawn(
  process.execPath,
  ['--import', 'tsx', path.join(ROOT, 'src', 'session-autostart.ts'), ...args],
  {
    cwd: ROOT,
    stdio: ['ignore', logFd, logFd],
    windowsHide: true,
    detached: true,
  },
);

child.once('exit', () => {
  try {
    fs.closeSync(logFd);
  } catch {
    /* already closed */
  }
});
child.unref();

// Nothing is printed on purpose — the caller should return immediately and
// not depend on any output from the detached background process. The pipeline
// log is available at .runtime/autostart-detached.log (and the lazy step log
// at logs/session-autostart-lazy.log).
