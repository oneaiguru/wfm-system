"""
ML Ensemble Models for WFM Forecasting

This module implements Prophet, ARIMA, and LightGBM models combined in an ensemble
for enhanced forecast accuracy targeting >75% MFA (Month Forecast Accuracy).

The ensemble combines:
- Prophet: Time series forecasting with seasonality and trend detection
- ARIMA: Statistical time series modeling with seasonal components
- LightGBM: Gradient boosting with engineered temporal features

Integration with Enhanced Erlang C:
- Predictions feed into staffing calculations
- Supports 15-minute interval granularity
- Handles enterprise scale (5+ years historical data)
"""

import math
import numpy as np
import pandas as pd
from typing import Dict, List, Tuple, Optional, Union
from dataclasses import dataclass
from datetime import datetime, timedelta
import warnings
warnings.filterwarnings('ignore')

# External dependencies that need to be installed
try:
    from prophet import Prophet
    from prophet.serialize import model_to_json, model_from_json
    PROPHET_AVAILABLE = True
except ImportError:
    PROPHET_AVAILABLE = False

try:
    from pmdarima import auto_arima
    from pmdarima.model_selection import train_test_split
    from statsmodels.tsa.stattools import adfuller
    ARIMA_AVAILABLE = True
except ImportError:
    ARIMA_AVAILABLE = False

try:
    import lightgbm as lgb
    LIGHTGBM_AVAILABLE = True
except ImportError:
    LIGHTGBM_AVAILABLE = False


@dataclass
class EnsembleWeights:
    """Weights for ensemble combination."""
    prophet: float = 0.4
    arima: float = 0.3
    lightgbm: float = 0.3
    
    def __post_init__(self):
        """Normalize weights to sum to 1."""
        total = self.prophet + self.arima + self.lightgbm
        if total > 0:
            self.prophet /= total
            self.arima /= total
            self.lightgbm /= total


@dataclass
class ForecastResult:
    """Result from individual or ensemble forecasting."""
    predictions: np.ndarray
    confidence_intervals: Optional[Tuple[np.ndarray, np.ndarray]] = None
    model_metrics: Optional[Dict[str, float]] = None
    feature_importance: Optional[Dict[str, float]] = None


class ProphetModelWrapper:
    """Prophet model wrapper with WFM-specific configuration."""
    
    def __init__(self, seasonality_mode: str = 'multiplicative'):
        """Initialize Prophet model with WFM configurations.
        
        Args:
            seasonality_mode: 'multiplicative' or 'additive' seasonality
        """
        if not PROPHET_AVAILABLE:
            raise ImportError("Prophet library not available. Install with: pip install prophet")
        
        self.seasonality_mode = seasonality_mode
        self.model = None
        self.fitted = False
        
        # WFM-specific configuration
        self.config = {
            'growth': 'linear',
            'seasonality_mode': seasonality_mode,
            'seasonality_prior_scale': 10.0,
            'holidays_prior_scale': 10.0,
            'changepoint_prior_scale': 0.05,
            'interval_width': 0.95,
            'daily_seasonality': True,
            'weekly_seasonality': True,
            'yearly_seasonality': True
        }
    
    def initialize_prophet_model(self, **kwargs) -> None:
        """Initialize Prophet model with configuration."""
        config = {**self.config, **kwargs}
        self.model = Prophet(**config)
        
        # Add custom seasonalities for WFM patterns
        self.model.add_seasonality(
            name='monthly', 
            period=30.5, 
            fourier_order=5
        )
        self.model.add_seasonality(
            name='quarterly',
            period=91.25,
            fourier_order=3
        )
    
    def train_prophet(self, historical_data: pd.DataFrame, holidays: Optional[pd.DataFrame] = None) -> None:
        """Train Prophet model on historical data.
        
        Args:
            historical_data: DataFrame with 'ds' (datetime) and 'y' (values) columns
            holidays: Optional DataFrame with holiday information
        """
        if self.model is None:
            self.initialize_prophet_model()
        
        # Add holidays if provided
        if holidays is not None:
            self.model.add_country_holidays(country_name='US')
        
        # Fit the model
        self.model.fit(historical_data)
        self.fitted = True
    
    def predict_prophet(self, periods: int, freq: str = '15min') -> ForecastResult:
        """Generate Prophet predictions.
        
        Args:
            periods: Number of future periods to predict
            freq: Frequency of predictions ('15min', '30min', '1H', etc.)
            
        Returns:
            ForecastResult with predictions and confidence intervals
        """
        if not self.fitted:
            raise ValueError("Model must be trained before prediction")
        
        # Create future dataframe
        future = self.model.make_future_dataframe(periods=periods, freq=freq)
        
        # Generate forecast
        forecast = self.model.predict(future)
        
        # Extract predictions and confidence intervals
        predictions = forecast['yhat'].values[-periods:]
        lower_ci = forecast['yhat_lower'].values[-periods:]
        upper_ci = forecast['yhat_upper'].values[-periods:]
        
        return ForecastResult(
            predictions=predictions,
            confidence_intervals=(lower_ci, upper_ci)
        )
    
    def extract_prophet_components(self) -> Dict[str, np.ndarray]:
        """Extract Prophet model components (trend, seasonality, etc.).
        
        Returns:
            Dictionary of component arrays
        """
        if not self.fitted:
            raise ValueError("Model must be trained before extracting components")
        
        # Make prediction on training data to get components
        forecast = self.model.predict(self.model.history)
        
        components = {
            'trend': forecast['trend'].values,
            'weekly': forecast['weekly'].values,
            'yearly': forecast['yearly'].values
        }
        
        if 'monthly' in forecast.columns:
            components['monthly'] = forecast['monthly'].values
        
        return components


class ARIMAModelWrapper:
    """ARIMA model wrapper with auto-selection and seasonality."""
    
    def __init__(self):
        """Initialize ARIMA model wrapper."""
        if not ARIMA_AVAILABLE:
            raise ImportError("pmdarima library not available. Install with: pip install pmdarima")
        
        self.model = None
        self.fitted = False
        
        # ARIMA configuration for WFM (15-minute intervals)
        self.config = {
            'max_p': 5,
            'max_d': 2,
            'max_q': 5,
            'seasonal': True,
            'm': 96,  # 96 intervals per day (15-min)
            'stepwise': True,
            'trace': False,
            'suppress_warnings': True
        }
    
    def validate_stationarity(self, data: pd.Series) -> Dict[str, float]:
        """Validate stationarity using Augmented Dickey-Fuller test.
        
        Args:
            data: Time series data
            
        Returns:
            Dictionary with test statistics
        """
        result = adfuller(data.dropna())
        return {
            'adf_statistic': result[0],
            'p_value': result[1],
            'critical_values': result[4],
            'is_stationary': result[1] < 0.05
        }
    
    def auto_arima_selection(self, data: pd.Series, **kwargs) -> None:
        """Automatically select ARIMA parameters.
        
        Args:
            data: Time series data for parameter selection
            **kwargs: Additional parameters for auto_arima
        """
        config = {**self.config, **kwargs}
        
        # Automatically select best ARIMA parameters
        self.model = auto_arima(
            data,
            start_p=0, start_q=0,
            max_p=config['max_p'],
            max_d=config['max_d'], 
            max_q=config['max_q'],
            seasonal=config['seasonal'],
            m=config['m'],
            stepwise=config['stepwise'],
            trace=config['trace'],
            suppress_warnings=config['suppress_warnings']
        )
        
        self.fitted = True
    
    def train_arima_model(self, data: pd.Series, order: Optional[Tuple] = None, 
                         seasonal_order: Optional[Tuple] = None) -> None:
        """Train ARIMA model with specified or auto-selected parameters.
        
        Args:
            data: Training data
            order: ARIMA order (p, d, q) - if None, auto-select
            seasonal_order: Seasonal ARIMA order - if None, auto-select
        """
        if order is None or seasonal_order is None:
            self.auto_arima_selection(data)
        else:
            from pmdarima.arima import ARIMA
            self.model = ARIMA(order=order, seasonal_order=seasonal_order)
            self.model.fit(data)
            self.fitted = True
    
    def predict_arima(self, steps_ahead: int) -> ForecastResult:
        """Generate ARIMA predictions.
        
        Args:
            steps_ahead: Number of steps to forecast
            
        Returns:
            ForecastResult with predictions and confidence intervals
        """
        if not self.fitted:
            raise ValueError("Model must be trained before prediction")
        
        # Generate forecast
        forecast, conf_int = self.model.predict(n_periods=steps_ahead, return_conf_int=True)
        
        return ForecastResult(
            predictions=forecast,
            confidence_intervals=(conf_int[:, 0], conf_int[:, 1])
        )


class LightGBMModelWrapper:
    """LightGBM model wrapper with temporal feature engineering."""
    
    def __init__(self):
        """Initialize LightGBM model wrapper."""
        if not LIGHTGBM_AVAILABLE:
            raise ImportError("LightGBM library not available. Install with: pip install lightgbm")
        
        self.model = None
        self.fitted = False
        self.feature_columns = []
        
        # LightGBM configuration
        self.config = {
            'objective': 'regression',
            'metric': 'rmse',
            'boosting_type': 'gbdt',
            'num_leaves': 31,
            'learning_rate': 0.05,
            'feature_fraction': 0.9,
            'bagging_fraction': 0.8,
            'bagging_freq': 5,
            'verbose': -1
        }
    
    def prepare_features(self, time_series_data: pd.DataFrame) -> pd.DataFrame:
        """Prepare features for LightGBM training.
        
        Args:
            time_series_data: DataFrame with datetime index and target values
            
        Returns:
            DataFrame with engineered features
        """
        df = time_series_data.copy()
        
        # Ensure datetime index
        if not isinstance(df.index, pd.DatetimeIndex):
            df.index = pd.to_datetime(df.index)
        
        # Temporal features
        df['hour_of_day'] = df.index.hour
        df['day_of_week'] = df.index.dayofweek
        df['day_of_month'] = df.index.day
        df['week_of_year'] = df.index.isocalendar().week
        df['month'] = df.index.month
        df['quarter'] = df.index.quarter
        
        # Binary features
        df['is_weekend'] = (df.index.dayofweek >= 5).astype(int)
        df['is_holiday'] = self._detect_holidays(df.index)
        
        # Lag features
        target_col = df.columns[0] if 'target' not in df.columns else 'target'
        df['lag_1_day'] = df[target_col].shift(96)  # 1 day ago (96 intervals)
        df['lag_1_week'] = df[target_col].shift(96 * 7)  # 1 week ago
        df['lag_2_weeks'] = df[target_col].shift(96 * 14)  # 2 weeks ago
        df['lag_1_month'] = df[target_col].shift(96 * 30)  # 1 month ago
        
        # Rolling features
        df['rolling_mean_24h'] = df[target_col].rolling(window=96, min_periods=1).mean()
        df['rolling_std_24h'] = df[target_col].rolling(window=96, min_periods=1).std()
        df['rolling_mean_7d'] = df[target_col].rolling(window=96*7, min_periods=1).mean()
        df['rolling_std_7d'] = df[target_col].rolling(window=96*7, min_periods=1).std()
        
        # Interaction features
        df['hour_dayofweek'] = df['hour_of_day'] * df['day_of_week']
        df['hour_weekend'] = df['hour_of_day'] * df['is_weekend']
        
        # Fill NaN values
        df.fillna(method='ffill', inplace=True)
        df.fillna(method='bfill', inplace=True)
        
        return df
    
    def _detect_holidays(self, date_index: pd.DatetimeIndex) -> pd.Series:
        """Detect holidays in date index."""
        # Simple holiday detection - can be enhanced with external holiday data
        holidays = pd.Series(0, index=date_index)
        
        # New Year's Day
        holidays[date_index.month == 1] = 1
        holidays[date_index.day == 1] = 1
        
        # Christmas
        holidays[(date_index.month == 12) & (date_index.day == 25)] = 1
        
        # Independence Day
        holidays[(date_index.month == 7) & (date_index.day == 4)] = 1
        
        return holidays
    
    def train_lightgbm_model(self, features: pd.DataFrame, target: pd.Series) -> None:
        """Train LightGBM model on features and target.
        
        Args:
            features: DataFrame with engineered features
            target: Target values for training
        """
        # Prepare feature matrix
        feature_cols = [col for col in features.columns if col not in ['target']]
        X = features[feature_cols]
        y = target
        
        # Remove any remaining NaN values
        mask = ~(X.isna().any(axis=1) | y.isna())
        X = X[mask]
        y = y[mask]
        
        # Store feature columns for prediction
        self.feature_columns = feature_cols
        
        # Create LightGBM dataset
        train_data = lgb.Dataset(X, label=y)
        
        # Train model
        self.model = lgb.train(
            self.config,
            train_data,
            num_boost_round=100,
            valid_sets=[train_data],
            callbacks=[lgb.early_stopping(stopping_rounds=10), lgb.log_evaluation(0)]
        )
        
        self.fitted = True
    
    def predict_lightgbm(self, future_features: pd.DataFrame) -> ForecastResult:
        """Generate LightGBM predictions.
        
        Args:
            future_features: DataFrame with future features
            
        Returns:
            ForecastResult with predictions and feature importance
        """
        if not self.fitted:
            raise ValueError("Model must be trained before prediction")
        
        # Select feature columns
        X = future_features[self.feature_columns]
        
        # Generate predictions
        predictions = self.model.predict(X)
        
        # Get feature importance
        feature_importance = dict(zip(
            self.feature_columns,
            self.model.feature_importance(importance_type='gain')
        ))
        
        return ForecastResult(
            predictions=predictions,
            feature_importance=feature_importance
        )
    
    def feature_importance_analysis(self) -> Dict[str, float]:
        """Analyze feature importance from trained model.
        
        Returns:
            Dictionary of feature importance scores
        """
        if not self.fitted:
            raise ValueError("Model must be trained before feature importance analysis")
        
        importance_scores = self.model.feature_importance(importance_type='gain')
        return dict(zip(self.feature_columns, importance_scores))


class MLEnsembleForecaster:
    """Main ensemble forecaster combining Prophet, ARIMA, and LightGBM."""
    
    def __init__(self, weights: Optional[EnsembleWeights] = None):
        """Initialize ensemble forecaster.
        
        Args:
            weights: Ensemble weights (default: equal weighting)
        """
        self.weights = weights or EnsembleWeights()
        
        # Initialize individual models
        self.prophet_model = ProphetModelWrapper()
        self.arima_model = ARIMAModelWrapper()
        self.lightgbm_model = LightGBMModelWrapper()
        
        # Training state
        self.trained = False
        self.training_data = None
        self.model_metrics = {}
    
    def train_ensemble(self, historical_data: pd.DataFrame, 
                      target_column: str = 'target',
                      validation_split: float = 0.2) -> Dict[str, float]:
        """Train all ensemble models on historical data.
        
        Args:
            historical_data: DataFrame with datetime index and target values
            target_column: Name of target column
            validation_split: Fraction of data for validation
            
        Returns:
            Dictionary with individual model metrics
        """
        # Prepare data
        df = historical_data.copy()
        if not isinstance(df.index, pd.DatetimeIndex):
            df.index = pd.to_datetime(df.index)
        
        # Split data for validation
        split_point = int(len(df) * (1 - validation_split))
        train_data = df.iloc[:split_point]
        val_data = df.iloc[split_point:]
        
        self.training_data = train_data
        
        # Train Prophet
        prophet_data = train_data.reset_index()
        prophet_data.columns = ['ds', 'y']
        self.prophet_model.train_prophet(prophet_data)
        
        # Train ARIMA
        self.arima_model.train_arima_model(train_data[target_column])
        
        # Train LightGBM
        features = self.lightgbm_model.prepare_features(train_data)
        self.lightgbm_model.train_lightgbm_model(features, train_data[target_column])
        
        # Validate models
        self.model_metrics = self._validate_models(val_data, target_column)
        
        self.trained = True
        return self.model_metrics
    
    def _validate_models(self, validation_data: pd.DataFrame, target_column: str) -> Dict[str, float]:
        """Validate individual models on validation data."""
        metrics = {}
        
        val_periods = len(validation_data)
        actual_values = validation_data[target_column].values
        
        # Prophet validation
        try:
            prophet_result = self.prophet_model.predict_prophet(val_periods)
            prophet_mae = np.mean(np.abs(prophet_result.predictions - actual_values))
            metrics['prophet_mae'] = prophet_mae
        except Exception as e:
            metrics['prophet_mae'] = float('inf')
        
        # ARIMA validation
        try:
            arima_result = self.arima_model.predict_arima(val_periods)
            arima_mae = np.mean(np.abs(arima_result.predictions - actual_values))
            metrics['arima_mae'] = arima_mae
        except Exception as e:
            metrics['arima_mae'] = float('inf')
        
        # LightGBM validation
        try:
            val_features = self.lightgbm_model.prepare_features(validation_data)
            lgb_result = self.lightgbm_model.predict_lightgbm(val_features)
            lgb_mae = np.mean(np.abs(lgb_result.predictions - actual_values))
            metrics['lightgbm_mae'] = lgb_mae
        except Exception as e:
            metrics['lightgbm_mae'] = float('inf')
        
        return metrics
    
    def optimize_ensemble_weights(self, predictions: Dict[str, np.ndarray], 
                                 actuals: np.ndarray) -> EnsembleWeights:
        """Optimize ensemble weights based on prediction accuracy.
        
        Args:
            predictions: Dictionary of model predictions
            actuals: Actual values for optimization
            
        Returns:
            Optimized ensemble weights
        """
        from scipy.optimize import minimize
        
        def objective(weights):
            w_prophet, w_arima, w_lightgbm = weights
            # Ensure weights sum to 1
            total = w_prophet + w_arima + w_lightgbm
            if total == 0:
                return float('inf')
            w_prophet /= total
            w_arima /= total
            w_lightgbm /= total
            
            # Calculate ensemble prediction
            ensemble_pred = (w_prophet * predictions['prophet'] + 
                           w_arima * predictions['arima'] + 
                           w_lightgbm * predictions['lightgbm'])
            
            # Return mean absolute error
            return np.mean(np.abs(ensemble_pred - actuals))
        
        # Initial weights
        x0 = [self.weights.prophet, self.weights.arima, self.weights.lightgbm]
        
        # Constraints: weights must be non-negative
        bounds = [(0, 1), (0, 1), (0, 1)]
        
        # Optimization
        result = minimize(objective, x0, method='L-BFGS-B', bounds=bounds)
        
        if result.success:
            optimal_weights = result.x
            total = sum(optimal_weights)
            if total > 0:
                return EnsembleWeights(
                    prophet=optimal_weights[0] / total,
                    arima=optimal_weights[1] / total,
                    lightgbm=optimal_weights[2] / total
                )
        
        return self.weights
    
    def weighted_ensemble_prediction(self, prophet_pred: np.ndarray, 
                                   arima_pred: np.ndarray, 
                                   lgb_pred: np.ndarray,
                                   weights: Optional[EnsembleWeights] = None) -> np.ndarray:
        """Combine predictions using weighted ensemble.
        
        Args:
            prophet_pred: Prophet predictions
            arima_pred: ARIMA predictions
            lgb_pred: LightGBM predictions
            weights: Ensemble weights (default: use trained weights)
            
        Returns:
            Weighted ensemble predictions
        """
        if weights is None:
            weights = self.weights
        
        # Ensure all predictions have the same length
        min_length = min(len(prophet_pred), len(arima_pred), len(lgb_pred))
        prophet_pred = prophet_pred[:min_length]
        arima_pred = arima_pred[:min_length]
        lgb_pred = lgb_pred[:min_length]
        
        return (weights.prophet * prophet_pred + 
                weights.arima * arima_pred + 
                weights.lightgbm * lgb_pred)
    
    def predict(self, periods: int, freq: str = '15min') -> ForecastResult:
        """Generate ensemble predictions for future periods.
        
        Args:
            periods: Number of future periods to predict
            freq: Frequency of predictions
            
        Returns:
            ForecastResult with ensemble predictions
        """
        if not self.trained:
            raise ValueError("Ensemble must be trained before prediction")
        
        # Get predictions from each model
        prophet_result = self.prophet_model.predict_prophet(periods, freq)
        arima_result = self.arima_model.predict_arima(periods)
        
        # For LightGBM, need to create future features
        future_index = pd.date_range(
            start=self.training_data.index[-1] + pd.Timedelta(freq),
            periods=periods,
            freq=freq
        )
        
        # Create future DataFrame with dummy target values
        future_df = pd.DataFrame(
            index=future_index,
            data={'target': np.zeros(periods)}
        )
        
        # Prepare features and get LightGBM predictions
        future_features = self.lightgbm_model.prepare_features(future_df)
        lgb_result = self.lightgbm_model.predict_lightgbm(future_features)
        
        # Combine predictions
        ensemble_pred = self.weighted_ensemble_prediction(
            prophet_result.predictions,
            arima_result.predictions,
            lgb_result.predictions
        )
        
        # Combine confidence intervals (using Prophet's as base)
        lower_ci, upper_ci = prophet_result.confidence_intervals
        
        return ForecastResult(
            predictions=ensemble_pred,
            confidence_intervals=(lower_ci, upper_ci),
            model_metrics=self.model_metrics,
            feature_importance=lgb_result.feature_importance
        )
    
    def calculate_mfa_accuracy(self, predictions: np.ndarray, actuals: np.ndarray) -> float:
        """Calculate MFA (Month Forecast Accuracy) metric.
        
        Args:
            predictions: Predicted values
            actuals: Actual values
            
        Returns:
            MFA accuracy as percentage (0-100)
        """
        if len(predictions) != len(actuals):
            raise ValueError("Predictions and actuals must have same length")
        
        # Calculate Mean Absolute Percentage Error (MAPE)
        mape = np.mean(np.abs((actuals - predictions) / (actuals + 1e-8))) * 100
        
        # MFA accuracy is 100 - MAPE
        mfa_accuracy = max(0, 100 - mape)
        
        return mfa_accuracy
    
    def adaptive_weight_adjustment(self, recent_errors: Dict[str, float]) -> EnsembleWeights:
        """Adjust ensemble weights based on recent prediction errors.
        
        Args:
            recent_errors: Dictionary of recent errors for each model
            
        Returns:
            Adjusted ensemble weights
        """
        # Calculate inverse error weights (better models get higher weights)
        prophet_inv_error = 1 / (recent_errors.get('prophet', 1) + 1e-8)
        arima_inv_error = 1 / (recent_errors.get('arima', 1) + 1e-8)
        lgb_inv_error = 1 / (recent_errors.get('lightgbm', 1) + 1e-8)
        
        # Normalize to sum to 1
        total_inv_error = prophet_inv_error + arima_inv_error + lgb_inv_error
        
        return EnsembleWeights(
            prophet=prophet_inv_error / total_inv_error,
            arima=arima_inv_error / total_inv_error,
            lightgbm=lgb_inv_error / total_inv_error
        )


# Convenience functions for integration with Enhanced Erlang C
def create_ensemble_forecaster(weights: Optional[EnsembleWeights] = None) -> MLEnsembleForecaster:
    """Create and return configured ensemble forecaster.
    
    Args:
        weights: Optional ensemble weights
        
    Returns:
        Configured MLEnsembleForecaster instance
    """
    return MLEnsembleForecaster(weights)


def validate_ensemble_accuracy(forecaster: MLEnsembleForecaster, 
                              test_data: pd.DataFrame,
                              target_column: str = 'target') -> Dict[str, float]:
    """Validate ensemble accuracy on test data.
    
    Args:
        forecaster: Trained ensemble forecaster
        test_data: Test data for validation
        target_column: Name of target column
        
    Returns:
        Dictionary with accuracy metrics
    """
    # Generate predictions
    periods = len(test_data)
    result = forecaster.predict(periods)
    
    # Calculate metrics
    actual_values = test_data[target_column].values
    predictions = result.predictions
    
    # MFA accuracy
    mfa_accuracy = forecaster.calculate_mfa_accuracy(predictions, actual_values)
    
    # Additional metrics
    mae = np.mean(np.abs(predictions - actual_values))
    rmse = np.sqrt(np.mean((predictions - actual_values) ** 2))
    mape = np.mean(np.abs((actual_values - predictions) / (actual_values + 1e-8))) * 100
    
    return {
        'mfa_accuracy': mfa_accuracy,
        'mae': mae,
        'rmse': rmse,
        'mape': mape,
        'individual_metrics': result.model_metrics
    }