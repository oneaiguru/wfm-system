// Gear Menu Types for WFM Workflow System
export type GearMenuAction = 
  // Historical Data tab actions
  | 'import'
  | 'export'
  | 'clear'
  | 'request_data'
  // Peak Analysis tab actions
  | 'save'
  | 'recalculate'
  | 'export_chart'
  | 'smooth_outliers'
  // Seasonality tab actions
  | 'save_templates'
  | 'import_templates'
  | 'reset'
  | 'apply_pattern'
  // Forecast tab actions
  | 'save_forecast'
  | 'export_forecast'
  | 'growth_factor'
  | 'recalculate_forecast'
  | 'compare_models'
  // Calculation tab actions
  | 'save_results'
  | 'export_excel'
  | 'print'
  | 'apply_coefficients';

export interface GearMenuItem {
  id: GearMenuAction;
  label: string;
  icon?: string;
  shortcut?: string;
  divider?: boolean;
  disabled?: boolean;
  tooltip?: string;
  requiresConfirmation?: boolean;
  confirmationMessage?: string;
}

export interface GearMenuConfig {
  tabId: string;
  items: GearMenuItem[];
}

export interface GearMenuProps {
  tabId: string;
  onAction: (action: GearMenuAction, tabId: string) => void | Promise<void>;
  isOpen?: boolean;
  onClose?: () => void;
  position?: 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left';
  className?: string;
}

export interface GrowthFactorConfig {
  period: {
    start: Date;
    end: Date;
  };
  growthFactor: number;
  applyTo: 'call_volume' | 'both';
  maintainAHT: boolean;
}

export interface GearMenuActionResult {
  success: boolean;
  message?: string;
  data?: any;
}

export interface TabGearMenuConfig {
  [tabId: string]: GearMenuItem[];
}

// Export configuration for gear menu items by tab
export const GEAR_MENU_CONFIGS: TabGearMenuConfig = {
  historical: [
    { id: 'import', label: 'Import', icon: '📥', shortcut: 'Ctrl+I', tooltip: 'Import data from Excel/CSV file' },
    { id: 'request_data', label: 'Request Data', icon: '🔄', tooltip: 'Request data from integration system' },
    { id: 'export', label: 'Export', icon: '📤', shortcut: 'Ctrl+E', tooltip: 'Export current data' },
    { id: 'clear', label: 'Clear Data', icon: '🗑️', requiresConfirmation: true, confirmationMessage: 'Are you sure you want to clear all historical data?' }
  ],
  peak: [
    { id: 'save', label: 'Save', icon: '💾', shortcut: 'Ctrl+S', tooltip: 'Save peak analysis results' },
    { id: 'smooth_outliers', label: 'Smooth Outliers', icon: '📊', tooltip: 'Apply outlier smoothing using IQR method' },
    { id: 'recalculate', label: 'Recalculate', icon: '🔄', tooltip: 'Recalculate peak analysis' },
    { id: 'export_chart', label: 'Export Chart', icon: '📸', tooltip: 'Export chart as image' }
  ],
  seasonality: [
    { id: 'save', label: 'Save', icon: '💾', shortcut: 'Ctrl+S', tooltip: 'Save seasonality configuration' },
    { id: 'save_templates', label: 'Save Templates', icon: '📋', tooltip: 'Save current settings as template' },
    { id: 'import_templates', label: 'Import Templates', icon: '📥', tooltip: 'Import seasonality templates' },
    { id: 'apply_pattern', label: 'Apply Pattern', icon: '🎯', tooltip: 'Apply predefined seasonal pattern' },
    { id: 'reset', label: 'Reset', icon: '↩️', requiresConfirmation: true, confirmationMessage: 'Reset all seasonality settings to defaults?' }
  ],
  forecast: [
    { id: 'save_forecast', label: 'Save', icon: '💾', shortcut: 'Ctrl+S', tooltip: 'Save forecast results' },
    { id: 'growth_factor', label: 'Growth Factor', icon: '📈', tooltip: 'Apply growth factor to scale volumes (e.g., 1,000 → 5,000 calls)' },
    { id: 'recalculate_forecast', label: 'Recalculate', icon: '🔄', tooltip: 'Recalculate forecast with current parameters' },
    { id: 'compare_models', label: 'Compare Models', icon: '📊', tooltip: 'Compare different forecasting models' },
    { id: 'export_forecast', label: 'Export', icon: '📤', tooltip: 'Export forecast data' }
  ],
  calculation: [
    { id: 'save_results', label: 'Save Results', icon: '💾', tooltip: 'Save operator calculation results' },
    { id: 'export_excel', label: 'Export to Excel', icon: '📊', tooltip: 'Export results to Excel format' },
    { id: 'apply_coefficients', label: 'Apply Coefficients', icon: '🔢', tooltip: 'Apply adjustment coefficients' },
    { id: 'print', label: 'Print', icon: '🖨️', shortcut: 'Ctrl+P', tooltip: 'Print calculation results' }
  ]
};