import { spawn, ChildProcess } from 'child_process';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { EventEmitter } from 'events';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = resolve(__dirname, '../../..');
const SERVER_SCRIPT = resolve(ROOT, 'scripts/mcp/skill-server.ts');
const PACKAGE_ROOT = resolve(__dirname, '..');

interface MCPRequest {
  jsonrpc: '2.0';
  id: number;
  method: string;
  params?: Record<string, unknown>;
}

interface MCPResponse {
  jsonrpc: '2.0';
  id: number;
  result?: unknown;
  error?: { code: number; message: string; data?: unknown };
}

interface ToolDefinition {
  name: string;
  description: string;
  inputSchema: Record<string, unknown>;
}

export class MCPBridge extends EventEmitter {
  private proc: ChildProcess | null = null;
  private reqId = 0;
  private pending = new Map<
    number,
    { resolve: (v: unknown) => void; reject: (e: Error) => void }
  >();
  private buffer = '';
  private _connected = false;
  private _tools: ToolDefinition[] = [];

  get connected(): boolean {
    return this._connected;
  }

  get tools(): ToolDefinition[] {
    return this._tools;
  }

  async start(): Promise<void> {
    const candidates = [
      resolve(PACKAGE_ROOT, 'node_modules/.bin/tsx'),
      resolve(ROOT, 'node_modules/.bin/tsx'),
      resolve(ROOT, 'node_modules/.bin/tsx.cmd'),
      'npx',
    ];
    const tsnode =
      candidates.find((p) => p === 'npx' || (existsSync(p) && statSync(p).isFile())) || 'npx';
    const args = tsnode === 'npx' ? ['tsx', SERVER_SCRIPT] : [tsnode, SERVER_SCRIPT];
    const cwd = existsSync(SERVER_SCRIPT) ? ROOT : undefined;
    if (!cwd) {
      this._tools = [];
      this._connected = false;
      return;
    }

    return new Promise((resolve, reject) => {
      this.proc = spawn(process.execPath, args, {
        stdio: ['pipe', 'pipe', 'pipe'],
        cwd,
      });

      let started = false;
      const timeout = setTimeout(() => {
        if (!started) reject(new Error('MCP bridge start timeout'));
      }, 15000);

      this.proc.stdout?.on('data', (data: Buffer) => {
        this.buffer += data.toString();
        this.processBuffer();
        if (!started) {
          started = true;
          clearTimeout(timeout);
          this._connected = true;
          this.emit('connected');
          this.discoverTools();
          resolve();
        }
      });

      this.proc.stderr?.on('data', (data: Buffer) => {
        this.emit('stderr', data.toString());
      });

      this.proc.on('exit', (code) => {
        this._connected = false;
        this.emit('disconnected', code);
        this.rejectAll(new Error(`MCP process exited with code ${code}`));
      });

      this.proc.on('error', (err) => {
        this._connected = false;
        if (!started) {
          clearTimeout(timeout);
          reject(err);
        }
        this.emit('error', err);
      });
    });
  }

  private processBuffer(): void {
    const lines = this.buffer.split('\n');
    this.buffer = lines.pop() || '';
    for (const line of lines) {
      if (!line.trim()) continue;
      try {
        const msg: MCPResponse = JSON.parse(line);
        this.handleResponse(msg);
      } catch {
        this.emit('stderr', line);
      }
    }
  }

  private handleResponse(msg: MCPResponse): void {
    const pending = this.pending.get(msg.id);
    if (pending) {
      this.pending.delete(msg.id);
      if (msg.error) {
        pending.reject(new Error(msg.error.message));
      } else {
        pending.resolve(msg.result);
      }
    }
  }

  private rejectAll(err: Error): void {
    for (const [, pending] of this.pending) {
      pending.reject(err);
    }
    this.pending.clear();
  }

  private async discoverTools(): Promise<void> {
    try {
      const result = (await this.request('tools/list')) as { tools: ToolDefinition[] };
      this._tools = result.tools || [];
      this.emit('tools_discovered', this._tools);
    } catch {
      this._tools = [];
    }
  }

  async request(method: string, params?: Record<string, unknown>): Promise<unknown> {
    const id = ++this.reqId;
    const req: MCPRequest = { jsonrpc: '2.0', id, method, params };

    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.proc?.stdin?.write(JSON.stringify(req) + '\n');
    });
  }

  async callTool(name: string, args?: Record<string, unknown>): Promise<unknown> {
    return this.request('tools/call', { name, arguments: args });
  }

  async stop(): Promise<void> {
    if (this.proc) {
      this.proc.kill();
      this.proc = null;
      this._connected = false;
    }
  }
}

let instance: MCPBridge | null = null;

export function getBridge(): MCPBridge {
  if (!instance) {
    instance = new MCPBridge();
  }
  return instance;
}
