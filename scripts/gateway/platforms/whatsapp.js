#!/usr/bin/env node
export class WhatsAppAdapter {
  constructor(sessionPath) {
    this.sessionPath = sessionPath;
    this.name = 'whatsapp';
  }

  async start() {
    console.log('WhatsApp adapter started');
  }

  async stop() {
    console.log('WhatsApp adapter stopped');
  }

  async sendMessage(phone, text) {
    return { phone, text, platform: 'whatsapp' };
  }
}
