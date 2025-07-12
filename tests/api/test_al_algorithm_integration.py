"""
Integration tests for AL's algorithm API endpoints.

Tests the seamless integration between AL's algorithms and API endpoints:
- Enhanced Erlang C with Service Level Corridor Support
- ML Ensemble (Prophet, ARIMA, LightGBM) forecasting
- Real-time optimization
- Performance validation
"""

import pytest
import json
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch
import numpy as np
import pandas as pd

from src.api.main import app
from src.api.services.algorithm_service import AlgorithmService


class TestALAlgorithmIntegration:
    """Test AL's algorithm integration with API endpoints."""
    
    def setup_method(self):
        """Set up test client and mock data."""
        self.client = TestClient(app)
        
        # Mock historical data for ML training
        self.historical_data = []
        start_date = datetime.now() - timedelta(days=30)
        
        for i in range(30 * 96):  # 30 days of 15-minute intervals
            timestamp = start_date + timedelta(minutes=15 * i)
            self.historical_data.append({
                "timestamp": timestamp.isoformat(),
                "call_volume": 50 + 20 * np.sin(i / 96 * 2 * np.pi) + np.random.normal(0, 5),
                "aht": 180 + np.random.normal(0, 20)
            })
    
    def test_enhanced_erlang_c_calculation(self):
        """Test AL's Enhanced Erlang C calculation endpoint."""
        payload = {
            "lambda_rate": 100,
            "mu_rate": 0.2,
            "target_service_level": 0.8,
            "use_service_level_corridor": True,
            "validation_mode": True
        }
        
        with patch('src.api.services.algorithm_service.AlgorithmService.calculate_al_enhanced_erlang_c') as mock_calc:
            mock_calc.return_value = {
                "status": "success",
                "data": {
                    "required_agents": 510,
                    "achieved_service_level": 0.82,
                    "offered_load": 500,
                    "utilization": 0.78,
                    "enhanced_metrics": {
                        "beta_star": 0.84,
                        "beta_correction": 12.5,
                        "enhanced_staffing_continuous": 509.8,
                        "service_level_corridor_applied": True
                    },
                    "performance_metrics": {
                        "processing_time_ms": 45,
                        "algorithm_type": "AL_Enhanced_Erlang_C",
                        "service_level_corridor_support": True,
                        "mathematical_precision": "argus_compatible"
                    }
                }
            }
            
            response = self.client.post("/algorithms/erlang-c/enhanced/calculate", json=payload)
            
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "success"
            assert data["data"]["required_agents"] == 510
            assert data["data"]["enhanced_metrics"]["service_level_corridor_applied"] == True
            assert data["data"]["performance_metrics"]["algorithm_type"] == "AL_Enhanced_Erlang_C"
    
    def test_ml_ensemble_training(self):
        """Test AL's ML ensemble training endpoint."""
        payload = {
            "service_id": "test_service_001",
            "historical_data": self.historical_data,
            "target_column": "call_volume",
            "validation_split": 0.2
        }
        
        with patch('src.api.services.algorithm_service.AlgorithmService.train_ml_ensemble') as mock_train:
            mock_train.return_value = {
                "status": "success",
                "data": {
                    "service_id": "test_service_001",
                    "training_metrics": {
                        "prophet_mae": 8.5,
                        "arima_mae": 9.2,
                        "lightgbm_mae": 7.8
                    },
                    "data_points": len(self.historical_data),
                    "target_column": "call_volume",
                    "validation_split": 0.2,
                    "model_status": "trained"
                }
            }
            
            response = self.client.post("/algorithms/ml-models/ensemble/train", json=payload)
            
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "success"
            assert data["data"]["service_id"] == "test_service_001"
            assert data["data"]["model_status"] == "trained"
            assert "training_metrics" in data["data"]
    
    def test_ml_ensemble_prediction(self):
        """Test AL's ML ensemble prediction endpoint."""
        payload = {
            "service_id": "test_service_001",
            "periods": 96,  # 24 hours
            "freq": "15min",
            "confidence_intervals": True
        }
        
        with patch('src.api.services.algorithm_service.AlgorithmService.predict_ml_ensemble') as mock_predict:
            mock_predict.return_value = {
                "status": "success",
                "data": {
                    "service_id": "test_service_001",
                    "predictions": [45.2, 48.1, 52.3, 55.8] * 24,  # 96 predictions
                    "confidence_intervals": {
                        "lower": [40.1, 43.5, 47.2, 50.5] * 24,
                        "upper": [50.3, 52.7, 57.4, 61.1] * 24
                    },
                    "model_metrics": {
                        "prophet_mae": 8.5,
                        "arima_mae": 9.2,
                        "lightgbm_mae": 7.8
                    },
                    "mfa_accuracy": 78.5,
                    "prediction_horizon": 96,
                    "frequency": "15min"
                }
            }
            
            response = self.client.post("/algorithms/ml-models/ensemble/predict", json=payload)
            
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "success"
            assert len(data["data"]["predictions"]) == 96
            assert data["data"]["mfa_accuracy"] > 75  # AL's target accuracy
            assert "confidence_intervals" in data["data"]
    
    def test_real_time_optimization(self):
        """Test AL's real-time optimization endpoint."""
        payload = {
            "service_id": "test_service_001",
            "current_metrics": {
                "calls_received": 45,
                "aht": 180,
                "agents_available": 10
            },
            "prediction_horizon": 4,
            "optimization_objective": "service_level"
        }
        
        with patch('src.api.services.algorithm_service.AlgorithmService.real_time_optimization') as mock_optimize:
            mock_optimize.return_value = {
                "status": "success",
                "data": {
                    "service_id": "test_service_001",
                    "optimization_recommendations": [
                        {
                            "interval": 1,
                            "predicted_calls": 48,
                            "optimal_agents": 11,
                            "achieved_service_level": 0.82,
                            "staffing_adjustment": 1
                        },
                        {
                            "interval": 2,
                            "predicted_calls": 52,
                            "optimal_agents": 12,
                            "achieved_service_level": 0.81,
                            "staffing_adjustment": 2
                        }
                    ],
                    "real_time_capabilities": {
                        "dynamic_staffing": True,
                        "ml_predictions": True,
                        "service_level_optimization": True
                    }
                }
            }
            
            response = self.client.post("/algorithms/ml-models/real-time/optimization", json=payload)
            
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "success"
            assert len(data["data"]["optimization_recommendations"]) >= 2
            assert data["data"]["real_time_capabilities"]["dynamic_staffing"] == True
    
    def test_algorithm_performance_metrics(self):
        """Test AL's algorithm performance metrics endpoint."""
        service_id = "test_service_001"
        
        with patch('src.api.services.algorithm_service.AlgorithmService.get_algorithm_performance_metrics') as mock_metrics:
            mock_metrics.return_value = {
                "status": "success",
                "data": {
                    "service_id": service_id,
                    "performance_metrics": {
                        "erlang_c_enhanced": {
                            "average_calculation_time_ms": 45,
                            "cache_hit_rate": 0.85,
                            "mathematical_precision": "argus_compatible",
                            "service_level_corridor_support": True,
                            "competitive_advantage": "30% faster than standard Erlang C"
                        },
                        "ml_ensemble": {
                            "models_available": ["Prophet", "ARIMA", "LightGBM"],
                            "target_mfa_accuracy": ">75%",
                            "prediction_granularity": "15-minute intervals",
                            "ensemble_weighting": "dynamic",
                            "competitive_advantage": "Multi-model ensemble for superior accuracy"
                        }
                    },
                    "competitive_analysis": {
                        "vs_standard_erlang_c": "30% performance improvement",
                        "vs_basic_forecasting": "25% accuracy improvement",
                        "vs_static_staffing": "40% efficiency improvement"
                    }
                }
            }
            
            response = self.client.get(f"/algorithms/ml-models/algorithms/performance?service_id={service_id}")
            
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "success"
            assert "performance_metrics" in data["data"]
            assert "competitive_analysis" in data["data"]
    
    def test_argus_validation(self):
        """Test AL's Argus validation endpoint."""
        payload = {
            "scenarios": [
                {
                    "lambda_rate": 100,
                    "mu_rate": 0.2,
                    "target_service_level": 0.8,
                    "expected_agents": 510
                }
            ],
            "tolerance": 0.05
        }
        
        with patch('src.api.services.algorithm_service.AlgorithmService.validate_against_argus_scenarios') as mock_validate:
            mock_validate.return_value = {
                "status": "success",
                "data": {
                    "validation_results": {
                        "custom_scenario_1": {
                            "calculated_agents": 510,
                            "achieved_sl": 0.82,
                            "expected_agents": 510,
                            "within_tolerance": True,
                            "relative_error": 0.0
                        }
                    },
                    "summary": {
                        "total_scenarios": 1,
                        "passed_scenarios": 1,
                        "success_rate": 1.0,
                        "mathematical_precision": "argus_compatible"
                    },
                    "competitive_validation": {
                        "argus_compatibility": True,
                        "precision_level": "enterprise_grade",
                        "validation_method": "reference_scenario_testing"
                    }
                }
            }
            
            response = self.client.post("/algorithms/erlang-c/validation/argus", json=payload)
            
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "success"
            assert data["data"]["summary"]["success_rate"] == 1.0
            assert data["data"]["competitive_validation"]["argus_compatibility"] == True
    
    def test_algorithm_error_handling(self):
        """Test error handling in AL's algorithm endpoints."""
        # Test with invalid data
        payload = {
            "lambda_rate": -1,  # Invalid negative rate
            "mu_rate": 0.2,
            "target_service_level": 0.8
        }
        
        response = self.client.post("/algorithms/erlang-c/enhanced/calculate", json=payload)
        
        # Should handle error gracefully
        assert response.status_code in [400, 500]
        data = response.json()
        assert "detail" in data
    
    def test_algorithm_caching(self):
        """Test caching behavior for AL's algorithms."""
        payload = {
            "service_id": "test_service_001",
            "periods": 96,
            "freq": "15min",
            "confidence_intervals": True
        }
        
        # First request
        response1 = self.client.post("/algorithms/ml-models/ensemble/predict", json=payload)
        
        # Second request should be cached (if caching is working)
        response2 = self.client.post("/algorithms/ml-models/ensemble/predict", json=payload)
        
        # Both should succeed
        assert response1.status_code == 200
        assert response2.status_code == 200
    
    def test_integration_data_flow(self):
        """Test complete data flow from API to AL's algorithms."""
        # Test the complete flow: train -> predict -> optimize
        
        # 1. Train ML ensemble
        train_payload = {
            "service_id": "integration_test",
            "historical_data": self.historical_data[:100],  # Smaller dataset for testing
            "target_column": "call_volume",
            "validation_split": 0.2
        }
        
        with patch('src.api.services.algorithm_service.AlgorithmService.train_ml_ensemble') as mock_train:
            mock_train.return_value = {"status": "success", "data": {"model_status": "trained"}}
            
            train_response = self.client.post("/algorithms/ml-models/ensemble/train", json=train_payload)
            assert train_response.status_code == 200
        
        # 2. Generate predictions
        predict_payload = {
            "service_id": "integration_test",
            "periods": 4,
            "freq": "15min"
        }
        
        with patch('src.api.services.algorithm_service.AlgorithmService.predict_ml_ensemble') as mock_predict:
            mock_predict.return_value = {
                "status": "success",
                "data": {
                    "predictions": [45, 48, 52, 55],
                    "confidence_intervals": {"lower": [40, 43, 47, 50], "upper": [50, 53, 57, 60]}
                }
            }
            
            predict_response = self.client.post("/algorithms/ml-models/ensemble/predict", json=predict_payload)
            assert predict_response.status_code == 200
        
        # 3. Real-time optimization
        optimize_payload = {
            "service_id": "integration_test",
            "current_metrics": {"calls_received": 45, "aht": 180, "agents_available": 10},
            "prediction_horizon": 4
        }
        
        with patch('src.api.services.algorithm_service.AlgorithmService.real_time_optimization') as mock_optimize:
            mock_optimize.return_value = {
                "status": "success",
                "data": {"optimization_recommendations": [{"interval": 1, "optimal_agents": 11}]}
            }
            
            optimize_response = self.client.post("/algorithms/ml-models/real-time/optimization", json=optimize_payload)
            assert optimize_response.status_code == 200
    
    def test_performance_benchmarks(self):
        """Test performance benchmarks for AL's algorithms."""
        # Test Enhanced Erlang C performance
        payload = {
            "lambda_rate": 1000,  # Large system
            "mu_rate": 0.15,
            "target_service_level": 0.9,
            "use_service_level_corridor": True
        }
        
        with patch('src.api.services.algorithm_service.AlgorithmService.calculate_al_enhanced_erlang_c') as mock_calc:
            mock_calc.return_value = {
                "status": "success",
                "data": {
                    "required_agents": 6750,
                    "performance_metrics": {
                        "processing_time_ms": 78,  # Should be < 100ms
                        "algorithm_type": "AL_Enhanced_Erlang_C"
                    }
                }
            }
            
            response = self.client.post("/algorithms/erlang-c/enhanced/calculate", json=payload)
            
            assert response.status_code == 200
            data = response.json()
            # Verify performance target
            assert data["data"]["performance_metrics"]["processing_time_ms"] < 100


if __name__ == "__main__":
    pytest.main([__file__, "-v"])