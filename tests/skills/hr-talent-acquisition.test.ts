#!/usr/bin/env node
/**
 * Test suite for hr-talent-acquisition skill
 * Verifies SKILL.md exists and has required sections
 */

import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

const skillPath = join('skills/hr-talent-acquisition/SKILL.md');

test('hr-talent-acquisition - SKILL.md exists', () => {
  assert(existsSync(skillPath), 'SKILL.md must exist');
});

test('hr-talent-acquisition - has required sections', () => {
  const content = readFileSync(skillPath, 'utf-8');

  const requiredSections = [
    '# hr-talent-acquisition',
    '## Description',
    '## When to Use',
    '## Workflow',
    '## Output Format',
    '## Examples',
    '## References',
  ];

  for (const section of requiredSections) {
    assert(content.includes(section), `Missing section: ${section}`);
  }
});

test('hr-talent-acquisition - has recruiting-specific content', () => {
  const content = readFileSync(skillPath, 'utf-8');

  // Should include recruiting terminology
  const terms = ['candidate', 'interview', 'recruiting', 'hiring', 'job description'];
  const hasTerms = terms.some((t) => content.toLowerCase().includes(t));
  assert(hasTerms, 'Should include recruiting terminology');
});

test('hr-talent-acquisition - has interview rubric', () => {
  const content = readFileSync(skillPath, 'utf-8');

  assert(
    content.includes('### Interview Rubric') || content.includes('### Job Description'),
    'Must include HR-specific examples',
  );
});

console.log('\nTest suite: hr-talent-acquisition');
console.log('='.repeat(50));
