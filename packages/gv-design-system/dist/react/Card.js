import { jsx as _jsx } from "react/jsx-runtime";
import { forwardRef } from 'react';
import './Card.css';
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
export const Card = forwardRef(function Card({ variant = 'glass', padding = 'md', interactive = false, className = '', children, ...rest }, ref) {
    const classes = [
        'gv-card',
        `gv-card--${variant}`,
        `gv-card--p-${padding}`,
        interactive ? 'gv-card--interactive' : '',
        className,
    ]
        .filter(Boolean)
        .join(' ');
    return (_jsx("div", { ref: ref, className: classes, ...rest, children: children }));
});
//# sourceMappingURL=Card.js.map