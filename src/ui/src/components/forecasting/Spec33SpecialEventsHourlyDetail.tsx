import React, { useState, useEffect } from 'react';
import {
  Calendar,
  Clock,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  Users,
  Activity,
  BarChart3,
  Filter,
  ChevronLeft,
  ChevronRight,
  ZoomIn,
  ZoomOut,
  Maximize2,
  RefreshCw,
  Download,
  Info,
  Settings,
  CloudRain,
  Megaphone,
  Wrench,
  ShoppingCart,
  Building,
  MapPin,
  Eye,
  Grid,
  List,
  Plus,
  Minus
} from 'lucide-react';

// SPEC-33: Special Events (Detailed Hourly)
// Extends SpecialEventsForecastingDashboard with 85% reuse
// Adds hourly breakdown, 15-minute intervals, intraday planning
// Focus: Detailed hourly event impact analysis (30+ daily users)

interface Spec33HourlyEventData {
  eventId: string;
  eventName: string;
  eventType: 'city_holiday' | 'mass_event' | 'weather_event' | 'technical_event' | 'marketing_event';
  date: string;
  hourlyBreakdown: HourlyBreakdown[];
  peakHours: string[];
  totalImpact: number;
  affectedServiceGroups: string[];
  staffingRequirements: StaffingRequirement[];
  intradayAdjustments: IntradayAdjustment[];
}

interface HourlyBreakdown {
  hour: string; // "09:00"
  intervals: IntervalData[]; // 15-minute intervals
  baseVolume: number;
  eventImpact: number;
  adjustedVolume: number;
  staffingNeeded: number;
  currentStaffing: number;
  gap: number;
  serviceLevel: number;
  isPokeHour: boolean;
  alerts: string[];
}

interface IntervalData {
  time: string; // "09:00", "09:15", "09:30", "09:45"
  volume: number;
  impactPercentage: number;
  staffing: number;
  queueLength: number;
  avgWaitTime: number;
  abandonRate: number;
}

interface StaffingRequirement {
  hour: string;
  required: number;
  scheduled: number;
  gap: number;
  overtime: number;
  recommendations: string[];
}

interface IntradayAdjustment {
  id: string;
  time: string;
  type: 'break_move' | 'overtime' | 'shift_extend' | 'callback' | 'remote_support';
  agents: number;
  duration: number; // minutes
  status: 'proposed' | 'approved' | 'implemented';
  impact: number;
}

interface HourlyMetrics {
  avgServiceLevel: number;
  peakVolumeHour: string;
  peakVolumeValue: number;
  totalInteractions: number;
  staffingEfficiency: number;
  overtimeHours: number;
  criticalHours: string[];
}

// Russian translations for SPEC-33
const russianTranslations = {
  title: 'Детальный почасовой анализ событий',
  subtitle: 'Управление персоналом по часам и 15-минутным интервалам',
  views: {
    hourly: 'Почасовой',
    intervals: '15-минутные интервалы',
    staffing: 'Персонал',
    adjustments: 'Корректировки'
  },
  metrics: {
    serviceLevel: 'Уровень обслуживания',
    volume: 'Объём',
    staffing: 'Персонал',
    gap: 'Дефицит',
    queueLength: 'Длина очереди',
    waitTime: 'Время ожидания',
    abandonRate: 'Процент потерь'
  },
  adjustments: {
    break_move: 'Перенос перерыва',
    overtime: 'Сверхурочные',
    shift_extend: 'Продление смены',
    callback: 'Вызов сотрудников',
    remote_support: 'Удалённая поддержка'
  },
  actions: {
    apply: 'Применить',
    propose: 'Предложить',
    approve: 'Утвердить',
    reject: 'Отклонить',
    simulate: 'Симулировать'
  },
  alerts: {
    highVolume: 'Высокая нагрузка',
    lowStaffing: 'Недостаток персонала',
    longWait: 'Долгое ожидание',
    highAbandon: 'Высокий процент потерь'
  }
};

const Spec33SpecialEventsHourlyDetail: React.FC = () => {
  const [selectedEvent, setSelectedEvent] = useState<Spec33HourlyEventData | null>(null);
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [viewMode, setViewMode] = useState<'hourly' | 'intervals' | 'staffing' | 'adjustments'>('hourly');
  const [selectedHour, setSelectedHour] = useState<string | null>(null);
  const [zoomLevel, setZoomLevel] = useState<'normal' | 'detailed' | 'compressed'>('normal');
  const [showAdjustmentPanel, setShowAdjustmentPanel] = useState(false);
  const [proposedAdjustments, setProposedAdjustments] = useState<IntradayAdjustment[]>([]);
  const [metrics, setMetrics] = useState<HourlyMetrics | null>(null);

  // Generate mock hourly data
  useEffect(() => {
    generateMockEventData();
  }, [selectedDate]);

  const generateMockEventData = () => {
    const mockEvent: Spec33HourlyEventData = {
      eventId: 'evt_001',
      eventName: 'Новогодние праздники / New Year Celebration',
      eventType: 'city_holiday',
      date: selectedDate,
      hourlyBreakdown: generateHourlyBreakdown(),
      peakHours: ['10:00', '14:00', '15:00', '16:00'],
      totalImpact: 35.5,
      affectedServiceGroups: ['support', 'sales', 'billing'],
      staffingRequirements: generateStaffingRequirements(),
      intradayAdjustments: []
    };

    const mockMetrics: HourlyMetrics = {
      avgServiceLevel: 78.5,
      peakVolumeHour: '15:00',
      peakVolumeValue: 450,
      totalInteractions: 3850,
      staffingEfficiency: 82.3,
      overtimeHours: 12,
      criticalHours: ['10:00', '14:00', '15:00', '16:00']
    };

    setSelectedEvent(mockEvent);
    setMetrics(mockMetrics);
  };

  const generateHourlyBreakdown = (): HourlyBreakdown[] => {
    const hours = [];
    for (let h = 8; h < 20; h++) {
      const hour = `${h.toString().padStart(2, '0')}:00`;
      const isPeak = [10, 14, 15, 16].includes(h);
      const baseVolume = 150 + Math.random() * 100;
      const eventImpact = isPeak ? 30 + Math.random() * 20 : 10 + Math.random() * 10;
      const adjustedVolume = baseVolume * (1 + eventImpact / 100);

      hours.push({
        hour,
        intervals: generateIntervals(h, adjustedVolume),
        baseVolume: Math.round(baseVolume),
        eventImpact: Math.round(eventImpact),
        adjustedVolume: Math.round(adjustedVolume),
        staffingNeeded: Math.ceil(adjustedVolume / 15),
        currentStaffing: Math.ceil(baseVolume / 15) - (isPeak ? 2 : 0),
        gap: isPeak ? -2 - Math.floor(Math.random() * 3) : 0,
        serviceLevel: isPeak ? 65 + Math.random() * 10 : 80 + Math.random() * 10,
        isPeakHour: isPeak,
        alerts: isPeak ? ['lowStaffing', 'highVolume'] : []
      });
    }
    return hours;
  };

  const generateIntervals = (hour: number, hourlyVolume: number): IntervalData[] => {
    const intervals = [];
    const distribution = [0.22, 0.28, 0.30, 0.20]; // Typical intra-hour distribution

    for (let i = 0; i < 4; i++) {
      const time = `${hour.toString().padStart(2, '0')}:${(i * 15).toString().padStart(2, '0')}`;
      const volume = hourlyVolume * distribution[i];
      
      intervals.push({
        time,
        volume: Math.round(volume),
        impactPercentage: 15 + Math.random() * 20,
        staffing: Math.ceil(volume / 15),
        queueLength: Math.round(Math.random() * 10),
        avgWaitTime: Math.round(20 + Math.random() * 60),
        abandonRate: Math.random() * 5
      });
    }
    return intervals;
  };

  const generateStaffingRequirements = (): StaffingRequirement[] => {
    const requirements = [];
    for (let h = 8; h < 20; h++) {
      const hour = `${h.toString().padStart(2, '0')}:00`;
      const isPeak = [10, 14, 15, 16].includes(h);
      const required = 20 + (isPeak ? 8 : 0) + Math.floor(Math.random() * 5);
      const scheduled = required - (isPeak ? 3 : 0);
      
      requirements.push({
        hour,
        required,
        scheduled,
        gap: scheduled - required,
        overtime: isPeak ? 2 : 0,
        recommendations: isPeak ? ['Перенести перерывы', 'Добавить сверхурочные'] : []
      });
    }
    return requirements;
  };

  const getEventIcon = (type: string) => {
    const icons = {
      city_holiday: Calendar,
      mass_event: Megaphone,
      weather_event: CloudRain,
      technical_event: Wrench,
      marketing_event: ShoppingCart
    };
    return icons[type as keyof typeof icons] || Calendar;
  };

  const getImpactColor = (impact: number) => {
    if (impact > 30) return 'text-red-600 bg-red-100';
    if (impact > 15) return 'text-yellow-600 bg-yellow-100';
    return 'text-green-600 bg-green-100';
  };

  const getServiceLevelColor = (sl: number) => {
    if (sl >= 80) return 'text-green-600';
    if (sl >= 70) return 'text-yellow-600';
    return 'text-red-600';
  };

  const renderHourlyView = () => {
    if (!selectedEvent) return null;

    return (
      <div className="space-y-4">
        {/* Hourly Grid */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Час</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Базовый объём</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Влияние события</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Итоговый объём</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Требуется</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Запланировано</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Дефицит</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">SL%</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Действия</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {selectedEvent.hourlyBreakdown.map((hour) => (
                  <tr
                    key={hour.hour}
                    className={`hover:bg-gray-50 ${hour.isPeakHour ? 'bg-yellow-50' : ''}`}
                  >
                    <td className="px-4 py-3 text-sm font-medium text-gray-900">
                      {hour.hour}
                      {hour.isPeakHour && (
                        <span className="ml-2 text-xs text-yellow-600">PEAK</span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-600">{hour.baseVolume}</td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2 py-1 text-xs font-medium rounded-full ${getImpactColor(hour.eventImpact)}`}>
                        +{hour.eventImpact}%
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm font-medium text-gray-900">{hour.adjustedVolume}</td>
                    <td className="px-4 py-3 text-sm text-gray-900">{hour.staffingNeeded}</td>
                    <td className="px-4 py-3 text-sm text-gray-900">{hour.currentStaffing}</td>
                    <td className="px-4 py-3">
                      <span className={`text-sm font-medium ${hour.gap < 0 ? 'text-red-600' : 'text-green-600'}`}>
                        {hour.gap}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`text-sm font-medium ${getServiceLevelColor(hour.serviceLevel)}`}>
                        {hour.serviceLevel.toFixed(1)}%
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => setSelectedHour(hour.hour)}
                        className="text-blue-600 hover:text-blue-800 text-sm"
                      >
                        Детали
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Hourly Chart */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Почасовая нагрузка</h3>
          <div className="h-64 flex items-end justify-between gap-2">
            {selectedEvent.hourlyBreakdown.map((hour) => {
              const maxVolume = Math.max(...selectedEvent.hourlyBreakdown.map(h => h.adjustedVolume));
              const heightPercent = (hour.adjustedVolume / maxVolume) * 100;
              
              return (
                <div key={hour.hour} className="flex-1 flex flex-col items-center">
                  <div className="w-full flex flex-col items-center">
                    <span className="text-xs text-gray-600 mb-1">{hour.adjustedVolume}</span>
                    <div
                      className={`w-full rounded-t transition-all ${
                        hour.isPeakHour ? 'bg-red-500' : 'bg-blue-500'
                      }`}
                      style={{ height: `${heightPercent * 2}px` }}
                    />
                  </div>
                  <span className="text-xs text-gray-500 mt-2">{hour.hour.split(':')[0]}</span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    );
  };

  const renderIntervalsView = () => {
    if (!selectedEvent || !selectedHour) {
      return (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
          <Clock className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <p className="text-gray-600">Выберите час для просмотра 15-минутных интервалов</p>
        </div>
      );
    }

    const hourData = selectedEvent.hourlyBreakdown.find(h => h.hour === selectedHour);
    if (!hourData) return null;

    return (
      <div className="space-y-6">
        {/* Hour Header */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <button
                onClick={() => setSelectedHour(null)}
                className="p-2 hover:bg-gray-100 rounded-lg"
              >
                <ChevronLeft className="h-5 w-5" />
              </button>
              <h3 className="text-lg font-semibold text-gray-900">
                Интервалы для {selectedHour}
              </h3>
              {hourData.isPeakHour && (
                <span className="px-2 py-1 bg-yellow-100 text-yellow-700 text-xs font-medium rounded-full">
                  ПИК-ЧАС
                </span>
              )}
            </div>
            <div className="flex items-center gap-2">
              <span className="text-sm text-gray-600">
                Общий объём: <span className="font-medium text-gray-900">{hourData.adjustedVolume}</span>
              </span>
              <span className="text-sm text-gray-600">
                SL: <span className={`font-medium ${getServiceLevelColor(hourData.serviceLevel)}`}>
                  {hourData.serviceLevel.toFixed(1)}%
                </span>
              </span>
            </div>
          </div>
        </div>

        {/* 15-Minute Intervals */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {hourData.intervals.map((interval) => (
            <div key={interval.time} className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
              <div className="flex items-center justify-between mb-3">
                <span className="text-lg font-semibold text-gray-900">{interval.time}</span>
                <Clock className="h-5 w-5 text-gray-400" />
              </div>
              
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Объём:</span>
                  <span className="font-medium text-gray-900">{interval.volume}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Персонал:</span>
                  <span className="font-medium text-gray-900">{interval.staffing}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Очередь:</span>
                  <span className={`font-medium ${interval.queueLength > 5 ? 'text-red-600' : 'text-green-600'}`}>
                    {interval.queueLength}
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Ожидание:</span>
                  <span className={`font-medium ${interval.avgWaitTime > 60 ? 'text-red-600' : 'text-green-600'}`}>
                    {interval.avgWaitTime}с
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Потери:</span>
                  <span className={`font-medium ${interval.abandonRate > 3 ? 'text-red-600' : 'text-green-600'}`}>
                    {interval.abandonRate.toFixed(1)}%
                  </span>
                </div>
              </div>

              {(interval.queueLength > 5 || interval.avgWaitTime > 60) && (
                <div className="mt-3 pt-3 border-t border-gray-200">
                  <button className="w-full px-3 py-1 bg-red-600 text-white text-sm rounded hover:bg-red-700">
                    Требуется вмешательство
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Interval Chart */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h4 className="text-md font-semibold text-gray-900 mb-4">Распределение нагрузки по интервалам</h4>
          <div className="h-48 flex items-end justify-between gap-4">
            {hourData.intervals.map((interval) => {
              const maxVolume = Math.max(...hourData.intervals.map(i => i.volume));
              const heightPercent = (interval.volume / maxVolume) * 100;
              
              return (
                <div key={interval.time} className="flex-1 flex flex-col items-center">
                  <span className="text-sm font-medium text-gray-900 mb-2">{interval.volume}</span>
                  <div
                    className="w-full bg-blue-500 rounded-t"
                    style={{ height: `${heightPercent * 1.5}px` }}
                  />
                  <span className="text-xs text-gray-600 mt-2">{interval.time.split(':')[1]}'</span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    );
  };

  const renderStaffingView = () => {
    if (!selectedEvent) return null;

    return (
      <div className="space-y-6">
        {/* Staffing Requirements Table */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Требования к персоналу</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Час</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Требуется</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Запланировано</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Дефицит/Избыток</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Сверхурочные</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Рекомендации</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {selectedEvent.staffingRequirements.map((req) => (
                  <tr key={req.hour} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm font-medium text-gray-900">{req.hour}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{req.required}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{req.scheduled}</td>
                    <td className="px-6 py-4">
                      <span className={`text-sm font-medium ${req.gap < 0 ? 'text-red-600' : 'text-green-600'}`}>
                        {req.gap > 0 ? '+' : ''}{req.gap}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-900">{req.overtime || '-'}</td>
                    <td className="px-6 py-4">
                      {req.recommendations.length > 0 ? (
                        <div className="space-y-1">
                          {req.recommendations.map((rec, idx) => (
                            <span key={idx} className="block text-xs text-gray-600">{rec}</span>
                          ))}
                        </div>
                      ) : (
                        <span className="text-sm text-gray-500">-</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Staffing Visualization */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Визуализация персонала</h3>
          <div className="space-y-3">
            {selectedEvent.staffingRequirements.map((req) => (
              <div key={req.hour} className="flex items-center gap-4">
                <span className="text-sm font-medium text-gray-700 w-16">{req.hour}</span>
                <div className="flex-1 flex items-center gap-2">
                  <div className="flex-1 bg-gray-200 rounded-full h-6 relative overflow-hidden">
                    <div
                      className="absolute left-0 top-0 h-full bg-blue-500 rounded-full"
                      style={{ width: `${(req.scheduled / req.required) * 100}%` }}
                    />
                    {req.overtime > 0 && (
                      <div
                        className="absolute top-0 h-full bg-orange-500"
                        style={{
                          left: `${(req.scheduled / req.required) * 100}%`,
                          width: `${(req.overtime / req.required) * 100}%`
                        }}
                      />
                    )}
                  </div>
                  <span className="text-sm text-gray-600 w-20 text-right">
                    {req.scheduled}/{req.required}
                  </span>
                </div>
              </div>
            ))}
          </div>
          <div className="mt-4 flex items-center gap-6 text-sm">
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-blue-500 rounded"></div>
              <span className="text-gray-600">Запланировано</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-orange-500 rounded"></div>
              <span className="text-gray-600">Сверхурочные</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-gray-200 rounded"></div>
              <span className="text-gray-600">Дефицит</span>
            </div>
          </div>
        </div>
      </div>
    );
  };

  const renderAdjustmentsView = () => {
    return (
      <div className="space-y-6">
        {/* Proposed Adjustments */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
            <h3 className="text-lg font-semibold text-gray-900">Внутридневные корректировки</h3>
            <button
              onClick={() => setShowAdjustmentPanel(true)}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2"
            >
              <Plus className="h-4 w-4" />
              Предложить корректировку
            </button>
          </div>
          
          {proposedAdjustments.length > 0 ? (
            <div className="p-6 space-y-4">
              {proposedAdjustments.map((adj) => (
                <div key={adj.id} className="border border-gray-200 rounded-lg p-4">
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="flex items-center gap-3 mb-2">
                        <span className="text-sm font-medium text-gray-900">
                          {russianTranslations.adjustments[adj.type]}
                        </span>
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                          adj.status === 'implemented' ? 'bg-green-100 text-green-700' :
                          adj.status === 'approved' ? 'bg-blue-100 text-blue-700' :
                          'bg-gray-100 text-gray-700'
                        }`}>
                          {adj.status}
                        </span>
                      </div>
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                        <div>
                          <span className="text-gray-600">Время:</span>
                          <span className="ml-2 font-medium text-gray-900">{adj.time}</span>
                        </div>
                        <div>
                          <span className="text-gray-600">Агенты:</span>
                          <span className="ml-2 font-medium text-gray-900">{adj.agents}</span>
                        </div>
                        <div>
                          <span className="text-gray-600">Длительность:</span>
                          <span className="ml-2 font-medium text-gray-900">{adj.duration} мин</span>
                        </div>
                        <div>
                          <span className="text-gray-600">Эффект:</span>
                          <span className="ml-2 font-medium text-green-600">+{adj.impact}%</span>
                        </div>
                      </div>
                    </div>
                    {adj.status === 'proposed' && (
                      <div className="flex items-center gap-2">
                        <button className="px-3 py-1 bg-green-600 text-white text-sm rounded hover:bg-green-700">
                          Утвердить
                        </button>
                        <button className="px-3 py-1 border border-gray-300 text-gray-700 text-sm rounded hover:bg-gray-50">
                          Отклонить
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="p-8 text-center text-gray-500">
              <Settings className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <p>Нет предложенных корректировок</p>
            </div>
          )}
        </div>

        {/* Impact Simulation */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Симуляция воздействия</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center">
              <div className="text-3xl font-bold text-gray-900 mb-2">
                {metrics?.avgServiceLevel.toFixed(1)}%
              </div>
              <div className="text-sm text-gray-600">Текущий SL</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-green-600 mb-2">
                {(metrics?.avgServiceLevel || 0 + 5.2).toFixed(1)}%
              </div>
              <div className="text-sm text-gray-600">Прогноз SL</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-blue-600 mb-2">
                +5.2%
              </div>
              <div className="text-sm text-gray-600">Улучшение</div>
            </div>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b border-gray-200">
        <div className="px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Activity className="h-6 w-6 text-blue-600" />
              <h1 className="text-2xl font-bold text-gray-900">{russianTranslations.title}</h1>
              <span className="px-2 py-1 bg-blue-100 text-blue-700 text-xs font-medium rounded-full">
                SPEC-33
              </span>
            </div>
            <div className="flex items-center gap-3">
              <select
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="2025-07-21">21 июля 2025</option>
                <option value="2025-07-22">22 июля 2025</option>
                <option value="2025-07-23">23 июля 2025</option>
              </select>
              <button className="p-2 hover:bg-gray-100 rounded-lg">
                <RefreshCw className="h-5 w-5 text-gray-600" />
              </button>
              <button className="p-2 hover:bg-gray-100 rounded-lg">
                <Download className="h-5 w-5 text-gray-600" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Event Info Bar */}
      {selectedEvent && (
        <div className="bg-blue-50 border-b border-blue-200">
          <div className="px-6 py-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                {React.createElement(getEventIcon(selectedEvent.eventType), {
                  className: "h-5 w-5 text-blue-600"
                })}
                <div>
                  <span className="font-medium text-gray-900">{selectedEvent.eventName}</span>
                  <span className="ml-4 text-sm text-gray-600">
                    Общее влияние: <span className="font-medium">+{selectedEvent.totalImpact}%</span>
                  </span>
                </div>
              </div>
              <div className="flex items-center gap-6 text-sm">
                <div>
                  <span className="text-gray-600">Пиковые часы:</span>
                  <span className="ml-2 font-medium text-red-600">
                    {selectedEvent.peakHours.join(', ')}
                  </span>
                </div>
                <div>
                  <span className="text-gray-600">Группы услуг:</span>
                  <span className="ml-2 font-medium text-gray-900">
                    {selectedEvent.affectedServiceGroups.length}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* View Tabs */}
      <div className="bg-white border-b border-gray-200">
        <div className="px-6">
          <nav className="flex space-x-6">
            {Object.entries(russianTranslations.views).map(([key, label]) => (
              <button
                key={key}
                onClick={() => setViewMode(key as any)}
                className={`py-4 border-b-2 font-medium text-sm transition-colors ${
                  viewMode === key
                    ? 'border-blue-600 text-blue-600'
                    : 'border-transparent text-gray-600 hover:text-gray-900'
                }`}
              >
                {label}
              </button>
            ))}
          </nav>
        </div>
      </div>

      {/* Metrics Summary */}
      {metrics && (
        <div className="px-6 py-4">
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
              <div className="text-2xl font-bold text-gray-900">{metrics.avgServiceLevel.toFixed(1)}%</div>
              <div className="text-sm text-gray-600">Средний SL</div>
            </div>
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
              <div className="text-2xl font-bold text-gray-900">{metrics.totalInteractions}</div>
              <div className="text-sm text-gray-600">Всего взаимодействий</div>
            </div>
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
              <div className="text-2xl font-bold text-red-600">{metrics.peakVolumeValue}</div>
              <div className="text-sm text-gray-600">Пиковый объём</div>
            </div>
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
              <div className="text-2xl font-bold text-gray-900">{metrics.staffingEfficiency.toFixed(1)}%</div>
              <div className="text-sm text-gray-600">Эффективность</div>
            </div>
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
              <div className="text-2xl font-bold text-orange-600">{metrics.overtimeHours}ч</div>
              <div className="text-sm text-gray-600">Сверхурочные</div>
            </div>
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
              <div className="text-2xl font-bold text-red-600">{metrics.criticalHours.length}</div>
              <div className="text-sm text-gray-600">Критические часы</div>
            </div>
          </div>
        </div>
      )}

      {/* Content */}
      <div className="px-6 py-6">
        {viewMode === 'hourly' && renderHourlyView()}
        {viewMode === 'intervals' && renderIntervalsView()}
        {viewMode === 'staffing' && renderStaffingView()}
        {viewMode === 'adjustments' && renderAdjustmentsView()}
      </div>
    </div>
  );
};

export default Spec33SpecialEventsHourlyDetail;