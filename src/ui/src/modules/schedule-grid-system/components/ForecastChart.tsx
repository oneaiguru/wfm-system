import React, { useRef, useEffect } from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  BarElement,
} from 'chart.js';
import { Chart } from 'react-chartjs-2';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  BarElement
);

interface ForecastChartProps {
  activeView: 'forecast' | 'deviations' | 'service';
}

const ForecastChart: React.FC<ForecastChartProps> = ({ activeView }) => {
  const chartRef = useRef<ChartJS>(null);

  // Generate sample data for July 2024
  const generateData = () => {
    const labels = [];
    const forecastData = [];
    const planData = [];
    const deviationData = [];
    const serviceData = [];

    for (let day = 1; day <= 20; day++) {
      labels.push(`${day}.07`);
      
      // Generate realistic call center data
      const baseForecast = 120 + Math.sin(day * 0.3) * 20 + Math.random() * 10;
      const basePlan = 100 + Math.sin(day * 0.3) * 15 + Math.random() * 8;
      
      forecastData.push(Math.round(baseForecast));
      planData.push(Math.round(basePlan));
      deviationData.push(Math.round(baseForecast - basePlan));
      serviceData.push(Math.round(85 + Math.random() * 15)); // Service level 85-100%
    }

    return { labels, forecastData, planData, deviationData, serviceData };
  };

  const { labels, forecastData, planData, deviationData, serviceData } = generateData();

  const getChartData = () => {
    switch (activeView) {
      case 'forecast':
        return {
          labels,
          datasets: [
            {
              label: 'Прогноз',
              data: forecastData,
              borderColor: '#3b82f6',
              backgroundColor: 'rgba(59, 130, 246, 0.1)',
              tension: 0.4,
              fill: true,
            },
            {
              label: 'План',
              data: planData,
              borderColor: '#059669',
              backgroundColor: 'rgba(5, 150, 105, 0.1)',
              tension: 0.4,
              fill: true,
            },
          ],
        };
      
      case 'deviations':
        return {
          labels,
          datasets: [
            {
              label: 'Отклонения',
              data: deviationData,
              backgroundColor: deviationData.map(val => val >= 0 ? '#059669' : '#dc2626'),
              borderColor: deviationData.map(val => val >= 0 ? '#059669' : '#dc2626'),
              type: 'bar' as const,
            },
          ],
        };
      
      case 'service':
        return {
          labels,
          datasets: [
            {
              label: 'Уровень сервиса (%)',
              data: serviceData,
              borderColor: '#f59e0b',
              backgroundColor: 'rgba(245, 158, 11, 0.1)',
              tension: 0.4,
              fill: true,
            },
          ],
        };
      
      default:
        return { labels: [], datasets: [] };
    }
  };

  const options = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'top' as const,
        labels: {
          usePointStyle: true,
          font: {
            size: 12,
          },
        },
      },
      tooltip: {
        mode: 'index' as const,
        intersect: false,
        backgroundColor: 'rgba(0, 0, 0, 0.8)',
        titleColor: 'white',
        bodyColor: 'white',
        borderColor: '#e5e7eb',
        borderWidth: 1,
      },
    },
    scales: {
      x: {
        display: true,
        grid: {
          display: false,
        },
        ticks: {
          font: {
            size: 11,
          },
        },
      },
      y: {
        display: true,
        grid: {
          color: 'rgba(0, 0, 0, 0.1)',
        },
        ticks: {
          font: {
            size: 11,
          },
          callback: function(value: any) {
            if (activeView === 'service') {
              return value + '%';
            }
            return value;
          },
        },
      },
    },
    elements: {
      point: {
        radius: 3,
        hoverRadius: 5,
      },
      line: {
        borderWidth: 2,
      },
    },
    interaction: {
      mode: 'nearest' as const,
      axis: 'x' as const,
      intersect: false,
    },
  };

  useEffect(() => {
    const chart = chartRef.current;
    if (chart) {
      chart.update();
    }
  }, [activeView]);

  return (
    <div style={{ height: '100%', width: '100%' }}>
      <Chart
        ref={chartRef}
        type={activeView === 'deviations' ? 'bar' : 'line'}
        data={getChartData()}
        options={options}
      />
    </div>
  );
};

export default ForecastChart;