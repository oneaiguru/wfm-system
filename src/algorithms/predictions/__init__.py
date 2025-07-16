"""
Prediction Algorithms Module

This module contains algorithms for demand prediction and resource forecasting:
- Resource demand forecasting with real database integration
- Load prediction engines
- Capacity planning algorithms
- Alert prediction systems

All algorithms use real data from wfm_enterprise database with zero mock dependencies.
"""

from .resource_demand_forecaster_real import ResourceDemandForecasterReal

# Alias for easier import
ResourceDemandForecaster = ResourceDemandForecasterReal

__all__ = [
    'ResourceDemandForecasterReal',
    'ResourceDemandForecaster'
]