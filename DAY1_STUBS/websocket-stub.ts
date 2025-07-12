// WebSocket Stub for INTEGRATION-OPUS
// This stub allows all agents to start building without waiting for full implementation

export interface WebSocketEvent {
  type: string;
  payload: any;
  timestamp: number;
}

// Core events that other agents can subscribe to
export const WS_EVENTS = {
  // Forecasting events
  FORECAST_UPDATED: 'forecast.updated',
  FORECAST_CALCULATED: 'forecast.calculated',
  FORECAST_ERROR: 'forecast.error',
  
  // Schedule events
  SCHEDULE_CHANGED: 'schedule.changed',
  SCHEDULE_OPTIMIZED: 'schedule.optimized',
  SHIFT_ASSIGNED: 'shift.assigned',
  SHIFT_SWAPPED: 'shift.swapped',
  
  // Real-time monitoring
  AGENT_STATUS_CHANGED: 'agent.status.changed',
  QUEUE_METRICS_UPDATE: 'queue.metrics.update',
  SLA_ALERT: 'sla.alert',
  
  // Skill management
  SKILL_ASSIGNED: 'skill.assigned',
  SKILL_REMOVED: 'skill.removed',
  SKILL_LEVEL_CHANGED: 'skill.level.changed',
  
  // Vacancy events
  VACANCY_CREATED: 'vacancy.created',
  VACANCY_FILLED: 'vacancy.filled',
  STAFFING_GAP_DETECTED: 'staffing.gap.detected',
  
  // Algorithm calculation events
  ERLANG_CALCULATION_COMPLETE: 'erlang.calculation.complete',
  OPTIMIZATION_COMPLETE: 'optimization.complete',
  ACCURACY_METRICS_READY: 'accuracy.metrics.ready'
};

// WebSocket connection stub
export class WebSocketStub {
  private subscribers: Map<string, Function[]> = new Map();
  private isConnected: boolean = false;
  
  connect(): Promise<void> {
    // Stub implementation - instantly "connects"
    return new Promise((resolve) => {
      setTimeout(() => {
        this.isConnected = true;
        this.emit(WS_EVENTS.CONNECTION_ESTABLISHED, {});
        resolve();
      }, 100);
    });
  }
  
  disconnect(): void {
    this.isConnected = false;
    this.subscribers.clear();
  }
  
  subscribe(event: string, callback: Function): void {
    if (!this.subscribers.has(event)) {
      this.subscribers.set(event, []);
    }
    this.subscribers.get(event)!.push(callback);
  }
  
  unsubscribe(event: string, callback: Function): void {
    const callbacks = this.subscribers.get(event);
    if (callbacks) {
      const index = callbacks.indexOf(callback);
      if (index > -1) {
        callbacks.splice(index, 1);
      }
    }
  }
  
  emit(event: string, payload: any): void {
    const callbacks = this.subscribers.get(event);
    if (callbacks) {
      callbacks.forEach(cb => {
        cb({
          type: event,
          payload,
          timestamp: Date.now()
        });
      });
    }
  }
  
  // Stub methods for testing real-time features
  simulateForecastUpdate(forecastId: string): void {
    this.emit(WS_EVENTS.FORECAST_UPDATED, {
      forecastId,
      intervalStart: new Date().toISOString(),
      callVolume: Math.floor(Math.random() * 100) + 50,
      aht: Math.floor(Math.random() * 60) + 180
    });
  }
  
  simulateScheduleChange(scheduleId: string, agentId: string): void {
    this.emit(WS_EVENTS.SCHEDULE_CHANGED, {
      scheduleId,
      agentId,
      changeType: 'shift_modified',
      newShift: {
        start: '09:00',
        end: '17:00',
        skills: ['voice', 'email']
      }
    });
  }
  
  simulateQueueMetrics(queueId: string): void {
    this.emit(WS_EVENTS.QUEUE_METRICS_UPDATE, {
      queueId,
      metrics: {
        callsInQueue: Math.floor(Math.random() * 20),
        avgWaitTime: Math.floor(Math.random() * 300),
        serviceLevel: Math.random() * 0.3 + 0.7,
        abandonment: Math.random() * 0.1
      }
    });
  }
}

// Export singleton instance
export const wsStub = new WebSocketStub();

// Example usage for other agents:
/*
import { wsStub, WS_EVENTS } from './websocket-stub';

// Subscribe to events
wsStub.subscribe(WS_EVENTS.FORECAST_UPDATED, (event) => {
  console.log('Forecast updated:', event.payload);
});

// Connect and start receiving events
await wsStub.connect();

// Emit events (for testing)
wsStub.emit(WS_EVENTS.SCHEDULE_OPTIMIZED, {
  scheduleId: '123',
  optimization: 'complete',
  improvement: 15.5
});
*/