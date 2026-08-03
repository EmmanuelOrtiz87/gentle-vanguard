import { execSync } from 'child_process';
import { existsSync, mkdirSync, readdirSync, rmSync, writeFileSync, cpSync } from 'fs';
import { join, resolve } from 'path';

const ROOT = resolve(process.cwd());
const TS = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);

function findDBs(dir: string): string[] {
  if (!existsSync(dir)) return [];
  return readdirSync(dir, { withFileTypes: true }).flatMap((e) =>
    e.isDirectory()
      ? findDBs(join(dir, e.name))
      : e.name.endsWith('.db') || e.name.endsWith('.sqlite')
        ? [join(dir, e.name)]
        : [],
  );
}

const checks = [
  { name: '.codegraph', critical: true },
  { name: '.engram-data', critical: false },
];
let critical = false;
console.log('=== RESCUE DATABASE ===');

for (const c of checks) {
  const p = join(ROOT, c.name);
  if (!existsSync(p)) {
    console.log('  ' + c.name + ': no existe');
    continue;
  }
  const dbs = findDBs(p);
  if (!dbs.length) {
    console.log('  ' + c.name + ': sin .db');
    continue;
  }
  try {
    const r = execSync('sqlite3 "' + dbs[0] + '" "SELECT COUNT(*) FROM nodes"', {
      encoding: 'utf8',
      timeout: 5000,
    }).trim();
    console.log('  ' + c.name + ': OK (' + r + ' nodos)');
  } catch {
    console.log('  ' + c.name + ': CORRUPT');
    if (c.critical) critical = true;
    const bk = join(ROOT, '.recovery', 'backup-' + TS, c.name);
    mkdirSync(bk, { recursive: true });
    cpSync(p, bk, { recursive: true, force: true });
    rmSync(p, { recursive: true, force: true });
    console.log('    -> Backup + eliminada');
  }
}

mkdirSync(join(ROOT, '.session', 'restore-points'), { recursive: true });
writeFileSync(
  join(ROOT, '.session', 'restore-points', TS + '.json'),
  JSON.stringify(
    {
      id: 'restore-' + TS,
      timestamp: TS,
      type: 'post-recovery-baseline',
      status: critical ? 'repaired' : 'healthy',
    },
    null,
    2,
  ),
);

mkdirSync(join(ROOT, '.recovery'), { recursive: true });
writeFileSync(
  join(ROOT, '.recovery', 'recovery-log.json'),
  JSON.stringify(
    {
      timestamp: TS,
      action: 'rescue',
      repaired: critical,
      status: critical ? 'restart-needed' : 'healthy',
    },
    null,
    2,
  ),
);

console.log('\n=== ' + (critical ? 'REPARADO -- reinicia opencode' : 'TODO OK') + ' ===');
process.exit(critical ? 1 : 0);
