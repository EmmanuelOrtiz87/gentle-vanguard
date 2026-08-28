import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import {
  analyzeInput,
  fetchBitbucketPullRequest,
  fetchConfluencePage,
  fetchJiraIssue,
  getConnectionStatus,
  searchEvidence,
} from './atlassian';

const server = new McpServer({
  name: 'gentle-vanguard-analytics-atlassian',
  version: '0.2.0',
  description: 'Read-only Atlassian analysis tools for Gentle-Vanguard Analytics.',
});

server.tool(
  'gv_analytics_connection_status',
  'Return current Jira, Confluence and Bitbucket connection status without exposing secrets.',
  {},
  async () => ({
    content: [{ type: 'text', text: JSON.stringify(await getConnectionStatus(), null, 2) }],
  }),
);

server.tool(
  'gv_analytics_analyze',
  'Analyze an Atlassian URL or requirement text and return a structured delivery report (fronts, roles, complexity, estimates, QA scenarios, diagrams).',
  {
    mode: z.enum(['url', 'request']).describe('Analyze a URL or free-form request text.'),
    input: z.string().min(4).describe('Jira, Confluence, Bitbucket URL or request text.'),
  },
  async ({ mode, input }) => ({
    content: [{ type: 'text', text: JSON.stringify(await analyzeInput(mode, input), null, 2) }],
  }),
);

server.tool(
  'gv_atlassian_jira_issue',
  'Read a Jira issue (key or URL) with description, status, assignee, labels and comments as plain text.',
  { keyOrUrl: z.string().min(3).describe('Issue key like PROJ-123 or full Jira URL.') },
  async ({ keyOrUrl }) => ({
    content: [{ type: 'text', text: await fetchJiraIssue(keyOrUrl) }],
  }),
);

server.tool(
  'gv_atlassian_confluence_page',
  'Read a Confluence page (pageId or URL) body as plain text.',
  { pageIdOrUrl: z.string().min(3).describe('Numeric pageId or full Confluence URL.') },
  async ({ pageIdOrUrl }) => ({
    content: [{ type: 'text', text: await fetchConfluencePage(pageIdOrUrl) }],
  }),
);

server.tool(
  'gv_atlassian_bitbucket_pr',
  'Read a Bitbucket pull request with description and diff as plain text.',
  {
    workspace: z.string().min(1).describe('Bitbucket workspace slug.'),
    repo: z.string().min(1).describe('Repository slug.'),
    prId: z.string().min(1).describe('Pull request id.'),
  },
  async ({ workspace, repo, prId }) => ({
    content: [{ type: 'text', text: await fetchBitbucketPullRequest(workspace, repo, prId) }],
  }),
);

server.tool(
  'gv_atlassian_search',
  'Search Jira issues and Confluence pages matching a text query, returning linked evidence.',
  { query: z.string().min(2).describe('Free text to search across Jira and Confluence.') },
  async ({ query }) => ({
    content: [{ type: 'text', text: JSON.stringify(await searchEvidence(query), null, 2) }],
  }),
);

const transport = new StdioServerTransport();
await server.connect(transport);
