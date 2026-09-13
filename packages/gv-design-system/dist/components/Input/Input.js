import { jsx as _jsx, jsxs as _jsxs } from 'react/jsx-runtime';
import { forwardRef } from 'react';
import styles from './Input.module.css';
export const Input = forwardRef(
  (
    {
      label,
      hint,
      error,
      success,
      iconLeft,
      iconRight,
      size = 'md',
      loading = false,
      className = '',
      id,
      ...props
    },
    ref,
  ) => {
    const inputId = id || `gv-input-${Math.random().toString(36).slice(2, 9)}`;
    const hintId = hint ? `${inputId}-hint` : undefined;
    const errorId = error ? `${inputId}-error` : undefined;
    const successId = success ? `${inputId}-success` : undefined;
    const describedBy = [hintId, errorId, successId].filter(Boolean).join(' ') || undefined;
    const hasIconLeftProp = iconLeft !== undefined;
    return _jsxs('div', {
      className: `${styles.wrapper} ${className}`,
      children: [
        label && _jsx('label', { htmlFor: inputId, className: styles.label, children: label }),
        _jsxs('div', {
          className: `${styles.field} ${iconLeft ? styles.hasIconLeft : ''} ${iconRight ? styles.hasIconRight : ''} ${loading ? styles.loading : ''}`,
          children: [
            iconLeft &&
              _jsx('span', {
                className: styles.iconLeft,
                'aria-hidden': 'true',
                children: iconLeft,
              }),
            _jsx('input', {
              ref: ref,
              id: inputId,
              className: styles.input,
              'aria-describedby': describedBy,
              'aria-invalid': error ? 'true' : 'false',
              'aria-busy': loading,
              disabled: loading,
              ...props,
            }),
            iconRight &&
              _jsx('span', {
                className: styles.iconRight,
                'aria-hidden': 'true',
                children: iconRight,
              }),
            loading &&
              _jsx('span', {
                className: styles.spinner,
                'aria-hidden': 'true',
                children: _jsxs('svg', {
                  viewBox: '0 0 24 24',
                  fill: 'none',
                  stroke: 'currentColor',
                  strokeWidth: '2',
                  children: [
                    _jsx('circle', { cx: '12', cy: '12', r: '10', strokeOpacity: '0.25' }),
                    _jsx('path', {
                      d: 'M12 2a10 10 0 0 1 10 10',
                      strokeLinecap: 'round',
                      strokeWidth: '3',
                      className: styles.spinnerPath,
                    }),
                  ],
                }),
              }),
          ],
        }),
        error &&
          _jsx('p', { id: errorId, className: styles.error, role: 'alert', children: error }),
        success && _jsx('p', { id: successId, className: styles.success, children: success }),
        hint && !error && _jsx('p', { id: hintId, className: styles.hint, children: hint }),
      ],
    });
  },
);
Input.displayName = 'Input';
export const Textarea = forwardRef(
  ({ label, hint, error, success, className = '', id, ...props }, ref) => {
    const textareaId = id || `gv-textarea-${Math.random().toString(36).slice(2, 9)}`;
    const hintId = hint ? `${id}-hint` : undefined;
    const errorId = error ? `${id}-error` : undefined;
    const successId = success ? `${id}-success` : undefined;
    const describedBy = [hintId, errorId, successId].filter(Boolean).join(' ') || undefined;
    return _jsxs('div', {
      className: className,
      children: [
        label && _jsx('label', { htmlFor: id, className: 'gv-input__label', children: label }),
        _jsx('div', {
          className: 'gv-input__field',
          children: _jsx('textarea', {
            ref: ref,
            id: id,
            className: 'gv-input',
            'aria-describedby':
              hintId || errorId || successId
                ? [hintId, errorId, successId].filter(Boolean).join(' ')
                : undefined,
            'aria-invalid': error ? 'true' : 'false',
            ...props,
          }),
        }),
        error && _jsx('p', { className: 'gv-input__error', role: 'alert', children: error }),
        success && _jsx('p', { className: 'gv-input__success', children: success }),
        hint && !error && _jsx('p', { className: 'gv-input__hint', children: hint }),
      ],
    });
  },
);
Textarea.displayName = 'Textarea';
export const Select = forwardRef(
  ({ label, hint, error, success, className = '', id, children, ...props }, ref) => {
    const selectId = id || `gv-select-${Math.random().toString(36).slice(2, 9)}`;
    const describedBy = [hint, error, success].filter(Boolean).join(' ') || undefined;
    return _jsxs('div', {
      className: 'gv-input-wrapper',
      children: [
        label && _jsx('label', { htmlFor: id, className: 'gv-input__label', children: label }),
        _jsx('div', {
          className: 'gv-input__field',
          children: _jsx('select', {
            ref: ref,
            id: id,
            className: 'gv-input',
            'aria-describedby':
              hint || error || success
                ? [hint, error, success].filter(Boolean).join(' ')
                : undefined,
            'aria-invalid': error ? 'true' : 'false',
            ...props,
            children: children,
          }),
        }),
        error && _jsx('p', { className: 'gv-input__error', role: 'alert', children: error }),
        hint && !error && _jsx('p', { className: 'gv-input__hint', children: hint }),
      ],
    });
  },
);
Select.displayName = 'Select';
export default { Input, Textarea, Select };
//# sourceMappingURL=Input.js.map
