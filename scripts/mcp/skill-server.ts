import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { McpError, ErrorCode } from '@modelcontextprotocol/sdk/types.js';
import { z } from 'zod';
import { execSync } from 'child_process';
import { readFileSync, readdirSync, existsSync, statSync, mkdirSync, writeFileSync } from 'fs';
import { join, resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = resolve(__dirname, '../../..');
const REGISTRY_PATH = join(ROOT, '.atl', 'skill-registry.md');
const SKILLS_DIR = join(ROOT, 'skills');
const STATS_PATH = join(ROOT, '.atl', 'skill-stats.json');

interface ParsedSkill {
  name: string;
  description: string;
  agent: string;
  triggers: string[];
  detail: string;
  files: string[];
  lastModified: Date;
}

interface SkillStats {
  totalCalls: number;
  callsByTool: Record<string, number>;
  callsBySkill: Record<string, number>;
  lastCall: string | null;
}

function log(
  level: 'INFO' | 'WARN' | 'ERROR',
  message: string,
  meta?: Record<string, unknown>,
): void {
  const timestamp = new Date().toISOString();
  const metaStr = meta ? ' ' + JSON.stringify(meta) : '';
  console.error(`[${timestamp}] [${level}] ${message}${metaStr}`);
}

function parseRegistryLine(
  line: string,
): { name: string; agent: string; triggers: string[] } | null {
  const parts = line.split('|').map((s) => s.trim());
  if (parts.length < 4) return null;
  const agent = parts[1];
  const name = parts[2];
  const rawTriggers = parts[3] || '';
  const triggers = rawTriggers
    .split(',')
    .map((t) => t.trim().replace(/^"|"$/g, ''))
    .filter((t) => t.length > 0 && t !== '...');
  if (!name || name.startsWith('-')) return null;
  if (name.includes('\\') || name.includes('/') || name === 'Path') return null;
  if (agent === 'File') return null;
  return { name, agent, triggers };
}

function parseFrontmatter(filePath: string): { name?: string; description?: string } {
  try {
    const content = readFileSync(filePath, 'utf-8');
    if (!content.startsWith('---')) return {};
    const end = content.indexOf('---', 3);
    if (end === -1) return {};
    const fm = content.slice(3, end).trim();
    const name = fm.match(/^name:\s*(.+)$/m)?.[1]?.trim();
    const descMatch = fm.match(/^description:\s*(.+)$/m);
    let description = descMatch?.[1]?.trim().replace(/^>\s*/, '');
    if (description === undefined) {
      const multiMatch = fm.match(/^description:\s*\n(?:^>\s*(.+))$/m);
      description = multiMatch?.[1]?.trim();
    }
    return { name, description };
  } catch {
    return {};
  }
}

function getSkillFiles(skillDir: string): string[] {
  if (!existsSync(skillDir)) return [];
  try {
    return readdirSync(skillDir, { recursive: true })
      .filter((f): f is string => typeof f === 'string')
      .filter((f) => f.endsWith('.md'));
  } catch {
    return [];
  }
}

function getLastModified(skillDir: string): Date {
  if (!existsSync(skillDir)) return new Date(0);
  try {
    const stats = statSync(skillDir);
    return stats.mtime;
  } catch {
    return new Date(0);
  }
}

function buildSkillMap(): Map<string, ParsedSkill> {
  const map = new Map<string, ParsedSkill>();
  if (!existsSync(REGISTRY_PATH)) {
    log('WARN', 'Registry not found', { path: REGISTRY_PATH });
    return map;
  }

  const lines = readFileSync(REGISTRY_PATH, 'utf-8').split('\n');
  let inMapping = false;

  for (const line of lines) {
    if (line.includes('| Agent') && line.includes('| Skill')) {
      inMapping = true;
      continue;
    }
    if (!inMapping) continue;
    if (line.startsWith('#') || line.trim().length === 0) continue;
    if (!line.includes('|')) continue;

    const parsed = parseRegistryLine(line);
    if (!parsed) continue;

    const skillDir = join(SKILLS_DIR, parsed.name);
    const skillMdPath = join(skillDir, 'SKILL.md');
    const fm = existsSync(skillMdPath) ? parseFrontmatter(skillMdPath) : {};

    let detail = '';
    const refDetail = join(skillDir, 'references', 'detail.md');
    if (existsSync(refDetail)) {
      try {
        detail = readFileSync(refDetail, 'utf-8').slice(0, 500);
      } catch {
        detail = '';
      }
    }

    map.set(parsed.name, {
      name: parsed.name,
      description: fm.description ?? parsed.name,
      agent: parsed.agent,
      triggers: parsed.triggers,
      detail,
      files: getSkillFiles(skillDir),
      lastModified: getLastModified(skillDir),
    });
  }

  log('INFO', 'Skill map built', { count: map.size });
  return map;
}

function buildSummaryTable(skills: Map<string, ParsedSkill>): string {
  const agents = new Map<string, number>();
  for (const s of skills.values()) {
    agents.set(s.agent, (agents.get(s.agent) ?? 0) + 1);
  }
  let table = '| Agent | Skills |\n|-------|--------|\n';
  for (const [agent, count] of agents) {
    table += `| ${agent} | ${count} |\n`;
  }
  return table;
}

function loadStats(): SkillStats {
  if (!existsSync(STATS_PATH)) {
    return { totalCalls: 0, callsByTool: {}, callsBySkill: {}, lastCall: null };
  }
  try {
    const content = readFileSync(STATS_PATH, 'utf-8');
    return JSON.parse(content);
  } catch {
    return { totalCalls: 0, callsByTool: {}, callsBySkill: {}, lastCall: null };
  }
}

function saveStats(stats: SkillStats): void {
  try {
    const dir = dirname(STATS_PATH);
    if (!existsSync(dir)) {
      mkdirSync(dir, { recursive: true });
    }
    writeFileSync(STATS_PATH, JSON.stringify(stats, null, 2));
  } catch (err) {
    log('WARN', 'Failed to save stats', { error: String(err) });
  }
}

function trackCall(stats: SkillStats, tool: string, skillName?: string): void {
  stats.totalCalls++;
  stats.callsByTool[tool] = (stats.callsByTool[tool] ?? 0) + 1;
  if (skillName !== undefined && skillName !== '') {
    stats.callsBySkill[skillName] = (stats.callsBySkill[skillName] ?? 0) + 1;
  }
  stats.lastCall = new Date().toISOString();
  saveStats(stats);
}

const skills = buildSkillMap();
const stats = loadStats();

const server = new McpServer({
  name: 'gentle-vanguard-skills',
  version: '2.0.0',
});

server.tool(
  'list_skills',
  {
    agent: z.string().optional().describe('Filter by agent code'),
    search: z.string().optional().describe('Search skills by name'),
  },
  async ({ agent, search }) => {
    try {
      trackCall(stats, 'list_skills');
      let filtered = Array.from(skills.values());

      if (agent !== undefined) {
        const re = new RegExp(agent.replace(/-/g, '[- ]').replace(/\*/g, '.*'), 'i');
        filtered = filtered.filter((s) => re.test(s.agent));
      }
      if (search !== undefined) {
        const q = search.toLowerCase();
        filtered = filtered.filter(
          (s) =>
            s.name.toLowerCase().includes(q) ||
            s.description.toLowerCase().includes(q) ||
            s.triggers.some((t) => t.toLowerCase().includes(q)),
        );
      }

      const summary = buildSummaryTable(skills);
      const list = filtered
        .map((s) => `- **${s.name}** (_${s.agent}_) — ${s.triggers.slice(0, 3).join(', ')}`)
        .join('\n');

      log('INFO', 'list_skills executed', { filtered: filtered.length, total: skills.size });

      return {
        content: [
          {
            type: 'text',
            text: `**Skills**: ${filtered.length} / ${skills.size}\n\n${summary}\n\n### Skills\n${list}`,
          },
        ],
      };
    } catch (err) {
      log('ERROR', 'list_skills failed', { error: String(err) });
      throw new McpError(ErrorCode.InternalError, `Failed to list skills: ${err}`);
    }
  },
);

server.tool(
  'get_skill',
  {
    name: z.string().describe('Skill name'),
  },
  async ({ name: skillName }) => {
    try {
      trackCall(stats, 'get_skill', skillName);
      const skill = skills.get(skillName);
      if (!skill) {
        throw new McpError(ErrorCode.InvalidRequest, `Skill "${skillName}" not found`);
      }

      const dir = join(SKILLS_DIR, skillName);
      const files = existsSync(dir)
        ? readdirSync(dir, { recursive: true })
            .filter((f): f is string => typeof f === 'string')
            .filter((f) => f.endsWith('.md'))
        : [];

      let fullDetail = skill.detail;
      if (!fullDetail) {
        const skillMdPath = join(dir, 'SKILL.md');
        if (existsSync(skillMdPath)) {
          fullDetail = readFileSync(skillMdPath, 'utf-8').slice(0, 2000);
        }
      }

      log('INFO', 'get_skill executed', { skill: skillName });

      return {
        content: [
          {
            type: 'text',
            text: [
              `## ${skill.name}`,
              `**Agent**: ${skill.agent}`,
              `**Description**: ${skill.description}`,
              `**Triggers**: ${skill.triggers.join(', ') || '(none)'}`,
              `**Files**: ${files.length > 0 ? files.join(', ') : '(skill directory only)'}`,
              '',
              fullDetail ? `### Detail\n${fullDetail.slice(0, 1500)}` : '',
            ]
              .filter(Boolean)
              .join('\n'),
          },
        ],
      };
    } catch (err) {
      if (err instanceof McpError) throw err;
      log('ERROR', 'get_skill failed', { error: String(err), skill: skillName });
      throw new McpError(ErrorCode.InternalError, `Failed to get skill: ${err}`);
    }
  },
);

server.tool(
  'search_skills',
  {
    query: z.string().describe('Search keyword'),
  },
  async ({ query }) => {
    try {
      trackCall(stats, 'search_skills');
      const q = query.toLowerCase();
      if (!q) {
        throw new McpError(ErrorCode.InvalidRequest, 'Query is required');
      }

      const results = Array.from(skills.values()).filter(
        (s) =>
          s.name.toLowerCase().includes(q) ||
          s.description.toLowerCase().includes(q) ||
          s.triggers.some((t) => t.toLowerCase().includes(q)) ||
          s.detail.toLowerCase().includes(q),
      );

      if (results.length === 0) {
        return {
          content: [{ type: 'text', text: `No skills found matching "${query}"` }],
        };
      }

      log('INFO', 'search_skills executed', { query, results: results.length });

      return {
        content: [
          {
            type: 'text',
            text: [
              `**Search results for "${query}"**: ${results.length} skills`,
              '',
              ...results.map(
                (s) => `- **${s.name}** (_${s.agent}_) — ${s.triggers.slice(0, 2).join(', ')}`,
              ),
            ].join('\n'),
          },
        ],
      };
    } catch (err) {
      if (err instanceof McpError) throw err;
      log('ERROR', 'search_skills failed', { error: String(err) });
      throw new McpError(ErrorCode.InternalError, `Failed to search skills: ${err}`);
    }
  },
);

server.tool(
  'execute_skill',
  {
    name: z.string().describe('Skill name to execute'),
    params: z.record(z.string(), z.unknown()).optional().describe('Parameters'),
  },
  async ({ name, params: _params }) => {
    try {
      trackCall(stats, 'execute_skill', name);
      const skill = skills.get(name);
      if (!skill) {
        throw new McpError(ErrorCode.InvalidRequest, `Skill "${name}" not found`);
      }

      const skillMdPath = join(SKILLS_DIR, name, 'SKILL.md');
      if (!existsSync(skillMdPath)) {
        throw new McpError(ErrorCode.InvalidRequest, `Skill "${name}" has no SKILL.md`);
      }

      const skillContent = readFileSync(skillMdPath, 'utf-8');

      let commandField: string | undefined;
      if (skillContent.startsWith('---')) {
        const end = skillContent.indexOf('---', 3);
        if (end !== -1) {
          const fm = skillContent.slice(3, end).trim();
          for (const field of ['command', 'run', 'script']) {
            const re = new RegExp(`^${field}:\\s*(.+)$`, 'm');
            const match = fm.match(re);
            if (match !== null && match[1] !== undefined && match[1] !== '') {
              commandField = match[1].trim();
              break;
            }
          }
        }
      }

      if (commandField !== undefined && commandField !== '') {
        log('INFO', 'execute_skill (running command)', { skill: name, command: commandField });
        try {
          const result = execSync(commandField, {
            encoding: 'utf-8',
            timeout: 60000,
            cwd: SKILLS_DIR,
          });
          return {
            content: [{ type: 'text', text: result }],
          };
        } catch (execErr) {
          const msg = execErr instanceof Error ? execErr.message : String(execErr);
          log('ERROR', 'execute_skill command failed', { skill: name, error: msg });
          return {
            content: [{ type: 'text', text: `Command execution failed:\n${msg}` }],
          };
        }
      }

      log('INFO', 'execute_skill (docs only)', { skill: name });
      return {
        content: [{ type: 'text', text: skillContent }],
      };
    } catch (err) {
      if (err instanceof McpError) throw err;
      log('ERROR', 'execute_skill failed', { error: String(err) });
      throw new McpError(ErrorCode.InternalError, `Failed to execute skill: ${err}`);
    }
  },
);

server.tool(
  'validate_skill',
  {
    name: z.string().describe('Skill name to validate'),
  },
  async ({ name }) => {
    try {
      trackCall(stats, 'validate_skill', name);
      const skill = skills.get(name);
      if (!skill) {
        throw new McpError(ErrorCode.InvalidRequest, `Skill "${name}" not found`);
      }

      const skillDir = join(SKILLS_DIR, name);
      const skillMdPath = join(skillDir, 'SKILL.md');
      const errors: string[] = [];
      const warnings: string[] = [];

      if (!existsSync(skillDir)) {
        errors.push(`Skill directory not found`);
      } else {
        if (!existsSync(skillMdPath)) {
          errors.push('SKILL.md not found');
        } else {
          const content = readFileSync(skillMdPath, 'utf-8');
          if (!content.startsWith('---')) {
            errors.push('Missing YAML frontmatter');
          }
          if (!content.includes('## Usage')) {
            warnings.push('Missing ## Usage section');
          }
        }

        const refDir = join(skillDir, 'references');
        if (!existsSync(refDir)) {
          warnings.push('No references directory');
        }
      }

      const isValid = errors.length === 0;
      log('INFO', 'validate_skill executed', { skill: name, valid: isValid });

      return {
        content: [
          {
            type: 'text',
            text: [
              `## Validation: ${name}`,
              `**Status**: ${isValid ? 'Valid' : 'Invalid'}`,
              errors.length > 0 ? `### Errors\n${errors.map((e) => `- ${e}`).join('\n')}` : '',
              warnings.length > 0
                ? `### Warnings\n${warnings.map((w) => `- ${w}`).join('\n')}`
                : '',
            ]
              .filter(Boolean)
              .join('\n'),
          },
        ],
      };
    } catch (err) {
      if (err instanceof McpError) throw err;
      log('ERROR', 'validate_skill failed', { error: String(err) });
      throw new McpError(ErrorCode.InternalError, `Failed to validate skill: ${err}`);
    }
  },
);

// MCP Prompts
server.prompt(
  'skill_usage_guide',
  {
    skillName: z.string().describe('Name of the skill to get usage guide for'),
  },
  ({ skillName }) => {
    const skill = skills.get(skillName);
    if (!skill) {
      return {
        messages: [
          {
            role: 'assistant',
            content: {
              type: 'text',
              text: `Skill "${skillName}" not found in the registry.`,
            },
          },
        ],
      };
    }

    const guide = [
      `# Skill Usage Guide: ${skillName}`,
      '',
      `**Agent**: ${skill.agent}`,
      `**Description**: ${skill.description}`,
      `**Triggers**: ${skill.triggers.join(', ') || '(none)'}`,
      '',
      '## How to Use',
      '',
      '1. **Identify the correct agent**: This skill is designed for the ' +
        `${skill.agent} agent.`,
      '',
      '2. **Trigger phrases**: Use any of these phrases to activate:',
      ...skill.triggers.map((t) => `   - "${t}"`),
      '',
      '3. **Execute the skill**: Once triggered, the agent will follow the',
      '   instructions defined in the skill documentation.',
      '',
      '## Validation',
      '',
      'Run the `validate_skill` tool to check if this skill is properly configured.',
      '',
      '## Best Practices',
      '',
      '- Always verify the skill is appropriate for your task',
      "- Check the skill's examples section for usage patterns",
      '- Use the `get_skill` tool to view full documentation',
    ].join('\n');

    return {
      messages: [
        {
          role: 'assistant',
          content: {
            type: 'text',
            text: guide,
          },
        },
      ],
    };
  },
);

server.prompt(
  'skill_development_guide',
  {
    skillName: z.string().optional().describe('Optional skill name for specific guidance'),
  },
  ({ skillName }) => {
    const specificSkill =
      skillName !== undefined && skillName !== '' ? skills.get(skillName) : null;

    const guide = [
      '# Skill Development Guide',
      '',
      '## Creating a New Skill',
      '',
      '1. **Create skill directory**: `mkdir skills/my-skill`',
      '2. **Add SKILL.md**: Create `skills/my-skill/SKILL.md` with:',
      '   - YAML frontmatter (name, description)',
      '   - ## Usage section',
      '   - ## Examples section',
      '   - ## References (optional)',
      '3. **Add references/**: Create `skills/my-skill/references/` for additional docs',
      '4. **Register skill**: Add to `.atl/skill-registry.md`',
      '',
      '## Skill Structure',
      '',
      '```',
      'skills/my-skill/',
      '├── SKILL.md           # Main skill definition',
      '└── references/',
      '    └── detail.md      # Additional documentation (optional)',
      '```',
      '',
      '## Validation',
      '',
      'Use the `validate_skill` tool to check your skill:',
      '- Validates YAML frontmatter',
      '- Checks for required sections',
      '- Verifies references directory',
      '',
      '## Testing',
      '',
      'Test your skill with `execute_skill` before deployment.',
      ...(specificSkill
        ? [
            '',
            `## Reference: ${skillName}`,
            `Agent: ${specificSkill.agent}`,
            `Triggers: ${specificSkill.triggers.join(', ')}`,
          ]
        : []),
    ].join('\n');

    return {
      messages: [
        {
          role: 'assistant',
          content: {
            type: 'text',
            text: guide,
          },
        },
      ],
    };
  },
);

server.prompt(
  'agent_selection_guide',
  {
    task: z.string().describe('Description of the task you need help with'),
  },
  ({ task }) => {
    const taskLower = task.toLowerCase();
    const recommendations: string[] = [];

    // Simple keyword matching for recommendations
    if (
      taskLower.includes('code') ||
      taskLower.includes('implement') ||
      taskLower.includes('develop')
    ) {
      recommendations.push('**DEV** - For code implementation and development tasks');
    }
    if (taskLower.includes('test') || taskLower.includes('quality') || taskLower.includes('bug')) {
      recommendations.push('**QA** - For testing, validation, and quality assurance');
    }
    if (taskLower.includes('doc') || taskLower.includes('document')) {
      recommendations.push('**DOC** - For documentation and technical writing');
    }
    if (
      taskLower.includes('deploy') ||
      taskLower.includes('infrastructure') ||
      taskLower.includes('ops')
    ) {
      recommendations.push('**OPS** - For deployment and infrastructure tasks');
    }
    if (
      taskLower.includes('govern') ||
      taskLower.includes('compliance') ||
      taskLower.includes('security')
    ) {
      recommendations.push('**GOV** - For governance, compliance, and security');
    }
    if (taskLower.includes('analyze') || taskLower.includes('requirement')) {
      recommendations.push('**BA** - For business analysis and requirements');
    }

    if (recommendations.length === 0) {
      recommendations.push('**DEV** - General development tasks');
    }

    const guide = [
      '# Agent Selection Guide',
      '',
      `**Task**: ${task}`,
      '',
      '## Recommended Agents',
      '',
      ...recommendations.map((r) => `- ${r}`),
      '',
      '## Next Steps',
      '',
      '1. Use `list_skills` with the agent filter to see available skills',
      `   Example: list_skills with agent="${recommendations[0].replace(/\*\*/g, '').split(' ')[0]}"`,
      '',
      '2. Review skill triggers to find the best match',
      '',
      '3. Execute the appropriate skill for your task',
      '',
      '## Available Agents',
    ];

    // Add agent counts
    const agentCounts = new Map<string, number>();
    for (const s of skills.values()) {
      agentCounts.set(s.agent, (agentCounts.get(s.agent) ?? 0) + 1);
    }
    for (const [agent, count] of agentCounts) {
      guide.push(`- ${agent}: ${count} skill(s)`);
    }

    return {
      messages: [
        {
          role: 'assistant',
          content: {
            type: 'text',
            text: guide.join('\n'),
          },
        },
      ],
    };
  },
);

async function main(): Promise<void> {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
