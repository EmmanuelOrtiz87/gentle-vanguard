#!/usr/bin/env node
/**
 * Test suite for finance-financial-analyst skill
 * Verifies SKILL.md exists and has required sections
 */

import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

const skillPath = join('.opencode/skills/finance-financial-analyst/SKILL.md');

test('finance-financial-analyst - SKILL.md exists', () => {
  assert(existsSync(skillPath), 'SKILL.md must exist');
});

test('finance-financial-analyst - has required sections', () => {
  const content = readFileSync(skillPath, 'utf-8');

  const requiredSections = [
    '# finance-financial-analyst',
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

test('finance-financial-analyst - has financial metrics', () => {
  const content = readFileSync(skillPath, 'utf-8');

  // Should include financial metrics
  const metrics = ['LTV', 'CAC', 'ROI', 'margin', 'revenue'];
  const hasMetrics = metrics.some((m) => content.includes(m));
  assert(hasMetrics, 'Should include financial metrics (LTV, CAC, ROI, etc.)');
});

test('finance-financial-analyst - has calculation examples', () => {
  const content = readFileSync(skillPath, 'utf-8');

  assert(
    content.includes('### Unit Economics Model') || content.includes('### Pricing Scenario'),
    'Must include financial modeling examples',
  );
  assert(content.includes('=') || content.includes('$'), 'Examples should include calculations');
});

console.log('\nTest suite: finance-financial-analyst');
console.log('='.repeat(50));
