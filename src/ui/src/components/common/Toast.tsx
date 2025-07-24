import React, { createContext, useContext, useReducer, useCallback, useEffect } from 'react';
import { createPortal } from 'react-dom';

type ToastType = 'success' | 'error' | 'warning' | 'info';
type ToastPosition = 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right' | 'top-center' | 'bottom-center';

interface Toast {
  id: string;
  type: ToastType;
  title?: string;
  message: string;
  duration?: number;
  persistent?: boolean;
  action?: {
    label: string;
    onClick: () => void;
  };
  onClose?: () => void;
}

interface ToastState {
  toasts: Toast[];
  position: ToastPosition;
}

type ToastAction = 
  | { type: 'ADD_TOAST'; payload: Toast }
  | { type: 'REMOVE_TOAST'; payload: string }
  | { type: 'SET_POSITION'; payload: ToastPosition }
  | { type: 'CLEAR_ALL' };

const initialState: ToastState = {
  toasts: [],
  position: 'top-right'
};

const toastReducer = (state: ToastState, action: ToastAction): ToastState => {
  switch (action.type) {
    case 'ADD_TOAST':
      return {
        ...state,
        toasts: [...state.toasts, action.payload]
      };
    case 'REMOVE_TOAST':
      return {
        ...state,
        toasts: state.toasts.filter(toast => toast.id !== action.payload)
      };
    case 'SET_POSITION':
      return {
        ...state,
        position: action.payload
      };
    case 'CLEAR_ALL':
      return {
        ...state,
        toasts: []
      };
    default:
      return state;
  }
};

interface ToastContextValue {
  addToast: (toast: Omit<Toast, 'id'>) => string;
  removeToast: (id: string) => void;
  clearAll: () => void;
  setPosition: (position: ToastPosition) => void;
}

const ToastContext = createContext<ToastContextValue | undefined>(undefined);

export const useToast = () => {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used within a ToastProvider');
  }
  return context;
};

// Individual Toast Component
const ToastItem: React.FC<{
  toast: Toast;
  onRemove: (id: string) => void;
  position: ToastPosition;
}> = ({ toast, onRemove, position }) => {
  useEffect(() => {
    if (!toast.persistent && toast.duration !== 0) {
      const timer = setTimeout(() => {
        onRemove(toast.id);
        toast.onClose?.();
      }, toast.duration || 5000);

      return () => clearTimeout(timer);
    }
  }, [toast, onRemove]);

  const handleClose = () => {
    onRemove(toast.id);
    toast.onClose?.();
  };

  const getTypeStyles = () => {
    const styles = {
      success: {
        bg: 'bg-green-50',
        border: 'border-green-200',
        icon: 'text-green-400',
        title: 'text-green-800',
        message: 'text-green-700'
      },
      error: {
        bg: 'bg-red-50',
        border: 'border-red-200',
        icon: 'text-red-400',
        title: 'text-red-800',
        message: 'text-red-700'
      },
      warning: {
        bg: 'bg-yellow-50',
        border: 'border-yellow-200',
        icon: 'text-yellow-400',
        title: 'text-yellow-800',
        message: 'text-yellow-700'
      },
      info: {
        bg: 'bg-blue-50',
        border: 'border-blue-200',
        icon: 'text-blue-400',
        title: 'text-blue-800',
        message: 'text-blue-700'
      }
    };
    return styles[toast.type];
  };

  const getIcon = () => {
    const iconProps = {
      className: `w-5 h-5 ${getTypeStyles().icon}`,
      fill: 'none',
      stroke: 'currentColor',
      viewBox: '0 0 24 24'
    };

    switch (toast.type) {
      case 'success':
        return (
          <svg {...iconProps}>
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        );
      case 'error':
        return (
          <svg {...iconProps}>
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        );
      case 'warning':
        return (
          <svg {...iconProps}>
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 18.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
        );
      case 'info':
        return (
          <svg {...iconProps}>
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        );
    }
  };

  const styles = getTypeStyles();
  const isLeft = position.includes('left');
  const animationClass = isLeft ? 'animate-slide-in-left' : 'animate-slide-in-right';

  return (
    <div className={`
      ${styles.bg} ${styles.border} 
      border rounded-lg shadow-lg p-4 mb-3 w-80 max-w-sm
      transform transition-all duration-300 ease-out
      ${animationClass}
    `}>
      <div className="flex">
        <div className="flex-shrink-0">
          {getIcon()}
        </div>
        
        <div className="ml-3 w-0 flex-1">
          {toast.title && (
            <p className={`text-sm font-medium ${styles.title}`}>
              {toast.title}
            </p>
          )}
          <p className={`text-sm ${styles.message} ${toast.title ? 'mt-1' : ''}`}>
            {toast.message}
          </p>
          
          {toast.action && (
            <div className="mt-3">
              <button
                onClick={toast.action.onClick}
                className={`text-sm font-medium ${styles.title} hover:underline focus:outline-none`}
              >
                {toast.action.label}
              </button>
            </div>
          )}
        </div>
        
        <div className="ml-4 flex-shrink-0 flex">
          <button
            onClick={handleClose}
            className={`rounded-md inline-flex text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500`}
          >
            <span className="sr-only">Close</span>
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      </div>
    </div>
  );
};

// Toast Container
const ToastContainer: React.FC<{
  toasts: Toast[];
  position: ToastPosition;
  onRemove: (id: string) => void;
}> = ({ toasts, position, onRemove }) => {
  if (toasts.length === 0) return null;

  const getPositionClasses = () => {
    const positions = {
      'top-left': 'top-4 left-4',
      'top-right': 'top-4 right-4',
      'bottom-left': 'bottom-4 left-4',
      'bottom-right': 'bottom-4 right-4',
      'top-center': 'top-4 left-1/2 transform -translate-x-1/2',
      'bottom-center': 'bottom-4 left-1/2 transform -translate-x-1/2'
    };
    return positions[position];
  };

  return createPortal(
    <div className={`fixed z-50 ${getPositionClasses()}`}>
      <div className="flex flex-col space-y-2">
        {toasts.map(toast => (
          <ToastItem
            key={toast.id}
            toast={toast}
            onRemove={onRemove}
            position={position}
          />
        ))}
      </div>
    </div>,
    document.body
  );
};

// Toast Provider
export const ToastProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, dispatch] = useReducer(toastReducer, initialState);

  const addToast = useCallback((toast: Omit<Toast, 'id'>) => {
    const id = `toast-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    const newToast: Toast = { ...toast, id };
    dispatch({ type: 'ADD_TOAST', payload: newToast });
    return id;
  }, []);

  const removeToast = useCallback((id: string) => {
    dispatch({ type: 'REMOVE_TOAST', payload: id });
  }, []);

  const clearAll = useCallback(() => {
    dispatch({ type: 'CLEAR_ALL' });
  }, []);

  const setPosition = useCallback((position: ToastPosition) => {
    dispatch({ type: 'SET_POSITION', payload: position });
  }, []);

  const contextValue: ToastContextValue = {
    addToast,
    removeToast,
    clearAll,
    setPosition
  };

  return (
    <ToastContext.Provider value={contextValue}>
      {children}
      <ToastContainer
        toasts={state.toasts}
        position={state.position}
        onRemove={removeToast}
      />
    </ToastContext.Provider>
  );
};

// Convenience hooks for different toast types
export const useToastHelpers = () => {
  const { addToast } = useToast();

  return {
    success: (message: string, options?: Partial<Omit<Toast, 'id' | 'type' | 'message'>>) =>
      addToast({ type: 'success', message, ...options }),
    
    error: (message: string, options?: Partial<Omit<Toast, 'id' | 'type' | 'message'>>) =>
      addToast({ type: 'error', message, ...options }),
    
    warning: (message: string, options?: Partial<Omit<Toast, 'id' | 'type' | 'message'>>) =>
      addToast({ type: 'warning', message, ...options }),
    
    info: (message: string, options?: Partial<Omit<Toast, 'id' | 'type' | 'message'>>) =>
      addToast({ type: 'info', message, ...options }),
  };
};

export type { Toast, ToastType, ToastPosition };