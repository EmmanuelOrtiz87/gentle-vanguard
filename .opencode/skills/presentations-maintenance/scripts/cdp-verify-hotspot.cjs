// cdp-verify-hotspot.cjs — verifica click en hotspot SVG → modal info multi-idioma
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

  console.log('=== HOTSPOT SVG → MODAL INFO (architecture.html) ===');
  const res = await ev(`(async function(){
    var img = document.querySelector('.svg-diagram');
    if (!img) return { error: 'no .svg-diagram' };
    img.click();
    await new Promise(r => setTimeout(r, 1200));
    var svgBox = document.querySelector('.gv-lightbox-svg');
    if (!svgBox || svgBox.hidden) return { error: 'svg no inline', svgHidden: svgBox ? svgBox.hidden : 'missing' };
    var hot = svgBox.querySelector('.gv-hotspot');
    if (!hot) return { error: 'no gv-hotspot en svg inline', hotspots: svgBox.querySelectorAll('.gv-hotspot').length };
    // Simular click real en el hotspot
    var rect = hot.getBoundingClientRect();
    var cx = rect.left + rect.width/2, cy = rect.top + rect.height/2;
    hot.dispatchEvent(new MouseEvent('click', { bubbles: true, clientX: cx, clientY: cy }));
    await new Promise(r => setTimeout(r, 400));
    var modal = document.querySelector('.gv-info-modal');
    var body = modal.querySelector('.gv-info-body');
    return {
      hotspots: svgBox.querySelectorAll('.gv-hotspot').length,
      modalOpen: modal.classList.contains('open'),
      tipKey: hot.getAttribute('data-i18n-title'),
      bodyStart: (body.textContent || '').trim().slice(0, 90)
    };
  })()`);
  console.log(JSON.stringify(res, null, 2));

  await ev(`document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))`);
  await sleep(300);
  ws.close();
  console.log('=== FIN ===');
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
