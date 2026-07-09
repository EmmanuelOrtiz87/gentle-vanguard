import { describe, it } from 'node:test';
import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = process.cwd();
const config = JSON.parse(readFileSync(join(ROOT, 'config', 'stack-maturity.json'), 'utf-8'));

describe('stack-maturity.json', () => {
  it('defines a core tier with stable modules', () => {
    assert.ok(Array.isArray(config.core));
    assert.ok(config.core.length >= 2);
    assert.ok(config.core.some((item: { name: string }) => item.name === 'session-orchestration'));
  });

  it('defines experimental modules as opt-in', () => {
    assert.ok(Array.isArray(config.experimental));
    assert.ok(config.experimental.length >= 2);
    assert.ok(config.experimental.every((item: { tier: string }) => item.tier === 'experimental'));
  });

  it('uses an explicit opt-in policy for experimental modules', () => {
    assert.equal(config.policy?.experimentalModules, 'opt-in');
    assert.equal(config.policy?.requireApprovalForExperimental, true);
    assert.ok(
      config.experimental.every((item: { activation: string }) => item.activation === 'opt-in'),
    );
  });
});
