import { z } from 'zod';
import { execSync } from 'child_process';

export function registerHealthTool(server: any, gentleVanguardRoot: string) {
  server.tool(
    'gentle-vanguard_health',
    'Check Gentle-Vanguard workspace health (tools, scripts, token budget, session status)',
    {
      detailed: z.boolean().default(false).describe('Include detailed checks'),
      strict: z.boolean().default(false).describe('Enable strict cleanup mode'),
    },
    async (args: any) => {
      try {
        const detailed = args.detailed || false;
        const strict = args.strict || false;
        const healthScript = `${gentleVanguardRoot}/scripts/utilities/gv.ps1`;
        const strictFlag = strict ? '-StrictCleanup' : '';
        const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -File "${healthScript}" health ${strictFlag}`;
        
        const output = execSync(cmd, {
          cwd: gentleVanguardRoot,
          encoding: 'utf-8',
          maxBuffer: 5 * 1024 * 1024
        });

        return {
          content: [{ type: 'text', text: output }],
          isError: false,
        };
      } catch (error: any) {
        return {
          content: [{ type: 'text', text: `Health check failed: ${error.message || error}` }],
          isError: true,
        };
      }
    }
  );
}

