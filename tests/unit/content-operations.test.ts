import assert from 'node:assert/strict';
import { mkdtempSync, existsSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import {
  loadManifest,
  packageJob,
  validate,
  type Job,
} from '../../src/content-operations/engine.js';

test('content operations validates a complete job', () => {
  const job: Job = {
    id: 'TEST-001',
    date: '2026-08-18',
    timezone: 'America/Argentina/San_Juan',
    platform: 'linkedin',
    campaign: 'TEST',
    theme: 'Test',
    contentType: 'test',
    copy: 'Contenido de prueba',
    status: 'DRAFT',
    approvalRequired: true,
  };

  assert.deepEqual(validate(job), []);
});

test('content operations rejects remote jobs without approval', () => {
  const job = {
    id: 'TEST-002',
    date: '2026-08-18',
    platform: 'x',
    campaign: 'TEST',
    theme: 'Test',
    contentType: 'test',
    copy: 'Contenido',
    status: 'DRAFT',
    approvalRequired: false,
  } as Job;

  assert.ok(validate(job).includes('approvalRequired must be true for remote publication'));
});

test('content operations packages a job without network access', () => {
  const root = mkdtempSync(join(tmpdir(), 'gv-content-operations-'));
  const job: Job = {
    id: 'TEST-003',
    date: '2026-08-18',
    platform: 'whatsapp_channel',
    campaign: 'TEST',
    theme: 'Test',
    contentType: 'test',
    copy: 'Contenido offline',
    cta: 'Feedback',
    status: 'DRAFT',
    approvalRequired: true,
  };

  const output = packageJob(root, job);

  assert.equal(existsSync(join(output, 'caption.txt')), true);
  assert.equal(existsSync(join(output, 'publication.json')), true);
  assert.equal(readFileSync(join(output, 'STATUS.txt'), 'utf8'), 'REVIEW\n');
});

test('content operations manifest is readable', () => {
  const root = process.cwd();
  const jobs = loadManifest(root);
  assert.ok(jobs.length >= 3);
  assert.ok(jobs.every((job) => job.approvalRequired));
});
