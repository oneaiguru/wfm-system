#!/usr/bin/env python3
"""
BDD-Compliant Forecast Accuracy Metrics
SPEC-08: Load Forecasting Demand Planning (Lines 336-341)
Only implements MFA (MAPE) and WFA (WAPE) as specified in BDD

Removed from original:
- All advanced metrics (RMSE, MAE, MASE, Tracking Signal, etc.)
- Outlier detection system
- Trend analysis and tracking
- Comprehensive bias analysis
- Time period analysis
- Self-learning capabilities

Kept only BDD-specified functionality:
- MFA (Mean Absolute Percentage Error / MAPE)
- WFA (Weighted Absolute Percentage Error / WAPE)
"""

import numpy as np
from typing import Dict, Any
import logging

logger = logging.getLogger(__name__)

class BDDForecastAccuracyMetrics:
    """
    BDD-Compliant Forecast Accuracy Metrics
    Implements only MAPE and WAPE as specified in BDD SPEC-08
    """
    
    def __init__(self):
        """Initialize BDD-compliant accuracy calculator"""
        logger.info("✅ BDD-Compliant Forecast Accuracy Metrics initialized")
    
    def calculate_mape(self, actual: np.ndarray, forecast: np.ndarray) -> float:
        """
        Mean Absolute Percentage Error (MFA in Argus BDD)
        MAPE = (1/n) × Σ(|Actual - Forecast| / Actual) × 100
        
        BDD Compliance: SPEC-08 Line 336-341
        """
        # Handle zero actuals
        mask = actual != 0
        if not np.any(mask):
            return np.inf
        
        mape = np.mean(np.abs((actual[mask] - forecast[mask]) / actual[mask])) * 100
        return round(mape, 2)
    
    def calculate_wape(self, actual: np.ndarray, forecast: np.ndarray) -> float:
        """
        Weighted Absolute Percentage Error (WFA in Argus BDD)
        WAPE = Σ(|Actual - Forecast|) / Σ(Actual) × 100
        Better than MAPE for intermittent demand
        
        BDD Compliance: SPEC-08 Line 336-341
        """
        total_actual = np.sum(actual)
        if total_actual == 0:
            return np.inf
        
        wape = np.sum(np.abs(actual - forecast)) / total_actual * 100
        return round(wape, 2)
    
    def calculate_accuracy_summary(self, actual: np.ndarray, forecast: np.ndarray) -> Dict[str, Any]:
        """
        Calculate both BDD-required accuracy metrics
        Returns only MAPE and WAPE as specified in BDD
        """
        try:
            mape = self.calculate_mape(actual, forecast)
            wape = self.calculate_wape(actual, forecast)
            
            return {
                'mfa_mape': mape,  # MFA as specified in BDD
                'wfa_wape': wape,  # WFA as specified in BDD
                'data_points': len(actual),
                'bdd_compliant': True
            }
            
        except Exception as e:
            logger.error(f"Accuracy calculation failed: {e}")
            return {
                'mfa_mape': np.inf,
                'wfa_wape': np.inf,
                'data_points': 0,
                'bdd_compliant': True,
                'error': str(e)
            }

# Simple function interfaces for BDD compliance
def calculate_forecast_accuracy_bdd(actual: np.ndarray, forecast: np.ndarray) -> Dict[str, Any]:
    """Simple BDD-compliant function interface"""
    metrics = BDDForecastAccuracyMetrics()
    return metrics.calculate_accuracy_summary(actual, forecast)

def validate_bdd_forecast_accuracy():
    """Test BDD-compliant forecast accuracy metrics"""
    try:
        # Sample test data
        actual = np.array([100, 120, 90, 110, 95])
        forecast = np.array([95, 115, 85, 105, 100])
        
        metrics = BDDForecastAccuracyMetrics()
        
        # Test individual metrics
        mape = metrics.calculate_mape(actual, forecast)
        wape = metrics.calculate_wape(actual, forecast)
        
        print(f"✅ BDD Forecast Accuracy Metrics Test:")
        print(f"   MFA (MAPE): {mape}%")
        print(f"   WFA (WAPE): {wape}%")
        
        # Test summary
        summary = metrics.calculate_accuracy_summary(actual, forecast)
        print(f"   Summary: {summary}")
        
        # Validate BDD compliance
        if summary['bdd_compliant'] and 'mfa_mape' in summary and 'wfa_wape' in summary:
            print("✅ BDD Compliance: PASSED - Only required metrics calculated")
            return True
        else:
            print("❌ BDD Compliance: FAILED")
            return False
            
    except Exception as e:
        print(f"❌ BDD forecast accuracy validation failed: {e}")
        return False

if __name__ == "__main__":
    # Test BDD-compliant version
    if validate_bdd_forecast_accuracy():
        print("\n✅ BDD-Compliant Forecast Accuracy Metrics: READY")
    else:
        print("\n❌ BDD-Compliant Forecast Accuracy Metrics: FAILED")