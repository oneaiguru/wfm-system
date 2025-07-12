// BDD: Vacancy Integration with Exchange System (Feature 27 - @vacancy_planning @integration @high)
import React, { useState, useEffect } from 'react';
import { ArrowRight, RefreshCw, CheckCircle, AlertCircle, Clock, Database, Users, Calendar } from 'lucide-react';
import type { ExchangeSystemTransfer } from '../types/vacancy';

export const VacancyIntegration: React.FC = () => {
  const [transfers, setTransfers] = useState<ExchangeSystemTransfer[]>([
    {
      dataType: 'StaffingGaps',
      transferStatus: 'completed',
      recordsTransferred: 25,
      lastSyncTime: new Date(Date.now() - 2 * 60 * 60 * 1000)
    },
    {
      dataType: 'SkillRequirements',
      transferStatus: 'completed',
      recordsTransferred: 18,
      lastSyncTime: new Date(Date.now() - 2 * 60 * 60 * 1000)
    },
    {
      dataType: 'ScheduleNeeds',
      transferStatus: 'pending',
      recordsTransferred: 0,
      lastSyncTime: new Date(Date.now() - 24 * 60 * 60 * 1000)
    },
    {
      dataType: 'PriorityLevels',
      transferStatus: 'pending',
      recordsTransferred: 0,
      lastSyncTime: new Date(Date.now() - 24 * 60 * 60 * 1000)
    }
  ]);

  const [personnelSyncStatus, setPersonnelSyncStatus] = useState({
    employeeCount: { status: 'synced', lastUpdate: new Date(), records: 850 },
    skillAssignments: { status: 'synced', lastUpdate: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000), records: 2100 },
    positionChanges: { status: 'syncing', lastUpdate: new Date(), records: 15 },
    availabilityStatus: { status: 'synced', lastUpdate: new Date(Date.now() - 60 * 60 * 1000), records: 850 }
  });

  const [isTransferring, setIsTransferring] = useState(false);
  const [syncErrors, setSyncErrors] = useState<string[]>([]);

  // BDD: Feed vacancy planning results to shift exchange system
  const pushToExchangeSystem = () => {
    setIsTransferring(true);
    setSyncErrors([]);
    
    // Simulate data transfer
    const pendingTransfers = transfers.filter(t => t.transferStatus === 'pending');
    
    pendingTransfers.forEach((transfer, index) => {
      setTimeout(() => {
        setTransfers(prev => prev.map(t => {
          if (t.dataType === transfer.dataType) {
            return {
              ...t,
              transferStatus: 'transferring',
              recordsTransferred: 0
            };
          }
          return t;
        }));
        
        // Simulate transfer completion
        setTimeout(() => {
          const success = Math.random() > 0.1; // 90% success rate
          
          setTransfers(prev => prev.map(t => {
            if (t.dataType === transfer.dataType) {
              if (success) {
                console.log(`[AUDIT] Successfully transferred ${transfer.dataType} to exchange system`);
                return {
                  ...t,
                  transferStatus: 'completed',
                  recordsTransferred: Math.floor(Math.random() * 30) + 10,
                  lastSyncTime: new Date()
                };
              } else {
                setSyncErrors(prev => [...prev, `Ошибка передачи ${transfer.dataType}`]);
                return {
                  ...t,
                  transferStatus: 'failed'
                };
              }
            }
            return t;
          }));
          
          if (index === pendingTransfers.length - 1) {
            setIsTransferring(false);
          }
        }, 2000);
      }, index * 1000);
    });
  };

  // BDD: Synchronize with personnel management system
  const syncPersonnelData = () => {
    console.log('[AUDIT] Initiating personnel data synchronization');
    
    Object.keys(personnelSyncStatus).forEach((key, index) => {
      setTimeout(() => {
        setPersonnelSyncStatus(prev => ({
          ...prev,
          [key]: {
            ...prev[key as keyof typeof prev],
            status: 'syncing'
          }
        }));
        
        setTimeout(() => {
          setPersonnelSyncStatus(prev => ({
            ...prev,
            [key]: {
              ...prev[key as keyof typeof prev],
              status: 'synced',
              lastUpdate: new Date(),
              records: prev[key as keyof typeof prev].records + Math.floor(Math.random() * 10)
            }
          }));
        }, 1500);
      }, index * 500);
    });
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
      case 'synced':
        return <CheckCircle className="h-5 w-5 text-green-500" />;
      case 'transferring':
      case 'syncing':
        return <RefreshCw className="h-5 w-5 text-blue-500 animate-spin" />;
      case 'failed':
        return <AlertCircle className="h-5 w-5 text-red-500" />;
      default:
        return <Clock className="h-5 w-5 text-gray-400" />;
    }
  };

  const getDataTypeInfo = (dataType: string) => {
    const info = {
      StaffingGaps: { 
        name: 'Кадровый дефицит', 
        description: 'Позиции, требующие покрытия',
        icon: Users 
      },
      SkillRequirements: { 
        name: 'Требования к навыкам', 
        description: 'Необходимые компетенции',
        icon: Database 
      },
      ScheduleNeeds: { 
        name: 'Потребности в графиках', 
        description: 'Конкретные временные периоды',
        icon: Calendar 
      },
      PriorityLevels: { 
        name: 'Уровни приоритета', 
        description: 'Индикаторы срочности',
        icon: AlertCircle 
      }
    };
    return info[dataType as keyof typeof info] || { name: dataType, description: '', icon: Database };
  };

  return (
    <div className="space-y-6">
      {/* Exchange System Integration */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-6 border-b">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-semibold">Интеграция с системой обмена сменами</h3>
              <p className="text-sm text-gray-600 mt-1">
                Передача результатов анализа вакансий для приоритизации обменов
              </p>
            </div>
            <button
              onClick={pushToExchangeSystem}
              disabled={isTransferring || transfers.every(t => t.transferStatus === 'completed')}
              className={`flex items-center gap-2 px-4 py-2 rounded-md ${
                isTransferring || transfers.every(t => t.transferStatus === 'completed')
                  ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                  : 'bg-blue-600 text-white hover:bg-blue-700'
              }`}
            >
              <ArrowRight className="h-4 w-4" />
              Передать в систему обмена
            </button>
          </div>
        </div>

        <div className="p-6">
          {/* BDD: Data transfer status */}
          <div className="space-y-4">
            {transfers.map((transfer, index) => {
              const typeInfo = getDataTypeInfo(transfer.dataType);
              return (
                <div key={index} className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex items-center gap-4">
                    <typeInfo.icon className="h-8 w-8 text-gray-400" />
                    <div>
                      <h4 className="font-medium">{typeInfo.name}</h4>
                      <p className="text-sm text-gray-600">{typeInfo.description}</p>
                      <p className="text-xs text-gray-500 mt-1">
                        Последняя синхронизация: {transfer.lastSyncTime.toLocaleString('ru-RU')}
                      </p>
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-4">
                    <div className="text-right">
                      <p className="text-sm font-medium">
                        {transfer.recordsTransferred > 0 ? `${transfer.recordsTransferred} записей` : 'Ожидание'}
                      </p>
                      <p className="text-xs text-gray-500">
                        {transfer.transferStatus === 'completed' ? 'Передано' :
                         transfer.transferStatus === 'transferring' ? 'Передается' :
                         transfer.transferStatus === 'failed' ? 'Ошибка' : 'Ожидание'}
                      </p>
                    </div>
                    {getStatusIcon(transfer.transferStatus)}
                  </div>
                </div>
              );
            })}
          </div>

          {/* Error messages */}
          {syncErrors.length > 0 && (
            <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
              <h4 className="font-medium text-red-800 mb-2">Ошибки синхронизации:</h4>
              <ul className="list-disc list-inside space-y-1">
                {syncErrors.map((error, index) => (
                  <li key={index} className="text-sm text-red-700">{error}</li>
                ))}
              </ul>
            </div>
          )}
        </div>
      </div>

      {/* Personnel System Synchronization */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-6 border-b">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-semibold">Синхронизация с системой управления персоналом</h3>
              <p className="text-sm text-gray-600 mt-1">
                Обновление данных о персонале для точного анализа
              </p>
            </div>
            <button
              onClick={syncPersonnelData}
              className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
            >
              <RefreshCw className="h-4 w-4" />
              Синхронизировать
            </button>
          </div>
        </div>

        <div className="p-6">
          {/* BDD: Personnel data sync status */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 border rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-medium">Количество сотрудников</h4>
                {getStatusIcon(personnelSyncStatus.employeeCount.status)}
              </div>
              <p className="text-2xl font-bold">{personnelSyncStatus.employeeCount.records}</p>
              <p className="text-sm text-gray-500">
                Ежедневная синхронизация
              </p>
              <p className="text-xs text-gray-400 mt-1">
                Обновлено: {personnelSyncStatus.employeeCount.lastUpdate.toLocaleTimeString('ru-RU')}
              </p>
            </div>

            <div className="p-4 border rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-medium">Назначения навыков</h4>
                {getStatusIcon(personnelSyncStatus.skillAssignments.status)}
              </div>
              <p className="text-2xl font-bold">{personnelSyncStatus.skillAssignments.records}</p>
              <p className="text-sm text-gray-500">
                Еженедельная синхронизация
              </p>
              <p className="text-xs text-gray-400 mt-1">
                Обновлено: {personnelSyncStatus.skillAssignments.lastUpdate.toLocaleDateString('ru-RU')}
              </p>
            </div>

            <div className="p-4 border rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-medium">Изменения должностей</h4>
                {getStatusIcon(personnelSyncStatus.positionChanges.status)}
              </div>
              <p className="text-2xl font-bold">{personnelSyncStatus.positionChanges.records}</p>
              <p className="text-sm text-gray-500">
                Синхронизация в реальном времени
              </p>
              <p className="text-xs text-gray-400 mt-1">
                Обновлено: {personnelSyncStatus.positionChanges.lastUpdate.toLocaleTimeString('ru-RU')}
              </p>
            </div>

            <div className="p-4 border rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-medium">Статус доступности</h4>
                {getStatusIcon(personnelSyncStatus.availabilityStatus.status)}
              </div>
              <p className="text-2xl font-bold">{personnelSyncStatus.availabilityStatus.records}</p>
              <p className="text-sm text-gray-500">
                Почасовая синхронизация
              </p>
              <p className="text-xs text-gray-400 mt-1">
                Обновлено: {personnelSyncStatus.availabilityStatus.lastUpdate.toLocaleTimeString('ru-RU')}
              </p>
            </div>
          </div>

          {/* Integration logs */}
          <div className="mt-6 border-t pt-6">
            <h4 className="font-medium mb-3">Журнал интеграции</h4>
            <div className="space-y-2 max-h-40 overflow-y-auto">
              <div className="flex items-center gap-2 text-sm">
                <CheckCircle className="h-4 w-4 text-green-500" />
                <span className="text-gray-600">14:32:15</span>
                <span>Успешная передача кадрового дефицита (25 записей)</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <CheckCircle className="h-4 w-4 text-green-500" />
                <span className="text-gray-600">14:32:10</span>
                <span>Успешная передача требований к навыкам (18 записей)</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <AlertCircle className="h-4 w-4 text-yellow-500" />
                <span className="text-gray-600">14:30:45</span>
                <span>Запущен анализ вакансий для отдела продаж</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <CheckCircle className="h-4 w-4 text-green-500" />
                <span className="text-gray-600">13:15:22</span>
                <span>Синхронизация данных о сотрудниках завершена</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};