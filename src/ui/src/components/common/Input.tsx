import React, { forwardRef, ReactNode } from 'react';

type InputVariant = 'default' | 'error' | 'success' | 'warning';
type InputSize = 'sm' | 'md' | 'lg';

interface InputProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'size'> {
  className?: string;
  variant?: InputVariant;
  size?: InputSize;
  label?: string;
  error?: string;
  success?: string;
  warning?: string;
  helperText?: string;
  leftIcon?: ReactNode;
  rightIcon?: ReactNode;
  loading?: boolean;
  required?: boolean;
  showRequiredIndicator?: boolean;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(({
  className = '',
  variant = 'default',
  size = 'md',
  label,
  error,
  success,
  warning,
  helperText,
  leftIcon,
  rightIcon,
  loading = false,
  required = false,
  showRequiredIndicator = true,
  id,
  ...props
}, ref) => {
  const inputId = id || `input-${Math.random().toString(36).substr(2, 9)}`;
  
  // Determine current variant based on validation states
  const currentVariant = error ? 'error' : success ? 'success' : warning ? 'warning' : variant;
  
  const sizeClasses = {
    sm: 'px-2.5 py-1.5 text-xs',
    md: 'px-3 py-2 text-sm',
    lg: 'px-4 py-2.5 text-base'
  };

  const variantClasses = {
    default: 'border-gray-300 focus:border-blue-500 focus:ring-blue-500',
    error: 'border-red-300 focus:border-red-500 focus:ring-red-500 bg-red-50',
    success: 'border-green-300 focus:border-green-500 focus:ring-green-500 bg-green-50',
    warning: 'border-yellow-300 focus:border-yellow-500 focus:ring-yellow-500 bg-yellow-50'
  };

  const iconSizeClasses = {
    sm: 'w-3 h-3',
    md: 'w-4 h-4',
    lg: 'w-5 h-5'
  };

  const baseClasses = `
    block w-full rounded-md border transition-colors duration-200
    placeholder-gray-400 focus:outline-none focus:ring-1
    disabled:cursor-not-allowed disabled:bg-gray-50 disabled:text-gray-500 disabled:border-gray-200
    ${sizeClasses[size]}
    ${variantClasses[currentVariant]}
    ${leftIcon ? (size === 'sm' ? 'pl-7' : size === 'md' ? 'pl-9' : 'pl-11') : ''}
    ${rightIcon || loading ? (size === 'sm' ? 'pr-7' : size === 'md' ? 'pr-9' : 'pr-11') : ''}
    ${className}
  `.trim().replace(/\s+/g, ' ');

  const renderValidationMessage = () => {
    const message = error || success || warning;
    if (!message) return null;

    const messageClasses = {
      error: 'text-red-600',
      success: 'text-green-600',
      warning: 'text-yellow-600'
    };

    const icons = {
      error: (
        <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
          <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
        </svg>
      ),
      success: (
        <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
        </svg>
      ),
      warning: (
        <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
          <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
        </svg>
      )
    };

    return (
      <div className={`mt-1 flex items-center space-x-1 text-xs ${messageClasses[currentVariant]}`}>
        {icons[currentVariant]}
        <span>{message}</span>
      </div>
    );
  };

  const renderHelperText = () => {
    if (!helperText || error || success || warning) return null;
    return (
      <div className="mt-1 text-xs text-gray-500">
        {helperText}
      </div>
    );
  };

  const renderLoadingSpinner = () => {
    if (!loading) return null;
    return (
      <div className="animate-spin">
        <svg className={iconSizeClasses[size]} fill="none" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
          <path className="opacity-75" fill="currentColor" d="m4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"/>
        </svg>
      </div>
    );
  };

  return (
    <div className="w-full">
      {label && (
        <label 
          htmlFor={inputId}
          className="block text-sm font-medium text-gray-700 mb-1"
        >
          {label}
          {required && showRequiredIndicator && (
            <span className="text-red-500 ml-1" aria-label="required">*</span>
          )}
        </label>
      )}
      
      <div className="relative">
        {leftIcon && (
          <div className={`absolute left-0 top-0 bottom-0 flex items-center ${
            size === 'sm' ? 'pl-2' : size === 'md' ? 'pl-3' : 'pl-4'
          } pointer-events-none text-gray-400`}>
            <div className={iconSizeClasses[size]}>
              {leftIcon}
            </div>
          </div>
        )}
        
        <input
          ref={ref}
          id={inputId}
          className={baseClasses}
          required={required}
          aria-invalid={!!error}
          aria-describedby={
            error ? `${inputId}-error` : 
            success ? `${inputId}-success` : 
            warning ? `${inputId}-warning` :
            helperText ? `${inputId}-helper` : undefined
          }
          {...props}
        />
        
        {(rightIcon || loading) && (
          <div className={`absolute right-0 top-0 bottom-0 flex items-center ${
            size === 'sm' ? 'pr-2' : size === 'md' ? 'pr-3' : 'pr-4'
          } pointer-events-none text-gray-400`}>
            <div className={iconSizeClasses[size]}>
              {loading ? renderLoadingSpinner() : rightIcon}
            </div>
          </div>
        )}
      </div>
      
      {renderValidationMessage()}
      {renderHelperText()}
    </div>
  );
});

Input.displayName = 'Input';

// Additional input variants for specific use cases
export const SearchInput = forwardRef<HTMLInputElement, Omit<InputProps, 'leftIcon' | 'type'>>(
  (props, ref) => {
    const searchIcon = (
      <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="m21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
      </svg>
    );
    
    return (
      <Input
        ref={ref}
        type="search"
        leftIcon={searchIcon}
        placeholder="Search..."
        {...props}
      />
    );
  }
);

SearchInput.displayName = 'SearchInput';

export const PasswordInput = forwardRef<HTMLInputElement, Omit<InputProps, 'rightIcon' | 'type'>>(
  ({ ...props }, ref) => {
    const [showPassword, setShowPassword] = React.useState(false);
    
    const toggleIcon = (
      <button
        type="button"
        className="text-gray-400 hover:text-gray-600 transition-colors"
        onClick={() => setShowPassword(!showPassword)}
        tabIndex={-1}
      >
        {showPassword ? (
          <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21" />
          </svg>
        ) : (
          <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
          </svg>
        )}
      </button>
    );
    
    return (
      <Input
        ref={ref}
        type={showPassword ? 'text' : 'password'}
        rightIcon={toggleIcon}
        {...props}
      />
    );
  }
);

PasswordInput.displayName = 'PasswordInput';

export type { InputProps };