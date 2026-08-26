# Redesign the six Academy diagrams with a row-lane layout (no overlaps).
import io, sys

path = 'app.js'
s = io.open(path, encoding='utf-8').read()

new_block = r"""  /* Row-lane diagram toolkit: wide canvas, labeled lanes, short arrows between
     adjacent boxes only. Flow reads top-to-bottom, left-to-right. */
  const DIAG_W = 960;
  const LANE_X = 8;
  const BOX_W = 170, BOX_H = 58, GAP = 26, ROW_D = BOX_H + 36;
  const COL1 = 132, COL2 = COL1 + BOX_W + GAP, COL3 = COL2 + BOX_W + GAP, COL4 = COL3 + BOX_W + GAP;

  const DEFS = ('<defs>'
    + '<marker id="dar" markerWidth="9" markerHeight="9" refX="8" refY="4.5" orient="auto"><path d="M0,0 L9,4.5 L0,9 z" fill="#22D3EE"/></marker>'
    + '<marker id="par" markerWidth="9" markerHeight="9" refX="8" refY="4.5" orient="auto"><path d="M0,0 L9,4.5 L0,9 z" fill="#A78BFA"/></marker>'
    + '</defs>');

  function svg(h, inner) {
    return `<svg viewBox="0 0 ${DIAG_W} ${h}" width="${DIAG_W}" height="${h}" role="img">${DEFS}${inner}</svg>`;
  }
  function lane(y, text) {
    return `<text x="${LANE_X}" y="${y + 34}" fill="#A78BFA" font-family="Inter,sans-serif" font-size="12" font-weight="800" letter-spacing="1.2">${text}</text>`;
  }
  function boxAt(x, y, label, sub, accent) {
    const stroke = accent || 'rgba(167,139,250,.5)';
    let r = `<rect x="${x}" y="${y}" width="${BOX_W}" height="${BOX_H}" rx="12" fill="rgba(31,41,55,.92)" stroke="${stroke}" stroke-width="1.5"/>`;
    r += `<text x="${x + BOX_W / 2}" y="${sub ? y + 24 : y + 34}" text-anchor="middle" fill="#E5E7EB" font-family="Inter,sans-serif" font-size="13.5" font-weight="700">${label}</text>`;
    if (sub) r += `<text x="${x + BOX_W / 2}" y="${y + 43}" text-anchor="middle" fill="#9CA3AF" font-family="Inter,sans-serif" font-size="10.5">${sub}</text>`;
    return r;
  }
  function hArrow(x1, y1, x2, y2) {
    return `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="#22D3EE" stroke-width="1.8" marker-end="url(#dar)" opacity=".85"/>`;
  }
  function vArrow(x, y1, y2) {
    return `<line x1="${x}" y1="${y1}" x2="${x}" y2="${y2}" stroke="#22D3EE" stroke-width="1.8" marker-end="url(#dar)" opacity=".85"/>`;
  }
  function row(y, items) {
    let out = '';
    const mid = y + BOX_H / 2;
    items.forEach((it, i) => {
      const x = COL1 + i * (BOX_W + GAP);
      out += boxAt(x, y, it[0], it[1], it[2]);
      if (i < items.length - 1) out += hArrow(x + BOX_W + 3, mid, x + BOX_W + GAP - 4, mid);
    });
    return out;
  }
  function note(y, text, color) {
    return `<text x="${DIAG_W / 2}" y="${y}" text-anchor="middle" fill="${color || '#9CA3AF'}" font-family="Inter,sans-serif" font-size="11.5">${text}</text>`;
  }

  const DIAGRAMS = {
    'stack-layers': () => {
      let y = 14, out = '';
      out += lane(y, 'INTERFAZ');
      out += row(y, [['CLI / gv', 'comandos', 'rgba(167,139,250,.7)'], ['Hooks', 'pre-commit / push'], ['Dashboard', 'WS + Vite', 'rgba(167,139,250,.7)']]);
      out += vArrow(320, y + BOX_H + 3, y + ROW_D - 6);
      y += ROW_D;
      out += lane(y, 'ORQUESTACIÓN');
      out += row(y, [['SDD cycle', 'BA→SAD→DEV→QA'], ['Routing', 'recommend-agent'], ['Delegación', '21 agentes', 'rgba(167,139,250,.7)']]);
      out += vArrow(320, y + BOX_H + 3, y + ROW_D - 6);
      y += ROW_D;
      out += lane(y, 'CONOCIMIENTO');
      out += row(y, [['Engram', 'memoria persistente'], ['CodeGraph', 'índice AST'], ['Nexus', 'SQLite · 27 tablas', 'rgba(167,139,250,.7)']]);
      out += vArrow(320, y + BOX_H + 3, y + ROW_D - 6);
      y += ROW_D;
      out += lane(y, 'SALUD');
      out += row(y, [['Watchtower', '97 checks', 'rgba(34,211,238,.7)'], ['Budget guard', 'alertas 5M / 3M', 'rgba(34,211,238,.7)']]);
      return svg(y + BOX_H + 14, out);
    },
    'sdd-cycle': () => {
      let y = 14, out = '';
      out += lane(y, 'CICLO');
      out += row(y, [['① BA', 'explorar'], ['② SAD', 'diseñar'], ['③ DEV', 'construir'], ['④ QA', 'verificar']]);
      const qaX = COL4 + BOX_W / 2, baX = COL1 + BOX_W / 2;
      out += `<path d="M ${qaX} ${y + BOX_H + 4} V ${y + BOX_H + 34} H ${baX} V ${y + BOX_H + 12}" fill="none" stroke="#A78BFA" stroke-width="1.8" marker-end="url(#par)" opacity=".85"/>`;
      out += note(y + BOX_H + 52, 'QA realimenta la próxima exploración — el ciclo itera con hallazgos verificados', '#A78BFA');
      y += ROW_D + 22;
      out += lane(y, 'GATES');
      out += row(y, [['CI gate', 'nada avanza sin verificar', 'rgba(34,211,238,.7)'], ['Artefactos', 'versionados por fase']]);
      return svg(y + BOX_H + 14, out);
    },
    'tokens-pipeline': () => {
      let y = 14, out = '';
      out += lane(y, 'FUENTES');
      out += row(y, [['OpenCode', 'sqlite'], ['ZCode', 'jsonl'], ['Codex', 'sesiones'], ['MiniMax', 'sqlite']]);
      out += vArrow(320, y + BOX_H + 3, y + ROW_D - 6);
      y += ROW_D;
      out += lane(y, 'CONSOLIDAR');
      out += row(y, [['token-ingest', 'daemon local', 'rgba(167,139,250,.7)']]);
      out += vArrow(320, y + BOX_H + 3, y + ROW_D - 6);
      y += ROW_D;
      out += lane(y, 'NEXUS');
      out += row(y, [['token_usage', 'por día / sesión'], ['transactions', 'por mensaje'], ['savings', 'cache + compresión']]);
      out += vArrow(320, y + BOX_H + 3, y + ROW_D - 6);
      y += ROW_D;
      out += lane(y, 'CONSUMO');
      out += row(y, [['Dashboard', 'costo en vivo', 'rgba(34,211,238,.7)'], ['Budget guard', 'umbrales 70 / 90', 'rgba(34,211,238,.7)']]);
      return svg(y + BOX_H + 14, out);
    },
    'routing-loop': () => {
      let y = 14, out = '';
      out += lane(y, 'DEMANDA');
      out += row(y, [['Tarea', 'texto del usuario']]);
      out += vArrow(320, y + BOX_H + 3, y + ROW_D - 6);
      y += ROW_D;
      out += lane(y, 'DECISIÓN');
      out += row(y, [['recommend-agent', 'ranking + aprendizaje', 'rgba(167,139,250,.7)'], ['Agente', 'ejecuta la tarea']]);
      out += vArrow(320, y + BOX_H + 3, y + ROW_D - 6);
      y += ROW_D;
      out += lane(y, 'APRENDIZAJE');
      out += row(y, [['Outcome', '¿éxito / fallo?'], ['routing_rules', 'success_rate x tenant', 'rgba(34,211,238,.7)']]);
      const rrX = COL2 + BOX_W / 2;
      out += `<path d="M ${rrX} ${y + BOX_H + 4} V ${y + ROW_D - 2} H ${COL1 - 18} V ${ROW_D + BOX_H / 2} H ${COL1 - 6}" fill="none" stroke="#A78BFA" stroke-width="1.8" marker-end="url(#par)" opacity=".9"/>`;
      out += note(y + BOX_H + 30, 'el outcome actualiza success_rate y mejora la próxima recomendación (loop)', '#A78BFA');
      return svg(y + BOX_H + 44, out);
    },
    'cache-flow': () => {
      let y = 14, out = '';
      out += lane(y, 'REQUEST');
      out += row(y, [['Request', 'prompt + contexto']]);
      out += vArrow(320, y + BOX_H + 3, y + ROW_D - 6);
      y += ROW_D;
      out += lane(y, 'CLAVE');
      out += row(y, [['SHA-256', 'clave de caché', 'rgba(167,139,250,.7)']]);
      out += vArrow(320, y + BOX_H + 3, y + ROW_D - 6);
      y += ROW_D;
      out += lane(y, 'RESULTADO');
      out += row(y, [['HIT → respuesta', 'costo 0 · al instante', 'rgba(52,211,153,.7)'], ['MISS → modelo', 'se paga el token', 'rgba(248,113,113,.7)'], ['Guardar', 'TTL 30-60 min']]);
      out += note(y + BOX_H + 26, 'impacto medido: 25–41% de requests servidas sin gastar tokens');
      return svg(y + BOX_H + 36, out);
    },
    'tenancy': () => {
      let y = 14, out = '';
      out += lane(y, 'DATOS');
      out += row(y, [['Repositorios', 'metrics · traces · backlog']]);
      out += vArrow(320, y + BOX_H + 3, y + ROW_D - 6);
      y += ROW_D;
      out += lane(y, 'AISLAMIENTO');
      out += row(y, [['WHERE tenant_id = ?', 'en SQL, no en memoria', 'rgba(167,139,250,.7)'], ['Provenance', 'explícita db / fs']]);
      out += vArrow(320, y + BOX_H + 3, y + ROW_D - 6);
      y += ROW_D;
      out += lane(y, 'ACCESO');
      out += row(y, [['Tenant A', 've solo lo suyo'], ['Tenant B', 've solo lo suyo'], ['RBAC v1', 'viewer < operator < admin', 'rgba(34,211,238,.7)']]);
      out += note(y + BOX_H + 26, 'aislamiento verificable por SQL + membresía por principal + auditoría de accesos');
      return svg(y + BOX_H + 36, out);
    },
  };"""

start = s.find('  const DIAGRAMS = {')
if start < 0:
    sys.exit('DIAGRAMS not found')
end = s.find('\n  };\n', start)
if end < 0:
    sys.exit('closing not found')
s = s[:start] + new_block + s[end + len('\n  };\n'):]
io.open(path, 'w', encoding='utf-8', newline='\n').write(s)
print('OK: 6 diagramas rediseñados (row-lane layout)')
