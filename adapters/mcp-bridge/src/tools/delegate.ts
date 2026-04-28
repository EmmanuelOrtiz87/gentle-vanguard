import { z } from 'zod';
import { execSync } from 'child_process';

export function registerDelegateTool(server: any, foundationRoot: string) {
  server.tool(
    'foundation_delegate',
    'Delegate task to Foundation subagent (sdd-apply, sdd-design, sdd-verify, etc.)',
    {
      agent: z.string().describe('Agent type: sdd-apply, sdd-design, sdd-verify, sdd-spec, sdd-tasks, etc.'),
      prompt: z.string().describe('Task description or prompt for the agent'),
      taskId: z.string().optional().describe('Optional task ID to resume existing session'),
    },
    async (args: any) => {
      try {
        const agent = args.agent;
        const prompt = args.prompt;
        const taskId = args.taskId || '';
        const delegateScript = `${foundationRoot}/scripts/utilities/wf.ps1`;
        const taskParam = taskId ? `-TaskId "${taskId}"` : '';
        const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -File "${delegateScript}" delegate -Agent "${agent}" -Prompt "${prompt}" ${taskParam}`;
        
        const output = execSync(cmd, {
          cwd: foundationRoot,
          encoding: 'utf-8',
          maxBuffer: 10 * 1024 * 1024,
          timeout: 300000
        });

        return {
          content: [{ type: 'text', text: output }],
          isError: false,
        };
      } catch (error: any) {
        return {
          content: [{ type: 'text', text: `Delegation failed: ${error.message || error}` }],
          isError: true,
        };
      }
    }
  );
}
