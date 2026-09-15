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
import { type ReactNode } from 'react';
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
export declare function useShellI18n(): ShellI18nCtx;
export declare function Shell({ appName, navItems, currentPage, logoHref, translations, actions, children, footer, }: ShellProps): import("react").JSX.Element;
export default Shell;
//# sourceMappingURL=Shell.d.ts.map