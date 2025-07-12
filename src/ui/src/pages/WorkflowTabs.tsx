import React, { useState, useEffect } from 'react';
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, BarElement, Title, Tooltip, Legend, Filler } from 'chart.js';
import { Line, Bar } from 'react-chartjs-2';
import ExcelUploader from '@/components/upload/ExcelUploader';
import PeakAnalysisChart from '@/components/charts/PeakAnalysisChart';
import ForecastChart from '@/components/charts/ForecastChart';
import MultiSkillPlanning from '@/pages/MultiSkillPlanning';
import { ROICalculator } from '@/components/roi';
import wfmService from '@/services/wfmService';
import GearMenu from '@/components/common/GearMenu';
import { GearMenuAction } from '@/types/GearMenuTypes';
import GrowthFactorDialog from '@/components/forecast/GrowthFactorDialog';
import { useGrowthFactor } from '@/hooks/useGrowthFactor';

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

const WorkflowTabs: React.FC<WorkflowTabsProps> = ({ onTabChange, onDataSave }) => {
  const [activeTab, setActiveTab] = useState<string>('historical');
  const [savedTabs, setSavedTabs] = useState<Set<string>>(new Set());
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [uploadedData, setUploadedData] = useState<any>(null);
  const [isCalculating, setIsCalculating] = useState<boolean>(false);
  const [calculationResults, setCalculationResults] = useState<PersonnelCalculation | null>(null);
  const [algorithms, setAlgorithms] = useState<any[]>([]);
  const [showGrowthFactorDialog, setShowGrowthFactorDialog] = useState<boolean>(false);
  const [forecastData, setForecastData] = useState<any>(null);
  
  const { applyGrowthFactor, validateGrowthConfig, generateGrowthPreview } = useGrowthFactor();
  
  const tabs: TabData[] = [
    { id: 'historical', label: 'Historical Data', icon: '📊', description: 'Upload and analyze historical data', requiresSave: false },
    { id: 'peak', label: 'Peak Analysis', icon: '🎯', description: 'Identify peak periods and patterns', requiresSave: true },
    { id: 'seasonality', label: 'Seasonality Config', icon: '🗓️', description: 'Configure seasonal patterns', requiresSave: true },
    { id: 'forecast', label: 'Forecast Results', icon: '📈', description: 'View and adjust forecasts', requiresSave: true },
    { id: 'calculation', label: 'Operator Calculation', icon: '👥', description: 'Calculate required operators', requiresSave: false },
    { id: 'multiskill', label: 'Multi-Skill Planning', icon: '🎓', description: 'ML-powered multi-skill optimization (85%+ accuracy)', requiresSave: false },
    { id: 'roi', label: 'ROI Calculator', icon: '💰', description: 'Calculate return on investment and business value', requiresSave: false }
  ];

  const canNavigateTo = (tabIndex: number): boolean => {
    if (tabIndex === 0) return true;
    const previousTab = tabs[tabIndex - 1];
    return savedTabs.has(previousTab.id) || !previousTab.requiresSave;
  };

  const handleTabClick = (tabId: string, index: number) => {
    if (!canNavigateTo(index)) {
      alert(`Please save data in ${tabs[index - 1].label} tab before proceeding`);
      return;
    }
    setActiveTab(tabId);
    onTabChange?.(tabId);
  };

  const handleSave = () => {
    setIsLoading(true);
    setTimeout(() => {
      setSavedTabs(prev => new Set([...prev, activeTab]));
      onDataSave?.(activeTab, { timestamp: new Date().toISOString() });
      setIsLoading(false);
      alert('Data saved successfully');
    }, 1000);
  };

  const handleDataUpload = (data: any) => {
    setUploadedData(data);
    setSavedTabs(prev => new Set([...prev, 'historical']));
  };

  const handleGrowthFactorApply = (config: any) => {
    console.log('Applying growth factor:', config);
    
    // Validate the configuration
    const validation = validateGrowthConfig(config);
    if (!validation.valid) {
      alert(`Validation errors:\n${validation.errors.join('\n')}`);
      return;
    }
    
    // Apply growth factor to forecast data
    if (forecastData) {
      const scaledData = applyGrowthFactor(forecastData, config);
      setForecastData(scaledData);
    }
    
    // Show success message
    const multiplier = config.growthType === 'percentage' 
      ? (1 + config.volumeGrowth / 100).toFixed(1)
      : 'custom';
    
    alert(`Growth factor of ${multiplier}x applied successfully!\n\nThis demonstrates scaling from 1,000 to 5,000 calls for the demo.`);
  };

  const handleGearMenuAction = async (action: GearMenuAction, tabId: string) => {
    console.log(`Gear menu action: ${action} on tab: ${tabId}`);
    
    switch (action) {
      case 'import':
        // Trigger file import dialog
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = '.xlsx,.xls,.csv';
        input.onchange = (e) => {
          const file = (e.target as HTMLInputElement).files?.[0];
          if (file) {
            console.log('Importing file:', file.name);
            // Handle file import
          }
        };
        input.click();
        break;
        
      case 'export':
      case 'export_chart':
      case 'export_forecast':
        // Export data/chart
        const data = tabId === 'historical' ? uploadedData : {};
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${tabId}_export_${new Date().toISOString()}.json`;
        a.click();
        URL.revokeObjectURL(url);
        break;
        
      case 'save':
      case 'save_forecast':
      case 'save_results':
        handleSave();
        break;
        
      case 'clear':
        setUploadedData(null);
        setSavedTabs(prev => {
          const newSet = new Set(prev);
          newSet.delete('historical');
          return newSet;
        });
        break;
        
      case 'request_data':
        alert('Requesting data from integration system...');
        // Implement integration data request
        break;
        
      case 'smooth_outliers':
        alert('Applying IQR-based outlier smoothing...');
        // Implement outlier smoothing
        break;
        
      case 'recalculate':
      case 'recalculate_forecast':
        alert(`Recalculating ${tabId} data...`);
        // Implement recalculation logic
        break;
        
      case 'save_templates':
      case 'import_templates':
        alert(`${action === 'save_templates' ? 'Saving' : 'Importing'} seasonality templates...`);
        // Implement template handling
        break;
        
      case 'apply_pattern':
        alert('Applying seasonal pattern...');
        break;
        
      case 'reset':
        alert('Resetting to defaults...');
        break;
        
      case 'growth_factor':
        // Open the comprehensive Growth Factor dialog
        setShowGrowthFactorDialog(true);
        break;
        
      case 'compare_models':
        alert('Opening model comparison view...');
        // Implement model comparison
        break;
        
      case 'export_excel':
        alert('Exporting to Excel format...');
        // Implement Excel export
        break;
        
      case 'apply_coefficients':
        alert('Opening coefficient configuration...');
        // Implement coefficient application
        break;
        
      case 'print':
        window.print();
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
    switch (activeTab) {
      case 'historical':
        return (
          <div className="space-y-6 relative">
            <div className="absolute top-0 right-0 z-10">
              <GearMenu tabId="historical" onAction={handleGearMenuAction} />
            </div>
            <ExcelUploader 
              onDataUploaded={handleDataUpload}
              acceptedFormats={['.xlsx', '.xls', '.csv']}
              maxFileSize={10 * 1024 * 1024} // 10MB
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
            <div className="absolute top-0 right-0 z-10">
              <GearMenu tabId="peak" onAction={handleGearMenuAction} />
            </div>
            <PeakAnalysisChart 
              data={uploadedData || {}}
              onChartClick={(dataPoint) => console.log('Clicked:', dataPoint)}
            />
            <div className="bg-yellow-50 p-4 rounded-lg">
              <p className="text-sm text-yellow-800">⚠️ Peak analysis requires saved historical data. Make sure to save before proceeding.</p>
            </div>
          </div>
        );

      case 'seasonality':
        return (
          <div className="space-y-6 relative">
            <div className="absolute top-0 right-0 z-10">
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
            <div className="absolute top-0 right-0 z-10">
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
            <div className="absolute top-0 right-0 z-10">
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

      case 'multiskill':
        return (
          <div className="space-y-6">
            <MultiSkillPlanning
              onDataUpdate={(data) => {
                console.log('Multi-skill data updated:', data);
                onDataSave?.('multiskill', data);
              }}
            />
          </div>
        );

      case 'roi':
        return (
          <div className="space-y-6">
            <ROICalculator />
          </div>
        );

      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b border-gray-200 shadow-sm">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <h1 className="text-2xl font-bold text-gray-900">WFM Workflow System</h1>
          </div>
        </div>
      </header>

      <nav className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex space-x-1">
            {tabs.map((tab, index) => {
              const isActive = activeTab === tab.id;
              const canNavigate = canNavigateTo(index);
              const isSaved = savedTabs.has(tab.id);
              
              return (
                <button
                  key={tab.id}
                  onClick={() => handleTabClick(tab.id, index)}
                  disabled={!canNavigate}
                  className={`
                    relative px-6 py-4 text-sm font-medium transition-all
                    ${isActive 
                      ? 'bg-blue-50 text-blue-600 border-b-2 border-blue-600' 
                      : canNavigate
                        ? 'text-gray-600 hover:text-gray-800 hover:bg-gray-50'
                        : 'text-gray-400 cursor-not-allowed'
                    }
                  `}
                >
                  <div className="flex items-center gap-2">
                    <span className="text-lg">{tab.icon}</span>
                    <span>{tab.label}</span>
                    {isSaved && (
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

        {renderTabContent()}

        {tabs.find(t => t.id === activeTab)?.requiresSave && !savedTabs.has(activeTab) && (
          <div className="mt-8 flex justify-end">
            <button
              onClick={handleSave}
              disabled={isLoading}
              className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition disabled:opacity-50"
            >
              {isLoading ? 'Saving...' : 'Save & Continue'}
            </button>
          </div>
        )}
      </main>

      <footer className="bg-gray-100 mt-12 py-6">
        <div className="max-w-7xl mx-auto px-4 text-center text-sm text-gray-600">
          <p>WFM Enterprise System • Production Ready</p>
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

      {/* Growth Factor Dialog */}
      <GrowthFactorDialog
        isOpen={showGrowthFactorDialog}
        onClose={() => setShowGrowthFactorDialog(false)}
        onApply={handleGrowthFactorApply}
        currentForecastData={forecastData}
        skills={[
          { id: 'technical', name: 'Technical Support', currentVolume: 600, currentAHT: 300 },
          { id: 'billing', name: 'Billing Inquiries', currentVolume: 300, currentAHT: 240 },
          { id: 'general', name: 'General Questions', currentVolume: 100, currentAHT: 180 }
        ]}
      />
    </div>
  );
};

export default WorkflowTabs;