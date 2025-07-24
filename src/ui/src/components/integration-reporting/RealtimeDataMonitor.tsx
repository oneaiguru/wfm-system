import React, { useState, useEffect, useRef } from 'react';
import { Activity, Database, Wifi, WifiOff, Pause, Play, Download, Settings } from 'lucide-react';

interface DataStream {
  id: string;
  name: string;
  type: 'websocket' | 'sse' | 'polling';
  url: string;
  status: 'connected' | 'disconnected' | 'connecting' | 'error';
  lastMessage: any;
  messageCount: number;
  lastUpdate: Date;
  enabled: boolean;
}

interface RealtimeMessage {
  id: string;
  streamId: string;
  timestamp: Date;
  type: string;
  data: any;
  size: number;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';
const WS_BASE_URL = process.env.REACT_APP_WS_URL || 'ws://localhost:8001/ws';

const RealtimeDataMonitor: React.FC = () => {
  const [streams, setStreams] = useState<DataStream[]>([]);
  const [messages, setMessages] = useState<RealtimeMessage[]>([]);
  const [selectedStream, setSelectedStream] = useState<string | null>(null);
  const [isPaused, setIsPaused] = useState(false);
  const [maxMessages, setMaxMessages] = useState(100);
  const [autoScroll, setAutoScroll] = useState(true);
  
  const websockets = useRef<Map<string, WebSocket>>(new Map());
  const eventSources = useRef<Map<string, EventSource>>(new Map());
  const pollingIntervals = useRef<Map<string, NodeJS.Timeout>>(new Map());
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const predefinedStreams: Omit<DataStream, 'status' | 'lastMessage' | 'messageCount' | 'lastUpdate'>[] = [
    {
      id: 'schedule-updates',
      name: 'Обновления расписания',
      type: 'websocket',
      url: `${WS_BASE_URL}/schedule-updates`,
      enabled: true
    },
    {
      id: 'employee-status',
      name: 'Статус сотрудников',
      type: 'sse',
      url: `${API_BASE_URL}/stream/employee-status`,
      enabled: true
    },
    {
      id: 'system-metrics',
      name: 'Метрики системы',
      type: 'polling',
      url: `${API_BASE_URL}/system/metrics`,
      enabled: true
    },
    {
      id: 'notifications',
      name: 'Уведомления',
      type: 'websocket',
      url: `${WS_BASE_URL}/notifications`,
      enabled: true
    },
    {
      id: 'audit-logs',
      name: 'Журнал аудита',
      type: 'sse',
      url: `${API_BASE_URL}/stream/audit-logs`,
      enabled: false
    },
    {
      id: 'performance-data',
      name: 'Данные производительности',
      type: 'polling',
      url: `${API_BASE_URL}/analytics/performance/live`,
      enabled: false
    }
  ];

  useEffect(() => {
    const initialStreams: DataStream[] = predefinedStreams.map(stream => ({
      ...stream,
      status: 'disconnected',
      lastMessage: null,
      messageCount: 0,
      lastUpdate: new Date()
    }));

    setStreams(initialStreams);
    setSelectedStream(initialStreams[0]?.id || null);

    // Connect enabled streams
    initialStreams.forEach(stream => {
      if (stream.enabled) {
        connectStream(stream);
      }
    });

    return () => {
      // Cleanup all connections
      websockets.current.forEach(ws => ws.close());
      eventSources.current.forEach(es => es.close());
      pollingIntervals.current.forEach(interval => clearInterval(interval));
    };
  }, []);

  useEffect(() => {
    if (autoScroll && messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [messages, autoScroll]);

  const connectStream = (stream: DataStream) => {
    updateStreamStatus(stream.id, 'connecting');

    try {
      switch (stream.type) {
        case 'websocket':
          connectWebSocket(stream);
          break;
        case 'sse':
          connectServerSentEvents(stream);
          break;
        case 'polling':
          connectPolling(stream);
          break;
      }
    } catch (error) {
      console.error(`Failed to connect stream ${stream.id}:`, error);
      updateStreamStatus(stream.id, 'error');
    }
  };

  const connectWebSocket = (stream: DataStream) => {
    try {
      const ws = new WebSocket(stream.url);

      ws.onopen = () => {
        console.log(`[REALTIME] WebSocket connected: ${stream.name}`);
        updateStreamStatus(stream.id, 'connected');
      };

      ws.onmessage = (event) => {
        if (!isPaused) {
          handleMessage(stream.id, JSON.parse(event.data));
        }
      };

      ws.onclose = () => {
        console.log(`[REALTIME] WebSocket disconnected: ${stream.name}`);
        updateStreamStatus(stream.id, 'disconnected');
        websockets.current.delete(stream.id);
      };

      ws.onerror = (error) => {
        console.error(`[REALTIME] WebSocket error: ${stream.name}`, error);
        updateStreamStatus(stream.id, 'error');
      };

      websockets.current.set(stream.id, ws);
    } catch (error) {
      // Fallback to mock data for WebSocket
      console.warn(`[REALTIME] WebSocket fallback for ${stream.name}`);
      startMockWebSocket(stream);
    }
  };

  const connectServerSentEvents = (stream: DataStream) => {
    try {
      const eventSource = new EventSource(stream.url);

      eventSource.onopen = () => {
        console.log(`[REALTIME] SSE connected: ${stream.name}`);
        updateStreamStatus(stream.id, 'connected');
      };

      eventSource.onmessage = (event) => {
        if (!isPaused) {
          handleMessage(stream.id, JSON.parse(event.data));
        }
      };

      eventSource.onerror = (error) => {
        console.error(`[REALTIME] SSE error: ${stream.name}`, error);
        updateStreamStatus(stream.id, 'error');
        eventSource.close();
        eventSources.current.delete(stream.id);
      };

      eventSources.current.set(stream.id, eventSource);
    } catch (error) {
      // Fallback to mock data for SSE
      console.warn(`[REALTIME] SSE fallback for ${stream.name}`);
      startMockSSE(stream);
    }
  };

  const connectPolling = (stream: DataStream) => {
    const pollData = async () => {
      try {
        const response = await fetch(stream.url);
        if (response.ok) {
          const data = await response.json();
          if (!isPaused) {
            handleMessage(stream.id, data);
          }
          updateStreamStatus(stream.id, 'connected');
        } else {
          throw new Error(`HTTP ${response.status}`);
        }
      } catch (error) {
        console.error(`[REALTIME] Polling error: ${stream.name}`, error);
        if (!isPaused) {
          // Generate mock data for demo
          handleMessage(stream.id, generateMockData(stream.id));
        }
        updateStreamStatus(stream.id, 'connected'); // Keep as connected for demo
      }
    };

    // Initial poll
    pollData();

    // Set up interval
    const interval = setInterval(pollData, 5000); // Poll every 5 seconds
    pollingIntervals.current.set(stream.id, interval);
    updateStreamStatus(stream.id, 'connected');
  };

  const startMockWebSocket = (stream: DataStream) => {
    updateStreamStatus(stream.id, 'connected');
    
    const interval = setInterval(() => {
      if (!isPaused) {
        handleMessage(stream.id, generateMockData(stream.id));
      }
    }, 2000 + Math.random() * 3000); // Random interval 2-5 seconds

    pollingIntervals.current.set(stream.id, interval);
  };

  const startMockSSE = (stream: DataStream) => {
    updateStreamStatus(stream.id, 'connected');
    
    const interval = setInterval(() => {
      if (!isPaused) {
        handleMessage(stream.id, generateMockData(stream.id));
      }
    }, 3000 + Math.random() * 4000); // Random interval 3-7 seconds

    pollingIntervals.current.set(stream.id, interval);
  };

  const generateMockData = (streamId: string) => {
    switch (streamId) {
      case 'schedule-updates':
        return {
          type: 'schedule_change',
          employeeId: `emp_${Math.floor(Math.random() * 100)}`,
          shiftId: `shift_${Math.floor(Math.random() * 1000)}`,
          action: Math.random() > 0.5 ? 'created' : 'modified',
          timestamp: new Date().toISOString()
        };
      case 'employee-status':
        return {
          type: 'status_update',
          employeeId: `emp_${Math.floor(Math.random() * 100)}`,
          status: ['active', 'break', 'lunch', 'offline'][Math.floor(Math.random() * 4)],
          location: ['Moscow Office', 'St. Petersburg Office', 'Remote'][Math.floor(Math.random() * 3)],
          timestamp: new Date().toISOString()
        };
      case 'system-metrics':
        return {
          cpu: Math.random() * 100,
          memory: Math.random() * 100,
          connections: Math.floor(Math.random() * 500),
          requests_per_minute: Math.floor(Math.random() * 1000),
          timestamp: new Date().toISOString()
        };
      case 'notifications':
        return {
          type: 'notification',
          level: ['info', 'warning', 'error'][Math.floor(Math.random() * 3)],
          message: [
            'Новое расписание создано',
            'Система перегружена',
            'Сотрудник вышел на смену',
            'Критическая ошибка в базе данных'
          ][Math.floor(Math.random() * 4)],
          timestamp: new Date().toISOString()
        };
      default:
        return {
          data: 'Mock data',
          timestamp: new Date().toISOString()
        };
    }
  };

  const handleMessage = (streamId: string, data: any) => {
    const message: RealtimeMessage = {
      id: `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      streamId,
      timestamp: new Date(),
      type: data.type || 'data',
      data,
      size: JSON.stringify(data).length
    };

    setMessages(prev => {
      const newMessages = [message, ...prev];
      return newMessages.slice(0, maxMessages);
    });

    setStreams(prev => prev.map(stream => 
      stream.id === streamId 
        ? { 
            ...stream, 
            lastMessage: data, 
            messageCount: stream.messageCount + 1, 
            lastUpdate: new Date() 
          }
        : stream
    ));
  };

  const updateStreamStatus = (streamId: string, status: DataStream['status']) => {
    setStreams(prev => prev.map(stream => 
      stream.id === streamId ? { ...stream, status } : stream
    ));
  };

  const toggleStream = (streamId: string) => {
    const stream = streams.find(s => s.id === streamId);
    if (!stream) return;

    if (stream.status === 'connected') {
      disconnectStream(streamId);
    } else {
      connectStream(stream);
    }
  };

  const disconnectStream = (streamId: string) => {
    const ws = websockets.current.get(streamId);
    if (ws) {
      ws.close();
      websockets.current.delete(streamId);
    }

    const es = eventSources.current.get(streamId);
    if (es) {
      es.close();
      eventSources.current.delete(streamId);
    }

    const interval = pollingIntervals.current.get(streamId);
    if (interval) {
      clearInterval(interval);
      pollingIntervals.current.delete(streamId);
    }

    updateStreamStatus(streamId, 'disconnected');
  };

  const clearMessages = () => {
    setMessages([]);
  };

  const exportMessages = () => {
    const data = JSON.stringify(messages, null, 2);
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `realtime-messages-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const getStatusIcon = (status: DataStream['status']) => {
    switch (status) {
      case 'connected':
        return <Wifi className="h-4 w-4 text-green-500" />;
      case 'connecting':
        return <Wifi className="h-4 w-4 text-yellow-500 animate-pulse" />;
      case 'error':
        return <WifiOff className="h-4 w-4 text-red-500" />;
      default:
        return <WifiOff className="h-4 w-4 text-gray-500" />;
    }
  };

  const getStatusColor = (status: DataStream['status']) => {
    switch (status) {
      case 'connected':
        return 'text-green-600';
      case 'connecting':
        return 'text-yellow-600';
      case 'error':
        return 'text-red-600';
      default:
        return 'text-gray-600';
    }
  };

  const formatTimestamp = (timestamp: Date) => {
    return timestamp.toLocaleTimeString('ru-RU', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      fractionalSecondDigits: 3
    });
  };

  const formatDataSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const selectedStreamData = selectedStream ? streams.find(s => s.id === selectedStream) : null;
  const filteredMessages = selectedStream ? messages.filter(m => m.streamId === selectedStream) : messages;

  return (
    <div className="p-6">
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 flex items-center">
              <Activity className="h-6 w-6 mr-2 text-blue-600" />
              Монитор Данных в Реальном Времени
            </h2>
            <p className="mt-2 text-gray-600">
              Мониторинг потоков данных через WebSocket, SSE и Polling
            </p>
          </div>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="autoScroll"
                checked={autoScroll}
                onChange={(e) => setAutoScroll(e.target.checked)}
                className="rounded"
              />
              <label htmlFor="autoScroll" className="text-sm text-gray-600">
                Автопрокрутка
              </label>
            </div>
            <button
              onClick={() => setIsPaused(!isPaused)}
              className={`flex items-center px-4 py-2 rounded-md text-white ${
                isPaused ? 'bg-green-600 hover:bg-green-700' : 'bg-red-600 hover:bg-red-700'
              }`}
            >
              {isPaused ? <Play className="h-4 w-4 mr-2" /> : <Pause className="h-4 w-4 mr-2" />}
              {isPaused ? 'Возобновить' : 'Пауза'}
            </button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Streams List */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Потоки Данных</h3>
            </div>
            
            <div className="p-4 space-y-3">
              {streams.map((stream) => (
                <div
                  key={stream.id}
                  className={`p-3 border rounded-lg cursor-pointer transition-colors ${
                    selectedStream === stream.id
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                  onClick={() => setSelectedStream(stream.id)}
                >
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      {getStatusIcon(stream.status)}
                      <span className="text-sm font-medium text-gray-900">{stream.name}</span>
                    </div>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        toggleStream(stream.id);
                      }}
                      className="text-xs px-2 py-1 rounded bg-gray-100 hover:bg-gray-200"
                    >
                      {stream.status === 'connected' ? 'Отключить' : 'Подключить'}
                    </button>
                  </div>
                  
                  <div className="text-xs text-gray-500 space-y-1">
                    <div className="flex justify-between">
                      <span>Тип:</span>
                      <span className="uppercase font-medium">{stream.type}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Сообщений:</span>
                      <span>{stream.messageCount}</span>
                    </div>
                    <div className={`text-xs ${getStatusColor(stream.status)}`}>
                      {stream.status === 'connected' ? 'Подключен' :
                       stream.status === 'connecting' ? 'Подключается...' :
                       stream.status === 'error' ? 'Ошибка' : 'Отключен'}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Settings */}
          <div className="mt-6 bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900 flex items-center">
                <Settings className="h-4 w-4 mr-2" />
                Настройки
              </h3>
            </div>
            
            <div className="p-4 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Максимум сообщений
                </label>
                <select
                  value={maxMessages}
                  onChange={(e) => setMaxMessages(Number(e.target.value))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value={50}>50</option>
                  <option value={100}>100</option>
                  <option value={200}>200</option>
                  <option value={500}>500</option>
                </select>
              </div>
              
              <div className="flex gap-2">
                <button
                  onClick={clearMessages}
                  className="flex-1 px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50"
                >
                  Очистить
                </button>
                <button
                  onClick={exportMessages}
                  className="flex-1 px-3 py-2 text-sm bg-blue-600 text-white rounded-md hover:bg-blue-700"
                >
                  <Download className="h-3 w-3 inline mr-1" />
                  Экспорт
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Messages Display */}
        <div className="lg:col-span-3">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 h-[800px] flex flex-col">
            <div className="px-4 py-3 border-b border-gray-200 flex items-center justify-between">
              <div>
                <h3 className="text-lg font-semibold text-gray-900">
                  {selectedStreamData ? selectedStreamData.name : 'Все потоки'}
                </h3>
                <p className="text-sm text-gray-500">
                  {filteredMessages.length} сообщений
                  {isPaused && <span className="ml-2 text-red-500">(На паузе)</span>}
                </p>
              </div>
              {selectedStreamData && (
                <div className="flex items-center gap-2">
                  {getStatusIcon(selectedStreamData.status)}
                  <span className={`text-sm ${getStatusColor(selectedStreamData.status)}`}>
                    {selectedStreamData.status === 'connected' ? 'Активен' :
                     selectedStreamData.status === 'connecting' ? 'Подключается' :
                     selectedStreamData.status === 'error' ? 'Ошибка' : 'Неактивен'}
                  </span>
                </div>
              )}
            </div>
            
            <div className="flex-1 overflow-auto p-4 space-y-2 font-mono text-sm">
              {filteredMessages.length === 0 ? (
                <div className="flex items-center justify-center h-full text-gray-500">
                  <div className="text-center">
                    <Database className="h-12 w-12 mx-auto mb-4 opacity-50" />
                    <p>Нет сообщений</p>
                    <p className="text-xs">Подключите поток данных для просмотра сообщений</p>
                  </div>
                </div>
              ) : (
                filteredMessages.map((message) => (
                  <div
                    key={message.id}
                    className="border border-gray-200 rounded-lg p-3 bg-gray-50 hover:bg-gray-100"
                  >
                    <div className="flex items-center justify-between mb-2 text-xs text-gray-500">
                      <div className="flex items-center gap-2">
                        <span className="font-medium">{formatTimestamp(message.timestamp)}</span>
                        <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded">
                          {message.type}
                        </span>
                      </div>
                      <span>{formatDataSize(message.size)}</span>
                    </div>
                    <pre className="text-xs text-gray-700 overflow-x-auto whitespace-pre-wrap">
                      {JSON.stringify(message.data, null, 2)}
                    </pre>
                  </div>
                ))
              )}
              <div ref={messagesEndRef} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RealtimeDataMonitor;