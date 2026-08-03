#!/usr/bin/env node
/**
 * Test suite for legal-compliance-officer skill
 * Verifies SKILL.md exists and has required sections
 */

import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';

const skillPath = join('.opencode/skills/legal-compliance-officer/SKILL.md');

test('legal-compliance-officer - SKILL.md exists', () => {
  assert(existsSync(skillPath), 'SKILL.md must exist');
});

test('legal-compliance-officer - has required sections', () => {
  const content = readFileSync(skillPath, 'utf-8');
  
  const requiredSections = [
    '# legal-compliance-officer',
    '## Description',
    '## When to Use',
    '## Workflow',
    '## Output Format',
    '## Examples',
    '## References'
  ];
  
  for (const section of requiredSections) {
    assert(content.includes(section), `Missing section: ${section}`);
  }
});

test('legal-compliance-officer - has legal terminology', () => {
  const content = readFileSync(skillPath, 'utf-8');
  
  // Should include legal/compliance terminology
  const terms = ['compliance', 'contract', 'license', 'GDPR', 'policy', 'privacy'];
  const hasTerms = terms.some(t => content.toLowerCase().includes(t.toLowerCase()));
  assert(hasTerms, 'Should include legal/compliance terminology');
});

test('legal-compliance-officer - has disclaimer', () => {
  const content = readFileSync(skillPath, 'utf-8');
  
  // Legal skill should have a disclaimer
  assert(content.includes('## Disclaimers') || content.includes('Disclaimer'), 
    'Must include legal disclaimer');
  assert(content.toLowerCase().includes('legal advice') || content.toLowerCase().includes('counsel'), 
    'Disclaimer should mention this is not legal advice');
});

test('legal-compliance-officer - has contract examples', () => {
  const content = readFileSync(skillPath, 'utf-8');
  
  assert(content.includes('### Vendor Contract Review') || content.includes('### Privacy Policy'), 
    'Must include legal document examples');
});

console.log('\nTest suite: legal-compliance-officer');
console.log('='.repeat(50));
