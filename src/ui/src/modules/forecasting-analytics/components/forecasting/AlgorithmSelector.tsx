import React, { useState } from 'react';
import { Settings, TrendingUp, BarChart3, Activity, CheckCircle2 } from 'lucide-react';

interface Algorithm {
  id: string;
  name: string;
  description: string;
  accuracy: number;
  processingTime: string;
  complexity: 'Low' | 'Medium' | 'High';
  parameters: { [key: string]: any };
  strengths: string[];
  limitations: string[];
}

interface AlgorithmSelectorProps {
  selectedAlgorithm: string;
  onAlgorithmChange: (algorithmId: string, parameters?: any) => void;
  onParameterChange?: (algorithmId: string, parameters: any) => void;
  isCalculating?: boolean;
  className?: string;
}

const AlgorithmSelector: React.FC<AlgorithmSelectorProps> = ({
  selectedAlgorithm,
  onAlgorithmChange,
  onParameterChange,
  isCalculating = false,
  className = ''
}) => {
  const [showParameters, setShowParameters] = useState(false);
  const [expandedAlgorithm, setExpandedAlgorithm] = useState<string | null>(null);

  const algorithms: Algorithm[] = [
    {
      id: 'enhanced-arima',
      name: 'Enhanced ARIMA',
      description: 'Advanced Auto-Regressive Integrated Moving Average with seasonal components',
      accuracy: 91.5,
      processingTime: '2.3s',
      complexity: 'High',
      parameters: {
        p: 2,
        d: 1,
        q: 2,
        seasonal_p: 1,
        seasonal_d: 1,
        seasonal_q: 1,
        seasonal_periods: 24
      },
      strengths: ['Handles seasonality well', 'High accuracy', 'Statistical foundation'],
      limitations: ['Requires stationary data', 'Complex parameter tuning']
    },
    {
      id: 'ml-ensemble',
      name: 'ML Ensemble',
      description: 'Machine Learning ensemble combining multiple prediction models',
      accuracy: 89.2,
      processingTime: '1.8s',
      complexity: 'High',
      parameters: {
        models: ['random_forest', 'gradient_boost', 'neural_network'],
        feature_engineering: true,
        cross_validation: 5,
        ensemble_method: 'weighted_average'
      },
      strengths: ['Robust predictions', 'Handles complex patterns', 'Feature engineering'],
      limitations: ['Requires large datasets', 'Black box model']
    },
    {
      id: 'linear-regression',
      name: 'Linear Regression',
      description: 'Enhanced linear regression with trend and seasonal components',
      accuracy: 78.8,
      processingTime: '0.5s',
      complexity: 'Low',
      parameters: {
        trend: true,
        seasonal: true,
        confidence_interval: 0.95,
        regularization: 'ridge'
      },
      strengths: ['Fast computation', 'Interpretable', 'Stable results'],
      limitations: ['Linear assumptions', 'Limited complexity handling']
    },
    {
      id: 'seasonal-naive',
      name: 'Seasonal Naive',
      description: 'Simple baseline model using historical seasonal patterns',
      accuracy: 76.3,
      processingTime: '0.1s',
      complexity: 'Low',
      parameters: {
        seasonal_periods: 24,
        smoothing: false
      },
      strengths: ['Very fast', 'Simple baseline', 'No training required'],
      limitations: ['Limited accuracy', 'No trend handling']
    }
  ];

  const selectedAlgo = algorithms.find(algo => algo.id === selectedAlgorithm) || algorithms[0];

  const getComplexityColor = (complexity: string) => {
    switch (complexity) {
      case 'Low': return 'text-green-600 bg-green-100';
      case 'Medium': return 'text-yellow-600 bg-yellow-100';
      case 'High': return 'text-red-600 bg-red-100';
      default: return 'text-gray-600 bg-gray-100';
    }
  };

  const getAccuracyColor = (accuracy: number) => {
    if (accuracy >= 90) return 'text-green-600';
    if (accuracy >= 80) return 'text-yellow-600';
    return 'text-red-600';
  };

  return (
    <div className={`bg-white rounded-lg shadow ${className}`}>
      {/* Header */}
      <div className="border-b border-gray-200 p-4">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
            <Settings className="w-5 h-5 text-blue-600" />
            Algorithm Selection
          </h3>
          <button
            onClick={() => setShowParameters(!showParameters)}
            className="text-sm text-blue-600 hover:text-blue-800 flex items-center gap-1"
          >
            <BarChart3 className="w-4 h-4" />
            {showParameters ? 'Hide' : 'Show'} Parameters
          </button>
        </div>
      </div>

      {/* Algorithm Grid */}
      <div className="p-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {algorithms.map(algorithm => (
            <div
              key={algorithm.id}
              className={`border rounded-lg p-4 cursor-pointer transition-all ${
                selectedAlgorithm === algorithm.id
                  ? 'border-blue-500 bg-blue-50 shadow-md'
                  : 'border-gray-200 hover:border-gray-300 hover:shadow-sm'
              }`}
              onClick={() => onAlgorithmChange(algorithm.id, algorithm.parameters)}
            >
              {/* Algorithm Header */}
              <div className="flex items-start justify-between mb-3">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <h4 className="font-medium text-gray-900">{algorithm.name}</h4>
                    {selectedAlgorithm === algorithm.id && (
                      <CheckCircle2 className="w-4 h-4 text-blue-600" />
                    )}
                  </div>
                  <p className="text-sm text-gray-600">{algorithm.description}</p>
                </div>
              </div>

              {/* Metrics */}
              <div className="grid grid-cols-3 gap-3 mb-3">
                <div className="text-center">
                  <div className="text-sm text-gray-600">Accuracy</div>
                  <div className={`font-bold ${getAccuracyColor(algorithm.accuracy)}`}>
                    {algorithm.accuracy}%
                  </div>
                </div>
                <div className="text-center">
                  <div className="text-sm text-gray-600">Speed</div>
                  <div className="font-bold text-gray-900">{algorithm.processingTime}</div>
                </div>
                <div className="text-center">
                  <div className="text-sm text-gray-600">Complexity</div>
                  <div className={`text-xs px-2 py-1 rounded-full font-medium ${getComplexityColor(algorithm.complexity)}`}>
                    {algorithm.complexity}
                  </div>
                </div>
              </div>

              {/* Expand/Collapse Details */}
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setExpandedAlgorithm(
                    expandedAlgorithm === algorithm.id ? null : algorithm.id
                  );
                }}
                className="text-sm text-blue-600 hover:text-blue-800 flex items-center gap-1"
              >
                <Activity className="w-4 h-4" />
                {expandedAlgorithm === algorithm.id ? 'Less' : 'More'} Details
              </button>

              {/* Expanded Details */}
              {expandedAlgorithm === algorithm.id && (
                <div className="mt-3 pt-3 border-t border-gray-200 space-y-3">
                  <div>
                    <div className="text-sm font-medium text-green-700 mb-1">Strengths:</div>
                    <ul className="text-sm text-gray-600 space-y-1">
                      {algorithm.strengths.map((strength, index) => (
                        <li key={index} className="flex items-center gap-1">
                          <span className="w-1 h-1 bg-green-500 rounded-full"></span>
                          {strength}
                        </li>
                      ))}
                    </ul>
                  </div>
                  <div>
                    <div className="text-sm font-medium text-red-700 mb-1">Limitations:</div>
                    <ul className="text-sm text-gray-600 space-y-1">
                      {algorithm.limitations.map((limitation, index) => (
                        <li key={index} className="flex items-center gap-1">
                          <span className="w-1 h-1 bg-red-500 rounded-full"></span>
                          {limitation}
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Selected Algorithm Summary */}
        {selectedAlgo && (
          <div className="mt-6 p-4 bg-blue-50 rounded-lg">
            <h4 className="font-medium text-blue-900 mb-2">Selected: {selectedAlgo.name}</h4>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
              <div>
                <span className="text-blue-700">Accuracy:</span>
                <span className="ml-1 font-medium">{selectedAlgo.accuracy}%</span>
              </div>
              <div>
                <span className="text-blue-700">Processing:</span>
                <span className="ml-1 font-medium">{selectedAlgo.processingTime}</span>
              </div>
              <div>
                <span className="text-blue-700">Complexity:</span>
                <span className="ml-1 font-medium">{selectedAlgo.complexity}</span>
              </div>
              <div>
                <span className="text-blue-700">vs Argus:</span>
                <span className="ml-1 font-medium text-green-600">+{(selectedAlgo.accuracy - 70).toFixed(1)}%</span>
              </div>
            </div>
          </div>
        )}

        {/* Parameter Configuration (if enabled) */}
        {showParameters && selectedAlgo && (
          <div className="mt-6 p-4 border rounded-lg">
            <h4 className="font-medium text-gray-900 mb-3">Algorithm Parameters</h4>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              {Object.entries(selectedAlgo.parameters).map(([key, value]) => (
                <div key={key}>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    {key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  </label>
                  <input
                    type={typeof value === 'number' ? 'number' : 'text'}
                    value={value.toString()}
                    onChange={(e) => {
                      const newValue = typeof value === 'number' 
                        ? parseFloat(e.target.value) || 0
                        : e.target.value;
                      
                      const newParams = {
                        ...selectedAlgo.parameters,
                        [key]: newValue
                      };
                      
                      onParameterChange?.(selectedAlgo.id, newParams);
                    }}
                    className="w-full px-3 py-1 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-1 focus:ring-blue-500"
                  />
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Action Buttons */}
        <div className="mt-6 flex gap-3">
          <button
            onClick={() => onAlgorithmChange(selectedAlgorithm, selectedAlgo.parameters)}
            disabled={isCalculating}
            className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
          >
            {isCalculating ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                Calculating...
              </>
            ) : (
              <>
                <TrendingUp className="w-4 h-4" />
                Apply Algorithm
              </>
            )}
          </button>
          
          <button
            onClick={() => setShowParameters(!showParameters)}
            className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
          >
            Advanced Settings
          </button>
        </div>
      </div>
    </div>
  );
};

export default AlgorithmSelector;