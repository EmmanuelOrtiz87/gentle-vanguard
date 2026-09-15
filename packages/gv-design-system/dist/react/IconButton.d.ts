import { type ButtonHTMLAttributes, type ReactNode } from 'react';
import './IconButton.css';
export type IconButtonVariant = 'default' | 'primary' | 'ghost';
export type IconButtonSize = 'sm' | 'md' | 'lg';
export interface IconButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
    variant?: IconButtonVariant;
    size?: IconButtonSize;
    icon: ReactNode;
    'aria-label': string;
}
/**
 * IconButton — Gentle-Vanguard v2 square icon-only button.
 * Used in toolbars, topbars, cards. Requires aria-label (icon-only = needs explicit label).
 *
 * @example
 *   <IconButton icon={<SearchIcon />} aria-label="Search" />
 *   <IconButton icon={<CloseIcon />} variant="primary" aria-label="Close" />
 */
export declare const IconButton: import("react").ForwardRefExoticComponent<IconButtonProps & import("react").RefAttributes<HTMLButtonElement>>;
//# sourceMappingURL=IconButton.d.ts.map