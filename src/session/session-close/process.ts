import { runSync } from '../../core/run-command.js';

export interface KillTarget {
  name: string;
  matcher: string;
  /** Required daemons are started by session-autostart and MUST be running at close. */
  required: boolean;
}

export const KILL_TARGETS: KillTarget[] = [
  { name: 'CodeGraph MCP', matcher: 'codegraph.*mcp', required: true },
  // Dashboard WS persists between sessions; its Apps Control Panel owns lifecycle.
  { name: 'Timeout Daemon', matcher: 'timeout-monitor.*daemon', required: true },
  // Optional daemon: the token-ingest --watch loop survives the close today and
  // keeps appending to .runtime/token-ingest.log. Not required → SKIP if it was
  // never started; never FAILs (avoids false positives in the close report).
  { name: 'Token Ingest', matcher: 'token-ingest', required: false },
];

/** True if at least one process (node/tsx) matches the command-line matcher. */
export function isProcessRunning(matcher: string): boolean {
  const isWin = process.platform === 'win32';
  try {
    if (isWin) {
      const psCmd = `@(@(Get-CimInstance Win32_Process -Filter "Name='node.exe' OR Name='tsx.exe'" | Where-Object { $_.CommandLine -match '${matcher}' -and $_.ProcessId -ne ${process.pid} -and $_.CommandLine -notmatch 'session-close-orchestrator' })).Count`;
      const r = runSync('powershell', ['-NoProfile', '-Command', psCmd], {
        timeout: 10000,
        stdio: 'pipe',
      });
      const count = parseInt((r.stdout ?? '').trim(), 10);
      return !isNaN(count) && count > 0;
    }
    // Array form: matcher may contain spaces/quotes — shell quoting is unreliable.
    const r = runSync('pgrep', ['-f', matcher], { timeout: 5000 });
    return r.status === 0;
  } catch {
    return false;
  }
}

/**
 * Poll for a matching process to appear, up to timeoutMs. The daemons are
 * started lazily by session-autostart and can still be booting if the session
 * closes quickly, so we give them a short window before deciding they're down.
 */
/**
 * True when the close protocol is running at SESSION STARTUP rather than at a
 * real session end. The autostart pipeline launches this orchestrator with
 * --reason autostart-close (and the lightweight mode uses 'startup-cleanup').
 * In those cases the daemons (codegraph, timeout, dashboard WS) were JUST
 * started by the autostart, so the daemon-kill phase must be skipped.
 */
export function isStartupClose(reason: string): boolean {
  return reason === 'autostart-close' || reason === 'startup-cleanup';
}

export function waitForProcess(matcher: string, timeoutMs: number): boolean {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (isProcessRunning(matcher)) return true;
    // Synchronous ~500ms sleep (Atomics.wait on a shared buffer).
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 500);
  }
  return isProcessRunning(matcher);
}

export function killProcessByCommandLine(matcher: string): boolean {
  const isWin = process.platform === 'win32';
  try {
    if (isWin) {
      // Windows: use CIM to find and kill processes matching command line.
      // Safety: NEVER kill the orchestrator itself or its ancestors. Exclude:
      //   - the current PID
      //   - the parent PID (npx/cmd wrapper that spawned tsx)
      //   - any process whose CommandLine references this script by name
      //     (protects the whole process tree: npx → tsx → orchestrator)
      const selfName = 'session-close-orchestrator';
      const psCmd = `Get-CimInstance Win32_Process -Filter "Name='node.exe' OR Name='tsx.exe'" | Where-Object { $_.CommandLine -match '${matcher}' -and $_.ProcessId -ne ${process.pid} -and $_.ProcessId -ne ${process.ppid ?? -1} -and $_.CommandLine -notmatch '${selfName}' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force; Write-Output "Killed PID $($_.ProcessId)" }`;
      const r = runSync('powershell', ['-NoProfile', '-Command', psCmd], {
        timeout: 15000,
        stdio: 'pipe',
      });
      const out = r.stdout.trim();
      return out.length > 0; // true if at least one process was killed
    } else {
      // Unix: use pkill -f, excluding the current process
      runSync('pkill', ['-f', matcher], { timeout: 10000, stdio: 'pipe' });
      // Verify if any matching processes (other than self) were killed
      const pgrep = runSync('pgrep', ['-f', matcher], { timeout: 5000 });
      return pgrep.status !== 0;
    }
  } catch {
    return false;
  }
}
