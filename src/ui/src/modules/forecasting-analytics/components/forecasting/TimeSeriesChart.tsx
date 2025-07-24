import React, { useRef, useEffect, useState, useMemo } from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler,
  TimeScale,
  InteractionItem
} from 'chart.js';
import { Line } from 'react-chartjs-2';
import 'chartjs-adapter-date-fns';
import zoomPlugin from 'chartjs-plugin-zoom';
import { ZoomIn, ZoomOut, Move, RotateCcw, TrendingUp, BarChart3, Clock } from 'lucide-react';

// Register Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler,
  TimeScale,
  zoomPlugin
);

// Type definitions
interface ForecastDataPoint {
  timestamp: string;
  predicted: number;
  actual?: number;
  confidence: number;
  adjustments?: number;
  requiredAgents: number;
  isWeekend: boolean;
  hour: number;
  dayOfWeek: number;
}

interface TimeSeriesChartProps {
  data: ForecastDataPoint[];
  loading?: boolean;
  error?: string | null;
  height?: number;
  showLegend?: boolean;
  showTooltips?: boolean;
  enableZoom?: boolean;
  enablePan?: boolean;
  onDataPointClick?: (dataPoint: ForecastDataPoint, index: number) => void;
  onRangeSelect?: (startIndex: number, endIndex: number) => void;
  showControls?: boolean;
  algorithmInfo?: {
    name: string;
    accuracy: number;
    confidence: number;
  };
}

const TimeSeriesChart: React.FC<TimeSeriesChartProps> = ({
  data,
  loading = false,
  error = null,
  height = 400,
  showLegend = true,
  showTooltips = true,
  enableZoom = true,
  enablePan = true,
  onDataPointClick,
  onRangeSelect,
  showControls = true,
  algorithmInfo = { name: 'Enhanced ARIMA', accuracy: 85.6, confidence: 94.2 }
}) => {
  const [currentTimeIndicator, setCurrentTimeIndicator] = useState<Date>(new Date());
  const [chartZoom, setChartZoom] = useState<'1h' | '6h' | '1d' | '3d' | '7d'>('1d');
  const [showHistorical, setShowHistorical] = useState(true);
  const [showConfidenceIntervals, setShowConfidenceIntervals] = useState(true);
  const [selectedDataPoint, setSelectedDataPoint] = useState<ForecastDataPoint | null>(null);
  const chartRef = useRef<ChartJS<'line'>>(null);

  // Update current time indicator every minute
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTimeIndicator(new Date());
    }, 60000);

    return () => clearInterval(interval);
  }, []);

  // Filter data based on selected zoom level
  const filteredData = useMemo(() => {
    if (!data || data.length === 0) return [];
    
    const now = new Date();
    const zoomHours = {
      '1h': 1,
      '6h': 6,
      '1d': 24,
      '3d': 72,
      '7d': 168
    }[chartZoom];

    const cutoffTime = new Date(now.getTime() - (zoomHours * 60 * 60 * 1000));
    const endTime = new Date(now.getTime() + (zoomHours * 60 * 60 * 1000));
    
    return data.filter(point => {
      const pointTime = new Date(point.timestamp);
      return pointTime >= cutoffTime && pointTime <= endTime;
    });
  }, [data, chartZoom]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        <span className="ml-3 text-gray-600">Loading forecast data...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-64 bg-red-50 rounded-lg">
        <div className="text-center">
          <div className="text-red-600 text-lg mb-2">⚠️ Error Loading Chart</div>
          <div className="text-red-500 text-sm">{error}</div>
        </div>
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <div className="flex items-center justify-center h-64 bg-gray-50 rounded-lg">
        <div className="text-center text-gray-500">
          <div className="text-lg mb-2">📊 No Data Available</div>
          <div className="text-sm">Upload historical data to generate forecasts</div>
        </div>
      </div>
    );
  }

  // Calculate statistics for current view
  const chartStats = useMemo(() => {
    if (!filteredData || filteredData.length === 0) return null;
    
    const actualValues = filteredData.filter(p => p.actual !== undefined).map(p => p.actual!);
    const predictedValues = filteredData.map(p => p.predicted);
    
    return {
      totalPoints: filteredData.length,
      actualPoints: actualValues.length,
      averageActual: actualValues.length > 0 ? actualValues.reduce((a, b) => a + b, 0) / actualValues.length : 0,
      averagePredicted: predictedValues.reduce((a, b) => a + b, 0) / predictedValues.length,
      maxVolume: Math.max(...predictedValues, ...actualValues),
      minVolume: Math.min(...predictedValues, ...actualValues),
      averageConfidence: filteredData.reduce((sum, p) => sum + p.confidence, 0) / filteredData.length
    };
  }, [filteredData]);

  // Prepare data
  const labels = filteredData.map(point => new Date(point.timestamp));
  const currentTime = new Date();
  const currentTimeIndex = filteredData.findIndex(point => new Date(point.timestamp) >= currentTime);

  // Create datasets
  const datasets = [];

  // Actual data (past) - only show if enabled
  if (showHistorical && filteredData.some(point => point.actual !== undefined)) {
    datasets.push({
      label: 'Actual Volume',
      data: filteredData.map(point => point.actual ?? null),
      borderColor: '#3B82F6',
      backgroundColor: '#3B82F6',
      fill: false,
      tension: 0.1,
      pointRadius: 3,
      pointHoverRadius: 6,
      borderWidth: 2,
      pointBackgroundColor: '#3B82F6',
      pointBorderColor: '#FFFFFF',
      pointBorderWidth: 2
    });
  }

  // Predicted data (future)
  if (currentTimeIndex >= 0) {
    datasets.push({
      label: 'Forecast',
      data: filteredData.map((point, index) => index >= currentTimeIndex ? point.predicted : null),
      borderColor: '#10B981',
      backgroundColor: '#10B981',
      fill: false,
      tension: 0.2,
      borderDash: [8, 4],
      pointRadius: 3,
      pointHoverRadius: 6,
      borderWidth: 2,
      pointBackgroundColor: '#10B981',
      pointBorderColor: '#FFFFFF',
      pointBorderWidth: 2
    });

    // Confidence intervals - only show if enabled
    if (showConfidenceIntervals) {
      datasets.push({
        label: 'Confidence Band',
        data: filteredData.map((point, index) => 
          index >= currentTimeIndex ? point.predicted + (point.confidence * point.predicted * 0.2) : null
        ),
        borderColor: 'rgba(16, 185, 129, 0.2)',
        backgroundColor: 'rgba(16, 185, 129, 0.1)',
        fill: '+1',
        tension: 0.2,
        pointRadius: 0,
        borderWidth: 0
      });

      datasets.push({
        label: 'Confidence Band Lower',
        data: filteredData.map((point, index) => 
          index >= currentTimeIndex ? Math.max(0, point.predicted - (point.confidence * point.predicted * 0.2)) : null
        ),
        borderColor: 'rgba(16, 185, 129, 0.2)',
        backgroundColor: 'rgba(16, 185, 129, 0.1)',
        fill: false,
        tension: 0.2,
        pointRadius: 0,
        borderWidth: 0
      });
    }
  }

  // Required agents overlay (secondary y-axis)
  datasets.push({
    label: 'Required Agents',
    data: filteredData.map(point => point.requiredAgents),
    borderColor: '#F59E0B',
    backgroundColor: 'rgba(245, 158, 11, 0.1)',
    fill: false,
    tension: 0.1,
    pointRadius: 2,
    pointHoverRadius: 4,
    borderWidth: 2,
    yAxisID: 'y1'
  });

  const chartData = {
    labels,
    datasets
  };

  const options = {
    responsive: true,
    maintainAspectRatio: false,
    interaction: {
      mode: 'index' as const,
      intersect: false
    },
    plugins: {
      zoom: {
        zoom: {
          wheel: {
            enabled: enableZoom,
          },
          pinch: {
            enabled: enableZoom
          },
          mode: 'x' as const,
        },
        pan: {
          enabled: enablePan,
          mode: 'x' as const,
        }
      },
      legend: {
        display: showLegend,
        position: 'top' as const,
        labels: {
          usePointStyle: true,
          padding: 20,
          filter: function(legendItem: any) {
            // Hide confidence interval labels from legend
            return !legendItem.text.includes('Confidence Band');
          },
          generateLabels: function(chart: any) {
            const labels = ChartJS.defaults.plugins.legend.labels.generateLabels(chart);
            return labels.map(label => {
              if (label.text === 'Actual Volume') {
                label.text = `📊 ${label.text}`;
              } else if (label.text === 'Forecast') {
                label.text = `🔮 ${label.text}`;
              } else if (label.text === 'Required Agents') {
                label.text = `👥 ${label.text}`;
              }
              return label;
            });
          }
        }
      },
      tooltip: {
        enabled: showTooltips,
        mode: 'index' as const,
        intersect: false,
        backgroundColor: 'rgba(0, 0, 0, 0.8)',
        titleColor: '#FFFFFF',
        bodyColor: '#FFFFFF',
        borderColor: '#E5E7EB',
        borderWidth: 1,
        cornerRadius: 8,
        displayColors: true,
        callbacks: {
          title: function(context: any) {
            const date = new Date(context[0].label);
            return date.toLocaleString('en-US', {
              weekday: 'long',
              month: 'short',
              day: 'numeric',
              hour: '2-digit',
              minute: '2-digit',
              hour12: true
            });
          },
          afterTitle: function(context: any) {
            const pointIndex = context[0].dataIndex;
            const point = filteredData[pointIndex];
            if (!point) return '';
            
            const tags = [];
            if (point.isWeekend) tags.push('Weekend');
            if (point.hour >= 12 && point.hour <= 16) tags.push('Peak Hours');
            if (point.confidence > 0.9) tags.push('High Confidence');
            
            return tags.length > 0 ? `(${tags.join(', ')})` : '';
          },
          label: function(context: any) {
            const pointIndex = context.dataIndex;
            const point = filteredData[pointIndex];
            const value = context.parsed.y;
            
            if (!point || value === null) return '';
            
            if (context.dataset.label === 'Actual Volume') {
              return `📊 Actual: ${value?.toFixed(0)} calls`;
            } else if (context.dataset.label === 'Forecast') {
              return `🔮 Forecast: ${value?.toFixed(0)} calls (${(point.confidence * 100).toFixed(1)}% confidence)`;
            } else if (context.dataset.label === 'Required Agents') {
              return `👥 Required Agents: ${value} agents`;
            }
            return `${context.dataset.label}: ${value?.toFixed(1)}`;
          },
          afterBody: function(context: any) {
            const pointIndex = context[0].dataIndex;
            const point = filteredData[pointIndex];
            if (!point) return '';
            
            const lines = [];
            if (point.adjustments) {
              lines.push(`🔧 Manual Adjustment: ${point.adjustments > 0 ? '+' : ''}${point.adjustments}`);
            }
            if (point.confidence) {
              const confidenceLevel = point.confidence > 0.8 ? 'High' : point.confidence > 0.6 ? 'Medium' : 'Low';
              lines.push(`🎯 Confidence: ${confidenceLevel}`);
            }
            return lines;
          }
        }
      }
    },
    scales: {
      x: {
        type: 'time' as const,
        time: {
          unit: chartZoom === '1h' ? 'minute' : chartZoom === '6h' ? 'hour' : 'hour',
          displayFormats: {
            minute: 'HH:mm',
            hour: 'MMM dd HH:mm',
            day: 'MMM dd'
          }
        },
        title: {
          display: true,
          text: 'Time',
          font: {
            size: 12,
            weight: 'bold'
          }
        },
        grid: {
          color: 'rgba(0, 0, 0, 0.1)',
          drawOnChartArea: true
        },
        ticks: {
          maxTicksLimit: 12,
          font: {
            size: 11
          }
        }
      },
      y: {
        type: 'linear' as const,
        display: true,
        position: 'left' as const,
        beginAtZero: true,
        title: {
          display: true,
          text: 'Call Volume',
          font: {
            size: 12,
            weight: 'bold'
          }
        },
        grid: {
          color: 'rgba(0, 0, 0, 0.1)',
          drawOnChartArea: true
        },
        ticks: {
          callback: function(value: any) {
            return Math.round(value).toLocaleString();
          }
        }
      },
      y1: {
        type: 'linear' as const,
        display: true,
        position: 'right' as const,
        beginAtZero: true,
        title: {
          display: true,
          text: 'Agents',
          font: {
            size: 12,
            weight: 'bold'
          }
        },
        grid: {
          drawOnChartArea: false,
        },
        ticks: {
          callback: function(value: any) {
            return Math.round(value);
          }
        }
      }
    },
    onClick: (event: any, elements: InteractionItem[]) => {
      if (elements.length > 0) {
        const pointIndex = elements[0].index;
        const dataPoint = filteredData[pointIndex];
        setSelectedDataPoint(dataPoint);
        if (onDataPointClick) {
          onDataPointClick(dataPoint, pointIndex);
        }
      }
    },
    onHover: (event: any, elements: InteractionItem[]) => {
      const canvas = event.native.target as HTMLCanvasElement;
      canvas.style.cursor = elements.length > 0 ? 'pointer' : 'default';
    }
  };

  const resetZoom = () => {
    if (chartRef.current) {
      chartRef.current.resetZoom();
    }
  };

  return (
    <div className="bg-white rounded-lg shadow border">
      {/* Header with Controls */}
      <div className="border-b border-gray-200 p-4">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="text-xl font-semibold text-gray-900 flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-blue-600" />
              Time Series Analysis
            </h3>
            <p className="text-sm text-gray-600 mt-1">
              Algorithm: {algorithmInfo.name} • Accuracy: {algorithmInfo.accuracy}% • Confidence: {algorithmInfo.confidence}%
            </p>
          </div>
          
          <div className="flex items-center gap-2">
            <div className="text-xs text-gray-500">
              {chartStats ? `${chartStats.totalPoints} points • ${chartStats.actualPoints} actual` : 'Loading...'}
            </div>
          </div>
        </div>

        {/* Chart Controls */}
        {showControls && (
          <div className="flex flex-wrap items-center justify-between gap-4">
            {/* Time Range Selector */}
            <div className="flex items-center gap-2">
              <Clock className="w-4 h-4 text-gray-400" />
              <span className="text-sm text-gray-600">View:</span>
              <div className="flex bg-gray-100 rounded-md p-1">
                {(['1h', '6h', '1d', '3d', '7d'] as const).map((range) => (
                  <button
                    key={range}
                    onClick={() => setChartZoom(range)}
                    className={`px-3 py-1 text-xs font-medium rounded transition-colors ${
                      chartZoom === range
                        ? 'bg-blue-500 text-white'
                        : 'text-gray-600 hover:text-gray-800 hover:bg-gray-200'
                    }`}
                  >
                    {range}
                  </button>
                ))}
              </div>
            </div>

            {/* Display Options */}
            <div className="flex items-center gap-4">
              <label className="flex items-center gap-2 text-sm text-gray-600">
                <input
                  type="checkbox"
                  checked={showHistorical}
                  onChange={(e) => setShowHistorical(e.target.checked)}
                  className="rounded border-gray-300"
                />
                <span>Historical</span>
              </label>
              <label className="flex items-center gap-2 text-sm text-gray-600">
                <input
                  type="checkbox"
                  checked={showConfidenceIntervals}
                  onChange={(e) => setShowConfidenceIntervals(e.target.checked)}
                  className="rounded border-gray-300"
                />
                <span>Confidence</span>
              </label>
            </div>

            {/* Zoom Controls */}
            {enableZoom && (
              <div className="flex items-center gap-2">
                <button
                  onClick={resetZoom}
                  className="p-2 text-gray-400 hover:text-gray-600 rounded-md hover:bg-gray-100"
                  title="Reset zoom"
                >
                  <RotateCcw className="w-4 h-4" />
                </button>
                <div className="text-xs text-gray-500">
                  {enablePan ? 'Zoom & Pan' : 'Zoom only'}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
      
      {/* Chart Area */}
      <div className="p-4">
        <div style={{ height: height }} className="relative">
          <Line ref={chartRef} data={chartData} options={options} />
        </div>
      </div>

      {/* Chart Statistics */}
      <div className="border-t border-gray-200 p-4">
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4 text-sm">
          <div className="text-center">
            <div className="font-medium text-blue-600">Accuracy</div>
            <div className="text-xl font-bold">{algorithmInfo.accuracy}%</div>
            <div className="text-xs text-gray-500">Current</div>
          </div>
          <div className="text-center">
            <div className="font-medium text-green-600">Confidence</div>
            <div className="text-xl font-bold">{algorithmInfo.confidence}%</div>
            <div className="text-xs text-gray-500">Average</div>
          </div>
          <div className="text-center">
            <div className="font-medium text-purple-600">Data Points</div>
            <div className="text-xl font-bold">{chartStats?.totalPoints || 0}</div>
            <div className="text-xs text-gray-500">Current view</div>
          </div>
          <div className="text-center">
            <div className="font-medium text-yellow-600">Peak Volume</div>
            <div className="text-xl font-bold">{chartStats?.maxVolume?.toFixed(0) || 'N/A'}</div>
            <div className="text-xs text-gray-500">Calls</div>
          </div>
          <div className="text-center">
            <div className="font-medium text-indigo-600">Time Range</div>
            <div className="text-xl font-bold">{chartZoom.toUpperCase()}</div>
            <div className="text-xs text-gray-500">Selected</div>
          </div>
        </div>
        
        {/* Selected Data Point Details */}
        {selectedDataPoint && (
          <div className="mt-4 bg-blue-50 p-3 rounded-lg">
            <div className="text-sm font-medium text-blue-900 mb-2">Selected Point Details</div>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-xs">
              <div>
                <span className="text-gray-600">Time:</span>
                <div className="font-medium">{new Date(selectedDataPoint.timestamp).toLocaleString()}</div>
              </div>
              <div>
                <span className="text-gray-600">Predicted:</span>
                <div className="font-medium">{selectedDataPoint.predicted.toFixed(0)} calls</div>
              </div>
              <div>
                <span className="text-gray-600">Confidence:</span>
                <div className="font-medium">{(selectedDataPoint.confidence * 100).toFixed(1)}%</div>
              </div>
              <div>
                <span className="text-gray-600">Agents:</span>
                <div className="font-medium">{selectedDataPoint.requiredAgents} required</div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

// Add display name for debugging
TimeSeriesChart.displayName = 'TimeSeriesChart';
};

export default TimeSeriesChart;

// Export additional types for external use
export type { ForecastDataPoint };
export type ChartZoomLevel = '1h' | '6h' | '1d' | '3d' | '7d';