import { readFileSync } from 'node:fs';
import { z } from 'zod';

const commandPolicyEntrySchema = z
  .object({
    command: z.string().min(1),
    executable: z.string().min(1),
    args: z.array(z.string()),
    timeoutMs: z.number().int().positive().max(300_000).default(60_000),
    maxOutputBytes: z
      .number()
      .int()
      .positive()
      .max(10 * 1024 * 1024)
      .default(1_048_576),
    network: z.boolean().default(false),
    filesystem: z.enum(['workspace', 'broad']).default('workspace'),
  })
  .strict();

const executionPolicySchema = z
  .object({
    $schema: z.string().optional(),
    version: z.string().min(1),
    skills: z.record(z.string(), commandPolicyEntrySchema),
  })
  .strict();

type ParsedCommand = z.infer<typeof commandPolicyEntrySchema>;
export type ApprovedCommand = Omit<
  ParsedCommand,
  'timeoutMs' | 'maxOutputBytes' | 'network' | 'filesystem'
> & {
  timeoutMs?: number;
  maxOutputBytes?: number;
  network?: boolean;
  filesystem?: 'workspace' | 'broad';
};
export type SkillExecutionPolicy = z.infer<typeof executionPolicySchema>;

export function parseCommandField(skillContent: string): string | undefined {
  if (!skillContent.startsWith('---')) return undefined;
  const end = skillContent.indexOf('---', 3);
  if (end === -1) return undefined;

  const frontmatter = skillContent.slice(3, end).trim();
  for (const field of ['command', 'run', 'script']) {
    const match = frontmatter.match(new RegExp(`^${field}:\\s*(.+)$`, 'm'));
    if (match?.[1] !== undefined && match[1] !== '') return match[1].trim();
  }
  return undefined;
}

export function loadSkillExecutionPolicy(policyPath: string): SkillExecutionPolicy {
  try {
    const parsed: unknown = JSON.parse(readFileSync(policyPath, 'utf-8'));
    return executionPolicySchema.parse(parsed);
  } catch {
    return { version: 'invalid', skills: {} };
  }
}

export function getApprovedCommand(
  policy: SkillExecutionPolicy,
  skillName: string,
  frontmatterCommand: string,
): ApprovedCommand | undefined {
  const approval = policy.skills[skillName];
  if (approval === undefined || approval.command !== frontmatterCommand) return undefined;
  return approval;
}
