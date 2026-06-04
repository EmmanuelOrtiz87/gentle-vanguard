import { readFileSync, writeFileSync, existsSync, mkdirSync, watch } from 'fs';
import { join, resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { EventEmitter } from 'events';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = resolve(__dirname, '../../..');
const EVENT_BUS_DIR = join(ROOT, '.event-bus');
const HISTORY_PATH = join(EVENT_BUS_DIR, 'history.json');
const SUBSCRIPTIONS_PATH = join(EVENT_BUS_DIR, 'subscriptions.json');

interface BusEvent {
  timestamp: string;
  event: string;
  execution_id?: string;
  payload?: string;
  status: string;
  handlers_triggered?: number;
}

interface BusHistory {
  version: string;
  events: BusEvent[];
  max_history: number;
}

interface AgentTask {
  id: string;
  agent: string;
  task: string;
  status: 'pending' | 'running' | 'completed' | 'error' | 'cancelled';
  startedAt: string;
  completedAt?: string;
  execution_id?: string;
}

const STANDARD_EVENTS = [
  'dispatch.started',
  'dispatch.completed',
  'agent.dispatched',
  'agent.completed',
  'session.started',
  'session.ended',
  'workflow.checkpoint',
  'workflow.publish',
  'validation.started',
  'validation.completed',
];

export class SharedStateBridge extends EventEmitter {
  private pollTimer: NodeJS.Timeout | null = null;
  private lastEventCount = 0;
  private _tasks: AgentTask[] = [];

  get tasks(): AgentTask[] {
    return this._tasks;
  }

  start(intervalMs = 3000): void {
    this.readHistory();
    this.pollTimer = setInterval(() => this.readHistory(), intervalMs);
  }

  stop(): void {
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
  }

  private readHistory(): void {
    try {
      if (!existsSync(HISTORY_PATH)) return;
      const raw = readFileSync(HISTORY_PATH, 'utf-8');
      const history: BusHistory = JSON.parse(raw);

      if (history.events.length > this.lastEventCount) {
        const newEvents = history.events.slice(0, history.events.length - this.lastEventCount);
        this.lastEventCount = history.events.length;

        for (const evt of newEvents.reverse()) {
          this.processEvent(evt);
          this.emit('event', evt);
        }
        this.emit('history_update', history.events.slice(0, 20));
      }
    } catch {
      // File might be temporarily locked
    }
  }

  private processEvent(evt: BusEvent): void {
    if (evt.event === 'agent.dispatched' && evt.payload) {
      try {
        const p = JSON.parse(evt.payload);
        this._tasks.unshift({
          id: `task-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
          agent: p.agent || 'unknown',
          task: p.task || 'unknown',
          status: 'running',
          startedAt: evt.timestamp,
          execution_id: evt.execution_id,
        });
        this.emit('task_update', this._tasks);
      } catch {
        /* ignore */
      }
    }

    if (evt.event === 'agent.completed' && evt.execution_id) {
      const task = this._tasks.find(
        (t) => t.execution_id === evt.execution_id && t.status === 'running',
      );
      if (task) {
        task.status = 'completed';
        task.completedAt = evt.timestamp;
        this.emit('task_update', this._tasks);
      }
    }
  }

  emitEvent(eventName: string, payload: Record<string, unknown>): void {
    const entry: BusEvent = {
      timestamp: new Date().toISOString(),
      event: eventName.toLowerCase(),
      payload: JSON.stringify(payload),
      status: 'emitted',
      execution_id: (payload.execution_id as string) || undefined,
      handlers_triggered: 0,
    };

    try {
      if (!existsSync(EVENT_BUS_DIR)) {
        mkdirSync(EVENT_BUS_DIR, { recursive: true });
      }

      let history: BusHistory;
      if (existsSync(HISTORY_PATH)) {
        history = JSON.parse(readFileSync(HISTORY_PATH, 'utf-8'));
      } else {
        history = { version: '1.0', events: [], max_history: 100 };
      }

      history.events.unshift(entry);
      if (history.events.length > history.max_history) {
        history.events = history.events.slice(0, history.max_history);
      }

      writeFileSync(HISTORY_PATH, JSON.stringify(history, null, 2));
      this.lastEventCount = history.events.length;
      this.processEvent(entry);
      this.emit('event', entry);
      this.emit('history_update', history.events.slice(0, 20));
    } catch {
      // File might be locked
    }
  }
}

let instance: SharedStateBridge | null = null;

export function getStateBridge(): SharedStateBridge {
  if (!instance) {
    instance = new SharedStateBridge();
  }
  return instance;
}
