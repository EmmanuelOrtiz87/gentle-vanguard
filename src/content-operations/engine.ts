#!/usr/bin/env node
/**
 * Content Operations Engine — offline-first domain service.
 *
 * This intentionally does not call remote APIs. It validates and packages
 * content jobs so the same artifacts can be consumed by the CMS, CLI or
 * future official platform adapters.
 */
import { readFileSync, writeFileSync, mkdirSync, existsSync, copyFileSync } from 'node:fs';
import { resolve, dirname, basename } from 'node:path';

type Status = 'DRAFT'|'VALIDATED'|'PACKAGED'|'REVIEW'|'APPROVED'|'PUBLISHED'|'MEASURED'|'FAILED';

type Job = {
  id: string; date: string; timezone?: string; platform: string;
  campaign: string; theme: string; contentType: string; copy: string;
  cta?: string; asset?: string; status: Status; approvalRequired: boolean;
  variants?: string[]; output?: string;
};

export function validate(job: Job): string[] {
  const errors: string[] = [];
  if (!job.id) errors.push('missing id');
  if (!job.date) errors.push('missing date');
  if (!job.platform) errors.push('missing platform');
  if (!job.copy?.trim()) errors.push('missing copy');
  if (!job.campaign) errors.push('missing campaign');
  if (!job.approvalRequired) errors.push('approvalRequired must be true for remote publication');
  return errors;
}

export function packageJob(root: string, job: Job): string {
  const out = resolve(root, '.runtime/content-operations', job.date, job.platform, job.id);
  mkdirSync(out, { recursive: true });
  writeFileSync(resolve(out, 'caption.txt'), `${job.copy}${job.cta ? `\n\n${job.cta}` : ''}\n`, 'utf8');
  writeFileSync(resolve(out, 'publication.json'), JSON.stringify({ ...job, generatedAt: new Date().toISOString(), status: 'REVIEW' }, null, 2), 'utf8');
  writeFileSync(resolve(out, 'STATUS.txt'), 'REVIEW\n', 'utf8');
  if (job.asset) {
    const source = resolve(root, job.asset);
    if (existsSync(source)) copyFileSync(source, resolve(out, basename(source)));
  }
  return out;
}

export function loadManifest(root: string): Job[] {
  const path = resolve(root, 'content/operations/master-manifest.json');
  return JSON.parse(readFileSync(path, 'utf8')) as Job[];
}

if (process.argv[1] && resolve(process.argv[1]) === resolve(process.argv[1])) {
  const root = process.cwd();
  const manifest = loadManifest(root);
  const date = process.argv.find((a) => a.startsWith('--date='))?.split('=')[1];
  const platform = process.argv.find((a) => a.startsWith('--platform='))?.split('=')[1];
  const jobs = manifest.filter((j) => (!date || j.date === date) && (!platform || j.platform === platform));
  for (const job of jobs) {
    const errors = validate(job);
    if (errors.length) console.error(`${job.id}: INVALID`, errors);
    else console.log(`${job.id}: ${packageJob(root, job)}`);
  }
}
