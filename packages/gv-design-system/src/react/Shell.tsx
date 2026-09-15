/**
 * Gentle-Vanguard Design System v2 — React Shell component.
 *
 * Homologated application shell for React apps (archify, content-cms,
 * academy-crm, ...). Renders the standard topbar (brand + nav + language
 * dropdown + theme toggle + hamburger) and footer, and manages the shared
 * GV keys `gv-cc-lang` (es/en/pt) and `gv-cc-theme` (light/dark).
 *
 * Usage:
 *   <Shell appName="Archify Studio" navItems={[...]} currentPage="studio">
 *     ...page content...
 *   </Shell>
 *
 * Hooks:
 *   const { locale, setLocale, t } = useShellI18n();
 *   const { theme, toggleTheme } = useShellTheme();
 */
import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';

export type ShellLocale = 'es' | 'en' | 'pt';
export type ShellTheme = 'light' | 'dark';

export interface ShellNavItem {
  id: string;
  label: string;
  href?: string;
  onClick?: () => void;
}

export interface ShellProps {
  appName: string;
  navItems: ShellNavItem[];
  currentPage?: string;
  logoHref?: string;
  /** Optional per-page content translations: { key: { es, en, pt } } */
  translations?: Record<string, Record<ShellLocale, string>>;
  /** Custom action buttons rendered before the lang/theme controls */
  actions?: ReactNode;
  children?: ReactNode;
  footer?: ReactNode;
}

export interface ShellI18nCtx {
  locale: ShellLocale;
  setLocale: (l: ShellLocale) => void;
  t: (key: string, fallback?: string) => string;
}

const I18nContext = createContext<ShellI18nCtx>({
  locale: 'es',
  setLocale: () => {},
  t: (k, f) => f ?? k,
});

export function useShellI18n(): ShellI18nCtx {
  return useContext(I18nContext);
}

const SHELL_STRINGS: Record<ShellLocale, Record<string, string>> = {
  es: {
    'aria.nav': 'Secciones de la aplicación',
    'aria.menu': 'Alternar menú de navegación',
    'aria.lang': 'Idioma',
    'aria.theme': 'Cambiar tema',
    'theme.light': 'Activar tema claro',
    'theme.dark': 'Activar tema oscuro',
    'footer.local': 'local-first',
  },
  en: {
    'aria.nav': 'App sections',
    'aria.menu': 'Toggle navigation menu',
    'aria.lang': 'Language',
    'aria.theme': 'Toggle theme',
    'theme.light': 'Enable light theme',
    'theme.dark': 'Enable dark theme',
    'footer.local': 'local-first',
  },
  pt: {
    'aria.nav': 'Seções do aplicativo',
    'aria.menu': 'Alternar menu de navegação',
    'aria.lang': 'Idioma',
    'aria.theme': 'Alternar tema',
    'theme.light': 'Ativar tema claro',
    'theme.dark': 'Ativar tema escuro',
    'footer.local': 'local-first',
  },
};

const LOCALE_FLAGS: Record<ShellLocale, string> = { es: '🇪🇸', en: '🇬🇧', pt: '🇧🇷' };
const LOCALE_NAMES: Record<ShellLocale, string> = { es: 'Español', en: 'English', pt: 'Português' };

function readLocale(): ShellLocale {
  const stored = localStorage.getItem('gv-cc-lang');
  const normalized = stored === 'pt-BR' ? 'pt' : stored;
  return normalized === 'en' || normalized === 'pt' || normalized === 'es' ? normalized : 'es';
}

function readTheme(): ShellTheme {
  return localStorage.getItem('gv-cc-theme') === 'light' ? 'light' : 'dark';
}

export function Shell({
  appName,
  navItems,
  currentPage,
  logoHref = '/',
  translations,
  actions,
  children,
  footer,
}: ShellProps) {
  const [locale, setLocaleState] = useState<ShellLocale>(readLocale);
  const [theme, setThemeState] = useState<ShellTheme>(readTheme);
  const [menuOpen, setMenuOpen] = useState(false);
  const [langOpen, setLangOpen] = useState(false);

  // Apply theme to <html> and persist shared key
  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    try {
      localStorage.setItem('gv-cc-theme', theme);
    } catch {
      /* localStorage may be disabled */
    }
  }, [theme]);

  // Persist locale to shared key
  const setLocale = (next: ShellLocale) => {
    setLocaleState(next);
    try {
      localStorage.setItem('gv-cc-lang', next);
    } catch {
      /* localStorage may be disabled */
    }
    document.documentElement.lang = next;
    document.dispatchEvent(new CustomEvent('gv:locale-changed', { detail: { locale: next } }));
  };

  const t = (key: string, fallback?: string): string => {
    const dict = translations?.[key];
    if (dict && dict[locale] !== undefined) return dict[locale];
    const shell = SHELL_STRINGS[locale];
    if (shell && shell[key] !== undefined) return shell[key];
    return fallback ?? key;
  };

  const i18nValue = useMemo<ShellI18nCtx>(() => ({ locale, setLocale, t }), [locale, translations]);

  const toggleTheme = () => setThemeState((prev) => (prev === 'light' ? 'dark' : 'light'));

  return (
    <I18nContext.Provider value={i18nValue}>
      <div className="gv-app-shell">
        {/* Atmosphere */}
        <div className="gv-grid-bg" aria-hidden="true" />
        <div className="gv-glow-a" aria-hidden="true" />
        <div className="gv-glow-b" aria-hidden="true" />

        {/* Topbar */}
        <header className="gv-topbar" role="banner">
          <div className="gv-topbar-inner">
            <a className="gv-brand" href={logoHref} aria-label={`Gentle-Vanguard — ${appName}`}>
              <img
                className="gv-brand-logo"
                src="/logo.svg"
                alt="Gentle-Vanguard"
                width={32}
                height={32}
              />
              <span className="gv-brand-wordmark">
                Gentle<span>Vanguard</span>
              </span>
              <span className="gv-shell-context">
                <small>{appName}</small>
              </span>
            </a>

            <nav className="gv-view-tabs gv-collapsible" aria-label={t('aria.nav')}>
              {navItems.map((item) =>
                item.href ? (
                  <a
                    key={item.id}
                    href={item.href}
                    aria-current={item.id === currentPage ? 'page' : undefined}
                  >
                    {item.label}
                  </a>
                ) : (
                  <button
                    key={item.id}
                    type="button"
                    className={item.id === currentPage ? 'active' : ''}
                    aria-current={item.id === currentPage ? 'page' : undefined}
                    onClick={() => {
                      item.onClick?.();
                      setMenuOpen(false);
                    }}
                  >
                    {item.label}
                  </button>
                ),
              )}
            </nav>

            {/* Custom actions (app-specific buttons) */}
            {actions && <div className="gv-shell-actions">{actions}</div>}

            {/* Controls: language + theme */}
            <div className="gv-shell-controls">
              <div className="gv-lang-dropdown">
                <button
                  type="button"
                  className="gv-icon-btn"
                  aria-label={t('aria.lang')}
                  aria-haspopup="true"
                  aria-expanded={langOpen}
                  onClick={() => setLangOpen((v) => !v)}
                >
                  <span>文A</span>
                </button>
                {langOpen && (
                  <div className="gv-lang-dropdown-menu">
                    {(Object.keys(LOCALE_NAMES) as ShellLocale[]).map((l) => (
                      <button
                        key={l}
                        type="button"
                        onClick={() => {
                          setLocale(l);
                          setLangOpen(false);
                        }}
                        aria-current={l === locale ? 'true' : undefined}
                      >
                        <span>{LOCALE_FLAGS[l]}</span>
                        <span>{LOCALE_NAMES[l]}</span>
                        <span className="gv-lang-check">{l === locale ? '✓' : ''}</span>
                      </button>
                    ))}
                  </div>
                )}
              </div>
              <button
                type="button"
                className="gv-icon-btn gv-theme-toggle"
                aria-label={theme === 'light' ? t('theme.dark') : t('theme.light')}
                onClick={toggleTheme}
              >
                {theme === 'light' ? '🌙' : '☀'}
              </button>
            </div>

            <button
              type="button"
              className="gv-shell-menu"
              aria-label={t('aria.menu')}
              aria-expanded={menuOpen}
              onClick={() => setMenuOpen((v) => !v)}
            >
              <span />
            </button>
          </div>
        </header>

        {/* Main content */}
        <main>{children}</main>

        {/* Footer */}
        <footer className="gv-footer">
          <div className="gv-footer-inner">
            <span className="gv-brand-wordmark">
              Gentle<span>Vanguard</span>
            </span>
            <span>{appName}</span>
            <span>·</span>
            <span>{t('footer.local')}</span>
          </div>
          {footer}
        </footer>
      </div>
    </I18nContext.Provider>
  );
}

export default Shell;