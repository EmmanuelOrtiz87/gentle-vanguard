// cdp-verify-svg.cjs — verifica lightbox SVG inline + hotspots en Chrome real
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

  await send('Page.navigate', { url: `${origin}/index.html?ts=${Date.now()}` });
  await sleep(3000);

  console.log('=== LIGHTBOX SVG INLINE ===');
  const res = await ev(`(async function(){
    var img = document.querySelector('#diagrams .svg-diagram');
    if (!img) return { error: 'no .svg-diagram en #diagrams' };
    img.click();
    await new Promise(r => setTimeout(r, 1500));
    var lbox = document.querySelector('.gv-lightbox');
    var svgBox = document.querySelector('.gv-lightbox-svg');
    var lightImg = document.querySelector('.gv-lightbox-img');
    return {
      open: lbox.classList.contains('open'),
      svgHidden: svgBox ? svgBox.hidden : 'no-svgbox',
      imgHidden: lightImg ? lightImg.hidden : 'no-img',
      svgNodes: svgBox && !svgBox.hidden ? svgBox.querySelectorAll('.gv-node').length : 0,
      svgHotspots: svgBox && !svgBox.hidden ? svgBox.querySelectorAll('.gv-hotspot').length : 0,
      svgHasViewBox: svgBox && !svgBox.hidden ? !!svgBox.querySelector('svg[viewBox]') : false,
      transform: (svgBox && !svgBox.hidden ? svgBox : lightImg).style.transform,
      cap: document.querySelector('.gv-lightbox-cap').textContent
    };
  })()`);
  console.log(JSON.stringify(res, null, 2));

  // Escapar
  await ev(`document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))`);
  await sleep(300);
  ws.close();
  console.log('=== FIN ===');
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
