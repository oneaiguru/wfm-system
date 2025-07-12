import React from 'react';

export interface SaveWarningDialogProps {
  isOpen: boolean;
  onSave: () => void | Promise<void>;
  onDiscard: () => void;
  onCancel: () => void;
  tabName?: string;
  isSaving?: boolean;
}

const SaveWarningDialog: React.FC<SaveWarningDialogProps> = ({
  isOpen,
  onSave,
  onDiscard,
  onCancel,
  tabName = 'this tab',
  isSaving = false,
}) => {
  if (!isOpen) return null;

  const handleSave = async () => {
    if (!isSaving) {
      await onSave();
    }
  };

  return (
    <>
      {/* Backdrop */}
      <div 
        className="fixed inset-0 bg-black bg-opacity-50 z-40 transition-opacity"
        onClick={onCancel}
      />
      
      {/* Dialog */}
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div className="bg-white rounded-lg shadow-xl max-w-md w-full p-6 transform transition-all">
          {/* Icon */}
          <div className="flex items-center justify-center w-12 h-12 mx-auto bg-yellow-100 rounded-full mb-4">
            <svg 
              className="w-6 h-6 text-yellow-600" 
              fill="none" 
              stroke="currentColor" 
              viewBox="0 0 24 24"
            >
              <path 
                strokeLinecap="round" 
                strokeLinejoin="round" 
                strokeWidth={2} 
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" 
              />
            </svg>
          </div>
          
          {/* Content */}
          <div className="text-center mb-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              Unsaved Changes
            </h3>
            <p className="text-sm text-gray-600">
              You have unsaved changes in {tabName}. What would you like to do?
            </p>
          </div>
          
          {/* Actions */}
          <div className="space-y-3">
            <button
              onClick={handleSave}
              disabled={isSaving}
              className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {isSaving ? (
                <>
                  <svg className="animate-spin h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
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
                </>
              ) : (
                <>
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path 
                      strokeLinecap="round" 
                      strokeLinejoin="round" 
                      strokeWidth={2} 
                      d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V2" 
                    />
                  </svg>
                  <span>Save Changes</span>
                </>
              )}
            </button>
            
            <button
              onClick={onDiscard}
              disabled={isSaving}
              className="w-full bg-white text-red-600 border border-red-600 py-2 px-4 rounded-lg hover:bg-red-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path 
                  strokeLinecap="round" 
                  strokeLinejoin="round" 
                  strokeWidth={2} 
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" 
                />
              </svg>
              <span>Discard Changes</span>
            </button>
            
            <button
              onClick={onCancel}
              disabled={isSaving}
              className="w-full bg-gray-100 text-gray-700 py-2 px-4 rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Cancel
            </button>
          </div>
          
          {/* Keyboard shortcut hint */}
          <div className="mt-4 text-center">
            <p className="text-xs text-gray-500">
              Tip: Use <kbd className="px-1 py-0.5 bg-gray-100 rounded text-xs">Ctrl+S</kbd> or <kbd className="px-1 py-0.5 bg-gray-100 rounded text-xs">⌘+S</kbd> to save quickly
            </p>
          </div>
        </div>
      </div>
    </>
  );
};

export default SaveWarningDialog;