/**
 * Get token budget for current tool context
 */
export function getTokenBudget(toolName: string): number {
  const budgets: Record<string, number> = {
    'cline': 100000,
    'copilot': 15000,
    'continue': 50000,
    'cursor': 100000,
    'opencode': 128000,
    'windsurf': 50000,
    'codex': 15000,
    'antigravity': 30000,
    'default': 50000,
  };

  return budgets[toolName.toLowerCase()] || budgets['default'];
}

/**
 * Apply context efficiency settings before tool execution
 */
export function addContextEfficiency(env: Record<string, string>, toolName: string): Record<string, string> {
  const budget = getTokenBudget(toolName);
  return {
    ...env,
    'FOUNDATION_TOKEN_BUDGET': budget.toString(),
    'FOUNDATION_EFFICIENCY_MODE': budget > 80000 ? 'balanced' : 'compact',
    'FOUNDATION_CONTEXT_LEVEL': 'workspace',
  };
}

/**
 * Log tool usage for telemetry
 */
export function logToolUsage(toolName: string, toolAction: string, tokensUsed: number): void {
  try {
    const fs = require('fs');
    const path = require('path');
    const logEntry = {
      timestamp: new Date().toISOString(),
      tool: toolName,
      action: toolAction,
      tokensUsed,
    };
    
    const logPath = path.join(process.cwd(), 'logs', 'mcp-bridge-usage.log');
    fs.appendFileSync(logPath, JSON.stringify(logEntry) + '\n');
  } catch {
    // Silently fail - logging shouldn't break functionality
  }
}
