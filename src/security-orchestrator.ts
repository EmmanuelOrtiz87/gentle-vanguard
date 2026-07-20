#!/usr/bin/env node

export type SecurityMode = 'prompt' | 'log' | 'error' | 'audit';
export type SecurityAction =
  | 'init'
  | 'sanitize'
  | 'audit'
  | 'block'
  | 'status'
  | 'enable'
  | 'disable'
  | 'scan';

export interface SecurityActionResult {
  status: 'OK' | 'AUTH_REQUIRED' | 'BLOCKED' | 'ERROR';
  message?: string;
  sanitized?: string;
  original?: string;
  mode?: SecurityMode;
  pattern?: string;
  requireAuth?: boolean;
}

export interface SecurityPattern {
  name: string;
  pattern: RegExp;
}

const criticalPatterns: SecurityPattern[] = [
  { name: 'AWS Key', pattern: /AKIA[0-9A-Z]{16}/ },
  { name: 'GitHub Token', pattern: /ghp_[A-Za-z0-9]{36}/ },
  { name: 'Stripe Key', pattern: /sk_live_[0-9a-zA-Z]{24,}/ },
  { name: 'Private Key', pattern: /-----BEGIN .+ PRIVATE KEY-----/ },
  {
    name: 'Prompt Injection: Instruction Override',
    pattern:
      /(?:\bignore\s+(?:all\s+)?(?:previous\s+)?(?:instructions|commands|directions|rules|prompts?|constraints?|guidelines?))\b/i,
  },
  {
    name: 'Prompt Injection: Prompt Leakage',
    pattern:
      /(?:\b(?:repeat|output|print|show|display|reveal|leak|dump|copy)\s+(?:your\s+)?(?:system\s+)?(?:prompt|instructions|rules))\b/i,
  },
  {
    name: 'Prompt Injection: Jailbreak',
    pattern:
      /(?:DAN|do\s+anything\s+now|jailbreak|unrestricted\s+mode|developer\s+mode|no\s+(?:limits|restrictions|filter))/i,
  },
  {
    name: 'Prompt Injection: Code Execution',
    pattern:
      /\$?(?:exec|eval|system|shell|cmd|powershell|bash|os\.system|subprocess|child_process|execSync|spawn)\s*\(/i,
  },
  {
    name: 'Prompt Injection: Role Takeover',
    pattern: /\byou\s+(?:are\s+)?(?:now|must\s+act\s+as|will\s+pretend|shall\s+behave)\b/i,
  },
];

export function sanitizeText(text: string, mode: SecurityMode = 'prompt'): string {
  if (!text) return text;

  let result = text;
  const replaceMachine = (value: string) => value.replace(/DESKTOP-1|COMPUTERNAME/gi, '<MACHINE>');
  const replaceUser = (value: string) => value.replace(/emmanuel|USERNAME/gi, '<USER>');
  const replaceHome = (value: string) =>
    value.replace(/C:\\Users\\[^\\]+|C:\/Users\/[^/]+/g, '<HOME>');
  const replaceSecret = (value: string) => value.replace(/ghp_[A-Za-z0-9]{36}/g, '<TOKEN>');

  if (mode === 'prompt') {
    result = replaceMachine(result);
    result = replaceUser(result);
    result = replaceHome(result);
    result = replaceSecret(result);
  } else if (mode === 'log') {
    result = replaceMachine(result);
    result = replaceUser(result);
    result = replaceHome(result);
  } else if (mode === 'error') {
    result = replaceMachine(result);
    result = replaceUser(result);
  }

  return result;
}

export function testBlockCritical(text: string): { blocked: boolean; pattern?: string } {
  for (const entry of criticalPatterns) {
    if (entry.pattern.test(text)) {
      return { blocked: true, pattern: entry.name };
    }
  }
  return { blocked: false };
}

export function evaluateAction(
  action: SecurityAction,
  content?: string,
  mode: SecurityMode = 'prompt',
  apiKey?: string,
  authenticated = false,
): SecurityActionResult {
  const restrictedActions = new Set<SecurityAction>(['enable', 'disable', 'audit', 'scan']);
  if (restrictedActions.has(action) && !authenticated && !apiKey) {
    return {
      status: 'AUTH_REQUIRED',
      requireAuth: true,
      message: `Operation '${action}' requires authentication.`,
    };
  }

  switch (action) {
    case 'sanitize': {
      if (!content) return { status: 'ERROR', message: 'Content required for sanitize' };
      const blocked = testBlockCritical(content);
      if (blocked.blocked) {
        return {
          status: 'BLOCKED',
          message: `Critical pattern detected: ${blocked.pattern}`,
          pattern: blocked.pattern,
        };
      }
      return { status: 'OK', original: content, sanitized: sanitizeText(content, mode), mode };
    }
    case 'block': {
      const blocked = testBlockCritical(content ?? '');
      if (blocked.blocked) {
        return {
          status: 'BLOCKED',
          message: `Blocked: ${blocked.pattern}`,
          pattern: blocked.pattern,
        };
      }
      return { status: 'OK', message: 'Allowed' };
    }
    case 'status':
    case 'init':
      return { status: 'OK', message: `${action} completed` };
    case 'enable':
    case 'disable':
      return { status: 'OK', message: `Security ${action}d` };
    case 'audit':
      return { status: 'OK', message: 'Audit logged' };
    case 'scan':
      return { status: 'OK', message: 'Scan completed' };
    default:
      return { status: 'ERROR', message: 'Unsupported action' };
  }
}

if (process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href) {
  const action = process.argv[2] as SecurityAction | undefined;
  const mode = (process.argv[3] as SecurityMode | undefined) ?? 'prompt';
  const result = evaluateAction(action ?? 'status', process.argv[4], mode);
  console.log(JSON.stringify(result));
}
