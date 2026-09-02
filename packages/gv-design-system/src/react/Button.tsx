import { type ButtonHTMLAttributes, type ReactNode, forwardRef } from 'react';
import './Button.css';

export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';
export type ButtonSize = 'sm' | 'md' | 'lg';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  iconLeft?: ReactNode;
  iconRight?: ReactNode;
  loading?: boolean;
  fullWidth?: boolean;
}

/**
 * Button — Gentle-Vanguard primary action component.
 *
 * @example
 *   <Button variant="primary" onClick={...}>Save</Button>
 *   <Button variant="ghost" iconLeft={<Icon />}>Cancel</Button>
 *   <Button variant="primary" loading>Saving...</Button>
 */
export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  {
    variant = 'primary',
    size = 'md',
    iconLeft,
    iconRight,
    loading = false,
    fullWidth = false,
    disabled,
    className = '',
    children,
    ...rest
  },
  ref
) {
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

  return (
    <button
      ref={ref}
      className={classes}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      {...rest}
    >
      {iconLeft && <span className="gv-btn__icon gv-btn__icon--left">{iconLeft}</span>}
      <span className="gv-btn__label">{children}</span>
      {iconRight && <span className="gv-btn__icon gv-btn__icon--right">{iconRight}</span>}
      {loading && <span className="gv-btn__spinner" aria-hidden="true" />}
    </button>
  );
});
