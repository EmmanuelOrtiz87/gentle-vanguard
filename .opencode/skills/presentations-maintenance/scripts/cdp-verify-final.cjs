/**
 * cdp-verify-final.js — Verificación en Chrome real (CDP) de la home de presentaciones.
 *
 * Checks:
 *   1. Icono Layer 4 (bi-book presente, bi-brain ausente)
 *   2. Info-triggers por sección (conteos esperados)
 *   3. Modal info: click en trigger -> texto traducido (en)
 *   4. Cambio de idioma a es/pt-BR -> modal muestra texto traducido
 *   5. Lightbox: abrir diagrama -> centrado (tx/ty/scale correctos matemáticamente)
 *
 * Uso:
 *   node .opencode/skills/presentations-maintenance/scripts/cdp-verify-final.js
 *     [--cdp 9225] [--origin http://localhost:8899] [--page index.html]
 *
 * Requiere: Chrome corriendo con --remote-debugging-port=<cdp> y un servidor sirviendo
 * docs/presentations/ (npm run presentations:serve -- --port 8899 --no-browser o gv-probe/serve.js).
 */
const WebSocket = require('ws');

const args = process.argv.slice(2);
const cdpPort = parseInt(args.find((a) => a.startsWith('--cdp='))?.split('=')[1] ?? '9225', 10);
const origin = args.find((a) => a.startsWith('--origin='))?.split('=')[1] ?? 'http://localhost:8899';
const page = args.find((a) => a.startsWith('--page='))?.split('=')[1] ?? 'index.html';

async function main() {
  const tabs = await (await fetch(`http://localhost:${cdpPort}/json`)).json().catch(() => []);
  let tab = tabs.find((t) => t.url.includes('localhost') || t.type === 'page');
  if (!tab) {
    console.log(`FAIL: Chrome CDP no está corriendo en :${cdpPort}. Relánzalo primero.`);
    process.exit(1);
  }

  const ws = new WebSocket(tab.webSocketDebuggerUrl);
  let id = 0;
  const pending = new Map();
  function send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const msgId = ++id;
      pending.set(msgId, { resolve, reject });
      ws.send(JSON.stringify({ id: msgId, method, params }));
    });
  }
  ws.on('message', (data) => {
    const msg = JSON.parse(data.toString());
    if (msg.id && pending.has(msg.id)) {
      const p = pending.get(msg.id);
      pending.delete(msg.id);
      if (msg.error) p.reject(new Error(msg.error.message));
      else p.resolve(msg.result);
    }
  });
  await new Promise((resolve, reject) => { ws.on('open', resolve); ws.on('error', reject); });
  await send('Runtime.enable');
  await send('Page.enable');

  async function evalJs(expr) {
    const r = await send('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true });
    if (r.exceptionDetails) return 'EXCEPTION: ' + (r.exceptionDetails.exception?.description || r.exceptionDetails.text || '').slice(0, 300);
    return r.result?.value;
  }
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  await send('Page.navigate', { url: `${origin}/${page}?ts=${Date.now()}` });
  await sleep(3000);

  console.log('=== 1. ICONO LAYER 4 ===');
  const layer4 = await evalJs(`(function(){
    var names = Array.from(document.querySelectorAll('.arch-layer .layer-name'));
    var l4 = names.find(n => n.textContent.includes('Layer 4'));
    if (!l4) return 'Layer 4 NO encontrado';
    var html = l4.innerHTML;
    return { hasBrain: html.includes('bi-brain'), hasBook: html.includes('bi-book') };
  })()`);
  console.log('  ' + JSON.stringify(layer4));

  console.log('\n=== 2. INFO-TRIGGERS POR SECCIÓN ===');
  const counts = await evalJs(`(function(){
    function countIn(sectionId) {
      var sec = document.getElementById(sectionId);
      if (!sec) return -1;
      return sec.querySelectorAll('.info-trigger').length;
    }
    return {
      components: countIn('components'), autonomy: countIn('autonomy'), data: countIn('data'),
      executive: countIn('executive'), features: countIn('features'), skills: countIn('skills'),
      metrics: countIn('metrics'),
    };
  })()`);
  console.log('  ' + JSON.stringify(counts));

  console.log('\n=== 3. MODAL INFO (idioma EN) ===');
  const modalEn = await evalJs(`(function(){
    var trigger = document.querySelector('#executive .info-trigger');
    trigger.click();
    var box = document.querySelector('.gv-info-box');
    var body = box.querySelector('.gv-info-body').textContent.trim();
    return { open: box.closest('.gv-info-modal').classList.contains('open'), bodyStart: body.slice(0, 80) };
  })()`);
  console.log('  ' + JSON.stringify(modalEn));
  await evalJs(`document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))`);
  await sleep(200);

  console.log('\n=== 4. MODAL INFO EN IDIOMA ES ===');
  const esRes = await evalJs(`(function(){
    window.__i18n.translate('es');
    var trigger = document.querySelector('#executive .info-trigger');
    trigger.click();
    var box = document.querySelector('.gv-info-box');
    var body = box.querySelector('.gv-info-body').textContent.trim();
    return { bodyStart: body.slice(0, 80) };
  })()`);
  console.log('  ' + JSON.stringify(esRes));
  await evalJs(`document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))`);
  await sleep(200);

  console.log('\n=== 5. MODAL INFO EN IDIOMA PT-BR (Matriz) ===');
  const ptRes = await evalJs(`(function(){
    window.__i18n.translate('pt-BR');
    var trigger = document.querySelector('#features .info-trigger');
    trigger.click();
    var box = document.querySelector('.gv-info-box');
    var body = box.querySelector('.gv-info-body').textContent.trim();
    return { bodyStart: body.slice(0, 80) };
  })()`);
  console.log('  ' + JSON.stringify(ptRes));
  await evalJs(`document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))`);
  await sleep(200);

  console.log('\n=== 6. LIGHTBOX CENTRADO ===');
  const lbox = await evalJs(`(function(){
    var img = document.querySelector('#diagrams .svg-diagram');
    img.click();
    var lightImg = document.querySelector('.gv-lightbox-img');
    var stage = document.querySelector('.gv-lightbox-stage');
    var sw = stage.clientWidth, sh = stage.clientHeight;
    var iw = lightImg.naturalWidth, ih = lightImg.naturalHeight;
    return { stageW: sw, stageH: sh, natW: iw, natH: ih, transform: lightImg.style.transform,
             open: document.querySelector('.gv-lightbox').classList.contains('open') };
  })()`);
  console.log('  ' + JSON.stringify(lbox));
  if (lbox && lbox.natW && lbox.transform) {
    const m = lbox.transform.match(/translate\(([-\d.]+)px, ([-\d.]+)px\) scale\(([-\d.]+)\)/);
    if (m) {
      const tx = parseFloat(m[1]), ty = parseFloat(m[2]), s = parseFloat(m[3]);
      const sw = lbox.stageW, sh = lbox.stageH, iw = lbox.natW, ih = lbox.natH;
      const expectedS = Math.min(sw / iw, sh / ih, 1);
      const expectedTx = (sw - iw * expectedS) / 2;
      const expectedTy = (sh - ih * expectedS) / 2;
      const okScale = Math.abs(s - expectedS) < 0.01;
      const okTx = Math.abs(tx - expectedTx) < 1;
      const okTy = Math.abs(ty - expectedTy) < 1;
      console.log(`  scale ${s.toFixed(3)} vs ${expectedS.toFixed(3)} -> ${okScale ? 'OK' : 'FAIL'}`);
      console.log(`  tx ${tx.toFixed(1)} vs ${expectedTx.toFixed(1)} -> ${okTx ? 'OK' : 'FAIL'}`);
      console.log(`  ty ${ty.toFixed(1)} vs ${expectedTy.toFixed(1)} -> ${okTy ? 'OK' : 'FAIL'}`);
      console.log(`  RESULTADO: ${okScale && okTx && okTy ? 'CENTRADO CORRECTAMENTE' : 'NO CENTRADO'}`);
    } else {
      console.log('  transform no matchea patrón esperado');
    }
  }
  await evalJs(`document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))`);
  await sleep(200);

  await evalJs(`window.__i18n.translate('en')`);
  ws.close();
  console.log('\n=== FIN VERIFICACIÓN ===');
}

main().catch((e) => { console.error('ERROR:', e.message); process.exit(1); });
