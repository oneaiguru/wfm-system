// Demo Plus Estimates Module - Business Value Visualizations
export { default as DemoEstimatesPortal } from './components/DemoEstimatesPortal';

// Dashboard Components
export { default as BusinessMetrics } from './components/dashboard/BusinessMetrics';

// Analysis Components  
export { default as CostComparison } from './components/analysis/CostComparison';
export { default as MarketReadiness } from './components/analysis/MarketReadiness';

// Visualization Components
export { default as EfficiencyGains } from './components/visualizations/EfficiencyGains';
export { default as ForecastAccuracy } from './components/visualizations/ForecastAccuracy';

// ROI Calculator (imported from shared components)
export { default as ROICalculator } from '../../../components/roi/ROICalculator';

// Module exports for easy integration
export * from './components/DemoEstimatesPortal';
export * from './components/dashboard/BusinessMetrics';
export * from './components/analysis/CostComparison';
export * from './components/analysis/MarketReadiness';
export * from './components/visualizations/EfficiencyGains';
export * from './components/visualizations/ForecastAccuracy';