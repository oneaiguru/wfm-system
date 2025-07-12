import React, { useState, useEffect, useRef, useCallback } from 'react';
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, BarElement, Title, Tooltip, Legend, Filler } from 'chart.js';
import { Line, Bar } from 'react-chartjs-2';
import ExcelUploader from '@/components/upload/ExcelUploader';
import PeakAnalysisChart from '@/components/charts/PeakAnalysisChart';
import ForecastChart from '@/components/charts/ForecastChart';
import wfmService from '@/services/wfmService';
import GearMenu from '@/components/common/GearMenu';
import SaveIndicator from '@/components/common/SaveIndicator';
import SaveWarningDialog from '@/components/common/SaveWarningDialog';
import { GearMenuAction } from '@/types/GearMenuTypes';
import { SaveStateProvider, useSaveState, useBeforeUnload } from '@/context/SaveStateContext';
import { useSaveValidation, useSaveShortcut } from '@/hooks/useSaveValidation';
import { useFormTracker } from '@/hooks/useFormTracker';
import { ScheduleGridContainer } from '@/modules/schedule-grid-system';
import { ForecastingAnalytics } from '@/modules/forecasting-analytics';
import { EmployeePortal } from '@/modules/employee-portal';

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, BarElement, Title, Tooltip, Legend, Filler);

interface TabData {
  id: string;
  label: string;
  icon: string;
  description: string;
  requiresSave: boolean;
}

interface WorkflowTabsProps {
  onTabChange?: (tabId: string) => void;
  onDataSave?: (tabId: string, data: any) => void;
}

interface PersonnelCalculation {
  peakRequirement: number;
  averageRequirement: number;
  totalFTE: number;
}

// Inner component that uses the save state context
const WorkflowTabsInner: React.FC<WorkflowTabsProps> = ({ onTabChange, onDataSave }) => {
  const [activeTab, setActiveTab] = useState<string>('historical');
  const [showSaveWarning, setShowSaveWarning] = useState(false);
  const [pendingTabChange, setPendingTabChange] = useState<{ tabId: string; index: number } | null>(null);
  const [uploadedData, setUploadedData] = useState<any>(null);
  const [isCalculating, setIsCalculating] = useState<boolean>(false);
  const [calculationResults, setCalculationResults] = useState<PersonnelCalculation | null>(null);
  const [algorithms, setAlgorithms] = useState<any[]>([]);
  
  const tabContentRef = useRef<HTMLDivElement>(null);
  
  const { getTabState, setTabDirty, setTabSaved } = useSaveState();
  
  // Enable browser warning for unsaved changes
  useBeforeUnload();
  
  const tabs: TabData[] = [
    { id: 'historical', label: 'Historical Data', icon: '📊', description: 'Upload and analyze historical data', requiresSave: false },
    { id: 'peak', label: 'Peak Analysis', icon: '🎯', description: 'Identify peak periods and patterns', requiresSave: true },
    { id: 'seasonality', label: 'Seasonality Config', icon: '🗓️', description: 'Configure seasonal patterns', requiresSave: true },
    { id: 'forecast', label: 'Forecast Results', icon: '📈', description: 'View and adjust forecasts', requiresSave: true },
    { id: 'calculation', label: 'Operator Calculation', icon: '👥', description: 'Calculate required operators', requiresSave: false },
    { id: 'forecasting-analytics', label: 'Forecasting Analytics', icon: '🚀', description: 'Advanced ML forecasting with 85%+ accuracy', requiresSave: true },
    { id: 'employee-portal', label: 'Employee Portal', icon: '👤', description: 'Self-service employee dashboard and tools', requiresSave: true },
    { id: 'schedule', label: 'Schedule Grid', icon: '📅', description: 'Manage employee schedules with drag-drop', requiresSave: true }
  ];

  // Save handlers for each tab
  const saveHandlers: Record<string, (data?: any) => Promise<void>> = {
    historical: async (data) => {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      console.log('Saving historical data:', data || uploadedData);
      onDataSave?.('historical', data || uploadedData);
    },
    peak: async (data) => {
      await new Promise(resolve => setTimeout(resolve, 1000));
      console.log('Saving peak analysis:', data);
      onDataSave?.('peak', data);
    },
    seasonality: async (data) => {
      await new Promise(resolve => setTimeout(resolve, 1000));
      console.log('Saving seasonality config:', data);
      onDataSave?.('seasonality', data);
    },
    forecast: async (data) => {
      await new Promise(resolve => setTimeout(resolve, 1000));
      console.log('Saving forecast results:', data);
      onDataSave?.('forecast', data);
    },
    calculation: async (data) => {
      await new Promise(resolve => setTimeout(resolve, 1000));
      console.log('Saving calculation results:', data);
      onDataSave?.('calculation', data);
    },
    schedule: async (data) => {
      await new Promise(resolve => setTimeout(resolve, 1000));
      console.log('Saving schedule grid:', data);
      onDataSave?.('schedule', data);
    },
    'forecasting-analytics': async (data) => {
      await new Promise(resolve => setTimeout(resolve, 1000));
      console.log('Saving forecasting analytics:', data);
      onDataSave?.('forecasting-analytics', data);
    },
    'employee-portal': async (data) => {
      await new Promise(resolve => setTimeout(resolve, 1000));
      console.log('Saving employee portal:', data);
      onDataSave?.('employee-portal', data);
    },
  };

  // Use save validation hook for current tab
  const { state: saveState, save, markDirty, markClean } = useSaveValidation({
    tabId: activeTab,
    autoSave: false,
    onSave: saveHandlers[activeTab],
    onDirtyStateChange: (isDirty) => {
      setTabDirty(activeTab, isDirty);
    },
  });

  // Form tracking for automatic dirty detection
  const { initializeTracking, resetTracking } = useFormTracker({
    tabId: activeTab,
    onDirtyChange: (isDirty) => {
      if (isDirty) markDirty();
      else markClean();
    },
    excludeSelectors: ['.no-track'], // Exclude elements with this class
  });

  // Initialize form tracking when tab content changes
  useEffect(() => {
    if (tabContentRef.current) {
      initializeTracking(tabContentRef.current);
    }
  }, [activeTab, initializeTracking]);

  // Keyboard shortcut for saving
  const handleSaveShortcut = useCallback(async () => {
    if (tabs.find(t => t.id === activeTab)?.requiresSave && getTabState(activeTab).isDirty) {
      await handleSave();
    }
  }, [activeTab, getTabState]);

  useSaveShortcut(handleSaveShortcut);

  const canNavigateTo = (tabIndex: number): boolean => {
    if (tabIndex === 0) return true;
    const previousTab = tabs[tabIndex - 1];
    const previousTabState = getTabState(previousTab.id);
    return !previousTab.requiresSave || !previousTabState.isDirty;
  };

  const handleTabClick = (tabId: string, index: number) => {
    const currentTabState = getTabState(activeTab);
    
    // If current tab has unsaved changes, show warning
    if (currentTabState.isDirty && tabs.find(t => t.id === activeTab)?.requiresSave) {
      setPendingTabChange({ tabId, index });
      setShowSaveWarning(true);
      return;
    }
    
    // Check if we can navigate based on previous tabs
    if (!canNavigateTo(index)) {
      alert(`Please save data in ${tabs[index - 1].label} tab before proceeding`);
      return;
    }
    
    setActiveTab(tabId);
    onTabChange?.(tabId);
  };

  const handleSave = async () => {
    const success = await save();
    if (success) {
      setTabSaved(activeTab, new Date());
      resetTracking(); // Reset form tracking after save
      
      // Show success notification
      const notification = document.createElement('div');
      notification.className = 'fixed top-4 right-4 bg-green-500 text-white px-4 py-2 rounded-lg shadow-lg z-50 animate-fade-in';
      notification.textContent = 'Changes saved successfully';
      document.body.appendChild(notification);
      
      setTimeout(() => {
        notification.remove();
      }, 3000);
    }
    return success;
  };

  const handleSaveWarningAction = async (action: 'save' | 'discard' | 'cancel') => {
    if (action === 'save') {
      const success = await handleSave();
      if (success && pendingTabChange) {
        setActiveTab(pendingTabChange.tabId);
        onTabChange?.(pendingTabChange.tabId);
      }
    } else if (action === 'discard') {
      markClean();
      setTabDirty(activeTab, false);
      if (pendingTabChange) {
        setActiveTab(pendingTabChange.tabId);
        onTabChange?.(pendingTabChange.tabId);
      }
    }
    
    setShowSaveWarning(false);
    setPendingTabChange(null);
  };

  const handleDataUpload = (data: any) => {
    setUploadedData(data);
    markDirty(); // Mark as dirty when data is uploaded
  };

  const handleGearMenuAction = async (action: GearMenuAction, tabId: string) => {
    console.log(`Gear menu action: ${action} on tab: ${tabId}`);
    
    switch (action) {
      case 'save':
      case 'save_forecast':
      case 'save_results':
        await handleSave();
        break;
        
      case 'import':
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = '.xlsx,.xls,.csv';
        input.onchange = (e) => {
          const file = (e.target as HTMLInputElement).files?.[0];
          if (file) {
            console.log('Importing file:', file.name);
            markDirty(); // Mark as dirty when importing
          }
        };
        input.click();
        break;
        
      case 'export':
      case 'export_chart':
      case 'export_forecast':
        const data = tabId === 'historical' ? uploadedData : {};
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${tabId}_export_${new Date().toISOString()}.json`;
        a.click();
        URL.revokeObjectURL(url);
        break;
        
      case 'clear':
        setUploadedData(null);
        markDirty();
        break;
        
      case 'recalculate':
      case 'recalculate_forecast':
        alert(`Recalculating ${tabId} data...`);
        markDirty(); // Mark as dirty after recalculation
        break;
        
      case 'growth_factor':
        console.log('Growth factor applied');
        markDirty(); // Mark as dirty when growth factor is applied
        break;
        
      default:
        console.warn(`Unhandled gear menu action: ${action}`);
    }
  };

  const handlePersonnelCalculation = async () => {
    setIsCalculating(true);
    try {
      const callVolume = Number((document.getElementById('callVolume') as HTMLInputElement)?.value) || 100;
      const avgHandleTime = Number((document.getElementById('avgHandleTime') as HTMLInputElement)?.value) || 180;
      const serviceLevelTarget = Number((document.getElementById('serviceLevelTarget') as HTMLInputElement)?.value) || 80;
      const shrinkage = Number((document.getElementById('shrinkage') as HTMLInputElement)?.value) || 30;

      const result = await wfmService.calculatePersonnel({
        callVolume,
        avgHandleTime,
        serviceLevelTarget,
        shrinkage
      });

      setCalculationResults(result);
      markDirty(); // Mark as dirty when calculation is performed
    } catch (error) {
      console.error('Calculation failed:', error);
      alert('Failed to calculate personnel requirements. Please try again.');
    } finally {
      setIsCalculating(false);
    }
  };

  // Load available algorithms on mount
  useEffect(() => {
    const loadAlgorithms = async () => {
      try {
        const result = await wfmService.getAvailableAlgorithms();
        setAlgorithms(result.algorithms);
      } catch (error) {
        console.error('Failed to load algorithms:', error);
      }
    };
    loadAlgorithms();
  }, []);

  const renderTabContent = () => {
    const currentTabState = getTabState(activeTab);
    
    switch (activeTab) {
      case 'historical':
        return (
          <div className="space-y-6 relative">
            <div className="absolute top-0 right-0 z-10 flex items-center gap-4">
              <SaveIndicator 
                isDirty={currentTabState.isDirty}
                isSaving={saveState.isSaving}
                lastSavedAt={currentTabState.lastSavedAt}
              />
              <GearMenu tabId="historical" onAction={handleGearMenuAction} />
            </div>
            <ExcelUploader 
              onDataUploaded={handleDataUpload}
              acceptedFormats={['.xlsx', '.xls', '.csv']}
              maxFileSize={10 * 1024 * 1024}
            />
            
            {uploadedData && (
              <div className="bg-white p-6 rounded-lg shadow">
                <h4 className="font-semibold mb-4">Sample Historical Data</h4>
                <div className="h-64">
                  <Line
                    data={{
                      labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                      datasets: [{
                        label: 'Call Volume',
                        data: [1200, 1350, 1100, 1450, 1300, 1500],
                        borderColor: 'rgb(59, 130, 246)',
                        backgroundColor: 'rgba(59, 130, 246, 0.1)',
                        tension: 0.4
                      }]
                    }}
                    options={{
                      responsive: true,
                      maintainAspectRatio: false,
                      plugins: {
                        legend: { position: 'top' as const },
                        title: { display: true, text: 'Historical Call Volume' }
                      }
                    }}
                  />
                </div>
              </div>
            )}
          </div>
        );

      case 'peak':
        return (
          <div className="space-y-6 relative">
            <div className="absolute top-0 right-0 z-10 flex items-center gap-4">
              <SaveIndicator 
                isDirty={currentTabState.isDirty}
                isSaving={saveState.isSaving}
                lastSavedAt={currentTabState.lastSavedAt}
              />
              <GearMenu tabId="peak" onAction={handleGearMenuAction} />
            </div>
            <PeakAnalysisChart 
              data={uploadedData || {}}
              onChartClick={(dataPoint) => {
                console.log('Clicked:', dataPoint);
                markDirty(); // Mark as dirty when chart is interacted with
              }}
            />
            <div className="bg-yellow-50 p-4 rounded-lg">
              <p className="text-sm text-yellow-800">⚠️ Peak analysis requires saved historical data. Make sure to save before proceeding.</p>
            </div>
          </div>
        );

      case 'seasonality':
        return (
          <div className="space-y-6 relative">
            <div className="absolute top-0 right-0 z-10 flex items-center gap-4">
              <SaveIndicator 
                isDirty={currentTabState.isDirty}
                isSaving={saveState.isSaving}
                lastSavedAt={currentTabState.lastSavedAt}
              />
              <GearMenu tabId="seasonality" onAction={handleGearMenuAction} />
            </div>
            <div className="bg-white p-6 rounded-lg shadow">
              <h3 className="text-lg font-semibold mb-4">🗓️ Seasonality Configuration</h3>
              <div className="space-y-4">
                <div className="grid md:grid-cols-2 gap-4">
                  <div className="border rounded-lg p-4">
                    <h4 className="font-medium mb-3">Monthly Patterns</h4>
                    {['January', 'February', 'March', 'April'].map(month => (
                      <label key={month} className="flex items-center space-x-2 mb-2">
                        <input type="checkbox" className="rounded" defaultChecked={month === 'March'} />
                        <span className="text-sm">{month} - High Season</span>
                      </label>
                    ))}
                  </div>
                  <div className="border rounded-lg p-4">
                    <h4 className="font-medium mb-3">Special Events</h4>
                    {['Black Friday', 'Christmas Period', 'Summer Sales', 'Back to School'].map(event => (
                      <label key={event} className="flex items-center space-x-2 mb-2">
                        <input type="checkbox" className="rounded" />
                        <span className="text-sm">{event}</span>
                      </label>
                    ))}
                  </div>
                </div>
                <div className="border rounded-lg p-4">
                  <h4 className="font-medium mb-3">Custom Seasonality Factor</h4>
                  <input 
                    type="range" 
                    min="0.5" 
                    max="2.0" 
                    step="0.1" 
                    defaultValue="1.0" 
                    className="w-full"
                  />
                  <div className="flex justify-between text-sm text-gray-600 mt-1">
                    <span>0.5x</span>
                    <span>1.0x (Normal)</span>
                    <span>2.0x</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        );

      case 'forecast':
        return (
          <div className="space-y-6 relative">
            <div className="absolute top-0 right-0 z-10 flex items-center gap-4">
              <SaveIndicator 
                isDirty={currentTabState.isDirty}
                isSaving={saveState.isSaving}
                lastSavedAt={currentTabState.lastSavedAt}
              />
              <GearMenu tabId="forecast" onAction={handleGearMenuAction} />
            </div>
            <ForecastChart 
              historicalData={uploadedData}
              algorithm="arima"
              showConfidenceIntervals={true}
              enableZoom={true}
            />
          </div>
        );

      case 'calculation':
        return (
          <div className="space-y-6 relative">
            <div className="absolute top-0 right-0 z-10 flex items-center gap-4">
              <SaveIndicator 
                isDirty={currentTabState.isDirty}
                isSaving={saveState.isSaving}
                lastSavedAt={currentTabState.lastSavedAt}
              />
              <GearMenu tabId="calculation" onAction={handleGearMenuAction} />
            </div>
            <div className="bg-white p-6 rounded-lg shadow">
              <h3 className="text-lg font-semibold mb-4">👥 Operator Calculation</h3>
              <div className="grid md:grid-cols-2 gap-6">
                <div className="space-y-4">
                  <div className="border rounded-lg p-4">
                    <h4 className="font-medium mb-2">Input Parameters</h4>
                    <div className="space-y-2">
                      <div className="flex justify-between">
                        <span className="text-sm">Call Volume/Hour:</span>
                        <input 
                          type="number" 
                          id="callVolume"
                          className="border rounded px-2 py-1 w-20 text-sm" 
                          defaultValue="100" 
                        />
                        <span className="text-sm">calls</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-sm">Average Handle Time:</span>
                        <input 
                          type="number" 
                          id="avgHandleTime"
                          className="border rounded px-2 py-1 w-20 text-sm" 
                          defaultValue="180" 
                        />
                        <span className="text-sm">sec</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-sm">Service Level Target:</span>
                        <input 
                          type="number" 
                          id="serviceLevelTarget"
                          className="border rounded px-2 py-1 w-20 text-sm" 
                          defaultValue="80" 
                        />
                        <span className="text-sm">%</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-sm">Shrinkage:</span>
                        <input 
                          type="number" 
                          id="shrinkage"
                          className="border rounded px-2 py-1 w-20 text-sm" 
                          defaultValue="30" 
                        />
                        <span className="text-sm">%</span>
                      </div>
                    </div>
                  </div>
                  
                  <button 
                    onClick={handlePersonnelCalculation}
                    disabled={isCalculating}
                    className="w-full bg-blue-600 text-white py-3 rounded-lg hover:bg-blue-700 transition disabled:opacity-50"
                  >
                    {isCalculating ? 'Calculating...' : 'Calculate Required Operators'}
                  </button>
                </div>
                
                <div className="border rounded-lg p-4">
                  <h4 className="font-medium mb-2">Calculation Results</h4>
                  {calculationResults ? (
                    <div className="space-y-3">
                      <div className="bg-blue-50 p-3 rounded">
                        <p className="text-sm text-gray-600">Peak Hour Requirement</p>
                        <p className="text-2xl font-bold text-blue-600">{calculationResults.peakRequirement} operators</p>
                      </div>
                      <div className="bg-green-50 p-3 rounded">
                        <p className="text-sm text-gray-600">Average Requirement</p>
                        <p className="text-2xl font-bold text-green-600">{calculationResults.averageRequirement} operators</p>
                      </div>
                      <div className="bg-purple-50 p-3 rounded">
                        <p className="text-sm text-gray-600">Total FTE Needed</p>
                        <p className="text-2xl font-bold text-purple-600">{calculationResults.totalFTE} FTE</p>
                      </div>
                    </div>
                  ) : (
                    <div className="text-center text-gray-500 py-8">
                      <p>Enter parameters and click calculate</p>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        );

      case 'forecasting-analytics':
        return (
          <div className="space-y-6 relative h-full">
            <div className="absolute top-0 right-0 z-10 flex items-center gap-4">
              <SaveIndicator 
                isDirty={currentTabState.isDirty}
                isSaving={saveState.isSaving}
                lastSavedAt={currentTabState.lastSavedAt}
              />
              <GearMenu tabId="forecasting-analytics" onAction={handleGearMenuAction} />
            </div>
            <div className="h-[calc(100vh-280px)]">
              <ForecastingAnalytics 
                onDataChange={(data) => markDirty()}
                className="h-full border-0 shadow-none"
              />
            </div>
          </div>
        );

      case 'schedule':
        return (
          <div className="space-y-6 relative h-full">
            <div className="absolute top-0 right-0 z-10 flex items-center gap-4">
              <SaveIndicator 
                isDirty={currentTabState.isDirty}
                isSaving={saveState.isSaving}
                lastSavedAt={currentTabState.lastSavedAt}
              />
              <GearMenu tabId="schedule" onAction={handleGearMenuAction} />
            </div>
            <div className="h-[calc(100vh-280px)]">
              <ScheduleGridContainer />
            </div>
          </div>
        );

      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <SaveWarningDialog
        isOpen={showSaveWarning}
        onSave={async () => await handleSaveWarningAction('save')}
        onDiscard={() => handleSaveWarningAction('discard')}
        onCancel={() => handleSaveWarningAction('cancel')}
        tabName={tabs.find(t => t.id === activeTab)?.label}
        isSaving={saveState.isSaving}
      />
      
      <header className="bg-white border-b border-gray-200 shadow-sm">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <h1 className="text-2xl font-bold text-gray-900">WFM Workflow System</h1>
            <div className="text-sm text-gray-500">
              Press <kbd className="px-1 py-0.5 bg-gray-100 rounded text-xs">Ctrl+S</kbd> to save
            </div>
          </div>
        </div>
      </header>

      <nav className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex space-x-1">
            {tabs.map((tab, index) => {
              const isActive = activeTab === tab.id;
              const canNavigate = canNavigateTo(index);
              const tabState = getTabState(tab.id);
              
              return (
                <button
                  key={tab.id}
                  onClick={() => handleTabClick(tab.id, index)}
                  disabled={!canNavigate && !isActive}
                  className={`
                    relative px-6 py-4 text-sm font-medium transition-all
                    ${isActive 
                      ? 'bg-blue-50 text-blue-600 border-b-2 border-blue-600' 
                      : canNavigate || isActive
                        ? 'text-gray-600 hover:text-gray-800 hover:bg-gray-50'
                        : 'text-gray-400 cursor-not-allowed'
                    }
                  `}
                >
                  <div className="flex items-center gap-2">
                    <span className="text-lg">{tab.icon}</span>
                    <span>{tab.label}</span>
                    {tabState.isDirty && (
                      <span className="text-yellow-600 text-lg leading-none">●</span>
                    )}
                    {!tabState.isDirty && tabState.lastSavedAt && (
                      <svg className="w-4 h-4 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                      </svg>
                    )}
                  </div>
                  {index > 0 && (
                    <div className={`absolute left-0 top-1/2 transform -translate-y-1/2 -translate-x-1/2 text-gray-400`}>
                      →
                    </div>
                  )}
                </button>
              );
            })}
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-4 py-8">
        <div className="mb-6">
          <h2 className="text-xl font-semibold text-gray-900">
            {tabs.find(t => t.id === activeTab)?.label}
          </h2>
          <p className="text-sm text-gray-600 mt-1">
            {tabs.find(t => t.id === activeTab)?.description}
          </p>
        </div>

        <div ref={tabContentRef}>
          {renderTabContent()}
        </div>

        {tabs.find(t => t.id === activeTab)?.requiresSave && getTabState(activeTab).isDirty && (
          <div className="mt-8 flex justify-end">
            <button
              onClick={handleSave}
              disabled={saveState.isSaving}
              className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition disabled:opacity-50 flex items-center gap-2"
            >
              {saveState.isSaving ? (
                <>
                  <svg className="animate-spin h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"/>
                  </svg>
                  <span>Saving...</span>
                </>
              ) : (
                'Save & Continue'
              )}
            </button>
          </div>
        )}
      </main>

      <footer className="bg-gray-100 mt-12 py-6">
        <div className="max-w-7xl mx-auto px-4 text-center text-sm text-gray-600">
          <p>WFM Enterprise System • Save Validation Enabled</p>
          <div className="mt-2 flex items-center justify-center gap-4">
            <button
              onClick={async () => {
                try {
                  const status = await wfmService.testIntegration();
                  console.log('Integration test:', status);
                  alert(`Integration Status: ${status.status}\n\nAlgorithms: ${Object.entries(status.modules_status || {}).map(([k, v]) => `\n${k}: ${v}`).join('')}`);
                } catch (error) {
                  alert('Integration test failed');
                }
              }}
              className="text-xs text-blue-600 hover:text-blue-800"
            >
              Test API Integration
            </button>
            {algorithms.length > 0 && (
              <span className="text-xs text-green-600">
                ✓ {algorithms.length} algorithms loaded
              </span>
            )}
          </div>
        </div>
      </footer>
    </div>
  );
};

// Wrapper component that provides the SaveStateProvider
const EnhancedWorkflowTabs: React.FC<WorkflowTabsProps> = (props) => {
  return (
    <SaveStateProvider>
      <WorkflowTabsInner {...props} />
    </SaveStateProvider>
  );
};

export default EnhancedWorkflowTabs;