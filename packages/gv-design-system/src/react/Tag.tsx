import { type HTMLAttributes, type ReactNode } from 'react';
import './Tag.css';

export type TagVariant = 'primary' | 'secondary' | 'success' | 'warning' | 'error' | 'neutral';
export type TagSize = 'sm' | 'md';

export interface TagProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: TagVariant;
  size?: TagSize;
  icon?: ReactNode;
  children: ReactNode;
}

/**
 * Tag — Gentle-Vanguard v2 pill-shaped label.
 * Use for status indicators, categories, metadata.
 *
 * @example
 *   <Tag variant="success">Active</Tag>
 *   <Tag variant="warning" icon={<Icon />}>Pending</Tag>
 *   <Tag variant="primary" size="sm">Beta</Tag>
 */
export function Tag({
  variant = 'neutral',
  size = 'md',
  icon,
  className = '',
  children,
  ...rest
}: TagProps) {
  const classes = [
    'gv-tag',
    `gv-tag--${variant}`,
    `gv-tag--${size}`,
    className,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <span className={classes} {...rest}>
      {icon && <span className="gv-tag__icon">{icon}</span>}
      <span className="gv-tag__label">{children}</span>
    </span>
  );
}
