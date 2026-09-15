import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
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
import { createContext, useContext, useEffect, useMemo, useState } from 'react';
const I18nContext = createContext({
    locale: 'es',
    setLocale: () => { },
    t: (k, f) => f ?? k,
});
export function useShellI18n() {
    return useContext(I18nContext);
}
const SHELL_STRINGS = {
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
const LOCALE_FLAGS = { es: '🇪🇸', en: '🇬🇧', pt: '🇧🇷' };
const LOCALE_NAMES = { es: 'Español', en: 'English', pt: 'Português' };
function readLocale() {
    const stored = localStorage.getItem('gv-cc-lang');
    const normalized = stored === 'pt-BR' ? 'pt' : stored;
    return normalized === 'en' || normalized === 'pt' || normalized === 'es' ? normalized : 'es';
}
function readTheme() {
    return localStorage.getItem('gv-cc-theme') === 'light' ? 'light' : 'dark';
}
export function Shell({ appName, navItems, currentPage, logoHref = '/', translations, actions, children, footer, }) {
    const [locale, setLocaleState] = useState(readLocale);
    const [theme, setThemeState] = useState(readTheme);
    const [menuOpen, setMenuOpen] = useState(false);
    const [langOpen, setLangOpen] = useState(false);
    // Apply theme to <html> and persist shared key
    useEffect(() => {
        document.documentElement.dataset.theme = theme;
        try {
            localStorage.setItem('gv-cc-theme', theme);
        }
        catch {
            /* localStorage may be disabled */
        }
    }, [theme]);
    // Persist locale to shared key
    const setLocale = (next) => {
        setLocaleState(next);
        try {
            localStorage.setItem('gv-cc-lang', next);
        }
        catch {
            /* localStorage may be disabled */
        }
        document.documentElement.lang = next;
        document.dispatchEvent(new CustomEvent('gv:locale-changed', { detail: { locale: next } }));
    };
    const t = (key, fallback) => {
        const dict = translations?.[key];
        if (dict && dict[locale] !== undefined)
            return dict[locale];
        const shell = SHELL_STRINGS[locale];
        if (shell && shell[key] !== undefined)
            return shell[key];
        return fallback ?? key;
    };
    const i18nValue = useMemo(() => ({ locale, setLocale, t }), [locale, translations]);
    const toggleTheme = () => setThemeState((prev) => (prev === 'light' ? 'dark' : 'light'));
    return (_jsx(I18nContext.Provider, { value: i18nValue, children: _jsxs("div", { className: "gv-app-shell", children: [_jsx("div", { className: "gv-grid-bg", "aria-hidden": "true" }), _jsx("div", { className: "gv-glow-a", "aria-hidden": "true" }), _jsx("div", { className: "gv-glow-b", "aria-hidden": "true" }), _jsx("header", { className: "gv-topbar", role: "banner", children: _jsxs("div", { className: "gv-topbar-inner", children: [_jsxs("a", { className: "gv-brand", href: logoHref, "aria-label": `Gentle-Vanguard — ${appName}`, children: [_jsx("img", { className: "gv-brand-logo", src: "/logo.svg", alt: "Gentle-Vanguard", width: 32, height: 32 }), _jsxs("span", { className: "gv-brand-wordmark", children: ["Gentle", _jsx("span", { children: "Vanguard" })] }), _jsx("span", { className: "gv-shell-context", children: _jsx("small", { children: appName }) })] }), _jsx("nav", { className: "gv-view-tabs gv-collapsible", "aria-label": t('aria.nav'), children: navItems.map((item) => item.href ? (_jsx("a", { href: item.href, "aria-current": item.id === currentPage ? 'page' : undefined, children: item.label }, item.id)) : (_jsx("button", { type: "button", className: item.id === currentPage ? 'active' : '', "aria-current": item.id === currentPage ? 'page' : undefined, onClick: () => {
                                        item.onClick?.();
                                        setMenuOpen(false);
                                    }, children: item.label }, item.id))) }), actions && _jsx("div", { className: "gv-shell-actions", children: actions }), _jsxs("div", { className: "gv-shell-controls", children: [_jsxs("div", { className: "gv-lang-dropdown", children: [_jsx("button", { type: "button", className: "gv-icon-btn", "aria-label": t('aria.lang'), "aria-haspopup": "true", "aria-expanded": langOpen, onClick: () => setLangOpen((v) => !v), children: _jsx("span", { children: "\u6587A" }) }), langOpen && (_jsx("div", { className: "gv-lang-dropdown-menu", children: Object.keys(LOCALE_NAMES).map((l) => (_jsxs("button", { type: "button", onClick: () => {
                                                        setLocale(l);
                                                        setLangOpen(false);
                                                    }, "aria-current": l === locale ? 'true' : undefined, children: [_jsx("span", { children: LOCALE_FLAGS[l] }), _jsx("span", { children: LOCALE_NAMES[l] }), _jsx("span", { className: "gv-lang-check", children: l === locale ? '✓' : '' })] }, l))) }))] }), _jsx("button", { type: "button", className: "gv-icon-btn gv-theme-toggle", "aria-label": theme === 'light' ? t('theme.dark') : t('theme.light'), onClick: toggleTheme, children: theme === 'light' ? '🌙' : '☀' })] }), _jsx("button", { type: "button", className: "gv-shell-menu", "aria-label": t('aria.menu'), "aria-expanded": menuOpen, onClick: () => setMenuOpen((v) => !v), children: _jsx("span", {}) })] }) }), _jsx("main", { children: children }), _jsxs("footer", { className: "gv-footer", children: [_jsxs("div", { className: "gv-footer-inner", children: [_jsxs("span", { className: "gv-brand-wordmark", children: ["Gentle", _jsx("span", { children: "Vanguard" })] }), _jsx("span", { children: appName }), _jsx("span", { children: "\u00B7" }), _jsx("span", { children: t('footer.local') })] }), footer] })] }) }));
}
export default Shell;
//# sourceMappingURL=Shell.js.map