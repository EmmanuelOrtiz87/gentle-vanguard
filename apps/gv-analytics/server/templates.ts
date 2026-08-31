/**
 * Gentle-Vanguard Analytics — Report templates.
 *
 * Templates shape the EXPORT output, not the underlying report data. Each
 * template declares which sections appear and how they are ordered. The full
 * AnalyticsReport is always available; templates only change presentation.
 *
 * Three templates ship today:
 *   - brief:     1-page executive summary (no diagrams, no evidence)
 *   - sdd:       full SDD lifecycle (everything, in the canonical order)
 *   - handoff:   developer-focused (heavy on evidence, no roles, compact)
 *
 * Add a new template: extend `ReportTemplate` with a new id, declare its
 * sections, then add a renderer in export.ts (Markdown / HTML / DOCX / PDF).
 */

import type { AnalyticsReport } from '../src/types';

export type TemplateId = 'brief' | 'sdd' | 'handoff';

export interface TemplateSection {
  /** Stable id used by the renderers. */
  id:
    | 'header'
    | 'metrics'
    | 'currentState'
    | 'proposedSolution'
    | 'impactedFronts'
    | 'roles'
    | 'qaScenarios'
    | 'nextActions'
    | 'diagrams'
    | 'evidence';
  /** Optional heading override (defaults to the id in Spanish). */
  title?: string;
  /** Hide this section if false. */
  visible: boolean;
}

export interface ReportTemplate {
  id: TemplateId;
  label: string;
  description: string;
  sections: TemplateSection[];
}

export const TEMPLATES: Record<TemplateId, ReportTemplate> = {
  brief: {
    id: 'brief',
    label: 'Executive brief',
    description: '1 pagina, foco en impacto y estimacion. Sin diagramas ni evidencia detallada.',
    sections: [
      { id: 'header', visible: true, title: 'Resumen' },
      { id: 'metrics', visible: true, title: 'Metricas' },
      { id: 'currentState', visible: true, title: 'Estado actual' },
      { id: 'proposedSolution', visible: true, title: 'Solucion propuesta' },
      { id: 'impactedFronts', visible: true, title: 'Frentes' },
      { id: 'roles', visible: false },
      { id: 'qaScenarios', visible: false },
      { id: 'nextActions', visible: true, title: 'Proximas acciones' },
      { id: 'diagrams', visible: false },
      { id: 'evidence', visible: false },
    ],
  },
  sdd: {
    id: 'sdd',
    label: 'SDD completo',
    description:
      'Documento SDD canonico: estado actual, propuesta, frentes, roles, QA, diagramas, evidencia.',
    sections: [
      { id: 'header', visible: true },
      { id: 'metrics', visible: true },
      { id: 'currentState', visible: true, title: 'Estado actual' },
      { id: 'proposedSolution', visible: true, title: 'Solucion propuesta' },
      { id: 'impactedFronts', visible: true, title: 'Frentes involucrados' },
      { id: 'roles', visible: true, title: 'Roles' },
      { id: 'qaScenarios', visible: true, title: 'Escenarios QA' },
      { id: 'nextActions', visible: true, title: 'Proximas acciones' },
      { id: 'diagrams', visible: true, title: 'Diagramas' },
      { id: 'evidence', visible: true, title: 'Evidencia' },
    ],
  },
  handoff: {
    id: 'handoff',
    label: 'Dev handoff',
    description:
      'Para developers: estimacion + escenarios QA + evidencia enlazada. Sin roles ni diagramas.',
    sections: [
      { id: 'header', visible: true },
      { id: 'metrics', visible: true, title: 'Estimacion' },
      { id: 'currentState', visible: true, title: 'Contexto actual' },
      { id: 'proposedSolution', visible: true, title: 'Implementacion propuesta' },
      { id: 'impactedFronts', visible: true, title: 'Frentes a tocar' },
      { id: 'roles', visible: false },
      { id: 'qaScenarios', visible: true, title: 'Escenarios QA a automatizar' },
      { id: 'nextActions', visible: true, title: 'Pasos inmediatos' },
      { id: 'diagrams', visible: false },
      { id: 'evidence', visible: true, title: 'Tickets / PRs / Docs' },
    ],
  },
};

export function listTemplates(): ReportTemplate[] {
  return Object.values(TEMPLATES);
}

export function getTemplate(id: string | undefined | null): ReportTemplate {
  if (id === 'brief' || id === 'sdd' || id === 'handoff') {
    return TEMPLATES[id];
  }
  return TEMPLATES.sdd;
}

export interface RenderedTemplate {
  template: ReportTemplate;
  markdown: string;
}

export function renderTemplateMarkdown(
  report: AnalyticsReport,
  templateId?: string | null,
): string {
  const template = getTemplate(templateId);
  const out: string[] = [];
  for (const section of template.sections) {
    if (!section.visible) continue;
    const title = section.title ?? defaultTitle(section.id);
    switch (section.id) {
      case 'header':
        out.push(`# ${report.summary}`);
        out.push('');
        out.push(
          `Reporte: ${report.id} · ${new Date(report.createdAt).toISOString()} · modo ${report.mode} · template ${template.id}`,
        );
        out.push('');
        out.push(`**Entrada**: ${report.input}`);
        if (report.llmSource) {
          const cached = report.llmCached ? ' (cache)' : '';
          out.push(
            `**Origen**: ${report.llmSource}${cached} · ${(report.llmDurationMs ?? 0) / 1000}s`,
          );
        }
        out.push('');
        break;
      case 'metrics':
        out.push(`## ${title}`);
        out.push('');
        out.push(`- **Complejidad**: ${report.complexity.level} — ${report.complexity.rationale}`);
        out.push(
          `- **Estimacion**: discovery ${report.estimate.discoveryHours}h · delivery ${report.estimate.deliveryHours}h · QA ${report.estimate.qaHours}h · confianza ${report.estimate.confidence}`,
        );
        out.push('');
        break;
      case 'currentState':
        out.push(`## ${title}`);
        out.push('');
        for (const item of report.currentState) out.push(`- ${item}`);
        out.push('');
        break;
      case 'proposedSolution':
        out.push(`## ${title}`);
        out.push('');
        for (const item of report.proposedSolution) out.push(`- ${item}`);
        out.push('');
        break;
      case 'impactedFronts':
        out.push(`## ${title}`);
        out.push('');
        for (const front of report.impactedFronts) out.push(`- **${front}**`);
        out.push('');
        break;
      case 'roles':
        if (report.roles.length === 0) break;
        out.push(`## ${title}`);
        out.push('');
        for (const role of report.roles) out.push(`- ${role}`);
        out.push('');
        break;
      case 'qaScenarios':
        if (report.qaScenarios.length === 0) break;
        out.push(`## ${title}`);
        out.push('');
        for (const scenario of report.qaScenarios) out.push(`- ${scenario}`);
        out.push('');
        break;
      case 'nextActions':
        out.push(`## ${title}`);
        out.push('');
        for (const action of report.nextActions) out.push(`- ${action}`);
        out.push('');
        break;
      case 'diagrams':
        if (!report.diagrams.current && !report.diagrams.proposed) break;
        out.push(`## ${title}`);
        out.push('');
        out.push('**Actual**');
        out.push('');
        out.push('```text');
        out.push(report.diagrams.current);
        out.push('```');
        out.push('');
        out.push('**Propuesto**');
        out.push('');
        out.push('```text');
        out.push(report.diagrams.proposed);
        out.push('```');
        out.push('');
        break;
      case 'evidence':
        if (report.evidence.length === 0) break;
        out.push(`## ${title}`);
        out.push('');
        for (const item of report.evidence) {
          out.push(
            `- **${item.source}** — ${item.title}${item.url ? ` ([link](${item.url}))` : ''}`,
          );
          out.push(`  ${item.detail.replace(/\n/g, '\n  ')}`);
        }
        out.push('');
        break;
    }
  }
  return out.join('\n');
}

function defaultTitle(id: TemplateSection['id']): string {
  switch (id) {
    case 'header':
      return 'Resumen';
    case 'metrics':
      return 'Metricas';
    case 'currentState':
      return 'Estado actual';
    case 'proposedSolution':
      return 'Solucion propuesta';
    case 'impactedFronts':
      return 'Frentes involucrados';
    case 'roles':
      return 'Roles';
    case 'qaScenarios':
      return 'Escenarios QA';
    case 'nextActions':
      return 'Proximas acciones';
    case 'diagrams':
      return 'Diagramas';
    case 'evidence':
      return 'Evidencia';
  }
}
