#!/usr/bin/env node
/**
 * Test suite for sales-account-executive skill
 * Verifies SKILL.md exists and has required sections
 */

import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

const skillPath = join('skills/sales-account-executive/SKILL.md');

test('sales-account-executive - SKILL.md exists', () => {
  assert(existsSync(skillPath), 'SKILL.md must exist');
});

test('sales-account-executive - has required sections', () => {
  const content = readFileSync(skillPath, 'utf-8');

  const requiredSections = [
    '# sales-account-executive',
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

test('sales-account-executive - workflow steps are numbered', () => {
  const content = readFileSync(skillPath, 'utf-8');
  const workflowMatch = content.match(/## Workflow[\s\S]*?(?=## |$)/);

  assert(workflowMatch, 'Workflow section must exist');
  const workflow = workflowMatch[0];
  const numberedSteps = workflow.match(/\d+\./g);
  assert(numberedSteps && numberedSteps.length >= 3, 'Must have at least 3 numbered steps');
});

test('sales-account-executive - has BANT framework', () => {
  const content = readFileSync(skillPath, 'utf-8');

  // Sales skill should reference BANT framework
  assert(
    content.includes('BANT') || content.includes('Budget') || content.includes('Authority'),
    'Should reference sales qualification framework',
  );
});

test('sales-account-executive - has concrete examples', () => {
  const content = readFileSync(skillPath, 'utf-8');

  assert(
    content.includes('### Discovery Questions') || content.includes('### Proposal Structure'),
    'Must include sales-specific examples',
  );
  assert(content.includes('**Input**:'), 'Examples must have Input markup');
});

console.log('\nTest suite: sales-account-executive');
console.log('='.repeat(50));
