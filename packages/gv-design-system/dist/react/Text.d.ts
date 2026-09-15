import { type ElementType, type ReactNode } from 'react';
import './Text.css';
export type TextVariant = 'display-1' | 'display-2' | 'heading-1' | 'heading-2' | 'heading-3' | 'body' | 'body-sm' | 'caption' | 'eyebrow' | 'code' | 'metric';
export type TextColor = 'primary' | 'muted' | 'accent' | 'success' | 'warning' | 'error' | 'gradient';
export interface TextProps {
    variant?: TextVariant;
    color?: TextColor;
    weight?: 400 | 500 | 600 | 700 | 800 | 900;
    as?: ElementType;
    truncate?: boolean;
    children: ReactNode;
    className?: string;
    id?: string;
    title?: string;
    style?: React.CSSProperties;
}
/**
 * Text — Gentle-Vanguard v2 typography component.
 * Use this for ALL text to ensure type scale + color tokens are applied.
 *
 * @example
 *   <Text variant="heading-1">Dashboard</Text>
 *   <Text variant="eyebrow" color="accent">Section label</Text>
 *   <Text variant="metric" color="gradient">99.9%</Text>
 *   <Text variant="code">npm install gv-design-system</Text>
 */
export declare function Text({ variant, color, weight, as: Tag, truncate, className, children, ...rest }: TextProps): import("react").ReactElement<any, string | import("react").JSXElementConstructor<any>>;
//# sourceMappingURL=Text.d.ts.map