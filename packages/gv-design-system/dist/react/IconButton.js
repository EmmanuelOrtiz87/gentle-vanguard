import { jsx as _jsx } from "react/jsx-runtime";
import { forwardRef } from 'react';
import './IconButton.css';
/**
 * IconButton — Gentle-Vanguard v2 square icon-only button.
 * Used in toolbars, topbars, cards. Requires aria-label (icon-only = needs explicit label).
 *
 * @example
 *   <IconButton icon={<SearchIcon />} aria-label="Search" />
 *   <IconButton icon={<CloseIcon />} variant="primary" aria-label="Close" />
 */
export const IconButton = forwardRef(function IconButton({ variant = 'default', size = 'md', icon, disabled, className = '', ...rest }, ref) {
    const classes = [
        'gv-icon-btn',
        `gv-icon-btn--${variant}`,
        `gv-icon-btn--${size}`,
        className,
    ]
        .filter(Boolean)
        .join(' ');
    return (_jsx("button", { ref: ref, className: classes, disabled: disabled, ...rest, children: _jsx("span", { className: "gv-icon-btn__icon", "aria-hidden": "true", children: icon }) }));
});
//# sourceMappingURL=IconButton.js.map