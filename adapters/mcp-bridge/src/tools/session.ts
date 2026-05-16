import { z } from 'zod';
import { execSync } from 'child_process';

export function registerSessionTools(server: any, gentle-vanguardRoot: string) {
  // Start session
  server.tool(
    'gentle-vanguard_session_start',
    'Start new Gentle-Vanguard session with automatic tool detection',
    {
      project: z.string().optional().describe('Project name (defaults to workspace_gentle_vanguard)'),
      directory: z.string().optional().describe('Working directory'),
    },
    async (args: any) => {
      try {
        const project = args.project || '';
        const directory = args.directory || '';
        const sessionScript = `${gentle-vanguardRoot}/scripts/utilities/gv.ps1`;
        const projParam = project ? `-Project "${project}"` : '';
        const dirParam = directory ? `-Directory "${directory}"` : '';
        const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -File "${sessionScript}" start-session ${projParam} ${dirParam}`;
        
        const output = execSync(cmd, {
          cwd: gentle-vanguardRoot,
          encoding: 'utf-8',
          maxBuffer: 5 * 1024 * 1024
        });

        return {
          content: [{ type: 'text', text: output }],
          isError: false,
        };
      } catch (error: any) {
        return {
          content: [{ type: 'text', text: `Session start failed: ${error.message || error}` }],
          isError: true,
        };
      }
    }
  );

  // End session
  server.tool(
    'gentle-vanguard_session_end',
    'End session with summary (saves to Engram memory)',
    {
      sessionId: z.string().describe('Session ID to close'),
      summary: z.string().optional().describe('Session summary (Goal, Discoveries, Accomplished, Next Steps)'),
    },
    async (args: any) => {
      try {
        const sessionId = args.sessionId;
        const summary = args.summary || '';
        const engramScript = `${gentle-vanguardRoot}/scripts/utilities/engram.ps1`;
        const summaryParam = summary ? `-Summary "${summary}"` : '';
        const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -File "${engramScript}" session-end -Id "${sessionId}" ${summaryParam}`;
        
        const output = execSync(cmd, {
          cwd: gentle-vanguardRoot,
          encoding: 'utf-8',
          maxBuffer: 5 * 1024 * 1024
        });

        return {
          content: [{ type: 'text', text: output }],
          isError: false,
        };
      } catch (error: any) {
        return {
          content: [{ type: 'text', text: `Session end failed: ${error.message || error}` }],
          isError: true,
        };
      }
    }
  );
}

