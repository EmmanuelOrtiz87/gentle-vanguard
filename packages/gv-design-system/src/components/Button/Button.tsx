import { forwardRef, ButtonHTMLAttributes } from 'react';
import styles from './Button.module.css';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  /** Variant visual del botón */
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger' | 'outline' | 'success';
  /** Tamaño del botón */
  size?: 'sm' | 'md' | 'lg';
  /** Si está en estado de carga */
  loading?: boolean;
  /** Icono a la izquierda del label */
  iconLeft?: React.ReactNode;
  /** Icono a la derecha del label */
  iconRight?: React.ReactNode;
  /** Ancho completo */
  fullWidth?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
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
    ref
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

    return (
      <button
        ref={ref}
        className={classNames}
        disabled={isDisabled}
        aria-busy={loading}
        aria-disabled={isDisabled}
        {...props}
      >
        {loading && (
          <span className={styles.spinner} aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="12" cy="12" r="10" strokeOpacity="0.25" />
              <path
                d="M12 2a10 10 0 0 1 10 10"
                strokeLinecap="round"
                strokeWidth="3"
                className={styles.spinnerPath}
              />
            </svg>
          </span>
        )}
        {!loading && iconLeft && <span className={styles.iconLeft} aria-hidden="true">{iconLeft}</span>}
        <span className={styles.label}>{children}</span>
        {!loading && iconRight && <span className={styles.iconRight} aria-hidden="true">{iconRight}</span>}
      </button>
    );
  }
);

Button.displayName = 'Button';

export default Button;