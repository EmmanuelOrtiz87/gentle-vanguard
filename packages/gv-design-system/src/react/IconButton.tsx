import { type ButtonHTMLAttributes, type ReactNode, forwardRef } from 'react';
import './IconButton.css';

export type IconButtonVariant = 'default' | 'primary' | 'ghost';
export type IconButtonSize = 'sm' | 'md' | 'lg';

export interface IconButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: IconButtonVariant;
  size?: IconButtonSize;
  icon: ReactNode;
  'aria-label': string; // required for accessibility
}

/**
 * IconButton — Gentle-Vanguard v2 square icon-only button.
 * Used in toolbars, topbars, cards. Requires aria-label (icon-only = needs explicit label).
 *
 * @example
 *   <IconButton icon={<SearchIcon />} aria-label="Search" />
 *   <IconButton icon={<CloseIcon />} variant="primary" aria-label="Close" />
 */
export const IconButton = forwardRef<HTMLButtonElement, IconButtonProps>(function IconButton(
  {
    variant = 'default',
    size = 'md',
    icon,
    disabled,
    className = '',
    ...rest
  },
  ref
) {
  const classes = [
    'gv-icon-btn',
    `gv-icon-btn--${variant}`,
    `gv-icon-btn--${size}`,
    className,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <button ref={ref} className={classes} disabled={disabled} {...rest}>
      <span className="gv-icon-btn__icon" aria-hidden="true">
        {icon}
      </span>
    </button>
  );
});
