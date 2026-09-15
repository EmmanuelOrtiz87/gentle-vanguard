import { type HTMLAttributes, type ReactNode } from 'react';
import './Card.css';
export type CardVariant = 'glass' | 'solid' | 'outline';
export type CardPadding = 'none' | 'sm' | 'md' | 'lg';
export interface CardProps extends HTMLAttributes<HTMLDivElement> {
    variant?: CardVariant;
    padding?: CardPadding;
    interactive?: boolean;
    children: ReactNode;
}
/**
 * Card — Gentle-Vanguard v2 surface component.
 * Glass variant is the brand default (backdrop-filter + violet border).
 *
 * @example
 *   <Card variant="glass" padding="md">
 *     <h3>Title</h3>
 *     <p>Body</p>
 *   </Card>
 *   <Card interactive onClick={...}>Clickable card</Card>
 */
export declare const Card: import("react").ForwardRefExoticComponent<CardProps & import("react").RefAttributes<HTMLDivElement>>;
//# sourceMappingURL=Card.d.ts.map