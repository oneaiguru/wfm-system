import React, { useState, useEffect } from 'react';
import { Search, Filter, Download, Upload, Users, Grid, List, RefreshCw, AlertCircle } from 'lucide-react';
import { Employee, EmployeeFilters, EmployeeStats } from '../../types/employee';
import realEmployeeService, { PaginatedResponse } from '../../../../services/realEmployeeService';

interface EmployeeListContainerProps {
  viewMode: 'list' | 'grid' | 'gallery';
}

const EmployeeListContainer: React.FC<EmployeeListContainerProps> = ({ viewMode }) => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [filters, setFilters] = useState<EmployeeFilters>({
    search: '',
    team: '',
    status: '',
    skill: '',
    position: '',
    sortBy: 'name',
    sortOrder: 'asc',
    showInactive: false
  });
  const [stats, setStats] = useState<EmployeeStats>({
    total: 0,
    active: 0,
    vacation: 0,
    probation: 0,
    inactive: 0,
    terminated: 0
  });
  const [selectedEmployees, setSelectedEmployees] = useState<string[]>([]);
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isLoading, setIsLoading] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [hasMore, setHasMore] = useState(false);
  const itemsPerPage = 50;

  // Real data loading from API
  const loadEmployees = async () => {
    setIsLoading(true);
    setApiError('');
    
    try {
      // Check API health first
      const isApiHealthy = await realEmployeeService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('Employee API server is not available. Please try again later.');
      }

      // Load employees with current filters and pagination
      const employeesResult = await realEmployeeService.getEmployees(filters, currentPage, itemsPerPage);
      
      if (employeesResult.success && employeesResult.data) {
        setEmployees(employeesResult.data.items);
        setTotalPages(Math.ceil(employeesResult.data.total / itemsPerPage));
        setHasMore(employeesResult.data.hasMore);
        console.log('[REAL EMPLOYEE LIST] Loaded employees:', employeesResult.data.items.length);
      } else {
        throw new Error(employeesResult.error || 'Failed to load employees');
      }

      // Load statistics
      const statsResult = await realEmployeeService.getEmployeeStats();
      if (statsResult.success && statsResult.data) {
        setStats(statsResult.data);
        console.log('[REAL EMPLOYEE LIST] Loaded stats:', statsResult.data);
      } else {
        console.warn('[REAL EMPLOYEE LIST] Failed to load stats:', statsResult.error);
      }

      setLastUpdate(new Date());
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL EMPLOYEE LIST] Error loading employees:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // Load employees on mount and when filters/page change
  useEffect(() => {
    loadEmployees();
  }, [filters, currentPage]);

  // Initial load
  useEffect(() => {
    loadEmployees();
  }, []);

  // Real refresh functionality
  const handleRefresh = async () => {
    await loadEmployees();
  };

  // Handle filter changes - reload data from server
  const handleFilterChange = (newFilters: Partial<EmployeeFilters>) => {
    setFilters(prev => ({ ...prev, ...newFilters }));
    setCurrentPage(1); // Reset to first page when filters change
  };

  // Handle pagination
  const handlePageChange = (newPage: number) => {
    setCurrentPage(newPage);
  };

  // Handle export functionality
  const handleExport = async () => {
    try {
      const result = await realEmployeeService.exportEmployees(filters, 'csv');
      if (result.success && result.data) {
        // Open download URL in new tab
        window.open(result.data.downloadUrl, '_blank');
      } else {
        setApiError(result.error || 'Export failed');
      }
    } catch (error) {
      setApiError('Export failed');
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800';
      case 'vacation':
        return 'bg-blue-100 text-blue-800';
      case 'probation':
        return 'bg-yellow-100 text-yellow-800';
      case 'inactive':
        return 'bg-gray-100 text-gray-800';
      case 'terminated':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getPerformanceColor = (score: number) => {
    if (score >= 90) return 'text-green-600';
    if (score >= 80) return 'text-yellow-600';
    return 'text-red-600';
  };

  const handleSelectEmployee = (employeeId: string) => {
    setSelectedEmployees(prev =>
      prev.includes(employeeId)
        ? prev.filter(id => id !== employeeId)
        : [...prev, employeeId]
    );
  };

  const handleSelectAll = () => {
    setSelectedEmployees(
      selectedEmployees.length === employees.length
        ? []
        : employees.map(emp => emp.id)
    );
  };

  return (
    <div>
      {/* Header with Stats */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-gray-900">Employee Directory</h2>
          <div className="flex items-center space-x-2">
            <button
              onClick={handleRefresh}
              disabled={isLoading}
              className={`flex items-center space-x-2 text-sm px-3 py-1 rounded-md transition-colors ${
                isLoading 
                  ? 'text-blue-600 bg-blue-50 cursor-not-allowed' 
                  : 'text-gray-500 hover:text-blue-600 hover:bg-blue-50'
              }`}
            >
              <RefreshCw className={`h-4 w-4 ${isLoading ? 'animate-spin' : ''}`} />
              <span>{isLoading ? 'Updating...' : `Updated: ${lastUpdate.toLocaleTimeString()}`}</span>
            </button>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 md:grid-cols-6 gap-4 mb-6">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-gray-900">{stats.total}</div>
            <div className="text-sm text-gray-600">Total</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-green-600">{stats.active}</div>
            <div className="text-sm text-gray-600">Active</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-blue-600">{stats.vacation}</div>
            <div className="text-sm text-gray-600">On Vacation</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-yellow-600">{stats.probation}</div>
            <div className="text-sm text-gray-600">Probation</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-gray-600">{stats.inactive}</div>
            <div className="text-sm text-gray-600">Inactive</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-red-600">{stats.terminated}</div>
            <div className="text-sm text-gray-600">Terminated</div>
          </div>
        </div>
      </div>

      {/* Filters and Actions */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center space-x-4">
            <div className="relative">
              <Search className="h-4 w-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Search employees..."
                value={filters.search}
                onChange={(e) => handleFilterChange({ search: e.target.value })}
                className="pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <select
              value={filters.status}
              onChange={(e) => handleFilterChange({ status: e.target.value })}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Statuses</option>
              <option value="active">Active</option>
              <option value="vacation">On Vacation</option>
              <option value="probation">Probation</option>
              <option value="inactive">Inactive</option>
            </select>

            <select
              value={filters.sortBy}
              onChange={(e) => handleFilterChange({ sortBy: e.target.value as any })}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="name">Sort by Name</option>
              <option value="position">Sort by Position</option>
              <option value="team">Sort by Team</option>
              <option value="hireDate">Sort by Hire Date</option>
              <option value="performance">Sort by Performance</option>
            </select>
          </div>

          <div className="flex items-center space-x-2">
            {selectedEmployees.length > 0 && (
              <span className="text-sm text-gray-600">
                {selectedEmployees.length} selected
              </span>
            )}
            <button 
              onClick={handleExport}
              disabled={isLoading}
              className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
            >
              <Download className="h-4 w-4 mr-2" />
              Export
            </button>
          </div>
        </div>
      </div>

      {/* API Error Display */}
      {apiError && (
        <div className="mb-6 bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center gap-2 text-red-800">
            <AlertCircle className="h-5 w-5 text-red-500" />
            <div>
              <div className="font-medium">Error Loading Employees</div>
              <div className="text-sm">{apiError}</div>
              <button
                onClick={handleRefresh}
                className="mt-2 text-sm text-red-600 hover:text-red-800 underline"
              >
                Try Again
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Loading State */}
      {isLoading && employees.length === 0 && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8">
          <div className="flex items-center justify-center">
            <RefreshCw className="h-6 w-6 animate-spin text-blue-600 mr-3" />
            <span className="text-gray-600">Loading employees...</span>
          </div>
        </div>
      )}

      {/* Employee List */}
      {!isLoading || employees.length > 0 ? (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          {viewMode === 'list' ? (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left">
                      <input
                        type="checkbox"
                        checked={selectedEmployees.length === employees.length && employees.length > 0}
                        onChange={handleSelectAll}
                        className="rounded"
                      />
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Employee
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Position
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Team
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Performance
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Last Login
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {employees.map((employee) => (
                    <tr key={employee.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4">
                        <input
                          type="checkbox"
                          checked={selectedEmployees.includes(employee.id)}
                          onChange={() => handleSelectEmployee(employee.id)}
                          className="rounded"
                        />
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <img
                            className="h-10 w-10 rounded-full"
                            src={employee.personalInfo.photo || `https://ui-avatars.com/api/?name=${employee.personalInfo.firstName}+${employee.personalInfo.lastName}&background=3b82f6&color=fff`}
                            alt=""
                          />
                          <div className="ml-4">
                            <div className="text-sm font-medium text-gray-900">
                              {employee.personalInfo.firstName} {employee.personalInfo.lastName}
                            </div>
                            <div className="text-sm text-gray-500">{employee.employeeId}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{employee.workInfo.position}</div>
                        <div className="text-sm text-gray-500">{employee.workInfo.department}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span 
                          className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                          style={{ backgroundColor: employee.workInfo.team.color + '20', color: employee.workInfo.team.color }}
                        >
                          {employee.workInfo.team.name}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(employee.status)}`}>
                          {employee.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className={`text-sm font-medium ${getPerformanceColor(employee.performance.qualityScore)}`}>
                          {employee.performance.qualityScore.toFixed(1)}%
                        </div>
                        <div className="text-xs text-gray-500">Quality Score</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {employee.metadata.lastLogin ? 
                          employee.metadata.lastLogin.toLocaleDateString() : 
                          'Never'
                        }
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 p-6">
              {employees.map((employee) => (
                <div key={employee.id} className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow">
                  <div className="flex items-center space-x-3 mb-3">
                    <img
                      className="h-12 w-12 rounded-full"
                      src={employee.personalInfo.photo || `https://ui-avatars.com/api/?name=${employee.personalInfo.firstName}+${employee.personalInfo.lastName}&background=3b82f6&color=fff`}
                      alt=""
                    />
                    <div>
                      <h3 className="text-sm font-medium text-gray-900">
                        {employee.personalInfo.firstName} {employee.personalInfo.lastName}
                      </h3>
                      <p className="text-xs text-gray-500">{employee.employeeId}</p>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <div className="text-sm text-gray-900">{employee.workInfo.position}</div>
                    <span 
                      className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
                      style={{ backgroundColor: employee.workInfo.team.color + '20', color: employee.workInfo.team.color }}
                    >
                      {employee.workInfo.team.name}
                    </span>
                    <div className="flex justify-between items-center">
                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(employee.status)}`}>
                        {employee.status}
                      </span>
                      <span className={`text-sm font-medium ${getPerformanceColor(employee.performance.qualityScore)}`}>
                        {employee.performance.qualityScore.toFixed(1)}%
                      </span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="px-6 py-4 border-t border-gray-200">
              <div className="flex items-center justify-between">
                <div className="text-sm text-gray-700">
                  Page {currentPage} of {totalPages} - {stats.total} total employees
                </div>
                <div className="flex space-x-2">
                  <button
                    onClick={() => handlePageChange(currentPage - 1)}
                    disabled={currentPage === 1 || isLoading}
                    className="px-3 py-1 border border-gray-300 rounded-md text-sm hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Previous
                  </button>
                  <button
                    onClick={() => handlePageChange(currentPage + 1)}
                    disabled={currentPage === totalPages || isLoading}
                    className="px-3 py-1 border border-gray-300 rounded-md text-sm hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Next
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      ) : null}
    </div>
  );
};

export default EmployeeListContainer;