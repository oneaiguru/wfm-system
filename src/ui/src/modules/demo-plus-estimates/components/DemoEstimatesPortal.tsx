import React, { useState } from 'react';
import { Calculator, TrendingUp, DollarSign, Target, Award, BarChart3, PieChart, AlertCircle } from 'lucide-react';
import ROICalculator from '../../../components/roi/ROICalculator';
import CostComparison from './analysis/CostComparison';
import EfficiencyGains from './visualizations/EfficiencyGains';
import BusinessMetrics from './dashboard/BusinessMetrics';
import MarketReadiness from './analysis/MarketReadiness';
import ForecastAccuracy from './visualizations/ForecastAccuracy';

interface DemoEstimatesPortalProps {
  currentView?: string;
  onViewChange?: (view: string) => void;
}

const DemoEstimatesPortal: React.FC<DemoEstimatesPortalProps> = ({ 
  currentView = 'dashboard',
  onViewChange 
}) => {
  const [selectedTimeframe, setSelectedTimeframe] = useState<'year1' | 'year3' | 'year5'>('year1');

  const navigationItems = [
    { id: 'dashboard', label: 'Executive Summary', icon: BarChart3 },
    { id: 'roi', label: 'ROI Calculator', icon: Calculator },
    { id: 'cost', label: 'Cost Analysis', icon: DollarSign },
    { id: 'efficiency', label: 'Efficiency Gains', icon: TrendingUp },
    { id: 'forecast', label: 'Forecast Accuracy', icon: Target },
    { id: 'market', label: 'Market Readiness', icon: Award },
  ];

  const renderContent = () => {
    switch (currentView) {
      case 'dashboard':
        return <BusinessMetrics timeframe={selectedTimeframe} />;
      case 'roi':
        return <ROICalculator />;
      case 'cost':
        return <CostComparison />;
      case 'efficiency':
        return <EfficiencyGains />;
      case 'forecast':
        return <ForecastAccuracy />;
      case 'market':
        return <MarketReadiness />;
      default:
        return <BusinessMetrics timeframe={selectedTimeframe} />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-2xl font-bold text-gray-900">
                WFM Business Value Calculator
              </h1>
              <div className="ml-8 flex items-center space-x-2 text-sm">
                <AlertCircle className="h-4 w-4 text-green-600" />
                <span className="text-green-600 font-medium">Live Demo</span>
              </div>
            </div>
            
            {/* Timeframe Selector */}
            <div className="flex items-center space-x-2">
              <span className="text-sm text-gray-600">Timeframe:</span>
              <select
                value={selectedTimeframe}
                onChange={(e) => setSelectedTimeframe(e.target.value as any)}
                className="px-3 py-1 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="year1">Year 1</option>
                <option value="year3">3 Years</option>
                <option value="year5">5 Years</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <div className="flex h-[calc(100vh-4rem)]">
        {/* Sidebar Navigation */}
        <div className="w-64 bg-white shadow-md">
          <nav className="mt-5 px-2">
            {navigationItems.map((item) => {
              const Icon = item.icon;
              const isActive = currentView === item.id;
              
              return (
                <button
                  key={item.id}
                  onClick={() => onViewChange?.(item.id)}
                  className={`
                    w-full group flex items-center px-2 py-2 text-sm font-medium rounded-md mb-1
                    ${isActive 
                      ? 'bg-blue-100 text-blue-900' 
                      : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                    }
                  `}
                >
                  <Icon className={`
                    mr-3 h-5 w-5
                    ${isActive ? 'text-blue-600' : 'text-gray-400 group-hover:text-gray-500'}
                  `} />
                  {item.label}
                </button>
              );
            })}
          </nav>

          {/* Key Metrics Summary */}
          <div className="mt-8 px-4">
            <div className="bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg p-4 text-white">
              <h3 className="text-sm font-semibold mb-3">Key Highlights</h3>
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-xs">vs Argus</span>
                  <span className="text-lg font-bold">$3.8M</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs">ROI Year 1</span>
                  <span className="text-lg font-bold">320%</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs">Accuracy</span>
                  <span className="text-lg font-bold">85%+</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs">Payback</span>
                  <span className="text-lg font-bold">3.8 mo</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="flex-1 overflow-y-auto">
          <div className="p-6">
            {renderContent()}
          </div>
        </div>
      </div>
    </div>
  );
};

export default DemoEstimatesPortal;