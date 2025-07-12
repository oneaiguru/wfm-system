import React, { memo, useRef, useCallback, useState } from 'react';
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend, Filler, TimeScale } from 'chart.js';
import { Line } from 'react-chartjs-2';
import 'chartjs-adapter-date-fns';
import { ForecastData, ChartProps, ChartConfig, ColorScheme } from '@/types/ChartTypes';

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend, Filler, TimeScale);

interface ForecastChartProps {
  historicalData?: any;
  algorithm?: string;
  showConfidenceIntervals?: boolean;
  enableZoom?: boolean;
  modelComparison?: boolean;
  config?: Partial<ChartConfig>;
  colorScheme?: Partial<ColorScheme>;
  loading?: boolean;
  onExport?: (options: any) => void;
  onDataPointClick?: (dataPoint: any) => void;
}

const defaultColorScheme: ColorScheme = {
  primary: 'rgba(168, 85, 247, 0.8)',
  secondary: 'rgba(34, 197, 94, 0.8)',
  accent: 'rgba(59, 130, 246, 0.8)',
  background: 'rgba(255, 255, 255, 0.9)',
  text: '#374151',
  grid: 'rgba(156, 163, 175, 0.3)',
  confidence: 'rgba(251, 146, 60, 0.2)',
  forecast: 'rgba(251, 146, 60, 0.8)',
  actual: 'rgba(59, 130, 246, 0.8)'
};

const defaultConfig: ChartConfig = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'top',
      display: true
    },
    title: {
      display: true,
      text: 'Forecast Analysis'
    },
    tooltip: {
      enabled: true,
      mode: 'index'
    }
  },
  scales: {
    x: {
      type: 'category',
      title: {
        display: true,
        text: 'Time Period'
      }
    },
    y: {
      title: {
        display: true,
        text: 'Call Volume'
      },
      min: 0
    }
  },
  interaction: {
    intersect: false,
    mode: 'index'
  }
};

const ForecastChart: React.FC<ForecastChartProps> = memo(({
  historicalData,
  algorithm = 'ARIMA',
  showConfidenceIntervals = true,
  enableZoom = true,
  modelComparison = false,
  config = {},
  colorScheme = {},
  loading = false,
  onExport,
  onDataPointClick
}) => {
  const chartRef = useRef<ChartJS>(null);
  const [zoomLevel, setZoomLevel] = useState(1);
  const [showConfidence, setShowConfidence] = useState(showConfidenceIntervals);
  const [selectedModel, setSelectedModel] = useState(algorithm);

  const finalColorScheme = { ...defaultColorScheme, ...colorScheme };
  const finalConfig = { ...defaultConfig, ...config };

  // Generate sample data if not provided
  const defaultData: ForecastData = {
    historical: Array.from({ length: 6 }, (_, i) => ({
      timestamp: `Week ${i + 1}`,
      value: 1200 + Math.random() * 300
    })),
    forecast: Array.from({ length: 4 }, (_, i) => ({
      timestamp: `Week ${i + 7}`,
      value: 1300 + Math.random() * 200,
      confidence: 0.85 + Math.random() * 0.1
    })),
    confidence: {
      upper: Array.from({ length: 4 }, (_, i) => ({
        timestamp: `Week ${i + 7}`,
        value: 1400 + Math.random() * 200
      })),
      lower: Array.from({ length: 4 }, (_, i) => ({
        timestamp: `Week ${i + 7}`,
        value: 1200 + Math.random() * 200
      }))
    },
    modelMetrics: {
      accuracy: 0.942,
      modelType: algorithm,
      r2Score: 0.887,
      mape: 5.8
    }
  };

  const data = historicalData || defaultData;

  const handleExport = useCallback((format: 'png' | 'jpg' = 'png') => {
    if (chartRef.current && onExport) {
      const canvas = chartRef.current.canvas;
      const url = canvas.toDataURL(`image/${format}`);
      
      const link = document.createElement('a');
      link.download = `forecast-analysis-${new Date().toISOString().split('T')[0]}.${format}`;
      link.href = url;
      link.click();
    }
  }, [onExport]);

  const chartData = {
    labels: [
      ...data.historical.map(d => d.timestamp),
      ...data.forecast.map(d => d.timestamp)
    ],
    datasets: [
      // Historical data
      {
        label: 'Historical',
        data: [
          ...data.historical.map(d => d.value),
          ...Array(data.forecast.length).fill(null)
        ],
        borderColor: finalColorScheme.actual,
        backgroundColor: finalColorScheme.actual.replace('0.8', '0.1'),
        borderWidth: 2,
        fill: false,
        tension: 0.1,
        pointRadius: 4,
        pointHoverRadius: 6
      },
      // Forecast data
      {
        label: `Forecast (${selectedModel})`,
        data: [
          ...Array(data.historical.length - 1).fill(null),
          data.historical[data.historical.length - 1].value,
          ...data.forecast.map(d => d.value)
        ],
        borderColor: finalColorScheme.forecast,
        backgroundColor: finalColorScheme.forecast.replace('0.8', '0.1'),
        borderWidth: 2,
        borderDash: [5, 5],
        fill: false,
        tension: 0.1,
        pointRadius: 4,
        pointHoverRadius: 6
      },
      // Confidence interval
      ...(showConfidence ? [
        {
          label: 'Confidence Upper',
          data: [
            ...Array(data.historical.length).fill(null),
            ...data.confidence.upper.map(d => d.value)
          ],
          borderColor: 'transparent',
          backgroundColor: finalColorScheme.confidence,
          fill: '+1',
          tension: 0.1,
          pointRadius: 0
        },
        {
          label: 'Confidence Lower',
          data: [
            ...Array(data.historical.length).fill(null),
            ...data.confidence.lower.map(d => d.value)
          ],
          borderColor: 'transparent',
          backgroundColor: 'transparent',
          fill: '-1',
          tension: 0.1,
          pointRadius: 0
        }
      ] : [])
    ]
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96 bg-gray-50 rounded-lg">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading forecast analysis...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Model Metrics */}
      <div className="bg-white p-4 rounded-lg shadow-sm border">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold">📈 Forecast Metrics</h3>
          <div className="flex items-center gap-2">
            <select
              value={selectedModel}
              onChange={(e) => setSelectedModel(e.target.value)}
              className="border rounded-lg px-3 py-1 text-sm"
            >
              <option value="ARIMA">ARIMA Model</option>
              <option value="Linear Regression">Linear Regression</option>
              <option value="Moving Average">Moving Average</option>
              <option value="Combined">Combined Model</option>
            </select>
          </div>
        </div>
        
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
          <div className="bg-green-50 p-3 rounded">
            <p className="text-gray-600">Accuracy</p>
            <p className="text-2xl font-bold text-green-600">{(data.modelMetrics.accuracy * 100).toFixed(1)}%</p>
          </div>
          <div className="bg-blue-50 p-3 rounded">
            <p className="text-gray-600">Model Type</p>
            <p className="text-lg font-bold text-blue-600">{selectedModel}</p>
          </div>
          {data.modelMetrics.r2Score && (
            <div className="bg-purple-50 p-3 rounded">
              <p className="text-gray-600">R² Score</p>
              <p className="text-2xl font-bold text-purple-600">{data.modelMetrics.r2Score.toFixed(3)}</p>
            </div>
          )}
          {data.modelMetrics.mape && (
            <div className="bg-orange-50 p-3 rounded">
              <p className="text-gray-600">MAPE</p>
              <p className="text-2xl font-bold text-orange-600">{data.modelMetrics.mape.toFixed(1)}%</p>
            </div>
          )}
        </div>
      </div>

      {/* Chart Controls */}
      <div className="bg-white p-4 rounded-lg shadow-sm border">
        <div className="flex items-center justify-between flex-wrap gap-4">
          <div className="flex items-center gap-2">
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={showConfidence}
                onChange={(e) => setShowConfidence(e.target.checked)}
                className="rounded"
              />
              Show Confidence Interval
            </label>
          </div>
          
          <div className="flex items-center gap-1">
            <button
              onClick={() => handleExport('png')}
              className="px-3 py-1 text-sm bg-green-100 text-green-700 rounded hover:bg-green-200"
            >
              Export PNG
            </button>
            <button
              onClick={() => handleExport('jpg')}
              className="px-3 py-1 text-sm bg-green-100 text-green-700 rounded hover:bg-green-200"
            >
              Export JPG
            </button>
          </div>
        </div>
      </div>

      {/* Main Chart */}
      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <div className="h-96">
          <Line
            ref={chartRef}
            data={chartData}
            options={finalConfig}
          />
        </div>
      </div>

      {/* Model Comparison */}
      {modelComparison && (
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h4 className="font-semibold mb-4">Model Comparison</h4>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b">
                  <th className="text-left p-2">Model</th>
                  <th className="text-left p-2">Accuracy</th>
                  <th className="text-left p-2">R² Score</th>
                  <th className="text-left p-2">MAPE</th>
                  <th className="text-left p-2">Status</th>
                </tr>
              </thead>
              <tbody>
                <tr className="border-b">
                  <td className="p-2">ARIMA</td>
                  <td className="p-2">94.2%</td>
                  <td className="p-2">0.887</td>
                  <td className="p-2">5.8%</td>
                  <td className="p-2">
                    <span className="px-2 py-1 bg-green-100 text-green-800 rounded text-xs">Active</span>
                  </td>
                </tr>
                <tr className="border-b">
                  <td className="p-2">Linear Regression</td>
                  <td className="p-2">89.7%</td>
                  <td className="p-2">0.832</td>
                  <td className="p-2">7.2%</td>
                  <td className="p-2">
                    <span className="px-2 py-1 bg-gray-100 text-gray-800 rounded text-xs">Available</span>
                  </td>
                </tr>
                <tr>
                  <td className="p-2">Moving Average</td>
                  <td className="p-2">92.1%</td>
                  <td className="p-2">0.864</td>
                  <td className="p-2">6.3%</td>
                  <td className="p-2">
                    <span className="px-2 py-1 bg-yellow-100 text-yellow-800 rounded text-xs">Testing</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
});

ForecastChart.displayName = 'ForecastChart';

export default ForecastChart;