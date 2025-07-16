import React, { useState, useEffect } from 'react';
import { Search, Filter, X, User, AlertCircle, RefreshCw, Calendar, MapPin } from 'lucide-react';
import realEmployeeService, { EmployeeSearchParams, PaginatedResponse } from '../../../../services/realEmployeeService';
import { Employee } from '../../types/employee';

interface EmployeeSearchProps {
  onEmployeeSelect?: (employee: Employee) => void;
  className?: string;
}

const EmployeeSearch: React.FC<EmployeeSearchProps> = ({ onEmployeeSelect, className = '' }) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<Employee[]>([]);
  const [filters, setFilters] = useState({
    teams: [] as string[],
    positions: [] as string[],
    statuses: [] as string[],
    departments: [] as string[]
  });
  const [isSearching, setIsSearching] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [totalResults, setTotalResults] = useState(0);
  const [currentPage, setCurrentPage] = useState(1);
  const [hasSearched, setHasSearched] = useState(false);
  const [showAdvancedFilters, setShowAdvancedFilters] = useState(false);

  const itemsPerPage = 20;

  const teams = [
    { id: 't1', name: 'Support Team', color: '#3b82f6' },
    { id: 't2', name: 'Sales Team', color: '#10b981' },
    { id: 't3', name: 'Quality Team', color: '#f59e0b' }
  ];

  const positions = [
    'Junior Operator',
    'Senior Operator', 
    'Team Lead',
    'Quality Specialist',
    'Training Specialist',
    'Supervisor'
  ];

  const statuses = [
    'active',
    'vacation',
    'probation',
    'inactive'
  ];

  const departments = [
    'Support',
    'Sales',
    'Quality',
    'Training'
  ];

  // Perform search
  const performSearch = async (page: number = 1) => {
    if (!searchQuery.trim() && filters.teams.length === 0 && filters.positions.length === 0) {
      return;
    }

    setIsSearching(true);
    setApiError('');
    
    try {
      // Check API health first
      const isApiHealthy = await realEmployeeService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('Employee API server is not available. Please try again later.');
      }

      const searchParams: EmployeeSearchParams = {
        query: searchQuery.trim(),
        filters: {
          teams: filters.teams.length > 0 ? filters.teams : undefined,
          positions: filters.positions.length > 0 ? filters.positions : undefined,
          statuses: filters.statuses.length > 0 ? filters.statuses : undefined,
          departments: filters.departments.length > 0 ? filters.departments : undefined
        },
        limit: itemsPerPage,
        offset: (page - 1) * itemsPerPage
      };

      console.log('[REAL EMPLOYEE SEARCH] Searching with params:', searchParams);

      const result = await realEmployeeService.searchEmployees(searchParams);
      
      if (result.success && result.data) {
        setSearchResults(result.data.items);
        setTotalResults(result.data.total);
        setCurrentPage(page);
        setHasSearched(true);
        console.log('[REAL EMPLOYEE SEARCH] Found', result.data.items.length, 'employees');
      } else {
        throw new Error(result.error || 'Search failed');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL EMPLOYEE SEARCH] Error:', error);
    } finally {
      setIsSearching(false);
    }
  };

  // Handle search form submission
  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setCurrentPage(1);
    performSearch(1);
  };

  // Handle filter changes
  const handleFilterChange = (filterType: keyof typeof filters, value: string, checked: boolean) => {
    setFilters(prev => ({
      ...prev,
      [filterType]: checked 
        ? [...prev[filterType], value]
        : prev[filterType].filter(item => item !== value)
    }));
  };

  // Clear filters
  const clearFilters = () => {
    setFilters({
      teams: [],
      positions: [],
      statuses: [],
      departments: []
    });
  };

  // Clear search
  const clearSearch = () => {
    setSearchQuery('');
    setSearchResults([]);
    setFilters({
      teams: [],
      positions: [],
      statuses: [],
      departments: []
    });
    setApiError('');
    setHasSearched(false);
    setCurrentPage(1);
    setTotalResults(0);
  };

  // Handle employee selection
  const handleEmployeeSelect = (employee: Employee) => {
    if (onEmployeeSelect) {
      onEmployeeSelect(employee);
    }
  };

  // Handle pagination
  const handlePageChange = (newPage: number) => {
    performSearch(newPage);
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

  // Auto-search when filters change (debounced)
  useEffect(() => {
    const timer = setTimeout(() => {
      if (hasSearched && (searchQuery.trim() || filters.teams.length > 0 || filters.positions.length > 0)) {
        performSearch(1);
      }
    }, 500);

    return () => clearTimeout(timer);
  }, [filters]);

  const totalPages = Math.ceil(totalResults / itemsPerPage);
  const hasActiveFilters = filters.teams.length > 0 || filters.positions.length > 0 || filters.statuses.length > 0 || filters.departments.length > 0;

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Search className="h-6 w-6 mr-2 text-blue-600" />
          Employee Search
        </h2>
        <div className="text-sm text-gray-500">
          Search through real employee database
        </div>
      </div>

      {/* Search Form */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <form onSubmit={handleSearch} className="space-y-4">
          <div className="flex gap-4">
            <div className="flex-1 relative">
              <Search className="h-4 w-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Search by name, email, employee ID..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <button
              type="button"
              onClick={() => setShowAdvancedFilters(!showAdvancedFilters)}
              className={`px-4 py-2 border rounded-md flex items-center gap-2 transition-colors ${
                showAdvancedFilters || hasActiveFilters
                  ? 'border-blue-500 bg-blue-50 text-blue-700'
                  : 'border-gray-300 text-gray-700 hover:bg-gray-50'
              }`}
            >
              <Filter className="h-4 w-4" />
              Filters
              {hasActiveFilters && (
                <span className="bg-blue-600 text-white text-xs px-2 py-1 rounded-full">
                  {filters.teams.length + filters.positions.length + filters.statuses.length + filters.departments.length}
                </span>
              )}
            </button>
            <button
              type="submit"
              disabled={isSearching}
              className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {isSearching ? (
                <>
                  <RefreshCw className="h-4 w-4 animate-spin" />
                  Searching...
                </>
              ) : (
                <>
                  <Search className="h-4 w-4" />
                  Search
                </>
              )}
            </button>
            {hasSearched && (
              <button
                type="button"
                onClick={clearSearch}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 flex items-center gap-2"
              >
                <X className="h-4 w-4" />
                Clear
              </button>
            )}
          </div>

          {/* Advanced Filters */}
          {showAdvancedFilters && (
            <div className="pt-4 border-t border-gray-200 space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                {/* Teams Filter */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Teams</label>
                  <div className="space-y-2 max-h-32 overflow-y-auto">
                    {teams.map(team => (
                      <label key={team.id} className="flex items-center gap-2 text-sm">
                        <input
                          type="checkbox"
                          checked={filters.teams.includes(team.id)}
                          onChange={(e) => handleFilterChange('teams', team.id, e.target.checked)}
                          className="rounded"
                        />
                        <span style={{ color: team.color }}>{team.name}</span>
                      </label>
                    ))}
                  </div>
                </div>

                {/* Positions Filter */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Positions</label>
                  <div className="space-y-2 max-h-32 overflow-y-auto">
                    {positions.map(position => (
                      <label key={position} className="flex items-center gap-2 text-sm">
                        <input
                          type="checkbox"
                          checked={filters.positions.includes(position)}
                          onChange={(e) => handleFilterChange('positions', position, e.target.checked)}
                          className="rounded"
                        />
                        <span>{position}</span>
                      </label>
                    ))}
                  </div>
                </div>

                {/* Status Filter */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Status</label>
                  <div className="space-y-2">
                    {statuses.map(status => (
                      <label key={status} className="flex items-center gap-2 text-sm">
                        <input
                          type="checkbox"
                          checked={filters.statuses.includes(status)}
                          onChange={(e) => handleFilterChange('statuses', status, e.target.checked)}
                          className="rounded"
                        />
                        <span className="capitalize">{status}</span>
                      </label>
                    ))}
                  </div>
                </div>

                {/* Departments Filter */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Departments</label>
                  <div className="space-y-2">
                    {departments.map(department => (
                      <label key={department} className="flex items-center gap-2 text-sm">
                        <input
                          type="checkbox"
                          checked={filters.departments.includes(department)}
                          onChange={(e) => handleFilterChange('departments', department, e.target.checked)}
                          className="rounded"
                        />
                        <span>{department}</span>
                      </label>
                    ))}
                  </div>
                </div>
              </div>

              {hasActiveFilters && (
                <div className="flex justify-end">
                  <button
                    type="button"
                    onClick={clearFilters}
                    className="text-sm text-gray-600 hover:text-gray-800 underline"
                  >
                    Clear all filters
                  </button>
                </div>
              )}
            </div>
          )}
        </form>
      </div>

      {/* API Error Display */}
      {apiError && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center gap-2 text-red-800">
            <AlertCircle className="h-5 w-5 text-red-500" />
            <div>
              <div className="font-medium">Search Error</div>
              <div className="text-sm">{apiError}</div>
            </div>
          </div>
        </div>
      )}

      {/* Search Results */}
      {hasSearched && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          {/* Results Header */}
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-medium text-gray-900">
                Search Results
                {totalResults > 0 && (
                  <span className="ml-2 text-sm font-normal text-gray-500">
                    ({totalResults} {totalResults === 1 ? 'employee' : 'employees'} found)
                  </span>
                )}
              </h3>
              {isSearching && (
                <RefreshCw className="h-5 w-5 animate-spin text-blue-600" />
              )}
            </div>
          </div>

          {/* Results List */}
          {searchResults.length > 0 ? (
            <div className="divide-y divide-gray-200">
              {searchResults.map((employee) => (
                <div
                  key={employee.id}
                  className="p-6 hover:bg-gray-50 cursor-pointer transition-colors"
                  onClick={() => handleEmployeeSelect(employee)}
                >
                  <div className="flex items-center space-x-4">
                    <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center overflow-hidden">
                      {employee.personalInfo.photo ? (
                        <img 
                          src={employee.personalInfo.photo} 
                          alt="Employee" 
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <User className="w-6 h-6 text-blue-600" />
                      )}
                    </div>
                    
                    <div className="flex-1">
                      <div className="flex items-center justify-between">
                        <div>
                          <h4 className="text-lg font-medium text-gray-900">
                            {employee.personalInfo.firstName} {employee.personalInfo.lastName}
                          </h4>
                          <p className="text-sm text-gray-500">
                            {employee.employeeId} • {employee.personalInfo.email}
                          </p>
                        </div>
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(employee.status)}`}>
                          {employee.status}
                        </span>
                      </div>
                      
                      <div className="mt-2 flex items-center space-x-4 text-sm text-gray-600">
                        <span className="flex items-center">
                          <Calendar className="w-4 h-4 mr-1" />
                          {employee.workInfo.position}
                        </span>
                        <span 
                          className="flex items-center px-2 py-1 rounded-full text-xs"
                          style={{ backgroundColor: employee.workInfo.team.color + '20', color: employee.workInfo.team.color }}
                        >
                          {employee.workInfo.team.name}
                        </span>
                        <span className="flex items-center">
                          <MapPin className="w-4 h-4 mr-1" />
                          {employee.workInfo.workLocation}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : !isSearching ? (
            <div className="px-6 py-12 text-center">
              <Search className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No employees found</h3>
              <p className="text-gray-500">
                Try adjusting your search query or filters to find employees.
              </p>
            </div>
          ) : null}

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="px-6 py-4 border-t border-gray-200">
              <div className="flex items-center justify-between">
                <div className="text-sm text-gray-700">
                  Page {currentPage} of {totalPages}
                </div>
                <div className="flex space-x-2">
                  <button
                    onClick={() => handlePageChange(currentPage - 1)}
                    disabled={currentPage === 1 || isSearching}
                    className="px-3 py-1 border border-gray-300 rounded-md text-sm hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Previous
                  </button>
                  <button
                    onClick={() => handlePageChange(currentPage + 1)}
                    disabled={currentPage === totalPages || isSearching}
                    className="px-3 py-1 border border-gray-300 rounded-md text-sm hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Next
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* No Search Performed */}
      {!hasSearched && !isSearching && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 px-6 py-12 text-center">
          <Search className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Search Real Employee Database</h3>
          <p className="text-gray-500 mb-4">
            Enter a search query and click "Search" to find employees using real API calls.
          </p>
          <div className="bg-blue-50 rounded-lg border border-blue-200 p-4 max-w-md mx-auto">
            <h4 className="text-sm font-medium text-blue-900 mb-2">Real Search Features:</h4>
            <ul className="text-sm text-blue-800 space-y-1">
              <li>• Search by name, email, or employee ID</li>
              <li>• Filter by team, position, status, department</li>
              <li>• Real-time API integration</li>
              <li>• Pagination for large results</li>
              <li>• JWT authentication enabled</li>
            </ul>
          </div>
        </div>
      )}
    </div>
  );
};

export default EmployeeSearch;