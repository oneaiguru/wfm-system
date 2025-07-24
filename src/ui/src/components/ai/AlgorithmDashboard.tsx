/**
 * Algorithm Dashboard Component
 * Provides AI model management interface with performance monitoring
 */
import React, { useState, useEffect } from 'react';
import { Brain, Activity, Settings, TrendingUp, AlertTriangle, Play, Pause, RotateCcw } from 'lucide-react';
import ModelSelector from './ModelSelector';

interface ModelPerformance {
  modelId: string;
  accuracy: number;
  processingTime: number;
  memoryUsage: number;
  lastRun: string;
  runsToday: number;
  successRate: number;
  avgConfidence: number;
}

interface AlgorithmJob {
  id: string;
  modelId: string;
  modelName: string;
  status: 'running' | 'completed' | 'failed' | 'queued';
  progress: number;
  startTime: string;
  estimatedCompletion?: string;
  result?: any;
  errorMessage?: string;
}

interface AlgorithmDashboardProps {
  className?: string;
}

export const AlgorithmDashboard: React.FC<AlgorithmDashboardProps> = ({ className = '' }) => {
  const [selectedModelId, setSelectedModelId] = useState<string>('');
  const [performance, setPerformance] = useState<ModelPerformance[]>([]);
  const [activeJobs, setActiveJobs] = useState<AlgorithmJob[]>([]);
  const [systemMetrics, setSystemMetrics] = useState({
    cpu_usage: 0,
    memory_usage: 0,
    gpu_usage: 0,
    active_models: 0,
    queue_length: 0
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [autoRefresh, setAutoRefresh] = useState(true);

  // Fetch performance data
  const fetchPerformanceData = async () => {
    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch('/api/v1/ai/algorithms/performance', {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        setPerformance(data.models || getDemoPerformanceData());
        setSystemMetrics(data.system_metrics || getDemoSystemMetrics());
      } else {
        // Use demo data if API not available
        setPerformance(getDemoPerformanceData());
        setSystemMetrics(getDemoSystemMetrics());
      }
    } catch (err) {
      console.warn('Failed to fetch performance data, using demo data');
      setPerformance(getDemoPerformanceData());
      setSystemMetrics(getDemoSystemMetrics());
    }
  };

  // Fetch active jobs
  const fetchActiveJobs = async () => {
    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch('/api/v1/ai/algorithms/jobs', {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        setActiveJobs(data.jobs || getDemoJobs());
      } else {
        setActiveJobs(getDemoJobs());
      }
    } catch (err) {
      setActiveJobs(getDemoJobs());
    }
  };

  // Run algorithm
  const runAlgorithm = async (modelId: string, parameters?: any) => {
    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch('/api/v1/ai/algorithms/run', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model_id: modelId,
          parameters: parameters || {}
        })
      });

      if (response.ok) {
        const result = await response.json();
        console.log('Algorithm started:', result);
        await fetchActiveJobs();
      }
    } catch (err) {
      console.error('Failed to run algorithm:', err);
    }
  };

  // Stop algorithm
  const stopAlgorithm = async (jobId: string) => {
    try {
      const token = localStorage.getItem('auth_token');
      const response = await fetch(`/api/v1/ai/algorithms/jobs/${jobId}/stop`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        await fetchActiveJobs();
      }
    } catch (err) {
      console.error('Failed to stop algorithm:', err);
    }
  };

  // Demo data functions
  const getDemoPerformanceData = (): ModelPerformance[] => [
    {
      modelId: 'genetic_optimizer_v2',
      accuracy: 92.5,
      processingTime: 180000,
      memoryUsage: 256,
      lastRun: new Date(Date.now() - 3600000).toISOString(),
      runsToday: 12,
      successRate: 95.8,
      avgConfidence: 0.87
    },
    {
      modelId: 'lstm_forecaster',
      accuracy: 89.7,
      processingTime: 45000,
      memoryUsage: 128,
      lastRun: new Date(Date.now() - 1800000).toISOString(),
      runsToday: 8,
      successRate: 91.2,
      avgConfidence: 0.82
    },
    {
      modelId: 'isolation_forest',
      accuracy: 87.3,
      processingTime: 15000,
      memoryUsage: 64,
      lastRun: new Date(Date.now() - 900000).toISOString(),
      runsToday: 24,
      successRate: 98.1,
      avgConfidence: 0.91
    }
  ];

  const getDemoSystemMetrics = () => ({
    cpu_usage: 45.2,
    memory_usage: 62.8,
    gpu_usage: 78.3,
    active_models: 3,
    queue_length: 2
  });

  const getDemoJobs = (): AlgorithmJob[] => [
    {
      id: 'job_001',
      modelId: 'genetic_optimizer_v2',
      modelName: 'Genetic Algorithm Optimizer',
      status: 'running',
      progress: 67,
      startTime: new Date(Date.now() - 120000).toISOString(),
      estimatedCompletion: new Date(Date.now() + 60000).toISOString()
    },
    {
      id: 'job_002',
      modelId: 'lstm_forecaster',
      modelName: 'LSTM Demand Forecaster',
      status: 'queued',
      progress: 0,
      startTime: new Date().toISOString()
    }
  ];

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      await Promise.all([fetchPerformanceData(), fetchActiveJobs()]);
      setLoading(false);
    };

    fetchData();

    let interval: NodeJS.Timeout;
    if (autoRefresh) {
      interval = setInterval(() => {
        fetchPerformanceData();
        fetchActiveJobs();
      }, 10000); // Update every 10 seconds
    }

    return () => {
      if (interval) clearInterval(interval);
    };
  }, [autoRefresh]);

  const formatDuration = (ms: number) => {
    if (ms < 1000) return `${ms}ms`;
    if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
    return `${(ms / 60000).toFixed(1)}min`;
  };

  const formatMemory = (mb: number) => {
    if (mb < 1024) return `${mb}MB`;
    return `${(mb / 1024).toFixed(1)}GB`;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'running':
        return 'bg-blue-100 text-blue-800';
      case 'completed':
        return 'bg-green-100 text-green-800';
      case 'failed':
        return 'bg-red-100 text-red-800';
      case 'queued':
        return 'bg-yellow-100 text-yellow-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'running':
        return <Activity className="w-3 h-3 animate-pulse" />;
      case 'completed':
        return <TrendingUp className="w-3 h-3" />;
      case 'failed':
        return <AlertTriangle className="w-3 h-3" />;
      default:
        return <Play className="w-3 h-3" />;
    }
  };

  if (loading) {
    return (
      <div className={`p-6 bg-white border border-gray-200 rounded-lg ${className}`}>
        <div className="animate-pulse space-y-4">
          <div className="h-6 bg-gray-300 rounded w-1/3"></div>
          <div className="grid grid-cols-4 gap-4">
            {[1, 2, 3, 4].map(i => (
              <div key={i} className="h-20 bg-gray-200 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Header */}
      <div className="bg-white border border-gray-200 rounded-lg p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <Brain className="w-8 h-8 text-blue-500" />
            <div>
              <h2 className="text-xl font-semibold text-gray-900">Algorithm Dashboard</h2>
              <p className="text-sm text-gray-600">Monitor and manage AI model performance</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setAutoRefresh(!autoRefresh)}
              className={`flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium ${
                autoRefresh 
                  ? 'bg-green-100 text-green-800' 
                  : 'bg-gray-100 text-gray-800'
              }`}
            >
              <RotateCcw className={`w-4 h-4 ${autoRefresh ? 'animate-spin' : ''}`} />
              Auto Refresh
            </button>
          </div>
        </div>

        {/* System Metrics */}
        <div className="grid grid-cols-5 gap-4">
          <div className="bg-blue-50 rounded-lg p-4">
            <div className="text-2xl font-bold text-blue-600">{systemMetrics.cpu_usage.toFixed(1)}%</div>
            <div className="text-sm text-blue-700">CPU Usage</div>
          </div>
          <div className="bg-green-50 rounded-lg p-4">
            <div className="text-2xl font-bold text-green-600">{systemMetrics.memory_usage.toFixed(1)}%</div>
            <div className="text-sm text-green-700">Memory Usage</div>
          </div>
          <div className="bg-purple-50 rounded-lg p-4">
            <div className="text-2xl font-bold text-purple-600">{systemMetrics.gpu_usage.toFixed(1)}%</div>
            <div className="text-sm text-purple-700">GPU Usage</div>
          </div>
          <div className="bg-orange-50 rounded-lg p-4">
            <div className="text-2xl font-bold text-orange-600">{systemMetrics.active_models}</div>
            <div className="text-sm text-orange-700">Active Models</div>
          </div>
          <div className="bg-red-50 rounded-lg p-4">
            <div className="text-2xl font-bold text-red-600">{systemMetrics.queue_length}</div>
            <div className="text-sm text-red-700">Queue Length</div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Model Selector */}
        <div>
          <ModelSelector
            selectedModelId={selectedModelId}
            onModelSelect={(model) => setSelectedModelId(model.id)}
            className="h-fit"
          />
        </div>

        {/* Performance Monitoring */}
        <div className="bg-white border border-gray-200 rounded-lg">
          <div className="p-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Performance Monitoring</h3>
          </div>
          <div className="p-4">
            <div className="space-y-4">
              {performance.map((perf) => (
                <div key={perf.modelId} className="p-4 border border-gray-200 rounded-lg">
                  <div className="flex items-center justify-between mb-3">
                    <h4 className="font-medium text-gray-900">
                      {perf.modelId.replace('_', ' ').toUpperCase()}
                    </h4>
                    <button
                      onClick={() => runAlgorithm(perf.modelId)}
                      className="flex items-center gap-1 px-3 py-1 bg-blue-500 text-white rounded text-sm hover:bg-blue-600"
                    >
                      <Play className="w-3 h-3" />
                      Run
                    </button>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-3 text-sm">
                    <div>
                      <span className="text-gray-600">Accuracy:</span>
                      <span className="ml-2 font-medium text-gray-900">{perf.accuracy}%</span>
                    </div>
                    <div>
                      <span className="text-gray-600">Success Rate:</span>
                      <span className="ml-2 font-medium text-gray-900">{perf.successRate}%</span>
                    </div>
                    <div>
                      <span className="text-gray-600">Avg Time:</span>
                      <span className="ml-2 font-medium text-gray-900">{formatDuration(perf.processingTime)}</span>
                    </div>
                    <div>
                      <span className="text-gray-600">Memory:</span>
                      <span className="ml-2 font-medium text-gray-900">{formatMemory(perf.memoryUsage)}</span>
                    </div>
                    <div>
                      <span className="text-gray-600">Runs Today:</span>
                      <span className="ml-2 font-medium text-gray-900">{perf.runsToday}</span>
                    </div>
                    <div>
                      <span className="text-gray-600">Confidence:</span>
                      <span className="ml-2 font-medium text-gray-900">{(perf.avgConfidence * 100).toFixed(1)}%</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Active Jobs */}
      {activeJobs.length > 0 && (
        <div className="bg-white border border-gray-200 rounded-lg">
          <div className="p-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Active Jobs</h3>
          </div>
          <div className="p-4">
            <div className="space-y-3">
              {activeJobs.map((job) => (
                <div key={job.id} className="p-4 border border-gray-200 rounded-lg">
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-3">
                      <div className={`flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(job.status)}`}>
                        {getStatusIcon(job.status)}
                        {job.status}
                      </div>
                      <span className="font-medium text-gray-900">{job.modelName}</span>
                    </div>
                    {job.status === 'running' && (
                      <button
                        onClick={() => stopAlgorithm(job.id)}
                        className="flex items-center gap-1 px-3 py-1 bg-red-500 text-white rounded text-sm hover:bg-red-600"
                      >
                        <Pause className="w-3 h-3" />
                        Stop
                      </button>
                    )}
                  </div>
                  
                  {job.status === 'running' && (
                    <div className="mb-2">
                      <div className="flex justify-between text-sm mb-1">
                        <span className="text-gray-600">Progress</span>
                        <span className="text-gray-900">{job.progress}%</span>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2">
                        <div 
                          className="bg-blue-500 h-2 rounded-full transition-all duration-300"
                          style={{ width: `${job.progress}%` }}
                        ></div>
                      </div>
                    </div>
                  )}
                  
                  <div className="grid grid-cols-2 gap-3 text-sm">
                    <div>
                      <span className="text-gray-600">Started:</span>
                      <span className="ml-2 text-gray-900">
                        {new Date(job.startTime).toLocaleTimeString()}
                      </span>
                    </div>
                    {job.estimatedCompletion && (
                      <div>
                        <span className="text-gray-600">ETA:</span>
                        <span className="ml-2 text-gray-900">
                          {new Date(job.estimatedCompletion).toLocaleTimeString()}
                        </span>
                      </div>
                    )}
                  </div>
                  
                  {job.errorMessage && (
                    <div className="mt-2 p-2 bg-red-50 border border-red-200 rounded text-sm text-red-700">
                      {job.errorMessage}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AlgorithmDashboard;