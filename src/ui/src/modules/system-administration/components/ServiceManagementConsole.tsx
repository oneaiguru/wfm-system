import React, { useState, useEffect } from 'react';
import { 
  Container, 
  Server, 
  Play, 
  Square, 
  RotateCcw,
  CheckCircle, 
  AlertCircle, 
  Clock, 
  Settings, 
  Plus,
  Edit,
  Trash2,
  Activity,
  Eye
} from 'lucide-react';

// BDD: Service management console - Adapted from SystemConnectors
// Based on: 18-system-administration-configuration.feature

interface DockerService {
  id: string;
  name: string;
  image: string;
  status: 'running' | 'stopped' | 'restarting' | 'error';
  ports: string[];
  cpu: number;
  memory: number;
  restarts: number;
  created: string;
  uptime: string;
  description: string;
}

const ServiceManagementConsole: React.FC = () => {
  const [services, setServices] = useState<DockerService[]>([]);
  const [filter, setFilter] = useState<'all' | 'running' | 'stopped' | 'error'>('all');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    const mockServices: DockerService[] = [
      {
        id: 'srv_001',
        name: 'wfm-api-server',
        image: 'technoservice/wfm-api:latest',
        status: 'running',
        ports: ['8000:8000'],
        cpu: 12.4,
        memory: 256,
        restarts: 0,
        created: '2024-07-01T10:00:00Z',
        uptime: '14d 5h 23m',
        description: 'Основной API сервер для WFM системы'
      },
      {
        id: 'srv_002',
        name: 'wfm-database',
        image: 'postgres:15.4',
        status: 'running',
        ports: ['5432:5432'],
        cpu: 8.7,
        memory: 512,
        restarts: 1,
        created: '2024-07-01T10:00:00Z',
        uptime: '14d 5h 20m',
        description: 'PostgreSQL база данных для хранения данных WFM'
      },
      {
        id: 'srv_003',
        name: 'wfm-ui-server',
        image: 'nginx:alpine',
        status: 'running',
        ports: ['3000:80'],
        cpu: 2.1,
        memory: 64,
        restarts: 0,
        created: '2024-07-01T10:30:00Z',
        uptime: '14d 4h 53m',
        description: 'Nginx сервер для веб-интерфейса'
      },
      {
        id: 'srv_004',
        name: 'wfm-redis-cache',
        image: 'redis:7-alpine',
        status: 'running',
        ports: ['6379:6379'],
        cpu: 1.8,
        memory: 128,
        restarts: 0,
        created: '2024-07-01T10:15:00Z',
        uptime: '14d 5h 8m',
        description: 'Redis кэш для повышения производительности'
      },
      {
        id: 'srv_005',
        name: 'wfm-backup-service',
        image: 'technoservice/backup:v1.2',
        status: 'stopped',
        ports: [],
        cpu: 0,
        memory: 0,
        restarts: 3,
        created: '2024-07-01T11:00:00Z',
        uptime: '0d 0h 0m',
        description: 'Сервис автоматического резервного копирования'
      },
      {
        id: 'srv_006',
        name: 'wfm-monitoring',
        image: 'prom/prometheus:latest',
        status: 'error',
        ports: ['9090:9090'],
        cpu: 0,
        memory: 0,
        restarts: 15,
        created: '2024-07-10T14:00:00Z',
        uptime: '0d 0h 0m',
        description: 'Prometheus мониторинг системы'
      }
    ];

    setServices(mockServices);
  }, []);

  const filteredServices = services.filter(service => {
    const matchesFilter = filter === 'all' || service.status === filter;
    const matchesSearch = 
      service.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      service.image.toLowerCase().includes(searchTerm.toLowerCase()) ||
      service.description.toLowerCase().includes(searchTerm.toLowerCase());
    
    return matchesFilter && matchesSearch;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'running': return 'bg-green-100 text-green-800';
      case 'restarting': return 'bg-yellow-100 text-yellow-800';
      case 'error': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'running': return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'restarting': return <RotateCcw className="h-4 w-4 text-yellow-500 animate-spin" />;
      case 'error': return <AlertCircle className="h-4 w-4 text-red-500" />;
      default: return <Square className="h-4 w-4 text-gray-500" />;
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'running': return 'Работает';
      case 'stopped': return 'Остановлен';
      case 'restarting': return 'Перезапуск';
      case 'error': return 'Ошибка';
      default: return status;
    }
  };

  const handleServiceAction = (serviceId: string, action: 'start' | 'stop' | 'restart') => {
    setServices(prev => prev.map(service =>
      service.id === serviceId
        ? { 
            ...service, 
            status: action === 'start' ? 'running' : 
                   action === 'stop' ? 'stopped' : 'restarting' as const
          }
        : service
    ));

    // Simulate action completion after 2 seconds
    if (action === 'restart') {
      setTimeout(() => {
        setServices(prev => prev.map(service =>
          service.id === serviceId
            ? { ...service, status: 'running' as const, restarts: service.restarts + 1 }
            : service
        ));
      }, 2000);
    }
  };

  const stats = {
    total: services.length,
    running: services.filter(s => s.status === 'running').length,
    stopped: services.filter(s => s.status === 'stopped').length,
    error: services.filter(s => s.status === 'error').length,
    restarting: services.filter(s => s.status === 'restarting').length
  };

  const totalCpu = services.filter(s => s.status === 'running').reduce((sum, s) => sum + s.cpu, 0);
  const totalMemory = services.filter(s => s.status === 'running').reduce((sum, s) => sum + s.memory, 0);

  return (
    <div>
      {/* Header - BDD: Service management console */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Container className="h-6 w-6 mr-2 text-blue-600" />
          Консоль управления сервисами
        </h2>
        <p className="mt-2 text-gray-600">
          Docker контейнеры и сервисы системы ООО "ТехноСервис"
        </p>
      </div>

      {/* Summary Cards - BDD: Service health monitoring */}
      <div className="grid grid-cols-1 md:grid-cols-6 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Server className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Всего</h3>
              <p className="text-2xl font-bold text-blue-600">{stats.total}</p>
              <p className="text-sm text-gray-600">Сервисов</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <CheckCircle className="h-8 w-8 text-green-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Работает</h3>
              <p className="text-2xl font-bold text-green-600">{stats.running}</p>
              <p className="text-sm text-gray-600">Активных</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Square className="h-8 w-8 text-gray-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Остановлено</h3>
              <p className="text-2xl font-bold text-gray-600">{stats.stopped}</p>
              <p className="text-sm text-gray-600">Неактивных</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <AlertCircle className="h-8 w-8 text-red-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Ошибки</h3>
              <p className="text-2xl font-bold text-red-600">{stats.error}</p>
              <p className="text-sm text-gray-600">Проблемы</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Activity className="h-8 w-8 text-purple-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">CPU</h3>
              <p className="text-2xl font-bold text-purple-600">{totalCpu.toFixed(1)}%</p>
              <p className="text-sm text-gray-600">Использование</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Server className="h-8 w-8 text-orange-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">ОЗУ</h3>
              <p className="text-2xl font-bold text-orange-600">{totalMemory}</p>
              <p className="text-sm text-gray-600">МБ</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters and Search - BDD: Service filtering */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="relative">
              <input
                type="text"
                placeholder="Поиск сервисов..."
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
              <option value="all">Все сервисы</option>
              <option value="running">Работающие</option>
              <option value="stopped">Остановленные</option>
              <option value="error">С ошибками</option>
            </select>

            <span className="text-sm text-gray-600">
              {filteredServices.length} сервисов
            </span>
          </div>

          <button className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
            <Plus className="h-4 w-4 mr-2" />
            Добавить сервис
          </button>
        </div>
      </div>

      {/* Service List - BDD: Docker container management UI */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Сервисы системы</h3>
        </div>

        <div className="divide-y divide-gray-200">
          {filteredServices.map((service) => (
            <div key={service.id} className="p-6 hover:bg-gray-50">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-4">
                  <div className="flex-shrink-0">
                    <Container className="h-8 w-8 text-blue-600" />
                  </div>
                  
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center space-x-3 mb-2">
                      <h4 className="text-lg font-medium text-gray-900">
                        {service.name}
                      </h4>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(service.status)}`}>
                        {getStatusIcon(service.status)}
                        <span className="ml-1">{getStatusText(service.status)}</span>
                      </span>
                    </div>
                    
                    <p className="text-sm text-gray-600 mb-2">{service.description}</p>
                    
                    <div className="flex items-center space-x-4 text-sm text-gray-500 mb-2">
                      <span>Образ: {service.image}</span>
                      <span>Время работы: {service.uptime}</span>
                      <span>Перезапусков: {service.restarts}</span>
                    </div>

                    <div className="flex items-center space-x-4 text-sm text-gray-500">
                      <span>CPU: {service.cpu.toFixed(1)}%</span>
                      <span>ОЗУ: {service.memory}МБ</span>
                      {service.ports.length > 0 && (
                        <span>Порты: {service.ports.join(', ')}</span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="flex items-center space-x-2">
                  {service.status === 'stopped' && (
                    <button
                      onClick={() => handleServiceAction(service.id, 'start')}
                      className="p-2 text-green-600 hover:text-green-800 hover:bg-green-50 rounded-md"
                      title="Запустить"
                    >
                      <Play className="h-4 w-4" />
                    </button>
                  )}
                  
                  {service.status === 'running' && (
                    <>
                      <button
                        onClick={() => handleServiceAction(service.id, 'restart')}
                        className="p-2 text-yellow-600 hover:text-yellow-800 hover:bg-yellow-50 rounded-md"
                        title="Перезапустить"
                      >
                        <RotateCcw className="h-4 w-4" />
                      </button>
                      
                      <button
                        onClick={() => handleServiceAction(service.id, 'stop')}
                        className="p-2 text-red-600 hover:text-red-800 hover:bg-red-50 rounded-md"
                        title="Остановить"
                      >
                        <Square className="h-4 w-4" />
                      </button>
                    </>
                  )}
                  
                  <button className="p-2 text-gray-600 hover:text-gray-800 hover:bg-gray-50 rounded-md" title="Просмотр логов">
                    <Eye className="h-4 w-4" />
                  </button>
                  
                  <button className="p-2 text-gray-600 hover:text-gray-800 hover:bg-gray-50 rounded-md" title="Настройки">
                    <Settings className="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

        {filteredServices.length === 0 && (
          <div className="text-center py-12">
            <Container className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">Сервисы не найдены</h3>
            <p className="text-gray-600">Попробуйте изменить критерии поиска или добавить новый сервис.</p>
          </div>
        )}
      </div>

      {/* Quick Actions - BDD: Service management actions */}
      <div className="mt-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Быстрые действия</h3>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Запустить все</h4>
            <p className="text-sm text-gray-600 mt-1">Запустить все остановленные сервисы</p>
          </button>
          
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Обновить образы</h4>
            <p className="text-sm text-gray-600 mt-1">Обновить Docker образы до последних версий</p>
          </button>
          
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Экспорт конфигурации</h4>
            <p className="text-sm text-gray-600 mt-1">Скачать docker-compose.yml</p>
          </button>

          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Мониторинг ресурсов</h4>
            <p className="text-sm text-gray-600 mt-1">Подробная статистика использования</p>
          </button>
        </div>
      </div>
    </div>
  );
};

export default ServiceManagementConsole;