import React, { createContext, useContext, useState, useCallback, ReactNode } from 'react';

export interface TabSaveState {
  isDirty: boolean;
  lastSavedAt?: Date;
  data?: any;
}

export interface SaveStateContextType {
  tabStates: Record<string, TabSaveState>;
  setTabDirty: (tabId: string, isDirty: boolean) => void;
  setTabData: (tabId: string, data: any) => void;
  setTabSaved: (tabId: string, savedAt: Date) => void;
  getTabState: (tabId: string) => TabSaveState;
  isAnyTabDirty: () => boolean;
  getDirtyTabs: () => string[];
  clearTabState: (tabId: string) => void;
  clearAllStates: () => void;
}

const SaveStateContext = createContext<SaveStateContextType | undefined>(undefined);

export const SaveStateProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [tabStates, setTabStates] = useState<Record<string, TabSaveState>>({});

  const setTabDirty = useCallback((tabId: string, isDirty: boolean) => {
    setTabStates(prev => ({
      ...prev,
      [tabId]: {
        ...prev[tabId],
        isDirty,
      },
    }));
  }, []);

  const setTabData = useCallback((tabId: string, data: any) => {
    setTabStates(prev => ({
      ...prev,
      [tabId]: {
        ...prev[tabId],
        data,
        isDirty: true, // Setting data marks tab as dirty
      },
    }));
  }, []);

  const setTabSaved = useCallback((tabId: string, savedAt: Date) => {
    setTabStates(prev => ({
      ...prev,
      [tabId]: {
        ...prev[tabId],
        isDirty: false,
        lastSavedAt: savedAt,
      },
    }));
  }, []);

  const getTabState = useCallback((tabId: string): TabSaveState => {
    return tabStates[tabId] || { isDirty: false };
  }, [tabStates]);

  const isAnyTabDirty = useCallback((): boolean => {
    return Object.values(tabStates).some(state => state.isDirty);
  }, [tabStates]);

  const getDirtyTabs = useCallback((): string[] => {
    return Object.entries(tabStates)
      .filter(([_, state]) => state.isDirty)
      .map(([tabId]) => tabId);
  }, [tabStates]);

  const clearTabState = useCallback((tabId: string) => {
    setTabStates(prev => {
      const newStates = { ...prev };
      delete newStates[tabId];
      return newStates;
    });
  }, []);

  const clearAllStates = useCallback(() => {
    setTabStates({});
  }, []);

  const value: SaveStateContextType = {
    tabStates,
    setTabDirty,
    setTabData,
    setTabSaved,
    getTabState,
    isAnyTabDirty,
    getDirtyTabs,
    clearTabState,
    clearAllStates,
  };

  return (
    <SaveStateContext.Provider value={value}>
      {children}
    </SaveStateContext.Provider>
  );
};

export const useSaveState = (): SaveStateContextType => {
  const context = useContext(SaveStateContext);
  if (!context) {
    throw new Error('useSaveState must be used within a SaveStateProvider');
  }
  return context;
};

// Hook for checking if user is trying to leave with unsaved changes
export const useBeforeUnload = () => {
  const { isAnyTabDirty } = useSaveState();

  React.useEffect(() => {
    const handleBeforeUnload = (event: BeforeUnloadEvent) => {
      if (isAnyTabDirty()) {
        event.preventDefault();
        event.returnValue = 'You have unsaved changes. Are you sure you want to leave?';
        return event.returnValue;
      }
    };

    window.addEventListener('beforeunload', handleBeforeUnload);

    return () => {
      window.removeEventListener('beforeunload', handleBeforeUnload);
    };
  }, [isAnyTabDirty]);
};

// Hook for showing save indicators
export const useSaveIndicator = (tabId: string) => {
  const { getTabState } = useSaveState();
  const state = getTabState(tabId);

  const getIndicatorProps = () => {
    if (state.isDirty) {
      return {
        show: true,
        color: 'text-yellow-600',
        icon: '●', // Unsaved indicator
        tooltip: 'Unsaved changes',
      };
    }
    
    if (state.lastSavedAt) {
      const timeSinceSave = Date.now() - state.lastSavedAt.getTime();
      const showRecentlySaved = timeSinceSave < 3000; // Show for 3 seconds
      
      if (showRecentlySaved) {
        return {
          show: true,
          color: 'text-green-600',
          icon: '✓',
          tooltip: 'Saved',
        };
      }
    }
    
    return { show: false };
  };

  return getIndicatorProps();
};