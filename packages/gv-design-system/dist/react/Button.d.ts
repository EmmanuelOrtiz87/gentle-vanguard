import { type ButtonHTMLAttributes, type ReactNode } from 'react';
import './Button.css';
export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';
export type ButtonSize = 'sm' | 'md' | 'lg';
export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
    variant?: ButtonVariant;
    size?: ButtonSize;
    iconLeft?: ReactNode;
    iconRight?: ReactNode;
    loading?: boolean;
    fullWidth?: boolean;
}
/**
 * Button — Gentle-Vanguard primary action component.
 *
 * @example
 *   <Button variant="primary" onClick={...}>Save</Button>
 *   <Button variant="ghost" iconLeft={<Icon />}>Cancel</Button>
 *   <Button variant="primary" loading>Saving...</Button>
 */
export declare const Button: import("react").ForwardRefExoticComponent<ButtonProps & import("react").RefAttributes<HTMLButtonElement>>;
//# sourceMappingURL=Button.d.ts.map