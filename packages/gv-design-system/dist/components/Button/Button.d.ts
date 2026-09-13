import { ButtonHTMLAttributes } from 'react';
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
export declare const Button: import('react').ForwardRefExoticComponent<
  ButtonProps & import('react').RefAttributes<HTMLButtonElement>
>;
export default Button;
//# sourceMappingURL=Button.d.ts.map
