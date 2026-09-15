import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { forwardRef, useId } from 'react';
import './Input.css';
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
export const Input = forwardRef(function Input({ label, hint, error, success, size = 'md', iconLeft, iconRight, fullWidth = false, disabled, className = '', id: providedId, ...rest }, ref) {
    const generatedId = useId();
    const id = providedId ?? generatedId;
    const hintId = hint ? `${id}-hint` : undefined;
    const messageId = error || success ? `${id}-msg` : undefined;
    const describedBy = [hintId, messageId].filter(Boolean).join(' ') || undefined;
    const state = error ? 'error' : success ? 'success' : 'default';
    const wrapperClasses = [
        'gv-input-wrapper',
        `gv-input-wrapper--${size}`,
        fullWidth ? 'gv-input-wrapper--full' : '',
    ]
        .filter(Boolean)
        .join(' ');
    const inputClasses = [
        'gv-input',
        `gv-input--${size}`,
        `gv-input--${state}`,
        iconLeft ? 'gv-input--has-icon-left' : '',
        iconRight ? 'gv-input--has-icon-right' : '',
        className,
    ]
        .filter(Boolean)
        .join(' ');
    return (_jsxs("div", { className: wrapperClasses, children: [label && (_jsx("label", { htmlFor: id, className: "gv-input__label", children: label })), _jsxs("div", { className: "gv-input__field", children: [iconLeft && _jsx("span", { className: "gv-input__icon gv-input__icon--left", children: iconLeft }), _jsx("input", { ref: ref, id: id, className: inputClasses, disabled: disabled, "aria-invalid": error ? 'true' : undefined, "aria-describedby": describedBy, ...rest }), iconRight && _jsx("span", { className: "gv-input__icon gv-input__icon--right", children: iconRight })] }), hint && !error && !success && (_jsx("span", { id: hintId, className: "gv-input__hint", children: hint })), error && (_jsx("span", { id: messageId, className: "gv-input__error", role: "alert", children: error })), success && !error && (_jsx("span", { id: messageId, className: "gv-input__success", children: success }))] }));
});
//# sourceMappingURL=Input.js.map