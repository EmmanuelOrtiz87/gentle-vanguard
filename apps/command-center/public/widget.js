(() => {
  const script = document.currentScript;
  const appId = script ? script.getAttribute('data-app') || '' : '';
  if (!appId) return;
  const cc = 'http://127.0.0.1:8090';
  const names = {
    dashboard: 'Dashboard',
    analytics: 'Analytics',
    cms: 'CMS',
    academy: 'Academy',
    prompts: 'Prompts',
  };
  const style = document.createElement('style');
  style.textContent =
    '.gv-cc-widget{position:fixed;right:18px;bottom:18px;z-index:9999;border:1px solid #1e3a5f;border-radius:999px;padding:9px 13px;background:#121a2a;color:#fff;box-shadow:0 8px 24px #0008;font:600 13px Segoe UI,system-ui,sans-serif;cursor:pointer}.gv-cc-widget:disabled{opacity:.6;cursor:wait}.gv-cc-widget .gv-cc-dot{display:inline-block;width:9px;height:9px;margin-right:8px;border-radius:50%;background:#6b7280}.gv-cc-widget .gv-cc-power{margin-right:6px;color:#4dcfff}.gv-cc-widget.gv-cc-running .gv-cc-dot{background:#22c55e}.gv-cc-widget.gv-cc-partial .gv-cc-dot{background:#f59e0b}';
  document.head.appendChild(style);
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'gv-cc-widget';
  button.innerHTML =
    '<span class="gv-cc-dot"></span><span class="gv-cc-power">⏻</span><span class="gv-cc-name"></span>';
  button.querySelector('.gv-cc-name').textContent = names[appId] || appId;
  document.body.appendChild(button);
  let current = 'stopped';
  const update = (app) => {
    current = app ? app.status : 'stopped';
    button.classList.toggle('gv-cc-running', current === 'running');
    button.classList.toggle('gv-cc-partial', current === 'partial');
    button.title = app
      ? app.processes
          .map(
            (p) =>
              `${p.name}: ${p.alive ? `PID ${p.pid || '—'} · puerto ${p.port}` : `puerto ${p.port} · detenido`}`,
          )
          .join('\n')
      : 'Command Center no disponible';
    button.setAttribute(
      'aria-label',
      `${current === 'running' ? 'Detener' : 'Iniciar'} ${names[appId] || appId}`,
    );
  };
  const poll = async () => {
    try {
      const response = await fetch(`${cc}/api/apps`);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      update((await response.json()).find((app) => app.id === appId));
    } catch (error) {
      update(null);
      console.warn('[GV CC widget] Command Center no disponible', error);
    }
  };
  button.addEventListener('click', async () => {
    if (current === 'running' && !confirm('¿Detener esta aplicación?')) return;
    button.disabled = true;
    try {
      const response = await fetch(
        `${cc}/api/apps/${encodeURIComponent(appId)}/${current === 'running' ? 'stop' : 'start'}`,
        { method: 'POST' },
      );
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      update(await response.json());
    } catch (error) {
      console.warn('[GV CC widget] No se pudo cambiar el estado', error);
      await poll();
    } finally {
      button.disabled = false;
    }
  });
  update(null);
  void poll();
  setInterval(() => void poll(), 5000);
})();
