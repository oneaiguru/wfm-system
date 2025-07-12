import React, { memo, useRef, useCallback } from 'react';
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, BarElement, Title, Tooltip, Legend, Filler } from 'chart.js';
import { Line, Bar } from 'react-chartjs-2';
import { PeakAnalysisData, ChartProps, ChartConfig, ColorScheme } from '@/types/ChartTypes';

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, BarElement, Title, Tooltip, Legend, Filler);

interface PeakAnalysisChartProps extends Omit<ChartProps, 'data'> {
  data: PeakAnalysisData | any; // Allow any for flexibility during integration
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
      text: 'Peak Analysis'
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

const PeakAnalysisChart: React.FC<PeakAnalysisChartProps> = memo(({
  data,
  config = {},
  colorScheme = {},
  loading = false,
  onExport,
  onDataPointClick
}) => {
  const hourlyChartRef = useRef<ChartJS>(null);
  const weeklyChartRef = useRef<ChartJS>(null);
  const heatmapRef = useRef<HTMLDivElement>(null);

  const finalColorScheme = { ...defaultColorScheme, ...colorScheme };
  const finalConfig = { ...defaultConfig, ...config };

  // Default data structure if not provided
  const defaultData: PeakAnalysisData = {
    hourlyData: Array.from({ length: 9 }, (_, i) => ({
      x: `${i + 9}:00`,
      y: Math.floor(Math.random() * 150 + 50)
    })),
    weeklyData: [
      { x: 'Mon', y: 1250 },
      { x: 'Tue', y: 1180 },
      { x: 'Wed', y: 1320 },
      { x: 'Thu', y: 1290 },
      { x: 'Fri', y: 1150 },
      { x: 'Sat', y: 680 },
      { x: 'Sun', y: 420 }
    ],
    heatmapData: [],
    metadata: {
      totalCalls: 7290,
      peakHour: '14:00',
      peakDay: 'Wednesday',
      averageCallsPerHour: 75
    }
  };

  // Ensure data has the required structure
  const chartData = React.useMemo(() => {
    if (!data || typeof data !== 'object') {
      return defaultData;
    }
    
    // If data exists but doesn't have the expected structure, use defaults
    return {
      hourlyData: data.hourlyData || defaultData.hourlyData,
      weeklyData: data.weeklyData || defaultData.weeklyData,
      heatmapData: data.heatmapData || defaultData.heatmapData,
      metadata: data.metadata || defaultData.metadata
    };
  }, [data]);

  const handleExport = useCallback((chartRef: React.RefObject<ChartJS>, chartType: string) => {
    if (chartRef.current && onExport) {
      const canvas = chartRef.current.canvas;
      const url = canvas.toDataURL('image/png');
      
      const link = document.createElement('a');
      link.download = `peak-analysis-${chartType}-${new Date().toISOString().split('T')[0]}.png`;
      link.href = url;
      link.click();
    }
  }, [onExport]);

  const hourlyChartData = {
    labels: chartData.hourlyData.map(d => d.x),
    datasets: [{
      label: 'Hourly Call Volume',
      data: chartData.hourlyData.map(d => d.y),
      backgroundColor: finalColorScheme.primary,
      borderColor: finalColorScheme.primary.replace('0.8', '1'),
      borderWidth: 2,
      borderRadius: 4,
      borderSkipped: false
    }]
  };

  const weeklyChartData = {
    labels: chartData.weeklyData.map(d => d.x),
    datasets: [{
      label: 'Weekly Call Pattern',
      data: chartData.weeklyData.map(d => d.y),
      borderColor: finalColorScheme.secondary,
      backgroundColor: finalColorScheme.secondary.replace('0.8', '0.1'),
      tension: 0.4,
      fill: true,
      pointRadius: 6,
      pointHoverRadius: 8
    }]
  };

  const renderHeatmap = () => {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const hours = Array.from({ length: 24 }, (_, i) => i);
    
    // Generate sample heatmap data if not provided
    const heatmapData = chartData.heatmapData.length > 0 ? chartData.heatmapData : 
      days.flatMap(day => 
        hours.map(hour => ({
          day,
          hour: hour.toString(),
          value: Math.floor(Math.random() * 150),
          intensity: Math.random()
        }))
      );
    
    return (
      <div className="grid grid-cols-25 gap-1 p-4">
        <div></div>
        {hours.map(hour => (
          <div key={hour} className="text-xs text-gray-500 text-center">
            {hour % 4 === 0 ? hour : ''}
          </div>
        ))}
        
        {days.map(day => (
          <React.Fragment key={day}>
            <div className="text-xs font-medium text-gray-600 flex items-center justify-end pr-2">
              {day}
            </div>
            {hours.map(hour => {
              const heatmapPoint = heatmapData.find(d => d.day === day && parseInt(d.hour) === hour);
              const intensity = heatmapPoint?.intensity || 0;
              const value = heatmapPoint?.value || 0;
              
              return (
                <div
                  key={`${day}-${hour}`}
                  className="aspect-square rounded-sm cursor-pointer hover:scale-110 transition-transform"
                  style={{
                    backgroundColor: `rgba(168, 85, 247, ${intensity})`,
                    border: '1px solid rgba(255, 255, 255, 0.2)'
                  }}
                  title={`${day} ${hour}:00 - ${value} calls`}
                  onClick={() => onDataPointClick && onDataPointClick({ x: `${day} ${hour}:00`, y: value })}
                />
              );
            })}
          </React.Fragment>
        ))}
      </div>
    );
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96 bg-gray-50 rounded-lg">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading peak analysis...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Metadata Summary */}
      <div className="bg-white p-4 rounded-lg shadow-sm border">
        <h3 className="text-lg font-semibold mb-3">📊 Peak Analysis Summary</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
          <div className="bg-blue-50 p-3 rounded">
            <p className="text-gray-600">Total Calls</p>
            <p className="text-xl font-bold text-blue-600">{chartData.metadata.totalCalls.toLocaleString()}</p>
          </div>
          <div className="bg-purple-50 p-3 rounded">
            <p className="text-gray-600">Peak Hour</p>
            <p className="text-xl font-bold text-purple-600">{chartData.metadata.peakHour}</p>
          </div>
          <div className="bg-green-50 p-3 rounded">
            <p className="text-gray-600">Peak Day</p>
            <p className="text-xl font-bold text-green-600">{chartData.metadata.peakDay}</p>
          </div>
          <div className="bg-orange-50 p-3 rounded">
            <p className="text-gray-600">Avg/Hour</p>
            <p className="text-xl font-bold text-orange-600">{Math.round(chartData.metadata.averageCallsPerHour)}</p>
          </div>
        </div>
      </div>

      {/* Hourly and Weekly Charts */}
      <div className="grid lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between mb-4">
            <h4 className="font-semibold">Daily Peak Hours</h4>
            {onExport && (
              <button
                onClick={() => handleExport(hourlyChartRef, 'hourly')}
                className="text-sm text-blue-600 hover:text-blue-800 flex items-center gap-1"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
                Export
              </button>
            )}
          </div>
          <div className="h-64">
            <Bar
              ref={hourlyChartRef}
              data={hourlyChartData}
              options={{
                ...finalConfig,
                plugins: {
                  ...finalConfig.plugins,
                  title: { display: false, text: '' }
                }
              }}
            />
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between mb-4">
            <h4 className="font-semibold">Weekly Pattern</h4>
            {onExport && (
              <button
                onClick={() => handleExport(weeklyChartRef, 'weekly')}
                className="text-sm text-blue-600 hover:text-blue-800 flex items-center gap-1"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
                Export
              </button>
            )}
          </div>
          <div className="h-64">
            <Line
              ref={weeklyChartRef}
              data={weeklyChartData}
              options={{
                ...finalConfig,
                plugins: {
                  ...finalConfig.plugins,
                  title: { display: false, text: '' }
                }
              }}
            />
          </div>
        </div>
      </div>

      {/* Heatmap */}
      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <div className="flex items-center justify-between mb-4">
          <h4 className="font-semibold">Call Volume Heatmap (Hour × Day)</h4>
          <div className="flex items-center gap-2 text-sm text-gray-600">
            <span>Low</span>
            <div className="w-16 h-4 bg-gradient-to-r from-purple-100 to-purple-600 rounded"></div>
            <span>High</span>
          </div>
        </div>
        <div ref={heatmapRef} className="overflow-x-auto">
          {renderHeatmap()}
        </div>
      </div>
    </div>
  );
});

PeakAnalysisChart.displayName = 'PeakAnalysisChart';

export default PeakAnalysisChart;