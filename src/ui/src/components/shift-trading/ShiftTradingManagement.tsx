import React, { useState, useEffect } from 'react';
import { 
  ArrowLeftRight, Calendar, Clock, User, AlertCircle, 
  CheckCircle, XCircle, Filter, Search, RefreshCw,
  ChevronRight, MessageSquare, FileText, Shield,
  Smartphone, TrendingUp, BarChart3
} from 'lucide-react';

interface ShiftExchange {
  id: string;
  requester: {
    id: string;
    name: string;
    team: string;
    shift: string;
    date: string;
  };
  recipient: {
    id: string;
    name: string;
    team: string;
    shift: string;
    date: string;
  };
  status: 'pending' | 'approved' | 'rejected' | 'cancelled';
  createdAt: string;
  approvalStage: 'operational' | 'schedule' | 'manager' | 'complete';
  validations: {
    shiftCompatibility: boolean;
    employeeEligibility: boolean;
    scheduleImpact: boolean;
    laborCompliance: boolean;
  };
  comments: string[];
  escalationLevel: number;
}

interface TradingRules {
  maxExchangesPerMonth: number;
  advanceNoticeHours: number;
  requireManagerApproval: boolean;
  allowCrossTeamExchanges: boolean;
  blackoutDates: string[];
  maxConsecutiveShifts: number;
  minRestHours: number;
}

interface TradingMetrics {
  totalExchanges: number;
  approvedExchanges: number;
  rejectedExchanges: number;
  averageApprovalTime: number;
  complianceRate: number;
  popularExchangeTimes: { day: string; count: number }[];
}

// Russian translations for SPEC-14 compliance
const russianTranslations = {
  title: 'Управление обменом сменами',
  subtitle: 'Координация и утверждение обмена сменами между сотрудниками',
  tabs: {
    exchanges: 'Обмены',
    rules: 'Правила',
    metrics: 'Метрики',
    mobile: 'Мобильный'
  },
  status: {
    pending: 'Ожидает',
    approved: 'Одобрено',
    rejected: 'Отклонено',
    cancelled: 'Отменено'
  },
  approvalStage: {
    operational: 'Операционная проверка',
    schedule: 'Проверка расписания',
    manager: 'Утверждение менеджера',
    complete: 'Завершено'
  },
  validations: {
    shiftCompatibility: 'Совместимость смен',
    employeeEligibility: 'Право сотрудника',
    scheduleImpact: 'Влияние на расписание',
    laborCompliance: 'Соответствие ТК'
  },
  actions: {
    approve: 'Одобрить',
    reject: 'Отклонить',
    viewDetails: 'Подробности',
    addComment: 'Добавить комментарий',
    escalate: 'Эскалировать'
  },
  rules: {
    maxExchanges: 'Макс. обменов в месяц',
    advanceNotice: 'Предварительное уведомление (часы)',
    managerApproval: 'Требуется одобрение менеджера',
    crossTeam: 'Разрешить обмен между командами',
    blackoutDates: 'Запрещенные даты',
    maxConsecutive: 'Макс. последовательных смен',
    minRest: 'Мин. часов отдыха'
  },
  metrics: {
    total: 'Всего обменов',
    approved: 'Одобрено',
    rejected: 'Отклонено',
    avgTime: 'Среднее время одобрения',
    compliance: 'Уровень соответствия',
    popularDays: 'Популярные дни обмена'
  },
  mobile: {
    title: 'Мобильный обмен сменами',
    description: 'Управляйте обменом смен на ходу',
    features: {
      quick: 'Быстрый обмен',
      notifications: 'Push-уведомления',
      offline: 'Офлайн режим',
      camera: 'Сканирование расписания'
    }
  },
  escalation: {
    level1: 'Напоминание (24ч)',
    level2: 'Уведомление супервайзера (48ч)',
    level3: 'Автоназначение (72ч)',
    level4: 'Эскалация руководству (96ч)'
  }
};

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

export const ShiftTradingManagement: React.FC = () => {
  const [exchanges, setExchanges] = useState<ShiftExchange[]>([]);
  const [tradingRules, setTradingRules] = useState<TradingRules | null>(null);
  const [metrics, setMetrics] = useState<TradingMetrics | null>(null);
  const [activeTab, setActiveTab] = useState<'exchanges' | 'rules' | 'metrics' | 'mobile'>('exchanges');
  const [selectedExchange, setSelectedExchange] = useState<ShiftExchange | null>(null);
  const [filterStatus, setFilterStatus] = useState<'all' | 'pending' | 'approved' | 'rejected'>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [showApprovalDialog, setShowApprovalDialog] = useState(false);
  const [approvalComment, setApprovalComment] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    loadShiftTradingData();
  }, []);

  const loadShiftTradingData = async () => {
    setLoading(true);
    setError('');

    try {
      const authToken = localStorage.getItem('authToken');
      
      // Load exchanges
      const exchangesResponse = await fetch(`${API_BASE_URL}/shift-trading/exchanges`, {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      // Load rules
      const rulesResponse = await fetch(`${API_BASE_URL}/shift-trading/rules`, {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      // Load metrics
      const metricsResponse = await fetch(`${API_BASE_URL}/shift-trading/metrics`, {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (exchangesResponse.ok && rulesResponse.ok && metricsResponse.ok) {
        const exchangesData = await exchangesResponse.json();
        const rulesData = await rulesResponse.json();
        const metricsData = await metricsResponse.json();
        
        setExchanges(exchangesData.exchanges || []);
        setTradingRules(rulesData);
        setMetrics(metricsData);
        console.log('✅ SPEC-37 Shift trading data loaded');
      } else {
        // Use demo data as fallback
        console.log('⚠️ Shift trading APIs not available, using demo data');
        setExchanges(generateDemoExchanges());
        setTradingRules(generateDemoRules());
        setMetrics(generateDemoMetrics());
      }
    } catch (err) {
      console.log('⚠️ Shift trading API error, using demo data');
      setExchanges(generateDemoExchanges());
      setTradingRules(generateDemoRules());
      setMetrics(generateDemoMetrics());
      setError('Используются демонстрационные данные');
    } finally {
      setLoading(false);
    }
  };

  const generateDemoExchanges = (): ShiftExchange[] => [
    {
      id: 'ex-1',
      requester: {
        id: 'emp-1',
        name: 'Иванов И.И.',
        team: 'Команда А',
        shift: '09:00-18:00',
        date: '2025-07-25'
      },
      recipient: {
        id: 'emp-2',
        name: 'Петров П.П.',
        team: 'Команда А',
        shift: '14:00-23:00',
        date: '2025-07-26'
      },
      status: 'pending',
      createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
      approvalStage: 'operational',
      validations: {
        shiftCompatibility: true,
        employeeEligibility: true,
        scheduleImpact: false,
        laborCompliance: true
      },
      comments: ['Требуется проверка влияния на покрытие'],
      escalationLevel: 0
    },
    {
      id: 'ex-2',
      requester: {
        id: 'emp-3',
        name: 'Сидорова А.В.',
        team: 'Команда B',
        shift: '07:00-15:00',
        date: '2025-07-24'
      },
      recipient: {
        id: 'emp-4',
        name: 'Козлов К.К.',
        team: 'Команда B',
        shift: '07:00-15:00',
        date: '2025-07-27'
      },
      status: 'approved',
      createdAt: new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString(),
      approvalStage: 'complete',
      validations: {
        shiftCompatibility: true,
        employeeEligibility: true,
        scheduleImpact: true,
        laborCompliance: true
      },
      comments: ['Одобрено менеджером', 'Все проверки пройдены'],
      escalationLevel: 0
    },
    {
      id: 'ex-3',
      requester: {
        id: 'emp-5',
        name: 'Новиков Н.Н.',
        team: 'Команда C',
        shift: '22:00-07:00',
        date: '2025-07-28'
      },
      recipient: {
        id: 'emp-6',
        name: 'Морозов М.М.',
        team: 'Команда D',
        shift: '22:00-07:00',
        date: '2025-07-29'
      },
      status: 'pending',
      createdAt: new Date(Date.now() - 72 * 60 * 60 * 1000).toISOString(),
      approvalStage: 'schedule',
      validations: {
        shiftCompatibility: true,
        employeeEligibility: false,
        scheduleImpact: true,
        laborCompliance: true
      },
      comments: ['Требуется проверка навыков сотрудника'],
      escalationLevel: 2
    }
  ];

  const generateDemoRules = (): TradingRules => ({
    maxExchangesPerMonth: 3,
    advanceNoticeHours: 48,
    requireManagerApproval: true,
    allowCrossTeamExchanges: false,
    blackoutDates: ['2025-12-25', '2025-01-01', '2025-05-01'],
    maxConsecutiveShifts: 5,
    minRestHours: 11
  });

  const generateDemoMetrics = (): TradingMetrics => ({
    totalExchanges: 156,
    approvedExchanges: 142,
    rejectedExchanges: 14,
    averageApprovalTime: 18.5,
    complianceRate: 96.8,
    popularExchangeTimes: [
      { day: 'Пятница', count: 45 },
      { day: 'Суббота', count: 38 },
      { day: 'Воскресенье', count: 32 },
      { day: 'Понедельник', count: 20 },
      { day: 'Четверг', count: 15 }
    ]
  });

  const handleApprove = async (exchangeId: string) => {
    try {
      const authToken = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/shift-trading/exchanges/${exchangeId}/approve`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ comment: approvalComment })
      });

      if (response.ok) {
        console.log('✅ Exchange approved');
        await loadShiftTradingData();
        setShowApprovalDialog(false);
        setApprovalComment('');
      } else {
        // Demo mode - update local state
        setExchanges(exchanges.map(ex => 
          ex.id === exchangeId 
            ? { ...ex, status: 'approved', approvalStage: 'complete' } 
            : ex
        ));
        setShowApprovalDialog(false);
      }
    } catch (err) {
      console.log('⚠️ Approve exchange error, demo mode');
    }
  };

  const handleReject = async (exchangeId: string) => {
    try {
      const authToken = localStorage.getItem('authToken');
      const response = await fetch(`${API_BASE_URL}/shift-trading/exchanges/${exchangeId}/reject`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ comment: approvalComment })
      });

      if (response.ok) {
        console.log('✅ Exchange rejected');
        await loadShiftTradingData();
        setShowApprovalDialog(false);
        setApprovalComment('');
      } else {
        // Demo mode - update local state
        setExchanges(exchanges.map(ex => 
          ex.id === exchangeId 
            ? { ...ex, status: 'rejected' } 
            : ex
        ));
        setShowApprovalDialog(false);
      }
    } catch (err) {
      console.log('⚠️ Reject exchange error, demo mode');
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'approved': return 'bg-green-100 text-green-800 border-green-200';
      case 'rejected': return 'bg-red-100 text-red-800 border-red-200';
      case 'pending': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'cancelled': return 'bg-gray-100 text-gray-800 border-gray-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getValidationIcon = (valid: boolean) => {
    return valid 
      ? <CheckCircle className="h-4 w-4 text-green-600" />
      : <XCircle className="h-4 w-4 text-red-600" />;
  };

  const getEscalationBadge = (level: number) => {
    if (level === 0) return null;
    
    const colors = [
      'bg-blue-100 text-blue-800',
      'bg-yellow-100 text-yellow-800',
      'bg-orange-100 text-orange-800',
      'bg-red-100 text-red-800'
    ];

    return (
      <span className={`px-2 py-1 rounded text-xs font-medium ${colors[level - 1]}`}>
        {russianTranslations.escalation[`level${level}` as keyof typeof russianTranslations.escalation]}
      </span>
    );
  };

  const filteredExchanges = exchanges.filter(exchange => {
    if (filterStatus !== 'all' && exchange.status !== filterStatus) return false;
    
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      return exchange.requester.name.toLowerCase().includes(query) ||
             exchange.recipient.name.toLowerCase().includes(query) ||
             exchange.requester.team.toLowerCase().includes(query) ||
             exchange.recipient.team.toLowerCase().includes(query);
    }
    
    return true;
  });

  const renderExchangesList = () => (
    <div className="space-y-4">
      {/* Filters */}
      <div className="flex flex-col md:flex-row gap-4 mb-6">
        <div className="flex-1">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              type="text"
              placeholder="Поиск по сотрудникам или командам..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
        </div>
        
        <div className="flex gap-2">
          {(['all', 'pending', 'approved', 'rejected'] as const).map(status => (
            <button
              key={status}
              onClick={() => setFilterStatus(status)}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                filterStatus === status
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              {status === 'all' ? 'Все' : russianTranslations.status[status]}
            </button>
          ))}
        </div>
      </div>

      {/* Exchange List */}
      <div className="bg-white rounded-lg shadow divide-y divide-gray-200">
        {filteredExchanges.map(exchange => (
          <div
            key={exchange.id}
            className={`p-4 hover:bg-gray-50 cursor-pointer transition-colors ${
              selectedExchange?.id === exchange.id ? 'bg-blue-50' : ''
            }`}
            onClick={() => setSelectedExchange(exchange)}
          >
            <div className="flex items-center justify-between">
              <div className="flex-1">
                <div className="flex items-center gap-4 mb-2">
                  <div className="flex items-center gap-2">
                    <User className="h-4 w-4 text-gray-400" />
                    <span className="font-medium">{exchange.requester.name}</span>
                    <span className="text-gray-500">({exchange.requester.shift})</span>
                  </div>
                  <ArrowLeftRight className="h-4 w-4 text-blue-600" />
                  <div className="flex items-center gap-2">
                    <User className="h-4 w-4 text-gray-400" />
                    <span className="font-medium">{exchange.recipient.name}</span>
                    <span className="text-gray-500">({exchange.recipient.shift})</span>
                  </div>
                </div>
                
                <div className="flex items-center gap-4 text-sm text-gray-600">
                  <div className="flex items-center gap-1">
                    <Calendar className="h-3 w-3" />
                    {exchange.requester.date} → {exchange.recipient.date}
                  </div>
                  <div className="flex items-center gap-1">
                    <Clock className="h-3 w-3" />
                    {new Date(exchange.createdAt).toLocaleString('ru-RU')}
                  </div>
                </div>

                <div className="flex items-center gap-3 mt-2">
                  <span className={`px-2 py-1 rounded border text-xs font-medium ${getStatusColor(exchange.status)}`}>
                    {russianTranslations.status[exchange.status]}
                  </span>
                  {exchange.status === 'pending' && (
                    <span className="text-xs text-gray-500">
                      {russianTranslations.approvalStage[exchange.approvalStage]}
                    </span>
                  )}
                  {getEscalationBadge(exchange.escalationLevel)}
                </div>
              </div>
              
              <ChevronRight className="h-5 w-5 text-gray-400" />
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  const renderExchangeDetails = () => {
    if (!selectedExchange) {
      return (
        <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
          Выберите обмен для просмотра деталей
        </div>
      );
    }

    return (
      <div className="bg-white rounded-lg shadow">
        <div className="p-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Детали обмена</h3>
        </div>

        <div className="p-4 space-y-4">
          {/* Participants */}
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-gray-50 rounded-lg p-3">
              <div className="text-sm text-gray-600 mb-1">Инициатор</div>
              <div className="font-medium">{selectedExchange.requester.name}</div>
              <div className="text-sm text-gray-600">{selectedExchange.requester.team}</div>
              <div className="text-sm">{selectedExchange.requester.shift} • {selectedExchange.requester.date}</div>
            </div>
            <div className="bg-gray-50 rounded-lg p-3">
              <div className="text-sm text-gray-600 mb-1">Получатель</div>
              <div className="font-medium">{selectedExchange.recipient.name}</div>
              <div className="text-sm text-gray-600">{selectedExchange.recipient.team}</div>
              <div className="text-sm">{selectedExchange.recipient.shift} • {selectedExchange.recipient.date}</div>
            </div>
          </div>

          {/* Validations */}
          <div>
            <h4 className="font-medium text-gray-900 mb-2">Проверки</h4>
            <div className="space-y-2">
              {Object.entries(selectedExchange.validations).map(([key, value]) => (
                <div key={key} className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">
                    {russianTranslations.validations[key as keyof typeof russianTranslations.validations]}
                  </span>
                  {getValidationIcon(value)}
                </div>
              ))}
            </div>
          </div>

          {/* Comments */}
          <div>
            <h4 className="font-medium text-gray-900 mb-2">Комментарии</h4>
            <div className="space-y-2">
              {selectedExchange.comments.map((comment, index) => (
                <div key={index} className="bg-gray-50 rounded p-2 text-sm">
                  {comment}
                </div>
              ))}
            </div>
          </div>

          {/* Actions */}
          {selectedExchange.status === 'pending' && (
            <div className="pt-4 border-t border-gray-200">
              <div className="flex gap-3">
                <button
                  onClick={() => {
                    setShowApprovalDialog(true);
                  }}
                  className="flex-1 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium"
                >
                  {russianTranslations.actions.approve}
                </button>
                <button
                  onClick={() => {
                    setShowApprovalDialog(true);
                  }}
                  className="flex-1 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium"
                >
                  {russianTranslations.actions.reject}
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    );
  };

  const renderRulesConfig = () => {
    if (!tradingRules) return null;

    return (
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Правила обмена сменами</h3>
        
        <div className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                {russianTranslations.rules.maxExchanges}
              </label>
              <input
                type="number"
                value={tradingRules.maxExchangesPerMonth}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                readOnly
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                {russianTranslations.rules.advanceNotice}
              </label>
              <input
                type="number"
                value={tradingRules.advanceNoticeHours}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                readOnly
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                {russianTranslations.rules.maxConsecutive}
              </label>
              <input
                type="number"
                value={tradingRules.maxConsecutiveShifts}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                readOnly
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                {russianTranslations.rules.minRest}
              </label>
              <input
                type="number"
                value={tradingRules.minRestHours}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                readOnly
              />
            </div>
          </div>

          <div className="space-y-3">
            <label className="flex items-center gap-3">
              <input
                type="checkbox"
                checked={tradingRules.requireManagerApproval}
                className="h-4 w-4 text-blue-600"
                readOnly
              />
              <span className="text-sm text-gray-700">{russianTranslations.rules.managerApproval}</span>
            </label>
            
            <label className="flex items-center gap-3">
              <input
                type="checkbox"
                checked={tradingRules.allowCrossTeamExchanges}
                className="h-4 w-4 text-blue-600"
                readOnly
              />
              <span className="text-sm text-gray-700">{russianTranslations.rules.crossTeam}</span>
            </label>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              {russianTranslations.rules.blackoutDates}
            </label>
            <div className="space-y-1">
              {tradingRules.blackoutDates.map((date, index) => (
                <div key={index} className="bg-gray-50 rounded px-3 py-2 text-sm">
                  {new Date(date).toLocaleDateString('ru-RU')}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  };

  const renderMetrics = () => {
    if (!metrics) return null;

    return (
      <div className="space-y-6">
        {/* Metric Cards */}
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
          <div className="bg-white rounded-lg shadow p-4">
            <div className="text-2xl font-bold text-gray-900">{metrics.totalExchanges}</div>
            <div className="text-sm text-gray-600">{russianTranslations.metrics.total}</div>
          </div>
          <div className="bg-white rounded-lg shadow p-4">
            <div className="text-2xl font-bold text-green-600">{metrics.approvedExchanges}</div>
            <div className="text-sm text-gray-600">{russianTranslations.metrics.approved}</div>
          </div>
          <div className="bg-white rounded-lg shadow p-4">
            <div className="text-2xl font-bold text-red-600">{metrics.rejectedExchanges}</div>
            <div className="text-sm text-gray-600">{russianTranslations.metrics.rejected}</div>
          </div>
          <div className="bg-white rounded-lg shadow p-4">
            <div className="text-2xl font-bold text-blue-600">{metrics.averageApprovalTime}ч</div>
            <div className="text-sm text-gray-600">{russianTranslations.metrics.avgTime}</div>
          </div>
          <div className="bg-white rounded-lg shadow p-4">
            <div className="text-2xl font-bold text-purple-600">{metrics.complianceRate}%</div>
            <div className="text-sm text-gray-600">{russianTranslations.metrics.compliance}</div>
          </div>
        </div>

        {/* Popular Days Chart */}
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
            {russianTranslations.metrics.popularDays}
          </h3>
          <div className="space-y-3">
            {metrics.popularExchangeTimes.map((item, index) => (
              <div key={index} className="flex items-center">
                <span className="w-24 text-sm text-gray-600">{item.day}</span>
                <div className="flex-1 mx-4">
                  <div className="bg-gray-200 rounded-full h-6">
                    <div
                      className="bg-blue-600 h-6 rounded-full"
                      style={{ width: `${(item.count / metrics.popularExchangeTimes[0].count) * 100}%` }}
                    />
                  </div>
                </div>
                <span className="text-sm font-medium">{item.count}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  };

  const renderMobileInterface = () => (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="max-w-md mx-auto">
        <div className="text-center mb-6">
          <Smartphone className="h-16 w-16 text-blue-600 mx-auto mb-3" />
          <h3 className="text-lg font-semibold text-gray-900">{russianTranslations.mobile.title}</h3>
          <p className="text-gray-600">{russianTranslations.mobile.description}</p>
        </div>

        <div className="space-y-4">
          {Object.entries(russianTranslations.mobile.features).map(([key, label]) => (
            <div key={key} className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
              <CheckCircle className="h-5 w-5 text-green-600" />
              <span className="text-gray-700">{label}</span>
            </div>
          ))}
        </div>

        <div className="mt-6 p-4 bg-blue-50 rounded-lg">
          <div className="flex items-center gap-3">
            <div className="flex-shrink-0">
              <img
                src="/api/placeholder/150/300"
                alt="Mobile app"
                className="w-32 h-64 object-cover rounded-lg shadow"
              />
            </div>
            <div className="space-y-2">
              <button className="w-full py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                Скачать для iOS
              </button>
              <button className="w-full py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">
                Скачать для Android
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center h-96">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-3"></div>
          <p className="text-gray-600">Загрузка системы обмена сменами...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6" data-testid="shift-trading-management">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{russianTranslations.title}</h1>
          <p className="text-gray-600">{russianTranslations.subtitle}</p>
        </div>
        
        <button
          onClick={loadShiftTradingData}
          className="flex items-center gap-2 px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50"
        >
          <RefreshCw className="h-4 w-4" />
          Обновить
        </button>
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
          {(['exchanges', 'rules', 'metrics', 'mobile'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === tab
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              {russianTranslations.tabs[tab]}
            </button>
          ))}
        </nav>
      </div>

      {/* Content */}
      {activeTab === 'exchanges' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div>{renderExchangesList()}</div>
          <div>{renderExchangeDetails()}</div>
        </div>
      )}

      {activeTab === 'rules' && renderRulesConfig()}
      {activeTab === 'metrics' && renderMetrics()}
      {activeTab === 'mobile' && renderMobileInterface()}

      {/* Approval Dialog */}
      {showApprovalDialog && selectedExchange && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl w-96 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Утверждение обмена
            </h3>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Комментарий
              </label>
              <textarea
                value={approvalComment}
                onChange={(e) => setApprovalComment(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg resize-none"
                rows={3}
                placeholder="Добавьте комментарий..."
              />
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => handleApprove(selectedExchange.id)}
                className="flex-1 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium"
              >
                Одобрить
              </button>
              <button
                onClick={() => handleReject(selectedExchange.id)}
                className="flex-1 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium"
              >
                Отклонить
              </button>
              <button
                onClick={() => {
                  setShowApprovalDialog(false);
                  setApprovalComment('');
                }}
                className="px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                Отмена
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ShiftTradingManagement;