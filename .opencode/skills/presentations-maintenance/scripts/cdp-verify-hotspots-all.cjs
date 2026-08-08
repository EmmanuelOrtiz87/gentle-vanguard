// cdp-verify-hotspots-all.cjs — verifica un hotspot por diagrama (4 SVG) en los 3 idiomas
// Páginas: autonomy.html (executive-loop), agents-pipeline.html (pipeline-flow),
//          operations-cloud.html (data-architecture), dashboard.html (stack-dashboard)
const WebSocket = require('ws');
const args = process.argv.slice(2);
const cdpPort = parseInt(args.find(a => a.startsWith('--cdp='))?.split('=')[1] ?? '9225', 10);
const origin = args.find(a => a.startsWith('--origin='))?.split('=')[1] ?? 'http://localhost:8899';

const CASES = [
  { page: 'autonomy.html',         hotspot: 'tip_hs_loop_detection',  expectEn: 'Detection' },
  { page: 'agents-pipeline.html',  hotspot: 'tip_hs_flow_phase1',     expectEn: 'Phase 1' },
  { page: 'operations-cloud.html', hotspot: 'tip_hs_data_nexus',      expectEn: 'NEXUS DB' },
  { page: 'dashboard.html',        hotspot: 'tip_hs_dash_sources',    expectEn: 'Data Sources' }
];

(async () => {
  const tabs = await (await fetch(`http://localhost:${cdpPort}/json`)).json().catch(() => []);
  let tab = tabs.find(t => t.type === 'page');
  if (!tab) { console.log('FAIL: CDP no disponible'); process.exit(1); }
  const ws = new WebSocket(tab.webSocketDebuggerUrl);
  let id = 0; const pending = new Map();
  const send = (method, params = {}) => new Promise((res, rej) => {
    const mid = ++id; pending.set(mid, { res, rej });
    ws.send(JSON.stringify({ id: mid, method, params }));
  });
  ws.on('message', (d) => { const m = JSON.parse(d.toString());
    if (m.id && pending.has(m.id)) { const p = pending.get(m.id); pending.delete(m.id);
      m.error ? p.rej(new Error(m.error.message)) : p.res(m.result); } });
  await new Promise((r, j) => { ws.on('open', r); ws.on('error', j); });
  await send('Runtime.enable'); await send('Page.enable');
  const ev = (expr) => send('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true })
    .then(r => {
      if (r.exceptionDetails) return { error: (r.exceptionDetails.exception?.description || r.exceptionDetails.text || '').slice(0, 300) };
      return r.result?.value;
    });
  const sleep = ms => new Promise(r => setTimeout(r, ms));

  const openHotspot = (selector) => `(async function(){
    try {
      var img = document.querySelector('.svg-diagram');
      if (!img) return { error: 'no .svg-diagram' };
      img.click();
      await new Promise(r => setTimeout(r, 1300));
      var svgBox = document.querySelector('.gv-lightbox-svg');
      if (!svgBox) return { error: 'no .gv-lightbox-svg' };
      if (svgBox.hidden) return { error: 'svgBox hidden (fallback a img)' };
      var hot = svgBox.querySelector('.gv-hotspot[data-i18n-title="' + '${selector}' + '"]');
      if (!hot) return { error: 'no hotspot ' + selector, hotspots: svgBox.querySelectorAll('.gv-hotspot').length };
      var rect = hot.getBoundingClientRect();
      hot.dispatchEvent(new MouseEvent('click', { bubbles: true, clientX: rect.left+rect.width/2, clientY: rect.top+rect.height/2 }));
      await new Promise(r => setTimeout(r, 450));
      var modal = document.querySelector('.gv-info-modal');
      var mopen = modal ? modal.classList.contains('open') : false;
      var body = mopen ? (modal.querySelector('.gv-info-body').textContent || '').trim().slice(0, 70) : '(closed)';
      return { lang: document.documentElement.getAttribute('lang'), modalOpen: mopen,
               hotspots: svgBox.querySelectorAll('.gv-hotspot').length, body: body };
    } catch (e) { return { error: 'JS: ' + e.message }; }
  })()`;
  const closeModal = `(function(){ document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true })); return true; })()`;
  const switchLang = (lang) => `(function(){ var b = document.querySelector('[data-lang="'+'${lang}'+'"]'); if (b) b.click(); return !!b; })()`;
  const forceLang = (lang) => `(function(){ try { localStorage.setItem('gv-lang','${lang}'); } catch(e){} var b = document.querySelector('[data-lang="'+'${lang}'+'"]'); if (b) b.click(); return true; })()`;

  let allPass = true;
  for (const c of CASES) {
    await send('Page.navigate', { url: `${origin}/${c.page}?ts=${Date.now()}` });
    await sleep(3000);
    // Forzar idioma base EN (el localStorage puede guardar es/pt de ejecuciones previas)
    await ev(forceLang('en')); await sleep(650);
    console.log(`\n=== ${c.page} -> ${c.hotspot} ===`);
    let r = await ev(openHotspot(c.hotspot));
    if (r && r.error) { console.log('  FAIL: ' + r.error); allPass = false; continue; }
    if (!r) { console.log('  FAIL: resultado vacio'); allPass = false; continue; }
    console.log(`  EN   lang=${r.lang} modal=${r.modalOpen} hotspots=${r.hotspots} -> ${r.body}`);
    const okEn = r.modalOpen && r.body.includes(c.expectEn);
    if (!okEn) { console.log('  ^ EN no esperado: falta "' + c.expectEn + '"'); allPass = false; }
    await ev(closeModal); await sleep(350);
    await ev(switchLang('es')); await sleep(650);
    r = await ev(openHotspot(c.hotspot));
    if (r && r.error) { console.log('  ES FAIL: ' + r.error); allPass = false; }
    else if (!r || !r.modalOpen) { console.log(`  ES   lang=${r && r.lang} modal=${r && r.modalOpen}`); allPass = false; }
    else console.log(`  ES   lang=${r.lang} modal=${r.modalOpen} -> ${r.body}`);
    await ev(closeModal); await sleep(350);
    await ev(switchLang('pt-BR')); await sleep(650);
    r = await ev(openHotspot(c.hotspot));
    if (r && r.error) { console.log('  PT FAIL: ' + r.error); allPass = false; }
    else if (!r || !r.modalOpen) { console.log(`  PT   lang=${r && r.lang} modal=${r && r.modalOpen}`); allPass = false; }
    else console.log(`  PT   lang=${r.lang} modal=${r.modalOpen} -> ${r.body}`);
    await ev(closeModal); await sleep(350);
  }
  ws.close();
  console.log(`\n=== RESULTADO: ${allPass ? 'ALL PASS' : 'HAY FALLOS'} ===`);
  process.exit(allPass ? 0 : 1);
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
