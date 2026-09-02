import { forwardRef, HTMLAttributes } from 'react';
import styles from './Card.module.css';

export interface CardProps extends HTMLAttributes<HTMLDivElement> {
  /** Variante visual de la tarjeta */
  variant?: 'glass' | 'solid' | 'outline' | 'elevated';
  /** Padding interno */
  padding?: 'none' | 'sm' | 'md' | 'lg' | 'xl';
  /** Si la tarjeta es interactiva (clickable) */
  interactive?: boolean;
  /** Si está seleccionada */
  selected?: boolean;
  /** Hijo que actúa como header */
  header?: React.ReactNode;
  /** Hijo que actúa como footer */
  footer?: React.ReactNode;
}

export const Card = forwardRef<HTMLDivElement, CardProps>(
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
    ref
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

    return (
      <div ref={ref} className={classNames} {...props}>
        {header && <div className={styles.header}>{header}</div>}
        <div className={styles.content}>{children}</div>
        {footer && <div className={styles.footer}>{footer}</div>}
      </div>
    );
  }
);

Card.displayName = 'Card';

export default Card;