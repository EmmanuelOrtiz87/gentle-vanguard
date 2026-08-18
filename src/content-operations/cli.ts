#!/usr/bin/env node
import { loadManifest, validate, packageJob } from './engine.js';

const root = process.cwd();
const args = process.argv.slice(2);
const command = args[0] ?? 'help';
const get = (name: string) => args.find((a) => a.startsWith(`--${name}=`))?.split('=')[1];

const jobs = loadManifest(root);
const selected = jobs.filter((j) => (!get('date') || j.date === get('date')) && (!get('platform') || j.platform === get('platform')) && (!get('id') || j.id === get('id')));

switch (command) {
  case 'list':
    console.table(selected.map(({ id, date, platform, status, campaign }) => ({ id, date, platform, status, campaign })));
    break;
  case 'validate':
    for (const job of selected) console.log(job.id, validate(job));
    break;
  case 'prepare':
    for (const job of selected) {
      const errors = validate(job);
      if (errors.length) { console.error(job.id, errors); continue; }
      console.log(`${job.id}: ${packageJob(root, job)}`);
    }
    break;
  default:
    console.log(`Gentle-Vanguard Content Operations\n\n  pnpm exec tsx src/content-operations/cli.ts list --date=YYYY-MM-DD\n  pnpm exec tsx src/content-operations/cli.ts validate --id=JOB-ID\n  pnpm exec tsx src/content-operations/cli.ts prepare --date=YYYY-MM-DD --platform=linkedin\n`);
}
