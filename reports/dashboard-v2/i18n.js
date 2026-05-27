// i18n - Internationalization
const i18n = {
  currentLang: localStorage.getItem('gv-lang') || 'en',
  
  // Ensure English is default on init
  init() {
    const savedLang = localStorage.getItem('gv-lang');
    if (!savedLang) {
      localStorage.setItem('gv-lang', 'en');
      this.currentLang = 'en';
    } else {
      this.currentLang = savedLang;
    }
    document.documentElement.lang = this.currentLang;
  },
  
  t(key) {
    const keys = key.split('.');
    let value = this.translations[this.currentLang];
    for (const k of keys) {
      value = value?.[k];
    }
    return value || key;
  },
  
  setLang(lang) {
    this.currentLang = lang;
    localStorage.setItem('gv-lang', lang);
    document.documentElement.lang = lang;
  },
  
  translations: {
    es: {
      title: 'Gentle-Vanguard Dashboard',
      subtitle: 'Métricas en tiempo real',
      lastUpdate: 'Última actualización',
      nav: { executive: 'Ejecutivo', operations: 'Operaciones', development: 'Desarrollo', cost: 'Costo', governance: 'Gobernanza', health: 'Salud', live: 'En Vivo', sla: 'SLA', performance: 'Rendimiento', references: 'Referencias', tv: 'TV' },
      sections: { executive: 'Vista Ejecutiva', operations: 'Operaciones', development: 'Desarrollo', cost: 'Costo y ROI', governance: 'Gobernanza', health: 'Salud del Sistema', live: 'Feed en Vivo', sla: 'Acuerdos de Nivel de Servicio', performance: 'Rendimiento', references: 'Referencias y Glosario' },
      cards: { trafficLight: 'Semáforo', tokenStatus: 'Estado Tokens', budgetUsed: 'Presupuesto Usado', estCost: 'Costo Est.', forecast: 'Pronóstico', savings: 'Ahorros', sessions: 'Sesiones', routing: 'Enrutamiento', totalSessions: 'Sesiones Totales', activeNow: 'Activas Ahora', today: 'Hoy', avgDuration: 'Duración Promedio', totalTime: 'Tiempo Total', latest: 'Última', totalCommits: 'Commits Totales', thisMonth: 'Este Mes', thisWeek: 'Esta Semana', prsMerged: 'PRs Mergeados', contributors: 'Contribuidores', linesAdded: 'Líneas Agregadas', linesRemoved: 'Líneas Eliminadas', actualCost: 'Costo Actual', dailyBudget: 'Presupuesto Diario', rate: 'Tarifa', baseline: 'Línea Base', tokensSaved: 'Tokens Ahorrados', roiSignal: 'Señal ROI', tokenGuard: 'Guardia Tokens', routingAcc: 'Precisión Enrutamiento', benchmark: 'Benchmark', status: 'Estado', uptime: 'Disponibilidad', incidents: 'Incidentes', mttr: 'MTTR', latency: 'Latencia', peakActivity: 'Actividad Pico', velocity: 'Velocidad' },
      meta: { executiveStatus: 'estado ejecutivo', budgetGuard: 'guardia presupuesto', tokens: 'tokens', per1M: 'por 1M tokens', projected: 'proyectado', vsBaseline: 'vs línea base', active: 'activas', dispatches: 'despachos', sinceInception: 'desde inicio', currentOpen: 'abiertas actualmente', started: 'iniciadas', perSession: 'por sesión', allTime: 'todo el tiempo', uniqueAuthors: 'autores únicos', last30Commits: 'últimos 30 commits', dayLimit: 'límite diario', withoutOpt: 'sin optimización', reduction: 'reducción', budgetCompliance: 'cumplimiento presupuesto', audited: 'auditados', regressionChecks: 'chequeos regresión', overallGuard: 'guardia general', allSystems: 'todos sistemas operativos', currentlyRunning: 'ejecutándose', passTotal: 'aprobado/total', dispatchAccuracy: 'precisión despacho', localStore: 'almacenamiento local', eventStream: 'flujo eventos', currentUsage: 'uso actual', activeCount: 'conteo activo', highActivity: 'alta actividad', target: 'objetivo', meanRecovery: 'tiempo medio recuperación', last30Days: 'últimos 30 días', average: 'promedio', fromAnalytics: 'de analíticas' },
      chartTitles: { tokenTrend: 'Tendencia Tokens', costBreakdown: 'Desglose Costos', sessionActivity: 'Actividad Sesiones', commitsByAuthor: 'Commits por Autor', savingsAnalysis: 'Análisis Ahorros', commitsTimeline: 'Línea Tiempo Commits' },
      references: { title: 'Referencias y Glosario', description: 'Esta sección explica el propósito y significado de cada métrica.', trafficLight: { title: 'Semáforo', purpose: 'Indicador visual del estado general', meaning: 'GREEN = Saludable, YELLOW = Atención, RED = Crítico' }, tokens: { title: 'Tokens', purpose: 'Uso de tokens API LLM', meaning: 'Consumidos vs presupuesto asignado' }, sessions: { title: 'Sesiones', purpose: 'Seguimiento sesiones activas', meaning: 'Abiertas, activas y totales' }, commits: { title: 'Commits', purpose: 'Actividad en repositorio', meaning: 'Cambios confirmados por período' }, routing: { title: 'Enrutamiento', purpose: 'Precisión delegación automática', meaning: '% tareas enrutadas correctamente' }, sla: { title: 'SLA', purpose: 'Cumplimiento acuerdos servicio', meaning: 'Disponibilidad y confiabilidad' }, mttr: { title: 'MTTR', purpose: 'Tiempo medio recuperación', meaning: 'Minutos para restaurar servicio' } }
    },
    pt: {
      title: 'Gentle-Vanguard Dashboard',
      subtitle: 'Métricas em tempo real',
      lastUpdate: 'Última atualização',
      nav: { executive: 'Executivo', operations: 'Operações', development: 'Desenvolvimento', cost: 'Custo', governance: 'Governança', health: 'Saúde', live: 'Ao Vivo', sla: 'SLA', performance: 'Desempenho', references: 'Referências', tv: 'TV' },
      sections: { executive: 'Visão Executiva', operations: 'Operações', development: 'Desenvolvimento', cost: 'Custo e ROI', governance: 'Governança', health: 'Saúde do Sistema', live: 'Feed ao Vivo', sla: 'Acordos Nível Serviço', performance: 'Desempenho', references: 'Referências e Glossário' },
      cards: { trafficLight: 'Semáforo', tokenStatus: 'Status Tokens', budgetUsed: 'Orçamento Usado', estCost: 'Custo Est.', forecast: 'Previsão', savings: 'Economias', sessions: 'Sessões', routing: 'Roteamento', totalSessions: 'Sessões Totais', activeNow: 'Ativas Agora', today: 'Hoje', avgDuration: 'Duração Média', totalTime: 'Tempo Total', latest: 'Última', totalCommits: 'Commits Totais', thisMonth: 'Este Mês', thisWeek: 'Esta Semana', prsMerged: 'PRs Mergeados', contributors: 'Contribuidores', linesAdded: 'Linhas Adicionadas', linesRemoved: 'Linhas Removidas', actualCost: 'Custo Atual', dailyBudget: 'Orçamento Diário', rate: 'Taxa', baseline: 'Linha Base', tokensSaved: 'Tokens Economizados', roiSignal: 'Sinal ROI', tokenGuard: 'Guarda Tokens', routingAcc: 'Precisão Roteamento', benchmark: 'Benchmark', status: 'Status', uptime: 'Disponibilidade', incidents: 'Incidentes', mttr: 'MTTR', latency: 'Latência', peakActivity: 'Atividade Pico', velocity: 'Velocidade' },
      meta: { executiveStatus: 'status executivo', budgetGuard: 'guarda orçamento', tokens: 'tokens', per1M: 'por 1M tokens', projected: 'projetado', vsBaseline: 'vs linha base', active: 'ativas', dispatches: 'despachos', sinceInception: 'desde início', currentOpen: 'abertas atualmente', started: 'iniciadas', perSession: 'por sessão', allTime: 'todo tempo', uniqueAuthors: 'autores únicos', last30Commits: 'últimos 30 commits', dayLimit: 'limite diário', withoutOpt: 'sem otimização', reduction: 'redução', budgetCompliance: 'conformidade orçamentária', audited: 'auditados', regressionChecks: 'checagens regressão', overallGuard: 'guarda geral', allSystems: 'todos sistemas operacionais', currentlyRunning: 'executando', passTotal: 'aprovado/total', dispatchAccuracy: 'precisão despacho', localStore: 'armazenamento local', eventStream: 'fluxo eventos', currentUsage: 'uso atual', activeCount: 'contagem ativa', highActivity: 'alta atividade', target: 'alvo', meanRecovery: 'tempo médio recuperação', last30Days: 'últimos 30 dias', average: 'média', fromAnalytics: 'de analíticas' },
      chartTitles: { tokenTrend: 'Tendência Tokens', costBreakdown: 'Detalhamento Custos', sessionActivity: 'Atividade Sessões', commitsByAuthor: 'Commits por Autor', savingsAnalysis: 'Análise Economias', commitsTimeline: 'Linha Tempo Commits' },
      references: { title: 'Referências e Glossário', description: 'Esta seção explica o propósito e significado de cada métrica.', trafficLight: { title: 'Semáforo', purpose: 'Indicador visual estado geral', meaning: 'GREEN = Saudável, YELLOW = Atenção, RED = Crítico' }, tokens: { title: 'Tokens', purpose: 'Uso tokens API LLM', meaning: 'Consumidos vs orçamento atribuído' }, sessions: { title: 'Sessões', purpose: 'Acompanhamento sessões ativas', meaning: 'Abertas, ativas e totais' }, commits: { title: 'Commits', purpose: 'Atividade no repositório', meaning: 'Mudanças confirmadas por período' }, routing: { title: 'Roteamento', purpose: 'Precisão delegação automática', meaning: '% tarefas roteadas corretamente' }, sla: { title: 'SLA', purpose: 'Cumprimento acordos serviço', meaning: 'Disponibilidade e confiabilidade' }, mttr: { title: 'MTTR', purpose: 'Tempo médio recuperação', meaning: 'Minutos para restaurar serviço' } }
    },
    en: {
      title: 'Gentle-Vanguard Dashboard',
      subtitle: 'Real-time metrics',
      lastUpdate: 'Last updated',
      nav: { executive: 'Executive', operations: 'Operations', development: 'Development', cost: 'Cost', governance: 'Governance', health: 'Health', live: 'Live', sla: 'SLA', performance: 'Performance', references: 'References', tv: 'TV' },
      sections: { executive: 'Executive Overview', operations: 'Operations', development: 'Development', cost: 'Cost & ROI', governance: 'Governance', health: 'System Health', live: 'Live Feed', sla: 'Service Level Agreements', performance: 'Performance', references: 'References & Glossary' },
      cards: { trafficLight: 'Traffic Light', tokenStatus: 'Token Status', budgetUsed: 'Budget Used', estCost: 'Est. Cost', forecast: 'Forecast', savings: 'Savings', sessions: 'Sessions', routing: 'Routing', totalSessions: 'Total Sessions', activeNow: 'Active Now', today: 'Today', avgDuration: 'Avg Duration', totalTime: 'Total Time', latest: 'Latest', totalCommits: 'Total Commits', thisMonth: 'This Month', thisWeek: 'This Week', prsMerged: 'PRs Merged', contributors: 'Contributors', linesAdded: 'Lines Added', linesRemoved: 'Lines Removed', actualCost: 'Actual Cost', dailyBudget: 'Daily Budget', rate: 'Rate', baseline: 'Baseline', tokensSaved: 'Tokens Saved', roiSignal: 'ROI Signal', tokenGuard: 'Token Guard', routingAcc: 'Routing Accuracy', benchmark: 'Benchmark', status: 'Status', uptime: 'Uptime', incidents: 'Incidents', mttr: 'MTTR', latency: 'Latency', peakActivity: 'Peak Activity', velocity: 'Velocity' },
      meta: { executiveStatus: 'executive status', budgetGuard: 'budget guard', tokens: 'tokens', per1M: 'per 1M tokens', projected: 'projected', vsBaseline: 'vs baseline', active: 'active', dispatches: 'dispatches', sinceInception: 'since inception', currentOpen: 'currently open', started: 'started', perSession: 'per session', allTime: 'all-time', uniqueAuthors: 'unique authors', last30Commits: 'last 30 commits', dayLimit: 'day limit', withoutOpt: 'without optimization', reduction: 'reduction', budgetCompliance: 'budget compliance', audited: 'audited', regressionChecks: 'regression checks', overallGuard: 'overall guard', allSystems: 'all systems operational', currentlyRunning: 'currently running', passTotal: 'pass/total', dispatchAccuracy: 'dispatch accuracy', localStore: 'local store', eventStream: 'event stream', currentUsage: 'current usage', activeCount: 'active count', highActivity: 'high activity', target: 'target', meanRecovery: 'mean time to recovery', last30Days: 'last 30 days', average: 'average', fromAnalytics: 'from analytics' },
      chartTitles: { tokenTrend: 'Token Trend', costBreakdown: 'Cost Breakdown', sessionActivity: 'Session Activity', commitsByAuthor: 'Commits by Author', savingsAnalysis: 'Savings Analysis', commitsTimeline: 'Commits Timeline' },
      references: { 
        title: 'References & Glossary', 
        description: 'This section explains the purpose and meaning of each metric.',
        panelTitle: 'Metric References',
        trafficLight: { title: 'Traffic Light', purpose: 'Visual system status indicator', meaning: 'GREEN = Healthy, YELLOW = Attention, RED = Critical' }, 
        tokens: { title: 'Tokens', purpose: 'LLM API token usage', meaning: 'Consumed vs allocated budget' }, 
        sessions: { title: 'Sessions', purpose: 'Active development tracking', meaning: 'Open, active and total count' }, 
        commits: { title: 'Commits', purpose: 'Repository activity', meaning: 'Code changes per period' }, 
        routing: { title: 'Routing', purpose: 'Auto-delegation accuracy', meaning: '% tasks routed correctly' }, 
        sla: { title: 'SLA', purpose: 'Service agreement compliance', meaning: 'Availability and reliability' }, 
        mttr: { title: 'MTTR', purpose: 'Mean recovery time', meaning: 'Minutes to restore service' },
        sectionRefs: {
          executive: [
            { metric: 'Traffic Light', what: 'Overall system health status', why: 'Quick visual indicator for executives', unit: 'GREEN/YELLOW/RED - Color-coded status' },
            { metric: 'Token Status', what: 'Budget compliance check', why: 'Ensure we stay within budget limits', unit: 'PASS/WARNING - Binary status' },
            { metric: 'Budget Used', what: 'Percentage of tokens consumed', why: 'Track resource utilization', unit: '% - Percentage of 120K daily limit' },
            { metric: 'Est. Cost', what: 'Current cost in USD', why: 'Financial tracking', unit: '$ USD - Based on $10 per 1M tokens' },
            { metric: 'Forecast', what: 'Projected month-end cost', why: 'Budget planning', unit: '$ USD - Linear projection' },
            { metric: 'Savings', what: 'Cost savings achieved', why: 'ROI measurement', unit: '$ USD - Compared to baseline' }
          ],
          operations: [
            { metric: 'Total Sessions', what: 'Cumulative session count', why: 'Usage tracking', unit: 'Count - Integer number' },
            { metric: 'Active Now', what: 'Currently open sessions', why: 'Real-time activity', unit: 'Count - Integer number' },
            { metric: 'Today', what: 'Sessions started today', why: 'Daily activity tracking', unit: 'Count - Integer number' },
            { metric: 'Avg Duration', what: 'Average session length', why: 'Productivity analysis', unit: 'Hours - Time duration' },
            { metric: 'Total Time', what: 'Cumulative time spent', why: 'Resource investment', unit: 'Minutes - Total time' }
          ],
          development: [
            { metric: 'Total Commits', what: 'All-time code commits', why: 'Development activity', unit: 'Count - Integer number' },
            { metric: 'This Month', what: 'Monthly commit count', why: 'Sprint velocity', unit: 'Count - Integer number' },
            { metric: 'This Week', what: 'Weekly commit count', why: 'Weekly progress', unit: 'Count - Integer number' },
            { metric: 'PRs Merged', what: 'Pull requests integrated', why: 'Code integration rate', unit: 'Count - Integer number' },
            { metric: 'Contributors', what: 'Unique developers', why: 'Team size', unit: 'Count - Integer number' }
          ],
          cost: [
            { metric: 'Actual Cost', what: 'Current spending', why: 'Budget monitoring', unit: '$ USD - Based on token usage' },
            { metric: 'Daily Budget', what: 'Maximum allowed tokens', why: 'Spending limit', unit: 'Tokens - 120,000 limit' },
            { metric: 'Rate', what: 'Cost per million tokens', why: 'Pricing reference', unit: '$10 USD - Per 1M tokens' },
            { metric: 'Tokens Saved', what: 'Optimization savings', why: 'Efficiency measure', unit: 'Tokens - Count saved' },
            { metric: 'Savings', what: 'Money saved', why: 'ROI calculation', unit: '$ USD - Dollar amount' }
          ],
          governance: [
            { metric: 'Traffic Light', what: 'Compliance status', why: 'Governance check', unit: 'GREEN/YELLOW/RED' },
            { metric: 'Token Guard', what: 'Budget compliance', why: 'Financial governance', unit: 'PASS/FAIL' },
            { metric: 'Routing Acc', what: 'Task routing precision', why: 'System accuracy', unit: '% - Percentage correct' },
            { metric: 'Benchmark', what: 'Performance tests', why: 'Quality assurance', unit: 'Pass/Total - Ratio' }
          ],
          health: [
            { metric: 'Status', what: 'System health', why: 'Operational status', unit: 'HEALTHY/DEGRADED' },
            { metric: 'Active Sessions', what: 'Running sessions', why: 'Load monitoring', unit: 'Count - Integer' },
            { metric: 'Benchmark', what: 'Test results', why: 'Performance check', unit: 'Pass/Total' },
            { metric: 'Routing', what: 'Accuracy rate', why: 'Reliability metric', unit: '% - Percentage' }
          ],
          sla: [
            { metric: 'Uptime', what: 'System availability', why: 'Reliability commitment', unit: '% - Percentage (target 99.9%)' },
            { metric: 'Incidents', what: 'Service disruptions', why: 'Problem tracking', unit: 'Count - Integer' },
            { metric: 'MTTR', what: 'Mean Time To Recovery', why: 'Recovery speed', unit: 'Minutes - Time duration' },
            { metric: 'Latency', what: 'Response time', why: 'Performance metric', unit: 'Seconds - Time duration' }
          ],
          performance: [
            { metric: 'Sessions', what: 'Activity count', why: 'Usage metric', unit: 'Count - Integer' },
            { metric: 'Peak Activity', what: 'Busiest hour', why: 'Capacity planning', unit: 'Hour:Minute - Time' },
            { metric: 'Sessions/Day', what: 'Daily average', why: 'Trend analysis', unit: 'Count - Decimal' },
            { metric: 'Velocity', what: 'Development speed', why: 'Team productivity', unit: '% - Percentage change' }
          ]
        }
      }
    }
  }
};
