import React from 'react';

interface SaveIndicatorProps {
  isDirty: boolean;
  isSaving: boolean;
  lastSavedAt?: Date;
  className?: string;
}

const SaveIndicator: React.FC<SaveIndicatorProps> = ({ 
  isDirty, 
  isSaving, 
  lastSavedAt,
  className = '' 
}) => {
  const getTimeAgo = (date: Date) => {
    const seconds = Math.floor((Date.now() - date.getTime()) / 1000);
    
    if (seconds < 60) return 'just now';
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
    return `${Math.floor(seconds / 86400)}d ago`;
  };

  if (isSaving) {
    return (
      <div className={`flex items-center gap-2 text-sm text-blue-600 ${className}`}>
        <svg className="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
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
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          />
        </svg>
        <span>Saving...</span>
      </div>
    );
  }

  if (isDirty) {
    return (
      <div className={`flex items-center gap-2 text-sm text-yellow-600 ${className}`}>
        <span className="text-lg leading-none">●</span>
        <span>Unsaved changes</span>
      </div>
    );
  }

  if (lastSavedAt) {
    return (
      <div className={`flex items-center gap-2 text-sm text-gray-500 ${className}`}>
        <svg className="w-4 h-4 text-green-500" fill="currentColor" viewBox="0 0 20 20">
          <path 
            fillRule="evenodd" 
            d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" 
            clipRule="evenodd" 
          />
        </svg>
        <span>Saved {getTimeAgo(lastSavedAt)}</span>
      </div>
    );
  }

  return null;
};

export default SaveIndicator;