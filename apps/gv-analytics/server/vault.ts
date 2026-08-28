import { createCipheriv, createDecipheriv, randomBytes, scryptSync } from 'crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { dirname, join, resolve } from 'path';

export interface StoredOAuthTokens {
  accessToken: string;
  refreshToken?: string;
  expiresAt: number;
  scope: string;
  cloudId?: string;
}

export interface StoredConnection {
  siteUrl: string;
  email: string;
  /** API token for Jira + Confluence (shared Atlassian token). */
  apiToken: string;
  /** Separate API token for Bitbucket. Optional for backward-compat with old vaults. */
  bitbucketApiToken?: string;
  bitbucketWorkspace: string;
  updatedAt: string;
  oauth?: StoredOAuthTokens;
}

const ROOT = resolve(process.cwd(), '../..');
const RUNTIME_DIR = join(ROOT, '.runtime', 'gv-analytics');
const VAULT_FILE = join(RUNTIME_DIR, 'atlassian-connection.vault');
const KEY_FILE = join(RUNTIME_DIR, 'vault.key');

function ensureRuntime() {
  mkdirSync(RUNTIME_DIR, { recursive: true });
}

function getKey(): Buffer {
  ensureRuntime();
  if (!existsSync(KEY_FILE)) {
    writeFileSync(KEY_FILE, randomBytes(32).toString('hex'), { encoding: 'utf-8', mode: 0o600 });
  }
  const secret = readFileSync(KEY_FILE, 'utf-8').trim();
  return scryptSync(secret, 'gentle-vanguard-analytics', 32);
}

export function saveConnection(connection: StoredConnection): void {
  ensureRuntime();
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', getKey(), iv);
  const encrypted = Buffer.concat([
    cipher.update(JSON.stringify(connection), 'utf-8'),
    cipher.final(),
  ]);
  const payload = {
    version: 1,
    iv: iv.toString('base64'),
    tag: cipher.getAuthTag().toString('base64'),
    data: encrypted.toString('base64'),
  };
  mkdirSync(dirname(VAULT_FILE), { recursive: true });
  writeFileSync(VAULT_FILE, JSON.stringify(payload, null, 2), 'utf-8');
}

export function loadConnection(): StoredConnection | null {
  if (!existsSync(VAULT_FILE)) return null;
  const payload = JSON.parse(readFileSync(VAULT_FILE, 'utf-8')) as {
    iv: string;
    tag: string;
    data: string;
  };
  const decipher = createDecipheriv('aes-256-gcm', getKey(), Buffer.from(payload.iv, 'base64'));
  decipher.setAuthTag(Buffer.from(payload.tag, 'base64'));
  const plain = Buffer.concat([
    decipher.update(Buffer.from(payload.data, 'base64')),
    decipher.final(),
  ]);
  return JSON.parse(plain.toString('utf-8')) as StoredConnection;
}
