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
    return localStorage.getItem(STORAGE_KEY) || 'en';
  }

  const FLAGS = { en: '🇬🇧', es: '🇪🇸', 'pt-BR': '🇧🇷' };
  const LANG_SHORT = { en: 'EN', es: 'ES', 'pt-BR': 'PT' };

  function translate(lang) {
    const dict = DICT[lang] || DICT.en;
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      const key = el.getAttribute('data-i18n');
      if (dict[key] !== undefined) {
        el.textContent = dict[key];
      }
    });
    document.documentElement.setAttribute('lang', lang);
    localStorage.setItem(STORAGE_KEY, lang);
    // Update active state on language buttons (Bootstrap dropdown + custom menu)
    document.querySelectorAll('[data-lang]').forEach(function (btn) {
      const isActive = btn.getAttribute('data-lang') === lang;
      btn.classList.toggle('active', isActive);
      const check = btn.querySelector('.lang-check');
      if (check) check.textContent = isActive ? '✓' : '';
    });
    // Update visible language button (flag + short name)
    const langBtn = document.querySelector('.lang-btn');
    if (langBtn) {
      const flag = langBtn.querySelector('.lang-flag');
      const name = langBtn.querySelector('.lang-name');
      const chevron = langBtn.querySelector('.lang-chevron');
      if (flag) flag.textContent = FLAGS[lang] || '🌐';
      if (name) name.textContent = LANG_SHORT[lang] || lang;
      if (!chevron) {
        const c = document.createElement('span');
        c.className = 'lang-chevron';
        c.textContent = '▼';
        langBtn.appendChild(c);
      }
    }
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
        closeLangMenu();
        // Close Bootstrap dropdown
        var dropdown = btn.closest('.dropdown-menu');
        if (dropdown) {
          var toggle = dropdown.previousElementSibling;
          if (toggle && toggle.getAttribute('data-bs-toggle') === 'dropdown') {
            var bsDropdown =
              bootstrap && bootstrap.Dropdown && bootstrap.Dropdown.getInstance(toggle);
            if (bsDropdown) bsDropdown.hide();
          }
        }
        return;
      }
      // Toggle custom language menu
      var toggleBtn = e.target.closest('.lang-btn');
      if (toggleBtn) {
        e.preventDefault();
        e.stopPropagation();
        var menu = document.getElementById(toggleBtn.getAttribute('aria-controls'));
        if (menu) {
          var isOpen = menu.classList.contains('open');
          closeLangMenu();
          if (!isOpen) {
            // Posicionar el menú cerca del botón (fixed para no ser recortado por overflow del navbar)
            var r = toggleBtn.getBoundingClientRect();
            var menuW = menu.offsetWidth || 190;
            var menuH = menu.offsetHeight || 140;
            var left = Math.min(r.left, window.innerWidth - menuW - 12);
            var top = r.bottom + 8;
            if (top + menuH > window.innerHeight) top = Math.max(8, r.top - menuH - 8);
            menu.style.left = Math.max(8, left) + 'px';
            menu.style.top = top + 'px';
            menu.classList.add('open');
            toggleBtn.setAttribute('aria-expanded', 'true');
          }
        }
        return;
      }
      closeLangMenu();
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') closeLangMenu();
    });
  }

  function closeLangMenu() {
    document.querySelectorAll('.lang-menu.open').forEach(function (m) {
      m.classList.remove('open');
    });
    document.querySelectorAll('.lang-btn[aria-expanded="true"]').forEach(function (b) {
      b.setAttribute('aria-expanded', 'false');
    });
  }

  // Run on DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  // Expose for debugging
  window.__i18n = { DICT: DICT, translate: translate, getCurrentLang: getCurrentLang };
})();
