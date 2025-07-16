"""
Forecasting Algorithms Module

This module contains algorithms for load forecasting and demand planning:
- Special events forecasting with real database integration
- Load forecasting engines
- Demand planning algorithms
- Seasonal forecasting systems

All algorithms use real data from wfm_enterprise database with zero mock dependencies.
"""

from .special_events_forecaster_real import SpecialEventsForecastingEngineReal

# Alias for easier import
SpecialEventsForecaster = SpecialEventsForecastingEngineReal

__all__ = [
    'SpecialEventsForecastingEngineReal', 
    'SpecialEventsForecaster'
]