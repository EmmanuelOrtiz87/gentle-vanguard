/* Gentle-Vanguard Academy — vanilla SPA (hash router + markdown-subset renderer)
   No dependencies, no build, works over file:// or any static server. */
(function () {
  'use strict';

  const CONTENT = window.GV_CONTENT || {};
  const TRACKS = window.GV_TRACKS || [];
  const GLOSSARY = window.GV_GLOSSARY || [];
  const app = document.getElementById('app');
  document.getElementById('foot-year').textContent = new Date().getFullYear();

  /* ---------- Markdown subset renderer ---------- */
  function esc(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }
  function inline(s) {
    return esc(s)
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
      .replace(/==([^=]+)==/g, '<span class="kw">$1</span>');
  }
  function renderMarkdown(md) {
    const lines = md.split('\n');
    const out = [];
    let inPre = false, inList = null, tableBuf = [];
    const flushList = () => { if (inList) { out.push(inList === 'ul' ? '</ul>' : '</ol>'); inList = null; } };
    const flushTable = () => {
      if (!tableBuf.length) return;
      const rows = tableBuf.filter(r => !/^\s*\|[\s:|-]+\|\s*$/.test(r)).map(r =>
        r.trim().replace(/^\||\|$/g, '').split('|').map(c => c.trim()));
      const head = rows.shift();
      let html = '<table><thead><tr>' + head.map(h => `<th>${inline(h)}</th>`).join('') + '</tr></thead><tbody>';
      for (const r of rows) html += '<tr>' + r.map(c => `<td>${inline(c)}</td>`).join('') + '</tr>';
      out.push(html + '</tbody></table>');
      tableBuf = [];
    };
    for (const raw of lines) {
      const line = raw.replace(/\s+$/, '');
      if (line.startsWith('```')) {
        if (inPre) { out.push('</code></pre>'); inPre = false; }
        else { flushList(); flushTable(); out.push('<pre><code>'); inPre = true; }
        continue;
      }
      if (inPre) { out.push(esc(raw)); continue; }
      if (/^\s*\|.*\|\s*$/.test(line)) { flushList(); tableBuf.push(line); continue; }
      flushTable();
      if (/^###\s+/.test(line)) { flushList(); out.push(`<h3>${inline(line.slice(4))}</h3>`); continue; }
      if (/^##\s+/.test(line)) { flushList(); out.push(`<h2>${inline(line.slice(3))}</h2>`); continue; }
      if (/^>\s?/.test(line)) { flushList(); out.push(`<blockquote>${inline(line.replace(/^>\s?/, ''))}</blockquote>`); continue; }
      if (/^---+$/.test(line)) { flushList(); out.push('<hr>'); continue; }
      const ul = /^\s*[-*]\s+(.*)$/.exec(line);
      if (ul) {
        if (inList !== 'ul') { flushList(); out.push('<ul>'); inList = 'ul'; }
        out.push(`<li>${inline(ul[1])}</li>`); continue;
      }
      const ol = /^\s*\d+\.\s+(.*)$/.exec(line);
      if (ol) {
        if (inList !== 'ol') { flushList(); out.push('<ol>'); inList = 'ol'; }
        out.push(`<li>${inline(ol[1])}</li>`); continue;
      }
      if (!line.trim()) { flushList(); continue; }
      flushList();
      out.push(`<p>${inline(line)}</p>`);
    }
    flushList(); flushTable();
    if (inPre) out.push('</code></pre>');
    return out.join('\n');
  }

  /* ---------- Views ---------- */
  function badgeClass(t) {
    if (t === 'laboratorio') return 'badge badge-lab';
    if (t === 'referencia') return 'badge badge-ref';
    return 'badge badge-course';
  }

  function viewHome() {
    const cards = TRACKS.map(t => {
      const lessons = (CONTENT[t.id] || { lessons: [] }).lessons.length;
      const mins = ((CONTENT[t.id] || { lessons: [] }).lessons || []).reduce((a, l) => a + (l.minutes || 6), 0);
      return `<a class="track-card" href="#/track/${t.id}">
        <div class="badge-row"><span class="${badgeClass(t.type)}">${t.type}</span></div>
        <h3>${t.title}</h3>
        <p>${t.desc}</p>
        <div class="meta">${lessons} lecciones · ~${mins} min</div>
      </a>`;
    }).join('');
    app.innerHTML = `
      <section class="hero">
        <h1>Aprende a operar el stack que hace que<br><span class="g">tu IA trabaje con ingeniería</span></h1>
        <p>Fundamentos, arquitectura, optimización, agentes, workflows y negocio — todo Gentle-Vanguard explicado desde cero, con laboratorios prácticos y el glosario completo. 100% local.</p>
        <div class="hero-ctas">
          <a class="btn btn-primary" href="#/track/fundamentos">Comenzar por los fundamentos</a>
          <a class="btn btn-ghost" href="#/glosario">Explorar el glosario</a>
        </div>
      </section>
      <h2 class="section-title">Rutas de aprendizaje</h2>
      <p class="section-sub">Cada track es autónomo; el orden sugerido es el orden de la lista.</p>
      <div class="tracks-grid">${cards}</div>`;
  }

  function viewTrack(id) {
    const track = TRACKS.find(t => t.id === id);
    const data = CONTENT[id];
    if (!track || !data) { viewNotFound(); return; }
    const rows = data.lessons.map((l, i) => `
      <a class="lesson-row" href="#/lesson/${id}/${l.id}">
        <span class="num">${String(i + 1).padStart(2, '0')}</span>
        <span class="lt">${l.title}</span>
        <span class="ld">${l.minutes || 6} min</span>
      </a>`).join('');
    app.innerHTML = `
      <div class="view-header">
        <div class="eyebrow">${track.type === 'laboratorio' ? 'Laboratorio' : track.type === 'referencia' ? 'Referencia' : 'Curso'} · ${data.lessons.length} lecciones</div>
        <h1>${track.title}</h1>
        <p class="desc">${track.desc}</p>
      </div>
      <div class="lesson-list">${rows}</div>`;
  }

  function viewLesson(trackId, lessonId) {
    const track = TRACKS.find(t => t.id === trackId);
    const data = CONTENT[trackId];
    if (!track || !data) { viewNotFound(); return; }
    const idx = data.lessons.findIndex(l => l.id === lessonId);
    if (idx < 0) { viewLesson(trackId, data.lessons[0].id); return; }
    const lesson = data.lessons[idx];
    const nav = data.lessons.map((l, i) =>
      `<a href="#/lesson/${trackId}/${l.id}" class="${i === idx ? 'active' : ''}">${String(i + 1).padStart(2, '0')} · ${l.title}</a>`).join('');
    const prev = data.lessons[idx - 1];
    const next = data.lessons[idx + 1];
    app.innerHTML = `
      <div class="view-header" style="margin-bottom:18px">
        <div class="eyebrow"><a href="#/track/${trackId}" style="color:inherit;text-decoration:none">${track.title}</a> · lección ${idx + 1} de ${data.lessons.length} · ${lesson.minutes || 6} min</div>
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
      </div>`;
  }

  function viewGlossary() {
    const letters = [...new Set(GLOSSARY.map(g => g.term[0].toUpperCase()))].sort();
    app.innerHTML = `
      <div class="view-header">
        <div class="eyebrow">Diccionario · ${GLOSSARY.length} términos</div>
        <h1>Glosario Gentle-Vanguard</h1>
        <p class="desc">Términos técnicos, de IA y de negocio que usa el stack — qué es, por qué existe y dónde vive en Gentle-Vanguard.</p>
      </div>
      <div class="gloss-filters" id="gloss-filters">
        <button class="on" data-l="*">Todos</button>
        ${letters.map(l => `<button data-l="${l}">${l}</button>`).join('')}
      </div>
      <div class="gloss-grid" id="gloss-grid"></div>`;
    const grid = document.getElementById('gloss-grid');
    const draw = (letter) => {
      grid.innerHTML = GLOSSARY
        .filter(g => letter === '*' || g.term[0].toUpperCase() === letter)
        .map(g => `<div class="gloss-card"><span class="term">${g.term}</span><span class="cat">${g.cat}</span><div class="def">${esc(g.def)}</div></div>`)
        .join('');
    };
    draw('*');
    document.getElementById('gloss-filters').addEventListener('click', (e) => {
      const btn = e.target.closest('button'); if (!btn) return;
      document.querySelectorAll('#gloss-filters button').forEach(b => b.classList.remove('on'));
      btn.classList.add('on'); draw(btn.dataset.l);
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
    document.querySelectorAll('#main-nav a').forEach(a => a.classList.remove('active'));
    window.scrollTo(0, 0);
    if (parts.length === 0) { viewHome(); setActive('home'); }
    else if (parts[0] === 'track' && parts[1]) { viewTrack(parts[1]); setActive(parts[1]); }
    else if (parts[0] === 'lesson' && parts[2]) { viewLesson(parts[1], parts[2]); setActive(parts[1]); }
    else if (parts[0] === 'glosario') { viewGlossary(); setActive('glosario'); }
    else viewNotFound();
  }
  function setActive(id) {
    const a = document.querySelector(`#main-nav a[data-route="${id}"]`);
    if (a) a.classList.add('active');
  }
  window.addEventListener('hashchange', route);

  /* ---------- Search (lessons + glossary) ---------- */
  const input = document.getElementById('search-input');
  const results = document.getElementById('search-results');
  function search(q) {
    q = q.trim().toLowerCase();
    if (q.length < 2) { results.style.display = 'none'; return; }
    const hits = [];
    for (const t of TRACKS) {
      for (const l of ((CONTENT[t.id] || {}).lessons || [])) {
        if (l.title.toLowerCase().includes(q) || (l.md || '').toLowerCase().includes(q))
          hits.push({ title: l.title, sub: t.title, href: `#/lesson/${t.id}/${l.id}` });
      }
    }
    for (const g of GLOSSARY) {
      if (g.term.toLowerCase().includes(q) || g.def.toLowerCase().includes(q))
        hits.push({ title: g.term, sub: 'Glosario · ' + g.cat, href: '#/glosario' });
    }
    results.innerHTML = hits.slice(0, 12).map(h =>
      `<div class="sr-item" onclick="location.hash='${h.href.slice(1)}';document.getElementById('search-results').style.display='none'">
        <div class="sr-title">${esc(h.title)}</div><div class="sr-sub">${esc(h.sub)}</div></div>`).join('')
      || '<div class="sr-item"><div class="sr-sub">Sin resultados</div></div>';
    results.style.display = 'block';
  }
  input.addEventListener('input', () => search(input.value));
  document.addEventListener('keydown', (e) => {
    if (e.key === '/' && document.activeElement !== input) { e.preventDefault(); input.focus(); }
    if (e.key === 'Escape') { results.style.display = 'none'; input.blur(); }
  });
  document.addEventListener('click', (e) => {
    if (!e.target.closest('.search-box') && !e.target.closest('#search-results')) results.style.display = 'none';
  });

  route();
})();
