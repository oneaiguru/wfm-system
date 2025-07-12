/**
 * WFM WebSocket Client Library
 * Type-safe WebSocket client for real-time communication with WFM backend
 * Replaces the websocket-stub.ts with production-ready implementation
 */

// ===== TYPE DEFINITIONS =====

export enum WebSocketEventType {
  // Forecasting events
  FORECAST_UPDATED = 'forecast.updated',
  FORECAST_CALCULATED = 'forecast.calculated',
  FORECAST_ERROR = 'forecast.error',
  
  // Schedule events
  SCHEDULE_CHANGED = 'schedule.changed',
  SCHEDULE_OPTIMIZED = 'schedule.optimized',
  SHIFT_ASSIGNED = 'shift.assigned',
  SHIFT_SWAPPED = 'shift.swapped',
  
  // Real-time monitoring
  AGENT_STATUS_CHANGED = 'agent.status.changed',
  QUEUE_METRICS_UPDATE = 'queue.metrics.update',
  SLA_ALERT = 'sla.alert',
  
  // Skill management
  SKILL_ASSIGNED = 'skill.assigned',
  SKILL_REMOVED = 'skill.removed',
  SKILL_LEVEL_CHANGED = 'skill.level.changed',
  
  // Vacancy events
  VACANCY_CREATED = 'vacancy.created',
  VACANCY_FILLED = 'vacancy.filled',
  STAFFING_GAP_DETECTED = 'staffing.gap.detected',
  
  // Algorithm calculation events
  ERLANG_CALCULATION_COMPLETE = 'erlang.calculation.complete',
  OPTIMIZATION_COMPLETE = 'optimization.complete',
  ACCURACY_METRICS_READY = 'accuracy.metrics.ready'
}

// Event payload interfaces - matching backend schemas
export interface ForecastEventPayload {
  forecast_id: string;
  interval_start: string; // ISO datetime string
  call_volume?: number;
  aht?: number;
  staffing_requirement?: number;
  accuracy_metrics?: Record<string, number>;
  error_message?: string;
}

export interface ScheduleEventPayload {
  schedule_id: string;
  agent_id?: string;
  change_type: 'shift_modified' | 'shift_added' | 'shift_removed' | 'optimized';
  shift_details?: Record<string, any>;
  optimization_metrics?: Record<string, number>;
}

export interface AgentStatusEventPayload {
  agent_id: string;
  status: 'available' | 'busy' | 'break' | 'offline';
  previous_status?: string;
  timestamp: string; // ISO datetime string
  location?: string;
  skills?: string[];
}

export interface QueueMetricsEventPayload {
  queue_id: string;
  group_id?: string;
  metrics: Record<string, number>; // calls_in_queue, avg_wait_time, service_level, abandonment
  timestamp: string; // ISO datetime string
  thresholds?: Record<string, number>;
}

export interface SLAAlertEventPayload {
  alert_id: string;
  alert_type: 'service_level' | 'abandonment' | 'wait_time';
  current_value: number;
  threshold: number;
  queue_id?: string;
  group_id?: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  timestamp: string; // ISO datetime string
}

export interface SkillEventPayload {
  agent_id: string;
  skill: string;
  action: 'assigned' | 'removed' | 'level_changed';
  skill_level?: number;
  previous_level?: number;
  timestamp: string; // ISO datetime string
}

export interface VacancyEventPayload {
  vacancy_id: string;
  position: string;
  department?: string;
  required_skills: string[];
  status: 'created' | 'filled' | 'cancelled';
  agent_id?: string; // For filled vacancies
  timestamp: string; // ISO datetime string
}

export interface StaffingGapEventPayload {
  gap_id: string;
  interval_start: string; // ISO datetime string
  interval_end: string; // ISO datetime string
  required_agents: number;
  available_agents: number;
  gap_size: number;
  skills_affected: string[];
  priority: 'low' | 'medium' | 'high' | 'critical';
  suggested_actions: string[];
}

export interface AlgorithmEventPayload {
  calculation_id: string;
  algorithm_type: 'erlang' | 'optimization' | 'accuracy';
  input_parameters: Record<string, any>;
  results: Record<string, any>;
  execution_time_ms: number;
  timestamp: string; // ISO datetime string
  accuracy_score?: number;
}

// Union type for all event payloads
export type EventPayload = 
  | ForecastEventPayload
  | ScheduleEventPayload
  | AgentStatusEventPayload
  | QueueMetricsEventPayload
  | SLAAlertEventPayload
  | SkillEventPayload
  | VacancyEventPayload
  | StaffingGapEventPayload
  | AlgorithmEventPayload
  | Record<string, any>; // Fallback for custom payloads

export interface WebSocketMessage {
  type: string;
  payload: EventPayload;
  timestamp: number;
  client_id?: string;
  room?: string;
  correlation_id?: string;
}

export interface WebSocketConnectionOptions {
  url?: string;
  client_id?: string;
  user_id?: string;
  token?: string;
  auto_reconnect?: boolean;
  reconnect_interval?: number;
  max_reconnect_attempts?: number;
  heartbeat_interval?: number;
  debug?: boolean;
}

export interface WebSocketConnectionStats {
  connected: boolean;
  connected_at?: Date;
  reconnect_count: number;
  last_error?: string;
  subscriptions: Set<string>;
  rooms: Set<string>;
  messages_sent: number;
  messages_received: number;
}

// Event handler types
export type EventHandler<T = EventPayload> = (payload: T, message: WebSocketMessage) => void | Promise<void>;
export type ConnectionEventHandler = (event: Event) => void | Promise<void>;
export type ErrorEventHandler = (error: Error) => void | Promise<void>;

// ===== WEBSOCKET CLIENT IMPLEMENTATION =====

export class WebSocketClient {
  private ws: WebSocket | null = null;
  private options: Required<WebSocketConnectionOptions>;
  private subscribers: Map<string, EventHandler[]> = new Map();
  private connectionHandlers: ConnectionEventHandler[] = [];
  private errorHandlers: ErrorEventHandler[] = [];
  private disconnectHandlers: ConnectionEventHandler[] = [];
  private reconnectTimer: NodeJS.Timeout | null = null;
  private heartbeatTimer: NodeJS.Timeout | null = null;
  private stats: WebSocketConnectionStats;
  private isReconnecting = false;
  private shouldReconnect = true;

  constructor(options: WebSocketConnectionOptions = {}) {
    this.options = {
      url: options.url || 'ws://localhost:8000/api/v1/ws',
      client_id: options.client_id || this.generateClientId(),
      user_id: options.user_id || '',
      token: options.token || '',
      auto_reconnect: options.auto_reconnect ?? true,
      reconnect_interval: options.reconnect_interval || 3000,
      max_reconnect_attempts: options.max_reconnect_attempts || 10,
      heartbeat_interval: options.heartbeat_interval || 30000,
      debug: options.debug ?? false
    };

    this.stats = {
      connected: false,
      reconnect_count: 0,
      subscriptions: new Set(),
      rooms: new Set(),
      messages_sent: 0,
      messages_received: 0
    };

    this.log('WebSocket client initialized', this.options);
  }

  // ===== CONNECTION MANAGEMENT =====

  async connect(): Promise<void> {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.log('Already connected');
      return;
    }

    return new Promise((resolve, reject) => {
      try {
        const url = new URL(this.options.url);
        
        // Add query parameters
        if (this.options.client_id) {
          url.searchParams.set('client_id', this.options.client_id);
        }
        if (this.options.user_id) {
          url.searchParams.set('user_id', this.options.user_id);
        }
        if (this.options.token) {
          url.searchParams.set('token', this.options.token);
        }

        this.ws = new WebSocket(url.toString());

        this.ws.onopen = (event) => {
          this.log('Connected to WebSocket server');
          this.stats.connected = true;
          this.stats.connected_at = new Date();
          this.isReconnecting = false;
          
          // Start heartbeat
          this.startHeartbeat();
          
          // Restore subscriptions and rooms
          this.restoreState();
          
          // Notify connection handlers
          this.connectionHandlers.forEach(handler => {
            try {
              handler(event);
            } catch (error) {
              this.log('Error in connection handler:', error);
            }
          });
          
          resolve();
        };

        this.ws.onmessage = (event) => {
          this.handleMessage(event.data);
        };

        this.ws.onerror = (event) => {
          this.log('WebSocket error:', event);
          this.stats.last_error = 'WebSocket error';
          
          // Notify error handlers
          this.errorHandlers.forEach(handler => {
            try {
              handler(new Error('WebSocket connection error'));
            } catch (error) {
              this.log('Error in error handler:', error);
            }
          });
          
          reject(new Error('WebSocket connection failed'));
        };

        this.ws.onclose = (event) => {
          this.log('WebSocket closed:', event.code, event.reason);
          this.stats.connected = false;
          this.stopHeartbeat();
          
          // Notify disconnect handlers
          this.disconnectHandlers.forEach(handler => {
            try {
              handler(event);
            } catch (error) {
              this.log('Error in disconnect handler:', error);
            }
          });
          
          // Auto-reconnect if enabled
          if (this.shouldReconnect && this.options.auto_reconnect && !this.isReconnecting) {
            this.scheduleReconnect();
          }
        };

      } catch (error) {
        this.log('Error creating WebSocket:', error);
        reject(error);
      }
    });
  }

  disconnect(): void {
    this.shouldReconnect = false;
    this.stopHeartbeat();
    
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
    
    this.stats.connected = false;
    this.log('Disconnected from WebSocket server');
  }

  private scheduleReconnect(): void {
    if (this.stats.reconnect_count >= this.options.max_reconnect_attempts) {
      this.log('Maximum reconnection attempts reached');
      return;
    }

    this.isReconnecting = true;
    this.stats.reconnect_count++;
    
    this.log(`Scheduling reconnection attempt ${this.stats.reconnect_count}/${this.options.max_reconnect_attempts}`);
    
    this.reconnectTimer = setTimeout(async () => {
      try {
        await this.connect();
      } catch (error) {
        this.log('Reconnection failed:', error);
        this.scheduleReconnect();
      }
    }, this.options.reconnect_interval);
  }

  private startHeartbeat(): void {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
    }
    
    this.heartbeatTimer = setInterval(() => {
      if (this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.sendMessage({
          type: 'pong',
          timestamp: Date.now()
        });
      }
    }, this.options.heartbeat_interval);
  }

  private stopHeartbeat(): void {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
  }

  // ===== EVENT SUBSCRIPTION =====

  subscribe<T extends EventPayload = EventPayload>(
    eventType: WebSocketEventType | string,
    handler: EventHandler<T>
  ): void {
    const eventTypeStr = typeof eventType === 'string' ? eventType : eventType.toString();
    
    if (!this.subscribers.has(eventTypeStr)) {
      this.subscribers.set(eventTypeStr, []);
    }
    
    this.subscribers.get(eventTypeStr)!.push(handler as EventHandler);
    this.stats.subscriptions.add(eventTypeStr);
    
    // Send subscription message to server
    this.sendMessage({
      type: 'subscribe',
      payload: {
        event_types: [eventTypeStr]
      },
      timestamp: Date.now()
    });
    
    this.log(`Subscribed to ${eventTypeStr}`);
  }

  unsubscribe(eventType: WebSocketEventType | string, handler?: EventHandler): void {
    const eventTypeStr = typeof eventType === 'string' ? eventType : eventType.toString();
    
    if (handler) {
      // Remove specific handler
      const handlers = this.subscribers.get(eventTypeStr);
      if (handlers) {
        const index = handlers.indexOf(handler);
        if (index > -1) {
          handlers.splice(index, 1);
          if (handlers.length === 0) {
            this.subscribers.delete(eventTypeStr);
            this.stats.subscriptions.delete(eventTypeStr);
          }
        }
      }
    } else {
      // Remove all handlers for this event type
      this.subscribers.delete(eventTypeStr);
      this.stats.subscriptions.delete(eventTypeStr);
    }
    
    // Send unsubscription message to server
    this.sendMessage({
      type: 'unsubscribe',
      payload: {
        event_types: [eventTypeStr]
      },
      timestamp: Date.now()
    });
    
    this.log(`Unsubscribed from ${eventTypeStr}`);
  }

  // ===== ROOM MANAGEMENT =====

  joinRoom(room: string): void {
    this.stats.rooms.add(room);
    
    this.sendMessage({
      type: 'join_room',
      payload: {
        rooms: [room]
      },
      timestamp: Date.now()
    });
    
    this.log(`Joined room: ${room}`);
  }

  leaveRoom(room: string): void {
    this.stats.rooms.delete(room);
    
    this.sendMessage({
      type: 'leave_room',
      payload: {
        rooms: [room]
      },
      timestamp: Date.now()
    });
    
    this.log(`Left room: ${room}`);
  }

  // ===== EVENT HANDLERS =====

  onConnect(handler: ConnectionEventHandler): void {
    this.connectionHandlers.push(handler);
  }

  onError(handler: ErrorEventHandler): void {
    this.errorHandlers.push(handler);
  }

  onDisconnect(handler: ConnectionEventHandler): void {
    this.disconnectHandlers.push(handler);
  }

  // ===== MESSAGE HANDLING =====

  private handleMessage(data: string): void {
    try {
      const message: WebSocketMessage = JSON.parse(data);
      this.stats.messages_received++;
      
      this.log('Received message:', message.type);
      
      // Handle system messages
      if (message.type === 'ping') {
        this.sendMessage({
          type: 'pong',
          timestamp: Date.now()
        });
        return;
      }
      
      // Handle event messages
      const handlers = this.subscribers.get(message.type);
      if (handlers) {
        handlers.forEach(handler => {
          try {
            handler(message.payload, message);
          } catch (error) {
            this.log('Error in event handler:', error);
          }
        });
      }
      
    } catch (error) {
      this.log('Error parsing message:', error);
    }
  }

  private sendMessage(message: Partial<WebSocketMessage>): void {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      this.log('Cannot send message: WebSocket not connected');
      return;
    }
    
    try {
      this.ws.send(JSON.stringify(message));
      this.stats.messages_sent++;
      this.log('Sent message:', message.type);
    } catch (error) {
      this.log('Error sending message:', error);
    }
  }

  // ===== STATE RESTORATION =====

  private restoreState(): void {
    // Restore subscriptions
    if (this.stats.subscriptions.size > 0) {
      this.sendMessage({
        type: 'subscribe',
        payload: {
          event_types: Array.from(this.stats.subscriptions)
        },
        timestamp: Date.now()
      });
    }
    
    // Restore rooms
    if (this.stats.rooms.size > 0) {
      this.sendMessage({
        type: 'join_room',
        payload: {
          rooms: Array.from(this.stats.rooms)
        },
        timestamp: Date.now()
      });
    }
  }

  // ===== UTILITY METHODS =====

  getStats(): WebSocketConnectionStats {
    return { ...this.stats };
  }

  isConnected(): boolean {
    return this.ws?.readyState === WebSocket.OPEN;
  }

  private generateClientId(): string {
    return `wfm-client-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  private log(...args: any[]): void {
    if (this.options.debug) {
      console.log('[WebSocketClient]', ...args);
    }
  }
}

// ===== TYPED EVENT HELPERS =====

export class TypedWebSocketClient extends WebSocketClient {
  // Forecast events
  onForecastUpdated(handler: EventHandler<ForecastEventPayload>): void {
    this.subscribe(WebSocketEventType.FORECAST_UPDATED, handler);
  }

  onForecastCalculated(handler: EventHandler<ForecastEventPayload>): void {
    this.subscribe(WebSocketEventType.FORECAST_CALCULATED, handler);
  }

  onForecastError(handler: EventHandler<ForecastEventPayload>): void {
    this.subscribe(WebSocketEventType.FORECAST_ERROR, handler);
  }

  // Schedule events
  onScheduleChanged(handler: EventHandler<ScheduleEventPayload>): void {
    this.subscribe(WebSocketEventType.SCHEDULE_CHANGED, handler);
  }

  onScheduleOptimized(handler: EventHandler<ScheduleEventPayload>): void {
    this.subscribe(WebSocketEventType.SCHEDULE_OPTIMIZED, handler);
  }

  onShiftAssigned(handler: EventHandler<ScheduleEventPayload>): void {
    this.subscribe(WebSocketEventType.SHIFT_ASSIGNED, handler);
  }

  onShiftSwapped(handler: EventHandler<ScheduleEventPayload>): void {
    this.subscribe(WebSocketEventType.SHIFT_SWAPPED, handler);
  }

  // Monitoring events
  onAgentStatusChanged(handler: EventHandler<AgentStatusEventPayload>): void {
    this.subscribe(WebSocketEventType.AGENT_STATUS_CHANGED, handler);
  }

  onQueueMetricsUpdate(handler: EventHandler<QueueMetricsEventPayload>): void {
    this.subscribe(WebSocketEventType.QUEUE_METRICS_UPDATE, handler);
  }

  onSLAAlert(handler: EventHandler<SLAAlertEventPayload>): void {
    this.subscribe(WebSocketEventType.SLA_ALERT, handler);
  }

  // Skill events
  onSkillAssigned(handler: EventHandler<SkillEventPayload>): void {
    this.subscribe(WebSocketEventType.SKILL_ASSIGNED, handler);
  }

  onSkillRemoved(handler: EventHandler<SkillEventPayload>): void {
    this.subscribe(WebSocketEventType.SKILL_REMOVED, handler);
  }

  onSkillLevelChanged(handler: EventHandler<SkillEventPayload>): void {
    this.subscribe(WebSocketEventType.SKILL_LEVEL_CHANGED, handler);
  }

  // Vacancy events
  onVacancyCreated(handler: EventHandler<VacancyEventPayload>): void {
    this.subscribe(WebSocketEventType.VACANCY_CREATED, handler);
  }

  onVacancyFilled(handler: EventHandler<VacancyEventPayload>): void {
    this.subscribe(WebSocketEventType.VACANCY_FILLED, handler);
  }

  onStaffingGapDetected(handler: EventHandler<StaffingGapEventPayload>): void {
    this.subscribe(WebSocketEventType.STAFFING_GAP_DETECTED, handler);
  }

  // Algorithm events
  onErlangCalculationComplete(handler: EventHandler<AlgorithmEventPayload>): void {
    this.subscribe(WebSocketEventType.ERLANG_CALCULATION_COMPLETE, handler);
  }

  onOptimizationComplete(handler: EventHandler<AlgorithmEventPayload>): void {
    this.subscribe(WebSocketEventType.OPTIMIZATION_COMPLETE, handler);
  }

  onAccuracyMetricsReady(handler: EventHandler<AlgorithmEventPayload>): void {
    this.subscribe(WebSocketEventType.ACCURACY_METRICS_READY, handler);
  }
}

// ===== SINGLETON INSTANCE =====

export const wfmWebSocket = new TypedWebSocketClient();

// ===== EXPORT LEGACY COMPATIBILITY =====

// For backward compatibility with existing code using the stub
export const WS_EVENTS = WebSocketEventType;
export const wsStub = wfmWebSocket; // Alias for existing code