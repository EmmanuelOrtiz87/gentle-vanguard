#!/usr/bin/env node
export class TelegramAdapter {
  constructor(token) {
    this.token = token;
    this.name = 'telegram';
  }

  async start() {
    console.log('Telegram adapter started');
  }

  async stop() {
    console.log('Telegram adapter stopped');
  }

  async sendMessage(chatId, text) {
    return { chatId, text, platform: 'telegram' };
  }
}
