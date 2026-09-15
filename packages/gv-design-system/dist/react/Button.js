import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { forwardRef } from 'react';
import './Button.css';
/**
 * Button — Gentle-Vanguard primary action component.
 *
 * @example
 *   <Button variant="primary" onClick={...}>Save</Button>
 *   <Button variant="ghost" iconLeft={<Icon />}>Cancel</Button>
 *   <Button variant="primary" loading>Saving...</Button>
 */
export const Button = forwardRef(function Button({ variant = 'primary', size = 'md', iconLeft, iconRight, loading = false, fullWidth = false, disabled, className = '', children, ...rest }, ref) {
    const classes = [
        'gv-btn',
        `gv-btn--${variant}`,
        `gv-btn--${size}`,
        fullWidth ? 'gv-btn--full' : '',
        loading ? 'gv-btn--loading' : '',
        className,
    ]
        .filter(Boolean)
        .join(' ');
    return (_jsxs("button", { ref: ref, className: classes, disabled: disabled || loading, "aria-busy": loading || undefined, ...rest, children: [iconLeft && _jsx("span", { className: "gv-btn__icon gv-btn__icon--left", children: iconLeft }), _jsx("span", { className: "gv-btn__label", children: children }), iconRight && _jsx("span", { className: "gv-btn__icon gv-btn__icon--right", children: iconRight }), loading && _jsx("span", { className: "gv-btn__spinner", "aria-hidden": "true" })] }));
});
//# sourceMappingURL=Button.js.map