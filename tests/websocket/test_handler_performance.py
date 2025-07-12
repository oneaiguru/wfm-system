"""
Performance tests for WebSocket event handlers
Tests throughput, latency, and memory usage
"""

import pytest
import asyncio
import time
import psutil
import gc
from datetime import datetime, timedelta
from typing import List, Dict, Any
from concurrent.futures import ThreadPoolExecutor
from unittest.mock import AsyncMock, MagicMock, patch

from src.api.websocket.handlers.base import BaseEventHandler, EventPayload, EventHandlerRegistry
from src.api.websocket.handlers.forecast_handlers import ForecastUpdatedHandler, ForecastCalculatedHandler
from src.api.websocket.handlers.schedule_handlers import ScheduleChangedHandler, ScheduleOptimizedHandler, ShiftAssignedHandler


class MockFastHandler(BaseEventHandler):
    """Mock handler for performance testing"""
    
    def __init__(self):
        super().__init__('mock.fast')
        self.process_count = 0
    
    async def validate(self, payload: EventPayload) -> bool:
        return True
    
    async def handle(self, payload: EventPayload) -> Dict[str, Any]:
        self.process_count += 1
        return {'status': 'success', 'count': self.process_count}


class MockSlowHandler(BaseEventHandler):
    """Mock slow handler for performance testing"""
    
    def __init__(self, delay_ms: int = 100):
        super().__init__('mock.slow')
        self.delay_ms = delay_ms
    
    async def validate(self, payload: EventPayload) -> bool:
        return True
    
    async def handle(self, payload: EventPayload) -> Dict[str, Any]:
        await asyncio.sleep(self.delay_ms / 1000)  # Convert ms to seconds
        return {'status': 'success', 'delay': self.delay_ms}


@pytest.mark.asyncio
class TestHandlerPerformance:
    """Test individual handler performance"""
    
    async def test_processing_time_under_50ms(self):
        """Test that handlers process events under 50ms"""
        handler = MockFastHandler()
        payload = EventPayload(
            timestamp=datetime.utcnow(),
            correlation_id='test-123',
            source='test',
            data={'test': 'data'}
        )
        
        start_time = time.perf_counter()
        result = await handler.process_event(payload)
        end_time = time.perf_counter()
        
        processing_time_ms = (end_time - start_time) * 1000
        
        assert result is not None
        assert processing_time_ms < 50, f"Processing time {processing_time_ms:.2f}ms exceeds 50ms limit"
    
    async def test_throughput_1000_events_per_second(self):
        """Test that handlers can process 1000+ events per second"""
        handler = MockFastHandler()
        num_events = 1000
        
        # Create test payloads
        payloads = [
            EventPayload(
                timestamp=datetime.utcnow(),
                correlation_id=f'test-{i}',
                source='test',
                data={'test': f'data-{i}'}
            )
            for i in range(num_events)
        ]
        
        # Process events
        start_time = time.perf_counter()
        
        tasks = [handler.process_event(payload) for payload in payloads]
        results = await asyncio.gather(*tasks)
        
        end_time = time.perf_counter()
        
        # Calculate throughput
        total_time = end_time - start_time
        throughput = num_events / total_time
        
        # Check results
        assert len(results) == num_events
        assert all(result is not None for result in results)
        assert throughput >= 1000, f"Throughput {throughput:.2f} events/sec is below 1000 events/sec"
    
    async def test_memory_usage_under_100mb(self):
        """Test that handler registry uses less than 100MB memory"""
        registry = EventHandlerRegistry()
        
        # Register multiple handlers
        handlers = [MockFastHandler() for _ in range(50)]
        for i, handler in enumerate(handlers):
            registry.register(f'test.handler.{i}', handler)
        
        # Get initial memory usage
        process = psutil.Process()
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB
        
        # Process many events
        num_events = 10000
        for i in range(num_events):
            payload = EventPayload(
                timestamp=datetime.utcnow(),
                correlation_id=f'test-{i}',
                source='test',
                data={'test': f'data-{i}'}
            )
            
            # Process through different handlers
            handler_idx = i % len(handlers)
            await registry.process(f'test.handler.{handler_idx}', payload)
        
        # Force garbage collection
        gc.collect()
        
        # Get final memory usage
        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_increase = final_memory - initial_memory
        
        assert memory_increase < 100, f"Memory increase {memory_increase:.2f}MB exceeds 100MB limit"
    
    async def test_error_rate_under_0_1_percent(self):
        """Test that error rate is under 0.1%"""
        handler = MockFastHandler()
        num_events = 10000
        
        # Create some invalid payloads to test error handling
        payloads = []
        for i in range(num_events):
            if i % 1000 == 0:  # 0.1% invalid payloads
                # Create invalid payload that will cause validation to fail
                payload = EventPayload(
                    timestamp=datetime.utcnow(),
                    correlation_id=f'test-{i}',
                    source='test',
                    data=None  # This might cause issues
                )
                # Override validation to fail occasionally
                if i % 2000 == 0:
                    payload.data = {'invalid': True}
            else:
                payload = EventPayload(
                    timestamp=datetime.utcnow(),
                    correlation_id=f'test-{i}',
                    source='test',
                    data={'test': f'data-{i}'}
                )
            payloads.append(payload)
        
        # Process all events
        tasks = [handler.process_event(payload) for payload in payloads]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Count errors
        successful_results = [r for r in results if isinstance(r, dict) and r is not None]
        error_count = len(results) - len(successful_results)
        error_rate = (error_count / num_events) * 100
        
        assert error_rate < 0.1, f"Error rate {error_rate:.3f}% exceeds 0.1% limit"


@pytest.mark.asyncio
class TestConcurrentEventProcessing:
    """Test concurrent event processing scenarios"""
    
    async def test_concurrent_different_event_types(self):
        """Test processing different event types concurrently"""
        registry = EventHandlerRegistry()
        
        # Register different handlers
        forecast_handler = MockFastHandler()
        forecast_handler.event_type = 'forecast.updated'
        schedule_handler = MockFastHandler()
        schedule_handler.event_type = 'schedule.changed'
        
        registry.register('forecast.updated', forecast_handler)
        registry.register('schedule.changed', schedule_handler)
        
        # Create mixed event types
        forecast_payloads = [
            EventPayload(
                timestamp=datetime.utcnow(),
                correlation_id=f'forecast-{i}',
                source='test',
                data={'forecast_id': f'forecast-{i}'}
            )
            for i in range(500)
        ]
        
        schedule_payloads = [
            EventPayload(
                timestamp=datetime.utcnow(),
                correlation_id=f'schedule-{i}',
                source='test',
                data={'schedule_id': f'schedule-{i}'}
            )
            for i in range(500)
        ]
        
        # Process concurrently
        start_time = time.perf_counter()
        
        forecast_tasks = [registry.process('forecast.updated', p) for p in forecast_payloads]
        schedule_tasks = [registry.process('schedule.changed', p) for p in schedule_payloads]
        
        all_results = await asyncio.gather(*forecast_tasks, *schedule_tasks)
        
        end_time = time.perf_counter()
        
        # Verify results
        assert len(all_results) == 1000
        assert all(result is not None for result in all_results)
        
        # Check performance
        total_time = end_time - start_time
        throughput = 1000 / total_time
        assert throughput >= 500, f"Concurrent throughput {throughput:.2f} events/sec is too low"
    
    async def test_high_concurrency_stress(self):
        """Test high concurrency stress scenarios"""
        registry = EventHandlerRegistry()
        handler = MockFastHandler()
        registry.register('stress.test', handler)
        
        # Create many concurrent tasks
        num_concurrent = 100
        events_per_task = 100
        
        async def process_batch(batch_id: int):
            """Process a batch of events"""
            results = []
            for i in range(events_per_task):
                payload = EventPayload(
                    timestamp=datetime.utcnow(),
                    correlation_id=f'stress-{batch_id}-{i}',
                    source='test',
                    data={'batch_id': batch_id, 'event_id': i}
                )
                result = await registry.process('stress.test', payload)
                results.append(result)
            return results
        
        # Run concurrent batches
        start_time = time.perf_counter()
        
        tasks = [process_batch(i) for i in range(num_concurrent)]
        batch_results = await asyncio.gather(*tasks)
        
        end_time = time.perf_counter()
        
        # Verify results
        total_events = num_concurrent * events_per_task
        all_results = [result for batch in batch_results for result in batch]
        
        assert len(all_results) == total_events
        assert all(result is not None for result in all_results)
        
        # Check performance
        total_time = end_time - start_time
        throughput = total_events / total_time
        assert throughput >= 1000, f"Stress test throughput {throughput:.2f} events/sec is too low"


@pytest.mark.asyncio
class TestRealWorldScenarios:
    """Test real-world performance scenarios"""
    
    @patch('src.api.websocket.handlers.forecast_handlers.get_db')
    @patch('src.api.websocket.handlers.forecast_handlers.ws_manager')
    async def test_forecast_handler_performance(self, mock_ws_manager, mock_get_db):
        """Test real forecast handler performance"""
        # Mock database and dependencies
        mock_db = MagicMock()
        mock_get_db.return_value = iter([mock_db])
        mock_ws_manager.emit_event = AsyncMock()
        
        handler = ForecastUpdatedHandler()
        handler.forecasting_service = AsyncMock()
        handler.algorithm_service = AsyncMock()
        
        # Create realistic forecast update payloads
        payloads = [
            EventPayload(
                timestamp=datetime.utcnow(),
                correlation_id=f'forecast-{i}',
                source='test',
                data={
                    'forecast_id': f'forecast-{i}',
                    'interval_start': (datetime.utcnow() + timedelta(hours=i)).isoformat(),
                    'call_volume': 100 + i,
                    'aht': 300 + i,
                    'service_level': 0.8
                }
            )
            for i in range(100)
        ]
        
        # Process events and measure performance
        start_time = time.perf_counter()
        
        tasks = [handler.process_event(payload) for payload in payloads]
        results = await asyncio.gather(*tasks)
        
        end_time = time.perf_counter()
        
        # Verify results
        assert len(results) == 100
        successful_results = [r for r in results if r and r.get('status') == 'success']
        assert len(successful_results) >= 95  # At least 95% success rate
        
        # Check performance
        total_time = end_time - start_time
        avg_time_per_event = (total_time / 100) * 1000  # Convert to ms
        assert avg_time_per_event < 50, f"Average processing time {avg_time_per_event:.2f}ms exceeds 50ms"
    
    @patch('src.api.websocket.handlers.schedule_handlers.get_db')
    @patch('src.api.websocket.handlers.schedule_handlers.ws_manager')
    async def test_schedule_handler_performance(self, mock_ws_manager, mock_get_db):
        """Test real schedule handler performance"""
        # Mock database and dependencies
        mock_db = MagicMock()
        mock_get_db.return_value = iter([mock_db])
        mock_ws_manager.emit_event = AsyncMock()
        
        handler = ScheduleChangedHandler()
        handler.algorithm_service = AsyncMock()
        
        # Mock database query
        mock_agent = MagicMock()
        mock_agent.id = 'agent-123'
        mock_db.query.return_value.filter.return_value.first.return_value = mock_agent
        
        # Create realistic schedule change payloads
        payloads = [
            EventPayload(
                timestamp=datetime.utcnow(),
                correlation_id=f'schedule-{i}',
                source='test',
                data={
                    'schedule_id': f'schedule-{i}',
                    'agent_id': 'agent-123',
                    'change_type': 'shift_modified',
                    'new_shift': {
                        'shift_id': f'shift-{i}',
                        'start_time': (datetime.utcnow() + timedelta(days=i)).isoformat(),
                        'end_time': (datetime.utcnow() + timedelta(days=i, hours=8)).isoformat(),
                        'skills': ['voice', 'email']
                    }
                }
            )
            for i in range(100)
        ]
        
        # Process events and measure performance
        start_time = time.perf_counter()
        
        tasks = [handler.process_event(payload) for payload in payloads]
        results = await asyncio.gather(*tasks)
        
        end_time = time.perf_counter()
        
        # Verify results
        assert len(results) == 100
        successful_results = [r for r in results if r and r.get('status') == 'success']
        assert len(successful_results) >= 95  # At least 95% success rate
        
        # Check performance
        total_time = end_time - start_time
        avg_time_per_event = (total_time / 100) * 1000  # Convert to ms
        assert avg_time_per_event < 50, f"Average processing time {avg_time_per_event:.2f}ms exceeds 50ms"


@pytest.mark.asyncio
class TestMemoryLeakDetection:
    """Test for memory leaks in event handlers"""
    
    async def test_no_memory_leak_with_repeated_processing(self):
        """Test that repeated event processing doesn't cause memory leaks"""
        registry = EventHandlerRegistry()
        handler = MockFastHandler()
        registry.register('memory.test', handler)
        
        # Get initial memory usage
        process = psutil.Process()
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB
        
        # Process events in batches
        num_batches = 10
        events_per_batch = 1000
        
        for batch in range(num_batches):
            payloads = [
                EventPayload(
                    timestamp=datetime.utcnow(),
                    correlation_id=f'memory-{batch}-{i}',
                    source='test',
                    data={'batch': batch, 'event': i}
                )
                for i in range(events_per_batch)
            ]
            
            tasks = [registry.process('memory.test', p) for p in payloads]
            await asyncio.gather(*tasks)
            
            # Force garbage collection after each batch
            gc.collect()
        
        # Get final memory usage
        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_increase = final_memory - initial_memory
        
        # Memory increase should be minimal (less than 50MB)
        assert memory_increase < 50, f"Memory leak detected: {memory_increase:.2f}MB increase"
    
    async def test_handler_registry_cleanup(self):
        """Test that handler registry properly cleans up resources"""
        registry = EventHandlerRegistry()
        
        # Register many handlers
        handlers = [MockFastHandler() for _ in range(100)]
        for i, handler in enumerate(handlers):
            registry.register(f'cleanup.test.{i}', handler)
        
        # Get initial memory
        process = psutil.Process()
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB
        
        # Process events
        for i in range(1000):
            payload = EventPayload(
                timestamp=datetime.utcnow(),
                correlation_id=f'cleanup-{i}',
                source='test',
                data={'event': i}
            )
            
            handler_idx = i % len(handlers)
            await registry.process(f'cleanup.test.{handler_idx}', payload)
        
        # Unregister all handlers
        for i in range(len(handlers)):
            registry.unregister(f'cleanup.test.{i}')
        
        # Force garbage collection
        gc.collect()
        
        # Check that registry is cleaned up
        assert len(registry.handlers) == 0
        
        # Check memory usage
        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_increase = final_memory - initial_memory
        
        # Memory should not increase significantly
        assert memory_increase < 30, f"Registry cleanup failed: {memory_increase:.2f}MB increase"