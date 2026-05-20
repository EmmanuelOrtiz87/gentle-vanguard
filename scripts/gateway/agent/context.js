import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';

const ROOT = path.resolve(import.meta.dirname, '..', '..', '..');

export function getProjectContext() {
  const ctx = {
    rootDir: ROOT,
    projectName: 'gentle-vanguard',
    skillsCount: 0,
    engramAvailable: false,
    currentBranch: 'unknown',
    lastCommit: 'unknown',
  };

  try {
    ctx.currentBranch = execSync('git branch --show-current', { cwd: ROOT, encoding: 'utf-8', timeout: 5000 }).trim();
  } catch { }

  try {
    ctx.lastCommit = execSync('git log -1 --format="%h %s"', { cwd: ROOT, encoding: 'utf-8', timeout: 5000 }).trim();
  } catch { }

  try {
    ctx.engramAvailable = !!execSync('pwsh -NoProfile -Command "Get-Command engram -ErrorAction SilentlyContinue"', { cwd: ROOT, encoding: 'utf-8', timeout: 5000 }).trim();
  } catch { ctx.engramAvailable = false; }

  try {
    const skillsDir = path.join(ROOT, 'skills');
    if (fs.existsSync(skillsDir)) {
      ctx.skillsCount = fs.readdirSync(skillsDir).filter(f => {
        try { return fs.statSync(path.join(skillsDir, f)).isDirectory(); } catch { return false; }
      }).length;
    }
  } catch { }

  return ctx;
}

export class ConversationHistory {
  constructor(maxMessages = 50) {
    this.maxMessages = maxMessages;
    this.messages = [];
  }

  add(role, content) {
    this.messages.push({ role, content });
    if (this.messages.length > this.maxMessages) {
      this.messages = this.messages.slice(-this.maxMessages);
    }
  }

  get() {
    return this.messages;
  }

  clear() {
    this.messages = [];
  }

  save(filePath) {
    try {
      fs.mkdirSync(path.dirname(filePath), { recursive: true });
      fs.writeFileSync(filePath, JSON.stringify(this.messages.slice(-20), null, 2));
    } catch { }
  }

  load(filePath) {
    try {
      if (fs.existsSync(filePath)) {
        this.messages = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
      }
    } catch { }
  }
}
