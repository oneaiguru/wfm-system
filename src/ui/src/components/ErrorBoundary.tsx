import React, { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
  onError?: (error: Error, errorInfo: ErrorInfo) => void;
  isolate?: boolean;
  level?: 'page' | 'section' | 'component';
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorId: string;
  retryCount: number;
}

class ErrorBoundary extends Component<Props, State> {
  private retryTimeoutId: number | null = null;

  public state: State = {
    hasError: false,
    error: null,
    errorId: '',
    retryCount: 0
  };

  public static getDerivedStateFromError(error: Error): Partial<State> {
    const errorId = `error-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    return { 
      hasError: true, 
      error,
      errorId
    };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    const { onError } = this.props;
    
    // Log error details
    console.group('🚨 Error Boundary Caught Error');
    console.error('Error:', error);
    console.error('Error Info:', errorInfo);
    console.error('Component Stack:', errorInfo.componentStack);
    console.error('Error ID:', this.state.errorId);
    console.groupEnd();

    // Report to external service if provided
    if (onError) {
      onError(error, errorInfo);
    }

    // Report to analytics/monitoring service
    this.reportError(error, errorInfo);
  }

  private reportError = (error: Error, errorInfo: ErrorInfo) => {
    // This would typically send to your error monitoring service
    // For now, we'll just structure the data for potential reporting
    const errorReport = {
      message: error.message,
      stack: error.stack,
      componentStack: errorInfo.componentStack,
      errorId: this.state.errorId,
      timestamp: new Date().toISOString(),
      userAgent: navigator.userAgent,
      url: window.location.href,
      userId: localStorage.getItem('user_id') || 'anonymous',
    };

    // You could send this to services like Sentry, LogRocket, etc.
    console.log('Error Report:', errorReport);
  };

  private handleRetry = () => {
    this.setState(prevState => ({
      hasError: false,
      error: null,
      errorId: '',
      retryCount: prevState.retryCount + 1
    }));
  };

  private handleRefresh = () => {
    window.location.reload();
  };

  private handleGoHome = () => {
    window.location.href = '/';
  };

  private copyErrorId = () => {
    navigator.clipboard.writeText(this.state.errorId);
    // You could show a toast notification here
    console.log('Error ID copied to clipboard');
  };

  private renderErrorIcon = () => {
    const { level = 'page' } = this.props;
    
    const iconSize = {
      page: 'w-16 h-16',
      section: 'w-12 h-12',
      component: 'w-8 h-8'
    };

    return (
      <div className={`${iconSize[level]} text-red-500 mx-auto mb-4`}>
        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 18.5c-.77.833.192 2.5 1.732 2.5z" />
        </svg>
      </div>
    );
  };

  private renderErrorDetails = () => {
    const { error } = this.state;
    if (!error) return null;

    return (
      <details className="mt-4 text-left">
        <summary className="cursor-pointer text-sm font-medium text-gray-700 hover:text-gray-900">
          Technical Details
        </summary>
        <div className="mt-2 p-3 bg-gray-100 rounded-md text-xs font-mono text-gray-600 overflow-x-auto">
          <div className="mb-2">
            <strong>Error:</strong> {error.message}
          </div>
          {error.stack && (
            <div>
              <strong>Stack:</strong>
              <pre className="mt-1 whitespace-pre-wrap">{error.stack}</pre>
            </div>
          )}
        </div>
      </details>
    );
  };

  private renderPageError = () => (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="bg-white p-8 rounded-xl shadow-lg max-w-md w-full text-center">
        {this.renderErrorIcon()}
        
        <h1 className="text-2xl font-bold text-gray-900 mb-2">
          Oops! Something went wrong
        </h1>
        
        <p className="text-gray-600 mb-6">
          We're sorry, but something unexpected happened. Our team has been notified and we're working to fix this issue.
        </p>

        <div className="space-y-3">
          <button
            onClick={this.handleRetry}
            className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
          >
            Try Again
          </button>
          
          <div className="flex space-x-2">
            <button
              onClick={this.handleRefresh}
              className="flex-1 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors font-medium"
            >
              Refresh Page
            </button>
            
            <button
              onClick={this.handleGoHome}
              className="flex-1 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors font-medium"
            >
              Go Home
            </button>
          </div>
        </div>

        {this.state.errorId && (
          <div className="mt-6 pt-4 border-t border-gray-200">
            <p className="text-xs text-gray-500 mb-2">Error ID for support:</p>
            <button
              onClick={this.copyErrorId}
              className="text-xs font-mono bg-gray-100 px-2 py-1 rounded border text-gray-600 hover:bg-gray-200 transition-colors"
              title="Click to copy"
            >
              {this.state.errorId}
            </button>
          </div>
        )}

        {this.renderErrorDetails()}
      </div>
    </div>
  );

  private renderSectionError = () => (
    <div className="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
      {this.renderErrorIcon()}
      
      <h3 className="text-lg font-semibold text-gray-900 mb-2">
        Section Error
      </h3>
      
      <p className="text-gray-600 mb-4">
        This section couldn't load properly. Try refreshing or continue using other parts of the application.
      </p>

      <div className="flex justify-center space-x-2">
        <button
          onClick={this.handleRetry}
          className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors text-sm font-medium"
        >
          Retry Section
        </button>
        
        <button
          onClick={this.handleRefresh}
          className="px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300 transition-colors text-sm font-medium"
        >
          Refresh Page
        </button>
      </div>

      {this.renderErrorDetails()}
    </div>
  );

  private renderComponentError = () => (
    <div className="bg-yellow-50 border border-yellow-200 rounded-md p-4 text-center">
      {this.renderErrorIcon()}
      
      <h4 className="text-sm font-medium text-gray-900 mb-1">
        Component Error
      </h4>
      
      <p className="text-xs text-gray-600 mb-3">
        This component failed to load.
      </p>

      <button
        onClick={this.handleRetry}
        className="px-3 py-1 bg-yellow-200 text-yellow-800 rounded text-xs font-medium hover:bg-yellow-300 transition-colors"
      >
        Retry
      </button>
    </div>
  );

  public render() {
    if (this.state.hasError) {
      // Custom fallback
      if (this.props.fallback) {
        return this.props.fallback;
      }

      // Level-based fallback
      const { level = 'page' } = this.props;
      
      switch (level) {
        case 'section':
          return this.renderSectionError();
        case 'component':
          return this.renderComponentError();
        default:
          return this.renderPageError();
      }
    }

    return this.props.children;
  }
}

// Higher-order component for wrapping components with error boundaries
export const withErrorBoundary = <P extends object>(
  Component: React.ComponentType<P>,
  errorBoundaryProps?: Omit<Props, 'children'>
) => {
  const WrappedComponent = (props: P) => (
    <ErrorBoundary {...errorBoundaryProps}>
      <Component {...props} />
    </ErrorBoundary>
  );
  
  WrappedComponent.displayName = `withErrorBoundary(${Component.displayName || Component.name})`;
  return WrappedComponent;
};

// Hook for error reporting from functional components
export const useErrorHandler = () => {
  return React.useCallback((error: Error, errorInfo?: ErrorInfo) => {
    console.error('Manual error report:', error, errorInfo);
    // This could trigger the same error reporting as the boundary
  }, []);
};

export default ErrorBoundary;