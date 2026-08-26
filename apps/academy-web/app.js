/* Gentle-Vanguard Academy — vanilla SPA
   Hash router + markdown-subset renderer + file-chip modals + SVG diagrams +
   demo gallery + interactive prompt generator. No dependencies, no build. */
(function () {
  'use strict';

  const CONTENT = window.GV_CONTENT || {};
  const TRACKS = window.GV_TRACKS || [];
  const GLOSSARY = window.GV_GLOSSARY || [];
  const FILES = window.GV_FILES || {};
  const app = document.getElementById('app');

  const I18N = window.GV_I18N || {};
  const TRACK_I18N = window.GV_TRACK_I18N || {};
  let LANG = localStorage.getItem('gv_academy_lang') || 'es';
  function t(key) { return (I18N[LANG] && I18N[LANG][key]) || (I18N.es && I18N.es[key]) || key; }
  function trackMeta(id) {
    const base = TRACKS.find(x => x.id === id) || { title: id, desc: '' };
    const loc = (TRACK_I18N[LANG] || {})[id];
    return loc ? { title: loc[0], desc: loc[1] } : base;
  }

  document.getElementById('foot-year').textContent = new Date().getFullYear();

  /* ---------- Diagrams (inline SVG, brand tokens) ---------- */
  const D = {
    box: (x, y, w, label, sub, accent) => `
      <rect x="${x}" y="${y}" width="${w}" height="52" rx="10" fill="rgba(31,41,55,.85)"
        stroke="${accent || 'rgba(167,139,250,.45)'}" stroke-width="1.4"/>
      <text x="${x + w / 2}" y="${sub ? y + 22 : y + 31}" text-anchor="middle" fill="#E5E7EB"
        font-family="Inter,sans-serif" font-size="13" font-weight="700">${label}</text>
      ${
        sub
          ? `<text x="${x + w / 2}" y="${y + 40}" text-anchor="middle" fill="#9CA3AF"
        font-family="Inter,sans-serif" font-size="10.5">${sub}</text>`
          : ''
      }`,
    arrow: (x1, y1, x2, y2, accent) => `
      <defs><marker id="ah" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto">
        <path d="M0,0 L8,4 L0,8 z" fill="${accent || '#22D3EE'}"/></marker></defs>
      <line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${accent || '#22D3EE'}"
        stroke-width="1.6" marker-end="url(#ah)" opacity=".8"/>`,
    wrap: (w, h, inner) =>
      `<svg viewBox="0 0 ${w} ${h}" width="${w}" height="${h}" role="img">${inner}</svg>`,
  };

  /* Row-lane diagram toolkit: wide canvas, labeled lanes, short arrows between
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
  };
  /* ---------- Markdown subset renderer ---------- */
  function esc(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }
  function inline(s) {
    return esc(s)
      .replace(/`([^`]+)`/g, (m, code) => {
        // Any inline code matching a packed file path becomes a clickable chip
        const clean = code.trim().replace(/^\.\//, '');
        const candidates = [clean, 'docs/' + clean, 'config/' + clean, 'rules/' + clean];
        const hit = candidates.find((c) => FILES[c]);
        if (hit && /^[A-Za-z0-9_\-./]+$/.test(clean)) {
          return `<span class="file-chip" data-file="${esc(hit)}" title="${esc(hit)}">${esc(clean)}</span>`;
        }
        return `<code>${code}</code>`;
      })
      .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
      .replace(/==([^=]+)==/g, '<span class="kw">$1</span>')
      .replace(/\[\[([^\]]+)\]\]/g, (m, p) => {
        const clean = p.trim();
        const hit = FILES[clean];
        return `<span class="file-chip${hit ? '' : ' missing'}" data-file="${esc(clean)}" title="${esc(clean)}">${esc(clean.split('/').pop())}</span>`;
      });
  }
  function diagramBlock(id) {
    const fn = DIAGRAMS[id.trim()];
    if (!fn) return '';
    const captions = {
      'stack-layers': 'Los planos del stack: todo orbita Nexus y se vigila con Watchtower.',
      'sdd-cycle': 'El ciclo SDD con gates: entender → diseñar → construir → verificar.',
      'tokens-pipeline': 'El consumo real de 4 herramientas converge en Nexus y dispara alertas.',
      'routing-loop':
        'El loop de aprendizaje de routing: cada outcome mejora la próxima recomendación.',
      'cache-flow': 'Response cache: la misma pregunta no se paga dos veces.',
      tenancy: 'Aislamiento por tenant verificado en SQL, no filtrado en memoria.',
    };
    return `<figure class="diagram-box">${fn()}<figcaption>${captions[id.trim()] || ''}</figcaption></figure>`;
  }
  function statsBlock(rest) {
    const parts = rest
      .split('|')
      .map((p) => p.trim())
      .filter(Boolean)
      .map((p) => {
        const [n, l] = p.split('~');
        return `<div class="stat-pill"><div class="n">${(n || '').trim()}</div><div class="l">${(l || '').trim()}</div></div>`;
      });
    return `<div class="stat-row">${parts.join('')}</div>`;
  }
  function renderMarkdown(md) {
    const lines = md.split('\n');
    const out = [];
    let inPre = false,
      inList = null,
      tableBuf = [];
    const flushList = () => {
      if (inList) {
        out.push(inList === 'ul' ? '</ul>' : '</ol>');
        inList = null;
      }
    };
    const flushTable = () => {
      if (!tableBuf.length) return;
      const rows = tableBuf
        .filter((r) => !/^\s*\|[\s:|-]+\|\s*$/.test(r))
        .map((r) =>
          r
            .trim()
            .replace(/^\||\|$/g, '')
            .split('|')
            .map((c) => c.trim()),
        );
      const head = rows.shift();
      let html =
        '<table><thead><tr>' +
        head.map((h) => `<th>${inline(h)}</th>`).join('') +
        '</tr></thead><tbody>';
      for (const r of rows)
        html += '<tr>' + r.map((c) => `<td>${inline(c)}</td>`).join('') + '</tr>';
      out.push(html + '</tbody></table>');
      tableBuf = [];
    };
    for (const raw of lines) {
      const line = raw.replace(/\s+$/, '');
      if (line.startsWith('```')) {
        if (inPre) {
          out.push('</code></pre>');
          inPre = false;
        } else {
          flushList();
          flushTable();
          out.push('<pre><code>');
          inPre = true;
        }
        continue;
      }
      if (inPre) {
        out.push(esc(raw));
        continue;
      }
      if (/^\s*\|.*\|\s*$/.test(line)) {
        flushList();
        tableBuf.push(line);
        continue;
      }
      flushTable();
      const dg = /^:::diagram\s+(\S+)\s*:::/.exec(line);
      if (dg) {
        flushList();
        out.push(diagramBlock(dg[1]));
        continue;
      }
      const st = /^:::stats\s+(.+):::/.exec(line);
      if (st) {
        flushList();
        out.push(statsBlock(st[1]));
        continue;
      }
      if (/^###\s+/.test(line)) {
        flushList();
        out.push(`<h3>${inline(line.slice(4))}</h3>`);
        continue;
      }
      if (/^##\s+/.test(line)) {
        flushList();
        out.push(`<h2>${inline(line.slice(3))}</h2>`);
        continue;
      }
      if (/^>\s?/.test(line)) {
        flushList();
        out.push(`<blockquote>${inline(line.replace(/^>\s?/, ''))}</blockquote>`);
        continue;
      }
      if (/^---+$/.test(line)) {
        flushList();
        out.push('<hr>');
        continue;
      }
      const ul = /^\s*[-*]\s+(.*)$/.exec(line);
      if (ul) {
        if (inList !== 'ul') {
          flushList();
          out.push('<ul>');
          inList = 'ul';
        }
        out.push(`<li>${inline(ul[1])}</li>`);
        continue;
      }
      const ol = /^\s*\d+\.\s+(.*)$/.exec(line);
      if (ol) {
        if (inList !== 'ol') {
          flushList();
          out.push('<ol>');
          inList = 'ol';
        }
        out.push(`<li>${inline(ol[1])}</li>`);
        continue;
      }
      if (!line.trim()) {
        flushList();
        continue;
      }
      flushList();
      out.push(`<p>${inline(line)}</p>`);
    }
    flushList();
    flushTable();
    if (inPre) out.push('</code></pre>');
    return out.join('\n');
  }

  /* ---------- Effects: reveal + progress ---------- */
  function bindEffects() {
    const els = document.querySelectorAll(
      '.track-card, .lesson-row, .gloss-card, .demo-card, .section-title',
    );
    els.forEach((el) => el.classList.add('reveal'));
    if (!('IntersectionObserver' in window)) {
      els.forEach((e) => e.classList.add('shown'));
      return;
    }
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) {
            e.target.classList.add('shown');
            io.unobserve(e.target);
          }
        });
      },
      { threshold: 0.08 },
    );
    els.forEach((el) => io.observe(el));
  }
  const progress = document.getElementById('read-progress');
  window.addEventListener(
    'scroll',
    () => {
      const h = document.documentElement;
      const max = h.scrollHeight - h.clientHeight;
      progress.style.width = max > 0 ? (h.scrollTop / max) * 100 + '%' : '0%';
    },
    { passive: true },
  );

  /* ---------- File modal ---------- */
  const overlay = document.getElementById('modal-overlay');
  function openFile(path) {
    const f = FILES[path];
    if (!f) return;
    document.getElementById('modal-path').textContent = path;
    const body = document.getElementById('modal-body');
    body.innerHTML =
      f.lang === 'md'
        ? renderMarkdown(f.body.replace(/^# .*/m, '').replace(/\[\[([^\]]+)\]\]/g, '$1'))
        : `<pre><code>${esc(f.body)}</code></pre>`;
    overlay.classList.add('open');
    document.body.style.overflow = 'hidden';
  }
  function closeModal() {
    overlay.classList.remove('open');
    document.body.style.overflow = '';
  }
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) closeModal();
  });
  document.getElementById('modal-close').addEventListener('click', closeModal);
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeModal();
  });
  document.addEventListener('click', (e) => {
    const chip = e.target.closest('.file-chip');
    if (chip && !chip.classList.contains('missing')) openFile(chip.dataset.file);
  });

  /* ---------- Views ---------- */
  function badgeClass(t) {
    if (t === 'laboratorio') return 'badge badge-lab';
    if (t === 'referencia') return 'badge badge-ref';
    return 'badge badge-course';
  }

  function viewHome() {
    const totalLessons = Object.values(CONTENT).reduce((a, tv) => a + tv.lessons.length, 0);
    const cards = TRACKS.map(tr => {
      const lessons = (CONTENT[tr.id] || { lessons: [] }).lessons.length;
      const mins = ((CONTENT[tr.id] || { lessons: [] }).lessons || []).reduce((a, l) => a + (l.minutes || 6), 0);
      const m = trackMeta(tr.id);
      const typeLabel = tr.type === 'laboratorio' ? t('lab') : tr.type === 'referencia' ? t('ref') : t('course');
      return `<a class="track-card" href="#/track/${tr.id}">
        <div class="badge-row"><span class="${badgeClass(tr.type)}">${typeLabel}</span></div>
        <h3>${m.title}</h3>
        <p>${m.desc}</p>
        <div class="meta">${lessons} ${t('lessons')} · ~${mins} ${t('min')}</div>
      </a>`;
    }).join('');
    app.innerHTML = `
      <div class="view-fade">
      <section class="hero">
        <h1>${t('home.h1a')}<br><span class="g">${t('home.h1b')}</span></h1>
        <p>${t('home.sub')}</p>
        <div class="hero-ctas">
          <a class="btn btn-primary" href="#/track/fundamentos">${t('home.cta1')}</a>
          <a class="btn btn-ghost" href="#/demo">${t('home.cta2')}</a>
          <a class="btn btn-ghost" href="#/generador">${t('home.cta3')}</a>
        </div>
        <div class="hero-stats">
          <div class="hstat"><div class="n" data-count="${TRACKS.length}">0</div><div class="l">${t('home.stat.tracks')}</div></div>
          <div class="hstat"><div class="n" data-count="${totalLessons}">0</div><div class="l">${t('home.stat.lessons')}</div></div>
          <div class="hstat"><div class="n" data-count="${GLOSSARY.length}">0</div><div class="l">${t('home.stat.terms')}</div></div>
          <div class="hstat"><div class="n" data-count="${Object.keys(FILES).length}">0</div><div class="l">${t('home.stat.docs')}</div></div>
        </div>
      </section>
      <h2 class="section-title">${t('home.section')}</h2>
      <p class="section-sub">${t('home.sectionSub')}</p>
      <div class="tracks-grid">${cards}</div>
      </div>`;
    animateCounters();
  }
  function animateCounters() {
    document.querySelectorAll('.hstat .n[data-count]').forEach((el) => {
      const target = parseInt(el.dataset.count, 10) || 0;
      const dur = 700;
      const t0 = performance.now();
      const tick = (t) => {
        const p = Math.min(1, (t - t0) / dur);
        el.textContent = Math.round(target * (1 - Math.pow(1 - p, 3)));
        if (p < 1) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
    });
  }

  function viewTrack(id) {
    const track = TRACKS.find((t) => t.id === id);
    const data = CONTENT[id];
    if (!track || !data) {
      viewNotFound();
      return;
    }
    const rows = data.lessons
      .map(
        (l, i) => `
      <a class="lesson-row" href="#/lesson/${id}/${l.id}">
        <span class="num">${String(i + 1).padStart(2, '0')}</span>
        <span class="lt">${l.title}</span>
        <span class="ld">${l.minutes || 6} ${t('min')}</span>
      </a>`,
      )
      .join('');
    app.innerHTML = `<div class="view-fade">
      <div class="view-header">
        <div class="eyebrow">${track.type === 'laboratorio' ? t('lab') : track.type === 'referencia' ? t('ref') : t('course')} · ${data.lessons.length} ${t('lessons')}</div>
        <h1>${trackMeta(id).title}</h1>
        <p class="desc">${trackMeta(id).desc}</p>
      </div>
      <div class="lesson-list">${rows}</div></div>`;
  }

  function viewLesson(trackId, lessonId) {
    const track = TRACKS.find((t) => t.id === trackId);
    const data = CONTENT[trackId];
    if (!track || !data) {
      viewNotFound();
      return;
    }
    const idx = data.lessons.findIndex((l) => l.id === lessonId);
    if (idx < 0) {
      viewLesson(trackId, data.lessons[0].id);
      return;
    }
    const lesson = data.lessons[idx];
    const nav = data.lessons
      .map(
        (l, i) =>
          `<a href="#/lesson/${trackId}/${l.id}" class="${i === idx ? 'active' : ''}">${String(i + 1).padStart(2, '0')} · ${l.title}</a>`,
      )
      .join('');
    const prev = data.lessons[idx - 1];
    const next = data.lessons[idx + 1];
    app.innerHTML = `<div class="view-fade">
      <div class="view-header" style="margin-bottom:18px">
        <div class="eyebrow"><a href="#/track/${trackId}" style="color:inherit;text-decoration:none">${track.title}</a> · ${t('lesson.of')} ${idx + 1}/${data.lessons.length} · ${lesson.minutes || 6} ${t('min')}</div>
        ${LANG !== 'es' ? `<div class=\"eyebrow\" style=\"margin-top:6px;font-size:11.5px\">${t('lesson.esNote')}</div>` : ''}
      </div>
      <div class="lesson-layout">
        <aside class="lesson-nav"><div class="nav-title">${track.title}</div>${nav}</aside>
        <article class="lesson-body">
          <div class="article">
            <h2 style="margin-top:0">${lesson.title}</h2>
            ${renderMarkdown(lesson.md)}
          </div>
          <div class="pager">
            ${prev ? `<a href="#/lesson/${trackId}/${prev.id}"><span class="dir">← Anterior</span>${prev.title}</a>` : '<span></span>'}
            ${next ? `<a href="#/lesson/${trackId}/${next.id}" style="text-align:right"><span class="dir">Siguiente →</span>${next.title}</a>` : `<a href="#/track/${trackId}" style="text-align:right"><span class="dir">Fin del track</span>Volver al índice</a>`}
          </div>
        </article>
      </div></div>`;
  }

  function viewDemo() {
    const card = (img, tc, dc) => `<div class="demo-card">
        <img src="assets/demo/${img}" alt="${t(tc)}" loading="lazy">
        <div class="dc-body"><h3>${t(tc)}</h3><p>${t(dc)}</p></div></div>`;
    app.innerHTML = `<div class="view-fade">
      <div class="view-header">
        <div class="eyebrow">${t('demo.eyebrow')}</div>
        <h1>${t('demo.title')}</h1>
        <p class="desc">${t('demo.desc')}</p>
      </div>
      <div class="demo-grid">
        ${card('dashboard-home.png', 'demo.c1', 'demo.c1d')}
        ${card('dashboard-tracing.png', 'demo.c2', 'demo.c2d')}
        ${card('dashboard-content-operations.png', 'demo.c3', 'demo.c3d')}
        ${card('dashboard-timeline.png', 'demo.c4', 'demo.c4d')}
        ${card('dashboard-marketplace.png', 'demo.c5', 'demo.c5d')}
        ${card('generator.png', 'demo.c6', 'demo.c6d')}
      </div>
      </div>`;
  }
  /* ---------- Prompt generator ---------- */
  const GEN_TEMPLATES = {
    review: { label: 'Code review', task: 'Hacer un code review completo del código provisto' },
    feature: { label: 'Generar una feature', task: 'Implementar la funcionalidad descrita' },
    architecture: {
      label: 'Análisis / arquitectura',
      task: 'Analizar el problema y proponer diseño técnico',
    },
    docs: { label: 'Documentación', task: 'Escribir la documentación solicitada' },
    tests: { label: 'Tests', task: 'Escribir tests para el código o comportamiento descrito' },
    refactor: {
      label: 'Refactor / optimización',
      task: 'Refactorizar u optimizar el código provisto',
    },
    research: {
      label: 'Investigación',
      task: 'Investigar el tema y sintetizar hallazgos accionables',
    },
  };

  function viewGenerator() {
    const opts = Object.entries(GEN_TEMPLATES)
      .map(([k, v]) => `<option value="${k}">${v.label}</option>`)
      .join('');
    app.innerHTML = `<div class="view-fade">
      <div class="view-header">
        <div class="eyebrow">Demo interactiva · prompt engineering</div>
        <h1>Generador de prompts</h1>
        <p class="desc">Completá los campos y obtené un prompt profesional estructurado (rol, tarea, contexto, formato, restricciones, verificación) listo para copiar a cualquier modelo. Los mismos principios del <a href="#/track/prompts" style="color:var(--gv-cyan)">track de prompts</a>, aplicados.</p>
      </div>
      <div class="gen-layout">
        <div class="gen-panel">
          <h3>1 · Configurá tu prompt</h3>
          <div class="field"><label>Tipo de tarea</label><select id="g-type">${opts}</select></div>
          <div class="field"><label>Rol del asistente <small>(quién debe ser)</small></label>
            <input id="g-role" type="text" value="Ingeniero de software senior, especialista en calidad y arquitectura"></div>
          <div class="field"><label>Objetivo / tarea <small>(una frase concreta)</small></label>
            <input id="g-goal" type="text" placeholder="Ej: review del módulo de pagos antes de liberar a producción"></div>
          <div class="field"><label>Contexto <small>(repo, stack, restricciones de negocio)</small></label>
            <textarea id="g-ctx" placeholder="Ej: monorepo TypeScript + React, tests con vitest, no romper API pública…"></textarea></div>
          <div class="field"><label>Criterios de aceptación <small>(uno por línea)</small></label>
            <textarea id="g-criteria" placeholder="Ej: sin vulnerabilidades high&#10;cubre casos borde&#10;mantiene estilo del repo"></textarea></div>
          <div class="field"><label>Formato de salida</label>
            <select id="g-format">
              <option value="Informe con secciones y severidades (crítico/alto/medio/bajo) con evidencia y recomendación por hallazgo">Informe con severidades</option>
              <option value="Código completo listo para aplicar, con comentarios solo donde el código no lo explica">Código listo</option>
              <option value="Plan paso a paso numerado con dependencias y riesgos">Plan paso a paso</option>
              <option value="Documento markdown con secciones, tabla de decisiones y trade-offs">Documento markdown</option>
              <option value="JSON estricto con el schema indicado en el contexto, sin texto extra">JSON estricto</option>
            </select></div>
          <div class="field"><label>Tono / estilo <small>(opcional)</small></label>
            <input id="g-tone" type="text" placeholder="Ej: directo, técnico, sin relleno"></div>
          <div class="gen-actions">
            <button class="btn btn-primary" id="g-build">Construir prompt</button>
            <button class="btn btn-ghost" id="g-fill">Cargar ejemplo</button>
          </div>
          <div class="gen-tip">Todo se procesa en tu navegador — nada sale de tu máquina.</div>
        </div>
        <div class="gen-panel gen-output">
          <h3>2 · Tu prompt</h3>
          <pre id="g-out">Completá los campos y presioná “Construir prompt”. El resultado aparece aquí, listo para copiar.</pre>
          <div class="gen-actions">
            <button class="btn btn-primary" id="g-copy">Copiar</button>
          </div>
          <div class="gen-tip" id="g-copied" style="color:var(--gv-cyan)"></div>
        </div>
      </div></div>`;

    const $ = (id) => document.getElementById(id);
    function build() {
      const t = GEN_TEMPLATES[$('g-type').value];
      const role = $('g-role').value.trim() || 'Asistente experto';
      const goal = $('g-goal').value.trim() || '[COMPLETAR: describí la tarea concreta]';
      const ctx = $('g-ctx').value.trim();
      const crit = $('g-criteria')
        .value.trim()
        .split('\n')
        .map((s) => s.trim())
        .filter(Boolean);
      const fmt = $('g-format').value;
      const tone = $('g-tone').value.trim();
      const L = [];
      L.push(`# Rol`);
      L.push(`Actuá como ${role}. Tu objetivo: ${goal}.`);
      L.push(``);
      L.push(`# Tarea`);
      L.push(
        t.task +
          '. Trabajá sobre la información provista; si algo esencial falta, formulá UNA lista breve de preguntas antes de ejecutar.',
      );
      if (ctx) {
        L.push('');
        L.push('# Contexto');
        L.push(ctx);
      }
      if (crit.length) {
        L.push('');
        L.push('# Criterios de aceptación');
        L.push('La respuesta es correcta solo si:');
        crit.forEach((c) => L.push(`- ${c}`));
      }
      L.push('');
      L.push('# Formato de salida');
      L.push(fmt + '.');
      if (tone) {
        L.push('');
        L.push('# Estilo');
        L.push(tone + '.');
      }
      L.push('');
      L.push('# Verificación');
      L.push(
        'Antes de responder, revisá tu borrador contra los criterios de aceptación y corregilo. Mostrá solo la versión final.',
      );
      $('g-out').textContent = L.join('\n');
      $('g-copied').textContent = '';
    }
    $('g-build').addEventListener('click', build);
    $('g-fill').addEventListener('click', () => {
      $('g-type').value = 'review';
      $('g-goal').value = 'Review del módulo de checkout antes de liberar a producción';
      $('g-ctx').value =
        'Monorepo TypeScript + React 18. Tests con vitest. El módulo maneja pagos con Stripe. No podemos romper la API pública ni los contratos existentes. Está en apps/web/src/checkout/.';
      $('g-criteria').value =
        'Sin vulnerabilidades high ni medium\nCubre casos de error y timeouts\nSeñala deuda técnica encontrada\nRespeta el estilo del repo';
      $('g-tone').value = 'Directo, técnico, sin relleno';
      build();
    });
    $('g-copy').addEventListener('click', async () => {
      const txt = $('g-out').textContent;
      try {
        await navigator.clipboard.writeText(txt);
        $('g-copied').textContent = '✓ Copiado al portapapeles';
      } catch {
        const ta = document.createElement('textarea');
        ta.value = txt;
        document.body.appendChild(ta);
        ta.select();
        document.execCommand('copy');
        ta.remove();
        $('g-copied').textContent = '✓ Copiado';
      }
      setTimeout(() => ($('g-copied').textContent = ''), 2200);
    });
  }

  function viewGlossary() {
    const letters = [...new Set(GLOSSARY.map((g) => g.term[0].toUpperCase()))].sort();
    app.innerHTML = `<div class="view-fade">
      <div class="view-header">
        <div class="eyebrow">Diccionario · ${GLOSSARY.length} términos</div>
        <h1>Glosario Gentle-Vanguard</h1>
        <p class="desc">Términos técnicos, de IA y de negocio que usa el stack — qué es, por qué existe y dónde vive.</p>
      </div>
      <div class="gloss-filters" id="gloss-filters">
        <button class="on" data-l="*">Todos</button>
        ${letters.map((l) => `<button data-l="${l}">${l}</button>`).join('')}
      </div>
      <div class="gloss-grid" id="gloss-grid"></div></div>`;
    const grid = document.getElementById('gloss-grid');
    const draw = (letter) => {
      grid.innerHTML = GLOSSARY.filter((g) => letter === '*' || g.term[0].toUpperCase() === letter)
        .map(
          (g) =>
            `<div class="gloss-card"><span class="term">${g.term}</span><span class="cat">${g.cat}</span><div class="def">${esc(g.def)}</div></div>`,
        )
        .join('');
      bindEffects();
    };
    draw('*');
    document.getElementById('gloss-filters').addEventListener('click', (e) => {
      const btn = e.target.closest('button');
      if (!btn) return;
      document.querySelectorAll('#gloss-filters button').forEach((b) => b.classList.remove('on'));
      btn.classList.add('on');
      draw(btn.dataset.l);
    });
  }

  function viewNotFound() {
    app.innerHTML = `<div class="view-header"><h1>No encontrado</h1>
      <p class="desc">Esa ruta no existe. <a href="#/" style="color:var(--gv-cyan)">Volver al inicio</a>.</p></div>`;
  }

  /* ---------- Router ---------- */
  function route() {
    const hash = location.hash.replace(/^#/, '') || '/';
    const parts = hash.split('/').filter(Boolean);
    document.querySelectorAll('#main-nav a').forEach((a) => a.classList.remove('active'));
    window.scrollTo(0, 0);
    if (parts.length === 0) {
      viewHome();
      setActive('home');
    } else if (parts[0] === 'track' && parts[1]) {
      viewTrack(parts[1]);
      setActive(parts[1]);
    } else if (parts[0] === 'lesson' && parts[2]) {
      viewLesson(parts[1], parts[2]);
      setActive(parts[1]);
    } else if (parts[0] === 'glosario') {
      viewGlossary();
      setActive('glosario');
    } else if (parts[0] === 'demo') {
      viewDemo();
      setActive('demo');
    } else if (parts[0] === 'generador') {
      viewGenerator();
      setActive('generador');
    } else viewNotFound();
    bindEffects();
  }
  function setActive(id) {
    const a = document.querySelector(`#main-nav a[data-route="${id}"]`);
    if (a) a.classList.add('active');
  }
  window.addEventListener('hashchange', () => {
    closeNav();
    route();
  });

  /* ---------- Mobile nav ---------- */
  const burger = document.getElementById('burger');
  const mainNav = document.getElementById('main-nav');
  function closeNav() {
    burger.classList.remove('open');
    mainNav.classList.remove('open');
  }
  burger.addEventListener('click', () => {
    burger.classList.toggle('open');
    mainNav.classList.toggle('open');
  });
  mainNav.addEventListener('click', (e) => {
    if (e.target.closest('a')) closeNav();
  });

  /* ---------- Search ---------- */
  const input = document.getElementById('search-input');
  const results = document.getElementById('search-results');
  function search(q) {
    q = q.trim().toLowerCase();
    if (q.length < 2) {
      results.style.display = 'none';
      return;
    }
    const hits = [];
    for (const t of TRACKS) {
      for (const l of (CONTENT[t.id] || {}).lessons || []) {
        if (l.title.toLowerCase().includes(q) || (l.md || '').toLowerCase().includes(q))
          hits.push({ title: l.title, sub: t.title, href: `#/lesson/${t.id}/${l.id}` });
      }
    }
    for (const g of GLOSSARY) {
      if (g.term.toLowerCase().includes(q) || g.def.toLowerCase().includes(q))
        hits.push({ title: g.term, sub: 'Glosario · ' + g.cat, href: '#/glosario' });
    }
    results.innerHTML =
      hits
        .slice(0, 12)
        .map(
          (h) =>
            `<div class="sr-item" onclick="location.hash='${h.href.slice(1)}';document.getElementById('search-results').style.display='none'">
        <div class="sr-title">${esc(h.title)}</div><div class="sr-sub">${esc(h.sub)}</div></div>`,
        )
        .join('') || '<div class="sr-item"><div class="sr-sub">Sin resultados</div></div>';
    results.style.display = 'block';
  }
  input.addEventListener('input', () => search(input.value));
  document.addEventListener('keydown', (e) => {
    if (e.key === '/' && document.activeElement !== input) {
      e.preventDefault();
      input.focus();
    }
    if (e.key === 'Escape') {
      results.style.display = 'none';
      input.blur();
    }
  });
  document.addEventListener('click', (e) => {
    if (!e.target.closest('.search-box') && !e.target.closest('#search-results'))
      results.style.display = 'none';
  });

  /* ---------- Language switcher ---------- */
  const langSwitch = document.getElementById('lang-switch');
  function applyStaticLang() {
    document.querySelectorAll('#main-nav a').forEach(a => {
      const route = a.dataset.route;
      if (route) a.textContent = t('nav.' + route);
    });
    input.placeholder = t('search.placeholder');
    document.getElementById('modal-close').textContent = t('modal.close');
    document.querySelectorAll('#lang-switch button').forEach(b =>
      b.classList.toggle('on', b.dataset.lang === LANG));
  }
  langSwitch.addEventListener('click', (e) => {
    const b = e.target.closest('button'); if (!b) return;
    LANG = b.dataset.lang;
    localStorage.setItem('gv_academy_lang', LANG);
    applyStaticLang();
    route();
  });
  applyStaticLang();

  route();
})();
