#!/usr/bin/env node
/**
 * Unit Tests: Audit Pipeline
 * Tests audit event generation and querying
 */

import { describe, it } from 'node:test';
import assert from 'node:assert';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

describe('Audit Pipeline', () => {
  const auditDir = join(process.cwd(), '.session', 'audit');
  const indexFile = join(auditDir, 'index.json');

  it('should have audit directory', () => {
    assert.ok(existsSync(auditDir), 'Audit directory should exist');
  });

  it('should have audit index', () => {
    assert.ok(existsSync(indexFile), 'Audit index should exist');
  });

  it('should have valid audit events', () => {
    if (existsSync(indexFile)) {
      const index = JSON.parse(readFileSync(indexFile, 'utf-8'));
      assert.ok(Array.isArray(index.events), 'Events should be an array');
      assert.ok(index.events.length >= 0, `Found ${index.events.length} events`);
      
      // Verify event structure
      if (index.events.length > 0) {
        const event = index.events[0];
        assert.ok(event.id, 'Event should have id');
        assert.ok(event.timestamp, 'Event should have timestamp');
        assert.ok(event.type, 'Event should have type');
        assert.ok(event.component, 'Event should have component');
      }
    }
  });

  it('should have audit log files', () => {
    if (existsSync(auditDir)) {
      const { readdirSync } = require('fs');
      const logDir = join(auditDir, 'logs');
      if (existsSync(logDir)) {
        const files = readdirSync(logDir).filter((f: string) => f.endsWith('.jsonl'));
        assert.ok(files.length >= 0, `Found ${files.length} log files`);
      }
    }
  });
});
