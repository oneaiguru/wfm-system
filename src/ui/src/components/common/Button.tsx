import React, { forwardRef, ReactNode } from 'react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'default' | 'outline' | 'ghost' | 'destructive' | 'success' | 'warning';
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  children: React.ReactNode;
  loading?: boolean;
  loadingText?: string;
  leftIcon?: ReactNode;
  rightIcon?: ReactNode;
  fullWidth?: boolean;
  rounded?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(({ 
  variant = 'default', 
  size = 'md', 
  className = '', 
  children,
  loading = false,
  loadingText,
  leftIcon,
  rightIcon,
  fullWidth = false,
  rounded = false,
  disabled,
  type = 'button',
  ...props 
}, ref) => {
  const isDisabled = disabled || loading;
  
  const baseClasses = `
    inline-flex items-center justify-center font-medium transition-all duration-200 
    focus:outline-none focus:ring-2 focus:ring-offset-2 
    disabled:opacity-50 disabled:cursor-not-allowed disabled:pointer-events-none
    ${rounded ? 'rounded-full' : 'rounded-md'}
    ${fullWidth ? 'w-full' : ''}
    ${loading ? 'cursor-wait' : ''}
  `.trim().replace(/\s+/g, ' ');
  
  const variantClasses = {
    default: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 active:bg-blue-800 shadow-sm hover:shadow-md',
    outline: 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 focus:ring-blue-500 active:bg-gray-100 shadow-sm hover:shadow-md',
    ghost: 'text-gray-700 hover:bg-gray-100 focus:ring-blue-500 active:bg-gray-200',
    destructive: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500 active:bg-red-800 shadow-sm hover:shadow-md',
    success: 'bg-green-600 text-white hover:bg-green-700 focus:ring-green-500 active:bg-green-800 shadow-sm hover:shadow-md',
    warning: 'bg-yellow-600 text-white hover:bg-yellow-700 focus:ring-yellow-500 active:bg-yellow-800 shadow-sm hover:shadow-md'
  };
  
  const sizeClasses = {
    xs: 'px-2 py-1 text-xs gap-1',
    sm: 'px-3 py-1.5 text-sm gap-1.5',
    md: 'px-4 py-2 text-sm gap-2',
    lg: 'px-6 py-3 text-base gap-2',
    xl: 'px-8 py-4 text-lg gap-3'
  };

  const iconSizeClasses = {
    xs: 'w-3 h-3',
    sm: 'w-4 h-4',
    md: 'w-4 h-4',
    lg: 'w-5 h-5',
    xl: 'w-6 h-6'
  };

  const LoadingSpinner = () => (
    <svg
      className={`animate-spin ${iconSizeClasses[size]}`}
      fill="none"
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
      <circle
        className="opacity-25"
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        strokeWidth="4"
      />
      <path
        className="opacity-75"
        fill="currentColor"
        d="m4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      />
    </svg>
  );

  const renderContent = () => {
    if (loading) {
      return (
        <>
          <LoadingSpinner />
          <span>{loadingText || 'Loading...'}</span>
        </>
      );
    }

    return (
      <>
        {leftIcon && (
          <span className={iconSizeClasses[size]} aria-hidden="true">
            {leftIcon}
          </span>
        )}
        <span>{children}</span>
        {rightIcon && (
          <span className={iconSizeClasses[size]} aria-hidden="true">
            {rightIcon}
          </span>
        )}
      </>
    );
  };

  return (
    <button
      ref={ref}
      type={type}
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${className}`}
      disabled={isDisabled}
      aria-busy={loading}
      aria-describedby={loading ? 'button-loading' : undefined}
      {...props}
    >
      {renderContent()}
    </button>
  );
});

Button.displayName = 'Button';

// Icon Button Component
export const IconButton = forwardRef<HTMLButtonElement, Omit<ButtonProps, 'children' | 'leftIcon' | 'rightIcon'> & { 
  icon: ReactNode;
  ariaLabel: string;
}>(({ 
  icon, 
  ariaLabel, 
  size = 'md',
  variant = 'ghost',
  rounded = true,
  ...props 
}, ref) => {
  const iconOnlySize = {
    xs: 'p-1',
    sm: 'p-1.5',
    md: 'p-2',
    lg: 'p-3',
    xl: 'p-4'
  };

  return (
    <Button
      ref={ref}
      variant={variant}
      size={size}
      rounded={rounded}
      className={`${iconOnlySize[size]} ${props.className || ''}`}
      aria-label={ariaLabel}
      {...props}
    >
      {icon}
    </Button>
  );
});

IconButton.displayName = 'IconButton';

// Button Group Component
export const ButtonGroup: React.FC<{
  children: React.ReactNode;
  className?: string;
  orientation?: 'horizontal' | 'vertical';
  size?: ButtonProps['size'];
  variant?: ButtonProps['variant'];
}> = ({ 
  children, 
  className = '', 
  orientation = 'horizontal',
  size,
  variant 
}) => {
  const groupClasses = orientation === 'horizontal' 
    ? 'inline-flex rounded-md shadow-sm' 
    : 'inline-flex flex-col rounded-md shadow-sm';

  const enhancedChildren = React.Children.map(children, (child, index) => {
    if (React.isValidElement(child) && child.type === Button) {
      const isFirst = index === 0;
      const isLast = index === React.Children.count(children) - 1;
      
      let roundedClasses = '';
      if (orientation === 'horizontal') {
        if (isFirst) roundedClasses = 'rounded-r-none';
        else if (isLast) roundedClasses = 'rounded-l-none';
        else roundedClasses = 'rounded-none';
      } else {
        if (isFirst) roundedClasses = 'rounded-b-none';
        else if (isLast) roundedClasses = 'rounded-t-none';
        else roundedClasses = 'rounded-none';
      }

      const borderClasses = orientation === 'horizontal' && !isFirst 
        ? '-ml-px' 
        : orientation === 'vertical' && !isFirst 
        ? '-mt-px' 
        : '';

      return React.cloneElement(child, {
        ...child.props,
        size: size || child.props.size,
        variant: variant || child.props.variant,
        className: `${child.props.className || ''} ${roundedClasses} ${borderClasses}`.trim()
      });
    }
    return child;
  });

  return (
    <div className={`${groupClasses} ${className}`} role="group">
      {enhancedChildren}
    </div>
  );
};

// Pre-configured button variants for common use cases
export const PrimaryButton = forwardRef<HTMLButtonElement, Omit<ButtonProps, 'variant'>>(
  (props, ref) => <Button ref={ref} variant="default" {...props} />
);

export const SecondaryButton = forwardRef<HTMLButtonElement, Omit<ButtonProps, 'variant'>>(
  (props, ref) => <Button ref={ref} variant="outline" {...props} />
);

export const DangerButton = forwardRef<HTMLButtonElement, Omit<ButtonProps, 'variant'>>(
  (props, ref) => <Button ref={ref} variant="destructive" {...props} />
);

export const SuccessButton = forwardRef<HTMLButtonElement, Omit<ButtonProps, 'variant'>>(
  (props, ref) => <Button ref={ref} variant="success" {...props} />
);

export const GhostButton = forwardRef<HTMLButtonElement, Omit<ButtonProps, 'variant'>>(
  (props, ref) => <Button ref={ref} variant="ghost" {...props} />
);

PrimaryButton.displayName = 'PrimaryButton';
SecondaryButton.displayName = 'SecondaryButton';
DangerButton.displayName = 'DangerButton';
SuccessButton.displayName = 'SuccessButton';
GhostButton.displayName = 'GhostButton';

export type { ButtonProps };