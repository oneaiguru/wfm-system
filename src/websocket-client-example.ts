/**
 * WFM WebSocket Client Usage Examples
 * Demonstrates how to use the new WebSocket client library
 */

import { 
  WebSocketClient, 
  TypedWebSocketClient, 
  WebSocketEventType, 
  wfmWebSocket,
  ForecastEventPayload,
  ScheduleEventPayload,
  AgentStatusEventPayload,
  QueueMetricsEventPayload
} from './websocket-client';

// ===== EXAMPLE 1: Basic Usage =====

async function basicUsageExample() {
  console.log('=== Basic Usage Example ===');
  
  // Create client instance
  const client = new WebSocketClient({
    url: 'ws://localhost:8000/api/v1/ws',
    client_id: 'dashboard-client-001',
    user_id: 'user-123',
    debug: true,
    auto_reconnect: true
  });
  
  // Handle connection events
  client.onConnect(() => {
    console.log('Connected to WFM WebSocket server');
  });
  
  client.onDisconnect(() => {
    console.log('Disconnected from WFM WebSocket server');
  });
  
  client.onError((error) => {
    console.error('WebSocket error:', error);
  });
  
  // Connect to server
  try {
    await client.connect();
    console.log('Connection established');
  } catch (error) {
    console.error('Failed to connect:', error);
    return;
  }
  
  // Subscribe to events
  client.subscribe(WebSocketEventType.FORECAST_UPDATED, (payload, message) => {
    console.log('Forecast updated:', payload);
  });
  
  client.subscribe(WebSocketEventType.QUEUE_METRICS_UPDATE, (payload, message) => {
    console.log('Queue metrics updated:', payload);
  });
  
  // Join rooms for targeted updates
  client.joinRoom('dashboard-main');
  client.joinRoom('queue-voice');
  
  // Keep running for demo
  setTimeout(() => {
    console.log('Client stats:', client.getStats());
    client.disconnect();
  }, 10000);
}

// ===== EXAMPLE 2: Typed Client Usage =====

async function typedClientExample() {
  console.log('=== Typed Client Example ===');
  
  // Use typed client for better type safety
  const client = new TypedWebSocketClient({
    url: 'ws://localhost:8000/api/v1/ws',
    client_id: 'monitoring-client-002',
    debug: true
  });
  
  await client.connect();
  
  // Type-safe event handlers
  client.onForecastUpdated((payload: ForecastEventPayload) => {
    console.log(`Forecast ${payload.forecast_id} updated:`);
    console.log(`- Call Volume: ${payload.call_volume}`);
    console.log(`- AHT: ${payload.aht}s`);
    console.log(`- Staffing Requirement: ${payload.staffing_requirement}`);
    
    if (payload.accuracy_metrics) {
      console.log(`- Accuracy: MAPE=${payload.accuracy_metrics.mape}, Bias=${payload.accuracy_metrics.bias}`);
    }
  });
  
  client.onScheduleChanged((payload: ScheduleEventPayload) => {
    console.log(`Schedule ${payload.schedule_id} changed:`);
    console.log(`- Change Type: ${payload.change_type}`);
    console.log(`- Agent: ${payload.agent_id}`);
    
    if (payload.shift_details) {
      console.log(`- Shift: ${payload.shift_details.start} - ${payload.shift_details.end}`);
    }
  });
  
  client.onAgentStatusChanged((payload: AgentStatusEventPayload) => {
    console.log(`Agent ${payload.agent_id} status changed:`);
    console.log(`- Status: ${payload.previous_status} → ${payload.status}`);
    console.log(`- Location: ${payload.location}`);
    console.log(`- Skills: ${payload.skills?.join(', ')}`);
  });
  
  client.onQueueMetricsUpdate((payload: QueueMetricsEventPayload) => {
    console.log(`Queue ${payload.queue_id} metrics updated:`);
    console.log(`- Calls in Queue: ${payload.metrics.calls_in_queue}`);
    console.log(`- Avg Wait Time: ${payload.metrics.avg_wait_time}s`);
    console.log(`- Service Level: ${(payload.metrics.service_level * 100).toFixed(1)}%`);
    console.log(`- Abandonment: ${(payload.metrics.abandonment * 100).toFixed(1)}%`);
  });
  
  client.onSLAAlert((payload) => {
    console.log(`🚨 SLA Alert: ${payload.alert_type}`);
    console.log(`- Current: ${payload.current_value}`);
    console.log(`- Threshold: ${payload.threshold}`);
    console.log(`- Severity: ${payload.severity}`);
  });
  
  // Algorithm events
  client.onErlangCalculationComplete((payload) => {
    console.log(`Erlang calculation ${payload.calculation_id} complete:`);
    console.log(`- Execution Time: ${payload.execution_time_ms}ms`);
    console.log(`- Results:`, payload.results);
  });
  
  client.onOptimizationComplete((payload) => {
    console.log(`Optimization ${payload.calculation_id} complete:`);
    console.log(`- Accuracy Score: ${payload.accuracy_score}`);
    console.log(`- Results:`, payload.results);
  });
  
  // Skill management events
  client.onSkillAssigned((payload) => {
    console.log(`Skill ${payload.skill} assigned to agent ${payload.agent_id}`);
    console.log(`- Skill Level: ${payload.skill_level}`);
  });
  
  client.onSkillLevelChanged((payload) => {
    console.log(`Skill level changed for agent ${payload.agent_id}`);
    console.log(`- Skill: ${payload.skill}`);
    console.log(`- Level: ${payload.previous_level} → ${payload.skill_level}`);
  });
  
  // Vacancy and staffing events
  client.onVacancyCreated((payload) => {
    console.log(`New vacancy created: ${payload.position}`);
    console.log(`- Required Skills: ${payload.required_skills.join(', ')}`);
    console.log(`- Department: ${payload.department}`);
  });
  
  client.onStaffingGapDetected((payload) => {
    console.log(`⚠️  Staffing gap detected: ${payload.gap_id}`);
    console.log(`- Gap Size: ${payload.gap_size} agents`);
    console.log(`- Priority: ${payload.priority}`);
    console.log(`- Affected Skills: ${payload.skills_affected.join(', ')}`);
    console.log(`- Suggested Actions: ${payload.suggested_actions.join(', ')}`);
  });
  
  // Subscribe to specific rooms
  client.joinRoom('operations-center');
  client.joinRoom('team-leads');
  
  setTimeout(() => {
    client.disconnect();
  }, 15000);
}

// ===== EXAMPLE 3: Global Instance Usage =====

async function globalInstanceExample() {
  console.log('=== Global Instance Example ===');
  
  // Configure global instance
  const globalClient = wfmWebSocket;
  
  // Use the global instance (convenient for app-wide usage)
  await globalClient.connect();
  
  // Set up comprehensive monitoring
  globalClient.onForecastUpdated((payload) => {
    // Update forecast displays
    updateForecastDashboard(payload);
  });
  
  globalClient.onScheduleChanged((payload) => {
    // Update schedule grids
    updateScheduleGrid(payload);
  });
  
  globalClient.onAgentStatusChanged((payload) => {
    // Update agent status displays
    updateAgentStatusBoard(payload);
  });
  
  globalClient.onQueueMetricsUpdate((payload) => {
    // Update real-time metrics
    updateMetricsDashboard(payload);
  });
  
  globalClient.onSLAAlert((payload) => {
    // Show alert notifications
    showAlert(payload);
  });
  
  setTimeout(() => {
    globalClient.disconnect();
  }, 20000);
}

// ===== EXAMPLE 4: Advanced Features =====

async function advancedFeaturesExample() {
  console.log('=== Advanced Features Example ===');
  
  const client = new TypedWebSocketClient({
    url: 'ws://localhost:8000/api/v1/ws',
    client_id: 'advanced-client-003',
    debug: true,
    auto_reconnect: true,
    reconnect_interval: 5000,
    max_reconnect_attempts: 5,
    heartbeat_interval: 30000
  });
  
  // Connection state monitoring
  client.onConnect(() => {
    console.log('🟢 Connected - Setting up subscriptions');
    
    // Subscribe to all forecast events
    client.onForecastUpdated((payload) => console.log('Forecast updated:', payload.forecast_id));
    client.onForecastCalculated((payload) => console.log('Forecast calculated:', payload.forecast_id));
    client.onForecastError((payload) => console.log('Forecast error:', payload.error_message));
    
    // Join multiple rooms
    client.joinRoom('forecasting-team');
    client.joinRoom('operations-managers');
    client.joinRoom('system-alerts');
  });
  
  client.onDisconnect(() => {
    console.log('🔴 Disconnected - Will attempt to reconnect');
  });
  
  client.onError((error) => {
    console.error('🚨 Connection error:', error.message);
  });
  
  await client.connect();
  
  // Periodic stats reporting
  const statsInterval = setInterval(() => {
    const stats = client.getStats();
    console.log('📊 Client Statistics:', {
      connected: stats.connected,
      subscriptions: stats.subscriptions.size,
      rooms: stats.rooms.size,
      messages_sent: stats.messages_sent,
      messages_received: stats.messages_received,
      reconnect_count: stats.reconnect_count
    });
  }, 30000);
  
  // Cleanup after demo
  setTimeout(() => {
    clearInterval(statsInterval);
    client.disconnect();
  }, 60000);
}

// ===== EXAMPLE 5: Error Handling and Resilience =====

async function errorHandlingExample() {
  console.log('=== Error Handling Example ===');
  
  const client = new TypedWebSocketClient({
    url: 'ws://localhost:8000/api/v1/ws',
    client_id: 'resilient-client-004',
    debug: true,
    auto_reconnect: true,
    max_reconnect_attempts: 3
  });
  
  // Comprehensive error handling
  client.onError((error) => {
    console.error('❌ WebSocket error:', error);
    
    // Log error details
    const stats = client.getStats();
    console.log('Error context:', {
      connected: stats.connected,
      last_error: stats.last_error,
      reconnect_count: stats.reconnect_count
    });
    
    // Implement custom error recovery logic
    if (stats.reconnect_count > 2) {
      console.log('🔄 Too many reconnection attempts, switching to polling mode');
      // Implement fallback to HTTP polling
    }
  });
  
  // Robust event handling with try-catch
  client.onForecastUpdated((payload) => {
    try {
      // Process forecast update
      processForecastUpdate(payload);
    } catch (error) {
      console.error('Error processing forecast update:', error);
      // Log error but don't crash
    }
  });
  
  // Connection recovery monitoring
  client.onConnect(() => {
    console.log('✅ Connection recovered');
    
    // Verify all subscriptions are restored
    const stats = client.getStats();
    console.log(`Restored ${stats.subscriptions.size} subscriptions and ${stats.rooms.size} rooms`);
  });
  
  try {
    await client.connect();
  } catch (error) {
    console.error('Initial connection failed:', error);
    // Implement fallback strategies
  }
  
  setTimeout(() => {
    client.disconnect();
  }, 30000);
}

// ===== HELPER FUNCTIONS =====

function updateForecastDashboard(payload: ForecastEventPayload) {
  console.log(`📈 Updating forecast dashboard for ${payload.forecast_id}`);
  // Implementation would update UI components
}

function updateScheduleGrid(payload: ScheduleEventPayload) {
  console.log(`📅 Updating schedule grid for ${payload.schedule_id}`);
  // Implementation would update schedule components
}

function updateAgentStatusBoard(payload: AgentStatusEventPayload) {
  console.log(`👤 Updating agent status for ${payload.agent_id}: ${payload.status}`);
  // Implementation would update agent status displays
}

function updateMetricsDashboard(payload: QueueMetricsEventPayload) {
  console.log(`📊 Updating metrics dashboard for queue ${payload.queue_id}`);
  // Implementation would update real-time metrics
}

function showAlert(payload: any) {
  console.log(`🚨 Showing alert: ${payload.alert_type} - ${payload.severity}`);
  // Implementation would show UI notifications
}

function processForecastUpdate(payload: ForecastEventPayload) {
  console.log(`🔄 Processing forecast update: ${payload.forecast_id}`);
  // Implementation would process the forecast data
}

// ===== DEMO RUNNER =====

async function runExamples() {
  console.log('🚀 Starting WebSocket Client Examples');
  
  try {
    await basicUsageExample();
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    await typedClientExample();
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    await globalInstanceExample();
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    await advancedFeaturesExample();
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    await errorHandlingExample();
    
    console.log('✅ All examples completed successfully');
  } catch (error) {
    console.error('❌ Example failed:', error);
  }
}

// Export for module usage
export {
  basicUsageExample,
  typedClientExample,
  globalInstanceExample,
  advancedFeaturesExample,
  errorHandlingExample,
  runExamples
};

// Run examples if called directly
if (require.main === module) {
  runExamples();
}

console.log('📚 WebSocket Client Examples Ready');
console.log('   - Basic usage with connection management');
console.log('   - Type-safe event handling for all 15 events');
console.log('   - Global instance for app-wide usage');
console.log('   - Advanced features with resilience');
console.log('   - Comprehensive error handling');