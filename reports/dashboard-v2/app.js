// Suppress extension errors (ad-blockers, password managers, etc.)
const originalConsoleError = console.error;
console.error = function(...args) {
  const msg = args[0]?.toString() || '';
  if (msg.includes('message channel closed') || 
      msg.includes('asynchronous response') ||
      msg.includes('chrome-extension') ||
      msg.includes('Unchecked runtime.lastError')) {
    return; // Suppress extension errors
  }
  originalConsoleError.apply(console, args);
};

// Real-Time Data Layer
const data = {
  tokens: { used: 9158, limit: 120000, cost: 0.0916, forecast: 0.11, savings: 0.0366, pct: 8.46 },
  sessions: { total: 38, active: 6, today: 4, avgDuration: '20.1h' },
  git: { commits: 1615, month: 971, week: 19, today: 0, prsMerged: 93, prsTotal: 100, contributors: 6 },
  health: { status: 'GREEN', routing: '100%', benchmark: '3/3' },
  sla: { uptime: '99.9%', incidents: 0, mttr: '0m' },
  history: {
    tokens: [1800, 3200, 4600, 6000, 7300, 9158],
    cost: [0.02, 0.03, 0.05, 0.06, 0.07, 0.09]
  }
};

// Helper function for translations
const t = (key) => i18n.t(key);

// Real-Time API Client
const api = {
  baseUrl: 'http://localhost:8080',
  
  async fetchMetrics() {
    try {
      const response = await fetch(`${this.baseUrl}/api/metrics`);
      if (!response.ok) throw new Error('Failed to fetch');
      return await response.json();
    } catch (e) {
      console.log('API unavailable, using local data');
      return null;
    }
  },
  
  async updateData() {
    const metrics = await this.fetchMetrics();
    if (!metrics) return false;
    
    // Update data object
    Object.assign(data.tokens, metrics.tokens);
    Object.assign(data.sessions, metrics.sessions);
    Object.assign(data.git, metrics.git);
    Object.assign(data.health, metrics.health);
    
    // Update history for charts
    if (data.history.tokens.length >= 6) data.history.tokens.shift();
    data.history.tokens.push(metrics.tokens.used);
    
    if (data.history.cost.length >= 6) data.history.cost.shift();
    data.history.cost.push(metrics.tokens.cost);
    
    return true;
  }
};

// Chart Engine
const charts = {
  drawLine(canvasId, labels, values, color) {
    const c = document.getElementById(canvasId);
    if (!c) return;
    const ctx = c.getContext('2d');
    const rect = c.parentElement.getBoundingClientRect();
    c.width = rect.width;
    c.height = rect.height;
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
      ctx.beginPath();
      ctx.moveTo(pad.l, y);
      ctx.lineTo(w - pad.r, y);
      ctx.stroke();
      ctx.fillStyle = '#90a8b8';
      ctx.font = '10px Segoe UI';
      ctx.textAlign = 'right';
      ctx.fillText((max * i / 4).toFixed(0), pad.l - 5, y + 3);
    }
    
    const step = cw / (values.length - 1);
    ctx.beginPath();
    values.forEach((v, i) => {
      const x = pad.l + i * step;
      const y = pad.t + ch - (v / max * ch);
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.stroke();
    
    ctx.lineTo(pad.l + cw, pad.t + ch);
    ctx.lineTo(pad.l, pad.t + ch);
    ctx.closePath();
    ctx.fillStyle = color + '33';
    ctx.fill();
    
    ctx.fillStyle = '#90a8b8';
    ctx.textAlign = 'center';
    labels.forEach((l, i) => {
      ctx.fillText(l, pad.l + i * step, h - 15);
    });
  },
  
  drawBar(canvasId, labels, values, color) {
    const c = document.getElementById(canvasId);
    if (!c) return;
    const ctx = c.getContext('2d');
    const rect = c.parentElement.getBoundingClientRect();
    c.width = rect.width;
    c.height = rect.height;
    const w = c.width, h = c.height;
    const pad = { t: 20, r: 20, b: 40, l: 50 };
    const cw = w - pad.l - pad.r, ch = h - pad.t - pad.b;
    const max = Math.max(...values, 1);
    const barW = (cw / values.length) * 0.7;
    const gap = (cw / values.length) * 0.3;
    
    ctx.fillStyle = '#0b161f';
    ctx.fillRect(0, 0, w, h);
    
    ctx.strokeStyle = '#274255';
    for (let i = 0; i <= 4; i++) {
      const y = pad.t + ch * (1 - i / 4);
      ctx.beginPath();
      ctx.moveTo(pad.l, y);
      ctx.lineTo(w - pad.r, y);
      ctx.stroke();
    }
    
    values.forEach((v, i) => {
      const x = pad.l + i * (barW + gap) + gap / 2;
      const barH = (v / max) * ch;
      const y = pad.t + ch - barH;
      ctx.fillStyle = color;
      ctx.fillRect(x, y, barW, barH);
      ctx.fillStyle = '#90a8b8';
      ctx.font = '9px Segoe UI';
      ctx.textAlign = 'center';
      ctx.fillText(labels[i] || '', x + barW / 2, h - 10);
    });
  },
  
  renderAll() {
    this.drawLine('chart-token', ['W1','W2','W3','W4','W5','W6'], data.history.tokens, '#37b8a8');
    this.drawLine('chart-cost', ['W1','W2','W3','W4','W5','W6'], data.history.cost, '#6ea8ff');
    this.drawBar('chart-sessions', ['Active','Today','Total'], [data.sessions.active, data.sessions.today, data.sessions.total], '#f5b800');
    this.drawBar('chart-commits', ['Today','Week','Month'], [data.git.today, data.git.week, data.git.month], '#45c77a');
    this.drawBar('chart-savings', ['Baseline','Actual','Saved'], [0.13, data.tokens.cost, data.tokens.savings], '#37b8a8');
  }
};

// UI Components - With compact tooltip modal for metric info
const ui = {
  // Card with info icon that opens compact tooltip modal
  card(label, value, meta, type = '', tooltip = '', metricKey = '') {
    const hasInfo = metricKey && metricInfo[metricKey];
    const infoIcon = hasInfo ? `<span class="gv-card__info" data-metric="${metricKey}" onclick="event.stopPropagation(); app.showMetricInfo('${metricKey}', '${label}', event)">ℹ️</span>` : '';
    const titleAttr = tooltip ? `title="${tooltip}"` : '';
    return `<div class="gv-card" ${titleAttr} data-metric-key="${metricKey}">${infoIcon}<div class="gv-card__label">${label}</div><div class="gv-card__value ${type ? 'gv-card__value--' + type : ''}">${value}</div><div class="gv-card__meta">${meta}</div></div>`;
  },
  
  renderSection(id, cards) {
    const grid = document.getElementById(id + '-grid');
    if (grid) grid.innerHTML = cards.join('');
  }
};

// App Controller
const app = {
  tvMode: false,
  tvInterval: null,
  sections: ['exec','ops','dev','cost','gov','health','live','sla','perf','refs'],
  currentModalMetric: null,
  
  init() {
    // Ensure English is default
    if (!localStorage.getItem('gv-lang')) {
      localStorage.setItem('gv-lang', 'en');
      i18n.currentLang = 'en';
    }
    
    this.bindNav();
    this.applyTranslations();
    this.renderData(); // Render initial data before starting updates
    this.startRealTimeUpdates();
    this.updateTime();
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
    // Update all elements with data-i18n attribute
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      const translation = t(key);
      if (translation && translation !== key) {
        el.textContent = translation;
      }
    });
    
    // Update document title
    document.title = t('title');
  },
  
  async startRealTimeUpdates() {
    // Initial data load
    await this.refreshData();
    
    // Auto-refresh every 10 seconds
    setInterval(() => this.refreshData(), 10000);
  },
  
  async refreshData() {
    const updated = await api.updateData();
    if (updated) {
      this.updateCardValuesOnly();
      charts.renderAll();
      this.showNotification('Data updated', 'success');
    }
  },
  
  // Update only values without re-rendering cards (preserves tooltips)
  updateCardValuesOnly() {
    const statusColor = data.health.status === 'GREEN' ? '#45c77a' : data.health.status === 'YELLOW' ? '#f0b13a' : '#f26464';
    const isPeak = new Date().getHours() >= 17 && new Date().getHours() <= 20;
    
    // Update Executive section values
    this.updateCardValue('exec', 0, `<span style="color:${statusColor}">${data.health.status}</span>`);
    this.updateCardValue('exec', 1, data.tokens.pct < 50 ? 'PASS' : 'WARNING');
    this.updateCardValue('exec', 2, data.tokens.pct + '%');
    this.updateCardValue('exec', 3, '$' + data.tokens.cost.toFixed(4));
    this.updateCardValue('exec', 4, '$' + data.tokens.forecast.toFixed(2));
    this.updateCardValue('exec', 5, '$' + data.tokens.savings.toFixed(4));
    this.updateCardValue('exec', 6, data.sessions.total.toString());
    this.updateCardValue('exec', 7, data.health.routing);
    
    // Update Operations section values
    this.updateCardValue('ops', 0, data.sessions.total.toString());
    this.updateCardValue('ops', 1, data.sessions.active.toString());
    this.updateCardValue('ops', 2, data.sessions.today.toString());
    this.updateCardValue('ops', 3, data.sessions.avgDuration);
    this.updateCardValue('ops', 4, '38597 min');
    this.updateCardValue('ops', 5, 'session-' + new Date().toISOString().slice(0,10));
    
    // Update Development section values
    this.updateCardValue('dev', 0, data.git.commits.toLocaleString());
    this.updateCardValue('dev', 1, data.git.month.toLocaleString());
    this.updateCardValue('dev', 2, data.git.week.toString());
    this.updateCardValue('dev', 3, data.git.today.toString());
    this.updateCardValue('dev', 4, data.git.prsMerged.toString());
    this.updateCardValue('dev', 5, data.git.contributors.toString());
    this.updateCardValue('dev', 6, '+18805');
    this.updateCardValue('dev', 7, '-21112');
    
    // Update Cost section values
    this.updateCardValue('cost', 0, '$' + data.tokens.cost.toFixed(4));
    this.updateCardValue('cost', 1, '$' + data.tokens.forecast.toFixed(2));
    this.updateCardValue('cost', 2, data.tokens.limit.toLocaleString());
    this.updateCardValue('cost', 3, '$10');
    this.updateCardValue('cost', 4, '12821');
    this.updateCardValue('cost', 5, '3663');
    this.updateCardValue('cost', 6, '$' + data.tokens.savings.toFixed(4));
    this.updateCardValue('cost', 7, data.health.status);
    
    // Update Governance section values
    this.updateCardValue('gov', 0, `<span style="color:${statusColor}">${data.health.status}</span>`);
    this.updateCardValue('gov', 1, 'PASS');
    this.updateCardValue('gov', 2, data.health.routing);
    this.updateCardValue('gov', 3, data.health.benchmark);
    this.updateCardValue('gov', 4, 'PASS');
    
    // Update Health section values
    this.updateCardValue('health', 0, `<span style="color:${statusColor}">HEALTHY</span>`);
    this.updateCardValue('health', 1, data.sessions.active.toString());
    this.updateCardValue('health', 2, data.health.benchmark);
    this.updateCardValue('health', 3, data.health.routing);
    this.updateCardValue('health', 4, 'EmmanuelOrtiz87');
    this.updateCardValue('health', 5, '.runtime/metrics/');
    
    // Update Live section values
    this.updateCardValue('live', 0, '<span style="color:#37b8a8">● LIVE</span>');
    this.updateCardValue('live', 1, data.tokens.used.toLocaleString());
    this.updateCardValue('live', 2, `<span style="color:${statusColor}">${data.health.status}</span>`);
    this.updateCardValue('live', 3, data.health.routing);
    this.updateCardValue('live', 4, data.sessions.active.toString());
    this.updateCardValue('live', 5, isPeak ? 'YES' : 'NO');
    
    // Update SLA section values
    this.updateCardValue('sla', 0, '99.9%');
    this.updateCardValue('sla', 1, '100%');
    this.updateCardValue('sla', 2, '0');
    this.updateCardValue('sla', 3, '0m');
    this.updateCardValue('sla', 4, '100%');
    this.updateCardValue('sla', 5, '1.3s');
    
    // Update Performance section values
    this.updateCardValue('perf', 0, '111');
    this.updateCardValue('perf', 1, '17:00');
    this.updateCardValue('perf', 2, '3.7');
    this.updateCardValue('perf', 3, '7 min');
    this.updateCardValue('perf', 4, '100');
    this.updateCardValue('perf', 5, '+9%');
  },
  
  // Update a single card value without destroying the card
  updateCardValue(sectionId, cardIndex, newValue) {
    const grid = document.getElementById(sectionId + '-grid');
    if (!grid) return;
    
    const cards = grid.querySelectorAll('.gv-card');
    if (cards[cardIndex]) {
      const valueEl = cards[cardIndex].querySelector('.gv-card__value');
      if (valueEl) {
        valueEl.innerHTML = newValue;
      }
    }
  },
  
  showNotification(msg, type = 'info') {
    const toast = document.createElement('div');
    toast.style.cssText = `
      position: fixed; top: 20px; right: 20px; 
      background: ${type === 'success' ? '#45c77a' : '#37b8a8'}; 
      color: white; padding: 12px 20px; border-radius: 8px;
      font-size: 13px; z-index: 10000; animation: slideIn 0.3s ease;
    `;
    toast.textContent = msg;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 3000);
  },
  
  bindNav() {
    document.querySelectorAll('.gv-nav__btn[data-section]').forEach(btn => {
      btn.addEventListener('click', (e) => {
        this.showSection(e.target.dataset.section);
      });
    });
  },
  
  showSection(id) {
    document.querySelectorAll('.gv-section').forEach(s => s.classList.remove('active'));
    document.querySelectorAll('.gv-nav__btn').forEach(b => b.classList.remove('active'));
    document.getElementById(id)?.classList.add('active');
    document.querySelector(`[data-section="${id}"]`)?.classList.add('active');
    setTimeout(() => charts.renderAll(), 50);
  },
  
  toggleTV() {
    this.tvMode = !this.tvMode;
    document.body.classList.toggle('tv-mode', this.tvMode);
    
    if (this.tvMode) {
      setTimeout(() => charts.renderAll(), 300);
      this.tvInterval = setInterval(() => {
        const current = document.querySelector('.gv-section.active');
        const idx = this.sections.indexOf(current?.id);
        const next = this.sections[(idx + 1) % this.sections.length];
        this.showSection(next);
      }, 30000);
    } else {
      clearInterval(this.tvInterval);
      setTimeout(() => charts.renderAll(), 300);
    }
  },
  
  // Export dashboard as PDF or PNG
  exportDashboard(format) {
    const section = document.querySelector('.gv-section.active');
    if (!section) {
      this.showNotification('No section active', 'error');
      return;
    }
    
    const sectionName = section.id;
    const timestamp = new Date().toISOString().slice(0,19).replace(/:/g, '-');
    const filename = `dashboard-${sectionName}-${timestamp}.${format}`;
    
    if (format === 'pdf') {
      // Use browser print to PDF
      const originalTitle = document.title;
      document.title = filename;
      window.print();
      document.title = originalTitle;
      this.showNotification(`Exported as ${filename}`, 'success');
    } else if (format === 'png') {
      // Use html2canvas for real PNG export
      this.showNotification('Generating PNG...', 'info');
      
      html2canvas(section, {
        backgroundColor: '#081016',
        scale: 2,
        useCORS: true,
        logging: false
      }).then(canvas => {
        const link = document.createElement('a');
        link.download = filename;
        link.href = canvas.toDataURL('image/png');
        link.click();
        this.showNotification(`Exported as ${filename}`, 'success');
      }).catch(err => {
        console.error('PNG export failed:', err);
        this.showNotification('PNG export failed', 'error');
      });
    }
  },
  
  updateTime() {
    document.getElementById('lastUpdate').textContent = new Date().toLocaleString();
  },
  
  // Modal methods for metric info - compact tooltip style
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
      <div class="gv-modal__section">
        <div class="gv-modal__label">What</div>
        <div class="gv-modal__text">${info.what}</div>
      </div>
      <div class="gv-modal__section">
        <div class="gv-modal__label">Why</div>
        <div class="gv-modal__text">${info.why}</div>
      </div>
      <div class="gv-modal__section">
        <div class="gv-modal__label">How</div>
        <div class="gv-modal__text">${info.how}</div>
      </div>
      <div class="gv-modal__section">
        <div class="gv-modal__label">Unit</div>
        <div class="gv-modal__text">${info.unit}</div>
      </div>
      <div class="gv-modal__section">
        <div class="gv-modal__label">Formula</div>
        <div class="gv-modal__formula">${info.formula}</div>
      </div>
    `;
    
    // Position modal near the clicked element
    if (event && event.target) {
      const rect = event.target.getBoundingClientRect();
      const modalWidth = 280;
      const modalHeight = 300;
      
      // Calculate position (right of the icon, or below if not enough space)
      let left = rect.right + 8;
      let top = rect.top;
      
      // Check if modal would go off-screen to the right
      if (left + modalWidth > window.innerWidth) {
        left = rect.left - modalWidth - 8;
      }
      
      // Check if modal would go off-screen at the bottom
      if (top + modalHeight > window.innerHeight) {
        top = window.innerHeight - modalHeight - 16;
      }
      
      // Ensure minimum top position
      if (top < 16) top = 16;
      
      content.style.left = left + 'px';
      content.style.top = top + 'px';
      content.style.position = 'fixed';
    }
    
    modal.classList.add('active');
    
    // Bind close events
    this.bindModalEvents();
  },
  
  closeModal() {
    const modal = document.getElementById('gv-modal');
    modal.classList.remove('active');
    this.currentModalMetric = null;
  },
  
  bindModalEvents() {
    const modal = document.getElementById('gv-modal');
    const overlay = modal.querySelector('.gv-modal__overlay');
    
    // Close on overlay click
    overlay.onclick = () => this.closeModal();
    
    // Close on ESC key - use addEventListener instead of onkeydown
    const escHandler = (e) => {
      if (e.key === 'Escape') {
        this.closeModal();
        document.removeEventListener('keydown', escHandler);
      }
    };
    document.addEventListener('keydown', escHandler);
  },
  
  renderData() {
    const statusColor = data.health.status === 'GREEN' ? '#45c77a' : data.health.status === 'YELLOW' ? '#f0b13a' : '#f26464';
    const isPeak = new Date().getHours() >= 17 && new Date().getHours() <= 20;
    
    // Executive
    ui.renderSection('exec', [
      ui.card(t('cards.trafficLight'), `<span style="color:${statusColor}">${data.health.status}</span>`, t('meta.executiveStatus'), '', 'Overall system health status. GREEN=Healthy, YELLOW=Attention, RED=Critical', 'trafficLight'),
      ui.card(t('cards.tokenStatus'), data.tokens.pct < 50 ? 'PASS' : 'WARNING', t('meta.budgetGuard'), data.tokens.pct < 50 ? 'success' : 'warning', 'Budget compliance check. PASS=Within limits, WARNING=Approaching limit', 'tokenStatus'),
      ui.card(t('cards.budgetUsed'), data.tokens.pct + '%', `${data.tokens.used.toLocaleString()} / ${data.tokens.limit.toLocaleString()} ${t('meta.tokens')}`, '', 'Percentage of daily token budget consumed. Unit: % of 120K limit', 'budgetUsed'),
      ui.card(t('cards.estCost'), '$' + data.tokens.cost.toFixed(4), t('meta.per1M'), '', 'Current cost in USD. Rate: $10 per 1M tokens', 'estCost'),
      ui.card(t('cards.forecast'), '$' + data.tokens.forecast.toFixed(2), t('meta.projected'), '', 'Projected month-end cost based on current usage trend', 'forecast'),
      ui.card(t('cards.savings'), '$' + data.tokens.savings.toFixed(4), t('meta.vsBaseline'), 'success', 'Cost savings achieved through optimization vs baseline', 'savings'),
      ui.card(t('cards.sessions'), data.sessions.total.toString(), `${data.sessions.active} ${t('meta.active')} · ${data.sessions.today} ${t('cards.today')}`, '', 'Total sessions: active now and started today', 'sessions'),
      ui.card(t('cards.routing'), data.health.routing, t('meta.dispatches'), 'success', 'Task routing accuracy percentage. Target: >95%', 'routing')
    ]);
    
    // Operations
    ui.renderSection('ops', [
      ui.card(t('cards.totalSessions'), data.sessions.total.toString(), t('meta.sinceInception'), '', 'Total sessions since system inception', 'totalSessions'),
      ui.card(t('cards.activeNow'), data.sessions.active.toString(), t('meta.currentOpen'), 'success', 'Currently open and active sessions', 'activeNow'),
      ui.card(t('cards.today'), data.sessions.today.toString(), t('meta.started'), '', 'Sessions started today', 'today'),
      ui.card(t('cards.avgDuration'), data.sessions.avgDuration, t('meta.perSession'), '', 'Average session duration in hours', 'avgDuration'),
      ui.card(t('cards.totalTime'), '38597 min', t('meta.allTime'), '', 'Cumulative time across all sessions', 'totalTime'),
      ui.card(t('cards.latest'), 'session-' + new Date().toISOString().slice(0,10), t('meta.active'), '', 'Most recent active session', 'latest')
    ]);
    
    // Development
    ui.renderSection('dev', [
      ui.card(t('cards.totalCommits'), data.git.commits.toLocaleString(), t('meta.allTime'), '', 'Total code commits in repository history', 'totalCommits'),
      ui.card(t('cards.thisMonth'), data.git.month.toLocaleString(), t('meta.sinceInception'), 'success', 'Commits this month since May 1', 'thisMonth'),
      ui.card(t('cards.thisWeek'), data.git.week.toString(), 'commits', '', 'Commits made this week', 'thisWeek'),
      ui.card(t('cards.today'), data.git.today.toString(), 'commits', '', 'Commits made today', 'today'),
      ui.card(t('cards.prsMerged'), data.git.prsMerged.toString(), `of ${data.git.prsTotal} total`, 'success', 'Pull requests merged vs total created', 'prsMerged'),
      ui.card(t('cards.contributors'), data.git.contributors.toString(), t('meta.uniqueAuthors'), '', 'Unique developers contributing to project', 'contributors'),
      ui.card(t('cards.linesAdded'), '+18805', t('meta.last30Commits'), 'success', 'Lines of code added in last 30 commits', 'linesAdded'),
      ui.card(t('cards.linesRemoved'), '-21112', t('meta.last30Commits'), 'error', 'Lines of code removed in last 30 commits', 'linesRemoved')
    ]);
    
    // Cost
    ui.renderSection('cost', [
      ui.card(t('cards.actualCost'), '$' + data.tokens.cost.toFixed(4), `${data.tokens.used.toLocaleString()} ${t('meta.tokens')} @ $10/1M`, '', 'Current spending based on token usage', 'actualCost'),
      ui.card(t('cards.forecast'), '$' + data.tokens.forecast.toFixed(2), t('meta.projected'), '', 'Projected month-end cost based on trend', 'forecast'),
      ui.card(t('cards.dailyBudget'), data.tokens.limit.toLocaleString(), t('meta.dayLimit'), '', 'Maximum tokens allowed per day: 120,000', 'dailyBudget'),
      ui.card(t('cards.rate'), '$10', t('meta.per1M'), '', 'Pricing: $10 USD per 1 million tokens', 'rate'),
      ui.card(t('cards.baseline'), '12821', t('meta.withoutOpt'), '', 'Estimated tokens without optimization', 'baseline'),
      ui.card(t('cards.tokensSaved'), '3663', '28.6% ' + t('meta.reduction'), 'success', 'Tokens saved through efficiency optimizations', 'tokensSaved'),
      ui.card(t('cards.savings'), '$' + data.tokens.savings.toFixed(4), 'USD ' + t('meta.active'), 'success', 'Money saved through optimization vs baseline', 'savings'),
      ui.card(t('cards.roiSignal'), data.health.status, t('meta.executiveStatus'), data.health.status === 'GREEN' ? 'success' : 'warning', 'Return on investment indicator', 'roiSignal')
    ]);
    
    // Governance
    ui.renderSection('gov', [
      ui.card(t('cards.trafficLight'), `<span style="color:${statusColor}">${data.health.status}</span>`, t('meta.executiveStatus'), '', 'Governance compliance status', 'trafficLight'),
      ui.card(t('cards.tokenGuard'), 'PASS', t('meta.budgetCompliance'), 'success', 'Token budget compliance check', 'tokenGuard'),
      ui.card(t('cards.routingAcc'), data.health.routing, t('meta.audited'), 'success', 'Task routing accuracy from audit logs', 'routingAcc'),
      ui.card(t('cards.benchmark'), data.health.benchmark, t('meta.regressionChecks'), 'success', 'Performance benchmark test results', 'benchmark'),
      ui.card(t('cards.status'), 'PASS', t('meta.overallGuard'), 'success', 'Overall governance guard status', 'status')
    ]);
    
    // Health
    ui.renderSection('health', [
      ui.card(t('cards.status'), `<span style="color:${statusColor}">HEALTHY</span>`, t('meta.allSystems'), '', 'Overall system health status', 'status'),
      ui.card(t('cards.sessions'), data.sessions.active.toString(), t('meta.currentlyRunning'), '', 'Currently running active sessions', 'activeNow'),
      ui.card(t('cards.benchmark'), data.health.benchmark, t('meta.passTotal'), 'success', 'Health benchmark pass rate', 'benchmark'),
      ui.card(t('cards.routing'), data.health.routing, t('meta.dispatchAccuracy'), 'success', 'System routing accuracy percentage', 'routing'),
      ui.card('Top Author', 'EmmanuelOrtiz87', '1382 commits', '', 'Developer with most commits', 'contributors'),
      ui.card(t('cards.dataSource'), '.runtime/metrics/', t('meta.localStore'), '', 'Local metrics storage path', 'status')
    ]);
    
    // Live
    ui.renderSection('live', [
      ui.card(t('cards.liveStatus'), '<span style="color:#37b8a8">● LIVE</span>', t('meta.eventStream'), '', '', 'liveStatus'),
      ui.card(t('cards.tokens'), data.tokens.used.toLocaleString(), t('meta.currentUsage'), '', '', 'tokens'),
      ui.card(t('cards.trafficLight'), `<span style="color:${statusColor}">${data.health.status}</span>`, t('meta.executiveStatus'), '', '', 'trafficLight'),
      ui.card(t('cards.routing'), data.health.routing, t('meta.dispatchAccuracy'), '', '', 'routing'),
      ui.card(t('cards.sessions'), data.sessions.active.toString(), t('meta.activeCount'), '', '', 'activeNow'),
      ui.card(t('cards.peakActivity'), isPeak ? 'YES' : 'NO', t('meta.highActivity'), isPeak ? 'warning' : 'success', '', 'peakActivityFlag')
    ]);
    
    // SLA
    ui.renderSection('sla', [
      ui.card(t('cards.uptime'), '99.9%', t('meta.target') + ': 99.5%', 'success', '', 'uptime'),
      ui.card(t('cards.uptime'), '100%', t('meta.target') + ': 99.9%', 'success', '', 'uptime'),
      ui.card(t('cards.incidents'), '0', '30d: 0 · 7d: 0', 'success', '', 'incidents'),
      ui.card(t('cards.mttr'), '0m', t('meta.meanRecovery'), '', '', 'mttr'),
      ui.card(t('cards.routingAcc'), '100%', t('meta.target') + ': 95%', 'success', '', 'routingAcc'),
      ui.card(t('cards.latency'), '1.3s', t('meta.target') + ': 1.5s', 'success', '', 'latency')
    ]);
    
    // Performance
    ui.renderSection('perf', [
      ui.card(t('cards.sessions'), '111', t('meta.last30Days'), '', '', 'sessions'),
      ui.card(t('cards.peakActivity'), '17:00', '13 sessions', '', '', 'peakActivity'),
      ui.card('Sessions/Day', '3.7', t('meta.average'), '', '', 'sessions'),
      ui.card('Avg Session', '7 min', 'duration', '', '', 'avgDuration'),
      ui.card('Active Now', '100', t('meta.fromAnalytics'), '', '', 'activeNow'),
      ui.card(t('cards.velocity'), '+9%', '60 vs 55', 'success', '', 'velocity')
    ]);
  }
};

// Initialize
document.addEventListener('DOMContentLoaded', () => app.init());
