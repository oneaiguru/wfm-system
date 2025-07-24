import React, { useState } from 'react';
import LoadingSpinner, { SkeletonLoader, CardSkeleton, TableSkeleton } from './LoadingSpinner';
import { Input, SearchInput, PasswordInput } from './common/Input';
import { Button, PrimaryButton, SecondaryButton, DangerButton, SuccessButton, GhostButton, IconButton, ButtonGroup } from './common/Button';
import ErrorBoundary from './ErrorBoundary';
import { ToastProvider, useToastHelpers } from './common/Toast';

// Demo component to showcase all the polished UI components
const UIPolishDemo: React.FC = () => {
  const [inputValue, setInputValue] = useState('');
  const [searchValue, setSearchValue] = useState('');
  const [passwordValue, setPasswordValue] = useState('');
  const [loading, setLoading] = useState(false);
  const [showSkeleton, setShowSkeleton] = useState(false);
  const [inputError, setInputError] = useState('');
  const [inputSuccess, setInputSuccess] = useState('');

  const { success, error, warning, info } = useToastHelpers();

  const handleSubmit = () => {
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      success('Form submitted successfully!', {
        title: 'Success',
        duration: 3000
      });
    }, 2000);
  };

  const validateInput = (value: string) => {
    if (value.length < 3) {
      setInputError('Must be at least 3 characters');
      setInputSuccess('');
    } else if (value.length > 20) {
      setInputError('Must be less than 20 characters');
      setInputSuccess('');
    } else {
      setInputError('');
      setInputSuccess('Input looks good!');
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setInputValue(value);
    validateInput(value);
  };

  const ErrorComponent = () => {
    throw new Error('This is a test error');
  };

  const [showError, setShowError] = useState(false);

  return (
    <div className="p-8 space-y-12 max-w-4xl mx-auto">
      <h1 className="text-3xl font-bold text-gray-900 mb-8">UI Polish Components Demo</h1>

      {/* Loading Spinners Section */}
      <section className="space-y-6">
        <h2 className="text-2xl font-semibold text-gray-800">Loading Spinners & Skeletons</h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="space-y-4">
            <h3 className="text-lg font-medium">Spinner Variants</h3>
            <LoadingSpinner size="sm" message="Small spinner" />
            <LoadingSpinner size="md" variant="pulse" color="green" message="Pulse animation" />
            <LoadingSpinner size="lg" variant="bounce" color="purple" message="Bounce animation" />
          </div>
          
          <div className="space-y-4">
            <h3 className="text-lg font-medium">Skeleton Loaders</h3>
            <button
              onClick={() => setShowSkeleton(!showSkeleton)}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              Toggle Skeleton
            </button>
            {showSkeleton ? (
              <div className="space-y-4">
                <SkeletonLoader lines={3} avatar button />
                <CardSkeleton />
              </div>
            ) : (
              <div className="bg-white p-6 rounded-lg shadow-sm border space-y-4">
                <div className="flex items-center space-x-3">
                  <img src="https://via.placeholder.com/48" alt="Avatar" className="w-12 h-12 rounded-lg" />
                  <div>
                    <h4 className="font-medium">John Doe</h4>
                    <p className="text-sm text-gray-500">Software Engineer</p>
                  </div>
                </div>
                <p>This is some content that would normally be here. When loading, it shows as a skeleton.</p>
                <button className="px-4 py-2 bg-blue-600 text-white rounded">Action Button</button>
              </div>
            )}
          </div>
          
          <div className="col-span-2">
            <h3 className="text-lg font-medium mb-4">Table Skeleton</h3>
            <TableSkeleton rows={3} cols={4} />
          </div>
        </div>
      </section>

      {/* Enhanced Inputs Section */}
      <section className="space-y-6">
        <h2 className="text-2xl font-semibold text-gray-800">Enhanced Input Components</h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-4">
            <Input
              label="Standard Input with Validation"
              value={inputValue}
              onChange={handleInputChange}
              error={inputError}
              success={inputSuccess}
              helperText="Enter some text to see validation"
              required
            />
            
            <SearchInput
              value={searchValue}
              onChange={(e) => setSearchValue(e.target.value)}
              placeholder="Search anything..."
              label="Search Input"
            />
            
            <PasswordInput
              value={passwordValue}
              onChange={(e) => setPasswordValue(e.target.value)}
              label="Password Input"
              helperText="Password visibility toggle included"
            />
          </div>
          
          <div className="space-y-4">
            <Input
              label="Input with Left Icon"
              leftIcon={
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.5 1.207" />
                </svg>
              }
              placeholder="user@example.com"
            />
            
            <Input
              label="Loading Input"
              loading
              value="Processing..."
              disabled
            />
            
            <Input
              label="Warning State"
              warning="This field needs attention"
              defaultValue="Some value"
            />
          </div>
        </div>
      </section>

      {/* Enhanced Buttons Section */}
      <section className="space-y-6">
        <h2 className="text-2xl font-semibold text-gray-800">Enhanced Button Components</h2>
        
        <div className="space-y-6">
          <div className="space-y-4">
            <h3 className="text-lg font-medium">Button Variants & Sizes</h3>
            <div className="flex flex-wrap gap-3">
              <PrimaryButton size="sm">Primary Small</PrimaryButton>
              <SecondaryButton size="md">Secondary Medium</SecondaryButton>
              <SuccessButton size="lg">Success Large</SuccessButton>
              <DangerButton size="xl">Danger XL</DangerButton>
              <GhostButton>Ghost Button</GhostButton>
            </div>
          </div>
          
          <div className="space-y-4">
            <h3 className="text-lg font-medium">Loading States & Icons</h3>
            <div className="flex flex-wrap gap-3">
              <Button
                loading={loading}
                loadingText="Submitting..."
                onClick={handleSubmit}
              >
                Submit Form
              </Button>
              
              <Button
                leftIcon={
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                }
              >
                Add Item
              </Button>
              
              <Button
                rightIcon={
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                  </svg>
                }
              >
                Next Step
              </Button>
              
              <IconButton
                icon={
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                }
                ariaLabel="Delete item"
                variant="destructive"
              />
            </div>
          </div>
          
          <div className="space-y-4">
            <h3 className="text-lg font-medium">Button Groups</h3>
            <ButtonGroup>
              <Button variant="outline">Previous</Button>
              <Button variant="outline">Current</Button>
              <Button variant="outline">Next</Button>
            </ButtonGroup>
            
            <ButtonGroup orientation="vertical">
              <Button variant="ghost">Top</Button>
              <Button variant="ghost">Middle</Button>
              <Button variant="ghost">Bottom</Button>
            </ButtonGroup>
          </div>
        </div>
      </section>

      {/* Toast Notifications Section */}
      <section className="space-y-6">
        <h2 className="text-2xl font-semibold text-gray-800">Toast Notifications</h2>
        
        <div className="flex flex-wrap gap-3">
          <Button
            onClick={() => success('Operation completed successfully!')}
            variant="success"
          >
            Success Toast
          </Button>
          
          <Button
            onClick={() => error('Something went wrong. Please try again.')}
            variant="destructive"
          >
            Error Toast
          </Button>
          
          <Button
            onClick={() => warning('Please check your input before proceeding.')}
            variant="warning"
          >
            Warning Toast
          </Button>
          
          <Button
            onClick={() => info('Here is some helpful information.', {
              title: 'Information',
              action: {
                label: 'Learn More',
                onClick: () => console.log('Learn more clicked')
              }
            })}
          >
            Info Toast with Action
          </Button>
        </div>
      </section>

      {/* Error Boundary Section */}
      <section className="space-y-6">
        <h2 className="text-2xl font-semibold text-gray-800">Error Boundaries</h2>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <h3 className="text-lg font-medium mb-4">Component Level</h3>
            <ErrorBoundary level="component">
              {showError ? <ErrorComponent /> : (
                <div className="p-4 border rounded">
                  <p>This component is working fine.</p>
                  <button
                    onClick={() => setShowError(true)}
                    className="mt-2 px-3 py-1 bg-red-600 text-white rounded text-sm"
                  >
                    Trigger Error
                  </button>
                </div>
              )}
            </ErrorBoundary>
          </div>
          
          <div>
            <h3 className="text-lg font-medium mb-4">Section Level</h3>
            <ErrorBoundary level="section">
              <div className="p-4 border rounded">
                <p>This section has error boundary protection.</p>
              </div>
            </ErrorBoundary>
          </div>
          
          <div>
            <h3 className="text-lg font-medium mb-4">Custom Fallback</h3>
            <ErrorBoundary
              fallback={
                <div className="p-4 bg-yellow-50 border border-yellow-200 rounded">
                  <p className="text-yellow-800">Custom error message here</p>
                </div>
              }
            >
              <div className="p-4 border rounded">
                <p>This has a custom fallback UI.</p>
              </div>
            </ErrorBoundary>
          </div>
        </div>
      </section>

      {/* Reset Demo Button */}
      <section className="pt-8 border-t">
        <Button
          onClick={() => {
            setInputValue('');
            setSearchValue('');
            setPasswordValue('');
            setLoading(false);
            setShowSkeleton(false);
            setInputError('');
            setInputSuccess('');
            setShowError(false);
          }}
          variant="outline"
          fullWidth
        >
          Reset Demo
        </Button>
      </section>
    </div>
  );
};

// Wrapper with Toast Provider
const UIPolishDemoWithProvider: React.FC = () => {
  return (
    <ToastProvider>
      <UIPolishDemo />
    </ToastProvider>
  );
};

export default UIPolishDemoWithProvider;