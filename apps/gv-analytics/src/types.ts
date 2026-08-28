export interface ConnectionStatus {
  configured: boolean;
  jira: ServiceStatus;
  confluence: ServiceStatus;
  bitbucket: ServiceStatus;
  siteUrl?: string;
  email?: string;
  bitbucketWorkspace?: string;
  updatedAt?: string;
}

export interface ServiceStatus {
  ok: boolean;
  message: string;
}

export interface ConnectionForm {
  siteUrl: string;
  email: string;
  apiToken: string;
  bitbucketWorkspace: string;
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
    level: 'low' | 'medium' | 'high' | 'unknown';
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
}
