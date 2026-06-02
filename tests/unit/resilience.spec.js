import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

describe('ResilienceManager Source Interface', () => {
  it('should support TierConfig shape', () => {
    const config = {
      id: 'primary',
      name: 'Primary Tier',
      mode: 'active',
      healthCheckInterval: 30,
      failoverTimeout: 10,
      syncInterval: 60,
    };
    assert.equal(config.id, 'primary');
    assert.equal(config.mode, 'active');
    assert.equal(typeof config.healthCheckInterval, 'number');
  });

  it('should support HealthStatus shape', () => {
    const status = {
      tierId: 'primary',
      isHealthy: true,
      lastCheck: new Date(),
      responseTime: 150,
      errorRate: 0.01,
    };
    assert.equal(status.isHealthy, true);
    assert.ok(status.responseTime > 0);
    assert.ok(status.lastCheck instanceof Date);
  });

  it('should support ResilienceMetrics shape', () => {
    const metrics = {
      uptime: 99.9,
      failoverCount: 2,
      recoveryTime: 45,
      dataLossEvents: 0,
    };
    assert.equal(metrics.uptime, 99.9);
    assert.equal(metrics.failoverCount, 2);
    assert.equal(metrics.dataLossEvents, 0);
  });

  it('should validate secondary tier config', () => {
    const config = {
      id: 'secondary',
      name: 'Secondary Tier',
      mode: 'standby',
      healthCheckInterval: 60,
      failoverTimeout: 30,
      syncInterval: 120,
    };
    assert.equal(config.id, 'secondary');
    assert.equal(config.mode, 'standby');
    assert.equal(config.healthCheckInterval, 60);
    assert.equal(config.syncInterval, 120);
  });

  it('should handle error edge case: responseTime zero', () => {
    const status = {
      tierId: 'tertiary',
      isHealthy: false,
      lastCheck: new Date(),
      responseTime: 0,
      errorRate: 0.5,
    };
    assert.equal(status.isHealthy, false);
    assert.equal(status.responseTime, 0);
    assert.equal(status.errorRate, 0.5);
  });
});
