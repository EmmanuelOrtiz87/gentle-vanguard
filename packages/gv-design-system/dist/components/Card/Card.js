import { jsx as _jsx, jsxs as _jsxs } from 'react/jsx-runtime';
import { forwardRef } from 'react';
import styles from './Card.module.css';
export const Card = forwardRef(
  (
    {
      variant = 'glass',
      padding = 'md',
      interactive = false,
      selected = false,
      header,
      footer,
      children,
      className = '',
      ...props
    },
    ref,
  ) => {
    const classNames = [
      styles.card,
      styles[variant],
      padding && styles[`p-${padding}`],
      interactive && styles.interactive,
      selected && styles.selected,
      className,
    ]
      .filter(Boolean)
      .join(' ');
    return _jsxs('div', {
      ref: ref,
      className: classNames,
      ...props,
      children: [
        header && _jsx('div', { className: styles.header, children: header }),
        _jsx('div', { className: styles.content, children: children }),
        footer && _jsx('div', { className: styles.footer, children: footer }),
      ],
    });
  },
);
Card.displayName = 'Card';
export default Card;
//# sourceMappingURL=Card.js.map
