#!/usr/bin/env node
/**
 * Skills PS1 Cleaner
 * Actualiza las instrucciones de skills para usar TypeScript en lugar de PowerShell
 *
 * USO: npx tsx src/skills-ps1-cleaner.ts [--apply]
 */

import { readFileSync, writeFileSync, existsSync, readdirSync } from 'fs';
import { join, extname } from 'path';

const ROOT = process.cwd();
const SKILLS_DIR = join(ROOT, '.antigravity', 'skills');

// Reemplazos de comandos PowerShell → TypeScript
const REPLACEMENTS = [
  // Comandos de ejecución
  {
    pattern:
      /```powershell\s*\.\\scripts\\utilities\\invoke-cloud-agent\.ps1\s+-Provider\s+(\w+)\s+-Command\s+"([^"]+)"\s*```/g,
    replacement: '```bash\nnpx tsx src/invoke-cloud-agent.ts --provider $1 --command "$2"\n```',
  },
  {
    pattern:
      /```powershell\s*\.\\scripts\\utilities\\invoke-cloud-agent\.ps1\s+-Provider\s+(\w+)\s+-Script\s+"([^"]+)"\s*```/g,
    replacement: '```bash\nnpx tsx src/invoke-cloud-agent.ts --provider $1 --script "$2"\n```',
  },
  {
    pattern:
      /```powershell\s*\.\\scripts\\utilities\\invoke-cloud-agent\.ps1\s+-Interactive\s*```/g,
    replacement: '```bash\nnpx tsx src/invoke-cloud-agent.ts --interactive\n```',
  },
  {
    pattern:
      /```powershell\s*\.\\scripts\\utilities\\invoke-cloud-agent\.ps1\s+-Provider\s+(\w+)\s+-Agent\s+"([^"]+)"\s*```/g,
    replacement: '```bash\nnpx tsx src/invoke-cloud-agent.ts --provider $1 --agent "$2"\n```',
  },
  {
    pattern:
      /```powershell\s*\.\\scripts\\utilities\\invoke-cloud-agent\.ps1\s+-Provider\s+(\w+)\s+-StrictJson\s+-Command\s+"([^"]+)"\s*```/g,
    replacement:
      '```bash\nnpx tsx src/invoke-cloud-agent.ts --provider $1 --strict-json --command "$2"\n```',
  },

  // Comandos de sesión
  {
    pattern: /`\.\\scripts\\utilities\\compact-start\.ps1\s+-Objective\s+"([^"]+)"`/g,
    replacement: '`npx tsx src/context-pack.ts --objective "$1"`',
  },
  {
    pattern: /`.\\scripts\\utilities\\context-pack\.ps1`/g,
    replacement: '`npx tsx src/context-pack.ts`',
  },
  {
    pattern: /`.\\scripts\\utilities\\context-metrics-report\.ps1`/g,
    replacement: '`npx tsx src/context-metrics-report.ts`',
  },

  // Comandos de hooks
  {
    pattern: /```powershell\s*\.\\hooks\\pre-tool-format\.ps1\s+-FilePath\s+"([^"]+)"\s*```/g,
    replacement: '```bash\nnpx tsx src/hooks/pre-tool-format.ts --file-path "$1"\n```',
  },
  {
    pattern: /```powershell\s*Invoke-ScriptAnalyzer\s+-Path\s+\.\\scripts\\\s*```/g,
    replacement: '```bash\nnpm run lint\n```',
  },
  {
    pattern: /\.\\scripts\\utilities\\sync-agent-instructions\.ps1/g,
    replacement: 'npx tsx src/sync-agent-instructions.ts',
  },

  // Comandos generales
  {
    pattern: /\.\\scripts\\adaptive\\auto-backup-orchestrator\.ps1/g,
    replacement: 'npx tsx src/auto-backup-orchestrator.ts',
  },
  {
    pattern: /\.\\scripts\\adaptive\\auto-norm-enforcer\.ps1/g,
    replacement: 'npx tsx src/auto-norm-enforcer.ts',
  },
  {
    pattern: /\.\\scripts\\adaptive\\auto-norm-learner\.ps1/g,
    replacement: 'npx tsx src/auto-norm-learner.ts',
  },
  {
    pattern: /\.\\scripts\\adaptive\\auto-doc-drift-detector\.ps1/g,
    replacement: 'npx tsx src/auto-doc-drift-detector.ts',
  },
  {
    pattern: /\.\\scripts\\adaptive\\auto-testing-final\.ps1/g,
    replacement: 'npx tsx src/auto-testing-final.ts',
  },

  // Workflow orchestration
  {
    pattern: /\.\\scripts\\utilities\\WORKFLOW-ORCHESTRATION\\daily-check\.ps1/g,
    replacement: 'npx tsx src/daily-check.ts',
  },
  {
    pattern: /\.\\scripts\\utilities\\WORKFLOW-ORCHESTRATION\\compact-start\.ps1/g,
    replacement: 'npx tsx src/context-pack.ts',
  },
  {
    pattern: /\.\\scripts\\utilities\\gv\.ps1/g,
    replacement: 'npx tsx src/gv.ts',
  },

  // Git
  {
    pattern: /`.\\scripts\\utilities\\GIt-VERSION-CONTROL\\pre-commit-validation\.ps1`/g,
    replacement: '`npx tsx src/pre-commit-validation.ts`',
  },
  {
    pattern: /`.\\scripts\\utilities\\GIT-VERSION-CONTROL\\post-merge-sync\.ps1`/g,
    replacement: '`npx tsx src/post-merge-sync.ts`',
  },

  // Comandos de testing
  {
    pattern: /\.\\gv\.ps1\s+test/g,
    replacement: 'npm run test',
  },
  {
    pattern: /Invoke-Pester\s+-Path\s+\.\\tests\\/g,
    replacement: 'npm run test',
  },

  // Comandos generales de scripts
  {
    pattern: /pwsh\s+-NoProfile\s+-File\s+scripts\/utilities\/session-learning-capture\.ps1/g,
    replacement: 'npx tsx src/session-learning-capture.ts',
  },
  {
    pattern: /pwsh\s+-NoProfile\s+-File\s+scripts\/skills\/usage-tracker\.ps1/g,
    replacement: 'npx tsx src/skills/usage-tracker.ts',
  },
  {
    pattern: /pwsh\s+-NoProfile\s+-File\s+scripts\/skills\/skill-nudge\.ps1/g,
    replacement: 'npx tsx src/skills/skill-nudge.ts',
  },

  // Audit
  {
    pattern: /`audit-sweep\.ps1`/g,
    replacement: '`npx tsx src/audit-sweep.ts`',
  },
  {
    pattern: /`gv\.ps1\s+audit\s+<scope>`/g,
    replacement: '`npx tsx src/audit-sweep.ts --scope <scope>`',
  },

  // Sync
  {
    pattern: /`\.\\scripts\\utilities\\gentle-vanguard-sync\.ps1\s+-Mode\s+sync`/g,
    replacement: '`npx tsx src/sync-to-public.ts --mode sync`',
  },
  {
    pattern: /auto-delegation-router\.ps1/g,
    replacement: 'auto-delegation-router.ts',
  },
  {
    pattern: /pre-process-input\.ps1/g,
    replacement: 'pre-process-input.ts',
  },
];

function cleanSkillFile(filePath: string, apply: boolean): { changes: number; success: boolean } {
  if (!existsSync(filePath)) {
    return { changes: 0, success: false };
  }

  let content = readFileSync(filePath, 'utf-8');
  const originalContent = content;
  let changes = 0;

  for (const { pattern, replacement } of REPLACEMENTS) {
    const matches = content.match(pattern);
    if (matches) {
      content = content.replace(pattern, replacement);
      changes += matches.length;
    }
  }

  if (content !== originalContent && apply) {
    writeFileSync(filePath, content, 'utf-8');
  }

  return { changes, success: content !== originalContent };
}

function main() {
  const apply = process.argv.includes('--apply');

  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║   SKILLS PS1 CLEANER - Limpieza de Instrucciones      ║');
  console.log(
    `║   Modo: ${apply ? 'APLICAR CAMBIOS' : 'SIMULACIÓN (dry-run)'}                          ║`,
  );
  console.log('╚════════════════════════════════════════════════════════╝');
  console.log();

  if (!existsSync(SKILLS_DIR)) {
    console.error('❌ Directory not found:', SKILLS_DIR);
    return;
  }

  const files = readdirSync(SKILLS_DIR)
    .filter((f) => extname(f) === '.json')
    .map((f) => join(SKILLS_DIR, f));

  console.log(`Found ${files.length} skill files to scan\n`);

  let totalChanges = 0;
  let modifiedFiles = 0;

  for (const file of files) {
    const result = cleanSkillFile(file, apply);

    if (result.changes > 0) {
      modifiedFiles++;
      totalChanges += result.changes;
      const fileName = file.split('\\').pop();
      console.log(`📄 ${fileName}`);
      console.log(`   Cambios: ${result.changes}`);
    }
  }

  console.log('\n' + '═'.repeat(60));
  console.log(`📊 RESUMEN:`);
  console.log(`   Archivos escaneados: ${files.length}`);
  console.log(`   Archivos modificados: ${modifiedFiles}`);
  console.log(`   Total cambios: ${totalChanges}`);
  console.log();

  if (apply) {
    console.log('✅ Cambios aplicados a los archivos de skills');
  } else {
    console.log('💡 Usa --apply para aplicar los cambios');
  }
}

main();
