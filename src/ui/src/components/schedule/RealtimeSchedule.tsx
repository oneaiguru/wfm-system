import React, { useState, useEffect, useRef } from 'react';
import { RefreshCw, Wifi, WifiOff, Clock, Users, Activity } from 'lucide-react';
import realScheduleService, { Shift, Employee } from '../../services/realScheduleService';

interface RealtimeScheduleProps {
  departmentId?: number;
  refreshInterval?: number; // in seconds, default 30
  enableWebSocket?: boolean; // for future WebSocket implementation
}

interface ScheduleUpdate {
  id: string;
  timestamp: string;
  type: 'shift_created' | 'shift_updated' | 'shift_deleted' | 'employee_updated';
  employeeId: number;
  employeeName: string;
  details: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001';

export const RealtimeSchedule: React.FC<RealtimeScheduleProps> = ({
  departmentId,
  refreshInterval = 30,
  enableWebSocket = false
}) => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [shifts, setShifts] = useState<Shift[]>([]);
  const [updates, setUpdates] = useState<ScheduleUpdate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const [isConnected, setIsConnected] = useState(false);
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());
  const [autoRefresh, setAutoRefresh] = useState(true);
  
  const intervalRef = useRef<NodeJS.Timeout | null>(null);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    loadScheduleData();
    
    if (enableWebSocket) {
      connectWebSocket();
    } else {
      startPolling();
    }

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, [departmentId, refreshInterval, enableWebSocket]);

  const connectWebSocket = () => {
    try {
      // WebSocket implementation for future use
      const ws = new WebSocket(`ws://localhost:8001/ws/schedules/realtime`);
      
      ws.onopen = () => {
        console.log('WebSocket connected');
        setIsConnected(true);
      };

      ws.onmessage = (event) => {
        const update = JSON.parse(event.data);
        handleRealtimeUpdate(update);
      };

      ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        setIsConnected(false);
        // Fallback to polling
        startPolling();
      };

      ws.onclose = () => {
        console.log('WebSocket disconnected');
        setIsConnected(false);
        // Attempt to reconnect after 5 seconds
        setTimeout(connectWebSocket, 5000);
      };

      wsRef.current = ws;
    } catch (err) {
      console.error('WebSocket connection failed:', err);
      // Fallback to polling
      startPolling();
    }
  };

  const startPolling = () => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }

    if (autoRefresh) {
      intervalRef.current = setInterval(() => {
        fetchRealtimeUpdates();
      }, refreshInterval * 1000);
    }
  };

  const loadScheduleData = async () => {
    setLoading(true);
    setError('');

    try {
      // Get today's date range
      const today = new Date();
      const startDate = today.toISOString().split('T')[0];
      const endDate = new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

      const [employeesResult, shiftsResult] = await Promise.all([
        realScheduleService.getEmployees(false),
        realScheduleService.getShifts(startDate, endDate)
      ]);

      if (employeesResult.success && employeesResult.employees) {
        setEmployees(employeesResult.employees);
      }

      if (shiftsResult.success && shiftsResult.shifts) {
        setShifts(shiftsResult.shifts);
      }

      setLastUpdate(new Date());
    } catch (err) {
      console.error('Failed to load schedule:', err);
      setError('Failed to load schedule data');
    } finally {
      setLoading(false);
    }
  };

  const fetchRealtimeUpdates = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/schedules/realtime/updates`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('wfm_auth_token')}`
        }
      });

      if (!response.ok) {
        throw new Error('Failed to fetch updates');
      }

      const data = await response.json();
      
      if (data.updates && data.updates.length > 0) {
        // Process updates
        data.updates.forEach((update: any) => {
          handleRealtimeUpdate(update);
        });
      }

      setLastUpdate(new Date());
      setIsConnected(true);
    } catch (err) {
      console.error('Failed to fetch realtime updates:', err);
      setIsConnected(false);
    }
  };

  const handleRealtimeUpdate = (update: any) => {
    // Create update notification
    const scheduleUpdate: ScheduleUpdate = {
      id: `update-${Date.now()}-${Math.random()}`,
      timestamp: new Date().toISOString(),
      type: update.type,
      employeeId: update.employee_id,
      employeeName: update.employee_name || `Employee ${update.employee_id}`,
      details: update.details || 'Schedule updated'
    };

    setUpdates(prev => [scheduleUpdate, ...prev].slice(0, 10)); // Keep last 10 updates

    // Update local data based on update type
    switch (update.type) {
      case 'shift_created':
        if (update.shift) {
          setShifts(prev => [...prev, update.shift]);
        }
        break;
      
      case 'shift_updated':
        if (update.shift) {
          setShifts(prev => prev.map(s => 
            s.id === update.shift.id ? update.shift : s
          ));
        }
        break;
      
      case 'shift_deleted':
        if (update.shift_id) {
          setShifts(prev => prev.filter(s => s.id !== update.shift_id));
        }
        break;
    }
  };

  const getCurrentShifts = () => {
    const now = new Date();
    const currentTime = now.getHours() * 60 + now.getMinutes();
    
    return shifts.filter(shift => {
      const shiftDate = new Date(shift.date);
      if (shiftDate.toDateString() !== now.toDateString()) return false;
      
      const [startHour, startMin] = shift.startTime.split('T')[1].split(':').map(Number);
      const [endHour, endMin] = shift.endTime.split('T')[1].split(':').map(Number);
      
      const shiftStart = startHour * 60 + startMin;
      const shiftEnd = endHour * 60 + endMin;
      
      return currentTime >= shiftStart && currentTime <= shiftEnd;
    });
  };

  const getUpcomingShifts = () => {
    const now = new Date();
    const in2Hours = new Date(now.getTime() + 2 * 60 * 60 * 1000);
    
    return shifts.filter(shift => {
      const shiftStart = new Date(shift.startTime);
      return shiftStart > now && shiftStart <= in2Hours;
    }).sort((a, b) => new Date(a.startTime).getTime() - new Date(b.startTime).getTime());
  };

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString('en-US', { 
      hour: '2-digit', 
      minute: '2-digit',
      hour12: false 
    });
  };

  const formatRelativeTime = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diff = Math.floor((date.getTime() - now.getTime()) / 1000 / 60); // minutes
    
    if (diff < 0) return 'Started';
    if (diff === 0) return 'Now';
    if (diff < 60) return `${diff}m`;
    return `${Math.floor(diff / 60)}h ${diff % 60}m`;
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-3"></div>
          <p className="text-gray-600">Loading realtime schedule...</p>
        </div>
      </div>
    );
  }

  const currentShifts = getCurrentShifts();
  const upcomingShifts = getUpcomingShifts();

  return (
    <div className="space-y-6" data-testid="realtime-schedule">
      {/* Header */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-xl font-semibold text-gray-900">Realtime Schedule Monitor</h2>
            <p className="text-sm text-gray-600 mt-1">
              Live updates every {refreshInterval} seconds
            </p>
          </div>
          
          <div className="flex items-center gap-4">
            {/* Connection Status */}
            <div className="flex items-center gap-2">
              {isConnected ? (
                <>
                  <Wifi className="h-4 w-4 text-green-600" />
                  <span className="text-sm text-green-600">Connected</span>
                </>
              ) : (
                <>
                  <WifiOff className="h-4 w-4 text-red-600" />
                  <span className="text-sm text-red-600">Disconnected</span>
                </>
              )}
            </div>

            {/* Auto Refresh Toggle */}
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={autoRefresh}
                onChange={(e) => {
                  setAutoRefresh(e.target.checked);
                  if (e.target.checked) {
                    startPolling();
                  } else if (intervalRef.current) {
                    clearInterval(intervalRef.current);
                  }
                }}
                className="h-4 w-4 text-blue-600 rounded border-gray-300"
              />
              <span className="text-sm text-gray-700">Auto-refresh</span>
            </label>

            {/* Manual Refresh */}
            <button
              onClick={() => {
                loadScheduleData();
                fetchRealtimeUpdates();
              }}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              title="Refresh now"
            >
              <RefreshCw className="h-4 w-4 text-gray-600" />
            </button>
          </div>
        </div>

        {/* Last Update Time */}
        <div className="text-xs text-gray-500">
          Last updated: {lastUpdate.toLocaleTimeString()}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Currently Working */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-2 mb-4">
            <Activity className="h-5 w-5 text-green-600" />
            <h3 className="font-semibold text-gray-900">Currently Working</h3>
            <span className="ml-auto text-sm font-medium text-green-600">
              {currentShifts.length}
            </span>
          </div>
          
          <div className="space-y-3">
            {currentShifts.length === 0 ? (
              <p className="text-sm text-gray-500 text-center py-4">
                No employees currently on shift
              </p>
            ) : (
              currentShifts.map(shift => {
                const employee = employees.find(e => e.id === shift.employeeId);
                return (
                  <div key={shift.id} className="p-3 bg-green-50 rounded-lg border border-green-200">
                    <div className="font-medium text-sm text-gray-900">
                      {employee?.fullName || `Employee ${shift.employeeId}`}
                    </div>
                    <div className="text-xs text-gray-600 mt-1">
                      {formatTime(shift.startTime)} - {formatTime(shift.endTime)}
                    </div>
                    <div className="text-xs text-green-600 mt-1">
                      {shift.shiftType}
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* Starting Soon */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-2 mb-4">
            <Clock className="h-5 w-5 text-blue-600" />
            <h3 className="font-semibold text-gray-900">Starting Soon</h3>
            <span className="ml-auto text-sm font-medium text-blue-600">
              {upcomingShifts.length}
            </span>
          </div>
          
          <div className="space-y-3">
            {upcomingShifts.length === 0 ? (
              <p className="text-sm text-gray-500 text-center py-4">
                No upcoming shifts in the next 2 hours
              </p>
            ) : (
              upcomingShifts.map(shift => {
                const employee = employees.find(e => e.id === shift.employeeId);
                return (
                  <div key={shift.id} className="p-3 bg-blue-50 rounded-lg border border-blue-200">
                    <div className="font-medium text-sm text-gray-900">
                      {employee?.fullName || `Employee ${shift.employeeId}`}
                    </div>
                    <div className="text-xs text-gray-600 mt-1">
                      Starts at {formatTime(shift.startTime)}
                    </div>
                    <div className="text-xs text-blue-600 mt-1 font-medium">
                      In {formatRelativeTime(shift.startTime)}
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* Recent Updates */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-2 mb-4">
            <Activity className="h-5 w-5 text-purple-600" />
            <h3 className="font-semibold text-gray-900">Recent Updates</h3>
            <span className="ml-auto text-sm font-medium text-purple-600">
              {updates.length}
            </span>
          </div>
          
          <div className="space-y-3 max-h-96 overflow-y-auto">
            {updates.length === 0 ? (
              <p className="text-sm text-gray-500 text-center py-4">
                No recent updates
              </p>
            ) : (
              updates.map(update => (
                <div key={update.id} className="p-3 bg-gray-50 rounded-lg border border-gray-200">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="text-sm font-medium text-gray-900">
                        {update.employeeName}
                      </div>
                      <div className="text-xs text-gray-600 mt-1">
                        {update.details}
                      </div>
                    </div>
                    <div className="text-xs text-gray-500">
                      {new Date(update.timestamp).toLocaleTimeString('en-US', {
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </div>
                  </div>
                  <div className="mt-2">
                    <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium
                      ${update.type === 'shift_created' ? 'bg-green-100 text-green-800' :
                        update.type === 'shift_updated' ? 'bg-blue-100 text-blue-800' :
                        update.type === 'shift_deleted' ? 'bg-red-100 text-red-800' :
                        'bg-gray-100 text-gray-800'}`}>
                      {update.type.replace('_', ' ')}
                    </span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Summary Stats */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <Users className="h-4 w-4 text-gray-400" />
              <span className="text-sm text-gray-600">Total Employees</span>
            </div>
            <p className="text-2xl font-bold text-gray-900">{employees.length}</p>
          </div>
          
          <div>
            <div className="flex items-center gap-2 mb-2">
              <Activity className="h-4 w-4 text-gray-400" />
              <span className="text-sm text-gray-600">Active Now</span>
            </div>
            <p className="text-2xl font-bold text-green-600">{currentShifts.length}</p>
          </div>
          
          <div>
            <div className="flex items-center gap-2 mb-2">
              <Clock className="h-4 w-4 text-gray-400" />
              <span className="text-sm text-gray-600">Next 2 Hours</span>
            </div>
            <p className="text-2xl font-bold text-blue-600">{upcomingShifts.length}</p>
          </div>
          
          <div>
            <div className="flex items-center gap-2 mb-2">
              <Calendar className="h-4 w-4 text-gray-400" />
              <span className="text-sm text-gray-600">Today's Shifts</span>
            </div>
            <p className="text-2xl font-bold text-purple-600">
              {shifts.filter(s => new Date(s.date).toDateString() === new Date().toDateString()).length}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RealtimeSchedule;