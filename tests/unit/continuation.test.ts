#!/usr/bin/env node
/**
 * Unit Tests: continuation + ack-before-burn + typed-refusal
 *
 * Absorbed from gentle-ai v2.5.0-rc.3 ("Re-entry ships with the freeze") and
 * rc.2 ("approval waits to be acknowledged"):
 *   - recordContinuation publishes the verbatim re-entry command (no prose).
 *   - CAS: re-recording the same key replaces in place, version+1 — one owner.
 *   - resolveContinuation validates root binding + selector echo, refuses
 *     replays typed, never with raw filesystem errors.
 *   - stageAck + acknowledge: only the EXACT token burns; wrong/stale/replayed
 *     acks refuse and leave no receipt, tombstone or authority behind.
 *   - nextTransition answers "what do I run now?" with the active envelope.
 *   - writeEvidence files only refusals that started something.
 */

import { test, beforeEach, after } from 'node:test';
import assert from 'node:assert';
import { mkdtempSync, rmSync, existsSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import {
  recordContinuation,
  getContinuation,
  resolveContinuation,
  nextTransition,
  stageAck,
  getPendingAck,
  acknowledge,
  setContinuationBaseDir,
  CONTINUATION_CONTRACT,
} from '../../src/core/continuation.ts';
import {
  refusal,
  describe as describeRefusal,
  writeEvidence,
  isTypedRefusal,
} from '../../src/core/typed-refusal.ts';

let dir: string;

beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), 'gv-continuation-'));
  setContinuationBaseDir(dir);
});

after(() => setContinuationBaseDir(null));

test('recordContinuation publishes the verbatim command (re-entry ships with the freeze)', () => {
  const env = recordContinuation({
    workflowId: 'rdd-abc-1',
    operation: 'rdd.classify',
    args: { workflow: 'rdd-abc-1' },
    command: 'npx tsx src/rdd/rdd-core.ts classify --workflow=rdd-abc-1',
    selectorArguments: '--base-ref=main --committed-only',
    requireEcho: true,
    root: process.cwd(),
  });
  assert.equal(env.contract, CONTINUATION_CONTRACT);
  assert.equal(env.command, 'npx tsx src/rdd/rdd-core.ts classify --workflow=rdd-abc-1');
  assert.equal(env.status, 'active');
  assert.equal(env.version, 1);

  // nextTransition answers "what do I run now?" with the SAME envelope
  const next = nextTransition('rdd-abc-1');
  assert.ok(next);
  assert.equal(next.id, env.id);
});

test('CAS: re-recording replaces in place with version+1 — one durable owner', () => {
  const a = recordContinuation({
    workflowId: 'w1',
    operation: 'op',
    command: 'cmd-one',
    root: process.cwd(),
  });
  const b = recordContinuation({
    workflowId: 'w1',
    operation: 'op',
    command: 'cmd-two',
    root: process.cwd(),
  });
  assert.equal(b.version, a.version + 1, 'replacement must bump, not fork');
  const stored = getContinuation({ workflowId: 'w1', operation: 'op' });
  assert.ok(stored);
  assert.equal(stored.command, 'cmd-two');
  assert.equal(stored.version, 2);
});

test('a new operation for the same workflow SUPERSEDES the previous active one', () => {
  recordContinuation({ workflowId: 'w3', operation: 'rdd.classify', command: 'cmd-classify', root: process.cwd() });
  recordContinuation({ workflowId: 'w3', operation: 'rdd.review', command: 'cmd-review', root: process.cwd() });

  // one durable owner: nextTransition must return the LATEST, never the stale one
  const next = nextTransition('w3');
  assert.ok(next);
  assert.equal(next.operation, 'rdd.review');
  assert.equal(next.command, 'cmd-review');

  // the superseded sibling is closed, not left active
  const stale = getContinuation({ workflowId: 'w3', operation: 'rdd.classify' });
  assert.ok(stale);
  assert.equal(stale.status, 'resolved');
});

test('resolveContinuation enforces the byte-identical selector echo', () => {
  const env = recordContinuation({
    workflowId: 'w2',
    operation: 'op',
    command: 'cmd',
    selectorArguments: '--base-ref=main --committed-only',
    requireEcho: true,
    root: process.cwd(),
  });
  const bad = resolveContinuation(env.id, { selectorEcho: '--base-ref=main' });
  assert.ok(!('command' in bad) || bad.status === 'active', 'mismatch must refuse');
  assert.ok(isTypedRefusal(bad), 'mismatch is a typed refusal');
  const r = bad as { kind: string; code: string; remediation?: { command: string } };
  assert.equal(r.kind, 'selector');
  assert.equal(r.code, 'continuation.echo-mismatch');
  // remediation names the verbatim command — a retry that CAN succeed
  assert.equal(r.remediation?.command, 'cmd');

  const ok = resolveContinuation(env.id, { selectorEcho: '--base-ref=main --committed-only' });
  assert.ok('command' in ok && ok.status === 'resolved');

  // replay after resolution → typed refusal, nothing started
  const replay = resolveContinuation(env.id, { selectorEcho: '--base-ref=main --committed-only' });
  assert.ok(isTypedRefusal(replay));
  assert.equal((replay as { code: string }).code, 'continuation.already-resolved');
});

test('ack-before-burn: only the exact token burns the authority', () => {
  const pending = stageAck('rdd.w1', 'rev-42');
  assert.ok(pending.token.startsWith('ack-'));

  // pending replays identically (a restarted STATUS returns the same token)
  assert.deepEqual(getPendingAck('rdd.w1'), pending);

  // wrong token → typed refusal, pending record still there
  const wrong = acknowledge('rdd.w1', 'ack-deadbeef');
  assert.equal(wrong.ok, false);
  if (!wrong.ok) {
    assert.equal(wrong.refusal.code, 'ack.wrong-token');
    assert.ok(wrong.refusal.remediation, 'names its way forward');
  }
  assert.ok(getPendingAck('rdd.w1'), 'wrong ack created nothing, burned nothing');

  // stale revision → typed refusal
  const stale = acknowledge('rdd.w1', pending.token, 'rev-old');
  assert.equal(stale.ok, false);
  if (!stale.ok) assert.equal(stale.refusal.code, 'ack.stale-revision');

  // exact token + current revision → burns
  const ok = acknowledge('rdd.w1', pending.token, 'rev-42');
  assert.deepEqual(ok, { ok: true, burned: true, resource: 'rdd.w1' });
  assert.equal(getPendingAck('rdd.w1'), null, 'authority burned');

  // replay of the burned ack → refuses, creates nothing
  const replay = acknowledge('rdd.w1', pending.token);
  assert.equal(replay.ok, false);
  if (!replay.ok) assert.equal(replay.refusal.code, 'ack.nothing-pending');
});

test('unknown continuation id → typed refusal, not a raw error', () => {
  const r = resolveContinuation('cont-does-not-exist');
  assert.ok(isTypedRefusal(r));
  assert.equal((r as { code: string }).code, 'continuation.unknown');
});

test('refusal evidence: only filed when something started', () => {
  const nothing = refusal('budget', 'rdd.forecast-over', 'forecast exceeded', {
    nothingStarted: true,
  });
  assert.equal(writeEvidence(nothing, dir), null, 'caller input must not file evidence');

  const terminal = refusal('authority', 'rdd.escalation', 'validator rejected the correction');
  const evidence = writeEvidence(terminal, dir);
  assert.ok(evidence, 'terminal escalation leaves inspectable evidence');
  const line = readFileSync(evidence!, 'utf-8').trim().split('\n').pop();
  const entry = JSON.parse(line!);
  assert.equal(entry.kind, 'authority');
  assert.equal(entry.code, 'rdd.escalation');
});

test('describe renders the refusal block without paths', () => {
  const text = describeRefusal(
    refusal('replay', 'ack.replayed', 'acknowledgement already consumed', {
      remediation: { command: 'npx tsx src/core/continuation.ts ack-status --resource rdd.w1', description: 'inspect pending' },
    }),
  );
  assert.match(text, /REFUSED \[replay\] ack\.replayed/);
  assert.match(text, /run: npx tsx/);
  assert.ok(!text.match(/[A-Z]:\\\\/), 'no absolute paths in refusal text');
});
