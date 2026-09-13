import { jsx as _jsx, jsxs as _jsxs } from 'react/jsx-runtime';
import { forwardRef } from 'react';
import styles from './Button.module.css';
export const Button = forwardRef(
  (
    {
      variant = 'primary',
      size = 'md',
      loading = false,
      iconLeft,
      iconRight,
      fullWidth = false,
      disabled,
      children,
      className = '',
      ...props
    },
    ref,
  ) => {
    const isDisabled = disabled || loading;
    const classNames = [
      styles.btn,
      styles[variant],
      styles[size],
      fullWidth ? styles.fullWidth : '',
      loading ? styles.loading : '',
      className,
    ]
      .filter(Boolean)
      .join(' ');
    return _jsxs('button', {
      ref: ref,
      className: classNames,
      disabled: isDisabled,
      'aria-busy': loading,
      'aria-disabled': isDisabled,
      ...props,
      children: [
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
        !loading &&
          iconLeft &&
          _jsx('span', { className: styles.iconLeft, 'aria-hidden': 'true', children: iconLeft }),
        _jsx('span', { className: styles.label, children: children }),
        !loading &&
          iconRight &&
          _jsx('span', { className: styles.iconRight, 'aria-hidden': 'true', children: iconRight }),
      ],
    });
  },
);
Button.displayName = 'Button';
export default Button;
//# sourceMappingURL=Button.js.map
