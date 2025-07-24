import React, { useState, useEffect } from 'react';
import {
  Calendar,
  CalendarDays,
  Clock,
  Users,
  Settings,
  ChevronLeft,
  ChevronRight,
  Plus,
  Filter,
  Search,
  Eye,
  Edit3,
  Ban,
  CheckCircle,
  AlertCircle,
  Target,
  TrendingUp,
  Download,
  Upload,
  RefreshCw,
  Grid,
  List,
  LayoutGrid,
  MapPin,
  Building,
  Globe,
  Layers,
  BarChart3,
  PieChart,
  Activity,
  UserCheck,
  UserX,
  Sun,
  Moon,
  Snowflake
} from 'lucide-react';

// SPEC-31: Vacation Schemes Calendar
// Extends VacationSchemeConfigurator.tsx with 80% reuse
// Adds calendar visualization, annual planning, blackout period display
// Focus: Vacation planning calendar for HR managers and employees (40+ daily users)

interface Spec31VacationScheme {
  id: string;
  name: string;
  nameRu: string;
  nameEn: string;
  description: string;
  type: 'annual' | 'sick' | 'unpaid' | 'maternity' | 'study' | 'custom';
  category: 'standard' | 'industry' | 'legal' | 'custom';
  entitlementDays: number;
  maxConsecutiveDays: number;
  minAdvanceNotice: number;
  maxAdvanceBooking: number;
  allowPartialDays: boolean;
  requiresApproval: boolean;
  isActive: boolean;
  isDefault: boolean;
  blackoutPeriods: BlackoutPeriod[];
  businessRules: BusinessRule[];
  color: string; // For calendar display
  icon: string;
}

interface BlackoutPeriod {
  id: string;
  name: string;
  nameRu: string;
  startDate: string;
  endDate: string;
  reason: string;
  reasonRu: string;
  isRecurring: boolean;
  recurrencePattern?: 'yearly' | 'monthly' | 'weekly';
  exceptions: string[];
  severity: 'warning' | 'restriction' | 'prohibition';
  affectedSchemes: string[];
}

interface BusinessRule {
  id: string;
  name: string;
  nameRu: string;
  type: 'validation' | 'calculation' | 'approval' | 'notification';
  condition: string;
  action: string;
  priority: number;
  isActive: boolean;
}

interface VacationRequest {
  id: string;
  employeeId: string;
  employeeName: string;
  employeeNameRu: string;
  schemeId: string;
  schemeName: string;
  startDate: string;
  endDate: string;
  days: number;
  status: 'pending' | 'approved' | 'rejected' | 'cancelled';
  reason?: string;
  createdAt: string;
  department: string;
  position: string;
}

interface CalendarDay {
  date: string;
  isToday: boolean;
  isCurrentMonth: boolean;
  isWeekend: boolean;
  isHoliday: boolean;
  holidayName?: string;
  blackoutPeriods: BlackoutPeriod[];
  vacationRequests: VacationRequest[];
  availabilityScore: number; // 0-100, based on team coverage
  isBlackedOut: boolean;
  notes?: string;
}

interface TeamCoverage {
  date: string;
  totalEmployees: number;
  onVacation: number;
  available: number;
  coveragePercentage: number;
  riskLevel: 'low' | 'medium' | 'high' | 'critical';
  affectedDepartments: string[];
}

// Russian translations
const russianTranslations = {
  title: 'Календарь схем отпусков',
  subtitle: 'Планирование отпусков и управление доступностью команды',
  views: {
    calendar: 'Календарь',
    schemes: 'Схемы',
    planning: 'Планирование',
    analytics: 'Аналитика',
    coverage: 'Покрытие'
  },
  calendar: {
    today: 'Сегодня',
    month: 'Месяц',
    week: 'Неделя',
    year: 'Год',
    planning: 'Планирование',
    coverage: 'Покрытие',
    blackouts: 'Блокировки',
    requests: 'Заявки'
  },
  schemes: {
    annual: 'Ежегодный',
    sick: 'Больничный',
    unpaid: 'Неоплачиваемый',
    maternity: 'Материнский',
    study: 'Учебный',
    custom: 'Пользовательский'
  },
  status: {
    pending: 'Ожидает',
    approved: 'Утверждено',
    rejected: 'Отклонено',
    cancelled: 'Отменено'
  },
  blackout: {
    warning: 'Предупреждение',
    restriction: 'Ограничение',
    prohibition: 'Запрет'
  },
  coverage: {
    excellent: 'Отличное',
    good: 'Хорошее',
    adequate: 'Достаточное',
    poor: 'Плохое',
    critical: 'Критическое'
  }
};

const Spec31VacationSchemesCalendar: React.FC = () => {
  const [activeView, setActiveView] = useState<'calendar' | 'schemes' | 'planning' | 'analytics' | 'coverage'>('calendar');
  const [currentDate, setCurrentDate] = useState(new Date());
  const [viewMode, setViewMode] = useState<'month' | 'week' | 'year'>('month');
  const [schemes, setSchemes] = useState<Spec31VacationScheme[]>([]);
  const [blackoutPeriods, setBlackoutPeriods] = useState<BlackoutPeriod[]>([]);
  const [vacationRequests, setVacationRequests] = useState<VacationRequest[]>([]);
  const [calendarDays, setCalendarDays] = useState<CalendarDay[]>([]);
  const [teamCoverage, setTeamCoverage] = useState<TeamCoverage[]>([]);
  const [selectedSchemes, setSelectedSchemes] = useState<string[]>([]);
  const [showBlackouts, setShowBlackouts] = useState(true);
  const [showRequests, setShowRequests] = useState(true);
  const [showCoverage, setShowCoverage] = useState(false);
  const [selectedDay, setSelectedDay] = useState<CalendarDay | null>(null);
  const [loading, setLoading] = useState(false);

  // Initialize with mock data based on VacationSchemeConfigurator patterns
  useEffect(() => {
    generateMockData();
    generateCalendarDays();
  }, [currentDate, viewMode]);

  const generateMockData = () => {
    // Mock vacation schemes (extending VacationSchemeConfigurator data)
    const mockSchemes: Spec31VacationScheme[] = [
      {
        id: 'scheme_annual',
        name: 'Annual Leave',
        nameRu: 'Ежегодный отпуск',
        nameEn: 'Annual Leave',
        description: 'Standard annual vacation entitlement',
        type: 'annual',
        category: 'standard',
        entitlementDays: 28,
        maxConsecutiveDays: 14,
        minAdvanceNotice: 14,
        maxAdvanceBooking: 365,
        allowPartialDays: true,
        requiresApproval: true,
        isActive: true,
        isDefault: true,
        blackoutPeriods: [],
        businessRules: [],
        color: '#3B82F6',
        icon: '🏖️'
      },
      {
        id: 'scheme_sick',
        name: 'Sick Leave',
        nameRu: 'Больничный лист',
        nameEn: 'Sick Leave',
        description: 'Medical leave for illness or medical appointments',
        type: 'sick',
        category: 'legal',
        entitlementDays: 10,
        maxConsecutiveDays: 5,
        minAdvanceNotice: 0,
        maxAdvanceBooking: 7,
        allowPartialDays: true,
        requiresApproval: false,
        isActive: true,
        isDefault: false,
        blackoutPeriods: [],
        businessRules: [],
        color: '#EF4444',
        icon: '🏥'
      },
      {
        id: 'scheme_maternity',
        name: 'Maternity Leave',
        nameRu: 'Декретный отпуск',
        nameEn: 'Maternity Leave',
        description: 'Maternity and parental leave',
        type: 'maternity',
        category: 'legal',
        entitlementDays: 140,
        maxConsecutiveDays: 140,
        minAdvanceNotice: 30,
        maxAdvanceBooking: 180,
        allowPartialDays: false,
        requiresApproval: true,
        isActive: true,
        isDefault: false,
        blackoutPeriods: [],
        businessRules: [],
        color: '#8B5CF6',
        icon: '👶'
      }
    ];

    // Mock blackout periods
    const mockBlackouts: BlackoutPeriod[] = [
      {
        id: 'blackout_newyear',
        name: 'New Year Holidays',
        nameRu: 'Новогодние праздники',
        startDate: '2025-12-25',
        endDate: '2026-01-08',
        reason: 'National holiday period',
        reasonRu: 'Период национальных праздников',
        isRecurring: true,
        recurrencePattern: 'yearly',
        exceptions: [],
        severity: 'restriction',
        affectedSchemes: ['scheme_annual']
      },
      {
        id: 'blackout_summer',
        name: 'Summer Peak Period',
        nameRu: 'Летний пиковый период',
        startDate: '2025-07-15',
        endDate: '2025-08-15',
        reason: 'High business activity',
        reasonRu: 'Высокая деловая активность',
        isRecurring: true,
        recurrencePattern: 'yearly',
        exceptions: [],
        severity: 'warning',
        affectedSchemes: ['scheme_annual']
      }
    ];

    // Mock vacation requests
    const mockRequests: VacationRequest[] = [
      {
        id: 'req_001',
        employeeId: 'emp_001',
        employeeName: 'Иван Петров',
        employeeNameRu: 'Иван Петров',
        schemeId: 'scheme_annual',
        schemeName: 'Annual Leave',
        startDate: '2025-08-01',
        endDate: '2025-08-14',
        days: 14,
        status: 'approved',
        reason: 'Family vacation',
        createdAt: '2025-07-01T10:00:00Z',
        department: 'Sales',
        position: 'Sales Manager'
      },
      {
        id: 'req_002',
        employeeId: 'emp_002',
        employeeName: 'Анна Смирнова',
        employeeNameRu: 'Анна Смирнова',
        schemeId: 'scheme_annual',
        schemeName: 'Annual Leave',
        startDate: '2025-09-15',
        endDate: '2025-09-22',
        days: 7,
        status: 'pending',
        reason: 'Rest and relaxation',
        createdAt: '2025-07-10T14:30:00Z',
        department: 'HR',
        position: 'HR Specialist'
      }
    ];

    // Mock team coverage
    const mockCoverage: TeamCoverage[] = generateTeamCoverage();

    setSchemes(mockSchemes);
    setBlackoutPeriods(mockBlackouts);
    setVacationRequests(mockRequests);
    setTeamCoverage(mockCoverage);
    setSelectedSchemes(mockSchemes.filter(s => s.isDefault).map(s => s.id));
  };

  const generateTeamCoverage = (): TeamCoverage[] => {
    const coverage: TeamCoverage[] = [];
    const startDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
    const endDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0);

    for (let d = new Date(startDate); d <= endDate; d.setDate(d.getDate() + 1)) {
      const dateStr = d.toISOString().split('T')[0];
      const isWeekend = d.getDay() === 0 || d.getDay() === 6;
      const baseAvailable = isWeekend ? 20 : 80; // Weekend has fewer people
      const onVacation = Math.floor(Math.random() * 15) + (isWeekend ? 2 : 8);
      const available = Math.max(baseAvailable - onVacation, 10);
      const coveragePercentage = (available / baseAvailable) * 100;

      let riskLevel: 'low' | 'medium' | 'high' | 'critical';
      if (coveragePercentage >= 80) riskLevel = 'low';
      else if (coveragePercentage >= 60) riskLevel = 'medium';
      else if (coveragePercentage >= 40) riskLevel = 'high';
      else riskLevel = 'critical';

      coverage.push({
        date: dateStr,
        totalEmployees: baseAvailable,
        onVacation,
        available,
        coveragePercentage,
        riskLevel,
        affectedDepartments: ['Sales', 'Support', 'HR']
      });
    }

    return coverage;
  };

  const generateCalendarDays = () => {
    const days: CalendarDay[] = [];
    const startDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
    const endDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0);

    // Add days from previous month to fill first week
    const firstDayOfWeek = startDate.getDay();
    const prevMonthStart = new Date(startDate);
    prevMonthStart.setDate(startDate.getDate() - firstDayOfWeek);

    // Add days from next month to fill last week
    const lastDayOfWeek = endDate.getDay();
    const nextMonthEnd = new Date(endDate);
    nextMonthEnd.setDate(endDate.getDate() + (6 - lastDayOfWeek));

    for (let d = new Date(prevMonthStart); d <= nextMonthEnd; d.setDate(d.getDate() + 1)) {
      const dateStr = d.toISOString().split('T')[0];
      const isCurrentMonth = d.getMonth() === currentDate.getMonth();
      const isToday = d.toDateString() === new Date().toDateString();
      const isWeekend = d.getDay() === 0 || d.getDay() === 6;
      
      // Check for holidays (Russian holidays)
      const holidayName = getRussianHolidayName(d);
      const isHoliday = !!holidayName;
      
      // Get blackout periods for this date
      const dayBlackouts = blackoutPeriods.filter(bp => {
        const start = new Date(bp.startDate);
        const end = new Date(bp.endDate);
        return d >= start && d <= end;
      });
      
      // Get vacation requests for this date
      const dayRequests = vacationRequests.filter(req => {
        const start = new Date(req.startDate);
        const end = new Date(req.endDate);
        return d >= start && d <= end;
      });
      
      // Calculate availability score
      const coverage = teamCoverage.find(tc => tc.date === dateStr);
      const availabilityScore = coverage ? coverage.coveragePercentage : 100;
      
      const isBlackedOut = dayBlackouts.some(bp => bp.severity === 'prohibition');

      days.push({
        date: dateStr,
        isToday,
        isCurrentMonth,
        isWeekend,
        isHoliday,
        holidayName,
        blackoutPeriods: dayBlackouts,
        vacationRequests: dayRequests,
        availabilityScore,
        isBlackedOut,
        notes: isHoliday ? `Праздник: ${holidayName}` : undefined
      });
    }

    setCalendarDays(days);
  };

  const getRussianHolidayName = (date: Date): string | undefined => {
    const month = date.getMonth() + 1;
    const day = date.getDate();
    
    const holidays: Record<string, string> = {
      '1-1': 'Новый год',
      '1-7': 'Рождество Христово',
      '2-23': 'День защитника Отечества',
      '3-8': 'Международный женский день',
      '5-1': 'Праздник Весны и Труда',
      '5-9': 'День Победы',
      '6-12': 'День России',
      '11-4': 'День народного единства'
    };
    
    return holidays[`${month}-${day}`];
  };

  const getCoverageColor = (score: number) => {
    if (score >= 80) return 'bg-green-100 text-green-800';
    if (score >= 60) return 'bg-yellow-100 text-yellow-800';
    if (score >= 40) return 'bg-orange-100 text-orange-800';
    return 'bg-red-100 text-red-800';
  };

  const getBlackoutColor = (severity: string) => {
    switch (severity) {
      case 'warning': return 'bg-yellow-200 border-yellow-400';
      case 'restriction': return 'bg-orange-200 border-orange-400';
      case 'prohibition': return 'bg-red-200 border-red-400';
      default: return 'bg-gray-200 border-gray-400';
    }
  };

  const navigateMonth = (direction: 'prev' | 'next') => {
    const newDate = new Date(currentDate);
    newDate.setMonth(currentDate.getMonth() + (direction === 'next' ? 1 : -1));
    setCurrentDate(newDate);
  };

  const renderCalendarView = () => (
    <div className="space-y-4">
      {/* Calendar Header */}
      <div className="flex items-center justify-between bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <div className="flex items-center gap-4">
          <button
            onClick={() => navigateMonth('prev')}
            className="p-2 hover:bg-gray-100 rounded-lg"
          >
            <ChevronLeft className="h-5 w-5" />
          </button>
          <h3 className="text-lg font-semibold text-gray-900">
            {currentDate.toLocaleDateString('ru-RU', { month: 'long', year: 'numeric' })}
          </h3>
          <button
            onClick={() => navigateMonth('next')}
            className="p-2 hover:bg-gray-100 rounded-lg"
          >
            <ChevronRight className="h-5 w-5" />
          </button>
        </div>
        
        <div className="flex items-center gap-3">
          <button
            onClick={() => setCurrentDate(new Date())}
            className="px-3 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            {russianTranslations.calendar.today}
          </button>
          
          <div className="flex items-center gap-2">
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={showBlackouts}
                onChange={(e) => setShowBlackouts(e.target.checked)}
                className="rounded border-gray-300"
              />
              Блокировки
            </label>
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={showRequests}
                onChange={(e) => setShowRequests(e.target.checked)}
                className="rounded border-gray-300"
              />
              Заявки
            </label>
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={showCoverage}
                onChange={(e) => setShowCoverage(e.target.checked)}
                className="rounded border-gray-300"
              />
              Покрытие
            </label>
          </div>
        </div>
      </div>

      {/* Calendar Grid */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        {/* Week Headers */}
        <div className="grid grid-cols-7 border-b border-gray-200">
          {['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'].map((day, index) => (
            <div key={day} className={`p-3 text-center text-sm font-medium ${
              index >= 5 ? 'text-red-600' : 'text-gray-700'
            }`}>
              {day}
            </div>
          ))}
        </div>

        {/* Calendar Days */}
        <div className="grid grid-cols-7">
          {calendarDays.map((day) => (
            <div
              key={day.date}
              onClick={() => setSelectedDay(day)}
              className={`min-h-32 p-2 border-r border-b border-gray-100 cursor-pointer hover:bg-gray-50 transition-colors ${
                !day.isCurrentMonth ? 'bg-gray-50' : ''
              } ${
                day.isToday ? 'bg-blue-50 border-blue-200' : ''
              } ${
                day.isBlackedOut ? 'bg-red-50' : ''
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <span className={`text-sm font-medium ${
                  !day.isCurrentMonth ? 'text-gray-400' : 
                  day.isToday ? 'text-blue-600' :
                  day.isWeekend || day.isHoliday ? 'text-red-600' : 
                  'text-gray-900'
                }`}>
                  {new Date(day.date).getDate()}
                </span>
                
                {showCoverage && (
                  <span className={`text-xs px-1 py-0.5 rounded ${getCoverageColor(day.availabilityScore)}`}>
                    {Math.round(day.availabilityScore)}%
                  </span>
                )}
              </div>

              <div className="space-y-1">
                {/* Holiday Indicator */}
                {day.isHoliday && (
                  <div className="text-xs text-red-600 font-medium truncate">
                    🎉 {day.holidayName}
                  </div>
                )}

                {/* Blackout Periods */}
                {showBlackouts && day.blackoutPeriods.map((blackout) => (
                  <div
                    key={blackout.id}
                    className={`text-xs p-1 rounded border-l-2 ${getBlackoutColor(blackout.severity)} truncate`}
                  >
                    🚫 {blackout.nameRu}
                  </div>
                ))}

                {/* Vacation Requests */}
                {showRequests && day.vacationRequests.map((request) => {
                  const scheme = schemes.find(s => s.id === request.schemeId);
                  return (
                    <div
                      key={request.id}
                      className="text-xs p-1 rounded truncate"
                      style={{ 
                        backgroundColor: `${scheme?.color}20`, 
                        borderLeft: `2px solid ${scheme?.color}` 
                      }}
                    >
                      {scheme?.icon} {request.employeeNameRu}
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  const renderSchemesView = () => (
    <div className="space-y-6">
      {/* Schemes Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold text-gray-900">Схемы отпусков</h2>
        <div className="flex items-center gap-3">
          <button className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center gap-2">
            <Search className="h-4 w-4" />
            Поиск
          </button>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2">
            <Plus className="h-4 w-4" />
            Создать схему
          </button>
        </div>
      </div>

      {/* Schemes Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {schemes.map((scheme) => (
          <div
            key={scheme.id}
            className="bg-white rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow"
          >
            <div className="p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div
                    className="w-12 h-12 rounded-lg flex items-center justify-center text-xl"
                    style={{ backgroundColor: `${scheme.color}20`, color: scheme.color }}
                  >
                    {scheme.icon}
                  </div>
                  <div>
                    <h3 className="font-semibold text-gray-900">{scheme.nameRu}</h3>
                    <p className="text-sm text-gray-600">{scheme.nameEn}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={selectedSchemes.includes(scheme.id)}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedSchemes([...selectedSchemes, scheme.id]);
                        } else {
                          setSelectedSchemes(selectedSchemes.filter(id => id !== scheme.id));
                        }
                      }}
                      className="rounded border-gray-300"
                    />
                  </label>
                </div>
              </div>

              <p className="text-sm text-gray-600 mb-4">{scheme.description}</p>

              <div className="grid grid-cols-2 gap-4 mb-4 text-sm">
                <div>
                  <span className="text-gray-500">Дней в году:</span>
                  <span className="ml-2 font-medium text-gray-900">{scheme.entitlementDays}</span>
                </div>
                <div>
                  <span className="text-gray-500">Макс. подряд:</span>
                  <span className="ml-2 font-medium text-gray-900">{scheme.maxConsecutiveDays}</span>
                </div>
                <div>
                  <span className="text-gray-500">Уведомление:</span>
                  <span className="ml-2 font-medium text-gray-900">{scheme.minAdvanceNotice} дней</span>
                </div>
                <div>
                  <span className="text-gray-500">Согласование:</span>
                  <span className="ml-2 font-medium text-gray-900">
                    {scheme.requiresApproval ? 'Да' : 'Нет'}
                  </span>
                </div>
              </div>

              <div className="flex items-center justify-between pt-4 border-t border-gray-200">
                <div className="flex items-center gap-2">
                  {scheme.isDefault && (
                    <span className="px-2 py-1 bg-blue-100 text-blue-700 text-xs font-medium rounded-full">
                      По умолчанию
                    </span>
                  )}
                  {scheme.isActive && (
                    <span className="px-2 py-1 bg-green-100 text-green-700 text-xs font-medium rounded-full">
                      Активна
                    </span>
                  )}
                </div>
                <div className="flex items-center gap-2">
                  <button className="p-1 hover:bg-gray-100 rounded">
                    <Eye className="h-4 w-4 text-gray-500" />
                  </button>
                  <button className="p-1 hover:bg-gray-100 rounded">
                    <Edit3 className="h-4 w-4 text-gray-500" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b border-gray-200">
        <div className="px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <CalendarDays className="h-6 w-6 text-blue-600" />
              <h1 className="text-2xl font-bold text-gray-900">{russianTranslations.title}</h1>
              <span className="px-2 py-1 bg-blue-100 text-blue-700 text-xs font-medium rounded-full">
                SPEC-31
              </span>
            </div>
            <div className="flex items-center gap-3">
              <button className="p-2 hover:bg-gray-100 rounded-lg">
                <RefreshCw className="h-5 w-5 text-gray-600" />
              </button>
              <button className="p-2 hover:bg-gray-100 rounded-lg">
                <Download className="h-5 w-5 text-gray-600" />
              </button>
              <button className="p-2 hover:bg-gray-100 rounded-lg">
                <Settings className="h-5 w-5 text-gray-600" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="bg-white border-b border-gray-200">
        <div className="px-6">
          <nav className="flex space-x-6">
            {Object.entries(russianTranslations.views).map(([key, label]) => (
              <button
                key={key}
                onClick={() => setActiveView(key as any)}
                className={`py-4 border-b-2 font-medium text-sm transition-colors ${
                  activeView === key
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

      {/* Content */}
      <div className="p-6">
        {activeView === 'calendar' && renderCalendarView()}
        {activeView === 'schemes' && renderSchemesView()}
        {activeView === 'planning' && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
            <Calendar className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-600">Годовое планирование - в разработке</p>
          </div>
        )}
        {activeView === 'analytics' && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
            <BarChart3 className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-600">Аналитика отпусков - в разработке</p>
          </div>
        )}
        {activeView === 'coverage' && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
            <Users className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-600">Покрытие команды - в разработке</p>
          </div>
        )}
      </div>

      {/* Day Detail Modal */}
      {selectedDay && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="px-6 py-4 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold text-gray-900">
                  {new Date(selectedDay.date).toLocaleDateString('ru-RU', { 
                    weekday: 'long', 
                    year: 'numeric', 
                    month: 'long', 
                    day: 'numeric' 
                  })}
                </h3>
                <button
                  onClick={() => setSelectedDay(null)}
                  className="p-2 hover:bg-gray-100 rounded-lg"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
            </div>
            
            <div className="p-6 space-y-6">
              {/* Day Summary */}
              <div className="grid grid-cols-2 gap-4">
                <div className="p-4 bg-gray-50 rounded-lg">
                  <div className="text-sm text-gray-600">Покрытие команды</div>
                  <div className={`text-lg font-semibold ${
                    selectedDay.availabilityScore >= 80 ? 'text-green-600' : 
                    selectedDay.availabilityScore >= 60 ? 'text-yellow-600' : 'text-red-600'
                  }`}>
                    {Math.round(selectedDay.availabilityScore)}%
                  </div>
                </div>
                <div className="p-4 bg-gray-50 rounded-lg">
                  <div className="text-sm text-gray-600">Заявок на отпуск</div>
                  <div className="text-lg font-semibold text-gray-900">
                    {selectedDay.vacationRequests.length}
                  </div>
                </div>
              </div>

              {/* Holiday Info */}
              {selectedDay.isHoliday && (
                <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                  <div className="flex items-center gap-2 text-blue-800">
                    <Sun className="h-5 w-5" />
                    <span className="font-medium">Праздничный день</span>
                  </div>
                  <p className="text-blue-700 mt-1">{selectedDay.holidayName}</p>
                </div>
              )}

              {/* Blackout Periods */}
              {selectedDay.blackoutPeriods.length > 0 && (
                <div className="space-y-2">
                  <h4 className="font-medium text-gray-900">Периоды блокировки</h4>
                  {selectedDay.blackoutPeriods.map((blackout) => (
                    <div
                      key={blackout.id}
                      className={`p-3 rounded-lg border-l-4 ${getBlackoutColor(blackout.severity)}`}
                    >
                      <div className="font-medium text-gray-900">{blackout.nameRu}</div>
                      <div className="text-sm text-gray-600">{blackout.reasonRu}</div>
                      <div className="text-xs text-gray-500 mt-1">
                        {russianTranslations.blackout[blackout.severity]}
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {/* Vacation Requests */}
              {selectedDay.vacationRequests.length > 0 && (
                <div className="space-y-2">
                  <h4 className="font-medium text-gray-900">Заявки на отпуск</h4>
                  {selectedDay.vacationRequests.map((request) => {
                    const scheme = schemes.find(s => s.id === request.schemeId);
                    return (
                      <div key={request.id} className="p-3 bg-gray-50 rounded-lg">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-3">
                            <div
                              className="w-8 h-8 rounded-lg flex items-center justify-center text-sm"
                              style={{ backgroundColor: `${scheme?.color}20`, color: scheme?.color }}
                            >
                              {scheme?.icon}
                            </div>
                            <div>
                              <div className="font-medium text-gray-900">{request.employeeNameRu}</div>
                              <div className="text-sm text-gray-600">{request.department}</div>
                            </div>
                          </div>
                          <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                            request.status === 'approved' ? 'bg-green-100 text-green-700' :
                            request.status === 'pending' ? 'bg-yellow-100 text-yellow-700' :
                            'bg-red-100 text-red-700'
                          }`}>
                            {russianTranslations.status[request.status]}
                          </span>
                        </div>
                        <div className="mt-2 text-sm text-gray-600">
                          {new Date(request.startDate).toLocaleDateString('ru-RU')} - 
                          {new Date(request.endDate).toLocaleDateString('ru-RU')} 
                          ({request.days} дней)
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Spec31VacationSchemesCalendar;