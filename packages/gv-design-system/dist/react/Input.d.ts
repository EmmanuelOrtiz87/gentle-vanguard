import { type InputHTMLAttributes, type ReactNode } from 'react';
import './Input.css';
export type InputSize = 'sm' | 'md' | 'lg';
export type InputState = 'default' | 'error' | 'success';
export interface InputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'size'> {
    label?: string;
    hint?: string;
    error?: string;
    success?: string;
    size?: InputSize;
    iconLeft?: ReactNode;
    iconRight?: ReactNode;
    fullWidth?: boolean;
}
/**
 * Input — Gentle-Vanguard v2 form control.
 * Built-in label, hint, error/success messaging, icon slots.
 * WCAG 2.2: proper aria-describedby, aria-invalid, label association.
 *
 * @example
 *   <Input label="Email" type="email" required />
 *   <Input label="Password" type="password" error="Too short" />
 *   <Input label="Search" iconLeft={<SearchIcon />} />
 */
export declare const Input: import("react").ForwardRefExoticComponent<InputProps & import("react").RefAttributes<HTMLInputElement>>;
//# sourceMappingURL=Input.d.ts.map