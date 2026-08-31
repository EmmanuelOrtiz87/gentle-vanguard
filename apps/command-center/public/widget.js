(() => {
  const script = document.currentScript;
  const appId = script ? script.getAttribute('data-app') || '' : '';
  if (!appId) return;
  const cc = 'http://127.0.0.1:8090';
  const lang = localStorage.getItem('gv-cc-lang') === 'en' ? 'en' : 'es';
  const I18N = {
    es: {
      start: 'Iniciar',
      stop: 'Detener',
      confirm: '¿Seguro? Click de nuevo',
      unavailable: 'Command Center no disponible',
      stopped: 'detenido',
      error: 'No se pudo cambiar el estado',
    },
    en: {
      start: 'Start',
      stop: 'Stop',
      confirm: 'Sure? Click again',
      unavailable: 'Command Center unavailable',
      stopped: 'stopped',
      error: 'Could not change state',
    },
  };
  const t = (key) => I18N[lang][key];
  const names = {
    dashboard: 'Dashboard',
    analytics: 'Analytics',
    cms: 'CMS',
    academy: 'Academy',
    prompts: 'Prompts',
  };
  const style = document.createElement('style');
  style.textContent =
    '.gv-cc-widget{--border:#1e3a5f;--bg:#121a2a;--text:#fff;--muted:#6b7280;--primary:#4dcfff;--success:#22c55e;--warning:#f59e0b;--error:#ef4444;position:fixed;right:18px;bottom:18px;z-index:9999;border:1px solid var(--border);border-radius:999px;padding:9px 13px;background:var(--bg);color:var(--text);box-shadow:0 8px 24px #0008;font:600 13px Segoe UI,system-ui,sans-serif;cursor:pointer}.gv-cc-widget:disabled{opacity:.6;cursor:wait}.gv-cc-widget .gv-cc-dot{display:inline-block;width:9px;height:9px;margin-right:8px;border-radius:50%;background:var(--muted)}.gv-cc-widget .gv-cc-power{margin-right:6px;color:var(--primary)}.gv-cc-widget.gv-cc-running .gv-cc-dot{background:var(--success)}.gv-cc-widget.gv-cc-partial .gv-cc-dot{background:var(--warning)}.gv-cc-widget.gv-cc-armed{border-color:var(--warning);color:var(--warning)}.gv-cc-widget.gv-cc-error{border-color:var(--error);color:var(--error)}:root[data-theme=light] .gv-cc-widget{--border:#cbd5e1;--bg:#fff;--text:#0f172a;--muted:#475569;--primary:#0055bb;--success:#16a34a;--warning:#d97706;--error:#dc2626}';
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
              `${p.name}: ${p.alive ? `PID ${p.pid || '—'} · port ${p.port}` : `port ${p.port} · ${t('stopped')}`}`,
          )
          .join('\n')
      : t('unavailable');
    button.setAttribute(
      'aria-label',
      `${current === 'running' ? t('stop') : t('start')} ${names[appId] || appId}`,
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
  // Two-click stop (arm → "¿Seguro?" → execute): confirm() dialogs can be
  // suppressed by browsers ("prevent more dialogs") or extensions, silently
  // returning false — which made the widget look dead with no visible error.
  let armed = false;
  let armTimer = null;
  const disarm = () => {
    armed = false;
    if (armTimer) clearTimeout(armTimer);
    button.classList.remove('gv-cc-armed');
    button.querySelector('.gv-cc-name').textContent = names[appId] || appId;
  };
  button.addEventListener('click', async () => {
    if (current === 'running' && !armed) {
      armed = true;
      button.classList.add('gv-cc-armed');
      button.querySelector('.gv-cc-name').textContent = t('confirm');
      armTimer = setTimeout(disarm, 3000);
      return;
    }
    disarm();
    button.disabled = true;
    try {
      const response = await fetch(
        `${cc}/api/apps/${encodeURIComponent(appId)}/${current === 'running' ? 'stop' : 'start'}`,
        { method: 'POST' },
      );
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      update(await response.json());
    } catch (error) {
      // Surface the failure visually — never only in the console.
      button.classList.add('gv-cc-error');
      button.title = `${t('error')}: ${error && error.message ? error.message : String(error)}`;
      setTimeout(() => button.classList.remove('gv-cc-error'), 2500);
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
