#!/usr/bin/env node
// Minimal CDP test
const http = require('http');
const WebSocket = require('ws');

// Get browser WS URL
http.get('http://127.0.0.1:9222/json/version', (res) => {
  let data = '';
  res.on('data', c => data += c);
  res.on('end', () => {
    const browserUrl = JSON.parse(data).webSocketDebuggerUrl;
    console.log('Browser WS:', browserUrl);
    const ws = new WebSocket(browserUrl);

    let msgId = 1;
    ws.on('open', () => {
      console.log('Connected to browser target');
      // List targets
      ws.send(JSON.stringify({ id: msgId++, method: 'Target.getTargets' }));
    });

    ws.on('message', (raw) => {
      const msg = JSON.parse(raw.toString());
      console.log('MSG:', JSON.stringify(msg).slice(0, 200));

      if (msg.id === 1 && msg.result?.targetInfos) {
        const dashboard = msg.result.targetInfos.find(t => t.url.includes('5173'));
        if (dashboard) {
          console.log('Found dashboard tab:', dashboard.targetId);
          ws.send(JSON.stringify({ id: msgId++, method: 'Target.attachToTarget', params: { targetId: dashboard.targetId, flatten: true } }));
        }
      }

      if (msg.method === 'Target.attachedToTarget') {
        const sid = msg.params.sessionId;
        console.log('Attached! Session:', sid);
        // In flatten mode, send sessionId at TOP level of message (not in params)
        setTimeout(() => {
          ws.send(JSON.stringify({ id: msgId++, sessionId: sid, method: 'Page.navigate', params: { url: 'http://localhost:5173' } }));
        }, 500);
        setTimeout(() => {
          ws.send(JSON.stringify({ id: msgId++, sessionId: sid, method: 'Runtime.evaluate', params: { expression: `JSON.stringify({title:document.title,cards:document.querySelectorAll('.card').length,sections:[...document.querySelectorAll('h2,h3')].map(h=>h.textContent.trim()).filter(Boolean)})` } }));
        }, 2000);
        setTimeout(() => {
          ws.send(JSON.stringify({ id: msgId++, sessionId: sid, method: 'Page.captureScreenshot', params: { format: 'png', fromSurface: true } }));
        }, 3500);
      }

      if (msg.result) {
        if (msg.result.result?.value) {
          console.log('EVAL:', msg.result.result.value);
        }
        if (msg.result.data) {
          const buf = Buffer.from(msg.result.data, 'base64');
          require('fs').writeFileSync('dashboard.png', buf);
          console.log('Screenshot:', buf.length, 'bytes');
          ws.close();
        }
      }
    });

    ws.on('error', console.error);
    ws.on('close', () => process.exit(0));
    setTimeout(() => process.exit(0), 10000);
  });
}).on('error', console.error);
