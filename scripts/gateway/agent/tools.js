import { execSync, spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..', '..', '..');
const MAX_OUTPUT = 10000;

function truncate(text) {
  if (!text || text.length <= MAX_OUTPUT) return text || '';
  return text.slice(0, MAX_OUTPUT) + `\n... [truncated ${text.length - MAX_OUTPUT} more chars]`;
}

function safeExec(cmd, cwd = ROOT) {
  try {
    const out = execSync(cmd, { cwd, encoding: 'utf-8', timeout: 30000, maxBuffer: 5 * 1024 * 1024 });
    return { success: true, output: truncate(out) };
  } catch (err) {
    return { success: false, output: truncate(err.stdout + '\n' + err.stderr), error: err.message };
  }
}

export const toolDefinitions = [
  {
    name: 'execute_command',
    description: 'Execute a PowerShell or shell command in the project root directory. Use for git, npm, pwsh scripts, and any CLI tool.',
    parameters: {
      type: 'object',
      properties: {
        command: { type: 'string', description: 'Command to execute (e.g., "pwsh -NoProfile -Command \\"git status\\"")' },
        workdir: { type: 'string', description: 'Working directory relative to project root (default: ".")' },
        timeout: { type: 'number', description: 'Timeout in ms (default: 30000)' },
      },
      required: ['command'],
    },
  },
  {
    name: 'read_file',
    description: 'Read the contents of a file. Use for configs, scripts, logs, SKILL.md files.',
    parameters: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'File path relative to project root (e.g., "config/orchestrator.json")' },
        limit: { type: 'number', description: 'Max lines to read (default: 200)' },
      },
      required: ['path'],
    },
  },
  {
    name: 'write_file',
    description: 'Write content to a file. Creates directories if needed. WARNING: This overwrites existing files.',
    parameters: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'File path relative to project root' },
        content: { type: 'string', description: 'Content to write' },
      },
      required: ['path', 'content'],
    },
  },
  {
    name: 'search_files',
    description: 'Search file contents using regex. Use for finding code patterns, function definitions, imports.',
    parameters: {
      type: 'object',
      properties: {
        pattern: { type: 'string', description: 'Regex pattern to search (e.g., "function\\s+\\w+" or "export async" )' },
        include: { type: 'string', description: 'File glob filter (e.g., "*.js", "*.ps1", "*.json")' },
        path: { type: 'string', description: 'Subdirectory to search in (default: ".")' },
      },
      required: ['pattern'],
    },
  },
  {
    name: 'list_directory',
    description: 'List files and directories at a given path. Use to explore project structure.',
    parameters: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'Directory path relative to project root (default: ".")' },
        depth: { type: 'number', description: 'Max depth (default: 1, max: 3)' },
      },
      required: [],
    },
  },
  {
    name: 'git_command',
    description: 'Run a git command. Use for status, diff, log, add, commit, branch operations.',
    parameters: {
      type: 'object',
      properties: {
        args: { type: 'string', description: 'Git arguments (e.g., "status", "diff", "log --oneline -5", "add -A")' },
      },
      required: ['args'],
    },
  },
  {
    name: 'send_message',
    description: 'Send a message back to the user via their original platform (WhatsApp/Telegram). Always use this for your final response.',
    parameters: {
      type: 'object',
      properties: {
        text: { type: 'string', description: 'Message text to send (Markdown supported)' },
      },
      required: ['text'],
    },
  },
];

export async function executeTool(toolName, args, log) {
  switch (toolName) {
    case 'execute_command': {
      const cwd = args.workdir ? path.join(ROOT, args.workdir) : ROOT;
      return safeExec(args.command, cwd);
    }
    case 'read_file': {
      const fp = path.join(ROOT, args.path);
      try {
        if (!fs.existsSync(fp)) return { success: false, output: `File not found: ${args.path}` };
        const content = fs.readFileSync(fp, 'utf-8');
        const lines = content.split('\n');
        const limit = args.limit || 200;
        const shown = lines.slice(0, limit);
        let result = shown.join('\n');
        if (lines.length > limit) result += `\n... [${lines.length - limit} more lines]`;
        return { success: true, output: result };
      } catch (err) {
        return { success: false, output: `Error reading ${args.path}: ${err.message}` };
      }
    }
    case 'write_file': {
      const fp = path.join(ROOT, args.path);
      try {
        fs.mkdirSync(path.dirname(fp), { recursive: true });
        fs.writeFileSync(fp, args.content, 'utf-8');
        return { success: true, output: `Written ${args.path} (${args.content.length} chars)` };
      } catch (err) {
        return { success: false, output: `Error writing ${args.path}: ${err.message}` };
      }
    }
    case 'search_files': {
      const searchPath = args.path ? path.join(ROOT, args.path) : ROOT;
      const include = args.include ? `--include="${args.include}"` : '';
      return safeExec(`rg -n ${include} "${args.pattern.replace(/"/g, '\\"')}" "${searchPath}" 2>nul || echo "No matches found"`);
    }
    case 'list_directory': {
      const dir = args.path ? path.join(ROOT, args.path) : ROOT;
      try {
        if (!fs.existsSync(dir)) return { success: false, output: `Directory not found: ${args.path || '.'}` };
        const depth = Math.min(args.depth || 1, 3);
        const items = fs.readdirSync(dir, { withFileTypes: true });
        let out = `Contents of ${args.path || '.'}:\n`;
        for (const item of items) {
          const prefix = item.isDirectory() ? '📁 ' : '📄 ';
          out += `${prefix}${item.name}\n`;
          if (item.isDirectory() && depth > 1) {
            try {
              const sub = fs.readdirSync(path.join(dir, item.name));
              for (const s of sub) {
                out += `  ${s}\n`;
              }
            } catch { }
          }
        }
        return { success: true, output: out };
      } catch (err) {
        return { success: false, output: `Error listing ${args.path || '.'}: ${err.message}` };
      }
    }
    case 'git_command': {
      return safeExec(`git ${args.args}`);
    }
    case 'send_message': {
      return { success: true, output: args.text, isResponse: true };
    }
    default:
      return { success: false, output: `Unknown tool: ${toolName}` };
  }
}
