import { z } from 'zod';
import { execSync } from 'child_process';

export function registerReviewTool(server: any, gentleVanguardRoot: string) {
  server.tool(
    'gentle-vanguard_review',
    'Run 7D code review (security, quality, architecture, testing, docs, api, gitflow)',
    {
      path: z.string().describe('File or directory path to review'),
      dimensions: z.array(z.string()).optional().describe('Review dimensions: security, quality, architecture, testing, docs, api, gitflow'),
      mode: z.enum(['quick', 'full']).default('quick').describe('Review mode'),
    },
    async (args: any) => {
      try {
        const path = args.path;
        const dims = args.dimensions || ['security', 'quality', 'architecture'];
        const mode = args.mode || 'quick';
        const dimsStr = dims.join(',');
        const reviewScript = `${gentleVanguardRoot}/scripts/utilities/gv.ps1`;
        const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -File "${reviewScript}" review ${mode} -Dimensions ${dimsStr} -Path "${path}"`;
        
        const output = execSync(cmd, {
          cwd: gentleVanguardRoot,
          encoding: 'utf-8',
          maxBuffer: 10 * 1024 * 1024
        });

        return {
          content: [{ type: 'text', text: output }],
          isError: false,
        };
      } catch (error: any) {
        return {
          content: [{ type: 'text', text: `Review failed: ${error.message || error}` }],
          isError: true,
        };
      }
    }
  );
}

