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
