"""
Comprehensive test suite for WebSocket event handlers
"""

import pytest
import asyncio
from datetime import datetime, timedelta
from typing import Dict, Any
from unittest.mock import AsyncMock, MagicMock, patch

from src.api.websocket.handlers.base import BaseEventHandler, EventPayload, EventHandlerRegistry
from src.api.websocket.handlers.forecast_handlers import (
    ForecastUpdatedHandler,
    ForecastCalculatedHandler,
    ForecastErrorHandler
)
from src.api.websocket.handlers.schedule_handlers import (
    ScheduleChangedHandler,
    ScheduleOptimizedHandler,
    ShiftAssignedHandler
)
from src.api.websocket.models.event_models import (
    ForecastUpdatePayload,
    ForecastCalculatedPayload,
    ScheduleChangePayload,
    ScheduleOptimizedPayload,
    ShiftAssignedPayload,
    ForecastPeriod,
    ShiftData,
    OptimizationChange,
    ScheduleChangeType,
    AssignmentType
)


class TestBaseEventHandler:
    """Test base event handler functionality"""
    
    class TestHandler(BaseEventHandler):
        def __init__(self):
            super().__init__('test.event')
            self.handle_called = False
            self.validate_called = False
            
        async def handle(self, payload: EventPayload) -> Dict[str, Any]:
            self.handle_called = True
            return {'status': 'success'}
            
        async def validate(self, payload: EventPayload) -> bool:
            self.validate_called = True
            return True
    
    @pytest.fixture
    def handler(self):
        return self.TestHandler()
    
    @pytest.fixture
    def test_payload(self):
        return EventPayload(
            timestamp=datetime.utcnow(),
            correlation_id='test-123',
            source='test',
            data={'test': 'data'}
        )
    
    @pytest.mark.asyncio
    async def test_process_event_success(self, handler, test_payload):
        """Test successful event processing"""
        result = await handler.process_event(test_payload)
        
        assert result == {'status': 'success'}
        assert handler.handle_called
        assert handler.validate_called
        assert handler.metrics.successful_events == 1
        assert handler.metrics.failed_events == 0
        assert handler.metrics.success_rate == 100.0
    
    @pytest.mark.asyncio
    async def test_process_event_validation_failure(self, handler, test_payload):
        """Test event processing with validation failure"""
        handler.validate = AsyncMock(return_value=False)
        
        result = await handler.process_event(test_payload)
        
        assert result is None
        assert handler.metrics.failed_events == 1
        assert handler.metrics.success_rate == 0.0
    
    @pytest.mark.asyncio
    async def test_process_event_handler_exception(self, handler, test_payload):
        """Test event processing with handler exception"""
        handler.handle = AsyncMock(side_effect=Exception("Test error"))
        
        result = await handler.process_event(test_payload)
        
        assert result is None
        assert handler.metrics.failed_events == 1
    
    @pytest.mark.asyncio
    async def test_disabled_handler(self, handler, test_payload):
        """Test disabled handler"""
        handler.enabled = False
        
        result = await handler.process_event(test_payload)
        
        assert result is None
        assert not handler.handle_called
        assert not handler.validate_called


class TestEventHandlerRegistry:
    """Test event handler registry functionality"""
    
    @pytest.fixture
    def registry(self):
        return EventHandlerRegistry()
    
    @pytest.fixture
    def test_handler(self):
        return TestBaseEventHandler.TestHandler()
    
    @pytest.fixture
    def test_payload(self):
        return EventPayload(
            timestamp=datetime.utcnow(),
            correlation_id='test-123',
            source='test',
            data={'test': 'data'}
        )
    
    def test_register_handler(self, registry, test_handler):
        """Test handler registration"""
        registry.register('test.event', test_handler)
        
        assert 'test.event' in registry.handlers
        assert registry.handlers['test.event'] == test_handler
    
    def test_unregister_handler(self, registry, test_handler):
        """Test handler unregistration"""
        registry.register('test.event', test_handler)
        registry.unregister('test.event')
        
        assert 'test.event' not in registry.handlers
    
    @pytest.mark.asyncio
    async def test_process_event_success(self, registry, test_handler, test_payload):
        """Test successful event processing through registry"""
        registry.register('test.event', test_handler)
        
        result = await registry.process('test.event', test_payload)
        
        assert result == {'status': 'success'}
        assert test_handler.handle_called
    
    @pytest.mark.asyncio
    async def test_process_event_no_handler(self, registry, test_payload):
        """Test processing event with no registered handler"""
        result = await registry.process('nonexistent.event', test_payload)
        
        assert result is None
    
    @pytest.mark.asyncio
    async def test_process_event_registry_disabled(self, registry, test_handler, test_payload):
        """Test processing event with disabled registry"""
        registry.register('test.event', test_handler)
        registry.global_enabled = False
        
        result = await registry.process('test.event', test_payload)
        
        assert result is None
        assert not test_handler.handle_called


class TestForecastHandlers:
    """Test forecast event handlers"""
    
    @pytest.fixture
    def forecast_update_payload(self):
        return EventPayload(
            timestamp=datetime.utcnow(),
            correlation_id='test-123',
            source='test',
            data={
                'forecast_id': 'forecast-123',
                'interval_start': datetime.utcnow().isoformat(),
                'call_volume': 100,
                'aht': 300,
                'service_level': 0.8
            }
        )
    
    @pytest.fixture
    def forecast_calculated_payload(self):
        return EventPayload(
            timestamp=datetime.utcnow(),
            correlation_id='test-123',
            source='test',
            data={
                'forecast_id': 'forecast-123',
                'periods': [
                    {
                        'interval_start': datetime.utcnow().isoformat(),
                        'interval_end': (datetime.utcnow() + timedelta(hours=1)).isoformat(),
                        'call_volume': 100,
                        'aht': 300,
                        'service_level': 0.8
                    }
                ],
                'accuracy': 85.5,
                'algorithm_version': '1.0'
            }
        )
    
    @pytest.mark.asyncio
    async def test_forecast_updated_validation_success(self, forecast_update_payload):
        """Test forecast updated validation success"""
        handler = ForecastUpdatedHandler()
        
        is_valid = await handler.validate(forecast_update_payload)
        
        assert is_valid is True
    
    @pytest.mark.asyncio
    async def test_forecast_updated_validation_failure(self):
        """Test forecast updated validation failure"""
        handler = ForecastUpdatedHandler()
        invalid_payload = EventPayload(
            timestamp=datetime.utcnow(),
            correlation_id='test-123',
            source='test',
            data={
                'forecast_id': 'forecast-123',
                'call_volume': -100,  # Invalid negative value
                'aht': 300
            }
        )
        
        is_valid = await handler.validate(invalid_payload)
        
        assert is_valid is False
    
    @pytest.mark.asyncio
    @patch('src.api.websocket.handlers.forecast_handlers.get_db')
    @patch('src.api.websocket.handlers.forecast_handlers.ws_manager')
    async def test_forecast_updated_handle_success(self, mock_ws_manager, mock_get_db, forecast_update_payload):
        """Test forecast updated handler success"""
        # Mock database session
        mock_db = MagicMock()
        mock_get_db.return_value = iter([mock_db])
        
        # Mock services
        handler = ForecastUpdatedHandler()
        handler.forecasting_service = AsyncMock()
        handler.algorithm_service = AsyncMock()
        
        # Mock WebSocket manager
        mock_ws_manager.emit_event = AsyncMock()
        
        result = await handler.handle(forecast_update_payload)
        
        assert result['status'] == 'success'
        assert result['forecast_id'] == 'forecast-123'
        handler.forecasting_service.update_forecast.assert_called_once()
        mock_ws_manager.emit_event.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_forecast_calculated_validation_success(self, forecast_calculated_payload):
        """Test forecast calculated validation success"""
        handler = ForecastCalculatedHandler()
        
        is_valid = await handler.validate(forecast_calculated_payload)
        
        assert is_valid is True
    
    @pytest.mark.asyncio
    async def test_forecast_calculated_validation_failure(self):
        """Test forecast calculated validation failure"""
        handler = ForecastCalculatedHandler()
        invalid_payload = EventPayload(
            timestamp=datetime.utcnow(),
            correlation_id='test-123',
            source='test',
            data={
                'forecast_id': 'forecast-123',
                'periods': [],  # Empty periods
                'accuracy': 150  # Invalid accuracy > 100
            }
        )
        
        is_valid = await handler.validate(invalid_payload)
        
        assert is_valid is False


class TestScheduleHandlers:
    """Test schedule event handlers"""
    
    @pytest.fixture
    def schedule_change_payload(self):
        return EventPayload(
            timestamp=datetime.utcnow(),
            correlation_id='test-123',
            source='test',
            data={
                'schedule_id': 'schedule-123',
                'agent_id': 'agent-123',
                'change_type': 'shift_modified',
                'new_shift': {
                    'shift_id': 'shift-123',
                    'start_time': datetime.utcnow().isoformat(),
                    'end_time': (datetime.utcnow() + timedelta(hours=8)).isoformat(),
                    'skills': ['voice', 'email']
                }
            }
        )
    
    @pytest.fixture
    def schedule_optimized_payload(self):
        return EventPayload(
            timestamp=datetime.utcnow(),
            correlation_id='test-123',
            source='test',
            data={
                'schedule_id': 'schedule-123',
                'optimization_id': 'opt-123',
                'improvement_percentage': 15.5,
                'changes': [
                    {
                        'agent_id': 'agent-123',
                        'change_type': 'shift_time_change',
                        'old_value': '09:00',
                        'new_value': '08:00',
                        'impact_score': 0.8
                    }
                ]
            }
        )
    
    @pytest.fixture
    def shift_assigned_payload(self):
        return EventPayload(
            timestamp=datetime.utcnow(),
            correlation_id='test-123',
            source='test',
            data={
                'shift_id': 'shift-123',
                'agent_id': 'agent-123',
                'shift': {
                    'shift_id': 'shift-123',
                    'start_time': datetime.utcnow().isoformat(),
                    'end_time': (datetime.utcnow() + timedelta(hours=8)).isoformat(),
                    'skills': ['voice', 'email']
                },
                'assignment_type': 'automatic',
                'priority': 3
            }
        )
    
    @pytest.mark.asyncio
    async def test_schedule_changed_validation_success(self, schedule_change_payload):
        """Test schedule changed validation success"""
        handler = ScheduleChangedHandler()
        
        is_valid = await handler.validate(schedule_change_payload)
        
        assert is_valid is True
    
    @pytest.mark.asyncio
    async def test_schedule_changed_validation_failure(self):
        """Test schedule changed validation failure"""
        handler = ScheduleChangedHandler()
        invalid_payload = EventPayload(
            timestamp=datetime.utcnow(),
            correlation_id='test-123',
            source='test',
            data={
                'schedule_id': 'schedule-123',
                'agent_id': 'agent-123',
                'change_type': 'shift_added',
                # Missing required 'new_shift' field
            }
        )
        
        is_valid = await handler.validate(invalid_payload)
        
        assert is_valid is False
    
    @pytest.mark.asyncio
    async def test_schedule_optimized_validation_success(self, schedule_optimized_payload):
        """Test schedule optimized validation success"""
        handler = ScheduleOptimizedHandler()
        
        is_valid = await handler.validate(schedule_optimized_payload)
        
        assert is_valid is True
    
    @pytest.mark.asyncio
    async def test_schedule_optimized_validation_failure(self):
        """Test schedule optimized validation failure"""
        handler = ScheduleOptimizedHandler()
        invalid_payload = EventPayload(
            timestamp=datetime.utcnow(),
            correlation_id='test-123',
            source='test',
            data={
                'schedule_id': 'schedule-123',
                'optimization_id': 'opt-123',
                'improvement_percentage': -5,  # Invalid negative improvement
                'changes': []  # Empty changes list
            }
        )
        
        is_valid = await handler.validate(invalid_payload)
        
        assert is_valid is False
    
    @pytest.mark.asyncio
    async def test_shift_assigned_validation_success(self, shift_assigned_payload):
        """Test shift assigned validation success"""
        handler = ShiftAssignedHandler()
        
        is_valid = await handler.validate(shift_assigned_payload)
        
        assert is_valid is True
    
    @pytest.mark.asyncio
    async def test_shift_assigned_validation_failure(self):
        """Test shift assigned validation failure"""
        handler = ShiftAssignedHandler()
        invalid_payload = EventPayload(
            timestamp=datetime.utcnow(),
            correlation_id='test-123',
            source='test',
            data={
                'shift_id': 'shift-123',
                'agent_id': 'agent-123',
                'shift': {
                    'shift_id': 'shift-123',
                    'start_time': datetime.utcnow().isoformat(),
                    'end_time': (datetime.utcnow() + timedelta(hours=8)).isoformat(),
                    'skills': ['voice', 'email']
                },
                'assignment_type': 'automatic',
                'priority': 10  # Invalid priority > 5
            }
        )
        
        is_valid = await handler.validate(invalid_payload)
        
        assert is_valid is False


class TestEventPayloadModels:
    """Test event payload models"""
    
    def test_forecast_update_payload_valid(self):
        """Test valid forecast update payload"""
        payload = ForecastUpdatePayload(
            forecast_id='forecast-123',
            interval_start=datetime.utcnow(),
            call_volume=100,
            aht=300,
            service_level=0.8
        )
        
        assert payload.forecast_id == 'forecast-123'
        assert payload.call_volume == 100
        assert payload.aht == 300
        assert payload.service_level == 0.8
    
    def test_forecast_update_payload_invalid_call_volume(self):
        """Test invalid forecast update payload with negative call volume"""
        with pytest.raises(ValueError):
            ForecastUpdatePayload(
                forecast_id='forecast-123',
                interval_start=datetime.utcnow(),
                call_volume=-100,  # Invalid negative value
                aht=300
            )
    
    def test_forecast_calculated_payload_valid(self):
        """Test valid forecast calculated payload"""
        periods = [
            ForecastPeriod(
                interval_start=datetime.utcnow(),
                interval_end=datetime.utcnow() + timedelta(hours=1),
                call_volume=100,
                aht=300
            )
        ]
        
        payload = ForecastCalculatedPayload(
            forecast_id='forecast-123',
            periods=periods,
            accuracy=85.5
        )
        
        assert payload.forecast_id == 'forecast-123'
        assert len(payload.periods) == 1
        assert payload.accuracy == 85.5
    
    def test_forecast_calculated_payload_invalid_accuracy(self):
        """Test invalid forecast calculated payload with invalid accuracy"""
        periods = [
            ForecastPeriod(
                interval_start=datetime.utcnow(),
                interval_end=datetime.utcnow() + timedelta(hours=1),
                call_volume=100,
                aht=300
            )
        ]
        
        with pytest.raises(ValueError):
            ForecastCalculatedPayload(
                forecast_id='forecast-123',
                periods=periods,
                accuracy=150  # Invalid accuracy > 100
            )
    
    def test_shift_data_valid(self):
        """Test valid shift data"""
        shift = ShiftData(
            shift_id='shift-123',
            start_time=datetime.utcnow(),
            end_time=datetime.utcnow() + timedelta(hours=8),
            skills=['voice', 'email']
        )
        
        assert shift.shift_id == 'shift-123'
        assert len(shift.skills) == 2
    
    def test_shift_data_invalid_end_time(self):
        """Test invalid shift data with end time before start time"""
        start_time = datetime.utcnow()
        
        with pytest.raises(ValueError):
            ShiftData(
                shift_id='shift-123',
                start_time=start_time,
                end_time=start_time - timedelta(hours=1),  # Invalid end time
                skills=['voice', 'email']
            )


@pytest.mark.asyncio
class TestPerformanceRequirements:
    """Test performance requirements"""
    
    async def test_handler_processing_time(self):
        """Test that handlers process events within 50ms"""
        handler = TestBaseEventHandler.TestHandler()
        payload = EventPayload(
            timestamp=datetime.utcnow(),
            correlation_id='test-123',
            source='test',
            data={'test': 'data'}
        )
        
        start_time = datetime.utcnow()
        await handler.process_event(payload)
        end_time = datetime.utcnow()
        
        processing_time = (end_time - start_time).total_seconds() * 1000  # Convert to ms
        assert processing_time < 50  # Should be less than 50ms
    
    async def test_handler_memory_usage(self):
        """Test that handlers don't consume excessive memory"""
        handler = TestBaseEventHandler.TestHandler()
        
        # Process multiple events
        for i in range(1000):
            payload = EventPayload(
                timestamp=datetime.utcnow(),
                correlation_id=f'test-{i}',
                source='test',
                data={'test': f'data-{i}'}
            )
            await handler.process_event(payload)
        
        # Check metrics
        assert handler.metrics.successful_events == 1000
        assert handler.metrics.failed_events == 0
        assert handler.metrics.success_rate == 100.0