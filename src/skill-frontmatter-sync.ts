#!/usr/bin/env tsx
/**
 * skill-frontmatter-sync.ts — Batch update SKILL.md frontmatter for all system skills
 *
 * Adds or standardizes YAML frontmatter with:
 * - name: skill directory name
 * - description: concise description + trigger words
 * - triggers: list of keywords for routing
 *
 * Usage:
 *   npx tsx src/skill-frontmatter-sync.ts [--dry-run]
 */

import * as fs from 'fs';
import * as path from 'path';

const SKILLS_DIR = path.join(process.cwd(), '.opencode', 'skills');
const DRY_RUN = process.argv.includes('--dry-run');

interface SkillInfo {
  name: string;
  description: string;
  triggers: string[];
  hasWhenToUse: boolean;
}

// Skill registry with known metadata
const SKILL_REGISTRY: Record<string, Partial<SkillInfo>> = {
  'ab-testing': {
    description:
      'A/B experimentation framework for comparing variants, routing strategies, and behavioral changes.',
    triggers: ['ab-test', 'experiment', 'variant', 'split-test', 'a/b testing'],
  },
  'api-and-interface-design': {
    description:
      'Design stable APIs and module boundaries. Use for REST/GraphQL endpoints, component props, or public interface changes.',
    triggers: ['api design', 'interface', 'endpoint', 'module boundary', 'public api'],
  },
  'browser-testing-with-devtools': {
    description:
      'Test in real browsers via Chrome DevTools MCP. Inspect DOM, capture console errors, analyze network requests, profile performance.',
    triggers: ['browser test', 'devtools', 'chrome', 'dom inspect', 'performance profile'],
  },
  'ci-cd-and-automation': {
    description:
      'Automate CI/CD pipelines. Configure build processes, test runners, deployment strategies, and quality gates.',
    triggers: ['ci/cd', 'pipeline', 'automation', 'build', 'deploy', 'github actions'],
  },
  'code-review-and-quality': {
    description:
      'Multi-axis code review. Assess correctness, readability, architecture, security, and performance before merging.',
    triggers: ['code review', 'quality', 'review code', 'assess', 'pre-merge review'],
  },
  'code-simplification': {
    description:
      'Simplify code for clarity without changing behavior. Refactor complex code to be more readable and maintainable.',
    triggers: ['simplify', 'refactor', 'clarity', 'clean up', 'simplification'],
  },
  'context-engineering': {
    description:
      'Optimize context for new sessions. Manage context budget, compression, and efficiency for AI interactions.',
    triggers: ['context', 'context optimization', 'session start', 'context budget'],
  },
  dashboard: {
    description:
      'LLM Observability Dashboard — React/TypeScript/Vite SPA with real-time WebSocket data pipeline, i18n, and 14 metric descriptions.',
    triggers: ['dashboard', 'metrics', 'visualization', 'observability', 'charts'],
  },
  'debugging-and-error-recovery': {
    description:
      'Systematic root-cause debugging. Use when tests fail, builds break, or behavior does not match expectations.',
    triggers: ['debug', 'error', 'troubleshoot', 'fix bug', 'root cause'],
  },
  'deprecation-and-migration': {
    description:
      'Manage deprecation and migration. Remove old systems, migrate users between implementations, decide on feature sunsetting.',
    triggers: ['deprecate', 'migration', 'sunset', 'legacy', 'migrate'],
  },
  'documentation-and-adrs': {
    description:
      'Record architectural decisions and documentation. Use when shipping features, changing APIs, or recording context for future engineers.',
    triggers: ['document', 'adr', 'decision record', 'architecture decision', 'documentation'],
  },
  'doubt-driven-development': {
    description:
      'Fresh-context adversarial review. Use when correctness matters, working in unfamiliar code, or stakes are high.',
    triggers: ['doubt', 'adversarial', 'challenge assumptions', 'stress-test', 'review with doubt'],
  },
  'engram-auto-update': {
    description: 'Auto-update engram to latest version with validation and rollback.',
    triggers: ['engram update', 'update engram', 'memory update'],
  },
  'frontend-ui-engineering': {
    description:
      'Build production-quality, accessible, responsive user interfaces. Implement layouts, components, manage state, meet WCAG requirements.',
    triggers: ['frontend', 'ui', 'component', 'react', 'accessible', 'responsive'],
  },
  'gentle-ai-monitor': {
    description:
      'Monitor gentle-ai releases without installation. Absorb updates and generate actionable suggestions.',
    triggers: ['gentle-ai', 'monitor updates', 'track releases'],
  },
  'git-workflow-and-versioning': {
    description:
      'Structure git workflow practices. Commit, branch, resolve conflicts, organize parallel work, cut releases, version bumping.',
    triggers: ['git', 'commit', 'branch', 'version', 'release', 'tag', 'changelog'],
  },
  'idea-refine': {
    description:
      'Refine raw ideas into sharp concepts. Divergent then convergent thinking to stress-test assumptions and expand options.',
    triggers: ['idea', 'refine', 'ideate', 'concept', 'brainstorm', 'stress-test idea'],
  },
  'incremental-implementation': {
    description:
      'Deliver changes incrementally. Break features into small, ordered steps that can be implemented, tested, and verified.',
    triggers: ['incremental', 'small steps', 'break down', 'step by step', 'iterative'],
  },
  'interview-me': {
    description:
      'Extract what the user actually wants. One-question-at-a-time interviewing with hypothesis attached.',
    triggers: ['interview', 'clarify', 'extract requirements', 'interview me', 'grill me'],
  },
  'planning-and-task-breakdown': {
    description:
      'Break work into small, ordered tasks from specs or vague requirements. Decompose into implementable units with acceptance criteria.',
    triggers: ['plan', 'breakdown', 'tasks', 'decompose', 'planning', 'task breakdown'],
  },
  'spec-driven-development': {
    description:
      'Create specs before coding. Use when starting new projects or when requirements are unclear or ambiguous.',
    triggers: ['spec', 'specification', 'requirements', 'sdd', 'spec-driven', 'spec first'],
  },
  'test-driven-development': {
    description:
      'Drive development with tests. Write failing tests before code. Use when implementing logic, fixing bugs, or modifying behavior.',
    triggers: ['tdd', 'test driven', 'write test first', 'failing test', 'test before code'],
  },
  'using-agent-skills': {
    description:
      'Discover and invoke agent skills. Use when starting a session or when you need to discover which skill applies.',
    triggers: ['skill', 'discover skill', 'invoke skill', 'which skill', 'find skill'],
  },
  'validate-stack': {
    description:
      'Validate the full Gentle-Vanguard stack. Run verification steps for pre-process-input, session pipeline, hooks, and tool detection.',
    triggers: ['validate', 'stack verify', 'verify stack', 'check stack', 'validation'],
  },
};

function parseExistingSkill(content: string): { frontmatter: string | null; body: string } {
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (match) {
    return { frontmatter: match[1], body: match[2].trim() };
  }
  return { frontmatter: null, body: content };
}

function extractTitleFromBody(body: string): string | null {
  const match = body.match(/^#\s+(.+)$/m);
  return match ? match[1] : null;
}

function generateFrontmatter(skillName: string, info: Partial<SkillInfo>): string {
  const triggers = info.triggers || [skillName.replace(/-/g, ' ')];
  return `---
name: ${skillName}
description: ${info.description || 'System skill for Gentle-Vanguard.'}
triggers:
${triggers.map((t) => `  - ${t}`).join('\n')}
---
`;
}

async function processSkill(skillDir: string): Promise<boolean> {
  const skillName = path.basename(skillDir);
  const skillFile = path.join(skillDir, 'SKILL.md');

  if (!fs.existsSync(skillFile)) {
    console.log(`❌ ${skillName}: No SKILL.md found`);
    return false;
  }

  const content = fs.readFileSync(skillFile, 'utf-8');
  const { frontmatter: existingFrontmatter, body } = parseExistingSkill(content);

  // Check if already has proper frontmatter with triggers
  if (existingFrontmatter && content.match(/triggers:\s*\n[\s\S]*-/)) {
    console.log(`✅ ${skillName}: Already has triggers in frontmatter`);
    return true;
  }

  // Get skill info from registry or extract from content
  const info = SKILL_REGISTRY[skillName] || {};
  if (!info.description) {
    const title = extractTitleFromBody(body);
    if (title) {
      info.description = title.replace(/^#\s+/, '').trim();
    }
  }
  if (!info.triggers) {
    info.triggers = [skillName.replace(/-/g, ' ')];
  }

  const newFrontmatter = generateFrontmatter(skillName, info);
  const newContent = `${newFrontmatter}\n${body}`;

  if (DRY_RUN) {
    console.log(`🔍 ${skillName}: Would update frontmatter`);
    return true;
  }

  fs.writeFileSync(skillFile, newContent, 'utf-8');
  console.log(`✅ ${skillName}: Updated with frontmatter`);
  return true;
}

async function main(): Promise<void> {
  console.log('=== Skill Frontmatter Sync ===');
  console.log(`Mode: ${DRY_RUN ? 'DRY-RUN' : 'LIVE'}`);
  console.log('');

  if (!fs.existsSync(SKILLS_DIR)) {
    console.error(`Skills directory not found: ${SKILLS_DIR}`);
    process.exit(1);
  }

  const skillDirs = fs
    .readdirSync(SKILLS_DIR)
    .map((name) => path.join(SKILLS_DIR, name))
    .filter((dir) => fs.statSync(dir).isDirectory());

  let updated = 0;
  let alreadyOk = 0;
  let failed = 0;

  for (const skillDir of skillDirs) {
    try {
      const result = await processSkill(skillDir);
      if (result) {
        if (
          fs.readFileSync(path.join(skillDir, 'SKILL.md'), 'utf-8').match(/triggers:\s*\n[\s\S]*-/)
        ) {
          alreadyOk++;
        } else {
          updated++;
        }
      } else {
        failed++;
      }
    } catch (err) {
      console.error(`❌ Error processing ${skillDir}:`, err);
      failed++;
    }
  }

  console.log('');
  console.log('=== Summary ===');
  console.log(`Total skills: ${skillDirs.length}`);
  console.log(`Already OK: ${alreadyOk}`);
  console.log(`Updated: ${updated}`);
  console.log(`Failed: ${failed}`);

  if (DRY_RUN) {
    console.log('');
    console.log('Run without --dry-run to apply changes');
  }
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
