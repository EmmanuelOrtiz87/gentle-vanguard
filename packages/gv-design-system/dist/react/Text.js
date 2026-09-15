import { createElement } from 'react';
import './Text.css';
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
export function Text({ variant = 'body', color = 'primary', weight, as: Tag = 'p', truncate = false, className = '', children, ...rest }) {
    const classes = [
        'gv-text',
        `gv-text--${variant}`,
        `gv-text--${color}`,
        truncate ? 'gv-text--truncate' : '',
        className,
    ]
        .filter(Boolean)
        .join(' ');
    const styleFromWeight = weight
        ? { ...rest.style, fontWeight: weight }
        : rest.style;
    return createElement(Tag, {
        className: classes,
        ...rest,
        style: styleFromWeight,
    }, children);
}
//# sourceMappingURL=Text.js.map