/**
 * cdp-verify-page.js — Verificación genérica en Chrome real (CDP) de info-triggers y modales
 * en cualquier página de docs/presentations/.
 *
 * Checks:
 *   1. Info-triggers presentes y todos con data-i18n-title
 *   2. Modal abre con texto (EN)
 *   3. Modal en ES (traducción activa, no fallback)
 *   4. Modal en pt-BR (traducción activa)
 *
 * Uso:
 *   node .opencode/skills/presentations-maintenance/scripts/cdp-verify-page.js
 *     [--cdp 9225] [--origin http://localhost:8899] [--page=health.html]
 *
 * NOTA: usar SIEMPRE --page=<archivo> (con signo igual). El script usa startsWith('--page=').
 *
 * Requiere: Chrome con --remote-debugging-port=<cdp> + servidor de docs/presentations/
 * (npm run presentations:serve -- --port 8899 --no-browser o gv-probe/serve.js).
 */
const WebSocket = require('ws');

const args = process.argv.slice(2);
const cdpPort = parseInt(args.find((a) => a.startsWith('--cdp='))?.split('=')[1] ?? '9225', 10);
const origin = args.find((a) => a.startsWith('--origin='))?.split('=')[1] ?? 'http://localhost:8899';
const page = args.find((a) => a.startsWith('--page='))?.split('=')[1] ?? 'health.html';

(async () => {
  const tabs = await (await fetch(`http://localhost:${cdpPort}/json`)).json().catch(() => []);
  let tab = tabs.find((t) => t.type === 'page');
  if (!tab) { console.log('FAIL: CDP no disponible'); process.exit(1); }
  const ws = new WebSocket(tab.webSocketDebuggerUrl);
  let id = 0;
  const pending = new Map();
  const send = (method, params = {}) => new Promise((res, rej) => {
    const mid = ++id;
    pending.set(mid, { res, rej });
    ws.send(JSON.stringify({ id: mid, method, params }));
  });
  ws.on('message', (d) => {
    const m = JSON.parse(d.toString());
    if (m.id && pending.has(m.id)) {
      const p = pending.get(m.id);
      pending.delete(m.id);
      m.error ? p.rej(new Error(m.error.message)) : p.res(m.result);
    }
  });
  await new Promise((r, j) => { ws.on('open', r); ws.on('error', j); });
  await send('Runtime.enable');
  await send('Page.enable');
  const ev = (expr) => send('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true })
    .then((r) => r.exceptionDetails ? 'EXCEPTION: ' + (r.exceptionDetails.exception?.description || '').slice(0, 200) : r.result?.value);
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  await send('Page.navigate', { url: `${origin}/${page}?ts=${Date.now()}` });
  await sleep(2500);

  console.log(`=== VERIFICACIÓN ${page} ===`);
  const stats = await ev(`(function(){
    var triggers = document.querySelectorAll('.info-trigger').length;
    var noTitle = Array.from(document.querySelectorAll('.info-trigger')).filter(t => !t.dataset.i18nTitle).length;
    var tables = document.querySelectorAll('table').length;
    var lang = document.querySelector('.lang-seg') ? 'ok' : 'missing';
    return { triggers, noTitle, tables, lang };
  })()`);
  console.log('  Stats: ' + JSON.stringify(stats));

  const modal = await ev(`(function(){
    var t = document.querySelector('.info-trigger');
    if (!t) return 'no triggers';
    var title = t.dataset.i18nTitle || t.getAttribute('title') || '';
    t.click();
    var box = document.querySelector('.gv-info-box');
    if (!box) return { title, open: false };
    var body = box.querySelector('.gv-info-body');
    return { title, open: box.closest('.gv-info-modal').classList.contains('open'),
             bodyStart: (body.textContent || '').trim().slice(0, 90) };
  })()`);
  console.log('  Modal EN: ' + JSON.stringify(modal));
  await ev(`document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))`);

  // Traducción ES
  const es = await ev(`(function(){
    window.__i18n.translate('es');
    var t = document.querySelector('.info-trigger');
    t.click();
    var box = document.querySelector('.gv-info-box');
    var body = box.querySelector('.gv-info-body');
    var out = { bodyStart: (body.textContent || '').trim().slice(0, 90) };
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    return out;
  })()`);
  console.log('  Modal ES: ' + JSON.stringify(es));

  // Traducción pt-BR
  const pt = await ev(`(function(){
    window.__i18n.translate('pt-BR');
    var t = document.querySelector('.info-trigger');
    t.click();
    var box = document.querySelector('.gv-info-box');
    var body = box.querySelector('.gv-info-body');
    var out = { bodyStart: (body.textContent || '').trim().slice(0, 90) };
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    return out;
  })()`);
  console.log('  Modal PT: ' + JSON.stringify(pt));

  await ev(`window.__i18n.translate('en')`);
  ws.close();
  console.log('=== FIN ===');
})().catch((e) => { console.error('ERROR:', e.message); process.exit(1); });
