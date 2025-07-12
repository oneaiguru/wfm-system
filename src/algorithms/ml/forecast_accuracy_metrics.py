#!/usr/bin/env python3
"""
Forecast Accuracy Metrics - MAPE, WAPE, and Advanced Metrics
Implements comprehensive accuracy measurement that Argus lacks
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Tuple, Optional
from datetime import datetime, timedelta
from scipy import stats
import warnings

class ForecastAccuracyMetrics:
    """
    Comprehensive forecast accuracy metrics
    Goes far beyond Argus's basic measurements
    """
    
    def __init__(self):
        self.metrics_history = {}
        self.threshold_configs = {
            'excellent': {'mape': 10, 'wape': 8, 'rmse': 0.15},
            'good': {'mape': 15, 'wape': 12, 'rmse': 0.20},
            'acceptable': {'mape': 20, 'wape': 15, 'rmse': 0.25},
            'poor': {'mape': 30, 'wape': 25, 'rmse': 0.35}
        }
    
    def calculate_mape(self, actual: np.ndarray, forecast: np.ndarray) -> float:
        """
        Mean Absolute Percentage Error
        MAPE = (1/n) × Σ(|Actual - Forecast| / Actual) × 100
        """
        # Handle zero actuals
        mask = actual != 0
        if not np.any(mask):
            return np.inf
        
        mape = np.mean(np.abs((actual[mask] - forecast[mask]) / actual[mask])) * 100
        return round(mape, 2)
    
    def calculate_wape(self, actual: np.ndarray, forecast: np.ndarray) -> float:
        """
        Weighted Absolute Percentage Error
        WAPE = Σ(|Actual - Forecast|) / Σ(Actual) × 100
        Better than MAPE for intermittent demand
        """
        total_actual = np.sum(actual)
        if total_actual == 0:
            return np.inf
        
        wape = np.sum(np.abs(actual - forecast)) / total_actual * 100
        return round(wape, 2)
    
    def calculate_rmse(self, actual: np.ndarray, forecast: np.ndarray) -> float:
        """Root Mean Square Error"""
        rmse = np.sqrt(np.mean((actual - forecast) ** 2))
        return round(rmse, 2)
    
    def calculate_mae(self, actual: np.ndarray, forecast: np.ndarray) -> float:
        """Mean Absolute Error"""
        mae = np.mean(np.abs(actual - forecast))
        return round(mae, 2)
    
    def calculate_mase(self, actual: np.ndarray, forecast: np.ndarray, 
                      seasonal_period: int = 1) -> float:
        """
        Mean Absolute Scaled Error
        Scale-independent metric, good for comparing across different series
        """
        n = len(actual)
        if n <= seasonal_period:
            return np.inf
        
        # Calculate naive forecast error (seasonal naive)
        naive_errors = actual[seasonal_period:] - actual[:-seasonal_period]
        scale = np.mean(np.abs(naive_errors))
        
        if scale == 0:
            return np.inf
        
        errors = actual - forecast
        mase = np.mean(np.abs(errors)) / scale
        return round(mase, 2)
    
    def calculate_tracking_signal(self, actual: np.ndarray, forecast: np.ndarray) -> float:
        """
        Tracking Signal = Cumulative Error / MAD
        Detects bias in forecasts
        """
        errors = actual - forecast
        cumulative_error = np.sum(errors)
        mad = np.mean(np.abs(errors))
        
        if mad == 0:
            return 0
        
        tracking_signal = cumulative_error / mad
        return round(tracking_signal, 2)
    
    def calculate_directional_accuracy(self, actual: np.ndarray, forecast: np.ndarray) -> float:
        """
        Percentage of times the forecast correctly predicted direction of change
        Important for trend detection
        """
        if len(actual) < 2:
            return 0
        
        actual_direction = np.diff(actual) > 0
        forecast_direction = np.diff(forecast) > 0
        
        correct_direction = np.sum(actual_direction == forecast_direction)
        total_changes = len(actual_direction)
        
        if total_changes == 0:
            return 0
        
        return round((correct_direction / total_changes) * 100, 2)
    
    def calculate_forecast_bias(self, actual: np.ndarray, forecast: np.ndarray) -> Dict[str, float]:
        """
        Comprehensive bias analysis
        Argus doesn't do this level of analysis
        """
        errors = forecast - actual
        
        bias_metrics = {
            'mean_bias': round(np.mean(errors), 2),
            'median_bias': round(np.median(errors), 2),
            'bias_percentage': round((np.mean(errors) / np.mean(actual)) * 100, 2),
            'over_forecast_pct': round((np.sum(errors > 0) / len(errors)) * 100, 2),
            'under_forecast_pct': round((np.sum(errors < 0) / len(errors)) * 100, 2)
        }
        
        # Bias classification
        if abs(bias_metrics['bias_percentage']) < 5:
            bias_metrics['bias_level'] = 'unbiased'
        elif bias_metrics['bias_percentage'] > 0:
            bias_metrics['bias_level'] = 'over-forecasting'
        else:
            bias_metrics['bias_level'] = 'under-forecasting'
        
        return bias_metrics
    
    def calculate_interval_accuracy(self, actual: np.ndarray, 
                                   lower_bound: np.ndarray, 
                                   upper_bound: np.ndarray) -> Dict[str, float]:
        """
        Prediction interval accuracy metrics
        """
        within_interval = np.sum((actual >= lower_bound) & (actual <= upper_bound))
        coverage = (within_interval / len(actual)) * 100
        
        # Average interval width
        avg_width = np.mean(upper_bound - lower_bound)
        
        # Interval score (penalizes wide intervals)
        interval_score = avg_width + (2 / 0.05) * (
            np.mean(np.maximum(0, lower_bound - actual)) +
            np.mean(np.maximum(0, actual - upper_bound))
        )
        
        return {
            'coverage_percentage': round(coverage, 2),
            'average_interval_width': round(avg_width, 2),
            'interval_score': round(interval_score, 2),
            'sharpness': round(1 / avg_width if avg_width > 0 else 0, 4)
        }
    
    def calculate_by_time_period(self, actual: pd.Series, forecast: pd.Series) -> Dict[str, Dict]:
        """
        Calculate accuracy by different time periods
        Identifies when forecasts are most/least accurate
        """
        if not isinstance(actual.index, pd.DatetimeIndex):
            warnings.warn("Series should have DatetimeIndex for time period analysis")
            return {}
        
        periods = {
            'hour_of_day': actual.index.hour,
            'day_of_week': actual.index.dayofweek,
            'week_of_month': (actual.index.day - 1) // 7 + 1,
            'month': actual.index.month
        }
        
        period_accuracy = {}
        
        for period_name, period_values in periods.items():
            period_metrics = {}
            unique_periods = np.unique(period_values)
            
            for period in unique_periods:
                mask = period_values == period
                if np.sum(mask) > 0:
                    period_actual = actual[mask].values
                    period_forecast = forecast[mask].values
                    
                    period_metrics[int(period)] = {
                        'mape': self.calculate_mape(period_actual, period_forecast),
                        'count': int(np.sum(mask))
                    }
            
            period_accuracy[period_name] = period_metrics
        
        return period_accuracy
    
    def calculate_all_metrics(self, actual: np.ndarray, forecast: np.ndarray,
                            lower_bound: Optional[np.ndarray] = None,
                            upper_bound: Optional[np.ndarray] = None) -> Dict[str, any]:
        """
        Calculate comprehensive set of accuracy metrics
        This is what makes us superior to Argus
        """
        metrics = {
            # Basic metrics
            'mape': self.calculate_mape(actual, forecast),
            'wape': self.calculate_wape(actual, forecast),
            'rmse': self.calculate_rmse(actual, forecast),
            'mae': self.calculate_mae(actual, forecast),
            
            # Advanced metrics
            'mase': self.calculate_mase(actual, forecast),
            'tracking_signal': self.calculate_tracking_signal(actual, forecast),
            'directional_accuracy': self.calculate_directional_accuracy(actual, forecast),
            
            # Bias analysis
            'bias_analysis': self.calculate_forecast_bias(actual, forecast),
            
            # Statistical tests
            'is_biased': self._test_bias_significance(actual, forecast),
            
            # Performance classification
            'performance_level': self._classify_performance(
                self.calculate_mape(actual, forecast),
                self.calculate_wape(actual, forecast)
            )
        }
        
        # Add interval metrics if bounds provided
        if lower_bound is not None and upper_bound is not None:
            metrics['interval_accuracy'] = self.calculate_interval_accuracy(
                actual, lower_bound, upper_bound
            )
        
        # Add sample size for context
        metrics['sample_size'] = len(actual)
        metrics['timestamp'] = datetime.now().isoformat()
        
        return metrics
    
    def _test_bias_significance(self, actual: np.ndarray, forecast: np.ndarray) -> bool:
        """
        Statistical test for forecast bias
        Uses t-test to determine if bias is significant
        """
        errors = forecast - actual
        
        # One-sample t-test against zero mean
        t_stat, p_value = stats.ttest_1samp(errors, 0)
        
        # Significant bias if p-value < 0.05
        return p_value < 0.05
    
    def _classify_performance(self, mape: float, wape: float) -> str:
        """Classify forecast performance level"""
        avg_error = (mape + wape) / 2
        
        if avg_error <= 10:
            return 'excellent'
        elif avg_error <= 15:
            return 'good'
        elif avg_error <= 20:
            return 'acceptable'
        elif avg_error <= 30:
            return 'poor'
        else:
            return 'unacceptable'
    
    def track_accuracy_over_time(self, model_id: str, metrics: Dict):
        """
        Track accuracy metrics over time for continuous improvement
        This enables learning that Argus lacks
        """
        if model_id not in self.metrics_history:
            self.metrics_history[model_id] = []
        
        self.metrics_history[model_id].append(metrics)
        
        # Keep only recent history (last 100 forecasts)
        if len(self.metrics_history[model_id]) > 100:
            self.metrics_history[model_id].pop(0)
    
    def get_accuracy_trends(self, model_id: str) -> Dict[str, any]:
        """Analyze accuracy trends over time"""
        if model_id not in self.metrics_history or len(self.metrics_history[model_id]) < 2:
            return {'status': 'insufficient_data'}
        
        history = self.metrics_history[model_id]
        
        # Extract metric series
        mape_series = [h['mape'] for h in history if 'mape' in h]
        wape_series = [h['wape'] for h in history if 'wape' in h]
        
        # Calculate trends
        trends = {
            'mape_trend': self._calculate_trend(mape_series),
            'wape_trend': self._calculate_trend(wape_series),
            'current_mape': mape_series[-1] if mape_series else None,
            'current_wape': wape_series[-1] if wape_series else None,
            'avg_mape_30': np.mean(mape_series[-30:]) if len(mape_series) >= 30 else np.mean(mape_series),
            'avg_wape_30': np.mean(wape_series[-30:]) if len(wape_series) >= 30 else np.mean(wape_series),
            'improvement_rate': self._calculate_improvement_rate(mape_series),
            'stability_score': self._calculate_stability_score(mape_series)
        }
        
        return trends
    
    def _calculate_trend(self, series: List[float]) -> str:
        """Calculate trend direction"""
        if len(series) < 3:
            return 'unknown'
        
        # Simple linear regression
        x = np.arange(len(series))
        slope, _ = np.polyfit(x, series, 1)
        
        if slope < -0.1:
            return 'improving'
        elif slope > 0.1:
            return 'deteriorating'
        else:
            return 'stable'
    
    def _calculate_improvement_rate(self, series: List[float]) -> float:
        """Calculate rate of improvement"""
        if len(series) < 10:
            return 0
        
        early_avg = np.mean(series[:10])
        recent_avg = np.mean(series[-10:])
        
        if early_avg == 0:
            return 0
        
        improvement = ((early_avg - recent_avg) / early_avg) * 100
        return round(improvement, 2)
    
    def _calculate_stability_score(self, series: List[float]) -> float:
        """
        Calculate stability score (0-100)
        Lower variance = higher stability
        """
        if len(series) < 5:
            return 50  # Default
        
        cv = np.std(series) / np.mean(series) if np.mean(series) > 0 else 1
        stability = max(0, min(100, 100 * (1 - cv)))
        return round(stability, 2)


class IQROutlierDetection:
    """
    Interquartile Range outlier detection for data cleaning
    Critical for accurate forecasting - Argus doesn't do this properly
    """
    
    def __init__(self):
        self.outlier_history = {}
        self.treatment_configs = {
            'aggressive': {'iqr_multiplier': 1.5, 'min_quartile_size': 10},
            'moderate': {'iqr_multiplier': 2.0, 'min_quartile_size': 20},
            'conservative': {'iqr_multiplier': 3.0, 'min_quartile_size': 30}
        }
    
    def detect_outliers(self, data: np.ndarray, 
                       method: str = 'moderate',
                       return_stats: bool = True) -> Dict[str, any]:
        """
        Detect outliers using IQR method
        Returns indices of outliers and optionally statistics
        """
        if len(data) < 4:
            return {'outliers': [], 'stats': None}
        
        config = self.treatment_configs.get(method, self.treatment_configs['moderate'])
        
        # Calculate quartiles
        q1 = np.percentile(data, 25)
        q3 = np.percentile(data, 75)
        iqr = q3 - q1
        
        # Calculate bounds
        multiplier = config['iqr_multiplier']
        lower_bound = q1 - multiplier * iqr
        upper_bound = q3 + multiplier * iqr
        
        # Extreme outliers (3x IQR)
        extreme_lower = q1 - 3 * iqr
        extreme_upper = q3 + 3 * iqr
        
        # Find outliers
        outlier_mask = (data < lower_bound) | (data > upper_bound)
        extreme_mask = (data < extreme_lower) | (data > extreme_upper)
        
        outlier_indices = np.where(outlier_mask)[0]
        extreme_indices = np.where(extreme_mask)[0]
        
        result = {
            'outlier_indices': outlier_indices.tolist(),
            'extreme_indices': extreme_indices.tolist(),
            'outlier_count': len(outlier_indices),
            'extreme_count': len(extreme_indices),
            'outlier_percentage': (len(outlier_indices) / len(data)) * 100
        }
        
        if return_stats:
            result['stats'] = {
                'q1': round(q1, 2),
                'q3': round(q3, 2),
                'iqr': round(iqr, 2),
                'lower_bound': round(lower_bound, 2),
                'upper_bound': round(upper_bound, 2),
                'extreme_lower': round(extreme_lower, 2),
                'extreme_upper': round(extreme_upper, 2),
                'median': round(np.median(data), 2),
                'mean': round(np.mean(data), 2),
                'std': round(np.std(data), 2)
            }
        
        return result
    
    def clean_outliers(self, data: np.ndarray, 
                       method: str = 'moderate',
                       treatment: str = 'winsorize') -> np.ndarray:
        """
        Clean outliers from data
        Treatment options: remove, winsorize, interpolate
        """
        detection_result = self.detect_outliers(data, method, return_stats=False)
        outlier_indices = detection_result['outlier_indices']
        
        if not outlier_indices:
            return data.copy()
        
        cleaned_data = data.copy()
        
        if treatment == 'remove':
            # Mark as NaN for removal
            cleaned_data[outlier_indices] = np.nan
            cleaned_data = cleaned_data[~np.isnan(cleaned_data)]
            
        elif treatment == 'winsorize':
            # Cap at bounds
            stats = self.detect_outliers(data, method, return_stats=True)['stats']
            cleaned_data = np.clip(cleaned_data, stats['lower_bound'], stats['upper_bound'])
            
        elif treatment == 'interpolate':
            # Replace with interpolated values
            cleaned_data[outlier_indices] = np.nan
            # Simple linear interpolation
            nans = np.isnan(cleaned_data)
            x = lambda z: z.nonzero()[0]
            cleaned_data[nans] = np.interp(x(nans), x(~nans), cleaned_data[~nans])
        
        return cleaned_data
    
    def analyze_outlier_patterns(self, data: pd.Series) -> Dict[str, any]:
        """
        Analyze patterns in outliers over time
        Helps identify systematic issues vs random spikes
        """
        if not isinstance(data.index, pd.DatetimeIndex):
            warnings.warn("Series should have DatetimeIndex for pattern analysis")
            return {}
        
        outliers = self.detect_outliers(data.values)
        outlier_indices = outliers['outlier_indices']
        
        if not outlier_indices:
            return {'pattern': 'no_outliers'}
        
        # Analyze temporal patterns
        outlier_dates = data.index[outlier_indices]
        
        patterns = {
            'total_outliers': len(outlier_indices),
            'outlier_percentage': outliers['outlier_percentage'],
            'hour_distribution': outlier_dates.hour.value_counts().to_dict(),
            'day_distribution': outlier_dates.dayofweek.value_counts().to_dict(),
            'clustering': self._analyze_clustering(outlier_indices),
            'trend': self._analyze_outlier_trend(data, outlier_indices)
        }
        
        # Identify pattern type
        if patterns['clustering']['max_cluster_size'] > 5:
            patterns['pattern_type'] = 'clustered_events'
        elif len(patterns['hour_distribution']) <= 3:
            patterns['pattern_type'] = 'time_specific'
        elif patterns['trend'] == 'increasing':
            patterns['pattern_type'] = 'deteriorating_quality'
        else:
            patterns['pattern_type'] = 'random'
        
        return patterns
    
    def _analyze_clustering(self, indices: List[int]) -> Dict[str, any]:
        """Analyze if outliers cluster together"""
        if len(indices) < 2:
            return {'max_cluster_size': 1, 'num_clusters': 1}
        
        # Find clusters (consecutive or near-consecutive indices)
        clusters = []
        current_cluster = [indices[0]]
        
        for i in range(1, len(indices)):
            if indices[i] - indices[i-1] <= 2:  # Within 2 positions
                current_cluster.append(indices[i])
            else:
                clusters.append(current_cluster)
                current_cluster = [indices[i]]
        
        clusters.append(current_cluster)
        
        return {
            'max_cluster_size': max(len(c) for c in clusters),
            'num_clusters': len(clusters),
            'avg_cluster_size': np.mean([len(c) for c in clusters])
        }
    
    def _analyze_outlier_trend(self, data: pd.Series, outlier_indices: List[int]) -> str:
        """Analyze if outliers are becoming more frequent"""
        if len(data) < 100 or len(outlier_indices) < 5:
            return 'insufficient_data'
        
        # Split data in half and compare outlier rates
        mid_point = len(data) // 2
        first_half_outliers = sum(1 for idx in outlier_indices if idx < mid_point)
        second_half_outliers = sum(1 for idx in outlier_indices if idx >= mid_point)
        
        first_rate = first_half_outliers / mid_point
        second_rate = second_half_outliers / (len(data) - mid_point)
        
        if second_rate > first_rate * 1.5:
            return 'increasing'
        elif second_rate < first_rate * 0.7:
            return 'decreasing'
        else:
            return 'stable'