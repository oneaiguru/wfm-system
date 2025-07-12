import React, { useState, useEffect } from 'react';
import { 
  Clock, 
  AlertCircle, 
  CheckCircle, 
  Info, 
  AlertTriangle,
  Filter,
  Download,
  RefreshCw,
  Search,
  Calendar,
  Database,
  Globe,
  Server
} from 'lucide-react';
import { IntegrationLog } from '../../types/integration';

const IntegrationLogs: React.FC = () => {
  const [logs, setLogs] = useState<IntegrationLog[]>([]);
  const [filter, setFilter] = useState<'all' | 'info' | 'warning' | 'error' | 'success'>('all');
  const [systemFilter, setSystemFilter] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [timeRange, setTimeRange] = useState<'1h' | '24h' | '7d' | '30d'>('24h');
  const [isLive, setIsLive] = useState(true);

  useEffect(() => {
    const generateMockLogs = (): IntegrationLog[] => {
      const systems = ['1C ZUP', 'Oktell API', 'LDAP', 'File Transfer', 'Message Queue'];
      const operations = ['sync', 'test', 'connect', 'disconnect', 'map', 'transform', 'validate'];
      const levels: ('info' | 'warning' | 'error' | 'success')[] = ['info', 'warning', 'error', 'success'];
      
      const mockLogs: IntegrationLog[] = [];
      
      for (let i = 0; i < 150; i++) {
        const level = levels[Math.floor(Math.random() * levels.length)];
        const system = systems[Math.floor(Math.random() * systems.length)];
        const operation = operations[Math.floor(Math.random() * operations.length)];
        
        let message = '';
        let details = '';
        
        switch (level) {
          case 'success':
            message = `${operation} operation completed successfully`;
            details = `Processed 127 records in 2.3 seconds`;
            break;
          case 'info':
            message = `${operation} operation started`;
            details = `Connecting to ${system} endpoint`;
            break;
          case 'warning':
            message = `${operation} operation has performance issues`;
            details = `Response time exceeded 5 seconds threshold`;
            break;
          case 'error':
            message = `${operation} operation failed`;
            details = `Connection timeout after 30 seconds`;
            break;
        }
        
        mockLogs.push({
          id: `log_${i.toString().padStart(3, '0')}`,
          timestamp: new Date(Date.now() - Math.random() * 24 * 60 * 60 * 1000),
          level,
          system,
          operation,
          message,
          details,
          duration: Math.floor(Math.random() * 5000) + 100
        });
      }
      
      return mockLogs.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
    };

    setLogs(generateMockLogs());
  }, []);

  // Real-time log updates
  useEffect(() => {
    if (!isLive) return;

    const interval = setInterval(() => {
      const newLog: IntegrationLog = {
        id: `log_${Date.now()}`,
        timestamp: new Date(),
        level: ['info', 'success', 'warning', 'error'][Math.floor(Math.random() * 4)] as any,
        system: ['1C ZUP', 'Oktell API', 'LDAP'][Math.floor(Math.random() * 3)],
        operation: ['sync', 'test', 'connect'][Math.floor(Math.random() * 3)],
        message: 'Real-time sync operation completed',
        details: 'Live data update from system',
        duration: Math.floor(Math.random() * 1000) + 100
      };

      setLogs(prev => [newLog, ...prev.slice(0, 149)]);
    }, 10000);

    return () => clearInterval(interval);
  }, [isLive]);

  const filteredLogs = logs.filter(log => {
    const matchesLevel = filter === 'all' || log.level === filter;
    const matchesSystem = systemFilter === 'all' || log.system === systemFilter;
    const matchesSearch = 
      log.message.toLowerCase().includes(searchTerm.toLowerCase()) ||
      log.system.toLowerCase().includes(searchTerm.toLowerCase()) ||
      log.operation.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (log.details && log.details.toLowerCase().includes(searchTerm.toLowerCase()));
    
    // Time range filter
    const now = new Date();
    const logTime = log.timestamp.getTime();
    let timeLimit = 0;
    
    switch (timeRange) {
      case '1h': timeLimit = 60 * 60 * 1000; break;
      case '24h': timeLimit = 24 * 60 * 60 * 1000; break;
      case '7d': timeLimit = 7 * 24 * 60 * 60 * 1000; break;
      case '30d': timeLimit = 30 * 24 * 60 * 60 * 1000; break;
    }
    
    const withinTimeRange = (now.getTime() - logTime) <= timeLimit;
    
    return matchesLevel && matchesSystem && matchesSearch && withinTimeRange;
  });

  const getLevelColor = (level: string) => {
    switch (level) {
      case 'success': return 'bg-green-100 text-green-800';
      case 'info': return 'bg-blue-100 text-blue-800';
      case 'warning': return 'bg-yellow-100 text-yellow-800';
      case 'error': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getLevelIcon = (level: string) => {
    switch (level) {
      case 'success': return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'info': return <Info className="h-4 w-4 text-blue-500" />;
      case 'warning': return <AlertTriangle className="h-4 w-4 text-yellow-500" />;
      case 'error': return <AlertCircle className="h-4 w-4 text-red-500" />;
      default: return <Clock className="h-4 w-4 text-gray-500" />;
    }
  };

  const getSystemIcon = (system: string) => {
    if (system.includes('1C')) return <Database className="h-4 w-4 text-blue-600" />;
    if (system.includes('Oktell')) return <Globe className="h-4 w-4 text-green-600" />;
    if (system.includes('LDAP')) return <Server className="h-4 w-4 text-purple-600" />;
    return <Server className="h-4 w-4 text-gray-600" />;
  };

  const formatTimestamp = (timestamp: Date) => {
    const now = new Date();
    const diff = now.getTime() - timestamp.getTime();
    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ago`;
    if (hours > 0) return `${hours}h ago`;
    if (minutes > 0) return `${minutes}m ago`;
    return 'Just now';
  };

  const exportLogs = () => {
    const csvContent = [
      'Timestamp,Level,System,Operation,Message,Details,Duration',
      ...filteredLogs.map(log => 
        `"${log.timestamp.toISOString()}","${log.level}","${log.system}","${log.operation}","${log.message}","${log.details || ''}","${log.duration || ''}"`
      )
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `integration-logs-${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    window.URL.revokeObjectURL(url);
  };

  const stats = {
    total: filteredLogs.length,
    success: filteredLogs.filter(l => l.level === 'success').length,
    info: filteredLogs.filter(l => l.level === 'info').length,
    warning: filteredLogs.filter(l => l.level === 'warning').length,
    error: filteredLogs.filter(l => l.level === 'error').length
  };

  const systems = [...new Set(logs.map(log => log.system))];

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Clock className="h-6 w-6 mr-2 text-blue-600" />
          Integration Logs
        </h2>
        <p className="mt-2 text-gray-600">
          Monitor system integration events and troubleshoot issues
        </p>
      </div>

      {/* Live Status Indicator */}
      <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <div className={`w-3 h-3 rounded-full mr-3 ${isLive ? 'bg-green-500 animate-pulse' : 'bg-gray-500'}`} />
            <span className="text-sm font-medium text-gray-900">
              {isLive ? 'Live Monitoring' : 'Static View'}
            </span>
            <button
              onClick={() => setIsLive(!isLive)}
              className="ml-3 px-3 py-1 text-xs bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              {isLive ? 'Pause' : 'Resume'}
            </button>
          </div>
          <div className="flex items-center space-x-2">
            <span className="text-sm text-gray-600">{filteredLogs.length} entries</span>
            <button
              onClick={exportLogs}
              className="flex items-center px-3 py-1 text-sm bg-gray-600 text-white rounded-md hover:bg-gray-700"
            >
              <Download className="h-4 w-4 mr-1" />
              Export
            </button>
          </div>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Clock className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Total</h3>
              <p className="text-2xl font-bold text-blue-600">{stats.total}</p>
              <p className="text-sm text-gray-600">Log Entries</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <CheckCircle className="h-8 w-8 text-green-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Success</h3>
              <p className="text-2xl font-bold text-green-600">{stats.success}</p>
              <p className="text-sm text-gray-600">Operations</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Info className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Info</h3>
              <p className="text-2xl font-bold text-blue-600">{stats.info}</p>
              <p className="text-sm text-gray-600">Messages</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <AlertTriangle className="h-8 w-8 text-yellow-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Warnings</h3>
              <p className="text-2xl font-bold text-yellow-600">{stats.warning}</p>
              <p className="text-sm text-gray-600">Issues</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <AlertCircle className="h-8 w-8 text-red-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Errors</h3>
              <p className="text-2xl font-bold text-red-600">{stats.error}</p>
              <p className="text-sm text-gray-600">Failed</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
        <div className="flex flex-wrap items-center gap-4">
          <div className="flex items-center space-x-2">
            <Search className="h-4 w-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search logs..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-2 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <select
            value={filter}
            onChange={(e) => setFilter(e.target.value as any)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Levels</option>
            <option value="success">Success</option>
            <option value="info">Info</option>
            <option value="warning">Warning</option>
            <option value="error">Error</option>
          </select>

          <select
            value={systemFilter}
            onChange={(e) => setSystemFilter(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Systems</option>
            {systems.map(system => (
              <option key={system} value={system}>{system}</option>
            ))}
          </select>

          <select
            value={timeRange}
            onChange={(e) => setTimeRange(e.target.value as any)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="1h">Last 1 hour</option>
            <option value="24h">Last 24 hours</option>
            <option value="7d">Last 7 days</option>
            <option value="30d">Last 30 days</option>
          </select>

          <button className="p-2 bg-gray-100 hover:bg-gray-200 rounded-md" title="Refresh">
            <RefreshCw className="h-4 w-4" />
          </button>
        </div>
      </div>

      {/* Logs List */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Activity Log</h3>
        </div>

        <div className="max-h-96 overflow-y-auto">
          {filteredLogs.map((log) => (
            <div key={log.id} className="border-b border-gray-100 p-4 hover:bg-gray-50">
              <div className="flex items-start space-x-3">
                <div className="flex-shrink-0 mt-1">
                  {getLevelIcon(log.level)}
                </div>
                
                <div className="flex-1 min-w-0">
                  <div className="flex items-center space-x-3 mb-1">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getLevelColor(log.level)}`}>
                      {log.level.toUpperCase()}
                    </span>
                    <div className="flex items-center space-x-1">
                      {getSystemIcon(log.system)}
                      <span className="text-sm font-medium text-gray-900">{log.system}</span>
                    </div>
                    <span className="text-sm text-gray-500">{log.operation}</span>
                    <span className="text-xs text-gray-400">{formatTimestamp(log.timestamp)}</span>
                  </div>
                  
                  <div className="text-sm text-gray-900 mb-1">{log.message}</div>
                  
                  {log.details && (
                    <div className="text-xs text-gray-600 bg-gray-50 p-2 rounded mt-2">
                      {log.details}
                    </div>
                  )}
                  
                  <div className="flex items-center space-x-4 mt-2 text-xs text-gray-500">
                    <span>{log.timestamp.toLocaleString()}</span>
                    {log.duration && <span>Duration: {log.duration}ms</span>}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {filteredLogs.length === 0 && (
          <div className="text-center py-12">
            <Clock className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No logs found</h3>
            <p className="text-gray-600">Try adjusting your search criteria or time range.</p>
          </div>
        )}
      </div>

      {/* Quick Actions */}
      <div className="mt-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Clear Old Logs</h4>
            <p className="text-sm text-gray-600 mt-1">Remove logs older than 30 days</p>
          </button>
          
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Configure Alerts</h4>
            <p className="text-sm text-gray-600 mt-1">Set up error notifications</p>
          </button>
          
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Log Analysis</h4>
            <p className="text-sm text-gray-600 mt-1">Generate error pattern report</p>
          </button>
        </div>
      </div>
    </div>
  );
};

export default IntegrationLogs;