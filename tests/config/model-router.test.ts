import { describe, it } from 'node:test';
import { strict as assert } from 'node:assert';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = process.cwd();
const config = JSON.parse(readFileSync(join(ROOT, 'config', 'model-router.json'), 'utf-8'));

describe('model-router.json', () => {
  it('has required top-level fields', () => {
    assert.ok(config.version);
    assert.ok(config.defaults);
    assert.ok(config.agentBindings);
    assert.ok(config.failover);
    assert.ok(config.audit);
  });

  it('has required default model settings', () => {
    assert.ok(config.defaults.model);
    assert.ok(config.defaults.provider);
    assert.equal(typeof config.defaults.temperature, 'number');
  });

  it('has agent bindings with required fields', () => {
    const agents = Object.values(config.agentBindings);
    assert.ok(agents.length > 0);
    for (const agent of agents) {
      assert.ok(agent.model, `Agent missing model: ${JSON.stringify(agent)}`);
      assert.ok(agent.provider, `Agent missing provider`);
      assert.equal(typeof agent.temperature, 'number');
    }
  });

  it('has routingPolicy from consolidation', () => {
    assert.ok(config.routingPolicy);
    assert.ok(config.routingPolicy.fastCheapToStrongReasoning);
    assert.ok(config.routingPolicy.retryStrategy);
  });

  it('has costTracking', () => {
    assert.ok(config.costTracking);
    assert.ok(config.costTracking.budgetLimits);
    assert.equal(typeof config.costTracking.budgetLimits.dailyTokens, 'number');
  });

  it('has modelLevels', () => {
    assert.ok(config.modelLevels);
    assert.ok(config.modelLevels.fastCheap);
    assert.ok(config.modelLevels.strongCoding);
    assert.ok(config.modelLevels.strongReasoning);
    assert.ok(config.modelLevels.strongReview);
  });
});
