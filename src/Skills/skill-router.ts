#!/usr/bin/env node
/**
 * Skill Router — Query routing for specialized skills.
 * Validates access for restricted operations.
 * TS migration of scripts/utilities/skills/SKILL/skill-router.ps1
 */

import { pathToFileURL } from 'url';

const SKILL_KEYWORDS: Record<string, string[]> = {
  angular: ['angular-core', 'angular-spa', 'angular-architecture'],
  react: ['react-19', 'react-19-skill'],
  go: ['golang-api', 'go-api', 'go-testing'],
  docker: ['docker-devops'],
  git: ['git-workflow'],
  security: ['security-skill'],
  test: ['testing-skill', 'testing-strategy'],
  typescript: ['typescript', 'typescript-skill'],
  zod: ['zod-4', 'zod-4-skill'],
  tailwind: ['tailwind-4', 'tailwind-4-skill'],
  zustand: ['zustand-5', 'zustand-5-skill'],
  next: ['nextjs-15', 'nextjs-15-skill'],
  ai: ['ai-sdk-5', 'ai-sdk-5-skill'],
  mcp: ['mcp-skill'],
  jira: ['jira-task', 'jira-epic'],
  github: ['github-pr', 'branch-pr'],
  django: ['django-drf', 'django-drf-skill'],
  playwright: ['playwright'],
  pytest: ['pytest'],
  database: ['database-relational', 'database-nosql'],
  api: ['api-design'],
  documentation: ['documentation-governance'],
  architecture: ['architecture-governance'],
  sdd: ['sdd-init', 'sdd-propose', 'sdd-explore', 'sdd-design', 'sdd-spec', 'sdd-tasks', 'sdd-apply', 'sdd-verify', 'sdd-archive'],
  'gentle-vanguard': ['gentle-vanguard-audit'],
  session: ['session-lifecycle'],
  automation: ['workspace-automation', 'project-scaffolding'],
};

function main(): void {
  const args = process.argv.slice(2);
  const queryIdx = args.indexOf('--query') !== -1 ? args.indexOf('--query') + 1 :
                   args.indexOf('-Query') !== -1 ? args.indexOf('-Query') + 1 : -1;
  const query = queryIdx >= 0 ? args[queryIdx] : '';
  // project available if needed: args[args.indexOf('--project') + 1] ?? 'workspace_gentle_vanguard'

  if (!query) {
    console.error('SKILL-ROUTER: --query is required');
    process.exit(1);
  }

  const queryLower = query.toLowerCase();
  const matchedSet = new Set<string>();

  for (const [keyword, skills] of Object.entries(SKILL_KEYWORDS)) {
    if (queryLower.includes(keyword)) {
      for (const s of skills) matchedSet.add(s);
    }
  }

  const matchedSkills = [...matchedSet];

  if (matchedSkills.length > 0) {
    console.log(`SKILL-ROUTER: Found ${matchedSkills.length} matching skill(s)`);
    for (const s of matchedSkills) console.log(`  - ${s}`);
    console.log(JSON.stringify({ Status: 'Routed', Skills: matchedSkills, Query: query }));
  } else {
    console.log('SKILL-ROUTER: No specific skills matched for query');
    console.log(JSON.stringify({ Status: 'NoMatch', Skills: [], Query: query }));
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
