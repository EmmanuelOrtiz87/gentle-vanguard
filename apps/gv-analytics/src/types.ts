export interface ConnectionStatus {
  configured: boolean;
  jira: ServiceStatus;
  confluence: ServiceStatus;
  bitbucket: ServiceStatus;
  siteUrl?: string;
  email?: string;
  bitbucketWorkspace?: string;
  updatedAt?: string;
  /** Whether the Jira/Confluence API token is stored (masked, never the raw value). */
  apiTokenSet?: boolean;
  /** Masked hint of the Jira/Confluence token (e.g. "••••1234"), for edit prefill. */
  apiTokenMasked?: string;
  /** Whether the Bitbucket API token is stored (masked, never the raw value). */
  bitbucketApiTokenSet?: boolean;
  /** Masked hint of the Bitbucket token (e.g. "••••1234"), for edit prefill. */
  bitbucketApiTokenMasked?: string;
}

export interface ServiceStatus {
  ok: boolean;
  message: string;
}

export interface ConnectionForm {
  siteUrl: string;
  email: string;
  /** API token for Jira + Confluence (they share the same Atlassian token). */
  apiToken: string;
  /** Separate API token for Bitbucket (different credential than Jira/Confluence). */
  bitbucketApiToken: string;
  bitbucketWorkspace: string;
}

export interface OAuthStatus {
  configured: boolean;
  redirectUri: string;
  scopes: string[];
  callback: { port: number; path: string; redirectUri: string };
  connected: boolean;
  expiresAt: number | null;
}

export interface AnalysisEvidence {
  source: 'jira' | 'confluence' | 'bitbucket' | 'input' | 'stack';
  title: string;
  url?: string;
  detail: string;
}

export interface AnalyticsReport {
  id: string;
  createdAt: string;
  mode: 'url' | 'request';
  input: string;
  summary: string;
  currentState: string[];
  proposedSolution: string[];
  impactedFronts: string[];
  roles: string[];
  complexity: {
    level: 'low' | 'medium' | 'high' | 'critical' | 'unknown';
    rationale: string;
  };
  estimate: {
    discoveryHours: number;
    deliveryHours: number;
    qaHours: number;
    confidence: 'low' | 'medium' | 'high';
  };
  qaScenarios: string[];
  diagrams: {
    current: string;
    proposed: string;
  };
  evidence: AnalysisEvidence[];
  nextActions: string[];
  /** LLM enrichment provenance. 'heuristic' means the rule-based fallback ran. */
  llmSource?: 'cache' | 'agent' | 'fallback' | 'heuristic';
  llmDurationMs?: number;
  llmCached?: boolean;
  llmNotes?: string;
}
