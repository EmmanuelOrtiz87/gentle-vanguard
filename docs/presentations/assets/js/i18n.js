/**
 * i18n.js — Multilingual support for Gentle-Vanguard presentations
 *
 * Translates data-i18n elements on the fly. Supports en/es/pt-BR.
 * Language preference is persisted in localStorage.
 *
 * Usage:
 *   <span data-i18n="nav_home">Home</span>
 *
 * Dependencies: Bootstrap 5.3+ (for dropdown)
 */
(function () {
  'use strict';

  const DICT = {
    en: {
      nav_home: 'Home',
      nav_arch: 'Arch',
      nav_autonomy: 'Autonomy',
      nav_dashboard: 'Dashboard',
      nav_quickstart: 'Quickstart',
      nav_memory: 'Memory',
      nav_security: 'Security',
      nav_agents: 'Agents',
      nav_cloud: 'Cloud',
      nav_patterns: 'Patterns',
      nav_health: 'Health',
      nav_diagrams: 'Diagrams',
      /* Títulos de sección — index */
      sec_architecture: 'System Architecture',
      sec_components: 'Stack Components',
      sec_autonomous: 'Autonomous Systems',
      sec_data_layer: 'Data Layer — 11 Repos',
      sec_executive: 'Executive Systems',
      sec_feature_matrix: 'Feature Matrix',
      sec_skills_rules: 'Skills & Rules Explorer',
      sec_stack_metrics: 'Stack Metrics',
      sec_the_book: 'El Libro — The Book',
      sec_diagrams: 'Diagrams & Visualizations',
      sec_tools: 'Tools Ecosystem',
      /* Títulos de sección — architecture */
      sec_arch_layers: 'System Architecture',
      sec_daos: 'Data Access Objects',
      sec_pipeline: 'Session Pipeline',
      sec_performance: 'Performance Optimizations',
      /* Títulos de sección — agents-pipeline */
      sec_agent_eco: 'Agent Ecosystem',
      sec_routing: 'Routing Rules',
      sec_lifecycle: 'Session Lifecycle',
      sec_delegation: 'Delegation Model',
      sec_skills_system: 'Skills System',
      /* Títulos de sección — quickstart */
      sec_prereq: 'Prerequisites',
      sec_setup: 'One-Command Setup',
      sec_daily: 'Daily Commands',
      sec_dash_cmds: 'Dashboard Commands',
      sec_db_cmds: 'Database Commands',
      sec_workflow: 'Development Workflow',
      sec_arch_overview: 'Architecture Overview',
      sec_troubleshoot: 'Troubleshooting',
      sec_references: 'Reference Links',
      /* Títulos de sección — memory-knowledge */
      sec_mem_stack: 'The Memory Stack',
      sec_engram: 'Engram — Persistent Memory',
      sec_codegraph: 'CodeGraph — Symbol Intelligence',
      sec_graphify: 'Graphify — Knowledge Graph',
      sec_nexus: 'Nexus DB — Operational Database',
      sec_mem_daos: 'Data Access Objects',
      sec_ml_emb: 'ML Embeddings',
      sec_kb_manager: 'Knowledge Base Manager',
      sec_data_flow: 'Data Flow Diagram',
      /* Títulos de sección — security-governance */
      sec_sec_orch: 'Security Orchestrator',
      sec_audit: 'Audit Pipeline',
      sec_normatives: 'Normatives System',
      sec_guardrails: 'Guardrails & Policies',
      sec_governance: 'Governance Framework',
      sec_compliance: 'Compliance Checks',
      sec_hardening: 'Security Hardening',
      sec_standards: 'Standards Summary',
      /* Hero */
      hero_subtitle: 'Autonomous AI Orchestration Platform — 100% Autonomous',
      /* Títulos — health */
      sec_health_dash: 'Health Dashboard',
      sec_perf_slos: 'Performance SLOs',
      /* Títulos — operations-cloud */
      sec_ci_cd: 'CI/CD Pipeline',
      sec_security_wf: 'Security Workflow',
      sec_cloud_conn: 'Cloud Connectors',
      sec_cb_states: 'Circuit Breaker States',
      sec_tracing: 'Distributed Tracing',
      sec_state_persist: 'State Persistence',
      sec_event_saga: 'Event Sourcing + Saga',
      sec_health_api: 'Health API',
      sec_testing_infra: 'Testing Infrastructure',
      sec_ops_cmds: 'Operations Commands',
      sec_pipe_integ: 'Pipeline Integration',
      /* Info tips (modal de la "i") */
      info_kicker: 'More information',
      info_title: 'About this feature',
      info_hint: 'Press ESC or click outside to close',
      tip_pipeline: 'Session autostart: 31 parallel Phase-1 steps + 70 lazy background steps launched in batches of 5. Includes tool detection, token budget, Karpathy guidelines, codegraph sync, security orchestration and DB init.',
      tip_engram: 'Persistent memory with automatic sync, SHA256 integrity checks and compaction. Currently holding 2,078 observations across 369 sessions. Survives across sessions and compactions.',
      tip_codegraph: 'SQLite knowledge graph for symbol intelligence. 10,663 nodes and 21,746 edges across 677 files with sub-millisecond symbol queries.',
      tip_dashboard: 'React + TypeScript + Vite observability SPA. WebSocket real-time updates every 5s with HTTP polling fallback, 7 dashboard sections, i18n in 3 languages and 8 alert rules.',
      tip_circuit: '3-state circuit breaker (CLOSED / OPEN / HALF_OPEN). 5 failures open the circuit, 2 successes recover it. Prevents cascading failures across the stack.',
      tip_autoapply: 'Executive engine that follows trigger → evaluate (≥80% confidence) → apply → verify → rollback. Maximum 5 auto-applies per day with rollback if degradation exceeds 15%.',
      tip_depgraph: 'Dynamically discovers component relationships from the pipeline config, replacing the hardcoded dependency map. Self-maintaining architecture.',
      tip_escalation: '3-tier escalation: warning (3 failures) → critical (5) → emergency (10). Every escalation is recorded with full audit trail in the findings ledger.',
      tip_abtest: 'Statistical A/B testing framework: createExperiment, assignVariant, evaluateExperiment with automatic rollback on statistical degradation.',
      tip_scoring: 'Per-session quality scoring tracking delegations, corrections and proactive hits. Automatic comparison, regression detection above 15% and anomaly alerts.',
      tip_watchtower: 'Central health orchestrator: 112 checks across 18 components with Promise.allSettled parallel execution and auto-heal modes (health, rebuild, autoheal, report, continuous).',
      tip_nexus: 'Operational SQLite database (WAL mode, FK ON) with 11 repositories, 7 migrations and 21 tables. Auto-init, auto-prune, auto-backup and watchtower monitoring.',
      tip_layers: 'The stack is organized in 6 layers: Tools (10 IDEs) → Agents (21 specialized) → Pipeline (101 enabled steps) → Memory & Knowledge → Data (11 repos) → Executive systems.',
      section_overview: 'Overview',
      section_architecture: 'Architecture',
      section_metrics: 'Metrics',
      section_quickstart: 'Quick Start',
      section_security: 'Security & Governance',
      section_operations: 'Operations',
      section_patterns: 'Patterns & Conventions',
      section_memory: 'Memory & Knowledge',
      section_agents: 'Agents & Pipeline',
      section_autonomy: 'Autonomy Levels',
      section_dashboard: 'Dashboard',
      theme_dark: 'Dark',
      theme_light: 'Light',
      lang_en: 'English',
      lang_es: 'Español',
      lang_pt: 'Português',
      footer_all_rights: 'All rights reserved.',
      footer_built_with: 'Built with',
      see_docs: 'See Documentation',
      view_on_github: 'View on GitHub',
      coming_soon: 'Coming soon',
      loading: 'Loading...',
      error: 'Error',
      search: 'Search...',
      no_results: 'No results found.',
      back_to_top: 'Back to top',
      copy: 'Copy',
      copied: 'Copied!',
      close: 'Close',
      save: 'Save',
      cancel: 'Cancel',
      delete: 'Delete',
      edit: 'Edit',
      create: 'Create',
      update: 'Update',
      refresh: 'Refresh',
      download: 'Download',
      upload: 'Upload',
      filter: 'Filter',
      sort: 'Sort',
      status_ok: 'Operational',
      status_warn: 'Warning',
      status_error: 'Error',
      status_unknown: 'Unknown',
    },
    es: {
      nav_home: 'Inicio',
      nav_arch: 'Arq',
      nav_autonomy: 'Autonomía',
      nav_dashboard: 'Dashboard',
      nav_quickstart: 'Inicio Rápido',
      nav_memory: 'Memoria',
      nav_security: 'Seguridad',
      nav_agents: 'Agentes',
      nav_cloud: 'Nube',
      nav_patterns: 'Patrones',
      nav_health: 'Salud',
      nav_diagrams: 'Diagramas',
      /* Títulos de sección — index */
      sec_architecture: 'Arquitectura del Sistema',
      sec_components: 'Componentes del Stack',
      sec_autonomous: 'Sistemas Autónomos',
      sec_data_layer: 'Capa de Datos — 11 Repos',
      sec_executive: 'Sistemas Ejecutivos',
      sec_feature_matrix: 'Matriz de Funcionalidades',
      sec_skills_rules: 'Explorador de Skills y Reglas',
      sec_stack_metrics: 'Métricas del Stack',
      sec_the_book: 'El Libro',
      sec_diagrams: 'Diagramas y Visualizaciones',
      sec_tools: 'Ecosistema de Herramientas',
      /* Títulos de sección — architecture */
      sec_arch_layers: 'Arquitectura del Sistema',
      sec_daos: 'Objetos de Acceso a Datos',
      sec_pipeline: 'Pipeline de Sesión',
      sec_performance: 'Optimizaciones de Rendimiento',
      /* Títulos de sección — agents-pipeline */
      sec_agent_eco: 'Ecosistema de Agentes',
      sec_routing: 'Reglas de Ruteo',
      sec_lifecycle: 'Ciclo de Vida de Sesión',
      sec_delegation: 'Modelo de Delegación',
      sec_skills_system: 'Sistema de Skills',
      /* Títulos de sección — quickstart */
      sec_prereq: 'Requisitos Previos',
      sec_setup: 'Instalación en un Comando',
      sec_daily: 'Comandos Diarios',
      sec_dash_cmds: 'Comandos del Dashboard',
      sec_db_cmds: 'Comandos de Base de Datos',
      sec_workflow: 'Flujo de Desarrollo',
      sec_arch_overview: 'Resumen de Arquitectura',
      sec_troubleshoot: 'Solución de Problemas',
      sec_references: 'Enlaces de Referencia',
      /* Títulos de sección — memory-knowledge */
      sec_mem_stack: 'El Stack de Memoria',
      sec_engram: 'Engram — Memoria Persistente',
      sec_codegraph: 'CodeGraph — Inteligencia de Símbolos',
      sec_graphify: 'Graphify — Grafo de Conocimiento',
      sec_nexus: 'Nexus DB — Base de Datos Operacional',
      sec_mem_daos: 'Objetos de Acceso a Datos',
      sec_ml_emb: 'Embeddings ML',
      sec_kb_manager: 'Gestor de Base de Conocimiento',
      sec_data_flow: 'Diagrama de Flujo de Datos',
      /* Títulos de sección — security-governance */
      sec_sec_orch: 'Orquestador de Seguridad',
      sec_audit: 'Pipeline de Auditoría',
      sec_normatives: 'Sistema de Normativas',
      sec_guardrails: 'Guardarraíles y Políticas',
      sec_governance: 'Marco de Gobernanza',
      sec_compliance: 'Verificaciones de Cumplimiento',
      sec_hardening: 'Endurecimiento de Seguridad',
      sec_standards: 'Resumen de Estándares',
      /* Hero */
      hero_subtitle: 'Plataforma Autónoma de Orquestración AI — 100% Autónoma',
      /* Títulos — health */
      sec_health_dash: 'Dashboard de Salud',
      sec_perf_slos: 'SLOs de Rendimiento',
      /* Títulos — operations-cloud */
      sec_ci_cd: 'Pipeline CI/CD',
      sec_security_wf: 'Flujo de Seguridad',
      sec_cloud_conn: 'Conectores Cloud',
      sec_cb_states: 'Estados del Circuit Breaker',
      sec_tracing: 'Trazabilidad Distribuida',
      sec_state_persist: 'Persistencia de Estado',
      sec_event_saga: 'Event Sourcing + Saga',
      sec_health_api: 'API de Salud',
      sec_testing_infra: 'Infraestructura de Testing',
      sec_ops_cmds: 'Comandos de Operaciones',
      sec_pipe_integ: 'Integración de Pipeline',
      /* Info tips (modal de la "i") */
      info_kicker: 'Más información',
      info_title: 'Acerca de esta función',
      info_hint: 'Pulsa ESC o haz clic fuera para cerrar',
      tip_pipeline: 'Autostart de sesión: 31 pasos Phase-1 en paralelo + 70 pasos lazy en background lanzados en lotes de 5. Incluye detección de herramientas, presupuesto de tokens, guías Karpathy, sync de codegraph, orquestación de seguridad e init de BD.',
      tip_engram: 'Memoria persistente con sincronización automática, checks de integridad SHA256 y compactación. Actualmente con 2,078 observaciones en 369 sesiones. Sobrevive entre sesiones y compactaciones.',
      tip_codegraph: 'Grafo de conocimiento SQLite para inteligencia de símbolos. 10,663 nodos y 21,746 aristas en 677 archivos con consultas de símbolos en menos de un milisegundo.',
      tip_dashboard: 'SPA de observabilidad React + TypeScript + Vite. WebSocket con actualizaciones en tiempo real cada 5s con fallback de polling HTTP, 7 secciones del dashboard, i18n en 3 idiomas y 8 reglas de alerta.',
      tip_circuit: 'Circuit breaker de 3 estados (CLOSED / OPEN / HALF_OPEN). 5 fallos abren el circuito, 2 éxitos lo recuperan. Previene fallos en cascada en todo el stack.',
      tip_autoapply: 'Motor ejecutivo que sigue trigger → evaluar (confianza ≥80%) → aplicar → verificar → rollback. Máximo 5 auto-aplicaciones por día con rollback si la degradación supera el 15%.',
      tip_depgraph: 'Descubre dinámicamente las relaciones entre componentes desde la config del pipeline, reemplazando el mapa de dependencias hardcodeado. Arquitectura auto-mantenible.',
      tip_escalation: 'Escalación de 3 niveles: advertencia (3 fallos) → crítico (5) → emergencia (10). Cada escalación queda registrada con trazabilidad completa en el ledger de hallazgos.',
      tip_abtest: 'Framework estadístico de A/B testing: createExperiment, assignVariant, evaluateExperiment con rollback automático ante degradación estadística.',
      tip_scoring: 'Scoring de calidad por sesión que rastrea delegaciones, correcciones y aciertos proactivos. Comparación automática, detección de regresión mayor al 15% y alertas de anomalías.',
      tip_watchtower: 'Orquestador central de salud: 112 checks en 18 componentes con ejecución paralela Promise.allSettled y modos de auto-healing (health, rebuild, autoheal, report, continuous).',
      tip_nexus: 'Base de datos operacional SQLite (modo WAL, FK ON) con 11 repositorios, 7 migraciones y 21 tablas. Auto-init, auto-prune, auto-backup y monitoreo por watchtower.',
      tip_layers: 'El stack se organiza en 6 capas: Tools (10 IDEs) → Agents (21 especializados) → Pipeline (101 pasos habilitados) → Memoria y Conocimiento → Datos (11 repos) → Sistemas ejecutivos.',
      section_overview: 'Resumen',
      section_architecture: 'Arquitectura',
      section_metrics: 'Métricas',
      section_quickstart: 'Inicio Rápido',
      section_security: 'Seguridad y Gobernanza',
      section_operations: 'Operaciones',
      section_patterns: 'Patrones y Convenciones',
      section_memory: 'Memoria y Conocimiento',
      section_agents: 'Agentes y Pipeline',
      section_autonomy: 'Niveles de Autonomía',
      section_dashboard: 'Dashboard',
      theme_dark: 'Oscuro',
      theme_light: 'Claro',
      lang_en: 'English',
      lang_es: 'Español',
      lang_pt: 'Português',
      footer_all_rights: 'Todos los derechos reservados.',
      footer_built_with: 'Construido con',
      see_docs: 'Ver Documentación',
      view_on_github: 'Ver en GitHub',
      coming_soon: 'Próximamente',
      loading: 'Cargando...',
      error: 'Error',
      search: 'Buscar...',
      no_results: 'Sin resultados.',
      back_to_top: 'Volver arriba',
      copy: 'Copiar',
      copied: '¡Copiado!',
      close: 'Cerrar',
      save: 'Guardar',
      cancel: 'Cancelar',
      delete: 'Eliminar',
      edit: 'Editar',
      create: 'Crear',
      update: 'Actualizar',
      refresh: 'Actualizar',
      download: 'Descargar',
      upload: 'Subir',
      filter: 'Filtrar',
      sort: 'Ordenar',
      status_ok: 'Operativo',
      status_warn: 'Advertencia',
      status_error: 'Error',
      status_unknown: 'Desconocido',
    },
    'pt-BR': {
      nav_home: 'Início',
      nav_arch: 'Arq',
      nav_autonomy: 'Autonomia',
      nav_dashboard: 'Dashboard',
      nav_quickstart: 'Início Rápido',
      nav_memory: 'Memória',
      nav_security: 'Segurança',
      nav_agents: 'Agentes',
      nav_cloud: 'Nuvem',
      nav_patterns: 'Padrões',
      nav_health: 'Saúde',
      nav_diagrams: 'Diagramas',
      /* Títulos de sección — index */
      sec_architecture: 'Arquitetura do Sistema',
      sec_components: 'Componentes da Stack',
      sec_autonomous: 'Sistemas Autônomos',
      sec_data_layer: 'Camada de Dados — 11 Repos',
      sec_executive: 'Sistemas Executivos',
      sec_feature_matrix: 'Matriz de Funcionalidades',
      sec_skills_rules: 'Explorador de Skills e Regras',
      sec_stack_metrics: 'Métricas da Stack',
      sec_the_book: 'O Livro',
      sec_diagrams: 'Diagramas e Visualizações',
      sec_tools: 'Ecossistema de Ferramentas',
      /* Títulos de sección — architecture */
      sec_arch_layers: 'Arquitetura do Sistema',
      sec_daos: 'Objetos de Acesso a Dados',
      sec_pipeline: 'Pipeline de Sessão',
      sec_performance: 'Otimizações de Desempenho',
      /* Títulos de sección — agents-pipeline */
      sec_agent_eco: 'Ecossistema de Agentes',
      sec_routing: 'Regras de Roteamento',
      sec_lifecycle: 'Ciclo de Vida da Sessão',
      sec_delegation: 'Modelo de Delegação',
      sec_skills_system: 'Sistema de Skills',
      /* Títulos de sección — quickstart */
      sec_prereq: 'Pré-requisitos',
      sec_setup: 'Instalação em um Comando',
      sec_daily: 'Comandos Diários',
      sec_dash_cmds: 'Comandos do Dashboard',
      sec_db_cmds: 'Comandos de Banco de Dados',
      sec_workflow: 'Fluxo de Desenvolvimento',
      sec_arch_overview: 'Visão Geral da Arquitetura',
      sec_troubleshoot: 'Solução de Problemas',
      sec_references: 'Links de Referência',
      /* Títulos de sección — memory-knowledge */
      sec_mem_stack: 'A Stack de Memória',
      sec_engram: 'Engram — Memória Persistente',
      sec_codegraph: 'CodeGraph — Inteligência de Símbolos',
      sec_graphify: 'Graphify — Grafo de Conhecimento',
      sec_nexus: 'Nexus DB — Banco de Dados Operacional',
      sec_mem_daos: 'Objetos de Acesso a Dados',
      sec_ml_emb: 'Embeddings ML',
      sec_kb_manager: 'Gerenciador de Base de Conhecimento',
      sec_data_flow: 'Diagrama de Fluxo de Dados',
      /* Títulos de sección — security-governance */
      sec_sec_orch: 'Orquestador de Segurança',
      sec_audit: 'Pipeline de Auditoria',
      sec_normatives: 'Sistema de Normativas',
      sec_guardrails: 'Guardrails e Políticas',
      sec_governance: 'Framework de Governança',
      sec_compliance: 'Verificações de Conformidade',
      sec_hardening: 'Endurecimento de Segurança',
      sec_standards: 'Resumo de Padrões',
      /* Hero */
      hero_subtitle: 'Plataforma Autônoma de Orquestração de IA — 100% Autônoma',
      /* Títulos — health */
      sec_health_dash: 'Painel de Saúde',
      sec_perf_slos: 'SLOs de Desempenho',
      /* Títulos — operations-cloud */
      sec_ci_cd: 'Pipeline CI/CD',
      sec_security_wf: 'Fluxo de Segurança',
      sec_cloud_conn: 'Conectores Cloud',
      sec_cb_states: 'Estados do Circuit Breaker',
      sec_tracing: 'Rastreamento Distribuído',
      sec_state_persist: 'Persistência de Estado',
      sec_event_saga: 'Event Sourcing + Saga',
      sec_health_api: 'API de Saúde',
      sec_testing_infra: 'Infraestrutura de Testes',
      sec_ops_cmds: 'Comandos de Operações',
      sec_pipe_integ: 'Integração de Pipeline',
      /* Info tips (modal da "i") */
      info_kicker: 'Mais informações',
      info_title: 'Sobre este recurso',
      info_hint: 'Pressione ESC ou clique fora para fechar',
      tip_pipeline: 'Autostart de sessão: 31 passos Phase-1 em paralelo + 70 passos lazy em background lançados em lotes de 5. Inclui detecção de ferramentas, orçamento de tokens, guias Karpathy, sync de codegraph, orquestração de segurança e init de BD.',
      tip_engram: 'Memória persistente com sincronização automática, checks de integridade SHA256 e compactação. Atualmente com 2.078 observações em 369 sessões. Sobrevive entre sessões e compactações.',
      tip_codegraph: 'Grafo de conhecimento SQLite para inteligência de símbolos. 10.663 nós e 21.746 arestas em 677 arquivos com consultas de símbolos em menos de um milissegundo.',
      tip_dashboard: 'SPA de observabilidade React + TypeScript + Vite. WebSocket com atualizações em tempo real a cada 5s com fallback de polling HTTP, 7 seções do dashboard, i18n em 3 idiomas e 8 regras de alerta.',
      tip_circuit: 'Circuit breaker de 3 estados (CLOSED / OPEN / HALF_OPEN). 5 falhas abrem o circuito, 2 sucessos o recuperam. Previne falhas em cascata em toda a stack.',
      tip_autoapply: 'Motor executivo que segue trigger → avaliar (confiança ≥80%) → aplicar → verificar → rollback. Máximo 5 auto-aplicações por dia com rollback se a degradação ultrapassar 15%.',
      tip_depgraph: 'Descobre dinamicamente as relações entre componentes a partir da config do pipeline, substituindo o mapa de dependências hardcoded. Arquitetura auto-mantida.',
      tip_escalation: 'Escalação de 3 níveis: aviso (3 falhas) → crítico (5) → emergência (10). Cada escalação fica registrada com rastreabilidade completa no ledger de descobertas.',
      tip_abtest: 'Framework estatístico de A/B testing: createExperiment, assignVariant, evaluateExperiment com rollback automático diante de degradação estatística.',
      tip_scoring: 'Scoring de qualidade por sessão que rastreia delegações, correções e acertos proativos. Comparação automática, detecção de regressão acima de 15% e alertas de anomalias.',
      tip_watchtower: 'Orquestrador central de saúde: 112 checks em 18 componentes com execução paralela Promise.allSettled e modos de auto-healing (health, rebuild, autoheal, report, continuous).',
      tip_nexus: 'Banco de dados operacional SQLite (modo WAL, FK ON) com 11 repositórios, 7 migrações e 21 tabelas. Auto-init, auto-prune, auto-backup e monitoramento por watchtower.',
      tip_layers: 'A stack se organiza em 6 camadas: Tools (10 IDEs) → Agents (21 especializados) → Pipeline (101 passos habilitados) → Memória e Conhecimento → Dados (11 repos) → Sistemas executivos.',
      section_overview: 'Visão Geral',
      section_architecture: 'Arquitetura',
      section_metrics: 'Métricas',
      section_quickstart: 'Início Rápido',
      section_security: 'Segurança e Governança',
      section_operations: 'Operações',
      section_patterns: 'Padrões e Convenções',
      section_memory: 'Memória e Conhecimento',
      section_agents: 'Agentes e Pipeline',
      section_autonomy: 'Níveis de Autonomia',
      section_dashboard: 'Dashboard',
      theme_dark: 'Escuro',
      theme_light: 'Claro',
      lang_en: 'English',
      lang_es: 'Español',
      lang_pt: 'Português',
      footer_all_rights: 'Todos os direitos reservados.',
      footer_built_with: 'Construído com',
      see_docs: 'Ver Documentação',
      view_on_github: 'Ver no GitHub',
      coming_soon: 'Em breve',
      loading: 'Carregando...',
      error: 'Erro',
      search: 'Pesquisar...',
      no_results: 'Nenhum resultado.',
      back_to_top: 'Voltar ao topo',
      copy: 'Copiar',
      copied: 'Copiado!',
      close: 'Fechar',
      save: 'Salvar',
      cancel: 'Cancelar',
      delete: 'Excluir',
      edit: 'Editar',
      create: 'Criar',
      update: 'Atualizar',
      refresh: 'Atualizar',
      download: 'Baixar',
      upload: 'Enviar',
      filter: 'Filtrar',
      sort: 'Ordenar',
      status_ok: 'Operacional',
      status_warn: 'Aviso',
      status_error: 'Erro',
      status_unknown: 'Desconhecido',
    },
  };

  const STORAGE_KEY = 'gv-lang';

  function getCurrentLang() {
    try {
      return localStorage.getItem(STORAGE_KEY) || 'en';
    } catch (e) {
      return 'en';
    }
  }

  const FLAGS = { en: '🇬🇧', es: '🇪🇸', 'pt-BR': '🇧🇷' };
  const LANG_SHORT = { en: 'EN', es: 'ES', 'pt-BR': 'PT' };

  function translate(lang) {
    const dict = DICT[lang] || DICT.en;
    // Mezclar diccionario de contenido externo (i18n-content.js) si existe
    const contentDict = window.__GV_CONTENT && window.__GV_CONTENT[lang]
      ? window.__GV_CONTENT[lang]
      : {};
    const merged = Object.assign({}, DICT.en, contentDict, dict);
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      const key = el.getAttribute('data-i18n');
      if (merged[key] !== undefined) {
        el.textContent = merged[key];
      }
    });
    // Traducir atributos title de elementos con data-i18n-title
    document.querySelectorAll('[data-i18n-title]').forEach(function (el) {
      const key = el.getAttribute('data-i18n-title');
      if (merged[key] !== undefined) {
        el.setAttribute('title', merged[key]);
      }
    });
    document.documentElement.setAttribute('lang', lang);
    try {
      localStorage.setItem(STORAGE_KEY, lang);
    } catch (e) {
      /* localStorage no disponible (file:// o modo restringido) */
    }
    // Update active state on language buttons (segmented control)
    document.querySelectorAll('[data-lang]').forEach(function (btn) {
      const isActive = btn.getAttribute('data-lang') === lang;
      btn.classList.toggle('active', isActive);
      btn.setAttribute('aria-pressed', isActive ? 'true' : 'false');
      const code = btn.querySelector('.lang-code');
      if (code) code.textContent = LANG_SHORT[btn.getAttribute('data-lang')];
    });
    // Dispatch event for other scripts
    document.dispatchEvent(new CustomEvent('langchange', { detail: { lang: lang } }));
  }

  function init() {
    var currentLang = getCurrentLang();
    translate(currentLang);

    // Delegate click events on language buttons
    document.addEventListener('click', function (e) {
      var btn = e.target.closest('[data-lang]');
      if (btn) {
        e.preventDefault();
        var lang = btn.getAttribute('data-lang');
        if (DICT[lang]) {
          translate(lang);
        }
      }
    });
  }

  // Run on DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  // Expose for debugging
  window.__i18n = {
    DICT: DICT,
    getDict: function (lang) {
      const current = lang || getCurrentLang();
      const contentDict = window.__GV_CONTENT && window.__GV_CONTENT[current]
        ? window.__GV_CONTENT[current]
        : {};
      return Object.assign({}, DICT.en, contentDict, DICT[current] || {});
    },
    translate: translate,
    getCurrentLang: getCurrentLang,
  };
})();
