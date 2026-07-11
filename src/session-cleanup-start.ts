#!/usr/bin/env node
import {
  existsSync,
  readFileSync,
  writeFileSync,
  mkdirSync,
  readdirSync,
  rmSync,
  statSync,
} from 'fs';
import { join, resolve } from 'path';
import { pathToFileURL } from 'url';
import { spawnSync } from 'child_process';

const ROOT = resolve(process.cwd());

function log(msg: string) {
  console.log(`[CLEANUP] ${msg}`);
}
function ok(msg: string) {
  console.log(`[CLEANUP] ${msg}`);
}
function warn(msg: string) {
  console.log(`[CLEANUP] ${msg}`);
}

function runPs1(script: string, ...args: string[]): { ok: boolean; output: string } {
  const fullPath = join(ROOT, script);
  if (!existsSync(fullPath)) return { ok: false, output: `Script not found: ${script}` };
  try {
    const r = spawnSync('pwsh', ['-NoProfile', '-File', fullPath, ...args], {
      cwd: ROOT,
      stdio: 'pipe',
      timeout: 30000,
    });
    return {
      ok: r.status === 0,
      output: (r.stdout?.toString() ?? '') + (r.stderr?.toString() ?? ''),
    };
  } catch (e: any) {
    return { ok: false, output: e.message };
  }
}

function removeStaleSessions(sessionDir: string): void {
  if (!existsSync(sessionDir)) return;
  const cutoff = Date.now() - 8 * 3600000;
  const today = new Date().toISOString().slice(0, 10);
  for (const f of readdirSync(sessionDir).filter((f) => f.endsWith('.json'))) {
    const fp = join(sessionDir, f);
    if (statSync(fp).mtimeMs < cutoff && !f.includes(today)) {
      rmSync(fp, { force: true });
      ok(`Removed stale: ${f}`);
    }
  }
}

function flushCaches(sessionDir: string): void {
  const targets = [
    { path: join(sessionDir, 'normativa-cache'), type: 'dir' as const },
    { path: join(sessionDir, 'preprocess-response-cache.json'), type: 'file' as const },
    { path: join(sessionDir, 'token-usage.json'), type: 'file' as const },
    { path: join(sessionDir, 'prompt-cache'), type: 'dir' as const },
  ];
  let flushed = 0;
  for (const t of targets) {
    if (existsSync(t.path)) {
      if (t.type === 'dir') {
        rmSync(t.path, { recursive: true, force: true });
        mkdirSync(t.path, { recursive: true });
      } else {
        rmSync(t.path, { force: true });
      }
      flushed++;
    }
  }
  for (const d of ['normativa-cache', 'prompt-cache']) {
    const fp = join(sessionDir, d);
    if (!existsSync(fp)) mkdirSync(fp, { recursive: true });
  }
  ok(`Flushed ${flushed} cache targets`);

  const tokenFile = join(sessionDir, 'token-usage.json');
  const sid = `session-${new Date().toISOString().slice(0, 16).replace(/[:-]/g, '')}`;
  writeFileSync(
    tokenFile,
    JSON.stringify(
      {
        sessionId: sid,
        startTime: new Date().toISOString(),
        messages: [],
        totalInputTokens: 0,
        totalOutputTokens: 0,
        totalTokens: 0,
        totalContextChars: 0,
        messageCount: 0,
      },
      null,
      2,
    ),
  );
  ok(`Token tracking reset for ${sid}`);
}

export function runCleanup(
  opts: {
    workspaceRoot?: string;
    skipOrphanCleanup?: boolean;
    skipCacheFlush?: boolean;
    skipCompression?: boolean;
    quiet?: boolean;
  } = {},
): boolean {
  const repoRoot = opts.workspaceRoot ?? ROOT;
  const sessionDir = join(repoRoot, '.session');
  const sessionDir2 = join(repoRoot, 'session');

  if (!opts.skipOrphanCleanup) {
    log('Closing orphaned sessions...');
    const r = runPs1(
      'scripts/utilities/session-manager.ps1',
      '-Mode',
      'Cleanup',
      '-OrphanMaxAgeHours',
      '8',
      '-NoExit',
    );
    if (r.ok) ok('Orphan cleanup done');
    removeStaleSessions(sessionDir2);
  }

  if (!opts.skipCacheFlush) {
    log('Flushing session caches...');
    flushCaches(sessionDir);
  }

  if (!opts.skipCompression) {
    log('Generating compressed CLAUDE.min.md...');
    const compressor = join(repoRoot, 'scripts/utilities/semantic-compression.ps1');
    if (existsSync(compressor)) {
      const claudePath = join(repoRoot, 'CLAUDE.md');
      const minPath = join(sessionDir, 'CLAUDE.min.md');
      if (existsSync(claudePath)) {
        runPs1(
          'scripts/utilities/semantic-compression.ps1',
          '-InputPath',
          claudePath,
          '-OutputPath',
          minPath,
          '-Aggressive',
        );
        if (existsSync(minPath)) {
          const origSize = statSync(claudePath).size;
          const minSize = statSync(minPath).size;
          ok(
            `CLAUDE.min.md generated: ${origSize} -> ${minSize} chars (${Math.round((1 - minSize / origSize) * 100)}% reduction)`,
          );
        }
      }
    } else {
      warn('Compressor not found, skipping');
    }
  }

  log('Closing session tracing span...');
  const spanDir = join(repoRoot, '.telemetry', 'spans');
  if (existsSync(spanDir)) {
    const spans = readdirSync(spanDir)
      .filter((f) => f.startsWith('spans-') && f.endsWith('.jsonl'))
      .sort()
      .reverse();
    if (spans.length > 0) {
      const content = readFileSync(join(spanDir, spans[0]), 'utf-8');
      const lines = content.split('\n').filter((l) => l.trim());
      for (const line of lines) {
        try {
          const span = JSON.parse(line);
          if (span.name === 'session-start') {
            const tracingScript = join(repoRoot, 'src/tracing-instrument.ts');
            if (existsSync(tracingScript)) {
              spawnSync(
                'npx',
                [
                  'tsx',
                  tracingScript,
                  '-Action',
                  'end',
                  '-TraceId',
                  span.traceId,
                  '-SpanId',
                  span.spanId,
                  '-SpanName',
                  'session-start',
                  '-Quiet',
                ],
                { cwd: repoRoot, stdio: 'pipe', timeout: 15000 },
              );
            }
            ok('Tracing span closed');
            break;
          }
        } catch {
          /* skip */
        }
      }
    }
  }

  log('Pruning old checkpoints...');
  runPs1('src/checkpoint-manager.ts'); // TS script — run via npx tsx
  const ckptMgr = join(ROOT, 'src/checkpoint-manager.ts');
  if (existsSync(ckptMgr)) {
    spawnSync('npx', ['tsx', ckptMgr, 'prune'], { cwd: ROOT, stdio: 'pipe', timeout: 15000 });
    ok('Checkpoint prune done');
  }

  log('Logging session end to audit...');
  const auditScript = join(ROOT, 'src/audit-pipeline.ts');
  if (existsSync(auditScript)) {
    spawnSync(
      'npx',
      [
        'tsx',
        auditScript,
        'log',
        '-EventType',
        'session.end',
        '-Component',
        'system',
        '-Operation',
        'cleanup',
        '-Actor',
        'system',
        '-Status',
        'success',
        '-Message',
        'Session cleanup completed',
        '-Quiet',
      ],
      { cwd: ROOT, stdio: 'pipe', timeout: 15000 },
    );
    ok('Audit session-end logged');
  }

  log('Recording session-close event...');
  const evtStore = join(ROOT, 'src/event-sourcing.ts');
  if (existsSync(evtStore)) {
    const aggId = `session-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}`;
    spawnSync(
      'npx',
      [
        'tsx',
        evtStore,
        '-Action',
        'append',
        '-AggregateId',
        aggId,
        '-EventType',
        'session.ended',
        '-EventData',
        '{"duration":"cleanup"}',
        '-Quiet',
      ],
      { cwd: ROOT, stdio: 'pipe', timeout: 15000 },
    );
    ok('Session end event recorded');
  }

  ok('Session cleanup complete');
  return true;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const args = process.argv.slice(2);
  const opts: Parameters<typeof runCleanup>[0] = {};
  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '-WorkspaceRoot':
        opts.workspaceRoot = args[++i];
        break;
      case '-SkipOrphanCleanup':
        opts.skipOrphanCleanup = true;
        break;
      case '-SkipCacheFlush':
        opts.skipCacheFlush = true;
        break;
      case '-SkipCompression':
        opts.skipCompression = true;
        break;
      case '-Quiet':
        opts.quiet = true;
        break;
    }
  }
  runCleanup(opts);
}
