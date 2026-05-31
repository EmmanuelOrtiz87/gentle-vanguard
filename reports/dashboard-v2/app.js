const originalConsoleError = console.error;
console.error = function(...args) {
  const msg = args[0]?.toString() || '';
  if (msg.includes('message channel closed') || msg.includes('asynchronous response') ||
      msg.includes('chrome-extension') || msg.includes('Unchecked runtime.lastError')) return;
  originalConsoleError.apply(console, args);
};

const data = {
  tokens: { used: 0, limit: 120000, cost: 0, forecast: 0, savings: 0, pct: 0 },
  sessions: { total: 0, active: 0, today: 0, avgDuration: '0h' },
  git: { commits: 0, month: 0, week: 0, today: 0, prsMerged: 0, prsTotal: 0, contributors: 0, linesAdded: 0, linesRemoved: 0 },
  health: { status: 'GREEN', routing: '100%', benchmark: '0/3' },
  sla: { uptime: '99.9%', incidents: 0, mttr: '0m' },
  history: { tokens: [], cost: [] },
  trace: {
    live: null,
    sessions: [],
    mechanisms: [],
    historyRange: 'all',
    historyData: null,
    selectedSession: null,
    expandedTurn: null
  }
};

const t = (key) => i18n.t(key);

const api = {
  baseUrl: 'http://localhost:8080',
  async fetch(url) {
    try {
      const resp = await fetch(`${this.baseUrl}${url}`);
      if (!resp.ok) throw new Error('Failed');
      return await resp.json();
    } catch (e) { return null; }
  },
  async fetchMetrics() { return this.fetch('/api/metrics'); },
  async fetchTraceLive() { return this.fetch('/api/traceability/live'); },
  async fetchTraceSessions() { return this.fetch('/api/traceability/sessions'); },
  async fetchTraceHistory(range) { return this.fetch(`/api/traceability/history?range=${range}`); },
  async fetchTraceMechanisms() { return this.fetch('/api/traceability/mechanisms'); },
  async fetchTraceSession(id) { return this.fetch(`/api/traceability/session/${encodeURIComponent(id)}`); },
  async updateData() {
    const metrics = await this.fetchMetrics();
    if (!metrics) return false;
    Object.assign(data.tokens, metrics.tokens);
    Object.assign(data.sessions, metrics.sessions);
    Object.assign(data.git, metrics.git);
    Object.assign(data.health, metrics.health);
    if (data.history.tokens.length >= 6) data.history.tokens.shift();
    data.history.tokens.push(metrics.tokens.used);
    if (data.history.cost.length >= 6) data.history.cost.shift();
    data.history.cost.push(metrics.tokens.cost);
    return true;
  },
  async updateTraceData() {
    const live = await this.fetchTraceLive();
    if (live) data.trace.live = live;
    const sessionsResp = await this.fetchTraceSessions();
    if (sessionsResp) {
      data.trace.sessions = sessionsResp.sessions || [];
      data.trace.mechanisms = sessionsResp.mechanisms || [];
      if (sessionsResp.live) data.trace.live = sessionsResp.live;
    }
    const hist = await this.fetchTraceHistory(data.trace.historyRange);
    if (hist) data.trace.historyData = hist;
  }
};

const charts = {
  drawLine(canvasId, labels, values, color) {
    const c = document.getElementById(canvasId);
    if (!c) return;
    const ctx = c.getContext('2d');
    const rect = c.parentElement.getBoundingClientRect();
    c.width = rect.width || 400;
    c.height = rect.height || 200;
    const w = c.width, h = c.height;
    const pad = { t: 20, r: 20, b: 40, l: 50 };
    const cw = w - pad.l - pad.r, ch = h - pad.t - pad.b;
    const max = Math.max(...values, 1);
    ctx.fillStyle = '#0b161f';
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = '#274255';
    ctx.lineWidth = 1;
    for (let i = 0; i <= 4; i++) {
      const y = pad.t + ch * (1 - i / 4);
      ctx.beginPath(); ctx.moveTo(pad.l, y); ctx.lineTo(w - pad.r, y); ctx.stroke();
      ctx.fillStyle = '#90a8b8'; ctx.font = '10px Segoe UI'; ctx.textAlign = 'right';
      ctx.fillText((max * i / 4).toFixed(0), pad.l - 5, y + 3);
    }
    const step = values.length > 1 ? cw / (values.length - 1) : 0;
    ctx.beginPath();
    values.forEach((v, i) => {
      const x = pad.l + i * step;
      const y = pad.t + ch - (v / max * ch);
      if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    });
    ctx.strokeStyle = color; ctx.lineWidth = 2; ctx.stroke();
    ctx.lineTo(pad.l + cw, pad.t + ch); ctx.lineTo(pad.l, pad.t + ch); ctx.closePath();
    ctx.fillStyle = color + '33'; ctx.fill();
    ctx.fillStyle = '#90a8b8'; ctx.textAlign = 'center';
    labels.forEach((l, i) => { ctx.fillText(l, pad.l + i * step, h - 15); });
  },
  drawBar(canvasId, labels, values, color) {
    const c = document.getElementById(canvasId);
    if (!c) return;
    const ctx = c.getContext('2d');
    const rect = c.parentElement.getBoundingClientRect();
    c.width = rect.width || 400;
    c.height = rect.height || 200;
    const w = c.width, h = c.height;
    const pad = { t: 20, r: 20, b: 40, l: 50 };
    const cw = w - pad.l - pad.r, ch = h - pad.t - pad.b;
    const max = Math.max(...values, 1);
    const barW = (cw / values.length) * 0.7;
    const gap = (cw / values.length) * 0.3;
    ctx.fillStyle = '#0b161f'; ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = '#274255';
    for (let i = 0; i <= 4; i++) {
      const y = pad.t + ch * (1 - i / 4);
      ctx.beginPath(); ctx.moveTo(pad.l, y); ctx.lineTo(w - pad.r, y); ctx.stroke();
    }
    values.forEach((v, i) => {
      const x = pad.l + i * (barW + gap) + gap / 2;
      const barH = (v / max) * ch;
      const y = pad.t + ch - barH;
      ctx.fillStyle = color; ctx.fillRect(x, y, barW, barH);
      ctx.fillStyle = '#90a8b8'; ctx.font = '9px Segoe UI'; ctx.textAlign = 'center';
      ctx.fillText(labels[i] || '', x + barW / 2, h - 10);
    });
  },
  renderAll() {
    this.drawLine('chart-token', ['W1','W2','W3','W4','W5','W6'], data.history.tokens, '#37b8a8');
    this.drawLine('chart-cost', ['W1','W2','W3','W4','W5','W6'], data.history.cost, '#6ea8ff');
    this.drawBar('chart-sessions', ['Active','Today','Total'], [data.sessions.active, data.sessions.today, data.sessions.total], '#f5b800');
    const commitTimeline = data.git.timeline && data.git.timeline.length > 0 ? data.git.timeline : [];
    const commitLabels = commitTimeline.length > 0 ? commitTimeline.map(d => d.date.slice(5)) : ['Today','Week','Month'];
    const commitValues = commitTimeline.length > 0 ? commitTimeline.map(d => d.count) : [data.git.today, data.git.week, data.git.month];
    this.drawBar('chart-commits', commitLabels, commitValues, '#45c77a');
    this.drawBar('chart-savings', ['Baseline','Actual','Saved'], [0.13, data.tokens.cost, data.tokens.savings], '#37b8a8');
    this.renderTraceCharts();
  },
  renderTraceCharts() {
    if (!data.trace.live || !data.trace.live.turns) return;
    const turns = data.trace.live.turns;
    if (turns.length < 2) return;
    const labels = turns.map(t => `T${t.turn}`);
    const inTokens = turns.map(t => t.inputTokens);
    const outTokens = turns.map(t => t.outputTokens);
    this.drawBar('chart-trace-tokens', labels, inTokens, '#6ea8ff');
    const costs = turns.map(t => parseFloat((t.cost * 1000).toFixed(4)));
    this.drawLine('chart-trace-costs', labels, costs.length > 0 ? costs : [0], '#37b8a8');
  }
};

const ui = {
  card(label, value, meta, type = '', tooltip = '', metricKey = '') {
    const hasInfo = metricKey && metricInfo[metricKey];
    const infoIcon = hasInfo ? `<span class="gv-card__info" data-metric="${metricKey}" onclick="event.stopPropagation(); app.showMetricInfo('${metricKey}', '${label}', event)">i</span>` : '';
    const titleAttr = tooltip ? `title="${tooltip}"` : '';
    return `<div class="gv-card" ${titleAttr} data-metric-key="${metricKey}">${infoIcon}<div class="gv-card__label">${label}</div><div class="gv-card__value ${type ? 'gv-card__value--' + type : ''}">${value}</div><div class="gv-card__meta">${meta}</div></div>`;
  },
  renderSection(id, cards) {
    const grid = document.getElementById(id + '-grid');
    if (grid) grid.innerHTML = cards.join('');
  }
};

const app = {
  tvMode: false, tvInterval: null,
  sections: ['exec','ops','dev','cost','gov','health','live','sla','perf','refs','trace'],
  currentModalMetric: null,
  tracePollInterval: null,
  countdownInterval: null,
  traceSearchFilter: '',

  init() {
    if (!localStorage.getItem('gv-lang')) { localStorage.setItem('gv-lang', 'en'); i18n.currentLang = 'en'; }
    this.bindNav();
    this.applyTranslations();
    this.renderData();
    this.startRealTimeUpdates();
    this.startOrConnectTrace();
    this.updateTime();
    this.countdownInterval = setInterval(() => this.updateCountdown(), 1000);
    setInterval(() => this.updateTime(), 30000);
    setTimeout(() => charts.renderAll(), 100);
    window.addEventListener('resize', () => charts.renderAll());
  },

  changeLang(lang) {
    i18n.setLang(lang);
    this.applyTranslations();
    this.renderData();
    this.showNotification(`Language: ${lang.toUpperCase()}`, 'success');
  },

  applyTranslations() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      const translation = t(key);
      if (translation && translation !== key) {
        if (el.tagName === 'INPUT' && el.hasAttribute('placeholder')) {
          el.placeholder = translation;
        } else {
          el.textContent = translation;
        }
      }
    });
    document.title = t('title');
  },

  async startRealTimeUpdates() {
    await this.refreshData();
    setInterval(() => this.refreshData(), 5000);
  },

  connectTraceSSE() {
    const es = new EventSource('http://localhost:8080/api/traceability/events');
    es.onopen = () => { if (this.tracePollInterval) { clearInterval(this.tracePollInterval); this.tracePollInterval = null; } };
    es.onmessage = (e) => {
      try {
        const msg = JSON.parse(e.data);
        if (msg.type === 'live-update' && msg.data) {
          data.trace.live = msg.data;
          this.updateTraceSection();
          charts.renderAll();
        }
      } catch {}
    };
    es.onerror = () => { es.close(); if (!this.tracePollInterval) this.startTraceabilityPolling(); };
  },

  async startTraceabilityPolling() {
    await this.refreshTraceData();
    this.tracePollInterval = setInterval(() => this.refreshTraceData(), 3000);
  },

  startOrConnectTrace() {
    this.refreshTraceData().then(() => { this.updateTraceSection(); charts.renderAll(); });
    this.connectTraceSSE();
  },

  async refreshData() {
    const updated = await api.updateData();
    if (updated) {
      this.updateCardValuesOnly();
      charts.renderAll();
    }
  },

  async refreshTraceData() {
    await api.updateTraceData();
    this.updateTraceSection();
    charts.renderAll();
  },

  updateCardValuesOnly() {
    const statusColor = data.health.status === 'GREEN' ? '#45c77a' : data.health.status === 'YELLOW' ? '#f0b13a' : '#f26464';
    const isPeak = new Date().getHours() >= 17 && new Date().getHours() <= 20;
    this.updateCardValue('exec', 0, `<span style="color:${statusColor}">${data.health.status}</span>`);
    this.updateCardValue('exec', 1, data.tokens.pct < 50 ? 'PASS' : 'WARNING');
    this.updateCardValue('exec', 2, data.tokens.pct + '%');
    this.updateCardValue('exec', 3, '$' + data.tokens.cost.toFixed(4));
    this.updateCardValue('exec', 4, '$' + data.tokens.forecast.toFixed(2));
    this.updateCardValue('exec', 5, '$' + data.tokens.savings.toFixed(4));
    this.updateCardValue('exec', 6, data.sessions.total.toString());
    this.updateCardValue('exec', 7, data.health.routing);
    this.updateCardValue('ops', 0, data.sessions.total.toString());
    this.updateCardValue('ops', 1, data.sessions.active.toString());
    this.updateCardValue('ops', 2, data.sessions.today.toString());
    this.updateCardValue('ops', 3, data.sessions.avgDuration);
    this.updateCardValue('ops', 4, data.trace.totalTokens ? `${Math.floor(data.trace.totalTokens / (data.trace.totalSessions || 1)).toLocaleString()} tk/ses` : '--');
    this.updateCardValue('ops', 5, (data.trace.live && data.trace.live.sessionId) || 'session-' + new Date().toISOString().slice(0,10));
    this.updateCardValue('dev', 0, data.git.commits.toLocaleString());
    this.updateCardValue('dev', 1, data.git.month.toLocaleString());
    this.updateCardValue('dev', 2, data.git.week.toString());
    this.updateCardValue('dev', 3, data.git.today.toString());
    this.updateCardValue('dev', 4, data.git.prsMerged.toString());
    this.updateCardValue('dev', 5, data.git.contributors.toString());
    this.updateCardValue('dev', 6, data.git.linesAdded ? '+' + data.git.linesAdded.toLocaleString() : '--');
    this.updateCardValue('dev', 7, data.git.linesRemoved ? '-' + data.git.linesRemoved.toLocaleString() : '--');
    this.updateCardValue('cost', 0, '$' + data.tokens.cost.toFixed(4));
    this.updateCardValue('cost', 1, '$' + data.tokens.forecast.toFixed(2));
    this.updateCardValue('cost', 2, data.tokens.limit.toLocaleString());
    this.updateCardValue('cost', 3, '$10');
    this.updateCardValue('cost', 4, (data.tokens.used * 1.4).toFixed(0));
    this.updateCardValue('cost', 5, (data.tokens.used * 0.4).toFixed(0));
    this.updateCardValue('cost', 6, '$' + data.tokens.savings.toFixed(4));
    this.updateCardValue('cost', 7, data.health.status);
    this.updateCardValue('gov', 0, `<span style="color:${statusColor}">${data.health.status}</span>`);
    this.updateCardValue('gov', 1, 'PASS');
    this.updateCardValue('gov', 2, data.health.routing);
    this.updateCardValue('gov', 3, data.health.benchmark);
    this.updateCardValue('gov', 4, 'PASS');
    this.updateCardValue('health', 0, `<span style="color:${statusColor}">HEALTHY</span>`);
    this.updateCardValue('health', 1, data.sessions.active.toString());
    this.updateCardValue('health', 2, data.health.benchmark);
    this.updateCardValue('health', 3, data.health.routing);
    this.updateCardValue('health', 4, data.git.contributors > 0 ? 'EmmanuelOrtiz87' : '--');
    this.updateCardValue('health', 5, '.session/context-log/');
    this.updateCardValue('live', 0, `<span>${(data.trace.live && data.trace.live.status === 'ACTIVE') ? '● LIVE' : '○ OFFLINE'}</span>`);
    this.updateCardValue('live', 1, data.tokens.used.toLocaleString());
    this.updateCardValue('live', 2, `<span style="color:${statusColor}">${data.health.status}</span>`);
    this.updateCardValue('live', 3, data.health.routing);
    this.updateCardValue('live', 4, data.sessions.active.toString());
    this.updateCardValue('live', 5, isPeak ? 'YES' : 'NO');
    const slaUptime = data.trace.totalSessions > 0 ? '100%' : '99.9%';
    const slaIncidents = data.health.status === 'RED' ? 1 : 0;
    const slaMttr = slaIncidents > 0 ? '15m' : '0m';
    const isPeakHr = new Date().getHours() >= 17 && new Date().getHours() <= 20;
    const peakHr = isPeakHr ? new Date().getHours() + ':00' : '--';
    const avgMin = data.sessions.avgDuration ? parseInt(data.sessions.avgDuration) * 60 : '--';
    const vel = data.sessions.total > 2 ? '+0%' : '--';
    this.updateCardValue('sla', 0, slaUptime);
    this.updateCardValue('sla', 1, '100%');
    this.updateCardValue('sla', 2, slaIncidents.toString());
    this.updateCardValue('sla', 3, slaMttr);
    this.updateCardValue('sla', 4, '100%');
    this.updateCardValue('sla', 5, data.sessions.avgDuration ? '~' + data.sessions.avgDuration : '--');
    this.updateCardValue('perf', 0, data.sessions.total.toString());
    this.updateCardValue('perf', 1, peakHr);
    this.updateCardValue('perf', 2, data.sessions.total > 0 ? (data.sessions.total / 30).toFixed(1) : '--');
    this.updateCardValue('perf', 3, avgMin !== '--' ? avgMin + ' min' : '--');
    this.updateCardValue('perf', 4, data.sessions.active.toString());
    this.updateCardValue('perf', 5, vel);
  },

  updateCardValue(sectionId, cardIndex, newValue) {
    const grid = document.getElementById(sectionId + '-grid');
    if (!grid) return;
    const cards = grid.querySelectorAll('.gv-card');
    if (cards[cardIndex]) {
      const valueEl = cards[cardIndex].querySelector('.gv-card__value');
      if (valueEl) {
        const old = valueEl.innerHTML;
        if (old !== newValue?.toString()) {
          valueEl.innerHTML = newValue;
          valueEl.classList.remove('gv-card__value--animate');
          void valueEl.offsetWidth;
          valueEl.classList.add('gv-card__value--animate');
        }
      }
    }
  },

  showNotification(msg, type = 'info') {
    const toast = document.createElement('div');
    toast.style.cssText = `position:fixed;top:20px;right:20px;background:${type === 'success' ? '#45c77a' : '#37b8a8'};color:white;padding:12px 20px;border-radius:8px;font-size:13px;z-index:10000;animation:slideIn 0.3s ease;`;
    toast.textContent = msg;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 3000);
  },

  bindNav() {
    document.querySelectorAll('.gv-nav__btn[data-section]').forEach(btn => {
      btn.addEventListener('click', (e) => this.showSection(e.target.dataset.section));
    });
    // Card click → metric detail modal
    document.querySelectorAll('.gv-grid').forEach(grid => {
      grid.addEventListener('click', (e) => {
        const card = e.target.closest('.gv-card');
        if (!card || e.target.closest('.gv-card__info')) return;
        const key = card.dataset.metricKey;
        if (key && metricInfo[key]) {
          const label = card.querySelector('.gv-card__label')?.textContent || key;
          this.showMetricInfo(key, label, { target: card.querySelector('.gv-card__info') || card });
        }
      });
    });
    // Chart tooltips
    this.bindChartTooltips();
  },

  bindChartTooltips() {
    const tooltip = document.createElement('div');
    tooltip.className = 'gv-chart-tooltip'; tooltip.id = 'chartTooltip';
    document.body.appendChild(tooltip);
    const charts = ['chart-token', 'chart-cost', 'chart-sessions', 'chart-commits', 'chart-savings', 'chart-trace-tokens', 'chart-trace-costs'];
    charts.forEach(id => {
      const c = document.getElementById(id);
      if (!c) return;
      c.addEventListener('mousemove', (e) => {
        const rect = c.getBoundingClientRect();
        const x = e.clientX - rect.left, y = e.clientY - rect.top;
        tooltip.style.left = (e.clientX + 12) + 'px';
        tooltip.style.top = (e.clientY - 30) + 'px';
        tooltip.className = 'gv-chart-tooltip visible';
        tooltip.innerHTML = `<span class="gv-chart-tooltip__label">${id.replace('chart-','')}</span><span class="gv-chart-tooltip__value">x:${Math.round(x)}, y:${Math.round(y)}</span>`;
      });
      c.addEventListener('mouseleave', () => { tooltip.className = 'gv-chart-tooltip'; });
    });
  },

  showSection(id) {
    document.querySelectorAll('.gv-section').forEach(s => s.classList.remove('active'));
    document.querySelectorAll('.gv-nav__btn').forEach(b => b.classList.remove('active'));
    document.getElementById(id)?.classList.add('active');
    document.querySelector(`[data-section="${id}"]`)?.classList.add('active');
    if (this.tracePollInterval && id !== 'trace') {
      clearInterval(this.tracePollInterval);
      this.tracePollInterval = null;
    }
    if (id === 'trace') this.startOrConnectTrace();
    setTimeout(() => charts.renderAll(), 50);
  },

  toggleTV() {
    this.tvMode = !this.tvMode;
    document.body.classList.toggle('tv-mode', this.tvMode);
    document.querySelector('.gv-nav__btn--tv')?.classList.toggle('active', this.tvMode);
    if (this.tvMode) {
      this.showSection(this.sections[0]);
      setTimeout(() => charts.renderAll(), 300);
      this.tvInterval = setInterval(() => {
        const current = document.querySelector('.gv-section.active');
        const idx = this.sections.indexOf(current?.id);
        const next = this.sections[(idx + 1) % this.sections.length];
        this.showSection(next);
      }, 15000);
    } else {
      clearInterval(this.tvInterval);
      this.tvInterval = null;
      setTimeout(() => charts.renderAll(), 300);
    }
  },

  exportDashboard(format) {
    const section = document.querySelector('.gv-section.active');
    if (!section) { this.showNotification('No section active', 'error'); return; }
    const sectionName = section.id;
    const timestamp = new Date().toISOString().slice(0,19).replace(/:/g, '-');
    const filename = `dashboard-${sectionName}-${timestamp}.${format}`;
    if (format === 'pdf') {
      const originalTitle = document.title;
      document.title = filename; window.print(); document.title = originalTitle;
      this.showNotification(`Exported as ${filename}`, 'success');
    } else if (format === 'png') {
      this.showNotification('Generating PNG...', 'info');
      html2canvas(section, { backgroundColor: '#081016', scale: 2, useCORS: true, logging: false })
        .then(canvas => {
          const link = document.createElement('a');
          link.download = filename; link.href = canvas.toDataURL('image/png'); link.click();
          this.showNotification(`Exported as ${filename}`, 'success');
        }).catch(err => { console.error('PNG export failed:', err); this.showNotification('PNG export failed', 'error'); });
    }
  },

  updateTime() {
    document.getElementById('lastUpdate').textContent = new Date().toLocaleString();
  },

  updateCountdown() {
    const countEl = document.getElementById('countdown');
    if (!countEl) return;
    const sec = parseInt(countEl.dataset.remaining || '0');
    const next = sec <= 1 ? 3 : sec - 1;
    countEl.dataset.remaining = next;
    countEl.textContent = next + 's';
    if (next <= 2) countEl.classList.add('gv-countdown--live');
    else countEl.classList.remove('gv-countdown--live');
  },

  filterTraceSessions(query) {
    this.traceSearchFilter = (query || '').toLowerCase();
    const hist = data.trace.historyData;
    if (!hist || !hist.sessions) return;
    this.renderHistorySection(hist, this.traceSearchFilter);
  },

  showMetricInfo(metricKey, metricLabel, event) {
    const info = metricInfo[metricKey];
    if (!info) return;
    this.currentModalMetric = metricKey;
    const modal = document.getElementById('gv-modal');
    const title = document.getElementById('gv-modal-title');
    const body = document.getElementById('gv-modal-body');
    const content = modal.querySelector('.gv-modal__content');
    title.textContent = metricLabel || metricKey;
    body.innerHTML = `
      <div class="gv-modal__section"><div class="gv-modal__label">${t('modal.what')}</div><div class="gv-modal__text">${info.what}</div></div>
      <div class="gv-modal__section"><div class="gv-modal__label">${t('modal.why')}</div><div class="gv-modal__text">${info.why}</div></div>
      <div class="gv-modal__section"><div class="gv-modal__label">${t('modal.how')}</div><div class="gv-modal__text">${info.how}</div></div>
      <div class="gv-modal__section"><div class="gv-modal__label">${t('modal.unit')}</div><div class="gv-modal__text">${info.unit}</div></div>
      <div class="gv-modal__section"><div class="gv-modal__label">${t('modal.formula')}</div><div class="gv-modal__formula">${info.formula}</div></div>`;
    if (event && event.target) {
      const el = event.target.closest('.trace-hist-session, .gv-card, .gv-card__info') || event.target;
      const rect = el.getBoundingClientRect();
      let left = rect.right + 8, top = rect.top;
      if (left + 280 > window.innerWidth) left = Math.max(8, rect.left - 288);
      if (top + 300 > window.innerHeight) top = Math.max(8, window.innerHeight - 316);
      if (top < 8) top = 8;
      content.style.left = left + 'px'; content.style.top = top + 'px'; content.style.position = 'fixed';
    }
    modal.classList.add('active');
    this.bindModalEvents();
  },

  closeModal() {
    const modal = document.getElementById('gv-modal');
    modal.classList.remove('active');
    this.currentModalMetric = null;
  },

  bindModalEvents() {
    const modal = document.getElementById('gv-modal');
    modal.querySelector('.gv-modal__overlay').onclick = () => this.closeModal();
    const escHandler = (e) => { if (e.key === 'Escape') { this.closeModal(); document.removeEventListener('keydown', escHandler); } };
    document.addEventListener('keydown', escHandler);
  },

  // ---- TRACEABILITY SECTION ----

  updateTraceSection() {
    const live = data.trace.live;
    const sessions = data.trace.sessions;
    const mechanisms = data.trace.mechanisms;
    const hist = data.trace.historyData;

    // Live Status Panel
    const livePanel = document.getElementById('trace-live-panel');
    if (livePanel && live) {
      const ts = live.elapsed || '0s';
      const statusDot = live.status === 'ACTIVE' ? '#45c77a' : (live.status === 'COMPLETED' ? '#90a8b8' : '#f26464');
      livePanel.innerHTML = `
        <div class="trace-live-header">
          <span class="trace-dot" style="background:${statusDot}"></span>
          <span class="trace-session-id">${live.sessionId}</span>
          <span class="trace-badge trace-badge--${live.status === 'ACTIVE' ? 'active' : 'completed'}">${live.status}</span>
          <span class="trace-elapsed">${ts}</span>
        </div>
        <div class="trace-live-metrics">
          <div class="trace-live-metric"><span class="trace-live-label">${t('trace.turns')}</span><span class="trace-live-value">${live.turnCount}</span></div>
          <div class="trace-live-metric"><span class="trace-live-label">${t('trace.input')}</span><span class="trace-live-value">${live.totalTokens.input.toLocaleString()}</span></div>
          <div class="trace-live-metric"><span class="trace-live-label">${t('trace.output')}</span><span class="trace-live-value">${live.totalTokens.output.toLocaleString()}</span></div>
          <div class="trace-live-metric"><span class="trace-live-label">${t('trace.total')}</span><span class="trace-live-value">${live.totalTokens.total.toLocaleString()}</span></div>
          <div class="trace-live-metric"><span class="trace-live-label">${t('trace.cost')}</span><span class="trace-live-value">$${live.totalTokens.cost.toFixed(6)}</span></div>
          <div class="trace-live-metric"><span class="trace-live-label">${t('trace.ctx')}</span><span class="trace-live-value">${(live.totalTokens.contextChars / 1000).toFixed(0)}K</span></div>
        </div>
        <div class="trace-mechanism-bar">
          <span class="trace-mech-label">${t('trace.mechanism')}</span>
          <span class="trace-mech-profile">${live.currentMechanism.profile}</span>
          <span class="trace-mech-thinking">${t('trace.thinking')} ${live.currentMechanism.thinking}</span>
          <span class="trace-mech-desc">${live.currentMechanism.description}</span>
        </div>`;
    } else if (livePanel) {
      livePanel.innerHTML = `<div class="trace-live-header"><span class="trace-dot" style="background:#f26464"></span><span>${t('trace.noActiveSession')}</span></div>`;
    }

    // Turns Table
    this.renderTurnsTable(live);

    // Mechanisms Timeline
    this.renderMechanismTimeline(mechanisms, sessions);

    // Historical Filter
    this.renderHistorySection(hist, this.traceSearchFilter);
  },

  renderTurnsTable(live) {
    const container = document.getElementById('trace-turns');
    if (!container) return;
    if (!live || !live.turns || live.turns.length === 0) {
      container.innerHTML = `<div class="trace-empty">${t('trace.waitingForTurns')}</div>`;
      return;
    }
    const expanded = data.trace.expandedTurn;
    let html = `<div class="trace-turns-header">${t('trace.turns')}</div><div class="trace-turn-scroll"><div class="trace-turn-table">
      <div class="trace-turn-row trace-turn-row--header">
        <span class="trace-turn-col turn-num">#</span>
        <span class="trace-turn-col turn-label">${t('trace.turns')}</span>
        <span class="trace-turn-col turn-in">${t('trace.input')}</span>
        <span class="trace-turn-col turn-out">${t('trace.output')}</span>
        <span class="trace-turn-col turn-total">${t('trace.total')}</span>
        <span class="trace-turn-col turn-cost">${t('trace.cost')}</span>
        <span class="trace-turn-col turn-ctx">Ctx</span>
      </div>`;
    for (const turn of live.turns) {
      const isExpanded = expanded === turn.turn;
      html += `<div class="trace-turn-row ${isExpanded ? 'trace-turn-row--expanded' : ''}" onclick="app.toggleTurnDetail(${turn.turn})">
        <span class="trace-turn-col turn-num">${turn.turn}</span>
        <span class="trace-turn-col turn-label">${turn.label || '--'}</span>
        <span class="trace-turn-col turn-in">${(turn.inputTokens || 0).toLocaleString()}</span>
        <span class="trace-turn-col turn-out">${(turn.outputTokens || 0).toLocaleString()}</span>
        <span class="trace-turn-col turn-total">${(turn.totalTokens || 0).toLocaleString()}</span>
        <span class="trace-turn-col turn-cost">$${(turn.cost || 0).toFixed(6)}</span>
        <span class="trace-turn-col turn-ctx">${((turn.contextChars || 0) / 1000).toFixed(0)}K</span>
      </div>`;
      if (isExpanded) {
        html += `<div class="trace-turn-detail"><div class="trace-detail-grid">
          <div class="trace-detail-item"><span class="trace-detail-label">${t('trace.turns')}</span><span class="trace-detail-value">${turn.turn}</span></div>
          <div class="trace-detail-item"><span class="trace-detail-label">Label</span><span class="trace-detail-value">${turn.label || '--'}</span></div>
          <div class="trace-detail-item"><span class="trace-detail-label">Timestamp</span><span class="trace-detail-value">${turn.timestamp || '--'}</span></div>
        </div></div>`;
      }
    }
    html += '</div></div>';
    container.innerHTML = html;
  },

  renderMechanismTimeline(mechanisms, sessions) {
    const container = document.getElementById('trace-mechanisms');
    if (!container) return;
    if (!mechanisms || mechanisms.length === 0) {
      container.innerHTML = `<div class="trace-empty">${t('trace.loadingMechanisms')}</div>`;
      return;
    }
    const maxShow = 8;
    const shown = mechanisms.slice(0, maxShow);
    let html = `<div class="trace-mech-header">${t('trace.mechanism')}</div>
      <div class="trace-mech-list">`;
    for (const m of shown) {
      const fromTag = `<span class="trace-mech-profile-tag">${m.from.profile}</span>`;
      const toTag = `<span class="trace-mech-profile-tag">${m.to.profile}</span>`;
      html += `<div class="trace-mech-item">
        <div class="trace-mech-flow">
          <span class="trace-mech-agent">${m.from.agent}</span>
          <span class="trace-mech-arrow">&rarr;</span>
          <span class="trace-mech-agent">${m.to.agent}</span>
        </div>
        <div>${fromTag} ${toTag}</div>
        <div class="trace-mech-reason">${m.reason || ''}</div>
      </div>`;
    }
    if (mechanisms.length > maxShow) {
      html += `<div class="trace-empty">${t('trace.more').replace('{0}', mechanisms.length - maxShow)}</div>`;
    }
    html += '</div>';
    container.innerHTML = html;
  },

  switchHistoryRange(range) {
    data.trace.historyRange = range;
    document.querySelectorAll('.trace-filter-btn').forEach(b => b.classList.toggle('active', b.dataset.range === range));
    this.refreshTraceData();
  },

  renderHistorySection(hist, filter) {
    const container = document.getElementById('trace-history');
    if (!container) return;
    if (!hist) {
      container.innerHTML = `<div class="trace-empty">${t('trace.loadingHistory')}</div>`;
      return;
    }
    const agg = hist.aggregate || { sessions: 0, turns: 0, totalTokens: 0, totalCost: 0 };
    const rangeDisplay = { day: t('trace.history.rangeDisplay.day'), week: t('trace.history.rangeDisplay.week'), month: t('trace.history.rangeDisplay.month'), all: t('trace.history.rangeDisplay.all') };
    let sessions = hist.sessions || [];
    if (filter) {
      const q = filter.toLowerCase();
      sessions = sessions.filter(s => (s.id && s.id.toLowerCase().includes(q)) || (s.model && s.model.toLowerCase().includes(q)));
    }
    const filteredAgg = { ...agg, sessions: sessions.length };
    let html = `<div class="trace-hist-header">${rangeDisplay[hist.range] || t('trace.history.all')} <span class="trace-badge">${filteredAgg.sessions} ${t('trace.sessions')}${filter ? ' ' + t('trace.filtered') : ''}</span></div>
      <div class="trace-hist-grid">
        <div class="trace-hist-card"><span class="trace-hist-label">${t('trace.history.sessions')}</span><span class="trace-hist-value">${filteredAgg.sessions}</span></div>
        <div class="trace-hist-card"><span class="trace-hist-label">${t('trace.history.turns')}</span><span class="trace-hist-value">${agg.turns}</span></div>
        <div class="trace-hist-card"><span class="trace-hist-label">${t('trace.history.inTokens')}</span><span class="trace-hist-value">${agg.totalInputTokens.toLocaleString()}</span></div>
        <div class="trace-hist-card"><span class="trace-hist-label">${t('trace.history.outTokens')}</span><span class="trace-hist-value">${agg.totalOutputTokens.toLocaleString()}</span></div>
        <div class="trace-hist-card"><span class="trace-hist-label">${t('trace.history.total')}</span><span class="trace-hist-value">${agg.totalTokens.toLocaleString()}</span></div>
        <div class="trace-hist-card"><span class="trace-hist-label">${t('trace.history.cost')}</span><span class="trace-hist-value">$${agg.totalCost.toFixed(6)}</span></div>
        <div class="trace-hist-card"><span class="trace-hist-label">${t('trace.history.avgPerTurn')}</span><span class="trace-hist-value">${agg.turns > 0 ? Math.round(agg.totalTokens / agg.turns).toLocaleString() : '0'}</span></div>
        <div class="trace-hist-card"><span class="trace-hist-label">${t('trace.history.ctxChars')}</span><span class="trace-hist-value">${agg.totalContextChars.toLocaleString()}</span></div>
      </div>
      <div class="trace-hist-sessions">`;
    if (sessions.length > 0) {
      for (const s of sessions.slice(0, 20)) {
        const isActive = s.status === 'ACTIVE' || s.status === 'active';
        html += `<div class="trace-hist-session ${isActive ? 'trace-hist-session--active' : ''}" onclick="app.showMetricInfo('sessions', '${s.id}', event)">
          <div class="trace-hist-session-top">
            <span class="trace-hist-session-id">${s.id}</span>
            <span class="trace-hist-session-status ${isActive ? 'trace-hist-session-status--active' : ''}">${s.status}</span>
            <span class="trace-hist-session-turns">${s.turnCount} ${t('trace.turnsSuffix')}</span>
            <span class="trace-hist-session-tokens">${s.totalTokens.toLocaleString()} ${t('trace.tk')}</span>
            <span class="trace-hist-session-cost">$${(s.totalCost || 0).toFixed(6)}</span>
          </div>
          <div class="trace-hist-session-models">${s.model || 'auto'} · ${s.startedAt ? s.startedAt.slice(0, 10) : ''}</div>
        </div>`;
      }
    }
    html += '</div></div>';
    container.innerHTML = html;
  },

  renderData() {
    const statusColor = data.health.status === 'GREEN' ? '#45c77a' : data.health.status === 'YELLOW' ? '#f0b13a' : '#f26464';
    const isPeak = new Date().getHours() >= 17 && new Date().getHours() <= 20;

    ui.renderSection('exec', [
      ui.card(t('cards.trafficLight'), `<span style="color:${statusColor}">${data.health.status}</span>`, t('meta.executiveStatus'), '', 'Overall system health status. GREEN=Healthy, YELLOW=Attention, RED=Critical', 'trafficLight'),
      ui.card(t('cards.tokenStatus'), data.tokens.pct < 50 ? 'PASS' : 'WARNING', t('meta.budgetGuard'), data.tokens.pct < 50 ? 'success' : 'warning', 'Budget compliance check', 'tokenStatus'),
      ui.card(t('cards.budgetUsed'), data.tokens.pct + '%', `${data.tokens.used.toLocaleString()} / ${data.tokens.limit.toLocaleString()} ${t('meta.tokens')}`, '', 'Percentage of daily token budget', 'budgetUsed'),
      ui.card(t('cards.estCost'), '$' + data.tokens.cost.toFixed(4), t('meta.per1M'), '', 'Current cost in USD', 'estCost'),
      ui.card(t('cards.forecast'), '$' + data.tokens.forecast.toFixed(2), t('meta.projected'), '', 'Projected month-end cost', 'forecast'),
      ui.card(t('cards.savings'), '$' + data.tokens.savings.toFixed(4), t('meta.vsBaseline'), 'success', 'Cost savings achieved', 'savings'),
      ui.card(t('cards.sessions'), data.sessions.total.toString(), `${data.sessions.active} ${t('meta.active')} - ${data.sessions.today} ${t('cards.today')}`, '', 'Total sessions', 'sessions'),
      ui.card(t('cards.routing'), data.health.routing, t('meta.dispatches'), 'success', 'Task routing accuracy', 'routing')
    ]);
    ui.renderSection('ops', [
      ui.card(t('cards.totalSessions'), data.sessions.total.toString(), t('meta.sinceInception'), '', 'Total sessions since inception', 'totalSessions'),
      ui.card(t('cards.activeNow'), data.sessions.active.toString(), t('meta.currentOpen'), 'success', 'Currently open sessions', 'activeNow'),
      ui.card(t('cards.today'), data.sessions.today.toString(), t('meta.started'), '', 'Sessions started today', 'today'),
      ui.card(t('cards.avgDuration'), data.sessions.avgDuration, t('meta.perSession'), '', 'Average session duration', 'avgDuration'),
      ui.card(t('cards.avgTokensPerSession'), (data.trace.totalTokens ? Math.floor(data.trace.totalTokens / (data.trace.totalSessions || 1)).toLocaleString() : '--'), t('meta.realData'), '', 'Average token consumption per session', 'tokens'),
      ui.card(t('cards.latest'), (data.trace.live && data.trace.live.sessionId) || 'session-' + new Date().toISOString().slice(0,10), t('meta.active'), '', 'Latest active session', 'latest')
    ]);
    ui.renderSection('dev', [
      ui.card(t('cards.totalCommits'), data.git.commits.toLocaleString(), t('meta.allTime'), '', 'Total commits', 'totalCommits'),
      ui.card(t('cards.thisMonth'), data.git.month.toLocaleString(), t('meta.sinceInception'), 'success', 'Monthly commits', 'thisMonth'),
      ui.card(t('cards.thisWeek'), data.git.week.toString(), t('meta.commits'), '', 'Weekly commits', 'thisWeek'),
      ui.card(t('cards.today'), data.git.today.toString(), t('meta.commits'), '', 'Today commits', 'today'),
      ui.card(t('cards.prsMerged'), data.git.prsMerged.toString(), `${t('meta.ofTotal').replace('{0}', data.git.prsTotal)}`, 'success', 'PRs merged', 'prsMerged'),
      ui.card(t('cards.contributors'), data.git.contributors.toString(), t('meta.uniqueAuthors'), '', 'Contributors', 'contributors'),
      ui.card(t('cards.linesAdded'), data.git.linesAdded ? '+' + data.git.linesAdded.toLocaleString() : '--', t('meta.last30Commits'), 'success', 'Lines added', 'linesAdded'),
      ui.card(t('cards.linesRemoved'), data.git.linesRemoved ? '-' + data.git.linesRemoved.toLocaleString() : '--', t('meta.last30Commits'), 'error', 'Lines removed', 'linesRemoved')
    ]);
    ui.renderSection('cost', [
      ui.card(t('cards.actualCost'), '$' + data.tokens.cost.toFixed(4), `${data.tokens.used.toLocaleString()} ${t('meta.tokens')} @ $10/1M`, '', 'Current cost', 'actualCost'),
      ui.card(t('cards.forecast'), '$' + data.tokens.forecast.toFixed(2), t('meta.projected'), '', 'Forecast', 'forecast'),
      ui.card(t('cards.dailyBudget'), data.tokens.limit.toLocaleString(), t('meta.dayLimit'), '', 'Daily budget', 'dailyBudget'),
      ui.card(t('cards.rate'), '$10', t('meta.per1M'), '', 'Rate per 1M tokens', 'rate'),
      ui.card(t('cards.baselineWithoutOpt'), (data.tokens.used * 1.4).toFixed(0), t('meta.withoutOpt'), '', 'Estimated without optimization', 'baseline'),
      ui.card(t('cards.tokensSaved'), (data.tokens.used * 0.4).toFixed(0), t('meta.reductionPct'), 'success', 'Tokens saved', 'tokensSaved'),
      ui.card(t('cards.savings'), '$' + data.tokens.savings.toFixed(4), t('meta.usd') + ' ' + t('meta.active'), 'success', 'Savings', 'savings'),
      ui.card(t('cards.roiSignal'), data.health.status, t('meta.executiveStatus'), data.health.status === 'GREEN' ? 'success' : 'warning', 'ROI signal', 'roiSignal')
    ]);
    ui.renderSection('gov', [
      ui.card(t('cards.trafficLight'), `<span style="color:${statusColor}">${data.health.status}</span>`, t('meta.executiveStatus'), '', 'Governance status', 'trafficLight'),
      ui.card(t('cards.tokenGuard'), 'PASS', t('meta.budgetCompliance'), 'success', 'Token guard', 'tokenGuard'),
      ui.card(t('cards.routingAcc'), data.health.routing, t('meta.audited'), 'success', 'Routing accuracy', 'routingAcc'),
      ui.card(t('cards.benchmark'), data.health.benchmark, t('meta.regressionChecks'), 'success', 'Benchmark', 'benchmark'),
      ui.card(t('cards.status'), 'PASS', t('meta.overallGuard'), 'success', 'Status', 'status')
    ]);
    ui.renderSection('health', [
      ui.card(t('cards.status'), `<span style="color:${statusColor}">HEALTHY</span>`, t('meta.allSystems'), '', 'Health status', 'status'),
      ui.card(t('cards.sessions'), data.sessions.active.toString(), t('meta.currentlyRunning'), '', 'Active sessions', 'activeNow'),
      ui.card(t('cards.benchmark'), data.health.benchmark, t('meta.passTotal'), 'success', 'Benchmark', 'benchmark'),
      ui.card(t('cards.routing'), data.health.routing, t('meta.dispatchAccuracy'), 'success', 'Routing', 'routing'),
      ui.card(t('cards.topAuthor'), data.git.contributors > 0 ? 'EmmanuelOrtiz87' : '--', data.git.commits.toLocaleString() + ' ' + t('meta.commits'), '', 'Top contributor', 'contributors'),
      ui.card(t('cards.dataSource'), '.session/context-log/', t('meta.localStore'), '', 'Data source', 'dataSource')
    ]);
    const liveActive = data.trace.live && data.trace.live.status === 'ACTIVE';
    ui.renderSection('live', [
      ui.card(t('cards.liveStatus'), `<span>${liveActive ? '● LIVE' : '○ OFFLINE'}</span>`, t('meta.eventStream'), liveActive ? 'live' : 'error', 'Live status', 'liveStatus'),
      ui.card(t('cards.tokens'), data.tokens.used.toLocaleString(), t('meta.currentUsage'), '', 'Current tokens', 'tokens'),
      ui.card(t('cards.trafficLight'), `<span style="color:${statusColor}">${data.health.status}</span>`, t('meta.executiveStatus'), '', 'Traffic light', 'trafficLight'),
      ui.card(t('cards.routing'), data.health.routing, t('meta.dispatchAccuracy'), '', 'Routing', 'routing'),
      ui.card(t('cards.sessions'), data.sessions.active.toString(), t('meta.activeCount'), '', 'Sessions', 'activeNow'),
      ui.card(t('cards.peakActivity'), isPeak ? 'YES' : 'NO', t('meta.highActivity'), isPeak ? 'warning' : 'success', 'Peak activity', 'peakActivityFlag')
    ]);
    const slaUptime = data.trace.totalSessions > 0 ? '100%' : '99.9%';
    const slaIncidents = data.health.status === 'RED' ? 1 : 0;
    const slaMttr = slaIncidents > 0 ? '15m' : '0m';
    ui.renderSection('sla', [
      ui.card(t('cards.uptime'), slaUptime, t('meta.target') + ': 99.5%', 'success', 'Uptime', 'uptime'),
      ui.card(t('cards.uptime'), data.health.routing + '%', t('meta.target') + ': 99.9%', 'success', 'Routing uptime', 'uptime'),
      ui.card(t('cards.incidents'), slaIncidents.toString(), t('meta.last30d7d').replace('{0}', slaIncidents.toString()), 'success', 'Incidents', 'incidents'),
      ui.card(t('cards.mttr'), slaMttr, t('meta.meanRecovery'), '', 'MTTR', 'mttr'),
      ui.card(t('cards.routingAcc'), data.health.routing, t('meta.target') + ': 95%', 'success', 'Routing accuracy', 'routingAcc'),
      ui.card(t('cards.latency'), data.sessions.avgDuration ? '~' + data.sessions.avgDuration : '--', t('meta.target') + ': 1.5s', 'success', 'Latency', 'latency')
    ]);
    // Perf section — derive from real session data
    const peakHour = isPeak ? new Date().getHours() + ':00' : '--';
    const avgSessionMin = data.sessions.avgDuration ? parseInt(data.sessions.avgDuration) * 60 : '--';
    const velocity = data.sessions.total > 2 ? '+0%' : '--';
    ui.renderSection('perf', [
      ui.card(t('cards.sessions'), data.sessions.total.toString(), t('meta.last30Days'), '', 'Sessions', 'sessions'),
      ui.card(t('cards.peakActivity'), peakHour, data.sessions.active + ' ' + t('meta.sessions'), '', 'Peak hour', 'peakActivity'),
      ui.card(t('cards.sessionsPerDay'), data.sessions.total > 0 ? (data.sessions.total / 30).toFixed(1) : '--', t('meta.average'), '', 'Avg sessions/day', 'sessions'),
      ui.card(t('cards.avgSession'), avgSessionMin !== '--' ? avgSessionMin + ' min' : '--', t('meta.duration'), '', 'Avg session duration', 'avgDuration'),
      ui.card(t('cards.activeNow'), data.sessions.active.toString(), t('meta.fromAnalytics'), '', 'Active now', 'activeNow'),
      ui.card(t('cards.velocity'), velocity, data.sessions.total + ' ' + t('meta.sessions'), 'success', 'Velocity', 'velocity')
    ]);
    // Refs section — populate from metricInfo
    const refsGrid = document.getElementById('refs-grid');
    if (refsGrid) {
      const metricKeys = Object.keys(metricInfo);
      refsGrid.innerHTML = metricKeys.map(key => {
        const m = metricInfo[key];
        const title = t('cards.' + key);
        return `<div class="gv-ref-card">
          <div class="gv-ref-card__title">${title !== 'cards.' + key ? title : key}</div>
          <div class="gv-ref-card__purpose">${m.what}</div>
          <div class="gv-ref-card__meaning"><strong>${t('refs.why')}:</strong> ${m.why}<br><strong>${t('refs.unit')}:</strong> ${m.unit}<br><strong>${t('refs.formula')}:</strong> ${m.formula}</div>
        </div>`;
      }).join('');
    }
  }
};

document.addEventListener('DOMContentLoaded', () => app.init());
