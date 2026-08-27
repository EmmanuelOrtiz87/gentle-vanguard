/**
 * Forensic probe v2: logs every fs event touching .session/session-current.json
 * PLUS a snapshot of running node/tsx/pwsh processes on delete events and on a
 * 30s heartbeat, to correlate deletions with the responsible process.
 *
 * Usage: npx tsx scripts/debug/session-file-probe.ts <durationSeconds>
 * Log:   .runtime/session-file-probe.log
 */
import { watch, existsSync, appendFileSync } from 'fs';
import { execSync } from 'child_process';
import { join } from 'path';

const ROOT = process.cwd();
const TARGET_DIR = join(ROOT, '.session');
const TARGET = join(TARGET_DIR, 'session-current.json');
const LOG = join(ROOT, '.runtime', 'session-file-probe.log');

const durationSec = parseInt(process.argv[2] || '600', 10);
const t0 = Date.now();

function stamp(): string {
  return `+${((Date.now() - t0) / 1000).toFixed(2)}s ${new Date().toISOString()}`;
}

function log(msg: string): void {
  appendFileSync(LOG, `${stamp()} ${msg}\n`, 'utf-8');
}

/** Snapshot node/tsx/pwsh/cmd processes with PID + truncated command line. */
function procSnapshot(): string {
  try {
    const out = execSync(
      'powershell -NoProfile -Command "Get-CimInstance Win32_Process | ' +
        "Where-Object { $_.Name -match 'node|pwsh|powershell|cmd' } | " +
        'Select-Object ProcessId,CreationDate,CommandLine | ' +
        'ConvertTo-Csv -NoTypeInformation" 2>$null',
      { encoding: 'utf-8', timeout: 8000, windowsHide: true },
    );
    return out
      .split('\n')
      .filter((l) => l.trim())
      .slice(0, 40)
      .map((l) => (l.length > 220 ? l.slice(0, 220) : l))
      .join(' | ');
  } catch (e) {
    return `SNAPSHOT_FAIL ${(e as Error).message.slice(0, 80)}`;
  }
}

log(`PROBE-V2 START target=${TARGET} exists=${existsSync(TARGET)} duration=${durationSec}s`);

let lastHeartbeat = Date.now();
const watcher = watch(TARGET_DIR, { persistent: false }, (eventType, filename) => {
  if (filename && filename.replace(/\\/g, '/') !== 'session-current.json') return;
  const ex = existsSync(TARGET);
  if (!ex) {
    // DELETE or pre-rename absence — capture processes IMMEDIATELY
    log(`DELETE-EVENT type=${eventType}`);
    log(`PROCS-AT-DELETE: ${procSnapshot()}`);
  } else {
    log(`EVENT type=${eventType} nowExists=true`);
  }
});

const hb = setInterval(() => {
  if (Date.now() - lastHeartbeat >= 30000) {
    lastHeartbeat = Date.now();
    log(`HEARTBEAT exists=${existsSync(TARGET)}`);
  }
}, 5000);

setTimeout(() => {
  log(`PROBE-V2 END finalExists=${existsSync(TARGET)}`);
  clearInterval(hb);
  watcher.close();
  process.exit(0);
}, durationSec * 1000);
