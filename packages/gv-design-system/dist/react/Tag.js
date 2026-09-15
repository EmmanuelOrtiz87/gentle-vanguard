import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import './Tag.css';
/**
 * Tag — Gentle-Vanguard v2 pill-shaped label.
 * Use for status indicators, categories, metadata.
 *
 * @example
 *   <Tag variant="success">Active</Tag>
 *   <Tag variant="warning" icon={<Icon />}>Pending</Tag>
 *   <Tag variant="primary" size="sm">Beta</Tag>
 */
export function Tag({ variant = 'neutral', size = 'md', icon, className = '', children, ...rest }) {
    const classes = [
        'gv-tag',
        `gv-tag--${variant}`,
        `gv-tag--${size}`,
        className,
    ]
        .filter(Boolean)
        .join(' ');
    return (_jsxs("span", { className: classes, ...rest, children: [icon && _jsx("span", { className: "gv-tag__icon", children: icon }), _jsx("span", { className: "gv-tag__label", children: children })] }));
}
//# sourceMappingURL=Tag.js.map