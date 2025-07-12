import { useEffect, useRef, useCallback } from 'react';
import { useSaveState } from '../context/SaveStateContext';

interface UseFormTrackerOptions {
  tabId: string;
  onDirtyChange?: (isDirty: boolean) => void;
  excludeSelectors?: string[]; // CSS selectors to exclude from tracking
}

export const useFormTracker = ({ tabId, onDirtyChange, excludeSelectors = [] }: UseFormTrackerOptions) => {
  const { setTabDirty, getTabState } = useSaveState();
  const formRef = useRef<HTMLElement | null>(null);
  const initialValuesRef = useRef<Map<string, any>>(new Map());
  const isTrackingRef = useRef(true);

  // Get current form values
  const getFormValues = useCallback(() => {
    const values = new Map<string, any>();
    
    if (!formRef.current) return values;
    
    // Track all form inputs
    const inputs = formRef.current.querySelectorAll('input, textarea, select');
    inputs.forEach((element) => {
      // Skip excluded elements
      if (excludeSelectors.some(selector => element.matches(selector))) {
        return;
      }
      
      const input = element as HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement;
      const name = input.name || input.id || `${input.tagName}_${Array.from(inputs).indexOf(element)}`;
      
      if (input.type === 'checkbox') {
        values.set(name, (input as HTMLInputElement).checked);
      } else if (input.type === 'radio') {
        if ((input as HTMLInputElement).checked) {
          values.set(input.name, input.value);
        }
      } else {
        values.set(name, input.value);
      }
    });
    
    return values;
  }, [excludeSelectors]);

  // Compare current values with initial values
  const checkDirtyState = useCallback(() => {
    if (!isTrackingRef.current) return;
    
    const currentValues = getFormValues();
    let isDirty = false;
    
    // Check if any value has changed
    for (const [key, value] of currentValues.entries()) {
      const initialValue = initialValuesRef.current.get(key);
      if (value !== initialValue) {
        isDirty = true;
        break;
      }
    }
    
    // Check if any initial values are missing (deleted inputs)
    for (const key of initialValuesRef.current.keys()) {
      if (!currentValues.has(key)) {
        isDirty = true;
        break;
      }
    }
    
    const currentState = getTabState(tabId);
    if (currentState.isDirty !== isDirty) {
      setTabDirty(tabId, isDirty);
      onDirtyChange?.(isDirty);
    }
  }, [tabId, setTabDirty, getTabState, onDirtyChange, getFormValues]);

  // Initialize form tracking
  const initializeTracking = useCallback((element: HTMLElement) => {
    formRef.current = element;
    initialValuesRef.current = getFormValues();
    isTrackingRef.current = true;
  }, [getFormValues]);

  // Reset tracking with current values as initial
  const resetTracking = useCallback(() => {
    initialValuesRef.current = getFormValues();
    setTabDirty(tabId, false);
    onDirtyChange?.(false);
  }, [tabId, setTabDirty, onDirtyChange, getFormValues]);

  // Pause tracking temporarily
  const pauseTracking = useCallback(() => {
    isTrackingRef.current = false;
  }, []);

  // Resume tracking
  const resumeTracking = useCallback(() => {
    isTrackingRef.current = true;
  }, []);

  // Set up event listeners
  useEffect(() => {
    if (!formRef.current) return;
    
    const handleChange = (event: Event) => {
      const target = event.target as HTMLElement;
      
      // Skip if target matches excluded selectors
      if (excludeSelectors.some(selector => target.matches(selector))) {
        return;
      }
      
      checkDirtyState();
    };
    
    // Listen to various change events
    const events = ['input', 'change', 'click']; // click for checkboxes/radios
    
    events.forEach(eventType => {
      formRef.current?.addEventListener(eventType, handleChange);
    });
    
    return () => {
      events.forEach(eventType => {
        formRef.current?.removeEventListener(eventType, handleChange);
      });
    };
  }, [checkDirtyState, excludeSelectors]);

  return {
    initializeTracking,
    resetTracking,
    pauseTracking,
    resumeTracking,
    checkDirtyState,
    getFormValues,
  };
};

// Hook for tracking specific form fields
export const useFieldTracker = (fieldName: string, tabId: string) => {
  const { setTabDirty } = useSaveState();
  const initialValueRef = useRef<any>(null);
  const isInitializedRef = useRef(false);

  const trackField = useCallback((value: any) => {
    if (!isInitializedRef.current) {
      initialValueRef.current = value;
      isInitializedRef.current = true;
      return;
    }
    
    const isDirty = value !== initialValueRef.current;
    setTabDirty(tabId, isDirty);
  }, [tabId, setTabDirty]);

  const resetField = useCallback((newInitialValue?: any) => {
    initialValueRef.current = newInitialValue ?? initialValueRef.current;
    setTabDirty(tabId, false);
  }, [tabId, setTabDirty]);

  return { trackField, resetField };
};