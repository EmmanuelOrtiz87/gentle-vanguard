#!/usr/bin/env node
export const tools = {
  async sendNotification(platform, recipient, message) {
    return { platform, recipient, message, sent: true };
  },

  async broadcastMessage(platforms, message) {
    const results = [];
    for (const platform of platforms) {
      results.push({ platform, sent: true });
    }
    return results;
  }
};
