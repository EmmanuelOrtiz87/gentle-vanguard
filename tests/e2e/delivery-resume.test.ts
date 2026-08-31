import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { rmSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { DeliveryStateMachine, loadCheckpoint } from '../../src/delivery/state-machine.ts';
import type { DeliveryIntent } from '../../src/delivery/types.ts';

const ROOT = resolve(import.meta.dirname, '..', '..');
const DELIVERY_CLI = join(ROOT, 'src', 'delivery', 'cli.ts');

function gitHead(): string {
  const result = spawnSync('git', ['rev-parse', 'HEAD'], {
    cwd: ROOT,
    encoding: 'utf8',
    windowsHide: true,
  });
  assert.equal(result.status, 0, result.stderr);
  return result.stdout.trim();
}

function runResume(runId: string) {
  return spawnSync(process.execPath, ['--import', 'tsx', DELIVERY_CLI, 'resume', runId], {
    cwd: ROOT,
    encoding: 'utf8',
    windowsHide: true,
  });
}

test('delivery resume accepts the current source HEAD and blocks a changed HEAD', () => {
  const runId = `delivery-e2e-resume-${randomUUID()}`;
  const intent: DeliveryIntent = {
    runId,
    summary: 'delivery resume source HEAD regression',
    target: 'develop',
    changePaths: ['tests/e2e/delivery-resume.test.ts'],
    commitGroups: [
      {
        scope: 'test',
        paths: ['tests/e2e/delivery-resume.test.ts'],
        message: 'test delivery resume source HEAD',
      },
    ],
    requestedBy: 'e2e-test',
    promotion: 'none',
  };

  try {
    const stateMachine = new DeliveryStateMachine(intent, gitHead());
    const sourceSha = gitHead();
    stateMachine.update({ sourceSha });

    const resumed = runResume(runId);
    assert.equal(resumed.status, 0, resumed.stderr);
    assert.match(resumed.stdout, new RegExp(`Resumed at state ${stateMachine.state}`));

    const checkpoint = loadCheckpoint(runId);
    assert.ok(checkpoint);
    checkpoint.sourceSha = `${sourceSha.slice(0, -1)}${sourceSha.endsWith('0') ? '1' : '0'}`;
    stateMachine.update({ sourceSha: checkpoint.sourceSha });

    const blocked = runResume(runId);
    assert.equal(blocked.status, 6, blocked.stderr);
    assert.match(blocked.stdout, /Source HEAD changed since checkpoint/);
  } finally {
    rmSync(join(ROOT, '.session', 'delivery', runId), {
      recursive: true,
      force: true,
      maxRetries: 5,
      retryDelay: 100,
    });
  }
});
