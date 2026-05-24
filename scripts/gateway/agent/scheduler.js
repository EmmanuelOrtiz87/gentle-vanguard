#!/usr/bin/env node
export class GatewayScheduler {
  constructor() {
    this.tasks = new Map();
    this.intervals = new Map();
  }

  addTask(name, handler, intervalMs) {
    this.tasks.set(name, { handler, intervalMs });
    const id = setInterval(handler, intervalMs);
    this.intervals.set(name, id);
  }

  removeTask(name) {
    if (this.intervals.has(name)) {
      clearInterval(this.intervals.get(name));
      this.intervals.delete(name);
      this.tasks.delete(name);
    }
  }

  stopAll() {
    for (const [name, id] of this.intervals) {
      clearInterval(id);
    }
    this.intervals.clear();
    this.tasks.clear();
  }
}
