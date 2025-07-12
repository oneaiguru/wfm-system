#!/usr/bin/env python3
"""
Integration Tests for AL-OPUS Algorithm Service
Tests connection between optimization algorithms and UI endpoints
"""

import pytest
import asyncio
import requests
import json
import time
from datetime import datetime, date, timedelta
import sys
import os

# Add the src directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from fastapi.testclient import TestClient
from fastapi import FastAPI

# Create test app with algorithm integration
def create_test_app():
    app = FastAPI(title="Algorithm Integration Test")
    
    # Import and include our algorithm integration router
    from src.api.v1.endpoints.algorithm_integration_service import router
    app.include_router(router)
    
    return app

class TestAlgorithmIntegration:
    """Test AL-OPUS algorithm integration with UI"""
    
    def setup_method(self):
        """Set up test environment"""
        self.app = create_test_app()
        self.client = TestClient(self.app)
        
        # Sample data for testing
        self.sample_schedule = [
            {
                "employee_id": "EMP_001",
                "start_time": "08:00",
                "end_time": "16:00",
                "skill_level": "intermediate",
                "days_per_week": 5
            },
            {
                "employee_id": "EMP_002", 
                "start_time": "09:00",
                "end_time": "17:00",
                "skill_level": "expert",
                "days_per_week": 5
            }
        ]
        
        self.sample_forecast = {
            "08:00": 2, "09:00": 3, "10:00": 4, "11:00": 4,
            "12:00": 3, "13:00": 4, "14:00": 5, "15:00": 4,
            "16:00": 3, "17:00": 2
        }
    
    def test_algorithm_status_endpoint(self):
        """Test algorithms status monitoring"""
        response = self.client.get("/algorithm/algorithms/status")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify all algorithms are listed
        algorithms = data["algorithms"]
        expected_algorithms = [
            "gap_analysis", "cost_calculator", "pattern_generator",
            "constraint_validator", "scoring_engine", "optimization_orchestrator"
        ]
        
        for algorithm in expected_algorithms:
            assert algorithm in algorithms
            assert algorithms[algorithm]["status"] == "ready"
            assert "avg_time_ms" in algorithms[algorithm]
        
        # Verify integration status
        integration = data["integration_status"]
        assert integration["ui_endpoints_available"] is True
        assert integration["real_time_processing"] is True
        
        print("✅ Algorithm status endpoint working")
    
    def test_integration_test_endpoint(self):
        """Test integration connectivity"""
        response = self.client.get("/algorithm/integration/test")
        
        assert response.status_code == 200
        data = response.json()
        
        assert data["integration_test"] == "PASSED"
        assert data["ready_for_production"] is True
        
        # All test results should show success
        for service, result in data["results"].items():
            assert "✅" in result, f"Service {service} failed: {result}"
        
        print("✅ Integration test passed")
    
    def test_quick_gap_analysis(self):
        """Test quick gap analysis for real-time UI feedback"""
        request_data = {
            "algorithm_type": "gap_analysis",
            "current_schedule": self.sample_schedule,
            "forecast_data": self.sample_forecast
        }
        
        start_time = time.time()
        response = self.client.post("/algorithm/analyze/quick", json=request_data)
        processing_time = time.time() - start_time
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify response structure
        assert data["algorithm_type"] == "gap_analysis"
        assert data["ui_ready"] is True
        assert data["confidence"] > 0
        assert data["processing_time_ms"] > 0
        
        # Verify analysis results
        result = data["result"]
        assert "total_gaps" in result
        assert "coverage_score" in result
        assert "recommendations" in result
        assert isinstance(result["recommendations"], list)
        
        # Performance requirement: <3 seconds for quick analysis
        assert processing_time < 3.0, f"Quick analysis took {processing_time:.2f}s (>3s limit)"
        
        print(f"✅ Quick gap analysis: {processing_time*1000:.1f}ms")
    
    def test_quick_cost_calculator(self):
        """Test quick cost calculation"""
        request_data = {
            "algorithm_type": "cost_calculator",
            "current_schedule": self.sample_schedule,
            "constraints": {
                "staffing_costs": {"base_hourly": 25.0},
                "overtime_policies": {"max_weekly_overtime": 8}
            }
        }
        
        response = self.client.post("/algorithm/analyze/quick", json=request_data)
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify cost analysis results
        result = data["result"]
        assert "total_weekly_cost" in result
        assert "cost_per_hour" in result
        assert "savings_opportunities" in result
        assert result["total_weekly_cost"] > 0
        
        print("✅ Quick cost calculator working")
    
    def test_optimization_job_lifecycle(self):
        """Test complete optimization job lifecycle"""
        # Step 1: Start optimization job
        job_request = {
            "service_id": "customer_care",
            "period_start": "2024-07-01",
            "period_end": "2024-07-31",
            "optimization_goals": ["coverage", "cost"],
            "mode": "phased",
            "max_processing_time": 30,
            "constraints": {
                "maxOvertimePercent": 10,
                "labor_laws": {"max_hours_week": 40},
                "staffing_costs": {"base_hourly": 25.0}
            }
        }
        
        response = self.client.post("/algorithm/optimize", json=job_request)
        assert response.status_code == 200
        
        job_data = response.json()
        job_id = job_data["job_id"]
        assert job_data["status"] == "pending"
        assert "customer_care" in job_id
        
        print(f"✅ Started optimization job: {job_id}")
        
        # Step 2: Check job status
        response = self.client.get(f"/algorithm/optimize/{job_id}/status")
        assert response.status_code == 200
        
        status_data = response.json()
        assert status_data["job_id"] == job_id
        assert status_data["status"] in ["pending", "processing", "completed"]
        
        print(f"✅ Job status: {status_data['status']}")
        
        # Step 3: Wait for completion (with timeout)
        max_wait = 35  # seconds
        wait_time = 0
        
        while wait_time < max_wait:
            response = self.client.get(f"/algorithm/optimize/{job_id}/status")
            if response.status_code == 200:
                status = response.json()["status"]
                if status == "completed":
                    break
                elif status == "failed":
                    pytest.fail(f"Optimization job failed: {response.json()}")
            
            time.sleep(2)
            wait_time += 2
        
        if wait_time >= max_wait:
            pytest.fail(f"Optimization job didn't complete within {max_wait}s")
        
        print(f"✅ Job completed in {wait_time}s")
        
        # Step 4: Get optimization results
        response = self.client.get(f"/algorithm/optimize/{job_id}")
        assert response.status_code == 200
        
        result_data = response.json()
        
        # Verify complete result structure
        assert result_data["status"] == "completed"
        assert "suggestions" in result_data
        assert "analysis_metadata" in result_data
        assert "validation_results" in result_data
        assert "implementation_plan" in result_data
        assert "ui_integration" in result_data
        
        # Verify UI integration data
        ui_data = result_data["ui_integration"]
        assert "dashboard_widgets" in ui_data
        assert "suggestion_cards" in ui_data
        assert "implementation_timeline" in ui_data
        
        # Verify dashboard widgets for UI display
        widgets = ui_data["dashboard_widgets"]
        widget_types = {w["type"] for w in widgets}
        expected_widgets = {"coverage_improvement", "cost_savings", "compliance_score"}
        assert widget_types.intersection(expected_widgets), "Missing expected dashboard widgets"
        
        # Verify suggestion cards for UI display
        if ui_data["suggestion_cards"]:
            card = ui_data["suggestion_cards"][0]
            assert "title" in card
            assert "coverage_improvement" in card
            assert "cost_impact" in card
            assert "risk_level" in card
            assert "action_buttons" in card
        
        print("✅ Complete optimization job lifecycle working")
        print(f"   - {len(result_data['suggestions'])} suggestions generated")
        print(f"   - Confidence: {result_data['confidence_score']:.1f}%")
        print(f"   - Processing time: {result_data['processing_time']:.1f}s")
    
    def test_ui_integration_data_format(self):
        """Test that data format is ready for UI consumption"""
        # Test quick analysis first
        request_data = {
            "algorithm_type": "gap_analysis",
            "current_schedule": self.sample_schedule,
            "forecast_data": self.sample_forecast
        }
        
        response = self.client.post("/algorithm/analyze/quick", json=request_data)
        data = response.json()
        
        # Verify UI-ready format
        assert data["ui_ready"] is True
        
        # Result should be structured for direct UI consumption
        result = data["result"]
        for key in ["total_gaps", "coverage_score", "recommendations"]:
            assert key in result
        
        # Recommendations should be actionable text
        if result["recommendations"]:
            for rec in result["recommendations"]:
                assert isinstance(rec, str)
                assert len(rec) > 10  # Meaningful recommendation text
        
        print("✅ UI integration data format verified")
    
    def test_performance_requirements(self):
        """Test performance requirements for real-time UI"""
        
        # Test 1: Quick analysis performance
        start_time = time.time()
        
        request_data = {
            "algorithm_type": "gap_analysis",
            "current_schedule": self.sample_schedule
        }
        
        response = self.client.post("/algorithm/analyze/quick", json=request_data)
        quick_analysis_time = time.time() - start_time
        
        # Quick analysis should be <3 seconds for UI responsiveness
        assert quick_analysis_time < 3.0, f"Quick analysis {quick_analysis_time:.2f}s exceeds 3s limit"
        
        # Test 2: Status endpoint performance
        start_time = time.time()
        response = self.client.get("/algorithm/algorithms/status")
        status_time = time.time() - start_time
        
        # Status should be very fast (<1 second)
        assert status_time < 1.0, f"Status endpoint {status_time:.2f}s exceeds 1s limit"
        
        print(f"✅ Performance requirements met:")
        print(f"   - Quick analysis: {quick_analysis_time*1000:.0f}ms")
        print(f"   - Status endpoint: {status_time*1000:.0f}ms")
    
    def test_error_handling(self):
        """Test error handling for robustness"""
        
        # Test 1: Invalid job ID
        response = self.client.get("/algorithm/optimize/INVALID_JOB_ID")
        assert response.status_code == 404
        
        # Test 2: Invalid algorithm type
        request_data = {
            "algorithm_type": "invalid_algorithm",
            "current_schedule": self.sample_schedule
        }
        
        response = self.client.post("/algorithm/analyze/quick", json=request_data)
        # Should return 422 for invalid enum value
        assert response.status_code in [400, 422]
        
        # Test 3: Empty schedule data
        request_data = {
            "algorithm_type": "gap_analysis",
            "current_schedule": []
        }
        
        response = self.client.post("/algorithm/analyze/quick", json=request_data)
        # Should handle gracefully (might return 200 with empty results or 400)
        assert response.status_code in [200, 400]
        
        print("✅ Error handling working correctly")

def test_live_server_integration():
    """Test integration with live server if available"""
    try:
        # Try to connect to local development server
        response = requests.get("http://localhost:8000/algorithm/algorithms/status", timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Live server integration test:")
            print(f"   - Integration status: {data['integration_status']}")
            print(f"   - Active jobs: {data['performance_metrics']['active_jobs']}")
            return True
        
    except (requests.ConnectionError, requests.Timeout):
        print("⚠️  Live server not available - skipping live integration test")
        return False

if __name__ == "__main__":
    # Run integration tests
    print("🧪 AL-OPUS Algorithm Integration Tests")
    print("=" * 50)
    
    test_instance = TestAlgorithmIntegration()
    test_instance.setup_method()
    
    try:
        # Core functionality tests
        test_instance.test_algorithm_status_endpoint()
        test_instance.test_integration_test_endpoint()
        test_instance.test_quick_gap_analysis()
        test_instance.test_quick_cost_calculator()
        test_instance.test_ui_integration_data_format()
        test_instance.test_performance_requirements()
        test_instance.test_error_handling()
        
        # Full optimization job test (takes longer)
        print("\n🔄 Running full optimization job test...")
        test_instance.test_optimization_job_lifecycle()
        
        # Live server test if available
        print("\n🌐 Testing live server integration...")
        test_live_server_integration()
        
        print("\n✅ ALL INTEGRATION TESTS PASSED!")
        print("\n🎯 Ready for UI integration:")
        print("   - Quick analysis: <3s response time")
        print("   - Full optimization: <30s processing")
        print("   - UI-ready data formats")
        print("   - Real-time status monitoring")
        print("   - Error handling robust")
        
    except Exception as e:
        print(f"\n❌ INTEGRATION TEST FAILED: {str(e)}")
        import traceback
        traceback.print_exc()