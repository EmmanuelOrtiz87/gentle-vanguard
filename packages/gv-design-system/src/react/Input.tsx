import { type InputHTMLAttributes, type ReactNode, forwardRef, useId } from 'react';
import './Input.css';

export type InputSize = 'sm' | 'md' | 'lg';
export type InputState = 'default' | 'error' | 'success';

export interface InputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'size'> {
  label?: string;
  hint?: string;
  error?: string;
  success?: string;
  size?: InputSize;
  iconLeft?: ReactNode;
  iconRight?: ReactNode;
  fullWidth?: boolean;
}

/**
 * Input — Gentle-Vanguard v2 form control.
 * Built-in label, hint, error/success messaging, icon slots.
 * WCAG 2.2: proper aria-describedby, aria-invalid, label association.
 *
 * @example
 *   <Input label="Email" type="email" required />
 *   <Input label="Password" type="password" error="Too short" />
 *   <Input label="Search" iconLeft={<SearchIcon />} />
 */
export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  {
    label,
    hint,
    error,
    success,
    size = 'md',
    iconLeft,
    iconRight,
    fullWidth = false,
    disabled,
    className = '',
    id: providedId,
    ...rest
  },
  ref
) {
  const generatedId = useId();
  const id = providedId ?? generatedId;
  const hintId = hint ? `${id}-hint` : undefined;
  const messageId = error || success ? `${id}-msg` : undefined;
  const describedBy = [hintId, messageId].filter(Boolean).join(' ') || undefined;

  const state: InputState = error ? 'error' : success ? 'success' : 'default';
  const wrapperClasses = [
    'gv-input-wrapper',
    `gv-input-wrapper--${size}`,
    fullWidth ? 'gv-input-wrapper--full' : '',
  ]
    .filter(Boolean)
    .join(' ');

  const inputClasses = [
    'gv-input',
    `gv-input--${size}`,
    `gv-input--${state}`,
    iconLeft ? 'gv-input--has-icon-left' : '',
    iconRight ? 'gv-input--has-icon-right' : '',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <div className={wrapperClasses}>
      {label && (
        <label htmlFor={id} className="gv-input__label">
          {label}
        </label>
      )}
      <div className="gv-input__field">
        {iconLeft && <span className="gv-input__icon gv-input__icon--left">{iconLeft}</span>}
        <input
          ref={ref}
          id={id}
          className={inputClasses}
          disabled={disabled}
          aria-invalid={error ? 'true' : undefined}
          aria-describedby={describedBy}
          {...rest}
        />
        {iconRight && <span className="gv-input__icon gv-input__icon--right">{iconRight}</span>}
      </div>
      {hint && !error && !success && (
        <span id={hintId} className="gv-input__hint">
          {hint}
        </span>
      )}
      {error && (
        <span id={messageId} className="gv-input__error" role="alert">
          {error}
        </span>
      )}
      {success && !error && (
        <span id={messageId} className="gv-input__success">
          {success}
        </span>
      )}
    </div>
  );
});
