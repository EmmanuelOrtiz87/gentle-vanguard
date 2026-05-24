#!/usr/bin/env node
export class GatewayContext {
  constructor() {
    this.conversations = new Map();
  }

  getConversation(id) {
    return this.conversations.get(id) || [];
  }

  addMessage(conversationId, message) {
    if (!this.conversations.has(conversationId)) {
      this.conversations.set(conversationId, []);
    }
    this.conversations.get(conversationId).push(message);
  }

  clearConversation(id) {
    this.conversations.delete(id);
  }
}
