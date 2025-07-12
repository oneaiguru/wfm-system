import React, { useState, useEffect } from 'react';
import { 
  Link2, 
  Database, 
  Globe, 
  Server, 
  CheckCircle, 
  AlertCircle, 
  Clock, 
  Settings, 
  Plus,
  Edit,
  Trash2,
  TestTube,
  Eye
} from 'lucide-react';
import { SystemConnection } from '../../types/integration';

const SystemConnectors: React.FC = () => {
  const [connections, setConnections] = useState<SystemConnection[]>([]);
  const [filter, setFilter] = useState<'all' | 'active' | 'inactive' | 'error'>('all');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    const mockConnections: SystemConnection[] = [
      {
        id: 'conn_001',
        name: '1C ZUP Integration',
        type: 'database',
        status: 'active',
        url: 'jdbc:postgresql://1c-server:5432/zup_db',
        lastSync: new Date(Date.now() - 15 * 60 * 1000),
        syncCount: 15423,
        errorCount: 12,
        description: 'Employee data synchronization with 1C ZUP payroll system'
      },
      {
        id: 'conn_002',
        name: 'Oktell API Gateway',
        type: 'api',
        status: 'active',
        url: 'https://api.oktell.ru/v2/',
        lastSync: new Date(Date.now() - 5 * 60 * 1000),
        syncCount: 8934,
        errorCount: 3,
        description: 'Real-time telephony data integration with Oktell platform'
      },
      {
        id: 'conn_003',
        name: 'LDAP Directory Service',
        type: 'api',
        status: 'active',
        url: 'ldap://corp-ldap.company.com:389',
        lastSync: new Date(Date.now() - 30 * 60 * 1000),
        syncCount: 2156,
        errorCount: 0,
        description: 'Corporate directory synchronization for user management'
      },
      {
        id: 'conn_004',
        name: 'File Transfer System',
        type: 'file',
        status: 'testing',
        url: 'sftp://fileserver.company.com/wfm-data/',
        lastSync: new Date(Date.now() - 60 * 60 * 1000),
        syncCount: 456,
        errorCount: 1,
        description: 'Automated file-based data exchange for reports and backups'
      },
      {
        id: 'conn_005',
        name: 'Message Queue System',
        type: 'queue',
        status: 'error',
        url: 'amqp://rabbitmq.company.com:5672',
        lastSync: new Date(Date.now() - 120 * 60 * 1000),
        syncCount: 12890,
        errorCount: 45,
        description: 'Asynchronous message processing for real-time events'
      },
      {
        id: 'conn_006',
        name: 'CRM Integration',
        type: 'api',
        status: 'inactive',
        url: 'https://crm-api.company.com/v1/',
        lastSync: new Date(Date.now() - 24 * 60 * 60 * 1000),
        syncCount: 3421,
        errorCount: 8,
        description: 'Customer relationship management system integration'
      }
    ];

    setConnections(mockConnections);
  }, []);

  const filteredConnections = connections.filter(conn => {
    const matchesFilter = filter === 'all' || conn.status === filter;
    const matchesSearch = 
      conn.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      conn.type.toLowerCase().includes(searchTerm.toLowerCase()) ||
      conn.description.toLowerCase().includes(searchTerm.toLowerCase());
    
    return matchesFilter && matchesSearch;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800';
      case 'testing': return 'bg-yellow-100 text-yellow-800';
      case 'error': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active': return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'testing': return <Clock className="h-4 w-4 text-yellow-500" />;
      case 'error': return <AlertCircle className="h-4 w-4 text-red-500" />;
      default: return <Server className="h-4 w-4 text-gray-500" />;
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'database': return <Database className="h-5 w-5 text-blue-600" />;
      case 'api': return <Globe className="h-5 w-5 text-green-600" />;
      case 'file': return <Server className="h-5 w-5 text-purple-600" />;
      case 'queue': return <Link2 className="h-5 w-5 text-orange-600" />;
      default: return <Server className="h-5 w-5 text-gray-600" />;
    }
  };

  const getTimeSinceSync = (lastSync: Date) => {
    const now = new Date();
    const diff = now.getTime() - lastSync.getTime();
    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ago`;
    if (hours > 0) return `${hours}h ago`;
    return `${minutes}m ago`;
  };

  const handleTestConnection = (connectionId: string) => {
    setConnections(prev => prev.map(conn =>
      conn.id === connectionId
        ? { ...conn, status: 'testing' as const }
        : conn
    ));

    // Simulate test result after 2 seconds
    setTimeout(() => {
      setConnections(prev => prev.map(conn =>
        conn.id === connectionId
          ? { ...conn, status: 'active' as const, lastSync: new Date() }
          : conn
      ));
    }, 2000);
  };

  const stats = {
    total: connections.length,
    active: connections.filter(c => c.status === 'active').length,
    testing: connections.filter(c => c.status === 'testing').length,
    error: connections.filter(c => c.status === 'error').length,
    inactive: connections.filter(c => c.status === 'inactive').length
  };

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Link2 className="h-6 w-6 mr-2 text-blue-600" />
          System Connectors
        </h2>
        <p className="mt-2 text-gray-600">
          Manage connections to external systems and data sources
        </p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Server className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Total</h3>
              <p className="text-2xl font-bold text-blue-600">{stats.total}</p>
              <p className="text-sm text-gray-600">Connections</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <CheckCircle className="h-8 w-8 text-green-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Active</h3>
              <p className="text-2xl font-bold text-green-600">{stats.active}</p>
              <p className="text-sm text-gray-600">Running</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Clock className="h-8 w-8 text-yellow-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Testing</h3>
              <p className="text-2xl font-bold text-yellow-600">{stats.testing}</p>
              <p className="text-sm text-gray-600">In Progress</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <AlertCircle className="h-8 w-8 text-red-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Errors</h3>
              <p className="text-2xl font-bold text-red-600">{stats.error}</p>
              <p className="text-sm text-gray-600">Need Attention</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Settings className="h-8 w-8 text-gray-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Inactive</h3>
              <p className="text-2xl font-bold text-gray-600">{stats.inactive}</p>
              <p className="text-sm text-gray-600">Disabled</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters and Search */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="relative">
              <input
                type="text"
                placeholder="Search connections..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-4 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <select
              value={filter}
              onChange={(e) => setFilter(e.target.value as any)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">All Connections</option>
              <option value="active">Active</option>
              <option value="testing">Testing</option>
              <option value="error">Error</option>
              <option value="inactive">Inactive</option>
            </select>

            <span className="text-sm text-gray-600">
              {filteredConnections.length} connections
            </span>
          </div>

          <button className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
            <Plus className="h-4 w-4 mr-2" />
            Add Connection
          </button>
        </div>
      </div>

      {/* Connection List */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">System Connections</h3>
        </div>

        <div className="divide-y divide-gray-200">
          {filteredConnections.map((connection) => (
            <div key={connection.id} className="p-6 hover:bg-gray-50">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-4">
                  <div className="flex-shrink-0">
                    {getTypeIcon(connection.type)}
                  </div>
                  
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center space-x-3 mb-2">
                      <h4 className="text-lg font-medium text-gray-900">
                        {connection.name}
                      </h4>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(connection.status)}`}>
                        {getStatusIcon(connection.status)}
                        <span className="ml-1 capitalize">{connection.status}</span>
                      </span>
                    </div>
                    
                    <p className="text-sm text-gray-600 mb-2">{connection.description}</p>
                    
                    <div className="flex items-center space-x-4 text-sm text-gray-500">
                      <span>Type: {connection.type.toUpperCase()}</span>
                      <span>Last sync: {getTimeSinceSync(connection.lastSync)}</span>
                      <span>Syncs: {connection.syncCount.toLocaleString()}</span>
                      <span>Errors: {connection.errorCount}</span>
                    </div>
                    
                    <div className="mt-2 text-xs text-gray-400 font-mono">
                      {connection.url}
                    </div>
                  </div>
                </div>

                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => handleTestConnection(connection.id)}
                    className="p-2 text-blue-600 hover:text-blue-800 hover:bg-blue-50 rounded-md"
                    title="Test Connection"
                  >
                    <TestTube className="h-4 w-4" />
                  </button>
                  
                  <button className="p-2 text-gray-600 hover:text-gray-800 hover:bg-gray-50 rounded-md" title="View Details">
                    <Eye className="h-4 w-4" />
                  </button>
                  
                  <button className="p-2 text-gray-600 hover:text-gray-800 hover:bg-gray-50 rounded-md" title="Edit">
                    <Edit className="h-4 w-4" />
                  </button>
                  
                  <button className="p-2 text-red-600 hover:text-red-800 hover:bg-red-50 rounded-md" title="Delete">
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

        {filteredConnections.length === 0 && (
          <div className="text-center py-12">
            <Link2 className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No connections found</h3>
            <p className="text-gray-600">Try adjusting your search criteria or add a new connection.</p>
          </div>
        )}
      </div>

      {/* Quick Actions */}
      <div className="mt-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Test All Connections</h4>
            <p className="text-sm text-gray-600 mt-1">Verify all connection statuses</p>
          </button>
          
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Export Configuration</h4>
            <p className="text-sm text-gray-600 mt-1">Download connection settings</p>
          </button>
          
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Import Settings</h4>
            <p className="text-sm text-gray-600 mt-1">Upload connection configurations</p>
          </button>
        </div>
      </div>
    </div>
  );
};

export default SystemConnectors;