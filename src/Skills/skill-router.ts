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
  database: ['database-relational', 'database-nosql', 'nexus-database'],
  nexus: ['nexus-database'],
  'gentle-vanguard': ['gentle-vanguard-audit', 'nexus-database'],
  'db-': ['nexus-database'],
  dbinit: ['nexus-database'],
  dbhealth: ['nexus-database'],
  dbbackup: ['nexus-database'],
  dbprune: ['nexus-database'],
  'session_scoring': ['nexus-database'],
  'response_cache': ['nexus-database'],
  'token_usage': ['nexus-database'],
  'routing_rules': ['nexus-database'],
  api: ['api-design'],
  documentation: ['documentation-governance'],
  architecture: ['architecture-governance'],
  sdd: ['sdd-init', 'sdd-propose', 'sdd-explore', 'sdd-design', 'sdd-spec', 'sdd-tasks', 'sdd-apply', 'sdd-verify', 'sdd-archive'],
  session: ['session-lifecycle'],
  automation: ['workspace-automation', 'project-scaffolding'],
  // Design skills
  accessibility: ['accessibility-design-skill', 'accessibility-review-skill'],
  'inclusive design': ['accessibility-design-skill'],
  a11y: ['accessibility-design-skill'],
  wcag: ['accessibility-design-skill'],
  canvas: ['canvas-design-skill'],
  canva: ['canva-creator-skill', 'canva-creator'],
  'social media': ['canva-creator-skill'],
  'ui design': ['design-ui-designer', 'design-system-skill'],
  mockup: ['design-ui-designer'],
  'design system': ['design-system-skill'],
  'ux research': ['design-ux-researcher'],
  usability: ['design-ux-researcher'],
  persona: ['design-ux-researcher'],
  'data viz': ['data-visualization-skill'],
  chart: ['data-visualization-skill'],
  graph: ['data-visualization-skill', 'visual-content-skill'],
  visualization: ['data-visualization-skill'],
  'visual content': ['visual-content-skill'],
  diagram: ['visual-content-skill', 'mermaid-renderer'],
  mermaid: ['mermaid-renderer'],
  presentation: ['presentaciones-visuales-skill'],
  slide: ['presentaciones-visuales-skill'],
  svg: ['svg-generator'],
  banner: ['svg-generator'],
  logo: ['svg-generator'],
  // Image Generation skill
  'generate image': ['image-generation-skill'],
  'image gen': ['image-generation-skill'],
  'image generation': ['image-generation-skill'],
  'ai image': ['image-generation-skill'],
  'ai art': ['image-generation-skill'],
  'dall-e': ['image-generation-skill'],
  'dalle': ['image-generation-skill'],
  'stable diffusion': ['image-generation-skill'],
  'flux': ['image-generation-skill'],
  'visual asset': ['image-generation-skill', 'svg-generator'],
  illustration: ['image-generation-skill'],
  // Diagram renderer skill
  graphviz: ['diagram-renderer-skill'],
  dot: ['diagram-renderer-skill'],
  plantuml: ['diagram-renderer-skill'],
  puml: ['diagram-renderer-skill'],
  'sequence diagram': ['diagram-renderer-skill'],
  'class diagram': ['diagram-renderer-skill'],
  'activity diagram': ['diagram-renderer-skill'],
  'state machine': ['diagram-renderer-skill', 'mermaid-renderer'],
  'network topology': ['diagram-renderer-skill'],
  'architecture diagram': ['diagram-renderer-skill', 'visual-content-skill'],
  'dependency graph': ['diagram-renderer-skill'],
  // Post-mortem / Incident
  'post-mortem': ['post-mortem-trigger'],
  'postmortem': ['post-mortem-trigger'],
  incident: ['post-mortem-trigger'],
  'auto-heal': ['post-mortem-trigger'],
  'break glass': ['post-mortem-trigger', 'self-diagnosis'],
  // Design tokens
  'design token': ['design-token-pipeline'],
  'brand token': ['design-token-pipeline'],
  'css tokens': ['design-token-pipeline'],
  'design system token': ['design-token-pipeline', 'design-system-skill'],
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

  // Exact matches (highest confidence)
  for (const [keyword, skills] of Object.entries(SKILL_KEYWORDS)) {
    if (queryLower.includes(keyword)) {
      for (const s of skills) matchedSet.add(s);
    }
  }

  // Fuzzy fallback: partial keyword matches when no exact matches found
  if (matchedSet.size === 0) {
    for (const [keyword, skills] of Object.entries(SKILL_KEYWORDS)) {
      // Check if query contains keyword OR keyword contains query (partial match)
      if (keyword.includes(queryLower) || queryLower.includes(keyword)) {
        for (const s of skills) matchedSet.add(s);
      }
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
