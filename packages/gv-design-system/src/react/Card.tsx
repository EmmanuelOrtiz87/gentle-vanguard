import { type HTMLAttributes, type ReactNode, forwardRef } from 'react';
import './Card.css';

export type CardVariant = 'glass' | 'solid' | 'outline';
export type CardPadding = 'none' | 'sm' | 'md' | 'lg';

export interface CardProps extends HTMLAttributes<HTMLDivElement> {
  variant?: CardVariant;
  padding?: CardPadding;
  interactive?: boolean;
  children: ReactNode;
}

/**
 * Card — Gentle-Vanguard v2 surface component.
 * Glass variant is the brand default (backdrop-filter + violet border).
 *
 * @example
 *   <Card variant="glass" padding="md">
 *     <h3>Title</h3>
 *     <p>Body</p>
 *   </Card>
 *   <Card interactive onClick={...}>Clickable card</Card>
 */
export const Card = forwardRef<HTMLDivElement, CardProps>(function Card(
  {
    variant = 'glass',
    padding = 'md',
    interactive = false,
    className = '',
    children,
    ...rest
  },
  ref
) {
  const classes = [
    'gv-card',
    `gv-card--${variant}`,
    `gv-card--p-${padding}`,
    interactive ? 'gv-card--interactive' : '',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <div ref={ref} className={classes} {...rest}>
      {children}
    </div>
  );
});
