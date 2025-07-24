/**
 * ML Model Selection Component
 * Allows users to select and configure AI algorithms
 */
import React, { useState, useEffect } from 'react';
import { Brain, Settings, Activity, ChevronDown, Check, AlertCircle, Zap } from 'lucide-react';

interface MLModel {
  id: string;
  name: string;
  description: string;
  category: string;
  version: string;
  accuracy: number;
  performance: number;
  complexity: 'low' | 'medium' | 'high';
  status: 'active' | 'inactive' | 'training' | 'error';
  lastTrained?: string;
  parameters?: Record<string, any>;
  capabilities: string[];
  estimatedRuntime?: string;
}

interface ModelSelectorProps {
  selectedModelId?: string;
  category?: string;
  onModelSelect?: (model: MLModel) => void;
  className?: string;
}

export const ModelSelector: React.FC<ModelSelectorProps> = ({
  selectedModelId,
  category,
  onModelSelect,
  className = ''
}) => {
  const [models, setModels] = useState<MLModel[]>([]);
  const [selectedModel, setSelectedModel] = useState<MLModel | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showSettings, setShowSettings] = useState(false);
  const [filterCategory, setFilterCategory] = useState<string>(category || 'all');

  // Available model categories
  const categories = [
    { id: 'all', name: 'All Models' },
    { id: 'scheduling', name: 'Schedule Optimization' },
    { id: 'forecasting', name: 'Demand Forecasting' },
    { id: 'anomaly_detection', name: 'Anomaly Detection' },
    { id: 'recommendation', name: 'Recommendations' },
    { id: 'classification', name: 'Classification' }
  ];

  // Fetch available ML models
  const fetchModels = async () => {
    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch('/api/v1/ai/models/available', {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        
        // Demo data if API doesn't return models
        const demoModels: MLModel[] = data.models || [
          {
            id: 'genetic_optimizer_v2',
            name: 'Genetic Algorithm Optimizer',
            description: 'Advanced genetic algorithm for schedule optimization with multi-objective fitness',
            category: 'scheduling',
            version: '2.1.0',
            accuracy: 92.5,
            performance: 85.2,
            complexity: 'high',
            status: 'active',
            lastTrained: '2025-07-20T10:30:00Z',
            parameters: {
              population_size: 100,
              mutation_rate: 0.1,
              crossover_rate: 0.8,
              generations: 500
            },
            capabilities: ['Multi-objective optimization', 'Constraint handling', 'Real-time adaptation'],
            estimatedRuntime: '2-5 minutes'
          },
          {
            id: 'lstm_forecaster',
            name: 'LSTM Demand Forecaster',
            description: 'Long Short-Term Memory neural network for accurate demand forecasting',
            category: 'forecasting',
            version: '1.3.2',
            accuracy: 89.7,
            performance: 78.9,
            complexity: 'medium',
            status: 'active',
            lastTrained: '2025-07-19T14:15:00Z',
            parameters: {
              sequence_length: 30,
              hidden_units: 128,
              dropout: 0.2,
              learning_rate: 0.001
            },
            capabilities: ['Time series forecasting', 'Seasonal pattern detection', 'Trend analysis'],
            estimatedRuntime: '30 seconds - 2 minutes'
          },
          {
            id: 'isolation_forest',
            name: 'Isolation Forest Anomaly Detector',
            description: 'Unsupervised anomaly detection for identifying unusual patterns in workforce data',
            category: 'anomaly_detection',
            version: '1.1.0',
            accuracy: 87.3,
            performance: 91.5,
            complexity: 'low',
            status: 'active',
            lastTrained: '2025-07-18T09:00:00Z',
            parameters: {
              n_estimators: 100,
              contamination: 0.1,
              max_samples: 'auto'
            },
            capabilities: ['Real-time anomaly detection', 'Outlier identification', 'Pattern analysis'],
            estimatedRuntime: '10-30 seconds'
          },
          {
            id: 'collaborative_filter',
            name: 'Collaborative Filtering Recommender',
            description: 'Matrix factorization-based recommendation system for shift preferences and assignments',
            category: 'recommendation',
            version: '2.0.1',
            accuracy: 85.1,
            performance: 88.7,
            complexity: 'medium',
            status: 'training',
            lastTrained: '2025-07-17T16:45:00Z',
            parameters: {
              factors: 50,
              regularization: 0.1,
              iterations: 50
            },
            capabilities: ['Preference learning', 'Similarity matching', 'Cold start handling'],
            estimatedRuntime: '1-3 minutes'
          },
          {
            id: 'random_forest_classifier',
            name: 'Random Forest Skills Classifier',
            description: 'Ensemble classifier for skill assessment and employee categorization',
            category: 'classification',
            version: '1.2.3',
            accuracy: 91.2,
            performance: 89.4,
            complexity: 'medium',
            status: 'inactive',
            lastTrained: '2025-07-16T11:20:00Z',
            parameters: {
              n_estimators: 200,
              max_depth: 15,
              min_samples_split: 5
            },
            capabilities: ['Multi-class classification', 'Feature importance', 'Probability estimates'],
            estimatedRuntime: '20-60 seconds'
          }
        ];

        setModels(demoModels);
        
        // Set selected model if provided
        if (selectedModelId) {
          const selected = demoModels.find(m => m.id === selectedModelId);
          if (selected) {
            setSelectedModel(selected);
          }
        }
        
        setError(null);
      } else {
        throw new Error('Failed to fetch models');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  // Select model
  const handleModelSelect = (model: MLModel) => {
    setSelectedModel(model);
    onModelSelect?.(model);
  };

  // Toggle model status
  const toggleModelStatus = async (modelId: string, newStatus: 'active' | 'inactive') => {
    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch(`/api/v1/ai/models/${modelId}/status`, {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ status: newStatus })
      });

      if (response.ok) {
        setModels(prev => prev.map(model => 
          model.id === modelId ? { ...model, status: newStatus } : model
        ));
      }
    } catch (err) {
      console.error('Failed to update model status:', err);
    }
  };

  useEffect(() => {
    fetchModels();
  }, []);

  const filteredModels = models.filter(model => 
    filterCategory === 'all' || model.category === filterCategory
  );

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active':
        return <Check className="w-4 h-4 text-green-500" />;
      case 'training':
        return <Activity className="w-4 h-4 text-blue-500 animate-pulse" />;
      case 'error':
        return <AlertCircle className="w-4 h-4 text-red-500" />;
      default:
        return <div className="w-4 h-4 bg-gray-300 rounded-full" />;
    }
  };

  const getComplexityColor = (complexity: string) => {
    switch (complexity) {
      case 'low':
        return 'bg-green-100 text-green-800';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800';
      case 'high':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  if (loading) {
    return (
      <div className={`p-6 bg-white border border-gray-200 rounded-lg ${className}`}>
        <div className="animate-pulse">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-8 h-8 bg-gray-300 rounded"></div>
            <div className="h-6 bg-gray-300 rounded w-1/3"></div>
          </div>
          <div className="space-y-3">
            {[1, 2, 3].map(i => (
              <div key={i} className="h-16 bg-gray-200 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className={`p-6 bg-white border border-gray-200 rounded-lg ${className}`}>
        <div className="flex items-center gap-2 text-red-600 mb-2">
          <AlertCircle className="w-5 h-5" />
          <span className="font-medium">Error Loading Models</span>
        </div>
        <p className="text-red-600 text-sm mb-3">{error}</p>
        <button
          onClick={fetchModels}
          className="text-red-600 text-sm underline hover:text-red-800"
        >
          Try Again
        </button>
      </div>
    );
  }

  return (
    <div className={`bg-white border border-gray-200 rounded-lg ${className}`}>
      {/* Header */}
      <div className="p-4 border-b border-gray-200">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Brain className="w-6 h-6 text-blue-500" />
            <h3 className="text-lg font-semibold text-gray-900">ML Model Selector</h3>
          </div>
          <button
            onClick={() => setShowSettings(!showSettings)}
            className="p-2 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100"
          >
            <Settings className="w-4 h-4" />
          </button>
        </div>

        {/* Category Filter */}
        <div className="relative">
          <select
            value={filterCategory}
            onChange={(e) => setFilterCategory(e.target.value)}
            className="w-full p-2 border border-gray-300 rounded-lg bg-white text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          >
            {categories.map(cat => (
              <option key={cat.id} value={cat.id}>{cat.name}</option>
            ))}
          </select>
          <ChevronDown className="absolute right-3 top-2.5 w-4 h-4 text-gray-400 pointer-events-none" />
        </div>
      </div>

      {/* Model List */}
      <div className="p-4">
        <div className="space-y-3">
          {filteredModels.map((model) => (
            <div
              key={model.id}
              className={`p-4 border rounded-lg cursor-pointer transition-all ${
                selectedModel?.id === model.id
                  ? 'border-blue-500 bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'
              }`}
              onClick={() => handleModelSelect(model)}
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    {getStatusIcon(model.status)}
                    <h4 className="font-medium text-gray-900">{model.name}</h4>
                    <span className="text-xs text-gray-500">v{model.version}</span>
                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${getComplexityColor(model.complexity)}`}>
                      {model.complexity}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 mb-3">{model.description}</p>
                  
                  {/* Performance Metrics */}
                  <div className="grid grid-cols-3 gap-4 mb-3">
                    <div>
                      <div className="text-xs text-gray-500 mb-1">Accuracy</div>
                      <div className="flex items-center gap-2">
                        <div className="flex-1 bg-gray-200 rounded-full h-2">
                          <div 
                            className="bg-green-500 h-2 rounded-full" 
                            style={{ width: `${model.accuracy}%` }}
                          ></div>
                        </div>
                        <span className="text-xs font-medium text-gray-900">{model.accuracy}%</span>
                      </div>
                    </div>
                    <div>
                      <div className="text-xs text-gray-500 mb-1">Performance</div>
                      <div className="flex items-center gap-2">
                        <div className="flex-1 bg-gray-200 rounded-full h-2">
                          <div 
                            className="bg-blue-500 h-2 rounded-full" 
                            style={{ width: `${model.performance}%` }}
                          ></div>
                        </div>
                        <span className="text-xs font-medium text-gray-900">{model.performance}%</span>
                      </div>
                    </div>
                    <div>
                      <div className="text-xs text-gray-500 mb-1">Runtime</div>
                      <div className="flex items-center gap-1">
                        <Zap className="w-3 h-3 text-yellow-500" />
                        <span className="text-xs text-gray-900">{model.estimatedRuntime}</span>
                      </div>
                    </div>
                  </div>

                  {/* Capabilities */}
                  <div className="flex flex-wrap gap-1">
                    {model.capabilities.slice(0, 3).map((capability, index) => (
                      <span key={index} className="px-2 py-1 bg-gray-100 text-gray-700 text-xs rounded">
                        {capability}
                      </span>
                    ))}
                    {model.capabilities.length > 3 && (
                      <span className="px-2 py-1 bg-gray-100 text-gray-500 text-xs rounded">
                        +{model.capabilities.length - 3} more
                      </span>
                    )}
                  </div>
                </div>

                {/* Status Toggle */}
                <div className="ml-4">
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      toggleModelStatus(
                        model.id, 
                        model.status === 'active' ? 'inactive' : 'active'
                      );
                    }}
                    className={`px-3 py-1 rounded-full text-xs font-medium transition-colors ${
                      model.status === 'active'
                        ? 'bg-green-100 text-green-800 hover:bg-green-200'
                        : model.status === 'training'
                        ? 'bg-blue-100 text-blue-800 cursor-not-allowed'
                        : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
                    }`}
                    disabled={model.status === 'training'}
                  >
                    {model.status === 'training' ? 'Training...' : model.status}
                  </button>
                </div>
              </div>

              {/* Selected Model Details */}
              {selectedModel?.id === model.id && (
                <div className="mt-4 pt-4 border-t border-blue-200">
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <span className="text-gray-600">Last Trained:</span>
                      <span className="ml-2 text-gray-900">
                        {model.lastTrained ? new Date(model.lastTrained).toLocaleDateString() : 'Never'}
                      </span>
                    </div>
                    <div>
                      <span className="text-gray-600">Category:</span>
                      <span className="ml-2 text-gray-900 capitalize">{model.category.replace('_', ' ')}</span>
                    </div>
                  </div>
                  
                  {showSettings && model.parameters && (
                    <div className="mt-3">
                      <h5 className="text-sm font-medium text-gray-900 mb-2">Model Parameters</h5>
                      <div className="bg-gray-50 rounded p-3">
                        <div className="grid grid-cols-2 gap-2 text-xs">
                          {Object.entries(model.parameters).map(([key, value]) => (
                            <div key={key} className="flex justify-between">
                              <span className="text-gray-600 capitalize">{key.replace('_', ' ')}:</span>
                              <span className="text-gray-900 font-mono">{String(value)}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>

        {filteredModels.length === 0 && (
          <div className="text-center py-8 text-gray-500">
            <Brain className="w-12 h-12 mx-auto mb-3 text-gray-300" />
            <p>No models available for the selected category</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default ModelSelector;