// cdp-verify-hotspot-multilang.cjs — verifica hotspot SVG → modal info en los 3 idiomas
const WebSocket = require('ws');
const args = process.argv.slice(2);
const cdpPort = parseInt(args.find(a => a.startsWith('--cdp='))?.split('=')[1] ?? '9225', 10);
const origin = args.find(a => a.startsWith('--origin='))?.split('=')[1] ?? 'http://localhost:8899';

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
    .then(r => r.exceptionDetails ? 'EXCEPTION: ' + (r.exceptionDetails.exception?.description || '').slice(0, 300) : r.result?.value);
  const sleep = ms => new Promise(r => setTimeout(r, ms));

  await send('Page.navigate', { url: `${origin}/architecture.html?ts=${Date.now()}` });
  await sleep(3000);

  // Abre lightbox + click en primer hotspot, devuelve texto del modal
  const openAndRead = `(async function(){
    document.querySelector('.svg-diagram').click();
    await new Promise(r => setTimeout(r, 1200));
    var hot = document.querySelector('.gv-lightbox-svg .gv-hotspot');
    var rect = hot.getBoundingClientRect();
    hot.dispatchEvent(new MouseEvent('click', { bubbles: true, clientX: rect.left+rect.width/2, clientY: rect.top+rect.height/2 }));
    await new Promise(r => setTimeout(r, 400));
    var modal = document.querySelector('.gv-info-modal');
    return {
      lang: document.documentElement.getAttribute('lang'),
      modalOpen: modal.classList.contains('open'),
      body: (modal.querySelector('.gv-info-body').textContent || '').trim().slice(0, 80)
    };
  })()`;
  const closeModal = `document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true })); true`;
  const switchLang = (lang) => `(function(){ var b = document.querySelector('[data-lang="${lang}"]'); if (b) b.click(); return !!b; })()`;

  console.log('=== HOTSPOT SVG → MODAL × 3 IDIOMAS ===');
  let r = await ev(openAndRead); console.log(`EN   lang=${r.lang} modal=${r.modalOpen} -> ${r.body}`);
  await ev(closeModal); await sleep(300);
  await ev(switchLang('es')); await sleep(600);
  r = await ev(openAndRead); console.log(`ES   lang=${r.lang} modal=${r.modalOpen} -> ${r.body}`);
  await ev(closeModal); await sleep(300);
  await ev(switchLang('pt-BR')); await sleep(600);
  r = await ev(openAndRead); console.log(`PT   lang=${r.lang} modal=${r.modalOpen} -> ${r.body}`);
  await ev(closeModal); await sleep(300);

  ws.close();
  console.log('=== FIN ===');
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
