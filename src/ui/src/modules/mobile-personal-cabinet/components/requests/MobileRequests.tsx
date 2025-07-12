import React, { useState } from 'react';
import { Plus, Clock, CheckCircle, XCircle, AlertCircle } from 'lucide-react';
import { MobileRequest } from '../../types/mobile';

// BDD: Forms for sick leave, day off, and vacation requests
const MobileRequests: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'my' | 'available'>('my');
  const [showCreateForm, setShowCreateForm] = useState(false);

  // Mock data - BDD specifies request types and statuses
  const myRequests: MobileRequest[] = [
    {
      id: 'REQ001',
      type: 'vacation',
      status: 'approved',
      startDate: '2024-08-15',
      endDate: '2024-08-25',
      reason: 'Отпуск',
      comment: 'Летний отпуск с семьей',
      createdAt: '2024-07-01T10:00:00Z',
      updatedAt: '2024-07-03T14:30:00Z'
    },
    {
      id: 'REQ002', 
      type: 'dayoff',
      status: 'pending',
      startDate: '2024-07-20',
      endDate: '2024-07-20',
      reason: 'Личные дела',
      comment: 'Поход к врачу',
      createdAt: '2024-07-10T09:15:00Z',
      updatedAt: '2024-07-10T09:15:00Z'
    },
    {
      id: 'REQ003',
      type: 'sick',
      status: 'rejected',
      startDate: '2024-07-05',
      endDate: '2024-07-07',
      reason: 'Больничный',
      comment: 'ОРВИ',
      createdAt: '2024-07-05T08:00:00Z',
      updatedAt: '2024-07-06T16:00:00Z'
    }
  ];

  const availableRequests = [
    {
      id: 'EXC001',
      type: 'shift-exchange',
      employee: 'Михаил Волков',
      date: '2024-07-18',
      shift: '14:00 - 22:00',
      reason: 'Семейное мероприятие'
    }
  ];

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'approved': return 'text-green-600 bg-green-100';
      case 'pending': return 'text-yellow-600 bg-yellow-100';
      case 'rejected': return 'text-red-600 bg-red-100';
      case 'draft': return 'text-gray-600 bg-gray-100';
      default: return 'text-gray-600 bg-gray-100';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'approved': return <CheckCircle className="h-4 w-4" />;
      case 'pending': return <Clock className="h-4 w-4" />;
      case 'rejected': return <XCircle className="h-4 w-4" />;
      case 'draft': return <AlertCircle className="h-4 w-4" />;
      default: return <Clock className="h-4 w-4" />;
    }
  };

  const getTypeLabel = (type: string) => {
    switch (type) {
      case 'vacation': return 'Отпуск';
      case 'sick': return 'Больничный';
      case 'dayoff': return 'Отгул';
      case 'shift-exchange': return 'Обмен смены';
      default: return type;
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'approved': return 'Одобрено';
      case 'pending': return 'Ожидает';
      case 'rejected': return 'Отклонено';
      case 'draft': return 'Черновик';
      default: return status;
    }
  };

  return (
    <div className="space-y-4">
      {/* Header with Create Button */}
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-gray-900">Заявки</h2>
        <button
          onClick={() => setShowCreateForm(true)}
          className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Plus className="h-4 w-4" />
          <span>Создать</span>
        </button>
      </div>

      {/* Tab Navigation - BDD: Two sections - "My requests" and "Available requests" */}
      <div className="bg-white rounded-lg shadow-sm">
        <div className="flex border-b">
          <button
            onClick={() => setActiveTab('my')}
            className={`flex-1 px-4 py-3 text-center font-medium transition-colors ${
              activeTab === 'my'
                ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            Мои заявки ({myRequests.length})
          </button>
          <button
            onClick={() => setActiveTab('available')}
            className={`flex-1 px-4 py-3 text-center font-medium transition-colors ${
              activeTab === 'available'
                ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            Доступные ({availableRequests.length})
          </button>
        </div>

        <div className="p-4">
          {activeTab === 'my' ? (
            <div className="space-y-4">
              {myRequests.map((request) => (
                <div key={request.id} className="border border-gray-200 rounded-lg p-4">
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex items-center space-x-2">
                      <span className="font-semibold text-gray-900">
                        {getTypeLabel(request.type)}
                      </span>
                      <div className={`flex items-center space-x-1 px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(request.status)}`}>
                        {getStatusIcon(request.status)}
                        <span>{getStatusLabel(request.status)}</span>
                      </div>
                    </div>
                    <span className="text-xs text-gray-500">
                      {new Date(request.createdAt).toLocaleDateString('ru-RU')}
                    </span>
                  </div>
                  
                  <div className="space-y-1 text-sm">
                    <p className="text-gray-600">
                      <span className="font-medium">Период:</span> {' '}
                      {new Date(request.startDate).toLocaleDateString('ru-RU')}
                      {request.startDate !== request.endDate && 
                        ` - ${new Date(request.endDate).toLocaleDateString('ru-RU')}`
                      }
                    </p>
                    {request.reason && (
                      <p className="text-gray-600">
                        <span className="font-medium">Причина:</span> {request.reason}
                      </p>
                    )}
                    {request.comment && (
                      <p className="text-gray-600">
                        <span className="font-medium">Комментарий:</span> {request.comment}
                      </p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="space-y-4">
              {availableRequests.map((request) => (
                <div key={request.id} className="border border-gray-200 rounded-lg p-4">
                  <div className="flex items-start justify-between mb-2">
                    <span className="font-semibold text-gray-900">
                      Обмен смены
                    </span>
                    <button className="px-3 py-1 bg-blue-600 text-white rounded-lg text-xs hover:bg-blue-700">
                      Откликнуться
                    </button>
                  </div>
                  
                  <div className="space-y-1 text-sm">
                    <p className="text-gray-600">
                      <span className="font-medium">Сотрудник:</span> {request.employee}
                    </p>
                    <p className="text-gray-600">
                      <span className="font-medium">Дата:</span> {new Date(request.date).toLocaleDateString('ru-RU')}
                    </p>
                    <p className="text-gray-600">
                      <span className="font-medium">Смена:</span> {request.shift}
                    </p>
                    <p className="text-gray-600">
                      <span className="font-medium">Причина:</span> {request.reason}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Create Request Modal - BDD: Type selection, date picker, comment field */}
      {showCreateForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-lg w-full max-w-md max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900">Новая заявка</h3>
                <button
                  onClick={() => setShowCreateForm(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <XCircle className="h-6 w-6" />
                </button>
              </div>

              <form className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Тип заявки
                  </label>
                  <select className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <option value="dayoff">Отгул</option>
                    <option value="vacation">Отпуск</option>
                    <option value="sick">Больничный</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Дата начала
                  </label>
                  <input
                    type="date"
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Дата окончания
                  </label>
                  <input
                    type="date"
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Комментарий
                  </label>
                  <textarea
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    rows={3}
                    placeholder="Укажите причину..."
                  />
                </div>

                <div className="flex space-x-3 pt-4">
                  <button
                    type="button"
                    onClick={() => setShowCreateForm(false)}
                    className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
                  >
                    Отмена
                  </button>
                  <button
                    type="submit"
                    className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                  >
                    Отправить
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default MobileRequests;