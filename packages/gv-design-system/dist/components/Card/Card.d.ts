import { HTMLAttributes } from 'react';
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
export declare const Card: import('react').ForwardRefExoticComponent<
  CardProps & import('react').RefAttributes<HTMLDivElement>
>;
export default Card;
//# sourceMappingURL=Card.d.ts.map
