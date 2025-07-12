import React, { useState, useEffect } from 'react';
import { 
  ArrowRight, 
  Database, 
  Edit, 
  Save, 
  Plus, 
  Trash2, 
  CheckCircle, 
  AlertCircle,
  Settings,
  RefreshCw,
  Eye
} from 'lucide-react';
import { DataMapping } from '../../types/integration';

const DataMappingTool: React.FC = () => {
  const [mappings, setMappings] = useState<DataMapping[]>([]);
  const [filter, setFilter] = useState<'all' | 'active' | 'inactive' | 'error'>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedMapping, setSelectedMapping] = useState<DataMapping | null>(null);
  const [isEditing, setIsEditing] = useState(false);

  useEffect(() => {
    const mockMappings: DataMapping[] = [
      {
        id: 'map_001',
        sourceSystem: '1C ZUP',
        targetSystem: 'WFM Database',
        sourceField: 'Сотрудник.ТабельныйНомер',
        targetField: 'employee.employee_id',
        transformation: 'toString()',
        status: 'active',
        lastMapped: new Date(Date.now() - 10 * 60 * 1000),
        recordCount: 1247
      },
      {
        id: 'map_002',
        sourceSystem: '1C ZUP',
        targetSystem: 'WFM Database',
        sourceField: 'Сотрудник.ФИО',
        targetField: 'employee.full_name',
        transformation: 'formatName()',
        status: 'active',
        lastMapped: new Date(Date.now() - 10 * 60 * 1000),
        recordCount: 1247
      },
      {
        id: 'map_003',
        sourceSystem: 'Oktell',
        targetSystem: 'WFM Database',
        sourceField: 'agent.login',
        targetField: 'employee.oktell_login',
        status: 'active',
        lastMapped: new Date(Date.now() - 5 * 60 * 1000),
        recordCount: 892
      },
      {
        id: 'map_004',
        sourceSystem: 'Oktell',
        targetSystem: 'WFM Database',
        sourceField: 'queue.statistics.calls_handled',
        targetField: 'performance.calls_handled',
        transformation: 'parseInt()',
        status: 'active',
        lastMapped: new Date(Date.now() - 5 * 60 * 1000),
        recordCount: 15423
      },
      {
        id: 'map_005',
        sourceSystem: 'LDAP',
        targetSystem: 'WFM Database',
        sourceField: 'uid',
        targetField: 'employee.domain_login',
        status: 'active',
        lastMapped: new Date(Date.now() - 30 * 60 * 1000),
        recordCount: 1156
      },
      {
        id: 'map_006',
        sourceSystem: 'File Import',
        targetSystem: 'WFM Database',
        sourceField: 'schedule.shift_start',
        targetField: 'schedule.start_time',
        transformation: 'parseDateTime()',
        status: 'error',
        lastMapped: new Date(Date.now() - 120 * 60 * 1000),
        recordCount: 0
      }
    ];

    setMappings(mockMappings);
  }, []);

  const filteredMappings = mappings.filter(mapping => {
    const matchesFilter = filter === 'all' || mapping.status === filter;
    const matchesSearch = 
      mapping.sourceSystem.toLowerCase().includes(searchTerm.toLowerCase()) ||
      mapping.targetSystem.toLowerCase().includes(searchTerm.toLowerCase()) ||
      mapping.sourceField.toLowerCase().includes(searchTerm.toLowerCase()) ||
      mapping.targetField.toLowerCase().includes(searchTerm.toLowerCase());
    
    return matchesFilter && matchesSearch;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800';
      case 'error': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active': return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'error': return <AlertCircle className="h-4 w-4 text-red-500" />;
      default: return <Settings className="h-4 w-4 text-gray-500" />;
    }
  };

  const getTimeSinceMapping = (lastMapped: Date) => {
    const now = new Date();
    const diff = now.getTime() - lastMapped.getTime();
    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ago`;
    if (hours > 0) return `${hours}h ago`;
    return `${minutes}m ago`;
  };

  const handleTestMapping = (mappingId: string) => {
    setMappings(prev => prev.map(mapping =>
      mapping.id === mappingId
        ? { ...mapping, status: 'active' as const, lastMapped: new Date() }
        : mapping
    ));
  };

  const stats = {
    total: mappings.length,
    active: mappings.filter(m => m.status === 'active').length,
    inactive: mappings.filter(m => m.status === 'inactive').length,
    error: mappings.filter(m => m.status === 'error').length,
    totalRecords: mappings.reduce((sum, m) => sum + m.recordCount, 0)
  };

  const systemPairs = [...new Set(mappings.map(m => `${m.sourceSystem} → ${m.targetSystem}`))];

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Database className="h-6 w-6 mr-2 text-blue-600" />
          Data Mapping Tool
        </h2>
        <p className="mt-2 text-gray-600">
          Configure field mappings between source and target systems
        </p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Database className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Total</h3>
              <p className="text-2xl font-bold text-blue-600">{stats.total}</p>
              <p className="text-sm text-gray-600">Mappings</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <CheckCircle className="h-8 w-8 text-green-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Active</h3>
              <p className="text-2xl font-bold text-green-600">{stats.active}</p>
              <p className="text-sm text-gray-600">Working</p>
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

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <ArrowRight className="h-8 w-8 text-purple-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Systems</h3>
              <p className="text-2xl font-bold text-purple-600">{systemPairs.length}</p>
              <p className="text-sm text-gray-600">Connections</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Settings className="h-8 w-8 text-orange-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Records</h3>
              <p className="text-2xl font-bold text-orange-600">{stats.totalRecords.toLocaleString()}</p>
              <p className="text-sm text-gray-600">Processed</p>
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
                placeholder="Search mappings..."
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
              <option value="all">All Mappings</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="error">Error</option>
            </select>

            <span className="text-sm text-gray-600">
              {filteredMappings.length} mappings
            </span>
          </div>

          <button className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
            <Plus className="h-4 w-4 mr-2" />
            Add Mapping
          </button>
        </div>
      </div>

      {/* Mapping List */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Field Mappings</h3>
        </div>

        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Source System
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Source Field
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Target System
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Target Field
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Transformation
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Last Mapped
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Records
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredMappings.map((mapping) => (
                <tr key={mapping.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <Database className="h-4 w-4 text-blue-600 mr-2" />
                      <span className="text-sm font-medium text-gray-900">{mapping.sourceSystem}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-sm text-gray-900 font-mono">{mapping.sourceField}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <ArrowRight className="h-4 w-4 text-gray-400 mr-2" />
                      <span className="text-sm font-medium text-gray-900">{mapping.targetSystem}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-sm text-gray-900 font-mono">{mapping.targetField}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-600 font-mono">
                      {mapping.transformation || 'None'}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      {getStatusIcon(mapping.status)}
                      <span className={`ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(mapping.status)}`}>
                        {mapping.status.charAt(0).toUpperCase() + mapping.status.slice(1)}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {getTimeSinceMapping(mapping.lastMapped)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {mapping.recordCount.toLocaleString()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm">
                    <div className="flex space-x-2">
                      <button
                        onClick={() => handleTestMapping(mapping.id)}
                        className="text-blue-600 hover:text-blue-900"
                        title="Test Mapping"
                      >
                        <RefreshCw className="h-4 w-4" />
                      </button>
                      <button className="text-gray-600 hover:text-gray-900" title="View Details">
                        <Eye className="h-4 w-4" />
                      </button>
                      <button className="text-gray-600 hover:text-gray-900" title="Edit">
                        <Edit className="h-4 w-4" />
                      </button>
                      <button className="text-red-600 hover:text-red-900" title="Delete">
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {filteredMappings.length === 0 && (
          <div className="text-center py-12">
            <Database className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No mappings found</h3>
            <p className="text-gray-600">Try adjusting your search criteria or create a new mapping.</p>
          </div>
        )}
      </div>

      {/* System Pairs Summary */}
      <div className="mt-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">System Integration Summary</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {systemPairs.map((pair, index) => (
            <div key={index} className="flex items-center p-3 bg-gray-50 rounded-lg">
              <ArrowRight className="h-5 w-5 text-gray-400 mr-3" />
              <span className="text-sm text-gray-700">{pair}</span>
              <span className="ml-auto text-sm text-gray-500">
                {mappings.filter(m => `${m.sourceSystem} → ${m.targetSystem}` === pair).length} mappings
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="mt-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Test All Mappings</h4>
            <p className="text-sm text-gray-600 mt-1">Validate all field mappings</p>
          </button>
          
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Import Mappings</h4>
            <p className="text-sm text-gray-600 mt-1">Upload mapping configuration</p>
          </button>
          
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Generate Schema</h4>
            <p className="text-sm text-gray-600 mt-1">Export mapping documentation</p>
          </button>
        </div>
      </div>
    </div>
  );
};

export default DataMappingTool;