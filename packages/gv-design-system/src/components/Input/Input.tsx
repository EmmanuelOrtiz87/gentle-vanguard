import { forwardRef, InputHTMLAttributes, TextareaHTMLAttributes, SelectHTMLAttributes } from 'react';
import styles from './Input.module.css';

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

export const Input = forwardRef<HTMLInputElement, InputProps>(
  (
    {
      label,
      hint,
      error,
      success,
      iconLeft,
      iconRight,
      size = 'md',
      loading = false,
      className = '',
      id,
      ...props
    },
    ref
  ) => {
    const inputId = id || `gv-input-${Math.random().toString(36).slice(2, 9)}`;
    const hintId = hint ? `${inputId}-hint` : undefined;
    const errorId = error ? `${inputId}-error` : undefined;
    const successId = success ? `${inputId}-success` : undefined;
    const describedBy = [hintId, errorId, successId].filter(Boolean).join(' ') || undefined;

    const hasIconLeftProp = iconLeft !== undefined;

    return (
      <div className={`${styles.wrapper} ${className}`}>
        {label && (
          <label htmlFor={inputId} className={styles.label}>
            {label}
          </label>
        )}
        <div className={`${styles.field} ${iconLeft ? styles.hasIconLeft : ''} ${iconRight ? styles.hasIconRight : ''} ${loading ? styles.loading : ''}`}>
          {iconLeft && <span className={styles.iconLeft} aria-hidden="true">{iconLeft}</span>}
          <input
            ref={ref}
            id={inputId}
            className={styles.input}
            aria-describedby={describedBy}
            aria-invalid={error ? 'true' : 'false'}
            aria-busy={loading}
            disabled={loading}
            {...props}
          />
          {iconRight && <span className={styles.iconRight} aria-hidden="true">{iconRight}</span>}
          {loading && (
            <span className={styles.spinner} aria-hidden="true">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="12" cy="12" r="10" strokeOpacity="0.25" />
                <path d="M12 2a10 10 0 0 1 10 10" strokeLinecap="round" strokeWidth="3" className={styles.spinnerPath} />
              </svg>
            </span>
          )}
        </div>
        {error && <p id={errorId} className={styles.error} role="alert">{error}</p>}
        {success && <p id={successId} className={styles.success}>{success}</p>}
        {hint && !error && <p id={hintId} className={styles.hint}>{hint}</p>}
      </div>
    );
  }
);

Input.displayName = 'Input';

export const Textarea = forwardRef<HTMLTextAreaElement, Omit<InputProps, 'type'> & TextareaHTMLAttributes<HTMLTextAreaElement>>(
  ({ label, hint, error, success, className = '', id, ...props }, ref) => {
    const textareaId = id || `gv-textarea-${Math.random().toString(36).slice(2, 9)}`;
    const hintId = hint ? `${id}-hint` : undefined;
    const errorId = error ? `${id}-error` : undefined;
    const successId = success ? `${id}-success` : undefined;
    const describedBy = [hintId, errorId, successId].filter(Boolean).join(' ') || undefined;

    return (
      <div className={className}>
        {label && <label htmlFor={id} className="gv-input__label">{label}</label>}
        <div className="gv-input__field">
          <textarea
            ref={ref}
            id={id}
            className="gv-input"
            aria-describedby={hintId || errorId || successId ? [hintId, errorId, successId].filter(Boolean).join(' ') : undefined}
            aria-invalid={error ? 'true' : 'false'}
            {...props}
          />
        </div>
        {error && <p className="gv-input__error" role="alert">{error}</p>}
        {success && <p className="gv-input__success">{success}</p>}
        {hint && !error && <p className="gv-input__hint">{hint}</p>}
      </div>
    );
  }
);

Textarea.displayName = 'Textarea';

export const Select = forwardRef<HTMLSelectElement, Omit<InputProps, 'type'> & SelectHTMLAttributes<HTMLSelectElement>>(
  ({ label, hint, error, success, className = '', id, children, ...props }, ref) => {
    const selectId = id || `gv-select-${Math.random().toString(36).slice(2, 9)}`;
    const describedBy = [hint, error, success].filter(Boolean).join(' ') || undefined;

    return (
      <div className="gv-input-wrapper">
        {label && <label htmlFor={id} className="gv-input__label">{label}</label>}
        <div className="gv-input__field">
          <select
            ref={ref}
            id={id}
            className="gv-input"
            aria-describedby={hint || error || success ? [hint, error, success].filter(Boolean).join(' ') : undefined}
            aria-invalid={error ? 'true' : 'false'}
            {...props}
          >
            {children}
          </select>
        </div>
        {error && <p className="gv-input__error" role="alert">{error}</p>}
        {hint && !error && <p className="gv-input__hint">{hint}</p>}
      </div>
    );
  }
);

Select.displayName = 'Select';

export default { Input, Textarea, Select };