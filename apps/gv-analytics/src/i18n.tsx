import { createContext, useContext, useState, type ReactNode } from 'react';

export type Locale = 'en' | 'es' | 'pt-BR';

export const LOCALE_NAMES: Record<Locale, string> = {
  en: 'English',
  es: 'Español',
  'pt-BR': 'Português (Brasil)',
};

export const LOCALE_FLAGS: Record<Locale, string> = {
  en: '🇬🇧',
  es: '🇪🇸',
  'pt-BR': '🇧🇷',
};

const STRINGS: Record<Locale, Record<string, string>> = {
  en: {
    // Brand / nav
    'brand.analytics': 'Analytics',
    'nav.sections': 'Sections',
    'nav.connection': 'Connection',
    'nav.analysis': 'Analysis',
    'nav.report': 'Report',
    'nav.evidence': 'Evidence',
    'nav.operation': 'Operation',
    'nav.config': 'Configuration',
    'nav.history': 'History',
    'state.ready': 'Atlassian ready',
    'state.partial': 'Partial connection',
    'state.none': 'No connection',
    'theme.toLight': 'Switch to light theme',
    'theme.toDark': 'Switch to dark theme',
    'theme.toggle': 'Toggle theme',

    // Connection panel
    'conn.title': 'Atlassian Connection',
    'conn.loaded': 'Credentials loaded for this local run.',
    'conn.configure': 'Configure the connection once to operate.',
    'conn.site': 'Site',
    'conn.bitbucket': 'Bitbucket',
    'conn.workspaceUndefined': 'Workspace not set',
    'conn.revalidate': 'Revalidate',
    'conn.edit': 'Edit',
    'conn.siteUrl': 'Site URL',
    'conn.email': 'Email',
    'conn.apiToken': 'API token (Jira + Confluence)',
    'conn.bitbucketApiToken': 'Bitbucket API token',
    'conn.bitbucketWorkspace': 'Bitbucket workspace',
    'conn.tokenHint': 'Jira and Confluence share the same Atlassian API token. Bitbucket uses a separate token.',
    'conn.bitbucketTokenHint': 'Bitbucket uses its own API token, different from the Jira/Confluence one.',
    'conn.tokenLoaded': 'Loaded: {masked}',
    'conn.keepExisting': 'Leave blank to keep the current value.',
    'conn.requiredHint': 'Required',
    'conn.test': 'Test',
    'conn.saveAndTest': 'Save and test',
    'conn.oauthOpened': 'Atlassian opened in a new tab. Authorize the app and come back.',
    'conn.saved': 'Connection saved and verified.',
    'conn.validAll': 'Connection valid for all 3 services.',
    'conn.partial': 'Partial connection, check the per-service detail.',
    'conn.oauthRemoved': 'OAuth tokens removed from the vault.',

    // Status panel
    'status.title': 'Status',
    'status.operational': 'Session operational without exposing credentials.',
    'status.pending': 'Pending connection.',
    'status.pendingShort': 'Pending',

    // History
    'history.title': 'History',
    'history.subtitle': 'Last 5 reports persisted in Nexus, ready to resume.',
    'history.empty': 'No reports yet.',
    'history.search': 'Search...',
    'history.columnDate': 'Date',
    'history.columnTime': 'Time',
    'history.columnTitle': 'Title',
    'history.columnMode': 'Mode',
    'history.columnId': 'ID',
    'history.noResults': 'No reports match the current filters.',
    'history.open': 'Open report',
    'history.export': 'Export',
    'history.columnExport': 'Export',
    'history.allModes': 'All modes',

    // Analysis
    'analysis.mode': 'Analysis mode',
    'analysis.url': 'URL',
    'analysis.request': 'Request',
    'analysis.optional': '(optional)',
    'analysis.export': 'Export',
    'analysis.template': 'Template',
    'analysis.urlPlaceholder': 'Paste a Bitbucket repository, PR, Jira or Confluence URL to pull real evidence...',
    'analysis.requestPlaceholder':
      'Describe the functional or technical request, paste a Jira ticket description, or a Jira URL. Combined with the URL above for a full analysis...',
    'analysis.urlHint': 'Atlassian URL — fetches real evidence (Jira issues, Confluence pages, Bitbucket PRs). Leave blank if you only have a text description.',
    'analysis.requestHint': 'Free-text description of the requirement or initiative. Can include a URL too — both fields are combined for the analysis.',
    'analysis.run': 'Analyze',

    // Report
    'report.emptyTitle': 'Ready to interpret an initiative',
    'report.emptyBody':
      'The first analysis will retrieve evidence, detect impact fronts and produce a technical response ready to evolve.',
    'report.label': 'Report',
    'report.complexity': 'Complexity',
    'report.delivery': 'Delivery',
    'report.qa': 'QA',
    'report.confidence': 'Confidence',
    'report.currentState': 'Current state',
    'report.proposedSolution': 'Proposed solution',
    'report.fronts': 'Fronts involved',
    'report.roles': 'Roles',
    'report.qaScenarios': 'QA scenarios',
    'report.nextActions': 'Next actions',
    'report.evidence': 'Evidence',
    'report.proposedState': 'Proposed state',
    'report.noContent': 'No content.',
    'report.copy': 'Copy',
    'report.copied': 'Copied',
    'report.mermaidRender': 'render mermaid:',

    // OAuth
    'oauth.title': 'OAuth 2.0 (3LO)',
    'oauth.connected': 'Connected',
    'oauth.ready': 'Ready to authorize',
    'oauth.notConfigured': 'Not configured',
    'oauth.expires': 'Expires:',
    'oauth.disconnect': 'Disconnect',
    'oauth.callback': 'Local callback:',
    'oauth.scopes': 'Scopes:',
    'oauth.configureHint':
      'Set GVA_OAUTH_CLIENT_ID and GVA_OAUTH_CLIENT_SECRET in the server environment to enable OAuth.',
    'oauth.connect': 'Connect with Atlassian',

    // LLM provenance
    'llm.agent': 'Generated by LLM (sdd-explore)',
    'llm.cache': 'Retrieved from LLM cache',
    'llm.fallback': 'Heuristic fallback (LLM unavailable)',
    'llm.heuristic': 'Local heuristic',
  },
  es: {
    'brand.analytics': 'Analytics',
    'nav.sections': 'Secciones',
    'nav.connection': 'Conexión',
    'nav.analysis': 'Análisis',
    'nav.report': 'Reporte',
    'nav.evidence': 'Evidencia',
    'nav.operation': 'Operación',
    'nav.config': 'Configuración',
    'nav.history': 'Historial',
    'state.ready': 'Atlassian listo',
    'state.partial': 'Conexión parcial',
    'state.none': 'Sin conexión',
    'theme.toLight': 'Cambiar a tema claro',
    'theme.toDark': 'Cambiar a tema oscuro',
    'theme.toggle': 'Cambiar tema',

    'conn.title': 'Conexión Atlassian',
    'conn.loaded': 'Credenciales cargadas para esta ejecución local.',
    'conn.configure': 'Configura la conexión una sola vez para operar.',
    'conn.site': 'Site',
    'conn.bitbucket': 'Bitbucket',
    'conn.workspaceUndefined': 'Workspace no definido',
    'conn.revalidate': 'Revalidar',
    'conn.edit': 'Editar',
    'conn.siteUrl': 'Site URL',
    'conn.email': 'Email',
    'conn.apiToken': 'API token (Jira + Confluence)',
    'conn.bitbucketApiToken': 'API token de Bitbucket',
    'conn.bitbucketWorkspace': 'Bitbucket workspace',
    'conn.tokenHint': 'Jira y Confluence comparten el mismo API token de Atlassian. Bitbucket usa un token separado.',
    'conn.bitbucketTokenHint': 'Bitbucket usa su propio API token, distinto del de Jira/Confluence.',
    'conn.tokenLoaded': 'Cargado: {masked}',
    'conn.keepExisting': 'Dejar vacío para mantener el valor actual.',
    'conn.requiredHint': 'Obligatorio',
    'conn.test': 'Probar',
    'conn.saveAndTest': 'Guardar y probar',
    'conn.oauthOpened': 'Atlassian abierto en nueva pestaña. Autoriza la app y vuelve acá.',
    'conn.saved': 'Conexión guardada y verificada.',
    'conn.validAll': 'Conexión válida para los 3 servicios.',
    'conn.partial': 'Conexión parcial, revisa el detalle por servicio.',
    'conn.oauthRemoved': 'Tokens OAuth eliminados del vault.',

    'status.title': 'Estado',
    'status.operational': 'Sesión operativa sin exponer credenciales.',
    'status.pending': 'Pendiente de conexión.',
    'status.pendingShort': 'Pendiente',

    'history.title': 'Historial',
    'history.subtitle': 'Últimos 5 reportes persistidos en Nexus, listos para retomar.',
    'history.empty': 'Sin reportes todavía.',
    'history.search': 'Buscar...',
    'history.columnDate': 'Fecha',
    'history.columnTime': 'Hora',
    'history.columnTitle': 'Título',
    'history.columnMode': 'Modo',
    'history.columnId': 'ID',
    'history.noResults': 'No hay reportes que coincidan con los filtros actuales.',
    'history.open': 'Abrir reporte',
    'history.export': 'Exportar',
    'history.columnExport': 'Exportar',
    'history.allModes': 'Todos los modos',

    'analysis.mode': 'Modo de análisis',
    'analysis.url': 'URL',
    'analysis.request': 'Pedido',
    'analysis.optional': '(opcional)',
    'analysis.export': 'Exportar',
    'analysis.template': 'Plantilla',
    'analysis.urlPlaceholder': 'Pega una URL de repositorio, PR, Jira o Confluence de Bitbucket para traer evidencia real...',
    'analysis.requestPlaceholder':
      'Describe el pedido funcional o técnico, pega la descripción de un ticket de Jira, o una URL de Jira. Se combina con la URL de arriba para un análisis completo...',
    'analysis.urlHint': 'URL de Atlassian — recupera evidencia real (issues de Jira, páginas de Confluence, PRs de Bitbucket). Podés dejarlo vacío si solo tenés descripción de texto.',
    'analysis.requestHint': 'Descripción libre del requerimiento o iniciativa. También puede incluir una URL — ambos campos se combinan en el análisis.',
    'analysis.run': 'Analizar',

    'report.emptyTitle': 'Listo para interpretar una iniciativa',
    'report.emptyBody':
      'El primer análisis va a recuperar evidencia, detectar frentes de impacto y producir una respuesta técnica lista para evolucionar.',
    'report.label': 'Reporte',
    'report.complexity': 'Complejidad',
    'report.delivery': 'Delivery',
    'report.qa': 'QA',
    'report.confidence': 'Confianza',
    'report.currentState': 'Estado actual',
    'report.proposedSolution': 'Solución propuesta',
    'report.fronts': 'Frentes involucrados',
    'report.roles': 'Roles',
    'report.qaScenarios': 'Escenarios QA',
    'report.nextActions': 'Próximas acciones',
    'report.evidence': 'Evidencia',
    'report.proposedState': 'Estado propuesto',
    'report.noContent': 'Sin contenido.',
    'report.copy': 'Copiar',
    'report.copied': 'Copiado',
    'report.mermaidRender': 'render mermaid:',

    'oauth.title': 'OAuth 2.0 (3LO)',
    'oauth.connected': 'Conectado',
    'oauth.ready': 'Listo para autorizar',
    'oauth.notConfigured': 'No configurado',
    'oauth.expires': 'Expira:',
    'oauth.disconnect': 'Desconectar',
    'oauth.callback': 'Callback local:',
    'oauth.scopes': 'Scopes:',
    'oauth.configureHint':
      'Configurar GVA_OAUTH_CLIENT_ID y GVA_OAUTH_CLIENT_SECRET en el entorno del server para habilitar OAuth.',
    'oauth.connect': 'Conectar con Atlassian',

    'llm.agent': 'Generado por LLM (sdd-explore)',
    'llm.cache': 'Recuperado del cache LLM',
    'llm.fallback': 'Fallback heurístico (LLM no disponible)',
    'llm.heuristic': 'Heurístico local',
  },
  'pt-BR': {
    'brand.analytics': 'Analytics',
    'nav.sections': 'Seções',
    'nav.connection': 'Conexão',
    'nav.analysis': 'Análise',
    'nav.report': 'Relatório',
    'nav.evidence': 'Evidência',
    'nav.operation': 'Operação',
    'nav.config': 'Configuração',
    'nav.history': 'Histórico',
    'state.ready': 'Atlassian pronto',
    'state.partial': 'Conexão parcial',
    'state.none': 'Sem conexão',
    'theme.toLight': 'Mudar para tema claro',
    'theme.toDark': 'Mudar para tema escuro',
    'theme.toggle': 'Alternar tema',

    'conn.title': 'Conexão Atlassian',
    'conn.loaded': 'Credenciais carregadas para esta execução local.',
    'conn.configure': 'Configure a conexão uma vez para operar.',
    'conn.site': 'Site',
    'conn.bitbucket': 'Bitbucket',
    'conn.workspaceUndefined': 'Workspace não definido',
    'conn.revalidate': 'Revalidar',
    'conn.edit': 'Editar',
    'conn.siteUrl': 'Site URL',
    'conn.email': 'Email',
    'conn.apiToken': 'API token (Jira + Confluence)',
    'conn.bitbucketApiToken': 'API token do Bitbucket',
    'conn.bitbucketWorkspace': 'Bitbucket workspace',
    'conn.tokenHint': 'Jira e Confluence compartilham o mesmo API token da Atlassian. O Bitbucket usa um token separado.',
    'conn.bitbucketTokenHint': 'O Bitbucket usa seu próprio API token, diferente do Jira/Confluence.',
    'conn.tokenLoaded': 'Carregado: {masked}',
    'conn.keepExisting': 'Deixe vazio para manter o valor atual.',
    'conn.requiredHint': 'Obrigatório',
    'conn.test': 'Testar',
    'conn.saveAndTest': 'Salvar e testar',
    'conn.oauthOpened': 'Atlassian aberto em nova aba. Autorize o app e volte aqui.',
    'conn.saved': 'Conexão salva e verificada.',
    'conn.validAll': 'Conexão válida para os 3 serviços.',
    'conn.partial': 'Conexão parcial, revise o detalhe por serviço.',
    'conn.oauthRemoved': 'Tokens OAuth removidos do vault.',

    'status.title': 'Status',
    'status.operational': 'Sessão operacional sem expor credenciais.',
    'status.pending': 'Pendente de conexão.',
    'status.pendingShort': 'Pendente',

    'history.title': 'Histórico',
    'history.subtitle': 'Últimos 5 relatórios persistidos no Nexus, prontos para retomar.',
    'history.empty': 'Sem relatórios ainda.',
    'history.search': 'Buscar...',
    'history.columnDate': 'Data',
    'history.columnTime': 'Hora',
    'history.columnTitle': 'Título',
    'history.columnMode': 'Modo',
    'history.columnId': 'ID',
    'history.noResults': 'Nenhum relatório corresponde aos filtros atuais.',
    'history.open': 'Abrir relatório',
    'history.export': 'Exportar',
    'history.columnExport': 'Exportar',
    'history.allModes': 'Todos os modos',

    'analysis.mode': 'Modo de análise',
    'analysis.url': 'URL',
    'analysis.request': 'Pedido',
    'analysis.optional': '(opcional)',
    'analysis.export': 'Exportar',
    'analysis.template': 'Modelo',
    'analysis.urlPlaceholder': 'Cole uma URL de repositório, PR, Jira ou Confluence do Bitbucket para trazer evidência real...',
    'analysis.requestPlaceholder':
      'Descreva o pedido funcional ou técnico, cole a descrição de um ticket do Jira, ou uma URL do Jira. É combinado com a URL acima para uma análise completa...',
    'analysis.urlHint': 'URL da Atlassian — busca evidências reais (issues do Jira, páginas do Confluence, PRs do Bitbucket). Pode deixar vazio se só tiver descrição em texto.',
    'analysis.requestHint': 'Descrição livre do requisito ou iniciativa. Também pode incluir uma URL — ambos os campos são combinados na análise.',
    'analysis.run': 'Analisar',

    'report.emptyTitle': 'Pronto para interpretar uma iniciativa',
    'report.emptyBody':
      'A primeira análise vai recuperar evidências, detectar frentes de impacto e produzir uma resposta técnica pronta para evoluir.',
    'report.label': 'Relatório',
    'report.complexity': 'Complexidade',
    'report.delivery': 'Delivery',
    'report.qa': 'QA',
    'report.confidence': 'Confiança',
    'report.currentState': 'Estado atual',
    'report.proposedSolution': 'Solução proposta',
    'report.fronts': 'Frentes envolvidas',
    'report.roles': 'Papéis',
    'report.qaScenarios': 'Cenários QA',
    'report.nextActions': 'Próximas ações',
    'report.evidence': 'Evidência',
    'report.proposedState': 'Estado proposto',
    'report.noContent': 'Sem conteúdo.',
    'report.copy': 'Copiar',
    'report.copied': 'Copiado',
    'report.mermaidRender': 'render mermaid:',

    'oauth.title': 'OAuth 2.0 (3LO)',
    'oauth.connected': 'Conectado',
    'oauth.ready': 'Pronto para autorizar',
    'oauth.notConfigured': 'Não configurado',
    'oauth.expires': 'Expira:',
    'oauth.disconnect': 'Desconectar',
    'oauth.callback': 'Callback local:',
    'oauth.scopes': 'Scopes:',
    'oauth.configureHint':
      'Defina GVA_OAUTH_CLIENT_ID e GVA_OAUTH_CLIENT_SECRET no ambiente do servidor para habilitar OAuth.',
    'oauth.connect': 'Conectar com Atlassian',

    'llm.agent': 'Gerado por LLM (sdd-explore)',
    'llm.cache': 'Recuperado do cache LLM',
    'llm.fallback': 'Fallback heurístico (LLM indisponível)',
    'llm.heuristic': 'Heurístico local',
  },
};

const LocaleContext = createContext<{ locale: Locale; setLocale: (l: Locale) => void }>({
  locale: 'es',
  setLocale: () => {},
});

export function LocaleProvider({ children }: { children: ReactNode }) {
  const [locale, setLocale] = useState<Locale>(() => {
    if (typeof window === 'undefined') return 'es';
    const stored = window.localStorage.getItem('gv-analytics-locale');
    return stored === 'en' || stored === 'pt-BR' || stored === 'es' ? stored : 'es';
  });
  return <LocaleContext.Provider value={{ locale, setLocale }}>{children}</LocaleContext.Provider>;
}

export function useLocale() {
  return useContext(LocaleContext);
}

export function useT(): { tt: (key: string) => string } {
  const { locale } = useLocale();
  const tt = (key: string): string => STRINGS[locale][key] ?? STRINGS.en[key] ?? key;
  return { tt };
}

export function LocaleSwitcher() {
  const { locale, setLocale } = useLocale();
  return (
    <select
      className="locale-switcher"
      value={locale}
      onChange={(event) => setLocale(event.target.value as Locale)}
      aria-label="Language / Idioma / Idioma"
      title="Language"
    >
      {(Object.keys(LOCALE_NAMES) as Locale[]).map((l) => (
        <option key={l} value={l}>
          {LOCALE_FLAGS[l]} {LOCALE_NAMES[l]}
        </option>
      ))}
    </select>
  );
}
