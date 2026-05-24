#!/usr/bin/env node
import { createServer } from 'node:http';

const PORT = process.env.GATEWAY_PORT || 3000;

const server = createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ status: 'ok', service: 'gateway', version: '1.0.0' }));
});

server.listen(PORT, () => {
  console.log(`Gateway running on port ${PORT}`);
});
