import React from 'react';

type SpinnerSize = 'sm' | 'md' | 'lg' | 'xl';
type SpinnerVariant = 'spinner' | 'pulse' | 'bounce' | 'skeleton';

interface LoadingSpinnerProps {
  message?: string;
  size?: SpinnerSize;
  variant?: SpinnerVariant;
  color?: string;
  className?: string;
  fullScreen?: boolean;
  overlay?: boolean;
}

interface SkeletonProps {
  lines?: number;
  avatar?: boolean;
  button?: boolean;
  width?: string;
  height?: string;
}

const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({ 
  message = 'Loading...', 
  size = 'md',
  variant = 'spinner',
  color = 'blue',
  className = '',
  fullScreen = false,
  overlay = false
}) => {
  const sizeClasses = {
    sm: 'h-4 w-4',
    md: 'h-8 w-8',
    lg: 'h-12 w-12',
    xl: 'h-16 w-16'
  };

  const colorClasses = {
    blue: 'border-blue-600',
    green: 'border-green-600',
    red: 'border-red-600',
    gray: 'border-gray-600',
    purple: 'border-purple-600'
  };

  const containerClasses = fullScreen 
    ? 'fixed inset-0 z-50 flex flex-col items-center justify-center bg-white bg-opacity-90'
    : 'flex flex-col items-center justify-center p-8';

  const renderSpinner = () => {
    switch (variant) {
      case 'pulse':
        return (
          <div className={`${sizeClasses[size]} bg-${color}-600 rounded-full animate-pulse`}>
            <div className="w-full h-full bg-white rounded-full animate-ping"></div>
          </div>
        );
      
      case 'bounce':
        return (
          <div className="flex space-x-1">
            {[0, 1, 2].map((i) => (
              <div
                key={i}
                className={`${size === 'sm' ? 'w-2 h-2' : size === 'md' ? 'w-3 h-3' : size === 'lg' ? 'w-4 h-4' : 'w-5 h-5'} bg-${color}-600 rounded-full animate-bounce`}
                style={{ animationDelay: `${i * 0.1}s` }}
              ></div>
            ))}
          </div>
        );
      
      case 'skeleton':
        return <SkeletonLoader />;
      
      default:
        return (
          <div className={`animate-spin rounded-full ${sizeClasses[size]} border-b-2 ${colorClasses[color as keyof typeof colorClasses] || colorClasses.blue}`}></div>
        );
    }
  };

  return (
    <div className={`${containerClasses} ${className}`}>
      {overlay && <div className="absolute inset-0 bg-black bg-opacity-20 backdrop-blur-sm"></div>}
      <div className="relative z-10 flex flex-col items-center">
        {renderSpinner()}
        {message && variant !== 'skeleton' && (
          <p className={`mt-4 text-gray-600 text-center ${size === 'sm' ? 'text-xs' : size === 'md' ? 'text-sm' : 'text-base'}`}>
            {message}
          </p>
        )}
      </div>
    </div>
  );
};

// Skeleton Loader Component
export const SkeletonLoader: React.FC<SkeletonProps> = ({
  lines = 3,
  avatar = false,
  button = false,
  width = 'full',
  height = 'auto'
}) => {
  return (
    <div className={`animate-pulse space-y-3 ${width === 'full' ? 'w-full' : width}`} style={{ height }}>
      {avatar && (
        <div className="flex items-center space-x-3 mb-4">
          <div className="w-10 h-10 bg-gray-300 rounded-full"></div>
          <div className="flex-1 space-y-2">
            <div className="h-4 bg-gray-300 rounded w-1/4"></div>
            <div className="h-3 bg-gray-300 rounded w-1/3"></div>
          </div>
        </div>
      )}
      
      {Array.from({ length: lines }).map((_, i) => (
        <div key={i} className="space-y-2">
          <div className={`h-4 bg-gray-300 rounded ${i === lines - 1 ? 'w-2/3' : 'w-full'}`}></div>
        </div>
      ))}
      
      {button && (
        <div className="pt-4">
          <div className="h-10 bg-gray-300 rounded w-32"></div>
        </div>
      )}
    </div>
  );
};

// Card Skeleton for common use cases
export const CardSkeleton: React.FC = () => {
  return (
    <div className="bg-white p-6 rounded-lg shadow-sm border animate-pulse space-y-4">
      <div className="flex items-center space-x-3">
        <div className="w-12 h-12 bg-gray-300 rounded-lg"></div>
        <div className="flex-1 space-y-2">
          <div className="h-4 bg-gray-300 rounded w-1/2"></div>
          <div className="h-3 bg-gray-300 rounded w-1/3"></div>
        </div>
      </div>
      <div className="space-y-2">
        <div className="h-4 bg-gray-300 rounded"></div>
        <div className="h-4 bg-gray-300 rounded"></div>
        <div className="h-4 bg-gray-300 rounded w-3/4"></div>
      </div>
      <div className="flex space-x-2 pt-2">
        <div className="h-8 bg-gray-300 rounded w-20"></div>
        <div className="h-8 bg-gray-300 rounded w-16"></div>
      </div>
    </div>
  );
};

// Table Skeleton for data tables
export const TableSkeleton: React.FC<{ rows?: number; cols?: number }> = ({ rows = 5, cols = 4 }) => {
  return (
    <div className="animate-pulse">
      <div className="bg-white shadow-sm rounded-lg overflow-hidden">
        {/* Header */}
        <div className="bg-gray-50 px-6 py-3 border-b">
          <div className="flex space-x-4">
            {Array.from({ length: cols }).map((_, i) => (
              <div key={i} className="h-4 bg-gray-300 rounded flex-1"></div>
            ))}
          </div>
        </div>
        
        {/* Rows */}
        {Array.from({ length: rows }).map((_, rowIndex) => (
          <div key={rowIndex} className="px-6 py-4 border-b border-gray-200">
            <div className="flex space-x-4">
              {Array.from({ length: cols }).map((_, colIndex) => (
                <div key={colIndex} className={`h-4 bg-gray-300 rounded ${
                  colIndex === 0 ? 'w-1/4' : 
                  colIndex === cols - 1 ? 'w-1/6' : 'flex-1'
                }`}></div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default LoadingSpinner;
export type { LoadingSpinnerProps, SkeletonProps };