#!/usr/bin/env node
export class GatewayAgent {
  constructor(config) {
    this.config = config;
    this.status = 'idle';
  }

  async processMessage(message) {
    return { processed: true, message };
  }

  async getStatus() {
    return { status: this.status, config: this.config };
  }
}
