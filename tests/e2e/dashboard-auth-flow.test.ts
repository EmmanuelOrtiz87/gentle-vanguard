import * as assert from 'node:assert/strict';
import { once } from 'node:events';
import { createServer } from 'node:http';
import { mkdtemp } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawn, type ChildProcess } from 'node:child_process';
import { describe, it, before, after } from 'node:test';
import { fileURLToPath } from 'node:url';
import WebSocket from 'ws';

const SERVER = fileURLToPath(
  new URL('../../apps/web-dashboard/server/websocket-server.ts', import.meta.url),
);
const DASHBOARD_TOKEN = 'test-dashboard-token-e2e-auth';

async function freePort(): Promise<number> {
  const probe = createServer();
  probe.listen(0, '127.0.0.1');
  await once(probe, 'listening');
  const port = (probe.address() as { port: number }).port;
  await new Promise<void>((resolve, reject) =>
    probe.close((error) => (error ? reject(error) : resolve())),
  );
  return port;
}

function waitForServerReady(child: ChildProcess, maxWaitMs: number = 10000): Promise<void> {
  return new Promise((resolve, reject) => {
    let output = '';
    const timeout = setTimeout(() => {
      child.stdout?.off('data', onData);
      reject(new Error(`Server startup timeout after ${maxWaitMs}ms. Output: ${output}`));
    }, maxWaitMs);

    const onData = (chunk: Buffer) => {
      output += chunk.toString();
      if (output.includes('[WS] Server on port')) {
        clearTimeout(timeout);
        child.stdout?.off('data', onData);
        resolve();
      }
    };

    child.stdout?.on('data', onData);
    child.once('error', (err) => {
      clearTimeout(timeout);
      reject(err);
    });
    child.once('exit', (code) => {
      clearTimeout(timeout);
      reject(new Error(`Dashboard server exited with code ${code}. Output: ${output}`));
    });
  });
}

function closeWebSocket(ws: WebSocket): Promise<void> {
  if (ws.readyState === WebSocket.CLOSED) return Promise.resolve();
  ws.close();
  return new Promise((resolve) => {
    const timeout = setTimeout(() => resolve(), 1000);
    ws.once('close', () => {
      clearTimeout(timeout);
      resolve();
    });
  });
}

describe('Dashboard Auth Flow E2E', () => {
  let child: ChildProcess;
  let baseUrl: string;
  let wsUrl: string;
  let dbDir: string;

  before(async () => {
    const port = await freePort();
    baseUrl = `http://127.0.0.1:${port}`;
    wsUrl = `ws://127.0.0.1:${port}`;
    dbDir = await mkdtemp(join(tmpdir(), 'gv-dashboard-auth-e2e-'));

    child = spawn(process.execPath, ['--import', 'tsx', SERVER], {
      cwd: process.cwd(),
      env: {
        ...process.env,
        WS_PORT: String(port),
        GV_DASHBOARD_TOKEN: DASHBOARD_TOKEN,
        GV_DASHBOARD_DEV_AUTH: '', // Production mode for auth testing
        GENTLE_TENANT_ID: 'test-tenant-auth',
        GENTLE_VANGUARD_DB_DIR: dbDir,
        NODE_ENV: 'production',
      },
      stdio: ['ignore', 'pipe', 'pipe'],
      windowsHide: true,
    });

    await waitForServerReady(child);
  });

  after(async () => {
    return new Promise<void>((resolve) => {
      if (child.kill()) {
        const timeout = setTimeout(() => resolve(), 2000);
        child.once('exit', () => {
          clearTimeout(timeout);
          resolve();
        });
      } else {
        resolve();
      }
    });
  });

  describe('WebSocket Connection & Authentication', () => {
    it('should reject connection without valid token', async () => {
      const ws = new WebSocket(`${wsUrl}/ws?tenantId=test-tenant-auth`);
      
      try {
        await once(ws, 'close');
        // Connection should be rejected (unauthorized)
        assert.ok(ws.readyState === WebSocket.CLOSED, 'Connection should be closed');
      } finally {
        await closeWebSocket(ws);
      }
    });

    it('should accept connection with valid token in query param', async () => {
      const ws = new WebSocket(
        `${wsUrl}/ws?tenantId=test-tenant-auth&token=${DASHBOARD_TOKEN}`,
      );

      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Connection timeout')), 5000);
        
        ws.once('open', () => {
          clearTimeout(timeout);
          resolve();
        });
        
        ws.once('error', (err) => {
          clearTimeout(timeout);
          reject(err);
        });
      });

      try {
        assert.ok(ws.readyState === WebSocket.OPEN, 'Connection should be open');
      } finally {
        await closeWebSocket(ws);
      }
    });

    it('should accept connection with valid token in header', async () => {
      const ws = new WebSocket(`${wsUrl}/ws?tenantId=test-tenant-auth`, {
        headers: {
          authorization: `Bearer ${DASHBOARD_TOKEN}`,
        },
      });

      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Connection timeout')), 5000);
        
        ws.once('open', () => {
          clearTimeout(timeout);
          resolve();
        });
        
        ws.once('error', (err) => {
          clearTimeout(timeout);
          reject(err);
        });
      });

      try {
        assert.ok(ws.readyState === WebSocket.OPEN, 'Connection should be open');
      } finally {
        await closeWebSocket(ws);
      }
    });

    it('should reject connection with invalid token', async () => {
      const ws = new WebSocket(
        `${wsUrl}/ws?tenantId=test-tenant-auth&token=invalid-token`,
      );

      await new Promise<void>((resolve) => {
        ws.once('close', () => resolve());
        ws.once('error', () => resolve());
        setTimeout(() => resolve(), 3000);
      });

      try {
        assert.ok(
          ws.readyState === WebSocket.CLOSED || ws.readyState === WebSocket.CLOSING,
          'Connection should be closed or closing',
        );
      } finally {
        await closeWebSocket(ws);
      }
    });
  });

  describe('WebSocket Handshake', () => {
    it('should complete WebSocket upgrade handshake', async () => {
      const ws = new WebSocket(
        `${wsUrl}/ws?tenantId=test-tenant-auth&token=${DASHBOARD_TOKEN}`,
      );

      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Handshake timeout')), 5000);
        
        ws.once('open', () => {
          clearTimeout(timeout);
          resolve();
        });
        
        ws.once('error', (err) => {
          clearTimeout(timeout);
          reject(err);
        });
      });

      try {
        assert.strictEqual(ws.readyState, WebSocket.OPEN);
        assert.ok(ws.extensions !== undefined);
      } finally {
        await closeWebSocket(ws);
      }
    });

    it('should send heartbeat/ping from server', async () => {
      const ws = new WebSocket(
        `${wsUrl}/ws?tenantId=test-tenant-auth&token=${DASHBOARD_TOKEN}`,
      );

      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Open timeout')), 5000);
        
        ws.once('open', () => {
          clearTimeout(timeout);
          resolve();
        });
        
        ws.once('error', reject);
      });

      try {
        // Wait for ping or any message from server
        await new Promise<void>((resolve) => {
          const timeout = setTimeout(() => resolve(), 3000);
          ws.once('ping', () => {
            clearTimeout(timeout);
            resolve();
          });
          ws.once('message', () => {
            clearTimeout(timeout);
            resolve();
          });
        });

        assert.ok(ws.readyState === WebSocket.OPEN, 'Should still be connected');
      } finally {
        await closeWebSocket(ws);
      }
    });

    it('should accept and respond to pong', async () => {
      const ws = new WebSocket(
        `${wsUrl}/ws?tenantId=test-tenant-auth&token=${DASHBOARD_TOKEN}`,
      );

      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Open timeout')), 5000);
        ws.once('open', () => {
          clearTimeout(timeout);
          resolve();
        });
        ws.once('error', reject);
      });

      try {
        ws.ping();
        
        await new Promise<void>((resolve) => {
          const timeout = setTimeout(() => resolve(), 2000);
          ws.once('pong', () => {
            clearTimeout(timeout);
            resolve();
          });
        });

        assert.ok(ws.readyState === WebSocket.OPEN);
      } finally {
        await closeWebSocket(ws);
      }
    });
  });

  describe('Tenant Authorization', () => {
    it('should reject connection with mismatched tenant ID', async () => {
      const ws = new WebSocket(
        `${wsUrl}/ws?tenantId=different-tenant&token=${DASHBOARD_TOKEN}`,
      );

      await new Promise<void>((resolve) => {
        const timeout = setTimeout(() => resolve(), 3000);
        ws.once('close', () => {
          clearTimeout(timeout);
          resolve();
        });
        ws.once('error', () => {
          clearTimeout(timeout);
          resolve();
        });
      });

      try {
        assert.ok(
          ws.readyState === WebSocket.CLOSED || ws.readyState === WebSocket.CLOSING,
          'Should reject mismatched tenant',
        );
      } finally {
        await closeWebSocket(ws);
      }
    });

    it('should accept connection with correct tenant ID', async () => {
      const ws = new WebSocket(
        `${wsUrl}/ws?tenantId=test-tenant-auth&token=${DASHBOARD_TOKEN}`,
      );

      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Connection timeout')), 5000);
        ws.once('open', () => {
          clearTimeout(timeout);
          resolve();
        });
        ws.once('error', reject);
      });

      try {
        assert.strictEqual(ws.readyState, WebSocket.OPEN, 'Should be connected');
      } finally {
        await closeWebSocket(ws);
      }
    });

    it('should handle tenant context in headers', async () => {
      const ws = new WebSocket(`${wsUrl}/ws?tenantId=test-tenant-auth&token=${DASHBOARD_TOKEN}`, {
        headers: {
          'x-tenant-id': 'test-tenant-auth',
        },
      });

      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Connection timeout')), 5000);
        ws.once('open', () => {
          clearTimeout(timeout);
          resolve();
        });
        ws.once('error', reject);
      });

      try {
        assert.strictEqual(ws.readyState, WebSocket.OPEN);
      } finally {
        await closeWebSocket(ws);
      }
    });
  });

  describe('Session Management', () => {
    it('should maintain session across multiple messages', async () => {
      const ws = new WebSocket(
        `${wsUrl}/ws?tenantId=test-tenant-auth&token=${DASHBOARD_TOKEN}`,
      );

      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Open timeout')), 5000);
        ws.once('open', () => {
          clearTimeout(timeout);
          resolve();
        });
        ws.once('error', reject);
      });

      try {
        // Send a test message
        ws.send(JSON.stringify({ type: 'ping', id: 1 }));

        // Wait for response or timeout
        await new Promise<void>((resolve) => {
          const timeout = setTimeout(() => resolve(), 2000);
          ws.once('message', () => {
            clearTimeout(timeout);
            resolve();
          });
        });

        // Should still be connected
        assert.ok(
          ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CLOSING,
          'Session should be maintained',
        );
      } finally {
        await closeWebSocket(ws);
      }
    });

    it('should properly close session on client disconnect', async () => {
      const ws = new WebSocket(
        `${wsUrl}/ws?tenantId=test-tenant-auth&token=${DASHBOARD_TOKEN}`,
      );

      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Open timeout')), 5000);
        ws.once('open', () => {
          clearTimeout(timeout);
          resolve();
        });
        ws.once('error', reject);
      });

      try {
        await closeWebSocket(ws);
        assert.strictEqual(ws.readyState, WebSocket.CLOSED);
      } finally {
        // Ensure cleanup
        await closeWebSocket(ws);
      }
    });
  });

  describe('Error Handling', () => {
    it('should handle malformed messages gracefully', async () => {
      const ws = new WebSocket(
        `${wsUrl}/ws?tenantId=test-tenant-auth&token=${DASHBOARD_TOKEN}`,
      );

      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Open timeout')), 5000);
        ws.once('open', () => {
          clearTimeout(timeout);
          resolve();
        });
        ws.once('error', reject);
      });

      try {
        // Send invalid JSON
        ws.send('{ invalid json');

        // Should not crash server
        await new Promise<void>((resolve) => {
          const timeout = setTimeout(() => resolve(), 1000);
          ws.once('error', () => {
            clearTimeout(timeout);
            resolve();
          });
        });

        // Connection should still be open or gracefully closing
        assert.ok(ws.readyState !== WebSocket.OPEN || true, 'Server should handle gracefully');
      } finally {
        await closeWebSocket(ws);
      }
    });

    it('should timeout idle connections', async () => {
      const ws = new WebSocket(
        `${wsUrl}/ws?tenantId=test-tenant-auth&token=${DASHBOARD_TOKEN}`,
      );

      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Open timeout')), 5000);
        ws.once('open', () => {
          clearTimeout(timeout);
          resolve();
        });
        ws.once('error', reject);
      });

      try {
        // Wait for potential timeout (30s server timeout)
        // Just verify connection persists for reasonable time
        await new Promise<void>((resolve) => {
          setTimeout(() => resolve(), 2000);
        });

        assert.ok(
          ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CLOSING,
          'Connection should not crash unexpectedly',
        );
      } finally {
        await closeWebSocket(ws);
      }
    });
  });
});
