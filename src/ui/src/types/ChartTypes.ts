export interface ChartDataPoint {
  x: number | string;
  y: number;
  label?: string;
}

export interface TimeSeriesData {
  timestamp: Date | string;
  value: number;
  confidence?: number;
}

export interface PeakAnalysisData {
  hourlyData: ChartDataPoint[];
  weeklyData: ChartDataPoint[];
  heatmapData: HeatmapDataPoint[];
  metadata: {
    totalCalls: number;
    peakHour: string;
    peakDay: string;
    averageCallsPerHour: number;
  };
}

export interface HeatmapDataPoint {
  day: string;
  hour: string;
  value: number;
  intensity: number;
}

export interface ForecastData {
  historical: TimeSeriesData[];
  forecast: TimeSeriesData[];
  confidence: {
    upper: TimeSeriesData[];
    lower: TimeSeriesData[];
  };
  modelMetrics: {
    accuracy: number;
    modelType: string;
    r2Score?: number;
    mape?: number;
  };
}

export interface ChartConfig {
  responsive: boolean;
  maintainAspectRatio: boolean;
  plugins: {
    legend: {
      position: 'top' | 'bottom' | 'left' | 'right';
      display: boolean;
    };
    title: {
      display: boolean;
      text: string;
    };
    tooltip: {
      enabled: boolean;
      mode: 'point' | 'nearest' | 'index' | 'dataset';
    };
  };
  scales?: {
    x?: {
      type: 'linear' | 'category' | 'time';
      title: {
        display: boolean;
        text: string;
      };
    };
    y?: {
      title: {
        display: boolean;
        text: string;
      };
      min?: number;
      max?: number;
    };
  };
  interaction?: {
    intersect: boolean;
    mode: 'point' | 'nearest' | 'index' | 'dataset';
  };
}

export interface ChartExportOptions {
  format: 'png' | 'jpg' | 'pdf' | 'svg';
  width: number;
  height: number;
  backgroundColor: string;
}

export interface ColorScheme {
  primary: string;
  secondary: string;
  accent: string;
  background: string;
  text: string;
  grid: string;
  confidence: string;
  forecast: string;
  actual: string;
}

export interface ChartProps {
  data: PeakAnalysisData | ForecastData;
  config?: Partial<ChartConfig>;
  colorScheme?: Partial<ColorScheme>;
  loading?: boolean;
  onExport?: (options: ChartExportOptions) => void;
  onDataPointClick?: (dataPoint: ChartDataPoint) => void;
}