import React, { useState } from 'react';
import { ArrowLeft } from 'lucide-react';
import EmployeeSearch from './EmployeeSearch';
import EmployeeProfile from './EmployeeProfile';

/**
 * Demo component showing integration between EmployeeSearch and EmployeeProfile
 * This demonstrates the complete workflow:
 * 1. Search for employees using the search component
 * 2. Click on a result to view their profile
 * 3. Return to search from the profile view
 */
const EmployeeSearchDemo: React.FC = () => {
  const [selectedEmployeeId, setSelectedEmployeeId] = useState<number | null>(null);

  const handleEmployeeSelect = (employeeId: number) => {
    console.log('[DEMO] Selected employee ID:', employeeId);
    setSelectedEmployeeId(employeeId);
  };

  const handleBackToSearch = () => {
    setSelectedEmployeeId(null);
  };

  return (
    <div className="min-h-screen bg-gray-100 py-8">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {selectedEmployeeId ? (
          <>
            {/* Back button */}
            <div className="mb-6">
              <button
                onClick={handleBackToSearch}
                className="flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <ArrowLeft className="h-4 w-4 mr-2" />
                Вернуться к поиску
              </button>
            </div>
            
            {/* Employee Profile */}
            <EmployeeProfile
              employeeId={selectedEmployeeId.toString()}
              onEdit={() => console.log('Edit employee', selectedEmployeeId)}
            />
          </>
        ) : (
          <>
            {/* Page Header */}
            <div className="mb-8">
              <h1 className="text-3xl font-bold text-gray-900">
                Поиск и просмотр сотрудников
              </h1>
              <p className="mt-2 text-gray-600">
                Найдите сотрудника по имени, email или коду агента, затем нажмите на результат для просмотра профиля
              </p>
            </div>

            {/* Employee Search */}
            <EmployeeSearch
              onEmployeeSelect={handleEmployeeSelect}
              className="max-w-4xl mx-auto"
            />

            {/* Usage Instructions */}
            <div className="mt-8 max-w-4xl mx-auto">
              <div className="bg-blue-50 border border-blue-200 rounded-md p-4">
                <h3 className="text-sm font-medium text-blue-800 mb-2">
                  Инструкция по использованию:
                </h3>
                <ul className="text-sm text-blue-700 space-y-1 list-disc list-inside">
                  <li>Введите минимум 2 символа для начала поиска</li>
                  <li>Используйте фильтры для уточнения результатов</li>
                  <li>Нажмите на результат поиска для просмотра профиля сотрудника</li>
                  <li>Используйте кнопки навигации для пролистывания результатов</li>
                </ul>
              </div>
            </div>

            {/* API Integration Info */}
            <div className="mt-6 max-w-4xl mx-auto">
              <div className="bg-green-50 border border-green-200 rounded-md p-4">
                <h3 className="text-sm font-medium text-green-800 mb-2">
                  API интеграция:
                </h3>
                <div className="text-sm text-green-700">
                  <p><strong>Endpoint:</strong> GET /api/v1/employees/search/query</p>
                  <p><strong>Параметры:</strong> q (поисковый запрос), active_only (только активные), limit (количество результатов)</p>
                  <p><strong>Поиск по:</strong> имя, фамилия, email, код агента, полное имя</p>
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default EmployeeSearchDemo;