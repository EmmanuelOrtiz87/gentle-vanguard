import { describe, it } from 'node:test';
import assert from 'node:assert';
import { createContainer, createAppContainer } from '../../src/core/container.js';
import { resetConfigService, getConfigService } from '../../src/config/config-service.js';

describe('createContainer', () => {
  it('resolves registered factories and memoizes instances', () => {
    const c = createContainer();
    let calls = 0;
    c.register('svc', () => {
      calls += 1;
      return { id: 'x' };
    });
    const a = c.resolve('svc');
    const b = c.resolve('svc');
    assert.equal(a, b);
    assert.equal(calls, 1);
  });

  it('factories receive the container (dependency resolution)', () => {
    const c = createContainer();
    c.register('config', () => ({ token: 'cfg-1' }));
    c.register('consumer', (cc) => ({ config: cc.resolve('config') }));
    const consumer = c.resolve<{ config: { token: string } }>('consumer');
    assert.equal(consumer.config.token, 'cfg-1');
  });

  it('registerValue resolves as-is', () => {
    const c = createContainer();
    const obj = { fixed: true };
    c.registerValue('static', obj);
    assert.equal(c.resolve('static'), obj);
  });

  it('throws on unknown key', () => {
    const c = createContainer();
    assert.throws(() => c.resolve('nope'), /nothing registered/);
  });

  it('throws on duplicate registration', () => {
    const c = createContainer();
    c.register('a', () => 1);
    assert.throws(() => c.register('a', () => 2), /already registered/);
  });

  it('throws on circular dependencies', () => {
    const c = createContainer();
    c.register('a', (cc) => cc.resolve('b'));
    c.register('b', (cc) => cc.resolve('a'));
    assert.throws(() => c.resolve('a'), /circular dependency/);
  });

  it('has() and keys() reflect registrations', () => {
    const c = createContainer();
    c.register('x', () => 1);
    c.registerValue('y', 2);
    assert.equal(c.has('x'), true);
    assert.equal(c.has('z'), false);
    assert.deepEqual(c.keys().sort(), ['x', 'y']);
  });

  it('containers are isolated (test isolation)', () => {
    const c1 = createContainer();
    const c2 = createContainer();
    c1.register('svc', () => ({ scope: 'one' }));
    c2.register('svc', () => ({ scope: 'two' }));
    assert.equal(c1.resolve<{ scope: string }>('svc').scope, 'one');
    assert.equal(c2.resolve<{ scope: string }>('svc').scope, 'two');
  });
});

describe('createAppContainer (pilot wiring)', () => {
  it('registers the pilot keys', () => {
    const c = createAppContainer();
    assert.equal(c.has('config'), true);
    assert.equal(c.has('db'), true);
    assert.equal(c.has('tokenBudgetGuard'), true);
  });

  it('config resolves to the ConfigService singleton', () => {
    try {
      const c = createAppContainer();
      const cfg = c.resolve<ReturnType<typeof getConfigService>>('config');
      assert.equal(cfg, getConfigService());
      assert.equal(cfg.validate().ok, true);
    } finally {
      resetConfigService();
    }
  });
});
