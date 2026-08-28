import { spawnSync } from 'child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import {
  AlignmentType,
  BorderStyle,
  Document,
  HeadingLevel,
  Packer,
  Paragraph,
  TabStopType,
  TextRun,
} from 'docx';
import type { AnalyticsReport } from '../src/types';

export type ExportFormat = 'md' | 'html' | 'docx' | 'pdf';

function sectionLines(title: string, items: string[]): string {
  return [`## ${title}`, ...items.map((item) => `- ${item}`), ''].join('\n');
}

export function toMarkdown(report: AnalyticsReport): string {
  const parts = [
    `# ${report.summary}`,
    '',
    `Reporte: ${report.id} · ${new Date(report.createdAt).toISOString()} · modo ${report.mode}`,
    '',
    `**Entrada**: ${report.input}`,
    `**Complejidad**: ${report.complexity.level} — ${report.complexity.rationale}`,
    `**Estimación**: discovery ${report.estimate.discoveryHours}h · delivery ${report.estimate.deliveryHours}h · QA ${report.estimate.qaHours}h · confianza ${report.estimate.confidence}`,
    '',
    sectionLines('Estado actual', report.currentState),
    sectionLines('Solución propuesta', report.proposedSolution),
    sectionLines('Frentes involucrados', report.impactedFronts.map((front) => `**${front}**`)),
    sectionLines('Roles', report.roles),
    sectionLines('Escenarios QA', report.qaScenarios),
    `## Diagramas`,
    '',
    `**Actual**`,
    '',
    '```text',
    report.diagrams.current,
    '```',
    '',
    `**Propuesto**`,
    '',
    '```text',
    report.diagrams.proposed,
    '```',
    '',
    sectionLines('Próximas acciones', report.nextActions),
    `## Evidencia`,
    '',
    ...report.evidence.map(
      (item) =>
        `- **${item.source}** — ${item.title}${item.url ? ` ([link](${item.url}))` : ''}\n  ${item.detail.replace(/\n/g, '\n  ')}`,
    ),
    '',
  ];
  return parts.join('\n');
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

export function toHtml(report: AnalyticsReport): string {
  const list = (items: string[]) =>
    `<ul>${items.map((item) => `<li>${escapeHtml(item)}</li>`).join('')}</ul>`;
  const evidence = report.evidence
    .map(
      (item) => `
      <article class="evidence">
        <span class="tag">${escapeHtml(item.source)}</span>
        <strong>${escapeHtml(item.title)}</strong>
        ${item.url ? `<a href="${escapeHtml(item.url)}">${escapeHtml(item.url)}</a>` : ''}
        <pre>${escapeHtml(item.detail)}</pre>
      </article>`,
    )
    .join('');
  return `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8" />
<title>GV Analytics ${escapeHtml(report.id)}</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: 'Segoe UI', system-ui, sans-serif; background: #0d1117; color: #e6edf3; padding: 40px; }
  .doc { max-width: 880px; margin: 0 auto; }
  header { border-bottom: 1px solid #1f2b3a; padding-bottom: 16px; margin-bottom: 24px; }
  h1 { font-size: 22px; margin: 0 0 6px; color: #ffffff; }
  h2 { font-size: 15px; margin: 28px 0 10px; color: #00bfff; text-transform: uppercase; letter-spacing: .06em; }
  .meta { color: #8b98a9; font-size: 12px; }
  .metrics { display: flex; gap: 12px; flex-wrap: wrap; margin: 16px 0; }
  .metric { background: #161c26; border: 1px solid #1f2b3a; border-radius: 8px; padding: 10px 14px; min-width: 110px; }
  .metric span { display: block; font-size: 11px; color: #8b98a9; text-transform: uppercase; }
  .metric strong { font-size: 16px; color: #00bfff; }
  ul { padding-left: 18px; margin: 8px 0; }
  li { margin: 4px 0; font-size: 13px; line-height: 1.5; }
  pre { background: #10161f; border: 1px solid #1f2b3a; border-radius: 8px; padding: 12px; font-size: 12px; overflow-x: auto; white-space: pre-wrap; }
  .diagrams { display: grid; gap: 12px; }
  .evidence { border: 1px solid #1f2b3a; border-radius: 8px; padding: 12px; margin: 10px 0; background: #121924; }
  .evidence .tag { display: inline-block; background: rgba(0,191,255,.12); color: #00bfff; border-radius: 999px; font-size: 10px; padding: 2px 10px; margin-bottom: 6px; text-transform: uppercase; }
  .evidence a { color: #a855f7; font-size: 12px; display: block; margin: 4px 0; word-break: break-all; }
  footer { margin-top: 32px; color: #5b6675; font-size: 11px; border-top: 1px solid #1f2b3a; padding-top: 12px; }
  @media print {
    body { background: #ffffff; color: #111418; padding: 0; }
    h1 { color: #111418; } h2 { color: #0087b8; }
    .metric, .evidence { background: #f4f7fa; border-color: #d7dee8; }
    .metric strong { color: #0087b8; }
    pre { background: #f4f7fa; border-color: #d7dee8; color: #111418; }
    .evidence .tag { background: #e2f4fd; color: #0087b8; }
  }
</style>
</head>
<body>
<div class="doc">
  <header>
    <h1>${escapeHtml(report.summary)}</h1>
    <div class="meta">Gentle-Vanguard Analytics · Reporte ${escapeHtml(report.id)} · ${escapeHtml(new Date(report.createdAt).toLocaleString())} · modo ${escapeHtml(report.mode)}</div>
    <div class="meta"><strong>Entrada:</strong> ${escapeHtml(report.input)}</div>
  </header>
  <div class="metrics">
    <div class="metric"><span>Complejidad</span><strong>${escapeHtml(report.complexity.level)}</strong></div>
    <div class="metric"><span>Discovery</span><strong>${report.estimate.discoveryHours}h</strong></div>
    <div class="metric"><span>Delivery</span><strong>${report.estimate.deliveryHours}h</strong></div>
    <div class="metric"><span>QA</span><strong>${report.estimate.qaHours}h</strong></div>
    <div class="metric"><span>Confianza</span><strong>${escapeHtml(report.estimate.confidence)}</strong></div>
  </div>
  <h2>Estado actual</h2>${list(report.currentState)}
  <h2>Solución propuesta</h2>${list(report.proposedSolution)}
  <h2>Frentes involucrados</h2>${list(report.impactedFronts)}
  <h2>Roles</h2>${list(report.roles)}
  <h2>Escenarios QA</h2>${list(report.qaScenarios)}
  <h2>Diagramas</h2>
  <div class="diagrams">
    <pre>Actual:\n${escapeHtml(report.diagrams.current)}</pre>
    <pre>Propuesto:\n${escapeHtml(report.diagrams.proposed)}</pre>
  </div>
  <h2>Próximas acciones</h2>${list(report.nextActions)}
  <h2>Evidencia</h2>${evidence}
  <footer>Generado por Gentle-Vanguard Analytics — ${escapeHtml(report.complexity.rationale)}</footer>
</div>
</body>
</html>`;
}

export async function toDocx(report: AnalyticsReport): Promise<Buffer> {
  const heading = (text: string) =>
    new Paragraph({ text, heading: HeadingLevel.HEADING_2, spacing: { before: 320, after: 120 } });
  const bullets = (items: string[]) =>
    items.map(
      (item) =>
        new Paragraph({
          children: [new TextRun(item)],
          bullet: { level: 0 },
          spacing: { after: 60 },
        }),
    );

  const doc = new Document({
    styles: {
      default: {
        document: { run: { font: 'Calibri', size: 22 } },
      },
    },
    sections: [
      {
        properties: {},
        children: [
          new Paragraph({
            text: 'Gentle-Vanguard Analytics',
            heading: HeadingLevel.TITLE,
            alignment: AlignmentType.LEFT,
          }),
          new Paragraph({
            children: [
              new TextRun({
                text: `${report.summary}`,
                bold: true,
                size: 28,
                color: '0D5C80',
              }),
            ],
            spacing: { after: 80 },
          }),
          new Paragraph({
            children: [
              new TextRun({
                text: `Reporte ${report.id} · ${new Date(report.createdAt).toLocaleString()} · modo ${report.mode}`,
                color: '777777',
                size: 18,
              }),
              new TextRun({ text: `Entrada: ${report.input}`, break: 1, color: '555555', size: 18 }),
              new TextRun({
                text: `Complejidad: ${report.complexity.level} · Discovery ${report.estimate.discoveryHours}h · Delivery ${report.estimate.deliveryHours}h · QA ${report.estimate.qaHours}h · Confianza ${report.estimate.confidence}`,
                break: 1,
                color: '555555',
                size: 18,
              }),
            ],
            border: {
              bottom: { style: BorderStyle.SINGLE, size: 4, color: 'DDDDDD' },
            },
            spacing: { after: 200 },
          }),
          heading('Estado actual'),
          ...bullets(report.currentState),
          heading('Solución propuesta'),
          ...bullets(report.proposedSolution),
          heading('Frentes involucrados'),
          ...bullets(report.impactedFronts),
          heading('Roles'),
          ...bullets(report.roles),
          heading('Escenarios QA'),
          ...bullets(report.qaScenarios),
          heading('Diagramas'),
          new Paragraph({ children: [new TextRun({ text: 'Actual', bold: true })] }),
          new Paragraph({ children: [new TextRun({ text: report.diagrams.current, font: 'Consolas', size: 18 })] }),
          new Paragraph({ children: [new TextRun({ text: 'Propuesto', bold: true })] }),
          new Paragraph({ children: [new TextRun({ text: report.diagrams.proposed, font: 'Consolas', size: 18 })] }),
          heading('Próximas acciones'),
          ...bullets(report.nextActions),
          heading('Evidencia'),
          ...report.evidence.flatMap((item) => [
            new Paragraph({
              children: [
                new TextRun({ text: `[${item.source}] `, bold: true, color: '0D5C80' }),
                new TextRun({ text: item.title, bold: true }),
                ...(item.url
                  ? [new TextRun({ text: ` — ${item.url}`, color: '777777', size: 18 })]
                  : []),
              ],
              spacing: { before: 120, after: 40 },
            }),
            new Paragraph({
              children: [new TextRun({ text: item.detail, size: 18, color: '444444' })],
              indent: { left: 360 },
            }),
          ]),
          new Paragraph({
            children: [
              new TextRun({
                text: `Generado por Gentle-Vanguard Analytics — ${report.complexity.rationale}`,
                size: 16,
                color: '888888',
              }),
            ],
            spacing: { before: 400 },
            tabStops: [{ type: TabStopType.LEFT, position: 0 }],
          }),
        ],
      },
    ],
  });
  return Packer.toBuffer(doc);
}

function findChromium(): string | null {
  const candidates = [
    process.env.GV_ANALYTICS_CHROME,
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  ].filter(Boolean) as string[];
  for (const candidate of candidates) {
    if (existsSync(candidate)) return candidate;
  }
  return null;
}

export async function toPdf(report: AnalyticsReport): Promise<Buffer> {
  const chromium = findChromium();
  if (!chromium) {
    throw new Error(
      'No se encontro Chrome/Edge para generar PDF. Exporta HTML o DOCX, o define GV_ANALYTICS_CHROME.',
    );
  }
  const workDir = mkdtempSync(join(tmpdir(), 'gv-analytics-'));
  const htmlPath = join(workDir, `${report.id}.html`);
  const pdfPath = join(workDir, `${report.id}.pdf`);
  try {
    writeFileSync(htmlPath, toHtml(report), 'utf-8');
    const fileUrl = `file:///${htmlPath.replace(/\\/g, '/')}`;
    const result = spawnSync(
      chromium,
      [
        '--headless',
        '--disable-gpu',
        '--no-sandbox',
        '--hide-scrollbars',
        `--print-to-pdf=${pdfPath}`,
        fileUrl,
      ],
      { windowsHide: true, stdio: 'ignore', timeout: 60_000 },
    );
    if (result.status !== 0 || !existsSync(pdfPath)) {
      throw new Error(`Chrome headless fallo (exit ${result.status}).`);
    }
    return readFileSync(pdfPath);
  } finally {
    rmSync(workDir, { recursive: true, force: true });
  }
}
