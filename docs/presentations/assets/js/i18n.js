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
    // Update active state on language buttons
    document.querySelectorAll('[data-lang]').forEach(function (btn) {
      const isActive = btn.getAttribute('data-lang') === lang;
      btn.classList.toggle('active', isActive);
      if (btn.closest('.dropdown-menu')) {
        btn.classList.toggle('active', isActive);
      }
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
        // Close Bootstrap dropdown
        var dropdown = btn.closest('.dropdown-menu');
        if (dropdown) {
          var toggle = dropdown.previousElementSibling;
          if (toggle && toggle.getAttribute('data-bs-toggle') === 'dropdown') {
            // Try Bootstrap dismiss
            var bsDropdown =
              bootstrap && bootstrap.Dropdown && bootstrap.Dropdown.getInstance(toggle);
            if (bsDropdown) bsDropdown.hide();
          }
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
  window.__i18n = { DICT: DICT, translate: translate, getCurrentLang: getCurrentLang };
})();
