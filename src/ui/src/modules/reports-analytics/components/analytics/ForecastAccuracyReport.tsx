import React, { useState, useEffect } from 'react';

interface ForecastData {
  accuracy: number;
  mape: number;
  trend: 'up' | 'down' | 'stable';
  changePercent: number;
}

interface ChartData {
  labels: string[];
  datasets: {
    label: string;
    data: number[];
    borderColor?: string;
    backgroundColor?: string;
    borderWidth?: number;
    borderDash?: number[];
    fill?: boolean;
  }[];
}

const ForecastAccuracyReport: React.FC = () => {
  const [chartType, setChartType] = useState<'line' | 'bar'>('line');
  const [forecastData, setForecastData] = useState<ForecastData>({
    accuracy: 87.6,
    mape: 12.4,
    trend: 'up',
    changePercent: 2.5
  });

  // Historical accuracy data
  const accuracyTrendData: ChartData = {
    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    datasets: [
      {
        label: 'Forecast Accuracy (%)',
        data: [82.1, 84.3, 86.7, 85.2, 87.1, 87.6],
        borderColor: '#3b82f6',
        backgroundColor: '#3b82f6' + '20',
        borderWidth: 2,
        fill: true
      },
      {
        label: 'Target Accuracy (%)',
        data: [85, 85, 85, 85, 85, 85],
        borderColor: '#f59e0b',
        backgroundColor: 'transparent',
        borderWidth: 2,
        borderDash: [5, 5],
        fill: false
      }
    ]
  };

  // MAPE by time periods
  const mapeData: ChartData = {
    labels: ['Morning', 'Day', 'Evening', 'Night'],
    datasets: [
      {
        label: 'MAPE (%)',
        data: [11.2, 9.8, 14.7, 16.3],
        backgroundColor: [
          '#10b981' + '80',
          '#10b981' + '80', 
          '#f59e0b' + '80',
          '#ef4444' + '80'
        ],
        borderColor: [
          '#10b981',
          '#10b981',
          '#f59e0b', 
          '#ef4444'
        ],
        borderWidth: 1
      }
    ]
  };

  const getAccuracyStatus = (accuracy: number) => {
    if (accuracy >= 90) return { status: 'excellent', icon: '', color: 'text-green-600' };
    if (accuracy >= 85) return { status: 'good', icon: '', color: 'text-blue-600' };
    if (accuracy >= 80) return { status: 'warning', icon: ' ', color: 'text-yellow-600' };
    return { status: 'critical', icon: 'W', color: 'text-red-600' };
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up': return '=È';
      case 'down': return '=É';
      case 'stable': return '¡';
      default: return '¡';
    }
  };

  const currentAccuracy = getAccuracyStatus(forecastData.accuracy);

  // Mock chart component since we don't have chart library
  const MockChart: React.FC<{ data: ChartData; type: 'line' | 'bar' }> = ({ data, type }) => (
    <div className="h-64 bg-gray-50 rounded-lg flex items-center justify-center">
      <div className="text-center">
        <div className="text-4xl mb-2">{type === 'line' ? '=Ê' : '=È'}</div>
        <div className="text-lg font-medium text-gray-700">
          {type === 'line' ? 'Forecast Accuracy Trend' : 'MAPE by Time Period'}
        </div>
        <div className="text-sm text-gray-500 mt-2">
          {type === 'line' ? 'Current: 87.6% | Target: 85%' : 'Best: 9.8% (Day) | Worst: 16.3% (Night)'}
        </div>
      </div>
    </div>
  );

  return (
    <div className="p-6 space-y-6">
      {/* Header with KPIs */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h3 className="text-lg font-medium text-gray-900">Forecast Accuracy Analysis</h3>
            <p className="text-sm text-gray-500">Quality analysis of forecasts and deviations</p>
          </div>
          
          <div className="flex bg-gray-100 rounded-lg p-1">
            <button
              onClick={() => setChartType('line')}
              className={`px-3 py-1 text-sm font-medium rounded-md transition-colors ${
                chartType === 'line'
                  ? 'bg-white text-blue-600 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              =È Trend
            </button>
            <button
              onClick={() => setChartType('bar')}
              className={`px-3 py-1 text-sm font-medium rounded-md transition-colors ${
                chartType === 'bar'
                  ? 'bg-white text-blue-600 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              =Ê MAPE
            </button>
          </div>
        </div>

        {/* KPI Cards */}
        <div className="grid grid-cols-4 gap-4 mb-6">
          <div className="text-center p-4 bg-blue-50 rounded-lg">
            <div className="text-2xl font-bold text-blue-600">
              {forecastData.accuracy.toFixed(1)}%
            </div>
            <div className="text-sm text-gray-600 flex items-center justify-center mt-1">
              <span className={`mr-1 ${currentAccuracy.color}`}>{currentAccuracy.icon}</span>
              Overall Accuracy
            </div>
          </div>
          <div className="text-center p-4 bg-orange-50 rounded-lg">
            <div className="text-2xl font-bold text-orange-600">
              {forecastData.mape.toFixed(1)}%
            </div>
            <div className="text-sm text-gray-600">MAPE</div>
          </div>
          <div className="text-center p-4 bg-green-50 rounded-lg">
            <div className="text-2xl font-bold text-green-600">+{forecastData.changePercent}%</div>
            <div className="text-sm text-gray-600 flex items-center justify-center mt-1">
              <span className="mr-1">{getTrendIcon(forecastData.trend)}</span>
              Improvement
            </div>
          </div>
          <div className="text-center p-4 bg-purple-50 rounded-lg">
            <div className="text-2xl font-bold text-purple-600">95%</div>
            <div className="text-sm text-gray-600 flex items-center justify-center mt-1">
              <span className="mr-1"><¯</span>
              Target Achieved
            </div>
          </div>
        </div>

        {/* Chart */}
        <div className="chart-container">
          <MockChart data={chartType === 'line' ? accuracyTrendData : mapeData} type={chartType} />
        </div>
      </div>

      {/* Detailed Analysis */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h4 className="font-medium text-gray-900 mb-4">Variance Analysis</h4>
          <div className="space-y-4">
            <div className="flex items-center justify-between p-3 bg-green-50 rounded-lg">
              <div>
                <p className="text-sm font-medium text-green-900">Morning Period</p>
                <p className="text-xs text-green-600">08:00 - 12:00</p>
              </div>
              <div className="text-right">
                <p className="text-lg font-bold text-green-600">11.2%</p>
                <p className="text-xs text-green-600">Excellent accuracy</p>
              </div>
            </div>
            
            <div className="flex items-center justify-between p-3 bg-blue-50 rounded-lg">
              <div>
                <p className="text-sm font-medium text-blue-900">Day Period</p>
                <p className="text-xs text-blue-600">12:00 - 18:00</p>
              </div>
              <div className="text-right">
                <p className="text-lg font-bold text-blue-600">9.8%</p>
                <p className="text-xs text-blue-600">Good accuracy</p>
              </div>
            </div>
            
            <div className="flex items-center justify-between p-3 bg-yellow-50 rounded-lg">
              <div>
                <p className="text-sm font-medium text-yellow-900">Evening Period</p>
                <p className="text-xs text-yellow-600">18:00 - 22:00</p>
              </div>
              <div className="text-right">
                <p className="text-lg font-bold text-yellow-600">14.7%</p>
                <p className="text-xs text-yellow-600">Needs improvement</p>
              </div>
            </div>
            
            <div className="flex items-center justify-between p-3 bg-red-50 rounded-lg">
              <div>
                <p className="text-sm font-medium text-red-900">Night Period</p>
                <p className="text-xs text-red-600">22:00 - 08:00</p>
              </div>
              <div className="text-right">
                <p className="text-lg font-bold text-red-600">16.3%</p>
                <p className="text-xs text-red-600">Critical</p>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h4 className="font-medium text-gray-900 mb-4">Recommendations</h4>
          <div className="space-y-4">
            <div className="p-3 bg-blue-50 rounded-lg">
              <h5 className="font-medium text-blue-900 mb-1">> Forecasting Model</h5>
              <p className="text-sm text-blue-700">
                Consider improving algorithms for evening and night periods
              </p>
            </div>
            
            <div className="p-3 bg-green-50 rounded-lg">
              <h5 className="font-medium text-green-900 mb-1">=Ê Historical Data</h5>
              <p className="text-sm text-green-700">
                Increase training data volume for non-standard periods
              </p>
            </div>
            
            <div className="p-3 bg-purple-50 rounded-lg">
              <h5 className="font-medium text-purple-900 mb-1">=ñ Monitoring</h5>
              <p className="text-sm text-purple-700">
                Implement daily accuracy control by time segments
              </p>
            </div>
            
            <div className="p-3 bg-orange-50 rounded-lg">
              <h5 className="font-medium text-orange-900 mb-1">™ Calibration</h5>
              <p className="text-sm text-orange-700">
                Weekly adjustment of model parameters
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Additional Insights */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h4 className="font-medium text-gray-900 mb-4">Performance Insights</h4>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="text-center p-4 bg-gradient-to-r from-blue-50 to-blue-100 rounded-lg">
            <div className="text-3xl mb-2">=È</div>
            <div className="text-lg font-bold text-blue-600">+5.5%</div>
            <div className="text-sm text-blue-700">Accuracy improvement over 6 months</div>
          </div>
          <div className="text-center p-4 bg-gradient-to-r from-green-50 to-green-100 rounded-lg">
            <div className="text-3xl mb-2">ñ</div>
            <div className="text-lg font-bold text-green-600">85%</div>
            <div className="text-sm text-green-700">Days above target accuracy</div>
          </div>
          <div className="text-center p-4 bg-gradient-to-r from-purple-50 to-purple-100 rounded-lg">
            <div className="text-3xl mb-2"><¯</div>
            <div className="text-lg font-bold text-purple-600">12.4%</div>
            <div className="text-sm text-purple-700">Average MAPE across all periods</div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ForecastAccuracyReport;