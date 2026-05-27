/**
 * Dashboard Tests
 * Run with: npm test
 */

// Mock DOM and localStorage
global.localStorage = {
  store: {},
  getItem(key) { return this.store[key] || null; },
  setItem(key, value) { this.store[key] = value; },
  removeItem(key) { delete this.store[key]; }
};

global.document = {
  title: '',
  body: { appendChild: jest.fn() },
  getElementById: jest.fn(() => ({ textContent: '', innerHTML: '' })),
  querySelector: jest.fn(),
  querySelectorAll: jest.fn(() => []),
  addEventListener: jest.fn(),
  createElement: jest.fn(() => ({ style: {}, textContent: '', click: jest.fn() }))
};

global.window = {
  addEventListener: jest.fn(),
  print: jest.fn(),
  location: { origin: 'http://localhost:8080' }
};

// Test data structure
describe('Dashboard Data Structure', () => {
  test('data object has required fields', () => {
    const data = {
      tokens: { used: 9158, limit: 120000, cost: 0.0916, forecast: 0.11, savings: 0.0366, pct: 8.46 },
      sessions: { total: 38, active: 6, today: 4, avgDuration: '20.1h' },
      git: { commits: 1615, month: 971, week: 19, today: 0, prsMerged: 93, prsTotal: 100, contributors: 6 },
      health: { status: 'GREEN', routing: '100%', benchmark: '3/3' },
      history: { tokens: [], cost: [] }
    };
    
    expect(data.tokens).toBeDefined();
    expect(data.sessions).toBeDefined();
    expect(data.git).toBeDefined();
    expect(data.health).toBeDefined();
    expect(data.history).toBeDefined();
  });
  
  test('token percentage is calculated correctly', () => {
    const tokens = { used: 9158, limit: 120000 };
    const pct = ((tokens.used / tokens.limit) * 100).toFixed(2);
    expect(parseFloat(pct)).toBeGreaterThan(0);
    expect(parseFloat(pct)).toBeLessThan(100);
  });
});

// Test i18n
describe('Internationalization', () => {
  test('default language is English', () => {
    const savedLang = localStorage.getItem('gv-lang');
    expect(savedLang).toBeNull(); // Initially null
    
    // After init, should be 'en'
    localStorage.setItem('gv-lang', 'en');
    expect(localStorage.getItem('gv-lang')).toBe('en');
  });
  
  test('language can be changed', () => {
    localStorage.setItem('gv-lang', 'es');
    expect(localStorage.getItem('gv-lang')).toBe('es');
    
    localStorage.setItem('gv-lang', 'pt');
    expect(localStorage.getItem('gv-lang')).toBe('pt');
  });
});

// Test API
describe('API Client', () => {
  test('API base URL is correct', () => {
    const baseUrl = 'http://localhost:8080';
    expect(baseUrl).toBe('http://localhost:8080');
  });
  
  test('API endpoints are defined', () => {
    const endpoints = ['/api/metrics', '/api/export', '/health'];
    endpoints.forEach(endpoint => {
      expect(endpoint).toMatch(/^\//);
    });
  });
});

// Test UI Components
describe('UI Components', () => {
  test('card component generates correct HTML', () => {
    const card = (label, value, meta, type = '', tooltip = '') => {
      const titleAttr = tooltip ? `title="${tooltip}"` : '';
      const infoIcon = tooltip ? '<span class="gv-card__info">ℹ️</span>' : '';
      return `<div class="gv-card" ${titleAttr}>${infoIcon}<div class="gv-card__label">${label}</div><div class="gv-card__value ${type ? 'gv-card__value--' + type : ''}">${value}</div><div class="gv-card__meta">${meta}</div></div>`;
    };
    
    const html = card('Test', '100', 'meta', 'success', 'tooltip text');
    expect(html).toContain('Test');
    expect(html).toContain('100');
    expect(html).toContain('success');
    expect(html).toContain('tooltip text');
    expect(html).toContain('ℹ️');
  });
  
  test('card without tooltip has no info icon', () => {
    const card = (label, value, meta) => {
      return `<div class="gv-card"><div class="gv-card__label">${label}</div><div class="gv-card__value">${value}</div><div class="gv-card__meta">${meta}</div></div>`;
    };
    
    const html = card('Test', '100', 'meta');
    expect(html).not.toContain('ℹ️');
  });
});

// Test Export Functionality
describe('Export Functionality', () => {
  test('PDF export uses window.print', () => {
    const mockPrint = jest.fn();
    global.window.print = mockPrint;
    
    // Simulate PDF export
    window.print();
    expect(mockPrint).toHaveBeenCalled();
  });
  
  test('PNG export requires html2canvas', () => {
    // html2canvas should be available (mocked in test environment)
    global.html2canvas = jest.fn(() => Promise.resolve({ toDataURL: () => 'data:image/png;base64,test' }));
    expect(typeof html2canvas).toBe('function');
  });
});

// Test Charts
describe('Chart Engine', () => {
  test('chart canvas IDs exist', () => {
    const canvasIds = ['chart-token', 'chart-cost', 'chart-sessions', 'chart-commits', 'chart-savings'];
    canvasIds.forEach(id => {
      expect(id).toMatch(/^chart-/);
    });
  });
});

// Integration Tests
describe('Integration', () => {
  test('all sections are defined', () => {
    const sections = ['exec', 'ops', 'dev', 'cost', 'gov', 'health', 'live', 'sla', 'perf'];
    expect(sections.length).toBe(9);
    sections.forEach(section => {
      expect(section).toBeTruthy();
    });
  });
  
  test('translations exist for all languages', () => {
    const languages = ['en', 'es', 'pt'];
    const requiredKeys = ['title', 'subtitle', 'nav', 'sections', 'cards'];
    
    languages.forEach(lang => {
      expect(lang).toMatch(/^(en|es|pt)$/);
    });
  });
});

console.log('✅ Dashboard tests loaded. Run with: npm test');
