import { InputHTMLAttributes, TextareaHTMLAttributes, SelectHTMLAttributes } from 'react';
export interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  /** Label del input */
  label?: string;
  /** Texto de ayuda */
  hint?: string;
  /** Mensaje de error */
  error?: string;
  /** Mensaje de éxito */
  success?: string;
  /** Icono a la izquierda */
  iconLeft?: React.ReactNode;
  /** Icono a la derecha */
  iconRight?: React.ReactNode;
  /** Tamaño */
  size?: 'sm' | 'md' | 'lg';
  /** Estado de carga */
  loading?: boolean;
  /** Si tiene icono a la izquierda (para padding) */
  hasIconLeft?: boolean;
}
export declare const Input: import('react').ForwardRefExoticComponent<
  InputProps & import('react').RefAttributes<HTMLInputElement>
>;
export declare const Textarea: import('react').ForwardRefExoticComponent<
  Omit<InputProps, 'type'> &
    TextareaHTMLAttributes<HTMLTextAreaElement> &
    import('react').RefAttributes<HTMLTextAreaElement>
>;
export declare const Select: import('react').ForwardRefExoticComponent<
  Omit<InputProps, 'type'> &
    SelectHTMLAttributes<HTMLSelectElement> &
    import('react').RefAttributes<HTMLSelectElement>
>;
declare const _default: {
  Input: import('react').ForwardRefExoticComponent<
    InputProps & import('react').RefAttributes<HTMLInputElement>
  >;
  Textarea: import('react').ForwardRefExoticComponent<
    Omit<InputProps, 'type'> &
      TextareaHTMLAttributes<HTMLTextAreaElement> &
      import('react').RefAttributes<HTMLTextAreaElement>
  >;
  Select: import('react').ForwardRefExoticComponent<
    Omit<InputProps, 'type'> &
      SelectHTMLAttributes<HTMLSelectElement> &
      import('react').RefAttributes<HTMLSelectElement>
  >;
};
export default _default;
//# sourceMappingURL=Input.d.ts.map
