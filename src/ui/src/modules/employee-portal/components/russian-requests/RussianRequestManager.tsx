/**
 * Russian Request Manager - SPEC-08 Integration
 * Manages Russian employee request workflows with enhanced API integration
 */

import React, { useState, useEffect } from 'react';
import { Plus, FileText, Calendar, Clock, AlertTriangle, RefreshCw } from 'lucide-react';
import RussianRequestForm from '../../../../components/RussianRequestForm';
import realRussianRequestService from '../../../../services/realRussianRequestService';

interface RussianRequest {
  id: string;
  type: 'больничный' | 'отгул' | 'отпуск' | 'внеочередной отпуск';
  startDate: string;
  endDate: string;
  reason: string;
  status: 'ожидает_подтверждения' | 'на_рассмотрении' | 'одобрено' | 'отклонено' | 'отменено';
  statusRu: string;
  createdAt: string;
  workingDaysCount?: number;
}

interface RussianRequestManagerProps {
  employeeId?: number;
  employeeName?: string;
}

const RussianRequestManager: React.FC<RussianRequestManagerProps> = ({
  employeeId = 1,
  employeeName = "Дмитрий Петров"
}) => {
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [selectedRequestType, setSelectedRequestType] = useState<'больничный' | 'отгул' | 'отпуск'>('отпуск');
  const [requests, setRequests] = useState<RussianRequest[]>([]);
  const [loading, setLoading] = useState(false);
  const [apiHealthy, setApiHealthy] = useState(false);

  // Russian translations
  const translations = {
    title: 'Российские Заявки',
    subtitle: 'Управление заявками сотрудников (больничный, отгул, отпуск)',
    newRequest: 'Новая заявка',
    myRequests: 'Мои заявки',
    requestTypes: {
      'больничный': 'Больничный лист',
      'отгул': 'Отгул',
      'отпуск': 'Отпуск',
      'внеочередной отпуск': 'Внеочередной отпуск'
    },
    status: {
      'ожидает_подтверждения': 'Ожидает подтверждения',
      'на_рассмотрении': 'На рассмотрении',
      'одобрено': 'Одобрено',
      'отклонено': 'Отклонено',
      'отменено': 'Отменено'
    },
    noRequests: 'Нет заявок',
    refresh: 'Обновить',
    apiStatus: 'Статус API'
  };

  // Demo data for when API is not available
  const demoRequests: RussianRequest[] = [
    {
      id: '1',
      type: 'отпуск',
      startDate: '2025-08-01',
      endDate: '2025-08-10',
      reason: 'Отдых с семьей',
      status: 'одобрено',
      statusRu: 'Одобрено',
      createdAt: '2025-07-20',
      workingDaysCount: 7
    },
    {
      id: '2',
      type: 'больничный',
      startDate: '2025-07-25',
      endDate: '2025-07-27',
      reason: 'ОРВИ, справка от врача №12345-АБ',
      status: 'ожидает_подтверждения',
      statusRu: 'Ожидает подтверждения',
      createdAt: '2025-07-21',
      workingDaysCount: 3
    }
  ];

  useEffect(() => {
    checkApiHealth();
    loadRequests();
  }, []);

  const checkApiHealth = async () => {
    try {
      const healthy = await realRussianRequestService.checkRussianApiHealth();
      setApiHealthy(healthy);
      console.log(`[RUSSIAN REQUEST MANAGER] API Health: ${healthy ? 'OK' : 'ERROR'}`);
    } catch (error) {
      console.error('[RUSSIAN REQUEST MANAGER] Health check failed:', error);
      setApiHealthy(false);
    }
  };

  const loadRequests = async () => {
    setLoading(true);
    try {
      if (apiHealthy) {
        console.log('[RUSSIAN REQUEST MANAGER] Loading requests from API...');
        const result = await realRussianRequestService.getMyRussianRequests();
        
        if (result.success && result.data) {
          setRequests(result.data.map(req => ({
            id: req.id || 'unknown',
            type: req.type,
            startDate: req.start_date,
            endDate: req.end_date,
            reason: req.reason,
            status: req.status || 'ожидает_подтверждения',
            statusRu: req.status || 'Ожидает подтверждения',
            createdAt: req.created_at || new Date().toISOString().split('T')[0],
            workingDaysCount: req.working_days_count
          })));
        } else {
          console.log('[RUSSIAN REQUEST MANAGER] API returned no data, using demo data');
          setRequests(demoRequests);
        }
      } else {
        console.log('[RUSSIAN REQUEST MANAGER] API unhealthy, using demo data');
        setRequests(demoRequests);
      }
    } catch (error) {
      console.error('[RUSSIAN REQUEST MANAGER] Load requests error:', error);
      setRequests(demoRequests);
    } finally {
      setLoading(false);
    }
  };

  const handleNewRequest = (type: 'больничный' | 'отгул' | 'отпуск') => {
    setSelectedRequestType(type);
    setIsFormOpen(true);
  };

  const handleRequestSubmit = async (requestData: any) => {
    console.log('[RUSSIAN REQUEST MANAGER] Request submitted:', requestData);
    
    // Add to demo list for immediate UI feedback
    const newRequest: RussianRequest = {
      id: Date.now().toString(),
      type: requestData.type,
      startDate: requestData.startDate,
      endDate: requestData.endDate,
      reason: requestData.reason,
      status: 'ожидает_подтверждения',
      statusRu: 'Ожидает подтверждения',
      createdAt: new Date().toISOString().split('T')[0],
      workingDaysCount: requestData.workingDaysCount
    };

    setRequests(prev => [newRequest, ...prev]);
    
    // Reload from API if available
    setTimeout(() => {
      loadRequests();
    }, 1000);
  };

  const getRequestTypeIcon = (type: string) => {
    switch (type) {
      case 'больничный': return <AlertTriangle className="h-5 w-5 text-red-600" />;
      case 'отгул': return <Clock className="h-5 w-5 text-blue-600" />;
      case 'отпуск': return <Calendar className="h-5 w-5 text-green-600" />;
      case 'внеочередной отпуск': return <AlertTriangle className="h-5 w-5 text-orange-600" />;
      default: return <FileText className="h-5 w-5 text-gray-600" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'одобрено': return 'bg-green-100 text-green-800';
      case 'отклонено': return 'bg-red-100 text-red-800';
      case 'на_рассмотрении': return 'bg-yellow-100 text-yellow-800';
      case 'ожидает_подтверждения': return 'bg-blue-100 text-blue-800';
      case 'отменено': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">{translations.title}</h2>
          <p className="text-gray-600">{translations.subtitle}</p>
          <div className="flex items-center gap-2 mt-1">
            <span className="text-sm text-gray-500">Сотрудник: {employeeName}</span>
            <span className={`text-xs px-2 py-1 rounded-full ${apiHealthy ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
              {translations.apiStatus}: {apiHealthy ? 'SPEC-08 API ✅' : 'Demo режим'}
            </span>
          </div>
        </div>
        <div className="flex gap-2">
          <button
            onClick={loadRequests}
            disabled={loading}
            className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50 flex items-center gap-2"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            {translations.refresh}
          </button>
        </div>
      </div>

      {/* Request Type Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        {Object.entries(translations.requestTypes).map(([key, label]) => (
          <button
            key={key}
            onClick={() => handleNewRequest(key as any)}
            className="p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-blue-400 hover:bg-blue-50 transition-colors text-left group"
          >
            <div className="flex items-center gap-3 mb-2">
              {getRequestTypeIcon(key)}
              <span className="font-medium text-gray-900 group-hover:text-blue-900">{label}</span>
            </div>
            <div className="flex items-center gap-1 text-sm text-gray-600 group-hover:text-blue-700">
              <Plus className="h-4 w-4" />
              Создать заявку
            </div>
          </button>
        ))}
      </div>

      {/* Requests List */}
      <div className="bg-white rounded-lg shadow">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">{translations.myRequests}</h3>
        </div>
        
        <div className="divide-y divide-gray-200">
          {loading ? (
            <div className="p-6 text-center">
              <RefreshCw className="h-6 w-6 animate-spin mx-auto mb-2 text-gray-400" />
              <p className="text-gray-600">Загрузка заявок...</p>
            </div>
          ) : requests.length === 0 ? (
            <div className="p-6 text-center">
              <FileText className="h-12 w-12 mx-auto mb-4 text-gray-400" />
              <p className="text-gray-600">{translations.noRequests}</p>
            </div>
          ) : (
            requests.map((request) => (
              <div key={request.id} className="p-6 hover:bg-gray-50">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    {getRequestTypeIcon(request.type)}
                    <div>
                      <h4 className="font-medium text-gray-900">
                        {translations.requestTypes[request.type]}
                      </h4>
                      <p className="text-sm text-gray-600">{request.reason}</p>
                      <div className="flex items-center gap-4 mt-1 text-xs text-gray-500">
                        <span>📅 {request.startDate} - {request.endDate}</span>
                        {request.workingDaysCount && (
                          <span>🗓️ {request.workingDaysCount} рабочих дней</span>
                        )}
                        <span>📤 Создано: {request.createdAt}</span>
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(request.status)}`}>
                      {translations.status[request.status] || request.statusRu}
                    </span>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Russian Request Form Modal */}
      <RussianRequestForm
        isOpen={isFormOpen}
        onClose={() => setIsFormOpen(false)}
        onSubmit={handleRequestSubmit}
        employeeId={employeeId}
        initialRequestType={selectedRequestType}
      />
    </div>
  );
};

export default RussianRequestManager;