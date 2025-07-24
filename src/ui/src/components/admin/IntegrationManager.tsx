import React, { useState, useEffect, useCallback } from 'react';
import { 
  Globe, Webhook, Key, Activity, AlertTriangle, CheckCircle,
  Settings, RefreshCw, Plus, Edit3, Trash2, TestTube,
  Clock, Shield, Zap, Database, ExternalLink, Copy,
  Eye, EyeOff, RotateCcw, Pause, Play, MoreVertical,
  TrendingUp, TrendingDown, BarChart3, Users, Server
} from 'lucide-react';

interface WebhookEndpoint {
  id: string;
  name: string;
  url: string;
  events: string[];
  secret_key: string;
  active: boolean;
  created_at: string;
  last_delivery: string | null;
  delivery_success_rate: number;
  total_deliveries: number;
  failed_deliveries: number;
}

interface ExternalSystem {
  id: string;
  name: string;
  type: '1c_zup' | 'contact_center' | 'email_gateway' | 'mobile_push' | 'custom';
  status: 'connected' | 'disconnected' | 'error' | 'testing';
  health_check_url: string;
  last_health_check: string;
  response_time: number;
  error_rate: number;
  configuration: Record<string, any>;
}

interface ApiKey {
  id: string;
  name: string;
  key_prefix: string;
  permissions: string[];
  expires_at: string | null;
  created_at: string;
  last_used: string | null;
  usage_count: number;
  rate_limit: number;
  active: boolean;
}

interface IntegrationLog {
  id: string;
  type: 'webhook' | 'api_call' | 'health_check' | 'authentication';
  endpoint_name: string;
  status: 'success' | 'failure' | 'timeout' | 'rate_limited';
  response_time: number;
  timestamp: string;
  details: string;
  error_message?: string;
}

interface IntegrationManagerData {
  webhooks: WebhookEndpoint[];
  external_systems: ExternalSystem[];
  api_keys: ApiKey[];
  integration_logs: IntegrationLog[];
  statistics: {
    total_integrations: number;
    active_integrations: number;
    average_response_time: number;
    success_rate: number;
    daily_requests: number;
  };
  rate_limiting: {
    global_limit: number;
    per_endpoint_limit: number;
    current_usage: number;
    strategies: string[];
  };
}

const russianIntegrationTranslations = {
  title: 'Управление Интеграциями',
  subtitle: 'Системы интеграции API и управление вебхуками',
  sections: {
    overview: 'Обзор',
    webhooks: 'Вебхуки',
    systems: 'Внешние системы',
    api_keys: 'API ключи',
    logs: 'Журналы'
  },
  status: {
    connected: 'Подключено',
    disconnected: 'Отключено',
    error: 'Ошибка',
    testing: 'Тестирование',
    active: 'Активно',
    inactive: 'Неактивно'
  },
  systems: {
    '1c_zup': '1C ЗУП',
    'contact_center': 'Контакт-центр',
    'email_gateway': 'Email шлюз',
    'mobile_push': 'Push уведомления',
    'custom': 'Пользовательская'
  },
  webhook_events: {
    'employee.created': 'Сотрудник создан',
    'employee.updated': 'Сотрудник обновлен',
    'schedule.changed': 'Расписание изменено',
    'request.approved': 'Заявка одобрена',
    'request.rejected': 'Заявка отклонена'
  },
  actions: {
    create: 'Создать',
    edit: 'Редактировать',
    delete: 'Удалить',
    test: 'Тестировать',
    refresh: 'Обновить',
    activate: 'Активировать',
    deactivate: 'Деактивировать',
    regenerate: 'Перегенерировать',
    copy: 'Копировать',
    export: 'Экспорт'
  },
  metrics: {
    total_integrations: 'Всего интеграций',
    active_integrations: 'Активных интеграций',
    success_rate: 'Успешность',
    response_time: 'Время отклика',
    daily_requests: 'Запросов в день',
    delivery_rate: 'Доставляемость'
  },
  log_types: {
    webhook: 'Вебхук',
    api_call: 'API вызов',
    health_check: 'Проверка здоровья',
    authentication: 'Аутентификация'
  },
  log_status: {
    success: 'Успех',
    failure: 'Ошибка',
    timeout: 'Таймаут',
    rate_limited: 'Лимит превышен'
  }
};

import { realIntegrationManagerService } from '../../services/realIntegrationManagerService';

export const IntegrationManager: React.FC = () => {
  const [integrationData, setIntegrationData] = useState<IntegrationManagerData | null>(null);
  const [activeTab, setActiveTab] = useState<'overview' | 'webhooks' | 'systems' | 'api_keys' | 'logs'>('overview');
  const [selectedItem, setSelectedItem] = useState<string | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showSecrets, setShowSecrets] = useState<Record<string, boolean>>({});
  const [filterStatus, setFilterStatus] = useState<'all' | 'active' | 'error'>('all');
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    loadIntegrationData();
  }, []);

  const loadIntegrationData = async () => {
    if (integrationData) setRefreshing(true);   
    else setLoading(true);
    
    setError('');

    try {
      console.log('[REAL API] Loading integration dashboard data from INTEGRATION-OPUS');
      const response = await realIntegrationManagerService.getIntegrationDashboard();

      if (response.success && response.data) {
        setIntegrationData(response.data);
        console.log('✅ SPEC-11 integration management loaded from INTEGRATION-OPUS:', response.data);
        setError(''); // Clear any previous error
      } else {
        // Use comprehensive demo data as fallback
        console.log('⚠️ SPEC-11 integration APIs not available, using demo data');
        setIntegrationData(generateIntegrationDemo());
        setError('Демо данные - SPEC-11 integration APIs в разработке: ' + (response.error || 'Unknown error'));
      }
    } catch (err) {
      console.log('⚠️ Integration management API error, using demo data:', err);
      setIntegrationData(generateIntegrationDemo());
      setError('Сетевая ошибка - использование демо данных: ' + (err instanceof Error ? err.message : 'Unknown error'));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const generateIntegrationDemo = (): IntegrationManagerData => {
    const webhooks: WebhookEndpoint[] = [
      {
        id: 'webhook-1',
        name: '1C ЗУП Интеграция',
        url: 'https://1c.company.ru/wfm/webhooks',
        events: ['employee.created', 'employee.updated', 'schedule.changed'],
        secret_key: 'whsec_3f4a8b9c1d2e5f6g7h8i9j0k',
        active: true,
        created_at: '2025-07-15T10:30:00Z',
        last_delivery: '2025-07-20T14:25:00Z',
        delivery_success_rate: 98.7,
        total_deliveries: 1247,
        failed_deliveries: 16
      },
      {
        id: 'webhook-2',
        name: 'Система Уведомлений',
        url: 'https://notifications.company.ru/hooks/wfm',
        events: ['request.approved', 'request.rejected'],
        secret_key: 'whsec_9k8j7h6g5f4e3d2c1b0a',
        active: true,
        created_at: '2025-07-10T09:15:00Z',
        last_delivery: '2025-07-20T13:45:00Z',
        delivery_success_rate: 99.2,
        total_deliveries: 2156,
        failed_deliveries: 17
      },
      {
        id: 'webhook-3',
        name: 'HR Система',
        url: 'https://hr.company.ru/api/wfm-updates',
        events: ['employee.created', 'employee.updated'],
        secret_key: 'whsec_a1b2c3d4e5f6g7h8i9j0',
        active: false,
        created_at: '2025-07-05T16:20:00Z',
        last_delivery: '2025-07-18T11:30:00Z',
        delivery_success_rate: 94.3,
        total_deliveries: 892,
        failed_deliveries: 51
      }
    ];

    const externalSystems: ExternalSystem[] = [
      {
        id: 'system-1',
        name: '1C ЗУП',
        type: '1c_zup',
        status: 'connected',
        health_check_url: 'https://1c.company.ru/health',
        last_health_check: '2025-07-20T14:30:00Z',
        response_time: 245,
        error_rate: 0.8,
        configuration: {
          server_url: 'https://1c.company.ru',
          database: 'wfm_production',
          sync_interval: 3600,
          encoding: 'windows-1251'
        }
      },
      {
        id: 'system-2',
        name: 'Email Gateway',
        type: 'email_gateway',
        status: 'connected',
        health_check_url: 'https://mail.company.ru/api/health',
        last_health_check: '2025-07-20T14:29:00Z',
        response_time: 156,
        error_rate: 0.3,
        configuration: {
          smtp_server: 'mail.company.ru',
          port: 587,
          authentication: 'STARTTLS',
          max_recipients: 1000
        }
      },
      {
        id: 'system-3',
        name: 'Mobile Push Service',
        type: 'mobile_push',
        status: 'error',
        health_check_url: 'https://push.company.ru/health',
        last_health_check: '2025-07-20T14:15:00Z',
        response_time: 2340,
        error_rate: 15.2,
        configuration: {
          firebase_key: 'AIza***',
          apns_certificate: 'valid',
          batch_size: 100
        }
      }
    ];

    const apiKeys: ApiKey[] = [
      {
        id: 'key-1',
        name: '1C ЗУП API Key',
        key_prefix: 'wfm_1c_',
        permissions: ['read:employees', 'write:schedule', 'read:requests'],
        expires_at: '2025-12-31T23:59:59Z',
        created_at: '2025-07-01T10:00:00Z',
        last_used: '2025-07-20T14:20:00Z',
        usage_count: 15678,
        rate_limit: 1000,
        active: true
      },
      {
        id: 'key-2',
        name: 'Mobile App API Key',
        key_prefix: 'wfm_mobile_',
        permissions: ['read:schedule', 'write:requests', 'read:notifications'],
        expires_at: null,
        created_at: '2025-06-15T14:30:00Z',
        last_used: '2025-07-20T14:28:00Z',
        usage_count: 45230,
        rate_limit: 2000,
        active: true
      },
      {
        id: 'key-3',
        name: 'Analytics Service',
        key_prefix: 'wfm_analytics_',
        permissions: ['read:metrics', 'read:reports'],
        expires_at: '2025-09-30T23:59:59Z',
        created_at: '2025-05-20T12:15:00Z',
        last_used: '2025-07-19T23:45:00Z',
        usage_count: 8934,
        rate_limit: 500,
        active: false
      }
    ];

    const integrationLogs: IntegrationLog[] = [
      {
        id: 'log-1',
        type: 'webhook',
        endpoint_name: '1C ЗУП Интеграция',
        status: 'success',
        response_time: 245,
        timestamp: '2025-07-20T14:25:00Z',
        details: 'Employee update webhook delivered successfully'
      },
      {
        id: 'log-2',
        type: 'health_check',
        endpoint_name: 'Email Gateway',
        status: 'success',
        response_time: 156,
        timestamp: '2025-07-20T14:24:00Z',
        details: 'Health check passed'
      },
      {
        id: 'log-3',
        type: 'api_call',
        endpoint_name: 'Mobile Push Service',
        status: 'failure',
        response_time: 2340,
        timestamp: '2025-07-20T14:23:00Z',
        details: 'Push notification delivery failed',
        error_message: 'Connection timeout after 2s'
      },
      {
        id: 'log-4',
        type: 'webhook',
        endpoint_name: 'Система Уведомлений',
        status: 'success',
        response_time: 134,
        timestamp: '2025-07-20T14:22:00Z',
        details: 'Request approval webhook delivered'
      }
    ];

    return {
      webhooks,
      external_systems: externalSystems,
      api_keys: apiKeys,
      integration_logs: integrationLogs,
      statistics: {
        total_integrations: 8,
        active_integrations: 6,
        average_response_time: 278,
        success_rate: 96.8,
        daily_requests: 15430
      },
      rate_limiting: {
        global_limit: 10000,
        per_endpoint_limit: 1000,
        current_usage: 4567,
        strategies: ['fixed_window', 'sliding_window', 'token_bucket']
      }
    };
  };

  const testWebhook = async (webhookId: string) => {
    try {
      console.log('[REAL API] Testing webhook via INTEGRATION-OPUS:', webhookId);
      const response = await realIntegrationManagerService.testWebhook(webhookId);

      if (response.success) {
        console.log('✅ Webhook test successful via INTEGRATION-OPUS');
        await loadIntegrationData();
      } else {
        console.log('⚠️ Webhook test failed, error:', response.error);
      }
    } catch (error) {
      console.log('⚠️ Webhook test error:', error);
    }
  };

  const toggleWebhook = async (webhookId: string, active: boolean) => {
    try {
      console.log('[REAL API] Toggling webhook via INTEGRATION-OPUS:', webhookId, 'active:', active);
      const response = await realIntegrationManagerService.toggleWebhook(webhookId, active);

      if (response.success) {
        console.log('✅ Webhook status updated via INTEGRATION-OPUS');
        await loadIntegrationData();
      } else {
        console.log('⚠️ Webhook status update failed, error:', response.error);
        // Optimistic update for demo
        if (integrationData) {
          const updatedWebhooks = integrationData.webhooks.map(w =>
            w.id === webhookId ? { ...w, active } : w
          );
          setIntegrationData({ ...integrationData, webhooks: updatedWebhooks });
        }
      }
    } catch (error) {
      console.log('⚠️ Webhook status update error:', error);
    }
  };

  const checkSystemHealth = async (systemId: string) => {
    try {
      console.log('[REAL API] Checking system health via INTEGRATION-OPUS:', systemId);
      const response = await realIntegrationManagerService.checkSystemHealth(systemId);

      if (response.success) {
        console.log('✅ System health check successful via INTEGRATION-OPUS');
        await loadIntegrationData();
      } else {
        console.log('⚠️ System health check failed, error:', response.error);
      }
    } catch (error) {
      console.log('⚠️ System health check error:', error);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'connected':
      case 'active':
      case 'success': return 'text-green-600 bg-green-100 border-green-200';
      case 'testing':
      case 'timeout': return 'text-yellow-600 bg-yellow-100 border-yellow-200';
      case 'error':
      case 'failure':
      case 'disconnected': return 'text-red-600 bg-red-100 border-red-200';
      case 'rate_limited': return 'text-orange-600 bg-orange-100 border-orange-200';
      case 'inactive': return 'text-gray-600 bg-gray-100 border-gray-200';
      default: return 'text-gray-600 bg-gray-100 border-gray-200';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'connected':
      case 'active':
      case 'success': return <CheckCircle className="h-4 w-4 text-green-600" />;
      case 'error':
      case 'failure':
      case 'disconnected': return <AlertTriangle className="h-4 w-4 text-red-600" />;
      case 'testing': return <Clock className="h-4 w-4 text-yellow-600" />;
      default: return <Activity className="h-4 w-4 text-gray-600" />;
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  const renderOverview = () => {
    if (!integrationData) return null;

    return (
      <div className="space-y-6">
        {/* Statistics */}
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <div className="text-2xl font-bold text-blue-600">{integrationData.statistics.total_integrations}</div>
            <div className="text-sm text-gray-600">{russianIntegrationTranslations.metrics.total_integrations}</div>
          </div>
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <div className="text-2xl font-bold text-green-600">{integrationData.statistics.active_integrations}</div>
            <div className="text-sm text-gray-600">{russianIntegrationTranslations.metrics.active_integrations}</div>
          </div>
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <div className="text-2xl font-bold text-purple-600">{integrationData.statistics.success_rate}%</div>
            <div className="text-sm text-gray-600">{russianIntegrationTranslations.metrics.success_rate}</div>
          </div>
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <div className="text-2xl font-bold text-orange-600">{integrationData.statistics.average_response_time}ms</div>
            <div className="text-sm text-gray-600">{russianIntegrationTranslations.metrics.response_time}</div>
          </div>
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <div className="text-2xl font-bold text-teal-600">{integrationData.statistics.daily_requests.toLocaleString()}</div>
            <div className="text-sm text-gray-600">{russianIntegrationTranslations.metrics.daily_requests}</div>
          </div>
        </div>

        {/* Active Webhooks */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Активные вебхуки</h3>
          <div className="space-y-3">
            {integrationData.webhooks.filter(w => w.active).map((webhook) => (
              <div key={webhook.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center gap-3">
                  <Webhook className="h-5 w-5 text-blue-600" />
                  <div>
                    <div className="font-medium text-gray-900">{webhook.name}</div>
                    <div className="text-sm text-gray-600">{webhook.events.length} событий</div>
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <div className="text-right">
                    <div className="text-sm font-medium text-green-600">{webhook.delivery_success_rate}%</div>
                    <div className="text-xs text-gray-600">доставляемость</div>
                  </div>
                  <button
                    onClick={() => testWebhook(webhook.id)}
                    className="p-1 text-blue-600 hover:text-blue-800"
                  >
                    <TestTube className="h-4 w-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* External Systems Status */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Статус внешних систем</h3>
          <div className="space-y-3">
            {integrationData.external_systems.map((system) => (
              <div key={system.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center gap-3">
                  <Server className="h-5 w-5 text-gray-600" />
                  <div>
                    <div className="font-medium text-gray-900">{system.name}</div>
                    <div className="text-sm text-gray-600">{russianIntegrationTranslations.systems[system.type]}</div>
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <div className="text-right">
                    <div className="text-sm font-medium">{system.response_time}ms</div>
                    <div className="text-xs text-gray-600">время отклика</div>
                  </div>
                  <div className={`flex items-center gap-1 px-2 py-1 rounded text-xs border ${getStatusColor(system.status)}`}>
                    {getStatusIcon(system.status)}
                    <span>{russianIntegrationTranslations.status[system.status]}</span>
                  </div>
                  <button
                    onClick={() => checkSystemHealth(system.id)}
                    className="p-1 text-blue-600 hover:text-blue-800"
                  >
                    <Activity className="h-4 w-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  };

  const renderWebhooks = () => {
    if (!integrationData) return null;

    const filteredWebhooks = integrationData.webhooks.filter(webhook => {
      if (filterStatus === 'active') return webhook.active;
      if (filterStatus === 'error') return webhook.delivery_success_rate < 95;
      return true;
    });

    return (
      <div className="space-y-4">
        {/* Filter Controls */}
        <div className="flex justify-between items-center">
          <div className="flex gap-2">
            {(['all', 'active', 'error'] as const).map((filter) => (
              <button
                key={filter}
                onClick={() => setFilterStatus(filter)}
                className={`px-3 py-2 text-sm rounded-lg ${
                  filterStatus === filter
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {filter === 'all' ? 'Все' : 
                 filter === 'active' ? 'Активные' : 'С ошибками'}
              </button>
            ))}
          </div>
          
          <button
            onClick={() => setShowCreateModal(true)}
            className="flex items-center gap-2 px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            <Plus className="h-4 w-4" />
            {russianIntegrationTranslations.actions.create}
          </button>
        </div>

        {/* Webhooks List */}
        <div className="space-y-3">
          {filteredWebhooks.map((webhook) => (
            <div key={webhook.id} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-start gap-3">
                  <Webhook className="h-6 w-6 text-blue-600 mt-1" />
                  <div>
                    <h4 className="font-medium text-gray-900">{webhook.name}</h4>
                    <p className="text-sm text-gray-600 mt-1">{webhook.url}</p>
                    <div className="flex gap-2 mt-2">
                      {webhook.events.map((event) => (
                        <span key={event} className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded">
                          {russianIntegrationTranslations.webhook_events[event] || event}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center gap-2">
                  <div className={`flex items-center gap-1 px-2 py-1 rounded text-xs border ${getStatusColor(webhook.active ? 'active' : 'inactive')}`}>
                    {webhook.active ? <CheckCircle className="h-3 w-3" /> : <Pause className="h-3 w-3" />}
                    <span>{webhook.active ? 'Активен' : 'Неактивен'}</span>
                  </div>
                  
                  <button
                    onClick={() => toggleWebhook(webhook.id, !webhook.active)}
                    className="p-1 text-gray-600 hover:text-gray-800"
                  >
                    {webhook.active ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
                  </button>
                  
                  <button
                    onClick={() => testWebhook(webhook.id)}
                    className="p-1 text-blue-600 hover:text-blue-800"
                  >
                    <TestTube className="h-4 w-4" />
                  </button>
                </div>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4 text-sm">
                <div>
                  <div className="text-gray-600">Доставляемость</div>
                  <div className="font-medium text-green-600">{webhook.delivery_success_rate}%</div>
                </div>
                <div>
                  <div className="text-gray-600">Всего доставок</div>
                  <div className="font-medium">{webhook.total_deliveries.toLocaleString()}</div>
                </div>
                <div>
                  <div className="text-gray-600">Ошибок</div>
                  <div className="font-medium text-red-600">{webhook.failed_deliveries}</div>
                </div>
                <div>
                  <div className="text-gray-600">Последняя доставка</div>
                  <div className="font-medium">
                    {webhook.last_delivery ? new Date(webhook.last_delivery).toLocaleString('ru-RU') : 'Никогда'}
                  </div>
                </div>
              </div>
              
              {/* Secret Key */}
              <div className="mt-4 p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center justify-between">
                  <div>
                    <div className="text-sm font-medium text-gray-900">Секретный ключ</div>
                    <div className="text-sm text-gray-600 font-mono">
                      {showSecrets[webhook.id] ? webhook.secret_key : '•'.repeat(webhook.secret_key.length)}
                    </div>
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={() => setShowSecrets(prev => ({ ...prev, [webhook.id]: !prev[webhook.id] }))}
                      className="p-1 text-gray-600 hover:text-gray-800"
                    >
                      {showSecrets[webhook.id] ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                    <button
                      onClick={() => copyToClipboard(webhook.secret_key)}
                      className="p-1 text-gray-600 hover:text-gray-800"
                    >
                      <Copy className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  };

  const renderApiKeys = () => {
    if (!integrationData) return null;

    return (
      <div className="space-y-4">
        {/* Header */}
        <div className="flex justify-between items-center">
          <h3 className="text-lg font-semibold text-gray-900">API Ключи</h3>
          <button
            onClick={() => setShowCreateModal(true)}
            className="flex items-center gap-2 px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            <Plus className="h-4 w-4" />
            Создать ключ
          </button>
        </div>

        {/* API Keys List */}
        <div className="space-y-3">
          {integrationData.api_keys.map((apiKey) => (
            <div key={apiKey.id} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-start gap-3">
                  <Key className="h-6 w-6 text-purple-600 mt-1" />
                  <div>
                    <h4 className="font-medium text-gray-900">{apiKey.name}</h4>
                    <p className="text-sm text-gray-600 font-mono mt-1">{apiKey.key_prefix}••••••••••••••••</p>
                    <div className="flex gap-1 mt-2">
                      {apiKey.permissions.slice(0, 3).map((permission) => (
                        <span key={permission} className="text-xs bg-purple-100 text-purple-800 px-2 py-1 rounded">
                          {permission}
                        </span>
                      ))}
                      {apiKey.permissions.length > 3 && (
                        <span className="text-xs bg-gray-100 text-gray-800 px-2 py-1 rounded">
                          +{apiKey.permissions.length - 3}
                        </span>
                      )}
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center gap-2">
                  <div className={`flex items-center gap-1 px-2 py-1 rounded text-xs border ${getStatusColor(apiKey.active ? 'active' : 'inactive')}`}>
                    {apiKey.active ? <CheckCircle className="h-3 w-3" /> : <Pause className="h-3 w-3" />}
                    <span>{apiKey.active ? 'Активен' : 'Неактивен'}</span>
                  </div>
                  
                  <button className="p-1 text-blue-600 hover:text-blue-800">
                    <RotateCcw className="h-4 w-4" />
                  </button>
                </div>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4 text-sm">
                <div>
                  <div className="text-gray-600">Использований</div>
                  <div className="font-medium">{apiKey.usage_count.toLocaleString()}</div>
                </div>
                <div>
                  <div className="text-gray-600">Лимит запросов</div>
                  <div className="font-medium">{apiKey.rate_limit}/час</div>
                </div>
                <div>
                  <div className="text-gray-600">Истекает</div>
                  <div className="font-medium">
                    {apiKey.expires_at ? new Date(apiKey.expires_at).toLocaleDateString('ru-RU') : 'Никогда'}
                  </div>
                </div>
                <div>
                  <div className="text-gray-600">Последнее использование</div>
                  <div className="font-medium">
                    {apiKey.last_used ? new Date(apiKey.last_used).toLocaleString('ru-RU') : 'Никогда'}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  };

  const renderLogs = () => {
    if (!integrationData) return null;

    return (
      <div className="space-y-4">
        {/* Logs List */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="p-4 border-b border-gray-200">
            <h3 className="font-medium text-gray-900">Журнал интеграций</h3>
          </div>
          
          <div className="divide-y divide-gray-200">
            {integrationData.integration_logs.map((log) => (
              <div key={log.id} className="p-4 hover:bg-gray-50">
                <div className="flex items-start justify-between">
                  <div className="flex items-start gap-3">
                    <div className={`p-2 rounded-lg ${
                      log.status === 'success' ? 'bg-green-100' :
                      log.status === 'failure' ? 'bg-red-100' :
                      log.status === 'timeout' ? 'bg-yellow-100' :
                      'bg-orange-100'
                    }`}>
                      {log.type === 'webhook' ? <Webhook className="h-4 w-4" /> :
                       log.type === 'api_call' ? <Globe className="h-4 w-4" /> :
                       log.type === 'health_check' ? <Activity className="h-4 w-4" /> :
                       <Shield className="h-4 w-4" />}
                    </div>
                    
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <span className="font-medium text-gray-900">{log.endpoint_name}</span>
                        <span className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded">
                          {russianIntegrationTranslations.log_types[log.type]}
                        </span>
                        <span className={`text-xs px-2 py-1 rounded border ${getStatusColor(log.status)}`}>
                          {russianIntegrationTranslations.log_status[log.status]}
                        </span>
                      </div>
                      
                      <p className="text-sm text-gray-600 mt-1">{log.details}</p>
                      {log.error_message && (
                        <p className="text-sm text-red-600 mt-1">{log.error_message}</p>
                      )}
                      
                      <div className="flex items-center gap-4 mt-2 text-xs text-gray-500">
                        <span>{new Date(log.timestamp).toLocaleString('ru-RU')}</span>
                        <span>{log.response_time}ms</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-3"></div>
          <p className="text-gray-600">Загрузка управления интеграциями...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6" data-testid="integration-manager">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{russianIntegrationTranslations.title}</h1>
          <p className="text-gray-600">{russianIntegrationTranslations.subtitle}</p>
          {integrationData && (
            <div className="flex items-center gap-4 mt-1 text-sm text-gray-600">
              <span>{integrationData.statistics.active_integrations} активных из {integrationData.statistics.total_integrations}</span>
              <span>•</span>
              <span>{integrationData.statistics.success_rate}% успешность</span>
              <span>•</span>
              <span>{integrationData.statistics.daily_requests.toLocaleString()} запросов/день</span>
            </div>
          )}
        </div>
        
        <div className="flex items-center gap-3">
          <button
            onClick={loadIntegrationData}
            disabled={refreshing}
            className="flex items-center gap-2 px-3 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            <RefreshCw className={`h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
            {russianIntegrationTranslations.actions.refresh}
          </button>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
          <p className="text-yellow-800">{error}</p>
        </div>
      )}

      {/* Navigation Tabs */}
      <div className="border-b border-gray-200">
        <nav className="flex space-x-8">
          {(['overview', 'webhooks', 'systems', 'api_keys', 'logs'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === tab
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              {russianIntegrationTranslations.sections[tab]}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      {activeTab === 'overview' && renderOverview()}
      {activeTab === 'webhooks' && renderWebhooks()}
      {activeTab === 'systems' && renderOverview()} {/* Systems shown in overview */}
      {activeTab === 'api_keys' && renderApiKeys()}
      {activeTab === 'logs' && renderLogs()}
    </div>
  );
};

export default IntegrationManager;