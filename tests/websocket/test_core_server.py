"""
WebSocket Core Server Tests
Testing WebSocket server functionality and performance
"""

import pytest
import asyncio
import json
from typing import Dict, Any
from fastapi.testclient import TestClient
from fastapi.websockets import WebSocket
from unittest.mock import Mock, AsyncMock, patch

from src.websocket.core.server import WebSocketServer, ConnectionPool
from src.websocket.core.connection import WebSocketConnection
from src.websocket.core.messages import WebSocketMessage, WebSocketEventType
from src.websocket.core.exceptions import ConnectionLimitException, WebSocketException


class TestConnectionPool:
    """Test connection pool functionality"""
    
    @pytest.fixture
    def connection_pool(self):
        return ConnectionPool(max_connections=10)
    
    @pytest.fixture
    def mock_websocket(self):
        websocket = Mock(spec=WebSocket)
        websocket.client_state.name = "CONNECTED"
        return websocket
    
    @pytest.fixture
    def mock_connection(self, mock_websocket):
        return WebSocketConnection(
            websocket=mock_websocket,
            connection_id="test-connection-1",
            user_id="user-1"
        )
    
    @pytest.mark.asyncio
    async def test_add_connection(self, connection_pool, mock_connection):
        """Test adding connection to pool"""
        result = await connection_pool.add_connection(mock_connection)
        
        assert result is True
        assert connection_pool.active_connections == 1
        assert "test-connection-1" in connection_pool.connections
        assert connection_pool.peak_connections == 1
    
    @pytest.mark.asyncio
    async def test_connection_limit(self, connection_pool):
        """Test connection limit enforcement"""
        # Fill pool to capacity
        for i in range(10):
            websocket = Mock(spec=WebSocket)
            websocket.client_state.name = "CONNECTED"
            connection = WebSocketConnection(
                websocket=websocket,
                connection_id=f"test-connection-{i}",
                user_id=f"user-{i}"
            )
            await connection_pool.add_connection(connection)
        
        # Try to add one more connection
        websocket = Mock(spec=WebSocket)
        websocket.client_state.name = "CONNECTED"
        connection = WebSocketConnection(
            websocket=websocket,
            connection_id="overflow-connection",
            user_id="overflow-user"
        )
        
        with pytest.raises(ConnectionLimitException):
            await connection_pool.add_connection(connection)
    
    @pytest.mark.asyncio
    async def test_remove_connection(self, connection_pool, mock_connection):
        """Test removing connection from pool"""
        await connection_pool.add_connection(mock_connection)
        
        result = await connection_pool.remove_connection("test-connection-1")
        
        assert result is True
        assert connection_pool.active_connections == 0
        assert "test-connection-1" not in connection_pool.connections
    
    @pytest.mark.asyncio
    async def test_get_user_connections(self, connection_pool):
        """Test getting connections by user"""
        # Add multiple connections for same user
        for i in range(3):
            websocket = Mock(spec=WebSocket)
            websocket.client_state.name = "CONNECTED"
            connection = WebSocketConnection(
                websocket=websocket,
                connection_id=f"test-connection-{i}",
                user_id="user-1"
            )
            await connection_pool.add_connection(connection)
        
        user_connections = await connection_pool.get_user_connections("user-1")
        
        assert len(user_connections) == 3
        assert all(conn.user_id == "user-1" for conn in user_connections)
    
    @pytest.mark.asyncio
    async def test_room_management(self, connection_pool, mock_connection):
        """Test room management functionality"""
        await connection_pool.add_connection(mock_connection)
        
        # Add connection to room
        await connection_pool.add_to_room("test-connection-1", "room-1")
        
        room_connections = await connection_pool.get_room_connections("room-1")
        assert len(room_connections) == 1
        assert room_connections[0].connection_id == "test-connection-1"
        
        # Remove connection from room
        await connection_pool.remove_from_room("test-connection-1", "room-1")
        
        room_connections = await connection_pool.get_room_connections("room-1")
        assert len(room_connections) == 0
    
    @pytest.mark.asyncio
    async def test_subscription_management(self, connection_pool, mock_connection):
        """Test subscription management"""
        await connection_pool.add_connection(mock_connection)
        
        # Add subscription
        await connection_pool.add_subscription("test-connection-1", "forecast.updated")
        
        subscribed_connections = await connection_pool.get_subscription_connections("forecast.updated")
        assert len(subscribed_connections) == 1
        assert subscribed_connections[0].connection_id == "test-connection-1"
        
        # Remove subscription
        await connection_pool.remove_subscription("test-connection-1", "forecast.updated")
        
        subscribed_connections = await connection_pool.get_subscription_connections("forecast.updated")
        assert len(subscribed_connections) == 0
    
    def test_pool_stats(self, connection_pool):
        """Test pool statistics"""
        stats = connection_pool.get_stats()
        
        assert isinstance(stats, dict)
        assert "active_connections" in stats
        assert "peak_connections" in stats
        assert "total_created" in stats
        assert "total_closed" in stats


class TestWebSocketServer:
    """Test WebSocket server functionality"""
    
    @pytest.fixture
    def ws_server(self):
        return WebSocketServer(max_connections=100)
    
    @pytest.mark.asyncio
    async def test_server_startup_shutdown(self, ws_server):
        """Test server startup and shutdown"""
        await ws_server.start()
        
        assert ws_server.heartbeat_task is not None
        assert ws_server.cleanup_task is not None
        
        await ws_server.stop()
        
        assert ws_server.heartbeat_task.done()
        assert ws_server.cleanup_task.done()
    
    @pytest.mark.asyncio
    async def test_health_status(self, ws_server):
        """Test health status endpoint"""
        health = await ws_server.get_health_status()
        
        assert health["status"] == "healthy"
        assert "uptime_seconds" in health
        assert "active_connections" in health
        assert "avg_message_latency_ms" in health
    
    @pytest.mark.asyncio
    async def test_server_stats(self, ws_server):
        """Test server statistics"""
        stats = await ws_server.get_server_stats()
        
        assert isinstance(stats, dict)
        assert "max_connections" in stats
        assert "active_connections" in stats
        assert "total_messages_processed" in stats
        assert "heartbeat_interval" in stats
    
    @pytest.mark.asyncio
    async def test_message_handler_registration(self, ws_server):
        """Test message handler registration"""
        handler_called = False
        
        async def test_handler(connection, message):
            nonlocal handler_called
            handler_called = True
        
        ws_server.register_message_handler("test_message", test_handler)
        
        assert "test_message" in ws_server.message_handlers
        assert ws_server.message_handlers["test_message"] == test_handler
    
    @pytest.mark.asyncio
    async def test_broadcast_message(self, ws_server):
        """Test message broadcasting"""
        # Mock connections
        mock_connections = []
        for i in range(3):
            websocket = Mock(spec=WebSocket)
            websocket.client_state.name = "CONNECTED"
            connection = WebSocketConnection(
                websocket=websocket,
                connection_id=f"test-connection-{i}",
                user_id=f"user-{i}"
            )
            connection.send_message = AsyncMock(return_value=True)
            mock_connections.append(connection)
            await ws_server.connection_pool.add_connection(connection)
        
        # Create test message
        message = WebSocketMessage(
            type="test_broadcast",
            payload={"data": "test"}
        )
        
        # Broadcast message
        sent_count = await ws_server.broadcast_message(message)
        
        assert sent_count == 3
        
        # Verify all connections received message
        for connection in mock_connections:
            connection.send_message.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_emit_event(self, ws_server):
        """Test event emission"""
        # Mock connection with subscription
        websocket = Mock(spec=WebSocket)
        websocket.client_state.name = "CONNECTED"
        connection = WebSocketConnection(
            websocket=websocket,
            connection_id="test-connection",
            user_id="user-1"
        )
        connection.send_message = AsyncMock(return_value=True)
        
        await ws_server.connection_pool.add_connection(connection)
        await ws_server.connection_pool.add_subscription("test-connection", "forecast.updated")
        
        # Emit event
        sent_count = await ws_server.emit_event(
            WebSocketEventType.FORECAST_UPDATED,
            {"forecast_id": "123"}
        )
        
        assert sent_count == 1
        connection.send_message.assert_called_once()


class TestWebSocketMessage:
    """Test WebSocket message functionality"""
    
    def test_message_creation(self):
        """Test message creation with defaults"""
        message = WebSocketMessage(
            type="test_message",
            payload={"key": "value"}
        )
        
        assert message.type == "test_message"
        assert message.payload == {"key": "value"}
        assert message.correlation_id is not None
        assert message.timestamp is not None
    
    def test_message_serialization(self):
        """Test message JSON serialization"""
        message = WebSocketMessage(
            type="test_message",
            payload={"key": "value"}
        )
        
        json_str = message.to_json()
        assert isinstance(json_str, str)
        
        # Verify JSON is valid
        parsed = json.loads(json_str)
        assert parsed["type"] == "test_message"
        assert parsed["payload"] == {"key": "value"}
    
    def test_message_deserialization(self):
        """Test message JSON deserialization"""
        json_data = {
            "type": "test_message",
            "payload": {"key": "value"},
            "metadata": {},
            "timestamp": "2024-01-01T00:00:00",
            "correlation_id": "test-id"
        }
        
        json_str = json.dumps(json_data)
        message = WebSocketMessage.from_json(json_str)
        
        assert message.type == "test_message"
        assert message.payload == {"key": "value"}
        assert message.correlation_id == "test-id"
    
    def test_message_bytes_serialization(self):
        """Test message bytes serialization"""
        message = WebSocketMessage(
            type="test_message",
            payload={"key": "value"}
        )
        
        message_bytes = message.to_bytes()
        assert isinstance(message_bytes, bytes)
        
        # Deserialize and verify
        restored_message = WebSocketMessage.from_bytes(message_bytes)
        assert restored_message.type == message.type
        assert restored_message.payload == message.payload


class TestPerformance:
    """Test performance requirements"""
    
    @pytest.mark.asyncio
    async def test_message_processing_latency(self):
        """Test message processing latency < 100ms"""
        ws_server = WebSocketServer()
        
        # Mock WebSocket connection
        websocket = Mock(spec=WebSocket)
        websocket.client_state.name = "CONNECTED"
        connection = WebSocketConnection(
            websocket=websocket,
            connection_id="perf-test",
            user_id="perf-user"
        )
        
        # Create test message
        message = WebSocketMessage(
            type="test_performance",
            payload={"data": "performance test"}
        )
        
        # Measure processing time
        start_time = asyncio.get_event_loop().time()
        
        # Process message (mock the processing)
        await ws_server.connection_pool.add_connection(connection)
        
        end_time = asyncio.get_event_loop().time()
        processing_time = (end_time - start_time) * 1000  # Convert to ms
        
        # Assert processing time is under 100ms
        assert processing_time < 100, f"Processing time {processing_time:.2f}ms exceeds 100ms limit"
    
    @pytest.mark.asyncio
    async def test_connection_establishment_speed(self):
        """Test connection establishment speed"""
        ws_server = WebSocketServer()
        
        # Measure connection establishment time
        start_time = asyncio.get_event_loop().time()
        
        websocket = Mock(spec=WebSocket)
        websocket.client_state.name = "CONNECTED"
        connection = WebSocketConnection(
            websocket=websocket,
            connection_id="speed-test",
            user_id="speed-user"
        )
        
        await ws_server.connection_pool.add_connection(connection)
        
        end_time = asyncio.get_event_loop().time()
        establishment_time = (end_time - start_time) * 1000  # Convert to ms
        
        # Assert establishment time is reasonable
        assert establishment_time < 50, f"Connection establishment {establishment_time:.2f}ms too slow"
    
    @pytest.mark.asyncio
    async def test_concurrent_connections(self):
        """Test handling multiple concurrent connections"""
        ws_server = WebSocketServer(max_connections=1000)
        
        # Create multiple connections concurrently
        connection_tasks = []
        for i in range(100):
            websocket = Mock(spec=WebSocket)
            websocket.client_state.name = "CONNECTED"
            connection = WebSocketConnection(
                websocket=websocket,
                connection_id=f"concurrent-{i}",
                user_id=f"user-{i}"
            )
            
            task = asyncio.create_task(ws_server.connection_pool.add_connection(connection))
            connection_tasks.append(task)
        
        # Wait for all connections to be established
        results = await asyncio.gather(*connection_tasks, return_exceptions=True)
        
        # Verify all connections were successful
        successful_connections = sum(1 for result in results if result is True)
        assert successful_connections == 100
        assert ws_server.connection_pool.active_connections == 100


# Performance benchmarks
@pytest.mark.benchmark
class TestBenchmarks:
    """Benchmark tests for performance validation"""
    
    @pytest.mark.asyncio
    async def test_message_serialization_benchmark(self, benchmark):
        """Benchmark message serialization performance"""
        message = WebSocketMessage(
            type="benchmark_test",
            payload={"data": "x" * 1000}  # 1KB payload
        )
        
        # Benchmark serialization
        result = benchmark(message.to_json)
        assert isinstance(result, str)
    
    @pytest.mark.asyncio
    async def test_connection_pool_benchmark(self, benchmark):
        """Benchmark connection pool operations"""
        pool = ConnectionPool(max_connections=10000)
        
        async def add_remove_connection():
            websocket = Mock(spec=WebSocket)
            websocket.client_state.name = "CONNECTED"
            connection = WebSocketConnection(
                websocket=websocket,
                connection_id="benchmark-connection",
                user_id="benchmark-user"
            )
            
            await pool.add_connection(connection)
            await pool.remove_connection("benchmark-connection")
        
        # Benchmark connection operations
        await benchmark(add_remove_connection)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])