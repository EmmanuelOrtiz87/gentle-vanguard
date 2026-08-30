import { describe, it, beforeEach, afterEach } from 'node:test';
import { strict as assert } from 'node:assert';
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  createCheckpoint,
  listCheckpoints,
  verifyCheckpoint,
} from '../../src/ops/checkpoint-manager.ts';

describe('checkpoint-manager.ts', () => {
  let tempRoot = '';

  beforeEach(() => {
    tempRoot = mkdtempSync(join(tmpdir(), 'gv-ckpt-'));
    mkdirSync(join(tempRoot, '.session'), { recursive: true });
    writeFileSync(join(tempRoot, '.session', 'state.json'), '{"step":1}', 'utf8');
  });

  afterEach(() => {
    rmSync(tempRoot, { recursive: true, force: true });
  });

  it('creates and verifies a checkpoint manifest from session state', () => {
    const created = createCheckpoint(tempRoot, { label: 'unit-test' });

    assert.ok(created.checkpointId.startsWith('ckpt-'));
    assert.equal(created.count, 1);
    assert.equal(created.label, 'unit-test');

    const checkpoints = listCheckpoints(tempRoot);
    assert.equal(checkpoints.length, 1);
    assert.equal(checkpoints[0].label, 'unit-test');

    const verification = verifyCheckpoint(tempRoot, created.checkpointId);
    assert.equal(verification.status, 'INTACT');
    assert.equal(verification.valid, 1);
  });
});
