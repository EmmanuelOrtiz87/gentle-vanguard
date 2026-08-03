const fs = require('fs');

// Auto Code Review
const autoCodeReview = `#!/usr/bin/env node

/**
 * Auto Code Review v1.0.0
 * Autonomous code review with multi-lens analysis
 * Part of Gentle-Vanguard v6.0
 */

import { EventEmitter } from 'events';

interface CodeReview {
  id: string;
  filePath: string;
  content: string;
  language: string;
  timestamp: number;
  lenses: LensResult[];
  overallScore: number;
  status: 'pending' | 'completed' | 'failed';
}

interface LensResult {
  lens: string;
  score: number;
  issues: Issue[];
  suggestions: string[];
}

interface Issue {
  line: number;
  severity: 'info' | 'warning' | 'error' | 'critical';
  message: string;
  rule: string;
  fix?: string;
}

export class AutoCodeReview extends EventEmitter {
  private reviews: Map<string, CodeReview> = new Map();
  private lenses: string[] = ['security', 'performance', 'maintainability', 'style'];

  public async review(filePath: string, content: string, language: string): Promise<CodeReview> {
    const reviewId = \`review_\${Date.now()}_\${Math.random().toString(36).substr(2, 9)}\`;
    
    const review: CodeReview = {
      id: reviewId,
      filePath,
      content,
      language,
      timestamp: Date.now(),
      lenses: [],
      overallScore: 0,
      status: 'pending',
    };

    this.emit('reviewStarted', review);

    // Run all lenses
    for (const lens of this.lenses) {
      const result = await this.runLens(lens, content, language);
      review.lenses.push(result);
    }

    // Calculate overall score
    review.overallScore = review.lenses.reduce((a, l) => a + l.score, 0) / review.lenses.length;
    review.status = review.overallScore >= 0.8 ? 'completed' : 'failed';

    this.reviews.set(reviewId, review);
    this.emit('reviewCompleted', review);

    return review;
  }

  private async runLens(lens: string, content: string, language: string): Promise<LensResult> {
    const issues: Issue[] = [];
    const suggestions: string[] = [];
    let score = 1.0;

    // Security lens
    if (lens === 'security') {
      if (content.includes('eval(') || content.includes('Function(')) {
        issues.push({ line: 1, severity: 'critical', message: 'Dynamic code execution detected', rule: 'no-eval' });
        score -= 0.3;
      }
      if (content.includes('password') && !content.includes('hash')) {
        issues.push({ line: 1, severity: 'error', message: 'Plain text password detected', rule: 'no-plain-password' });
        score -= 0.2;
      }
      suggestions.push('Use parameterized queries to prevent SQL injection');
    }

    // Performance lens
    if (lens === 'performance') {
      const nestedLoops = (content.match(/for.*for/g) || []).length;
      if (nestedLoops > 2) {
        issues.push({ line: 1, severity: 'warning', message: 'Nested loops may cause performance issues', rule: 'avoid-nested-loops' });
        score -= 0.1;
      }
      suggestions.push('Consider memoization for expensive calculations');
    }

    // Maintainability lens
    if (lens === 'maintainability') {
      const lines = content.split('\\n');
      if (lines.length > 200) {
        issues.push({ line: lines.length, severity: 'warning', message: 'File too long, consider splitting', rule: 'max-lines' });
        score -= 0.1;
      }
      suggestions.push('Add JSDoc comments for public APIs');
    }

    // Style lens
    if (lens === 'style') {
      if (content.includes('var ')) {
        issues.push({ line: 1, severity: 'info', message: 'Use const or let instead of var', rule: 'no-var' });
        score -= 0.05;
      }
      suggestions.push('Follow consistent naming conventions');
    }

    return { lens, score: Math.max(0, score), issues, suggestions };
  }

  public getStats(): object {
    const reviews = Array.from(this.reviews.values());
    return {
      totalReviews: reviews.length,
      passed: reviews.filter(r => r.status === 'completed').length,
      failed: reviews.filter(r => r.status === 'failed').length,
      avgScore: reviews.length > 0 ? reviews.reduce((a, r) => a + r.overallScore, 0) / reviews.length : 0,
    };
  }
}

export const autoCodeReview = new AutoCodeReview();
`;

// Receipt Manager
const receiptManager = `#!/usr/bin/env node

/**
 * Receipt Manager v1.0.0
 * Structured review receipts with decision tracking
 * Part of Gentle-Vanguard v6.0
 */

import { EventEmitter } from 'events';

interface Receipt {
  id: string;
  reviewId: string;
  timestamp: number;
  decisions: Decision[];
  summary: string;
  approved: boolean;
  signatures: Signature[];
}

interface Decision {
  id: string;
  type: 'approve' | 'reject' | 'request-changes' | 'comment';
  author: string;
  timestamp: number;
  comment: string;
  lineRange?: { start: number; end: number };
}

interface Signature {
  author: string;
  timestamp: number;
  hash: string;
}

export class ReceiptManager extends EventEmitter {
  private receipts: Map<string, Receipt> = new Map();

  public createReceipt(reviewId: string): string {
    const receiptId = \`receipt_\${Date.now()}_\${Math.random().toString(36).substr(2, 9)}\`;
    
    const receipt: Receipt = {
      id: receiptId,
      reviewId,
      timestamp: Date.now(),
      decisions: [],
      summary: '',
      approved: false,
      signatures: [],
    };

    this.receipts.set(receiptId, receipt);
    this.emit('receiptCreated', receipt);
    return receiptId;
  }

  public addDecision(receiptId: string, decision: Omit<Decision, 'id' | 'timestamp'>): void {
    const receipt = this.receipts.get(receiptId);
    if (!receipt) return;

    const fullDecision: Decision = {
      ...decision,
      id: \`decision_\${Date.now()}\`,
      timestamp: Date.now(),
    };

    receipt.decisions.push(fullDecision);
    
    // Update approval status
    const approvals = receipt.decisions.filter(d => d.type === 'approve').length;
    const rejects = receipt.decisions.filter(d => d.type === 'reject').length;
    receipt.approved = approvals > 0 && rejects === 0;

    this.emit('decisionAdded', { receiptId, decision: fullDecision });
  }

  public signReceipt(receiptId: string, author: string): void {
    const receipt = this.receipts.get(receiptId);
    if (!receipt) return;

    const signature: Signature = {
      author,
      timestamp: Date.now(),
      hash: this.generateHash(receipt),
    };

    receipt.signatures.push(signature);
    this.emit('receiptSigned', { receiptId, signature });
  }

  private generateHash(receipt: Receipt): string {
    return require('crypto').createHash('sha256')
      .update(JSON.stringify(receipt.decisions))
      .digest('hex')
      .substring(0, 16);
  }

  public getReceipt(receiptId: string): Receipt | null {
    return this.receipts.get(receiptId) || null;
  }

  public getStats(): object {
    const receipts = Array.from(this.receipts.values());
    return {
      totalReceipts: receipts.length,
      approved: receipts.filter(r => r.approved).length,
      pending: receipts.filter(r => !r.approved).length,
      totalDecisions: receipts.reduce((a, r) => a + r.decisions.length, 0),
    };
  }
}

export const receiptManager = new ReceiptManager();
`;

// Staged Review
const stagedReview = `#!/usr/bin/env node

/**
 * Staged Review v1.0.0
 * Staged index review with incremental validation
 * Part of Gentle-Vanguard v6.0
 */

import { EventEmitter } from 'events';

interface StagedChange {
  id: string;
  filePath: string;
  changeType: 'added' | 'modified' | 'deleted';
  diff: string;
  stage: number;
  validated: boolean;
  validationResult?: ValidationResult;
}

interface ValidationResult {
  passed: boolean;
  checks: CheckResult[];
  timestamp: number;
}

interface CheckResult {
  name: string;
  passed: boolean;
  message: string;
}

interface ReviewStage {
  id: number;
  name: string;
  validators: string[];
  required: boolean;
}

export class StagedReview extends EventEmitter {
  private stages: ReviewStage[] = [
    { id: 1, name: 'Syntax Check', validators: ['eslint', 'prettier'], required: true },
    { id: 2, name: 'Unit Tests', validators: ['jest', 'mocha'], required: true },
    { id: 3, name: 'Integration Tests', validators: ['integration'], required: false },
    { id: 4, name: 'Security Scan', validators: ['security'], required: true },
  ];
  
  private changes: Map<string, StagedChange> = new Map();
  private currentStage: number = 1;

  public stageChange(filePath: string, changeType: StagedChange['changeType'], diff: string): string {
    const changeId = \`change_\${Date.now()}_\${Math.random().toString(36).substr(2, 9)}\`;
    
    const change: StagedChange = {
      id: changeId,
      filePath,
      changeType,
      diff,
      stage: 1,
      validated: false,
    };

    this.changes.set(changeId, change);
    this.emit('changeStaged', change);
    return changeId;
  }

  public async validateStage(changeId: string): Promise<boolean> {
    const change = this.changes.get(changeId);
    if (!change) return false;

    const stage = this.stages.find(s => s.id === change.stage);
    if (!stage) return false;

    this.emit('validationStarted', { changeId, stage: stage.name });

    // Run validators
    const checks: CheckResult[] = [];
    let allPassed = true;

    for (const validator of stage.validators) {
      const passed = await this.runValidator(validator, change);
      checks.push({
        name: validator,
        passed,
        message: passed ? 'Passed' : 'Failed',
      });
      if (!passed) allPassed = false;
    }

    change.validationResult = {
      passed: allPassed,
      checks,
      timestamp: Date.now(),
    };
    change.validated = allPassed;

    if (allPassed && change.stage < this.stages.length) {
      change.stage++;
      this.emit('stageAdvanced', { changeId, newStage: change.stage });
    }

    this.emit('validationCompleted', { changeId, result: change.validationResult });
    return allPassed;
  }

  private async runValidator(validator: string, change: StagedChange): Promise<boolean> {
    // Simulate validation
    await new Promise(resolve => setTimeout(resolve, 100));
    return Math.random() > 0.1; // 90% pass rate
  }

  public promoteToNextStage(changeId: string): boolean {
    const change = this.changes.get(changeId);
    if (!change || !change.validated) return false;
    
    if (change.stage < this.stages.length) {
      change.stage++;
      change.validated = false;
      change.validationResult = undefined;
      this.emit('stageAdvanced', { changeId, newStage: change.stage });
      return true;
    }
    return false;
  }

  public getStats(): object {
    const changes = Array.from(this.changes.values());
    return {
      totalChanges: changes.length,
      byStage: this.stages.map(s => ({
        stage: s.name,
        count: changes.filter(c => c.stage === s.id).length,
      })),
      fullyValidated: changes.filter(c => c.stage === this.stages.length && c.validated).length,
    };
  }
}

export const stagedReview = new StagedReview();
`;

// Write all files
fs.writeFileSync('src/v6.0-AutonomousReview/auto-code-review.ts', autoCodeReview);
fs.writeFileSync('src/v6.0-AutonomousReview/receipt-manager.ts', receiptManager);
fs.writeFileSync('src/v6.0-AutonomousReview/staged-review.ts', stagedReview);

console.log('v6.0 Autonomous Review components created:');
console.log('  - auto-code-review.ts');
console.log('  - receipt-manager.ts');
console.log('  - staged-review.ts');
