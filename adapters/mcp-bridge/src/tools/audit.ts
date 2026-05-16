import { z } from 'zod';
import { execSync } from 'child_process';

export function registerAuditTool(server: any, gentle-vanguardRoot: string) {
  server.tool(
    'gentle-vanguard_audit',
    'Run comprehensive workspace audit (delivery status, operational risk, test suite, git status)',
    {
      mode: z.enum(['quick', 'full']).default('full').describe('Audit mode'),
      outputFile: z.string().optional().describe('Output file path for audit report'),
    },
    async (args: any) => {
      try {
        const mode = args.mode || 'full';
        const outputFile = args.outputFile || '';
        const auditScript = `${gentle-vanguardRoot}/scripts/utilities/gv.ps1`;
        const outParam = outputFile ? `-OutputFile "${outputFile}"` : '';
        const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -File "${auditScript}" audit -Mode ${mode} ${outParam}`;
        
        const output = execSync(cmd, {
          cwd: gentle-vanguardRoot,
          encoding: 'utf-8',
          maxBuffer: 10 * 1024 * 1024
        });

        return {
          content: [{ type: 'text', text: output }],
          isError: false,
        };
      } catch (error: any) {
        return {
          content: [{ type: 'text', text: `Audit failed: ${error.message || error}` }],
          isError: true,
        };
      }
    }
  );
}

