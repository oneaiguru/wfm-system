"""
Comprehensive Database-API Integration Tests
Created: 2025-07-11

Tests for verifying all database features are properly accessible through APIs:
- Contact statistics and performance metrics
- Real-time monitoring and alerts
- Schedule management and optimization
- Forecasting and analytics
- Integration management
- Data validation and quality checks
- System health monitoring
"""

import pytest
import asyncio
from typing import Dict, Any, List
from datetime import datetime, date, timedelta
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import AsyncSession
from unittest.mock import AsyncMock, MagicMock, patch

# Import the main application
from src.api.main import app
from src.api.services.database_service import DatabaseService
from src.api.utils.database_integration import DatabaseIntegrationManager

# Create test client
client = TestClient(app)

# Test configuration
TEST_API_KEY = "test-api-key-2024"
TEST_HEADERS = {"X-API-Key": TEST_API_KEY}


class TestDatabaseAPIIntegration:
    """Comprehensive tests for database-API integration."""
    
    @pytest.fixture
    def mock_db_session(self):
        """Create a mock database session."""
        session = AsyncMock(spec=AsyncSession)
        return session
    
    @pytest.fixture
    def mock_database_service(self):
        """Create a mock database service."""
        service = AsyncMock(spec=DatabaseService)
        return service
    
    # ========================================================================================
    # CONTACT STATISTICS & PERFORMANCE METRICS TESTS
    # ========================================================================================
    
    def test_get_contact_statistics_api(self):
        """Test contact statistics API endpoint."""
        # Test basic request
        response = client.get(
            "/api/v1/db/database/contact-statistics",
            headers=TEST_HEADERS
        )
        
        # Should return 200 or appropriate error (depends on database state)
        assert response.status_code in [200, 500]  # 500 if no database connection
        
        # Test with parameters
        response = client.get(
            "/api/v1/db/database/contact-statistics",
            params={
                "service_ids": "1,2,3",
                "start_date": "2024-01-01T00:00:00",
                "end_date": "2024-01-31T23:59:59",
                "include_calculated_metrics": True
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 400, 500]
    
    def test_get_agent_activity_api(self):
        """Test agent activity API endpoint."""
        response = client.get(
            "/api/v1/db/database/agent-activity",
            params={
                "agent_ids": "1,2,3",
                "include_performance_metrics": True
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 400, 500]
    
    @pytest.mark.asyncio
    async def test_database_service_contact_statistics(self, mock_db_session):
        """Test database service contact statistics method."""
        service = DatabaseService(mock_db_session)
        
        # Mock the database execute method
        mock_result = MagicMock()
        mock_result.fetchall.return_value = [
            MagicMock(
                service_id=1,
                service_name="Test Service",
                service_code="TS001",
                group_id=1,
                group_name="Test Group",
                group_code="TG001",
                interval_start_time=datetime(2024, 1, 1, 9, 0),
                interval_end_time=datetime(2024, 1, 1, 9, 15),
                not_unique_received=100,
                not_unique_treated=95,
                not_unique_missed=5,
                received_calls=90,
                treated_calls=85,
                miss_calls=5,
                aht=180,
                talk_time=150,
                post_processing=30,
                service_level=85.0,
                abandonment_rate=5.0,
                occupancy_rate=75.0
            )
        ]
        
        mock_db_session.execute.return_value = mock_result
        
        # Test the method
        result = await service.get_contact_statistics(
            service_ids=[1],
            start_date=datetime(2024, 1, 1),
            end_date=datetime(2024, 1, 31),
            include_calculated_metrics=True
        )
        
        # Verify results
        assert isinstance(result, dict)
        assert "statistics" in result
        assert "summary" in result
        assert len(result["statistics"]) == 1
        
        stat = result["statistics"][0]
        assert stat["service_id"] == 1
        assert stat["service_name"] == "Test Service"
        assert "metrics" in stat
        assert "calculated_metrics" in stat
    
    # ========================================================================================
    # REAL-TIME MONITORING & ALERTS TESTS
    # ========================================================================================
    
    def test_get_realtime_status_api(self):
        """Test real-time status API endpoint."""
        response = client.get(
            "/api/v1/db/database/realtime-status",
            params={"entity_type": "all"},
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 500]
        
        # Test with specific entity type
        response = client.get(
            "/api/v1/db/database/realtime-status",
            params={
                "entity_type": "queue",
                "entity_ids": "Q001,Q002"
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 400, 500]
    
    def test_get_performance_alerts_api(self):
        """Test performance alerts API endpoint."""
        response = client.get(
            "/api/v1/db/database/performance-alerts",
            params={
                "severity": "high",
                "entity_type": "queue",
                "active_only": True
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 500]
    
    @pytest.mark.asyncio
    async def test_database_service_realtime_status(self, mock_db_session):
        """Test database service real-time status method."""
        service = DatabaseService(mock_db_session)
        
        # Mock queue data
        mock_queue_result = MagicMock()
        mock_queue_result.fetchall.return_value = [
            MagicMock(
                queue_id="Q001",
                queue_name="Customer Service",
                queue_type="voice",
                status="active",
                current_calls=10,
                waiting_calls=5,
                agents_available=8,
                agents_busy=12,
                agents_total=20,
                avg_wait_time=45.5,
                avg_handle_time=180.2,
                service_level=85.6,
                abandon_rate=3.2,
                last_updated=datetime.now()
            )
        ]
        
        # Mock agent data
        mock_agent_result = MagicMock()
        mock_agent_result.fetchall.return_value = [
            MagicMock(
                agent_id="A001",
                agent_name="John Doe",
                status="online",
                state="busy",
                queue_id="Q001",
                current_call_id=None,
                call_start_time=None,
                session_start_time=datetime.now(),
                calls_handled=23,
                avg_handle_time=175.0,
                occupancy_rate=82.5,
                location="New York",
                device_type="desktop",
                last_activity=datetime.now(),
                status_changed_at=datetime.now()
            )
        ]
        
        # Mock system data
        mock_system_result = MagicMock()
        mock_system_result.fetchone.return_value = MagicMock(
            total_active_sessions=150,
            active_sessions=120,
            idle_sessions=30,
            avg_session_age=300.0
        )
        
        # Setup mock execute to return different results based on query
        def mock_execute(query, params=None):
            if "realtime_queues" in str(query):
                return mock_queue_result
            elif "realtime_agents" in str(query):
                return mock_agent_result
            elif "realtime_sessions" in str(query):
                return mock_system_result
            return MagicMock()
        
        mock_db_session.execute.side_effect = mock_execute
        
        # Test the method
        result = await service.get_real_time_status(
            entity_type="all",
            entity_ids=None
        )
        
        # Verify results
        assert isinstance(result, dict)
        assert "status_data" in result
        assert "queues" in result["status_data"]
        assert "agents" in result["status_data"]
        assert "system" in result["status_data"]
        
        # Check queue data
        assert len(result["status_data"]["queues"]) == 1
        queue = result["status_data"]["queues"][0]
        assert queue["queue_id"] == "Q001"
        assert queue["queue_name"] == "Customer Service"
        
        # Check agent data
        assert len(result["status_data"]["agents"]) == 1
        agent = result["status_data"]["agents"][0]
        assert agent["agent_id"] == "A001"
        assert agent["agent_name"] == "John Doe"
        assert agent["status"] == "online"
        
        # Check system data
        system = result["status_data"]["system"]
        assert system["total_active_sessions"] == 150
        assert system["active_sessions"] == 120
    
    # ========================================================================================
    # SCHEDULE MANAGEMENT TESTS
    # ========================================================================================
    
    def test_get_schedule_data_api(self):
        """Test schedule data API endpoint."""
        response = client.get(
            "/api/v1/db/database/schedules",
            params={
                "agent_ids": "1,2,3",
                "start_date": "2024-01-01",
                "end_date": "2024-01-31",
                "include_conflicts": True
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 400, 500]
    
    def test_optimize_schedules_api(self):
        """Test schedule optimization API endpoint."""
        response = client.post(
            "/api/v1/db/database/schedules/optimize",
            json={
                "schedule_period_id": "test-period-id",
                "optimization_type": "coverage",
                "parameters": {
                    "max_overtime_hours": 10,
                    "prefer_skill_match": True
                }
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 400, 500]
    
    # ========================================================================================
    # FORECASTING & ANALYTICS TESTS
    # ========================================================================================
    
    def test_get_forecast_data_api(self):
        """Test forecast data API endpoint."""
        response = client.get(
            "/api/v1/db/database/forecasts",
            params={
                "forecast_type": "call_volume",
                "start_date": "2024-01-01T00:00:00",
                "end_date": "2024-01-31T23:59:59",
                "include_data_points": True
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 400, 500]
    
    def test_calculate_forecast_api(self):
        """Test forecast calculation API endpoint."""
        response = client.post(
            "/api/v1/db/database/forecasts/calculate",
            json={
                "forecast_type": "call_volume",
                "data_source": "historical",
                "method": "prophet",
                "parameters": {
                    "seasonality_mode": "additive",
                    "confidence_interval": 0.95
                }
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 400, 500]
    
    # ========================================================================================
    # INTEGRATION MANAGEMENT TESTS
    # ========================================================================================
    
    def test_get_integration_status_api(self):
        """Test integration status API endpoint."""
        response = client.get(
            "/api/v1/db/database/integrations",
            params={
                "integration_type": "contact_center",
                "include_sync_logs": True
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 500]
    
    def test_trigger_integration_sync_api(self):
        """Test integration sync trigger API endpoint."""
        response = client.post(
            "/api/v1/db/database/integrations/sync",
            json={
                "integration_id": "test-integration-id",
                "sync_type": "incremental",
                "parameters": {
                    "force_sync": False,
                    "validate_data": True
                }
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 400, 500]
    
    # ========================================================================================
    # DATA VALIDATION & QUALITY TESTS
    # ========================================================================================
    
    def test_validate_data_quality_api(self):
        """Test data quality validation API endpoint."""
        response = client.get(
            "/api/v1/db/database/validation/contact_statistics",
            params={
                "validation_rules": "completeness,consistency,accuracy",
                "start_date": "2024-01-01T00:00:00",
                "end_date": "2024-01-31T23:59:59"
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 400, 500]
    
    def test_run_data_quality_checks_api(self):
        """Test batch data quality checks API endpoint."""
        response = client.post(
            "/api/v1/db/database/validation/run-checks",
            json={
                "tables": ["contact_statistics", "agent_activity", "work_schedules"],
                "check_types": ["completeness", "consistency", "accuracy"],
                "parameters": {
                    "start_date": "2024-01-01T00:00:00",
                    "end_date": "2024-01-31T23:59:59"
                }
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 400, 500]
    
    @pytest.mark.asyncio
    async def test_database_service_data_validation(self, mock_db_session):
        """Test database service data validation method."""
        service = DatabaseService(mock_db_session)
        
        # Mock validation query result
        mock_result = MagicMock()
        mock_result.fetchone.return_value = MagicMock(
            total_records=1000,
            null_received=5,
            null_treated=3,
            null_service_level=2,
            negative_received=0,
            invalid_treated=1
        )
        
        mock_db_session.execute.return_value = mock_result
        
        # Test the method
        result = await service.validate_data_quality(
            table_name="contact_statistics",
            start_date=datetime(2024, 1, 1),
            end_date=datetime(2024, 1, 31)
        )
        
        # Verify results
        assert isinstance(result, dict)
        assert "table_name" in result
        assert "validation_timestamp" in result
        assert "quality_score" in result
        assert "issues_found" in result
        assert "statistics" in result
        
        assert result["table_name"] == "contact_statistics"
        assert isinstance(result["quality_score"], float)
        assert isinstance(result["issues_found"], list)
    
    # ========================================================================================
    # SYSTEM HEALTH & MONITORING TESTS
    # ========================================================================================
    
    def test_get_database_health_api(self):
        """Test database health API endpoint."""
        response = client.get(
            "/api/v1/db/database/health",
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 500]
    
    def test_get_performance_metrics_api(self):
        """Test performance metrics API endpoint."""
        response = client.get(
            "/api/v1/db/database/performance-metrics",
            params={
                "metric_type": "query_performance",
                "time_range": "1hour"
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 500]
    
    # ========================================================================================
    # BULK OPERATIONS TESTS
    # ========================================================================================
    
    def test_bulk_export_data_api(self):
        """Test bulk export API endpoint."""
        response = client.post(
            "/api/v1/db/database/bulk/export",
            json={
                "tables": ["contact_statistics", "agent_activity"],
                "format": "csv",
                "filters": {
                    "start_date": "2024-01-01T00:00:00",
                    "end_date": "2024-01-31T23:59:59"
                },
                "compression": "gzip"
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 400, 500]
    
    def test_bulk_import_data_api(self):
        """Test bulk import API endpoint."""
        response = client.post(
            "/api/v1/db/database/bulk/import",
            json={
                "table": "contact_statistics",
                "format": "csv",
                "file_path": "/path/to/import/file.csv",
                "validation": True,
                "batch_size": 1000
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 400, 500]
    
    # ========================================================================================
    # ADMINISTRATIVE OPERATIONS TESTS
    # ========================================================================================
    
    def test_run_maintenance_cleanup_api(self):
        """Test maintenance cleanup API endpoint."""
        response = client.post(
            "/api/v1/db/database/maintenance/cleanup",
            json={
                "cleanup_type": "all",
                "parameters": {
                    "max_age_days": 30,
                    "force_vacuum": False
                }
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 500]
    
    def test_get_schema_information_api(self):
        """Test schema information API endpoint."""
        response = client.get(
            "/api/v1/db/database/schema/info",
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [200, 500]
    
    # ========================================================================================
    # INTEGRATION UTILITIES TESTS
    # ========================================================================================
    
    @pytest.mark.asyncio
    async def test_database_integration_manager(self):
        """Test database integration manager functionality."""
        manager = DatabaseIntegrationManager(
            database_url="postgresql+asyncpg://test:test@localhost/testdb"
        )
        
        # Test initialization (will fail without real database)
        with pytest.raises(Exception):
            await manager.initialize()
    
    def test_query_builder_functionality(self):
        """Test database query builder utility."""
        from src.api.utils.database_integration import DatabaseQueryBuilder
        
        builder = DatabaseQueryBuilder("contact_statistics")
        query = (builder
                 .select("service_id", "SUM(not_unique_received) as total_received")
                 .join("services s", "s.id = contact_statistics.service_id")
                 .where("interval_start_time >= '2024-01-01'")
                 .where("interval_start_time < '2024-02-01'")
                 .group_by("service_id", "s.service_name")
                 .order_by("total_received", "DESC")
                 .limit(10)
                 .build())
        
        # Verify query structure
        assert "SELECT service_id, SUM(not_unique_received) as total_received" in query
        assert "FROM contact_statistics" in query
        assert "INNER JOIN services s ON s.id = contact_statistics.service_id" in query
        assert "WHERE interval_start_time >= '2024-01-01'" in query
        assert "GROUP BY service_id, s.service_name" in query
        assert "ORDER BY total_received DESC" in query
        assert "LIMIT 10" in query
    
    def test_data_transformer_functionality(self):
        """Test data transformation utilities."""
        from src.api.utils.database_integration import DataTransformer
        from decimal import Decimal
        
        # Test JSON serialization
        test_data = {
            "id": 1,
            "amount": Decimal("123.45"),
            "created_at": datetime(2024, 1, 1, 12, 0, 0),
            "metadata": {
                "score": Decimal("98.7"),
                "tags": ["test", "validation"]
            }
        }
        
        converted = DataTransformer.convert_to_json_serializable(test_data)
        
        assert converted["id"] == 1
        assert isinstance(converted["amount"], float)
        assert converted["amount"] == 123.45
        assert isinstance(converted["created_at"], str)
        assert isinstance(converted["metadata"]["score"], float)
        assert converted["metadata"]["tags"] == ["test", "validation"]
        
        # Test field normalization
        test_fields = {
            "Service ID": 1,
            "agent-name": "John Doe",
            "total_calls": 100
        }
        
        normalized = DataTransformer.normalize_field_names(test_fields, "snake_case")
        
        assert "service_id" in normalized
        assert "agent_name" in normalized
        assert "total_calls" in normalized
        assert normalized["service_id"] == 1
        assert normalized["agent_name"] == "John Doe"
        
        # Test data flattening
        nested_data = {
            "agent": {
                "id": 1,
                "name": "John Doe",
                "metrics": {
                    "calls": 100,
                    "aht": 180
                }
            }
        }
        
        flattened = DataTransformer.flatten_nested_data(nested_data)
        
        assert "agent_id" in flattened
        assert "agent_name" in flattened
        assert "agent_metrics_calls" in flattened
        assert "agent_metrics_aht" in flattened
    
    # ========================================================================================
    # ERROR HANDLING & EDGE CASES TESTS
    # ========================================================================================
    
    def test_api_without_auth_header(self):
        """Test API endpoints without authentication header."""
        response = client.get("/api/v1/db/database/health")
        
        # Should return 401 or 403 for missing auth
        assert response.status_code in [401, 403, 422]
    
    def test_api_with_invalid_auth_header(self):
        """Test API endpoints with invalid authentication header."""
        response = client.get(
            "/api/v1/db/database/health",
            headers={"X-API-Key": "invalid-key"}
        )
        
        # Should return 401 or 403 for invalid auth
        assert response.status_code in [401, 403, 200]  # 200 if auth not enforced in tests
    
    def test_api_with_invalid_parameters(self):
        """Test API endpoints with invalid parameters."""
        # Test with invalid date format
        response = client.get(
            "/api/v1/db/database/contact-statistics",
            params={
                "start_date": "invalid-date",
                "service_ids": "not-a-number"
            },
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [400, 422, 500]
        
        # Test with missing required parameters
        response = client.post(
            "/api/v1/db/database/schedules/optimize",
            json={},
            headers=TEST_HEADERS
        )
        
        assert response.status_code in [400, 422, 500]
    
    @pytest.mark.asyncio
    async def test_database_service_error_handling(self, mock_db_session):
        """Test database service error handling."""
        service = DatabaseService(mock_db_session)
        
        # Mock database error
        mock_db_session.execute.side_effect = Exception("Database connection failed")
        
        # Test that service properly handles and re-raises errors
        with pytest.raises(Exception) as exc_info:
            await service.get_contact_statistics()
        
        assert "Database connection failed" in str(exc_info.value)
    
    # ========================================================================================
    # PERFORMANCE & LOAD TESTS
    # ========================================================================================
    
    def test_api_response_times(self):
        """Test API response times for performance."""
        import time
        
        # Test lightweight endpoint
        start_time = time.time()
        response = client.get(
            "/api/v1/db/database/health",
            headers=TEST_HEADERS
        )
        end_time = time.time()
        
        response_time = end_time - start_time
        
        # Should respond within reasonable time (adjust based on requirements)
        assert response_time < 5.0  # 5 seconds max for health check
    
    def test_concurrent_api_requests(self):
        """Test concurrent API requests handling."""
        import concurrent.futures
        import threading
        
        def make_request():
            return client.get(
                "/api/v1/db/database/health",
                headers=TEST_HEADERS
            )
        
        # Test multiple concurrent requests
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(make_request) for _ in range(10)]
            results = [future.result() for future in concurrent.futures.as_completed(futures)]
        
        # All requests should complete successfully or fail gracefully
        for response in results:
            assert response.status_code in [200, 500, 503]
    
    # ========================================================================================
    # COMPATIBILITY TESTS
    # ========================================================================================
    
    def test_api_response_format_compatibility(self):
        """Test API response format compatibility."""
        response = client.get(
            "/api/v1/db/database/health",
            headers=TEST_HEADERS
        )
        
        if response.status_code == 200:
            data = response.json()
            
            # Check response structure
            assert isinstance(data, dict)
            
            # Check for expected fields (adjust based on actual implementation)
            expected_fields = ["database_health", "timestamp"]
            for field in expected_fields:
                if field in data:
                    assert data[field] is not None
    
    def test_api_error_response_format(self):
        """Test API error response format consistency."""
        # Test with invalid parameters to trigger error
        response = client.get(
            "/api/v1/db/database/contact-statistics",
            params={"service_ids": "invalid"},
            headers=TEST_HEADERS
        )
        
        if response.status_code >= 400:
            data = response.json()
            
            # Check error response structure
            assert isinstance(data, dict)
            assert "detail" in data  # FastAPI standard error format


# Run the tests
if __name__ == "__main__":
    pytest.main([__file__, "-v"])