#!/usr/bin/env node
export class DiscordAdapter {
  constructor(token) {
    this.token = token;
    this.name = 'discord';
  }

  async start() {
    console.log('Discord adapter started');
  }

  async stop() {
    console.log('Discord adapter stopped');
  }

  async sendMessage(channelId, text) {
    return { channelId, text, platform: 'discord' };
  }
}
