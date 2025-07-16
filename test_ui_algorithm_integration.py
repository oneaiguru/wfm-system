#!/usr/bin/env python3
"""
Complete UI-Algorithm Integration Test
Tests the full flow: LoadPlanningUI → Forecasting API → AL Algorithms → UI Display
"""

import pytest
import asyncio
import requests
import json
import time
from datetime import datetime
import sys
import os

# Add the src directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from fastapi.testclient import TestClient
from fastapi import FastAPI

def create_full_integration_app():
    """Create complete app with all integrations"""
    app = FastAPI(title="Complete UI-Algorithm Integration Test")
    
    # Import all necessary routers
    try:
        from src.api.v1.endpoints.algorithm_integration_service import router as algorithm_router
        from src.api.v1.endpoints.forecasting_ui_simple import router as forecasting_router
        
        app.include_router(algorithm_router)
        app.include_router(forecasting_router)
        
        return app, True
    except ImportError as e:
        print(f"Import error: {e}")
        return None, False

class TestCompleteUIAlgorithmIntegration:
    """Test complete UI-Algorithm integration flow"""
    
    def setup_method(self):
        """Set up test environment"""
        self.app, self.imports_successful = create_full_integration_app()
        
        if self.imports_successful:
            self.client = TestClient(self.app)
        
        # Sample data matching LoadPlanningUI format
        self.ui_forecast_data = {
            "service_name": "Technical Support",
            "period": "2024-07-01_2024-07-31",
            "hourly_demand": {
                "08:00": 3, "09:00": 4, "10:00": 5, "11:00": 5,
                "12:00": 4, "13:00": 5, "14:00": 6, "15:00": 5,
                "16:00": 4, "17:00": 3
            }
        }
        
        self.ui_schedule_data = [
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
            },
            {
                "employee_id": "EMP_003",
                "start_time": "10:00",
                "end_time": "18:00",
                "skill_level": "basic",
                "days_per_week": 4
            }
        ]
    
    @pytest.mark.skipif(not pytest.importorskip, reason="Module imports failed")
    def test_complete_ui_workflow_simulation(self):
        """
        Simulate complete UI workflow:
        1. User loads LoadPlanningUI
        2. Forecasting data is fetched
        3. Real-time optimization analysis runs
        4. User triggers full optimization
        5. Results display in UI widgets
        """
        if not self.imports_successful:
            pytest.skip("Required modules not available")
        
        print("\n🎯 SIMULATING COMPLETE UI-ALGORITHM WORKFLOW")
        print("=" * 60)
        
        # Step 1: Simulate UI loading forecasting data
        print("📊 Step 1: LoadPlanningUI fetches forecasting data...")
        
        forecast_response = self.client.get(
            f"/api/v1/forecasting/forecasts?period={self.ui_forecast_data['period']}&service_name={self.ui_forecast_data['service_name']}"
        )
        
        assert forecast_response.status_code == 200
        forecast_data = forecast_response.json()
        print(f"   ✅ Forecast data loaded: {len(forecast_data.get('forecasts', []))} forecasts")
        
        # Step 2: Simulate real-time optimization analysis (auto-triggered by UI)
        print("⚡ Step 2: Real-time optimization analysis (auto-triggered)...")
        
        quick_analysis_start = time.time()
        quick_response = self.client.post("/algorithm/analyze/quick", json={
            "algorithm_type": "gap_analysis",
            "current_schedule": self.ui_schedule_data,
            "forecast_data": self.ui_forecast_data["hourly_demand"]
        })
        quick_analysis_time = time.time() - quick_analysis_start
        
        assert quick_response.status_code == 200
        quick_data = quick_response.json()
        
        print(f"   ✅ Quick analysis completed in {quick_analysis_time*1000:.1f}ms")
        print(f"   📈 Coverage score: {quick_data['result']['coverage_score']}")
        print(f"   🔍 Total gaps: {quick_data['result']['total_gaps']}")
        print(f"   💡 Recommendations: {len(quick_data['result']['recommendations'])}")
        
        # Verify UI-ready format
        assert quick_data["ui_ready"] is True
        assert "ui_metrics" in quick_data["result"]
        
        # Step 3: User clicks "Full Optimization" button
        print("🚀 Step 3: User triggers full optimization...")
        
        optimization_response = self.client.post("/algorithm/optimize", json={
            "service_id": "load_planning",
            "period_start": "2024-07-01",
            "period_end": "2024-07-31",
            "optimization_goals": ["coverage", "cost"],
            "mode": "phased",
            "constraints": {
                "labor_laws": {"max_hours_week": 40},
                "staffing_costs": {"base_hourly": 25.0}
            }
        })
        
        assert optimization_response.status_code == 200
        job_data = optimization_response.json()
        job_id = job_data["job_id"]
        
        print(f"   ✅ Optimization job started: {job_id}")
        
        # Step 4: Poll for completion (simulate progress bar)
        print("📊 Step 4: Monitoring optimization progress...")
        
        max_wait = 35
        wait_time = 0
        
        while wait_time < max_wait:
            status_response = self.client.get(f"/algorithm/optimize/{job_id}/status")
            assert status_response.status_code == 200
            
            status_data = status_response.json()
            print(f"   📈 Progress: {status_data.get('progress', 0)}% - {status_data['status']}")
            
            if status_data["status"] == "completed":
                break
            elif status_data["status"] == "failed":
                pytest.fail("Optimization failed")
            
            time.sleep(2)
            wait_time += 2
        
        assert wait_time < max_wait, "Optimization timed out"
        
        # Step 5: Get full results for UI display
        print("🎨 Step 5: Loading results for UI display...")
        
        results_response = self.client.get(f"/algorithm/optimize/{job_id}")
        assert results_response.status_code == 200
        
        results_data = results_response.json()
        
        # Verify UI integration data
        assert "ui_integration" in results_data
        ui_data = results_data["ui_integration"]
        
        assert "dashboard_widgets" in ui_data
        assert "suggestion_cards" in ui_data
        assert "implementation_timeline" in ui_data
        
        print(f"   ✅ UI widgets ready: {len(ui_data['dashboard_widgets'])} widgets")
        print(f"   ✅ Suggestion cards: {len(ui_data['suggestion_cards'])} suggestions")
        print(f"   ✅ Implementation plan: {len(ui_data['implementation_timeline'])} phases")
        
        # Step 6: Verify dashboard widget data
        print("📊 Step 6: Validating dashboard widget data...")
        
        for widget in ui_data["dashboard_widgets"]:
            assert "type" in widget
            assert "value" in widget
            assert "format" in widget
            assert "color" in widget
            
            print(f"   📈 {widget['type']}: {widget['value']} ({widget['format']}) - {widget['color']}")
        
        # Step 7: Verify suggestion cards for UI
        print("💡 Step 7: Validating suggestion cards...")
        
        for i, card in enumerate(ui_data["suggestion_cards"][:3]):  # Top 3
            assert "title" in card
            assert "coverage_improvement" in card
            assert "cost_impact" in card
            assert "risk_level" in card
            assert "action_buttons" in card
            
            print(f"   {i+1}. {card['title']}")
            print(f"      Coverage: {card['coverage_improvement']} | Cost: {card['cost_impact']}")
            print(f"      Risk: {card['risk_level']} | Actions: {card['action_buttons']}")
        
        print("\n🏆 COMPLETE UI-ALGORITHM WORKFLOW SUCCESS!")
        print(f"   Total time: {wait_time}s")
        print(f"   Quick analysis: {quick_analysis_time*1000:.0f}ms")
        print(f"   Full optimization: {results_data['processing_time']:.1f}s")
        print(f"   Confidence: {results_data['confidence_score']:.1f}%")
    
    def test_ui_performance_requirements(self):
        """Test performance requirements for UI responsiveness"""
        if not self.imports_successful:
            pytest.skip("Required modules not available")
        
        print("\n⚡ TESTING UI PERFORMANCE REQUIREMENTS")
        print("=" * 50)
        
        # Test 1: Quick analysis must be <3s for real-time UI feedback
        start_time = time.time()
        response = self.client.post("/algorithm/analyze/quick", json={
            "algorithm_type": "gap_analysis",
            "current_schedule": self.ui_schedule_data,
            "forecast_data": self.ui_forecast_data["hourly_demand"]
        })
        analysis_time = time.time() - start_time
        
        assert response.status_code == 200
        assert analysis_time < 3.0, f"Quick analysis {analysis_time:.2f}s exceeds 3s UI requirement"
        
        print(f"✅ Quick analysis: {analysis_time*1000:.0f}ms (< 3s requirement)")
        
        # Test 2: Status endpoint must be <1s for progress updates
        start_time = time.time()
        response = self.client.get("/algorithm/algorithms/status")
        status_time = time.time() - start_time
        
        assert response.status_code == 200
        assert status_time < 1.0, f"Status endpoint {status_time:.2f}s exceeds 1s requirement"
        
        print(f"✅ Status endpoint: {status_time*1000:.0f}ms (< 1s requirement)")
        
        # Test 3: Forecasting data load must be reasonable
        start_time = time.time()
        response = self.client.get(f"/api/v1/forecasting/forecasts?period={self.ui_forecast_data['period']}")
        forecast_time = time.time() - start_time
        
        assert response.status_code == 200
        assert forecast_time < 5.0, f"Forecast load {forecast_time:.2f}s exceeds 5s reasonable limit"
        
        print(f"✅ Forecast loading: {forecast_time*1000:.0f}ms (< 5s reasonable)")
    
    def test_ui_data_format_compatibility(self):
        """Test that all data formats are compatible with UI components"""
        if not self.imports_successful:
            pytest.skip("Required modules not available")
        
        print("\n🎨 TESTING UI DATA FORMAT COMPATIBILITY")
        print("=" * 50)
        
        # Test quick analysis format
        response = self.client.post("/algorithm/analyze/quick", json={
            "algorithm_type": "gap_analysis",
            "current_schedule": self.ui_schedule_data,
            "forecast_data": self.ui_forecast_data["hourly_demand"]
        })
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify OptimizationPanel compatibility
        result = data["result"]
        required_fields = ["total_gaps", "coverage_score", "average_gap_percentage", "recommendations"]
        
        for field in required_fields:
            assert field in result, f"Missing required field for OptimizationPanel: {field}"
        
        # Verify numeric types for UI widgets
        assert isinstance(result["total_gaps"], int)
        assert isinstance(result["coverage_score"], (int, float))
        assert isinstance(result["average_gap_percentage"], (int, float))
        assert isinstance(result["recommendations"], list)
        
        print(f"✅ Quick analysis format compatible with OptimizationPanel")
        
        # Test full optimization format
        opt_response = self.client.post("/algorithm/optimize", json={
            "service_id": "test",
            "period_start": "2024-07-01",
            "period_end": "2024-07-31",
            "optimization_goals": ["coverage"],
            "mode": "phased"
        })
        
        assert opt_response.status_code == 200
        job_data = opt_response.json()
        
        # Wait for completion and get results
        time.sleep(3)  # Allow processing
        
        results_response = self.client.get(f"/algorithm/optimize/{job_data['job_id']}")
        if results_response.status_code == 200:
            results = results_response.json()
            
            if "ui_integration" in results:
                ui_data = results["ui_integration"]
                
                # Verify dashboard widget format
                if "dashboard_widgets" in ui_data:
                    for widget in ui_data["dashboard_widgets"]:
                        required_widget_fields = ["type", "value", "format", "color"]
                        for field in required_widget_fields:
                            assert field in widget, f"Widget missing field: {field}"
                
                # Verify suggestion card format
                if "suggestion_cards" in ui_data:
                    for card in ui_data["suggestion_cards"]:
                        required_card_fields = ["title", "coverage_improvement", "cost_impact", "risk_level"]
                        for field in required_card_fields:
                            assert field in card, f"Suggestion card missing field: {field}"
                
                print(f"✅ Full optimization format compatible with UI widgets")
    
    def test_error_handling_for_ui(self):
        """Test error handling that UI components need"""
        if not self.imports_successful:
            pytest.skip("Required modules not available")
        
        print("\n🛡️ TESTING ERROR HANDLING FOR UI")
        print("=" * 40)
        
        # Test invalid algorithm type
        response = self.client.post("/algorithm/analyze/quick", json={
            "algorithm_type": "invalid_type",
            "current_schedule": []
        })
        
        assert response.status_code in [400, 422]  # Should return proper error
        print("✅ Invalid algorithm type handled correctly")
        
        # Test empty data
        response = self.client.post("/algorithm/analyze/quick", json={
            "algorithm_type": "gap_analysis",
            "current_schedule": [],
            "forecast_data": {}
        })
        
        # Should handle gracefully (either process empty data or return error)
        assert response.status_code in [200, 400]
        print("✅ Empty data handled gracefully")
        
        # Test invalid job ID
        response = self.client.get("/algorithm/optimize/INVALID_ID")
        assert response.status_code == 404
        print("✅ Invalid job ID returns 404")

def test_live_integration_if_server_running():
    """Test with live server if available"""
    try:
        response = requests.get("http://localhost:8000/algorithm/algorithms/status", timeout=3)
        
        if response.status_code == 200:
            print("\n🌐 LIVE SERVER INTEGRATION TEST")
            print("=" * 40)
            
            # Test real server endpoints
            forecast_response = requests.get(
                "http://localhost:8000/forecasting/forecasts?period=2024-07-01_2024-07-31&service_name=Technical%20Support",
                timeout=5
            )
            
            if forecast_response.status_code == 200:
                print("✅ Live forecasting endpoint working")
            
            status_data = response.json()
            print(f"✅ Algorithm service status: {status_data['integration_status']}")
            
            return True
        
    except (requests.ConnectionError, requests.Timeout):
        print("⚠️ Live server not available - integration test skipped")
        return False

if __name__ == "__main__":
    # Run complete integration test
    print("🎯 COMPLETE UI-ALGORITHM INTEGRATION TEST")
    print("=" * 60)
    
    test_instance = TestCompleteUIAlgorithmIntegration()
    test_instance.setup_method()
    
    if test_instance.imports_successful:
        try:
            test_instance.test_complete_ui_workflow_simulation()
            test_instance.test_ui_performance_requirements()
            test_instance.test_ui_data_format_compatibility()
            test_instance.test_error_handling_for_ui()
            
            # Test live server if available
            test_live_integration_if_server_running()
            
            print("\n🏆 ALL UI-ALGORITHM INTEGRATION TESTS PASSED!")
            print("\n🎯 READY FOR PRODUCTION:")
            print("   ✅ Complete workflow functional")
            print("   ✅ Performance requirements met")
            print("   ✅ UI data formats compatible") 
            print("   ✅ Error handling robust")
            print("\n🚀 LoadPlanningUI can now connect to optimization algorithms!")
            
        except Exception as e:
            print(f"\n❌ INTEGRATION TEST FAILED: {str(e)}")
            import traceback
            traceback.print_exc()
    else:
        print("❌ Module imports failed - check dependencies")