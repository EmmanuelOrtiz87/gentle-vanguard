import { describe, it } from 'node:test';
import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const config = JSON.parse(
  readFileSync(join(process.cwd(), 'config', 'ps1-ts-migration.json'), 'utf-8'),
);

describe('ps1-ts-migration.json', () => {
  it('prioritizes security and cloud migration candidates', () => {
    assert.ok(
      config.priorities.some((item: { id: string }) => item.id === 'security-orchestrator'),
    );
    assert.ok(config.priorities.some((item: { id: string }) => item.id === 'hybrid-executor'));
  });

  it('keeps the first migration wave focused on high-impact scripts', () => {
    assert.ok(Array.isArray(config.firstWave));
    assert.ok(config.firstWave.length >= 3);
    assert.equal(config.firstWave[0], 'security-orchestrator');
    assert.equal(config.firstWave[1], 'hybrid-executor');
  });
});
