#!/usr/bin/env node
/**
 * Test suite for marketing-content-writer skill
 * Verifies SKILL.md exists and has required sections
 */

import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

const skillPath = join('skills/marketing-content-writer/SKILL.md');

/**
 * SDD Step: Verify Skill File Structure
 * Type: Test
 * Purpose: Ensure marketing-content-writer skill follows SKILL.md schema
 */
test('marketing-content-writer - SKILL.md exists', () => {
  assert(
    existsSync(skillPath),
    'SKILL.md must exist at .opencode/skills/marketing-content-writer/SKILL.md',
  );
});

/**
 * SDD Step: Verify Required Sections
 * Type: Test
 * Purpose: Ensure SKILL.md has all required sections per SKILL.md schema
 */
test('marketing-content-writer - has required sections', () => {
  const content = readFileSync(skillPath, 'utf-8');

  // Required sections per SKILL.md schema
  const requiredSections = [
    '# marketing-content-writer',
    '## Description',
    '## When to Use',
    '## Workflow',
    '## Output Format',
    '## Examples',
    '## References',
  ];

  for (const section of requiredSections) {
    assert(content.includes(section), `SKILL.md must include section: ${section}`);
  }
});

/**
 * SDD Step: Verify Workflow Steps
 * Type: Test
 * Purpose: Ensure workflow has numbered steps
 */
test('marketing-content-writer - workflow steps are numbered', () => {
  const content = readFileSync(skillPath, 'utf-8');
  const workflowMatch = content.match(/## Workflow[\s\S]*?(?=## |$)/);

  assert(workflowMatch, 'Workflow section must exist');
  const workflow = workflowMatch[0];

  // Should have numbered steps (1., 2., etc.)
  const numberedSteps = workflow.match(/\d+\./g);
  assert(
    numberedSteps && numberedSteps.length >= 3,
    'Workflow must have at least 3 numbered steps',
  );
});

/**
 * SDD Step: Verify Examples Section
 * Type: Test
 * Purpose: Ensure skill has concrete examples
 */
test('marketing-content-writer - has concrete examples', () => {
  const content = readFileSync(skillPath, 'utf-8');

  // Should have at least 2 examples (Landing Page and Email Campaign)
  assert(content.includes('### Landing Page'), 'Must include Landing Page example');
  assert(content.includes('### Email Campaign'), 'Must include Email Campaign example');

  // Examples should have input/output
  assert(content.includes('**Input**:'), 'Examples must have Input markup');
  assert(content.includes('**Output**:'), 'Examples must have Output markup');
});

/**
 * SDD Step: Verify Skill Quality
 * Type: Test
 * Purpose: Ensure skill content meets minimum standards
 */
test('marketing-content-writer - minimum content standards', () => {
  const content = readFileSync(skillPath, 'utf-8');
  const lines = content.split('\n');

  // Minimum 50 lines
  assert(lines.length >= 50, 'SKILL.md must have at least 50 lines');

  // Maximum 500 lines (oversized check)
  assert(lines.length <= 500, 'SKILL.md should not exceed 500 lines');

  // Should have code blocks
  assert(content.includes('```'), 'Should include at least one code block');
});

/**
 * SDD Step: Verify References Section
 * Type: Test
 * Purpose: Ensure references are relative paths
 */
test('marketing-content-writer - references use relative paths', () => {
  const content = readFileSync(skillPath, 'utf-8');
  const referencesMatch = content.match(/## References[\s\S]*?(?=## |$)/);

  if (referencesMatch) {
    const references = referencesMatch[0];
    // Avoid absolute paths in references
    const hasAbsolutePaths = /[A-Z]:\\|\\/.test(references);
    assert(!hasAbsolutePaths, 'References should not use absolute paths');
  }
});

console.log('\nTest suite: marketing-content-writer');
console.log('='.repeat(50));
