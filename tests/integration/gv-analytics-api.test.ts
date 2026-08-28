/**
 * gv-analytics API integration tests.
 *
 * Probes the live API server (default 127.0.0.1:4754). Skips gracefully if
 * the server is not running. Covers the public endpoints exercised by the
 * UI and the launcher's smoke check.
 */

import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';

const PORT = process.env.GV_ANALYTICS_PORT || '4754';
const BASE_URL = process.env.GV_ANALYTICS_BASE_URL || `http://127.0.0.1:${PORT}`;

const serverUp = await fetch(`${BASE_URL}/api/connection/status`, {
  signal: AbortSignal.timeout(2000),
})
  .then((r) => r.ok)
  .catch(() => false);
const skipReason = serverUp ? false : `gv-analytics API not reachable at ${BASE_URL}`;

interface ConnectionStatus {
  configured: boolean;
  jira: { ok: boolean; message: string };
  confluence: { ok: boolean; message: string };
  bitbucket: { ok: boolean; message: string };
}

interface ReportListItem {
  id: string;
  createdAt: string;
  mode: string;
  summary: string;
  input: string;
}

interface OAuthStatus {
  configured: boolean;
  redirectUri: string;
  scopes: string[];
  connected: boolean;
}

interface MetricsSummary {
  totals: {
    requests: number;
    analyzeRequests: number;
    errorCount: number;
    llmHits: number;
    cacheHits: number;
    fallbackHits: number;
    heuristicHits: number;
  };
  latencyMs: { p50: number; p95: number; mean: number };
  byEndpoint: Array<{ endpoint: string; count: number; errors: number; meanMs: number }>;
}

describe('gv-analytics API', { skip: skipReason }, () => {
  before(() => {
    // The launcher already wrote pidfiles; nothing to start here.
  });

  after(() => {
    // Same.
  });

  it('GET /api/connection/status returns the connection shape', async () => {
    const res = await fetch(`${BASE_URL}/api/connection/status`);
    assert.equal(res.status, 200);
    const body = (await res.json()) as ConnectionStatus;
    assert.equal(typeof body.configured, 'boolean');
    assert.ok(body.jira);
    assert.ok(body.confluence);
    assert.ok(body.bitbucket);
    for (const svc of [body.jira, body.confluence, body.bitbucket]) {
      assert.equal(typeof svc.ok, 'boolean');
      assert.equal(typeof svc.message, 'string');
    }
  });

  it('GET /api/oauth/status returns redirect + scopes', async () => {
    const res = await fetch(`${BASE_URL}/api/oauth/status`);
    assert.equal(res.status, 200);
    const body = (await res.json()) as OAuthStatus;
    assert.equal(typeof body.configured, 'boolean');
    assert.match(body.redirectUri, /^http:\/\/127\.0\.0\.1:\d+\/oauth\/callback$/);
    assert.ok(Array.isArray(body.scopes));
    assert.ok(body.scopes.length >= 4);
    assert.equal(typeof body.connected, 'boolean');
  });

  it('GET /api/reports?limit=5 caps the list at the limit', async () => {
    const res = await fetch(`${BASE_URL}/api/reports?limit=5`);
    assert.equal(res.status, 200);
    const body = (await res.json()) as { reports: ReportListItem[] };
    assert.ok(Array.isArray(body.reports));
    assert.ok(body.reports.length <= 5, `expected <=5, got ${body.reports.length}`);
  });

  it('GET /api/metrics?hours=1 returns summary structure', async () => {
    const res = await fetch(`${BASE_URL}/api/metrics?hours=1`);
    assert.equal(res.status, 200);
    const body = (await res.json()) as MetricsSummary;
    assert.ok(body.totals);
    assert.equal(typeof body.totals.requests, 'number');
    assert.equal(typeof body.totals.errorRate, 'number');
    assert.ok(body.latencyMs);
    assert.equal(typeof body.latencyMs.p50, 'number');
    assert.equal(typeof body.latencyMs.p95, 'number');
    assert.ok(Array.isArray(body.byEndpoint));
  });

  it('GET /api/reports?limit=999 caps at 25 (server-side clamp)', async () => {
    const res = await fetch(`${BASE_URL}/api/reports?limit=999`);
    assert.equal(res.status, 200);
    const body = (await res.json()) as { reports: ReportListItem[] };
    assert.ok(body.reports.length <= 25, `expected <=25, got ${body.reports.length}`);
  });

  it('GET /api/connection without POST returns 404', async () => {
    const res = await fetch(`${BASE_URL}/api/connection`);
    assert.equal(res.status, 404);
  });

  it('GET /api/analyze without POST returns 404', async () => {
    const res = await fetch(`${BASE_URL}/api/analyze`);
    assert.equal(res.status, 404);
  });

  it('GET /api/unknown returns 404 with error payload', async () => {
    const res = await fetch(`${BASE_URL}/api/unknown-route`);
    assert.equal(res.status, 404);
    const body = (await res.json()) as { error: string };
    assert.equal(typeof body.error, 'string');
  });

  it('GET / returns the static index.html (build artifact)', async () => {
    const res = await fetch(`${BASE_URL}/`);
    assert.equal(res.status, 200);
    const text = await res.text();
    assert.ok(text.length > 0, 'index.html should be non-empty');
    assert.match(text, /<div id="root">/);
  });

  it('GET /oauth/callback without code returns 400 (no error HTML)', async () => {
    const res = await fetch(`${BASE_URL}/oauth/callback`);
    assert.equal(res.status, 400);
    const text = await res.text();
    assert.match(text, /<h1>Callback incompleto<\/h1>/);
  });

  it('GET /oauth/callback with error param returns 400 (auth error HTML)', async () => {
    const res = await fetch(`${BASE_URL}/oauth/callback?error=access_denied`);
    assert.equal(res.status, 400);
    const text = await res.text();
    assert.match(text, /OAuth cancelado/);
    assert.match(text, /access_denied/);
  });
});
