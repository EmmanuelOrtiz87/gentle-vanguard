import { spawnSync } from 'child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import type { Paragraph } from 'docx';
import type { AnalyticsReport } from '../src/types';
import { getTemplate, renderTemplateMarkdown } from './templates';

export type ExportFormat = 'md' | 'html' | 'docx' | 'pdf';

export function toMarkdown(report: AnalyticsReport, templateId?: string | null): string {
  return renderTemplateMarkdown(report, templateId);
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function inlineMarkdown(md: string): string {
  return md
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
    .replace(/\*([^*]+)\*/g, '<em>$1</em>');
}

function markdownToHtml(md: string, report: AnalyticsReport): string {
  const lines = md.split(/\r?\n/);
  const out: string[] = [];
  let inList = false;
  let inPre = false;
  for (const raw of lines) {
    const line = raw;
    if (line.startsWith('```')) {
      if (inPre) {
        out.push('</pre>');
        inPre = false;
      } else {
        out.push('<pre>');
        inPre = true;
      }
      continue;
    }
    if (inPre) {
      out.push(escapeHtml(line));
      continue;
    }
    if (line.startsWith('# ')) {
      out.push(`<h1>${escapeHtml(line.slice(2))}</h1>`);
    } else if (line.startsWith('## ')) {
      out.push(`<h2>${escapeHtml(line.slice(3))}</h2>`);
    } else if (line.startsWith('- ')) {
      if (!inList) {
        out.push('<ul>');
        inList = true;
      }
      out.push(`<li>${inlineMarkdown(escapeHtml(line.slice(2)))}</li>`);
    } else if (line.trim() === '') {
      if (inList) {
        out.push('</ul>');
        inList = false;
      }
    } else {
      if (inList) {
        out.push('</ul>');
        inList = false;
      }
      out.push(`<p>${inlineMarkdown(escapeHtml(line))}</p>`);
    }
  }
  if (inList) out.push('</ul>');
  if (inPre) out.push('</pre>');

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
  h1 { font-size: 22px; color: #ffffff; }
  h2 { font-size: 15px; margin: 28px 0 10px; color: #00bfff; text-transform: uppercase; letter-spacing: .06em; }
  ul { padding-left: 18px; margin: 8px 0; }
  li { margin: 4px 0; font-size: 13px; line-height: 1.5; }
  p { font-size: 13px; line-height: 1.55; }
  pre { background: #10161f; border: 1px solid #1f2b3a; border-radius: 8px; padding: 12px; font-size: 12px; overflow-x: auto; white-space: pre-wrap; margin: 8px 0; }
  code { font-family: 'Consolas', monospace; font-size: 12px; background: rgba(255,255,255,0.06); padding: 1px 4px; border-radius: 3px; }
  footer { margin-top: 32px; color: #5b6675; font-size: 11px; border-top: 1px solid #1f2b3a; padding-top: 12px; }
  @media print { body { background: #ffffff; color: #111418; padding: 0; } h1, h2 { color: #111418; } pre { background: #f4f7fa; border-color: #d7dee8; } }
</style>
</head>
<body>
<div class="doc">
${out.join('\n')}
<footer>Generado por Gentle-Vanguard Analytics</footer>
</div>
</body>
</html>`;
}

export function toHtml(report: AnalyticsReport, templateId?: string | null): string {
  const md = renderTemplateMarkdown(report, templateId);
  return markdownToHtml(md, report);
}

export async function toDocx(report: AnalyticsReport, templateId?: string | null): Promise<Buffer> {
  // Lazy-load docx so the module is not parsed at startup when only MD/HTML
  // exports are used, keeping the server's cold-start footprint smaller.
  const {
    AlignmentType,
    BorderStyle,
    Document,
    HeadingLevel,
    Packer,
    Paragraph,
    TabStopType,
    TextRun,
  } = await import('docx');

  const template = getTemplate(templateId);
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

  const children: Paragraph[] = [
    new Paragraph({
      text: 'Gentle-Vanguard Analytics',
      heading: HeadingLevel.TITLE,
      alignment: AlignmentType.LEFT,
    }),
    new Paragraph({
      children: [new TextRun({ text: report.summary, bold: true, size: 28, color: '0D5C80' })],
      spacing: { after: 80 },
    }),
  ];

  for (const section of template.sections) {
    if (!section.visible) continue;
    const title = section.title ?? section.id;
    if (section.id === 'header') {
      children.push(
        new Paragraph({
          children: [
            new TextRun({
              text: `Reporte ${report.id} · ${new Date(report.createdAt).toLocaleString()} · modo ${report.mode} · template ${template.id}`,
              color: '777777',
              size: 18,
            }),
            new TextRun({ text: `Entrada: ${report.input}`, break: 1, color: '555555', size: 18 }),
            ...(report.llmSource
              ? [
                  new TextRun({
                    text: `Origen: ${report.llmSource}${report.llmCached ? ' (cache)' : ''} · ${(report.llmDurationMs ?? 0) / 1000}s`,
                    break: 1,
                    color: '555555',
                    size: 18,
                  }),
                ]
              : []),
          ],
          border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: 'DDDDDD' } },
          spacing: { after: 200 },
        }),
      );
    } else if (section.id === 'metrics') {
      children.push(
        heading(title),
        new Paragraph({
          children: [
            new TextRun({
              text: `Complejidad: ${report.complexity.level} — ${report.complexity.rationale}`,
              size: 20,
            }),
          ],
          spacing: { after: 60 },
        }),
        new Paragraph({
          children: [
            new TextRun({
              text: `Estimacion: discovery ${report.estimate.discoveryHours}h · delivery ${report.estimate.deliveryHours}h · QA ${report.estimate.qaHours}h · confianza ${report.estimate.confidence}`,
              size: 20,
            }),
          ],
          spacing: { after: 120 },
        }),
      );
    } else if (section.id === 'currentState') {
      children.push(heading(title), ...bullets(report.currentState));
    } else if (section.id === 'proposedSolution') {
      children.push(heading(title), ...bullets(report.proposedSolution));
    } else if (section.id === 'impactedFronts') {
      children.push(
        heading(title),
        ...report.impactedFronts.map(
          (front) =>
            new Paragraph({
              children: [new TextRun({ text: front, bold: true })],
              bullet: { level: 0 },
            }),
        ),
      );
    } else if (section.id === 'roles') {
      if (report.roles.length > 0) children.push(heading(title), ...bullets(report.roles));
    } else if (section.id === 'qaScenarios') {
      if (report.qaScenarios.length > 0)
        children.push(heading(title), ...bullets(report.qaScenarios));
    } else if (section.id === 'nextActions') {
      children.push(heading(title), ...bullets(report.nextActions));
    } else if (section.id === 'diagrams') {
      if (report.diagrams.current || report.diagrams.proposed) {
        children.push(
          heading(title),
          new Paragraph({ children: [new TextRun({ text: 'Actual', bold: true })] }),
          new Paragraph({
            children: [new TextRun({ text: report.diagrams.current, font: 'Consolas', size: 18 })],
          }),
          new Paragraph({ children: [new TextRun({ text: 'Propuesto', bold: true })] }),
          new Paragraph({
            children: [new TextRun({ text: report.diagrams.proposed, font: 'Consolas', size: 18 })],
          }),
        );
      }
    } else if (section.id === 'evidence') {
      if (report.evidence.length > 0) {
        children.push(heading(title));
        for (const item of report.evidence) {
          children.push(
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
          );
        }
      }
    }
  }

  const doc = new Document({
    styles: { default: { document: { run: { font: 'Calibri', size: 22 } } } },
    sections: [
      {
        properties: {},
        children: [
          ...children,
          new Paragraph({
            children: [
              new TextRun({
                text: `Generado por Gentle-Vanguard Analytics · template ${template.id}`,
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

export async function toPdf(report: AnalyticsReport, templateId?: string | null): Promise<Buffer> {
  const chromium = findChromium();
  if (!chromium) {
    // No Chrome/Edge found — return the HTML export with a header that makes
    // the caller aware so it can adjust the Content-Type and filename.
    // We signal this by setting a well-known property on the returned Buffer.
    const html = toHtml(report, templateId);
    const buf = Buffer.from(html, 'utf-8') as Buffer & { pdfFallbackHtml?: true };
    buf.pdfFallbackHtml = true;
    return buf;
  }
  const workDir = mkdtempSync(join(tmpdir(), 'gv-analytics-'));
  const htmlPath = join(workDir, `${report.id}.html`);
  const pdfPath = join(workDir, `${report.id}.pdf`);
  try {
    writeFileSync(htmlPath, toHtml(report, templateId), 'utf-8');
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
