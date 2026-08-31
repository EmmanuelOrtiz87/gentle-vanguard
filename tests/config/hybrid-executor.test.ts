import { describe, it } from 'node:test';
import { strict as assert } from 'node:assert';
import {
  getProviderCatalog,
  getProviderOrder,
  selectProvider,
} from '../../src/orchestration/hybrid-executor.ts';

describe('hybrid-executor.ts', () => {
  it('prefers the lowest-cost provider by default', () => {
    const providers = getProviderCatalog({
      AWS_ESTIMATED_COST: '0.0000167',
      AZURE_ESTIMATED_COST: '0.00002',
    });

    const selected = selectProvider(providers, 'auto', 'cost');
    assert.equal(selected.provider, 'AWS');
  });

  it('switches to latency-based selection when requested', () => {
    const providers = getProviderCatalog({
      AWS_ESTIMATED_LATENCY_MS: '20',
      AZURE_ESTIMATED_LATENCY_MS: '60',
    });

    const selected = selectProvider(providers, 'auto', 'latency');
    assert.equal(selected.provider, 'AWS');
  });

  it('returns a fallback order anchored on the preferred provider', () => {
    const selected = {
      provider: 'Azure',
      cost: 0.00002,
      latency: 60,
      load: 0.5,
      capacity: 500,
      reliability: 0.985,
    };

    const order = getProviderOrder(selected);
    assert.deepEqual(order, ['Azure', 'AWS']);
  });
});
