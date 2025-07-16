import React, { useState, useEffect, useCallback } from 'react';
import { Search, Filter, User, Mail, UserCheck, UserX, AlertCircle, Loader2, Eye, ChevronLeft, ChevronRight } from 'lucide-react';

// API Response type based on the endpoint
interface EmployeeSearchResult {
  id: number;
  agent_code: string;
  first_name: string;
  last_name: string;
  email: string | null;
  is_active: boolean;
}

export interface EmployeeSearchProps {
  onEmployeeSelect?: (employeeId: number) => void;
  className?: string;
}

const EmployeeSearch: React.FC<EmployeeSearchProps> = ({ onEmployeeSelect, className = '' }) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [debouncedQuery, setDebouncedQuery] = useState('');
  const [employees, setEmployees] = useState<EmployeeSearchResult[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  
  // Filters
  const [activeOnly, setActiveOnly] = useState(true);
  const [limit, setLimit] = useState(10);
  const [currentPage, setCurrentPage] = useState(1);
  
  // Pagination state
  const [hasMoreResults, setHasMoreResults] = useState(false);
  const [totalDisplayed, setTotalDisplayed] = useState(0);

  const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

  // Debounce search query
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedQuery(searchQuery);
      setCurrentPage(1); // Reset to first page on new search
    }, 300);

    return () => clearTimeout(timer);
  }, [searchQuery]);

  // Perform search when debounced query changes
  useEffect(() => {
    if (debouncedQuery.length >= 2) {
      performSearch();
    } else {
      setEmployees([]);
      setError('');
      setHasMoreResults(false);
      setTotalDisplayed(0);
    }
  }, [debouncedQuery, activeOnly, limit, currentPage]);

  const performSearch = useCallback(async () => {
    setIsLoading(true);
    setError('');

    try {
      const params = new URLSearchParams({
        q: debouncedQuery,
        active_only: activeOnly.toString(),
        limit: limit.toString()
      });

      console.log(`[EMPLOYEE SEARCH] Searching: ${API_BASE_URL}/employees/search/query?${params}`);
      
      const response = await fetch(`${API_BASE_URL}/employees/search/query?${params}`, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: Поиск не удался`);
      }

      const searchResults = await response.json();
      console.log('[EMPLOYEE SEARCH] Search results:', searchResults);
      
      setEmployees(searchResults);
      setTotalDisplayed(searchResults.length);
      setHasMoreResults(searchResults.length === limit); // Assume more results if we got full limit
      
    } catch (err) {
      console.error('[EMPLOYEE SEARCH] Error searching employees:', err);
      setError(err instanceof Error ? err.message : 'Ошибка поиска сотрудников');
      setEmployees([]);
    } finally {
      setIsLoading(false);
    }
  }, [debouncedQuery, activeOnly, limit, currentPage, API_BASE_URL]);

  const handleEmployeeClick = (employeeId: number) => {
    if (onEmployeeSelect) {
      onEmployeeSelect(employeeId);
    }
  };

  const getStatusBadge = (isActive: boolean) => {
    if (isActive) {
      return (
        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
          <UserCheck className="h-3 w-3 mr-1" />
          Активен
        </span>
      );
    } else {
      return (
        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
          <UserX className="h-3 w-3 mr-1" />
          Неактивен
        </span>
      );
    }
  };

  const handleNextPage = () => {
    if (hasMoreResults) {
      setCurrentPage(prev => prev + 1);
    }
  };

  const handlePrevPage = () => {
    if (currentPage > 1) {
      setCurrentPage(prev => prev - 1);
    }
  };

  return (
    <div className={`bg-white rounded-lg shadow-md ${className}`}>
      {/* Header */}
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-semibold text-gray-900">Поиск сотрудников</h2>
          <button
            onClick={() => setShowFilters(!showFilters)}
            className="flex items-center px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <Filter className="h-4 w-4 mr-2" />
            Фильтры
          </button>
        </div>

        {/* Search Input */}
        <div className="relative">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search className="h-5 w-5 text-gray-400" />
          </div>
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Поиск по имени, email или коду агента..."
            className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
          {isLoading && (
            <div className="absolute inset-y-0 right-0 pr-3 flex items-center">
              <Loader2 className="h-5 w-5 text-gray-400 animate-spin" />
            </div>
          )}
        </div>

        {/* Filters Panel */}
        {showFilters && (
          <div className="mt-4 p-4 bg-gray-50 rounded-md">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Статус
                </label>
                <select
                  value={activeOnly ? 'active' : 'all'}
                  onChange={(e) => setActiveOnly(e.target.value === 'active')}
                  className="block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="active">Только активные</option>
                  <option value="all">Все сотрудники</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Результатов на странице
                </label>
                <select
                  value={limit}
                  onChange={(e) => setLimit(Number(e.target.value))}
                  className="block w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value={5}>5</option>
                  <option value={10}>10</option>
                  <option value={25}>25</option>
                  <option value={50}>50</option>
                </select>
              </div>
            </div>
          </div>
        )}

        {/* Search Info */}
        {debouncedQuery.length >= 2 && (
          <div className="mt-4 text-sm text-gray-600">
            {isLoading ? (
              'Поиск...'
            ) : employees.length > 0 ? (
              `Найдено: ${totalDisplayed} сотрудников${hasMoreResults ? ' (возможно больше)' : ''}`
            ) : (
              'Сотрудники не найдены'
            )}
          </div>
        )}
      </div>

      {/* Search Results */}
      <div className="p-6">
        {/* Error State */}
        {error && (
          <div className="flex items-center justify-center py-8">
            <div className="text-center">
              <AlertCircle className="h-12 w-12 text-red-500 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">Ошибка поиска</h3>
              <p className="text-gray-600 mb-4">{error}</p>
              <button
                onClick={performSearch}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                Попробовать снова
              </button>
            </div>
          </div>
        )}

        {/* Empty State */}
        {!error && debouncedQuery.length < 2 && (
          <div className="text-center py-8">
            <Search className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">Начните поиск</h3>
            <p className="text-gray-600">Введите минимум 2 символа для поиска сотрудников</p>
          </div>
        )}

        {/* No Results */}
        {!error && debouncedQuery.length >= 2 && employees.length === 0 && !isLoading && (
          <div className="text-center py-8">
            <User className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">Сотрудники не найдены</h3>
            <p className="text-gray-600">Попробуйте изменить поисковый запрос или фильтры</p>
          </div>
        )}

        {/* Results List */}
        {!error && employees.length > 0 && (
          <div className="space-y-3">
            {employees.map((employee) => (
              <div
                key={employee.id}
                onClick={() => handleEmployeeClick(employee.id)}
                className="p-4 border border-gray-200 rounded-md hover:bg-gray-50 hover:border-gray-300 cursor-pointer transition-colors"
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-4">
                    <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                      <User className="h-5 w-5 text-blue-600" />
                    </div>
                    <div>
                      <h4 className="text-lg font-medium text-gray-900">
                        {employee.first_name} {employee.last_name}
                      </h4>
                      <div className="flex items-center space-x-4 text-sm text-gray-600">
                        <span>Код: {employee.agent_code}</span>
                        {employee.email && (
                          <div className="flex items-center">
                            <Mail className="h-4 w-4 mr-1" />
                            {employee.email}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-3">
                    {getStatusBadge(employee.is_active)}
                    <Eye className="h-5 w-5 text-gray-400" />
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Pagination */}
        {!error && employees.length > 0 && (
          <div className="mt-6 flex items-center justify-between">
            <div className="text-sm text-gray-600">
              Страница {currentPage}
            </div>
            <div className="flex items-center space-x-2">
              <button
                onClick={handlePrevPage}
                disabled={currentPage === 1}
                className="flex items-center px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <ChevronLeft className="h-4 w-4 mr-1" />
                Назад
              </button>
              <button
                onClick={handleNextPage}
                disabled={!hasMoreResults}
                className="flex items-center px-3 py-2 text-sm border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Далее
                <ChevronRight className="h-4 w-4 ml-1" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default EmployeeSearch;