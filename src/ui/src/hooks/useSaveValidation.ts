import { useState, useEffect, useCallback, useRef } from 'react';

export interface SaveValidationState {
  isDirty: boolean;
  isSaving: boolean;
  lastSavedAt?: Date;
  hasError: boolean;
  errorMessage?: string;
}

export interface UseSaveValidationOptions {
  tabId: string;
  autoSave?: boolean;
  autoSaveDelay?: number;
  onSave?: (data: any) => Promise<void>;
  onDirtyStateChange?: (isDirty: boolean) => void;
}

export interface UseSaveValidationReturn {
  state: SaveValidationState;
  markDirty: () => void;
  markClean: () => void;
  save: (data?: any) => Promise<boolean>;
  canNavigateAway: () => boolean;
  resetState: () => void;
}

export const useSaveValidation = (options: UseSaveValidationOptions): UseSaveValidationReturn => {
  const { tabId, autoSave = false, autoSaveDelay = 5000, onSave, onDirtyStateChange } = options;
  
  const [state, setState] = useState<SaveValidationState>({
    isDirty: false,
    isSaving: false,
    hasError: false,
  });
  
  const autoSaveTimerRef = useRef<NodeJS.Timeout | null>(null);
  const currentDataRef = useRef<any>(null);
  
  // Track dirty state changes
  useEffect(() => {
    onDirtyStateChange?.(state.isDirty);
  }, [state.isDirty, onDirtyStateChange]);
  
  // Clear auto-save timer on unmount
  useEffect(() => {
    return () => {
      if (autoSaveTimerRef.current) {
        clearTimeout(autoSaveTimerRef.current);
      }
    };
  }, []);
  
  const markDirty = useCallback(() => {
    setState(prev => ({ ...prev, isDirty: true, hasError: false }));
    
    // Set up auto-save if enabled
    if (autoSave && onSave) {
      if (autoSaveTimerRef.current) {
        clearTimeout(autoSaveTimerRef.current);
      }
      
      autoSaveTimerRef.current = setTimeout(async () => {
        await save(currentDataRef.current);
      }, autoSaveDelay);
    }
  }, [autoSave, autoSaveDelay, onSave]);
  
  const markClean = useCallback(() => {
    setState(prev => ({ ...prev, isDirty: false }));
    
    // Clear auto-save timer
    if (autoSaveTimerRef.current) {
      clearTimeout(autoSaveTimerRef.current);
      autoSaveTimerRef.current = null;
    }
  }, []);
  
  const save = useCallback(async (data?: any): Promise<boolean> => {
    if (!onSave) {
      console.warn(`No save handler provided for tab: ${tabId}`);
      return true;
    }
    
    setState(prev => ({ ...prev, isSaving: true, hasError: false, errorMessage: undefined }));
    
    try {
      await onSave(data || currentDataRef.current);
      setState(prev => ({
        ...prev,
        isDirty: false,
        isSaving: false,
        lastSavedAt: new Date(),
        hasError: false,
      }));
      
      // Clear auto-save timer after successful save
      if (autoSaveTimerRef.current) {
        clearTimeout(autoSaveTimerRef.current);
        autoSaveTimerRef.current = null;
      }
      
      return true;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to save data';
      setState(prev => ({
        ...prev,
        isSaving: false,
        hasError: true,
        errorMessage,
      }));
      console.error(`Save failed for tab ${tabId}:`, error);
      return false;
    }
  }, [tabId, onSave]);
  
  const canNavigateAway = useCallback(() => {
    return !state.isDirty || state.isSaving;
  }, [state.isDirty, state.isSaving]);
  
  const resetState = useCallback(() => {
    setState({
      isDirty: false,
      isSaving: false,
      hasError: false,
    });
    currentDataRef.current = null;
    
    if (autoSaveTimerRef.current) {
      clearTimeout(autoSaveTimerRef.current);
      autoSaveTimerRef.current = null;
    }
  }, []);
  
  // Update current data reference
  const updateData = useCallback((data: any) => {
    currentDataRef.current = data;
  }, []);
  
  return {
    state,
    markDirty,
    markClean,
    save,
    canNavigateAway,
    resetState,
    updateData,
  } as UseSaveValidationReturn & { updateData: (data: any) => void };
};

// Custom hook for keyboard shortcuts
export const useSaveShortcut = (saveHandler: () => void | Promise<void>) => {
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      // Ctrl+S or Cmd+S
      if ((event.ctrlKey || event.metaKey) && event.key === 's') {
        event.preventDefault();
        saveHandler();
      }
    };
    
    window.addEventListener('keydown', handleKeyDown);
    
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [saveHandler]);
};