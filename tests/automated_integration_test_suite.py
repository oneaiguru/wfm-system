"""
Automated Integration Test Suite - UI-API BDD Validation
Comprehensive testing framework for UI-OPUS ↔ INTEGRATION-OPUS connectivity
"""

import asyncio
import aiohttp
import json
import time
from datetime import datetime
from typing import Dict, List, Optional, Any
import websockets
import pytest


class IntegrationTestSuite:
    """Automated test suite for comprehensive UI-API integration validation"""
    
    def __init__(self, api_base_url: str = "http://localhost:8000/api/v1", 
                 ui_base_url: str = "http://localhost:3000",
                 websocket_url: str = "ws://localhost:8000/ws"):
        self.api_base_url = api_base_url
        self.ui_base_url = ui_base_url
        self.websocket_url = websocket_url
        self.test_results: Dict[str, Any] = {}
        self.session: Optional[aiohttp.ClientSession] = None
        
    async def initialize(self):
        """Initialize test session and connections"""
        self.session = aiohttp.ClientSession()
        print("🚀 Initializing Integration Test Suite...")
        
    async def cleanup(self):
        """Clean up test session"""
        if self.session:
            await self.session.close()
        print("🧹 Test suite cleanup completed")

    # Core API Tests
    async def test_core_api_health(self) -> Dict[str, Any]:
        """Test core API health and connectivity"""
        print("🔍 Testing Core API Health...")
        results = {}
        
        # Health Check
        try:
            async with self.session.get(f"{self.api_base_url}/health") as response:
                results["health_check"] = {
                    "status": response.status,
                    "response_time": await self._measure_response_time(response),
                    "data": await response.json() if response.status == 200 else None
                }
        except Exception as e:
            results["health_check"] = {"status": "error", "error": str(e)}
            
        # Authentication Test
        try:
            async with self.session.get(f"{self.api_base_url}/auth/test") as response:
                results["auth_test"] = {
                    "status": response.status,
                    "response_time": await self._measure_response_time(response)
                }
        except Exception as e:
            results["auth_test"] = {"status": "error", "error": str(e)}
            
        # Database Health
        try:
            async with self.session.get(f"{self.api_base_url}/integration/database/health") as response:
                results["database_health"] = {
                    "status": response.status,
                    "response_time": await self._measure_response_time(response)
                }
        except Exception as e:
            results["database_health"] = {"status": "error", "error": str(e)}
            
        # Algorithm Integration
        try:
            async with self.session.get(f"{self.api_base_url}/integration/algorithms/test-integration") as response:
                results["algorithm_integration"] = {
                    "status": response.status,
                    "response_time": await self._measure_response_time(response)
                }
        except Exception as e:
            results["algorithm_integration"] = {"status": "error", "error": str(e)}
            
        return results

    # Personnel Management Tests
    async def test_personnel_management(self) -> Dict[str, Any]:
        """Test personnel management API integration"""
        print("👥 Testing Personnel Management...")
        results = {}
        
        # Get Employees
        try:
            async with self.session.get(f"{self.api_base_url}/personnel/employees") as response:
                results["get_employees"] = {
                    "status": response.status,
                    "response_time": await self._measure_response_time(response),
                    "data": await response.json() if response.status == 200 else None
                }
        except Exception as e:
            results["get_employees"] = {"status": "error", "error": str(e)}
            
        # Create Employee Test
        employee_data = {
            "personalInfo": {
                "lastName": "Иванов",
                "firstName": "Иван", 
                "middleName": "Иванович"
            },
            "workInfo": {
                "employeeNumber": "EMP001",
                "department": "Call Center",
                "position": "Operator"
            }
        }
        
        try:
            async with self.session.post(f"{self.api_base_url}/personnel/employees", 
                                       json=employee_data) as response:
                results["create_employee"] = {
                    "status": response.status,
                    "response_time": await self._measure_response_time(response),
                    "data": await response.json() if response.status in [200, 201] else None
                }
        except Exception as e:
            results["create_employee"] = {"status": "error", "error": str(e)}
            
        return results

    # Vacancy Planning Tests
    async def test_vacancy_planning(self) -> Dict[str, Any]:
        """Test vacancy planning API integration"""
        print("📊 Testing Vacancy Planning...")
        results = {}
        
        # Settings API
        try:
            async with self.session.get(f"{self.api_base_url}/vacancy-planning/settings") as response:
                results["settings_api"] = {
                    "status": response.status,
                    "response_time": await self._measure_response_time(response)
                }
        except Exception as e:
            results["settings_api"] = {"status": "error", "error": str(e)}
            
        # Analysis API
        analysis_request = {
            "settings": {
                "minimumVacancyEfficiency": 85,
                "analysisPeriod": 90,
                "forecastConfidence": 95
            },
            "departments": ["Call Center"],
            "timeframe": "6 months"
        }
        
        try:
            async with self.session.post(f"{self.api_base_url}/vacancy-planning/analysis",
                                       json=analysis_request) as response:
                results["analysis_api"] = {
                    "status": response.status,
                    "response_time": await self._measure_response_time(response)
                }
        except Exception as e:
            results["analysis_api"] = {"status": "error", "error": str(e)}
            
        # Exchange Integration
        try:
            async with self.session.get(f"{self.api_base_url}/vacancy-planning/exchange") as response:
                results["exchange_integration"] = {
                    "status": response.status,
                    "response_time": await self._measure_response_time(response)
                }
        except Exception as e:
            results["exchange_integration"] = {"status": "error", "error": str(e)}
            
        # Reporting API
        try:
            async with self.session.get(f"{self.api_base_url}/vacancy-planning/reports") as response:
                results["reporting_api"] = {
                    "status": response.status,
                    "response_time": await self._measure_response_time(response)
                }
        except Exception as e:
            results["reporting_api"] = {"status": "error", "error": str(e)}
            
        return results

    # Real-time Features Tests
    async def test_real_time_features(self) -> Dict[str, Any]:
        """Test real-time features and WebSocket integration"""
        print("⚡ Testing Real-time Features...")
        results = {}
        
        # WebSocket Connection Test
        try:
            async with websockets.connect(self.websocket_url) as websocket:
                await websocket.send(json.dumps({"type": "ping"}))
                response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                results["websocket_connection"] = {
                    "status": "success",
                    "response": response
                }
        except Exception as e:
            results["websocket_connection"] = {"status": "error", "error": str(e)}
            
        # Real-time Metrics
        try:
            async with self.session.get(f"{self.api_base_url}/monitoring/operational") as response:
                results["realtime_metrics"] = {
                    "status": response.status,
                    "response_time": await self._measure_response_time(response)
                }
        except Exception as e:
            results["realtime_metrics"] = {"status": "error", "error": str(e)}
            
        # Agent Status Updates
        try:
            async with self.session.get(f"{self.api_base_url}/monitoring/agents") as response:
                results["agent_status"] = {
                    "status": response.status,
                    "response_time": await self._measure_response_time(response)
                }
        except Exception as e:
            results["agent_status"] = {"status": "error", "error": str(e)}
            
        # Schedule Changes
        try:
            async with self.session.get(f"{self.api_base_url}/schedules/current") as response:
                results["schedule_changes"] = {
                    "status": response.status,
                    "response_time": await self._measure_response_time(response)
                }
        except Exception as e:
            results["schedule_changes"] = {"status": "error", "error": str(e)}
            
        return results

    # UI Integration Tests
    async def test_ui_integration_tester(self) -> Dict[str, Any]:
        """Test UI integration tester availability and functionality"""
        print("🖥️ Testing UI Integration Tester...")
        results = {}
        
        try:
            async with self.session.get(f"{self.ui_base_url}/integration-tester") as response:
                results["ui_tester_available"] = {
                    "status": response.status,
                    "response_time": await self._measure_response_time(response)
                }
        except Exception as e:
            results["ui_tester_available"] = {"status": "error", "error": str(e)}
            
        return results

    # Performance Tests
    async def test_performance_benchmarks(self) -> Dict[str, Any]:
        """Test system performance under various loads"""
        print("⚡ Testing Performance Benchmarks...")
        results = {}
        
        # Concurrent Request Test
        concurrent_requests = 10
        start_time = time.time()
        
        tasks = [
            self.session.get(f"{self.api_base_url}/health")
            for _ in range(concurrent_requests)
        ]
        
        try:
            responses = await asyncio.gather(*tasks, return_exceptions=True)
            end_time = time.time()
            
            successful_responses = [r for r in responses if not isinstance(r, Exception)]
            
            results["concurrent_requests"] = {
                "total_requests": concurrent_requests,
                "successful_requests": len(successful_responses),
                "total_time": end_time - start_time,
                "average_response_time": (end_time - start_time) / concurrent_requests
            }
        except Exception as e:
            results["concurrent_requests"] = {"status": "error", "error": str(e)}
            
        return results

    # Comprehensive Test Execution
    async def run_comprehensive_tests(self) -> Dict[str, Any]:
        """Execute all integration tests and generate comprehensive report"""
        print("🔄 Running Comprehensive Integration Tests...")
        
        await self.initialize()
        
        try:
            # Execute all test suites
            core_results = await self.test_core_api_health()
            personnel_results = await self.test_personnel_management()
            vacancy_results = await self.test_vacancy_planning()
            realtime_results = await self.test_real_time_features()
            ui_results = await self.test_ui_integration_tester()
            performance_results = await self.test_performance_benchmarks()
            
            # Compile comprehensive report
            report = {
                "timestamp": datetime.now().isoformat(),
                "test_suites": {
                    "core_api": core_results,
                    "personnel_management": personnel_results,
                    "vacancy_planning": vacancy_results,
                    "real_time_features": realtime_results,
                    "ui_integration": ui_results,
                    "performance": performance_results
                },
                "summary": self._generate_test_summary({
                    "core_api": core_results,
                    "personnel_management": personnel_results,
                    "vacancy_planning": vacancy_results,
                    "real_time_features": realtime_results,
                    "ui_integration": ui_results,
                    "performance": performance_results
                })
            }
            
            return report
            
        finally:
            await self.cleanup()

    async def _measure_response_time(self, response) -> float:
        """Measure API response time"""
        # This would be implemented with proper timing
        return 0.0  # Placeholder
        
    def _generate_test_summary(self, all_results: Dict[str, Any]) -> Dict[str, Any]:
        """Generate summary statistics from test results"""
        total_tests = 0
        passed_tests = 0
        failed_tests = 0
        
        for suite_name, suite_results in all_results.items():
            for test_name, test_result in suite_results.items():
                total_tests += 1
                if isinstance(test_result, dict) and test_result.get("status") in [200, 201, "success"]:
                    passed_tests += 1
                else:
                    failed_tests += 1
        
        return {
            "total_tests": total_tests,
            "passed_tests": passed_tests,
            "failed_tests": failed_tests,
            "success_rate": (passed_tests / total_tests * 100) if total_tests > 0 else 0,
            "recommendations": self._generate_recommendations(all_results)
        }
        
    def _generate_recommendations(self, all_results: Dict[str, Any]) -> List[str]:
        """Generate recommendations based on test results"""
        recommendations = []
        
        # Check for API connectivity issues
        core_results = all_results.get("core_api", {})
        if core_results.get("health_check", {}).get("status") != 200:
            recommendations.append("Fix API health endpoint - core connectivity issue")
            
        # Check for authentication problems
        if core_results.get("auth_test", {}).get("status") != 200:
            recommendations.append("Resolve authentication service issues")
            
        # Check for database connectivity
        if core_results.get("database_health", {}).get("status") != 200:
            recommendations.append("Check database connectivity and schema")
            
        # Performance recommendations
        performance_results = all_results.get("performance", {})
        concurrent_test = performance_results.get("concurrent_requests", {})
        if concurrent_test.get("average_response_time", 0) > 2.0:
            recommendations.append("Optimize API performance - response times exceed 2s threshold")
            
        return recommendations


# CLI Test Runner
async def main():
    """Main test runner function"""
    print("🧪 Starting Automated Integration Test Suite")
    print("=" * 60)
    
    test_suite = IntegrationTestSuite()
    report = await test_suite.run_comprehensive_tests()
    
    # Print summary
    summary = report["summary"]
    print("\n📊 Test Results Summary:")
    print(f"Total Tests: {summary['total_tests']}")
    print(f"Passed: {summary['passed_tests']}")
    print(f"Failed: {summary['failed_tests']}")
    print(f"Success Rate: {summary['success_rate']:.1f}%")
    
    if summary["recommendations"]:
        print("\n💡 Recommendations:")
        for rec in summary["recommendations"]:
            print(f"  • {rec}")
    
    # Save detailed report
    with open("integration_test_report.json", "w") as f:
        json.dump(report, f, indent=2)
    
    print(f"\n📄 Detailed report saved to: integration_test_report.json")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())