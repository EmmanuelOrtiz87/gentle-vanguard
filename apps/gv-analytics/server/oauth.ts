/**
 * Gentle-Vanguard Analytics — Atlassian OAuth 2.0 (3LO) client.
 *
 * Implements the Authorization Code flow against Atlassian's unified auth
 * (https://auth.atlassian.com). Designed to coexist with the API-token path:
 * if OAuth is configured, the Atlassian client uses the bearer token instead
 * of Basic auth. Both credentials live in the same AES-GCM vault.
 *
 * Required registration (out of band, in Atlassian Developer Console):
 *   - App type: OAuth 2.0 (3LO)
 *   - Callback URL: http://127.0.0.1:4755/oauth/callback
 *   - Scopes: read:jira-work read:jira-user read:confluence-content.summary
 *             read:confluence-content.detail read:bitbucket repositories
 *
 * Environment:
 *   GVA_OAUTH_CLIENT_ID, GVA_OAUTH_CLIENT_SECRET
 *   (or stored in vault under "oauth" namespace).
 */

import { createHash, randomBytes } from 'crypto';
import { loadConnection, saveConnection, type StoredConnection } from './vault';

const AUTH_BASE = 'https://auth.atlassian.com';
const TOKEN_URL = `${AUTH_BASE}/oauth/token`;
const ACCESSIBLE_RESOURCES_URL = 'https://api.atlassian.com/oauth/token/accessible-resources';
const CALLBACK_PORT = Number(
  process.env.GV_OAUTH_CALLBACK_PORT || process.env.GV_ANALYTICS_PORT || 4754,
);
const CALLBACK_PATH = '/oauth/callback';
const REDIRECT_URI = `http://127.0.0.1:${CALLBACK_PORT}${CALLBACK_PATH}`;
const SCOPES = [
  'read:jira-work',
  'read:jira-user',
  'read:confluence-content.summary',
  'read:confluence-content.detail',
  'read:bitbucket',
].join(' ');

export interface OAuthConfig {
  clientId: string;
  clientSecret: string;
}

export interface OAuthTokens {
  accessToken: string;
  refreshToken?: string;
  expiresAt: number;
  scope: string;
  cloudId?: string;
}

export interface PendingFlow {
  state: string;
  codeVerifier: string;
  createdAt: number;
  clientId: string;
}

let pendingFlow: PendingFlow | null = null;
let inMemoryTokens: OAuthTokens | null = null;

function base64Url(buf: Buffer): string {
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function codeChallengeFromVerifier(verifier: string): string {
  return base64Url(createHash('sha256').update(verifier).digest());
}

function generatePkcePair(): { verifier: string; challenge: string } {
  const verifier = base64Url(randomBytes(48));
  return { verifier, challenge: codeChallengeFromVerifier(verifier) };
}

export function getCallbackInfo(): { port: number; path: string; redirectUri: string } {
  return { port: CALLBACK_PORT, path: CALLBACK_PATH, redirectUri: REDIRECT_URI };
}

export function getOAuthConfig(): OAuthConfig | null {
  const envId = process.env.GVA_OAUTH_CLIENT_ID;
  const envSecret = process.env.GVA_OAUTH_CLIENT_SECRET;
  if (envId && envSecret) return { clientId: envId, clientSecret: envSecret };
  return null;
}

export function buildAuthorizationUrl(clientId: string): {
  url: string;
  state: string;
  verifier: string;
} {
  const { verifier, challenge } = generatePkcePair();
  const state = base64Url(randomBytes(24));
  pendingFlow = { state, codeVerifier: verifier, createdAt: Date.now(), clientId };
  const url = new URL(`${AUTH_BASE}/authorize`);
  url.searchParams.set('audience', 'api.atlassian.com');
  url.searchParams.set('client_id', clientId);
  url.searchParams.set('scope', SCOPES);
  url.searchParams.set('redirect_uri', REDIRECT_URI);
  url.searchParams.set('state', state);
  url.searchParams.set('response_type', 'code');
  url.searchParams.set('prompt', 'consent');
  url.searchParams.set('code_challenge', challenge);
  url.searchParams.set('code_challenge_method', 'S256');
  return { url: url.toString(), state, verifier };
}

export function consumePendingFlow(state: string): PendingFlow | null {
  if (!pendingFlow) return null;
  if (pendingFlow.state !== state) return null;
  if (Date.now() - pendingFlow.createdAt > 10 * 60_000) {
    pendingFlow = null;
    return null;
  }
  const flow = pendingFlow;
  pendingFlow = null;
  return flow;
}

export function cancelPendingFlow(): void {
  pendingFlow = null;
}

export async function exchangeCodeForTokens(args: {
  clientId: string;
  clientSecret: string;
  code: string;
  codeVerifier: string;
}): Promise<OAuthTokens> {
  const body = new URLSearchParams({
    grant_type: 'authorization_code',
    client_id: args.clientId,
    client_secret: args.clientSecret,
    code: args.code,
    redirect_uri: REDIRECT_URI,
    code_verifier: args.codeVerifier,
  });
  const response = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`OAuth token exchange HTTP ${response.status}: ${text.slice(0, 200)}`);
  }
  const data = (await response.json()) as {
    access_token: string;
    refresh_token?: string;
    expires_in: number;
    scope: string;
  };
  const tokens: OAuthTokens = {
    accessToken: data.access_token,
    refreshToken: data.refresh_token,
    expiresAt: Date.now() + data.expires_in * 1000,
    scope: data.scope,
  };
  // Fetch accessible-resources to pick the right cloudId.
  try {
    const resResponse = await fetch(ACCESSIBLE_RESOURCES_URL, {
      headers: { Authorization: `Bearer ${tokens.accessToken}`, Accept: 'application/json' },
    });
    if (resResponse.ok) {
      const resources = (await resResponse.json()) as Array<{
        id: string;
        url: string;
        name: string;
      }>;
      if (resources.length > 0) {
        tokens.cloudId = resources[0].id;
      }
    }
  } catch {
    /* non-fatal: cloudId can be set later by the user */
  }
  inMemoryTokens = tokens;
  return tokens;
}

export async function refreshTokens(args: {
  clientId: string;
  clientSecret: string;
  refreshToken: string;
}): Promise<OAuthTokens> {
  const body = new URLSearchParams({
    grant_type: 'refresh_token',
    client_id: args.clientId,
    client_secret: args.clientSecret,
    refresh_token: args.refreshToken,
  });
  const response = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`OAuth refresh HTTP ${response.status}: ${text.slice(0, 200)}`);
  }
  const data = (await response.json()) as {
    access_token: string;
    refresh_token?: string;
    expires_in: number;
    scope: string;
  };
  const tokens: OAuthTokens = {
    accessToken: data.access_token,
    refreshToken: data.refresh_token ?? args.refreshToken,
    expiresAt: Date.now() + data.expires_in * 1000,
    scope: data.scope,
    cloudId: inMemoryTokens?.cloudId,
  };
  inMemoryTokens = tokens;
  return tokens;
}

export function getActiveTokens(): OAuthTokens | null {
  return inMemoryTokens;
}

export function setActiveTokens(tokens: OAuthTokens | null): void {
  inMemoryTokens = tokens;
}

export function isTokenValid(tokens: OAuthTokens | null): tokens is OAuthTokens {
  return Boolean(tokens && tokens.accessToken && tokens.expiresAt > Date.now() + 30_000);
}

export function tokensFromConnection(conn: StoredConnection): OAuthTokens | null {
  if (!conn.oauth) return null;
  return {
    accessToken: conn.oauth.accessToken,
    refreshToken: conn.oauth.refreshToken,
    expiresAt: conn.oauth.expiresAt,
    scope: conn.oauth.scope,
    cloudId: conn.oauth.cloudId,
  };
}

export function persistTokensToVault(tokens: OAuthTokens): void {
  const conn = loadConnection();
  if (!conn) {
    setActiveTokens(tokens);
    return;
  }
  saveConnection({
    ...conn,
    oauth: {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresAt: tokens.expiresAt,
      scope: tokens.scope,
      cloudId: tokens.cloudId,
    },
  });
  setActiveTokens(tokens);
}

export function clearOAuth(): void {
  const conn = loadConnection();
  if (conn?.oauth) {
    saveConnection({ ...conn, oauth: undefined });
  }
  setActiveTokens(null);
  cancelPendingFlow();
}

export { REDIRECT_URI, SCOPES };
