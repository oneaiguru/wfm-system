import React, { useState, useEffect } from 'react';
import {
  Building,
  Building2,
  MapPin,
  Globe2,
  Users,
  Settings,
  Plus,
  Search,
  Filter,
  Edit3,
  Trash2,
  Save,
  X,
  RefreshCw,
  AlertCircle,
  CheckCircle,
  Clock,
  Navigation,
  Shuffle,
  Activity,
  BarChart3,
  Route,
  Map,
  Calendar,
  Shield,
  AlertTriangle,
  Eye,
  ChevronDown,
  ChevronRight,
  ArrowUpRight,
  ArrowDownRight,
  Copy,
  FileText,
  Download,
  Upload,
  User
} from 'lucide-react';
import { realSiteService, type Spec22SiteInfo, type Spec22EmployeeAssignment, type Spec22SitePerformance } from '../../../services/realSiteService';

// SPEC-22: Multi-Site Location Management
// Enhanced from admin management components with 80% reuse
// Focus: Enterprise multi-site management for administrators and managers (15+ daily users)
// Now using real API integration with GET /api/v1/sites/hierarchy

const Spec22MultiSiteManagement: React.FC = () => {
  const [sites, setSites] = useState<Spec22SiteInfo[]>([]);
  const [assignments, setAssignments] = useState<Spec22EmployeeAssignment[]>([]);
  const [sitePerformance, setSitePerformance] = useState<Spec22SitePerformance[]>([]);
  const [activeTab, setActiveTab] = useState<'hierarchy' | 'assignments' | 'performance' | 'security'>('hierarchy');
  const [selectedSite, setSelectedSite] = useState<Spec22SiteInfo | null>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterLevel, setFilterLevel] = useState<string>('all');
  const [language, setLanguage] = useState<'ru' | 'en'>('ru');
  const [isLoading, setIsLoading] = useState(true);
  const [expandedSites, setExpandedSites] = useState<Set<string>>(new Set());
  const [error, setError] = useState<string | null>(null);

  // Real API data initialization
  useEffect(() => {
    const loadSiteData = async () => {
      try {
        setIsLoading(true);
        setError(null);
        
        console.log('🔄 Spec22MultiSiteManagement: Loading site data...');
        
        // Load site hierarchy (primary data)
        const hierarchyResult = await realSiteService.getSiteHierarchy();
        setSites(hierarchyResult.sites);
        
        // Expand corporate and regional sites by default
        const corporateAndRegional = hierarchyResult.sites
          .filter(site => site.level === 'corporate' || site.level === 'regional')
          .map(site => site.id);
        setExpandedSites(new Set(corporateAndRegional));
        
        console.log('✅ Spec22MultiSiteManagement: Site hierarchy loaded:', {
          sitesCount: hierarchyResult.sites.length,
          totalSites: hierarchyResult.totalSites,
          timezonesCount: hierarchyResult.timezoneCoverage.length
        });
        
        // Load employee assignments if sites exist
        if (hierarchyResult.sites.length > 0) {
          try {
            const assignmentsResult = await realSiteService.getEmployeeAssignments();
            setAssignments(assignmentsResult);
            console.log('✅ Spec22MultiSiteManagement: Employee assignments loaded:', assignmentsResult.length);
          } catch (assignmentError) {
            console.warn('⚠️ Spec22MultiSiteManagement: Could not load employee assignments:', assignmentError);
            setAssignments([]); // Continue without assignments
          }
        }
        
        // Load site performance for last 30 days
        if (hierarchyResult.sites.length > 0) {
          try {
            const dateFrom = new Date();
            dateFrom.setDate(dateFrom.getDate() - 30);
            const dateTo = new Date();
            
            const performanceResult = await realSiteService.getSitePerformance(
              dateFrom.toISOString().split('T')[0],
              dateTo.toISOString().split('T')[0]
            );
            setSitePerformance(performanceResult);
            console.log('✅ Spec22MultiSiteManagement: Site performance loaded:', performanceResult.length);
          } catch (performanceError) {
            console.warn('⚠️ Spec22MultiSiteManagement: Could not load site performance:', performanceError);
            setSitePerformance([]); // Continue without performance data
          }
        }
        
      } catch (error) {
        console.error('❌ Spec22MultiSiteManagement: Error loading site data:', error);
        setError('Failed to load site data. Please check your connection and try again.');
        setSites([]);
        setAssignments([]);
        setSitePerformance([]);
      } finally {
        setIsLoading(false);
      }
    };

    loadSiteData();
  }, []);

  const t = (key: string): string => {
    const translations: Record<string, Record<string, string>> = {
      ru: {
        'multi_site_management': 'Управление множественными площадками',
        'site_hierarchy': 'Иерархия площадок',
        'employee_assignments': 'Назначения сотрудников',
        'site_performance': 'Производительность площадок',
        'security_policies': 'Политики безопасности',
        'add_site': 'Добавить площадку',
        'search_sites': 'Поиск площадок...',
        'filter_by_level': 'Фильтр по уровню',
        'all_levels': 'Все уровни',
        'corporate': 'Корпоративный',
        'regional': 'Региональный',
        'site': 'Площадка',
        'department': 'Отдел',
        'active': 'Активный',
        'inactive': 'Неактивный',
        'maintenance': 'Обслуживание',
        'capacity': 'Емкость',
        'service_level': 'Уровень сервиса',
        'productivity': 'Производительность',
        'cost_per_hour': 'Стоимость/час',
        'employees': 'Сотрудники',
        'distance': 'Расстояние',
        'km': 'км',
        'view_details': 'Подробнее',
        'edit_site': 'Редактировать',
        'delete_site': 'Удалить',
        'primary_site': 'Основная площадка',
        'secondary_sites': 'Дополнительные площадки',
        'assignment_type': 'Тип назначения',
        'effective_dates': 'Действующие даты',
        'travel_allowance': 'Командировочные',
        'skills_required': 'Требуемые навыки',
        'backup': 'Резерв',
        'specialist': 'Специалист',
        'temporary': 'Временно',
        'remote': 'Удаленно',
        'customer_satisfaction': 'Удовл. клиентов',
        'operational_cost': 'Операц. стоимость',
        'utilization_rate': 'Коэфф. использования',
        'trends': 'Тренды',
        'alerts': 'Уведомления',
        'recommendations': 'Рекомендации',
        'last_updated': 'Обновлено',
        'export_data': 'Экспорт данных',
        'refresh_data': 'Обновить данные',
        'close': 'Закрыть',
        'save': 'Сохранить'
      },
      en: {
        'multi_site_management': 'Multi-Site Management',
        'site_hierarchy': 'Site Hierarchy',
        'employee_assignments': 'Employee Assignments',
        'site_performance': 'Site Performance',
        'security_policies': 'Security Policies',
        'add_site': 'Add Site',
        'search_sites': 'Search sites...',
        'filter_by_level': 'Filter by Level',
        'all_levels': 'All Levels',
        'corporate': 'Corporate',
        'regional': 'Regional',
        'site': 'Site',
        'department': 'Department',
        'active': 'Active',
        'inactive': 'Inactive',
        'maintenance': 'Maintenance',
        'capacity': 'Capacity',
        'service_level': 'Service Level',
        'productivity': 'Productivity',
        'cost_per_hour': 'Cost/Hour',
        'employees': 'Employees',
        'distance': 'Distance',
        'km': 'km',
        'view_details': 'View Details',
        'edit_site': 'Edit Site',
        'delete_site': 'Delete Site',
        'primary_site': 'Primary Site',
        'secondary_sites': 'Secondary Sites',
        'assignment_type': 'Assignment Type',
        'effective_dates': 'Effective Dates',
        'travel_allowance': 'Travel Allowance',
        'skills_required': 'Skills Required',
        'backup': 'Backup',
        'specialist': 'Specialist',
        'temporary': 'Temporary',
        'remote': 'Remote',
        'customer_satisfaction': 'Customer Satisfaction',
        'operational_cost': 'Operational Cost',
        'utilization_rate': 'Utilization Rate',
        'trends': 'Trends',
        'alerts': 'Alerts',
        'recommendations': 'Recommendations',
        'last_updated': 'Last Updated',
        'export_data': 'Export Data',
        'refresh_data': 'Refresh Data',
        'close': 'Close',
        'save': 'Save'
      }
    };
    return translations[language][key] || key;
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active': return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'inactive': return <AlertCircle className="w-4 h-4 text-gray-400" />;
      case 'maintenance': return <AlertTriangle className="w-4 h-4 text-yellow-500" />;
      default: return <AlertCircle className="w-4 h-4 text-gray-400" />;
    }
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up': return <ArrowUpRight className="w-4 h-4 text-green-500" />;
      case 'down': return <ArrowDownRight className="w-4 h-4 text-red-500" />;
      case 'stable': return <ArrowUpRight className="w-4 h-4 text-gray-400" />;
      default: return <ArrowUpRight className="w-4 h-4 text-gray-400" />;
    }
  };

  const getLevelIcon = (level: string) => {
    switch (level) {
      case 'corporate': return <Building2 className="w-4 h-4 text-purple-500" />;
      case 'regional': return <Building className="w-4 h-4 text-blue-500" />;
      case 'site': return <MapPin className="w-4 h-4 text-green-500" />;
      case 'department': return <Users className="w-4 h-4 text-orange-500" />;
      default: return <Building className="w-4 h-4 text-gray-400" />;
    }
  };

  const filteredSites = sites.filter(site => {
    const matchesSearch = 
      site.siteName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      site.siteCode.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (site.siteNameRu && site.siteNameRu.toLowerCase().includes(searchTerm.toLowerCase()));
    const matchesLevel = filterLevel === 'all' || site.level === filterLevel;
    return matchesSearch && matchesLevel;
  });

  const toggleSiteExpansion = (siteId: string) => {
    const newExpanded = new Set(expandedSites);
    if (newExpanded.has(siteId)) {
      newExpanded.delete(siteId);
    } else {
      newExpanded.add(siteId);
    }
    setExpandedSites(newExpanded);
  };

  const renderSiteHierarchy = () => {
    const rootSites = filteredSites.filter(site => !site.parentId);
    const getChildSites = (parentId: string) => 
      filteredSites.filter(site => site.parentId === parentId);

    const renderSiteNode = (site: Spec22SiteInfo, level: number = 0) => {
      const childSites = getChildSites(site.id);
      const hasChildren = childSites.length > 0;
      const isExpanded = expandedSites.has(site.id);
      const displayName = language === 'ru' ? site.siteNameRu || site.siteName : site.siteNameEn || site.siteName;

      return (
        <div key={site.id} className="mb-2">
          <div 
            className={`p-4 border rounded-lg cursor-pointer hover:bg-gray-50 ${
              selectedSite?.id === site.id ? 'border-blue-500 bg-blue-50' : 'border-gray-200'
            }`}
            style={{ marginLeft: `${level * 20}px` }}
            onClick={() => setSelectedSite(site)}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="flex items-center space-x-1">
                  {hasChildren && (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        toggleSiteExpansion(site.id);
                      }}
                      className="p-1 hover:bg-gray-200 rounded"
                    >
                      {isExpanded ? <ChevronDown className="w-4 h-4" /> : <ChevronRight className="w-4 h-4" />}
                    </button>
                  )}
                  {!hasChildren && <div className="w-6" />}
                  {getLevelIcon(site.level)}
                </div>
                <div>
                  <div className="flex items-center space-x-2">
                    <span className="font-medium text-lg">{displayName}</span>
                    <span className="text-sm text-gray-500">({site.siteCode})</span>
                    {getStatusIcon(site.status)}
                  </div>
                  <div className="text-sm text-gray-600">{site.address}</div>
                  <div className="flex items-center space-x-4 mt-1">
                    <span className="text-xs bg-gray-100 px-2 py-1 rounded">
                      {site.timezone}
                    </span>
                    <span className="text-xs text-gray-500">
                      {t('capacity')}: {site.capacity.current}/{site.capacity.maximum}
                    </span>
                    {site.distanceToParent && (
                      <span className="text-xs text-gray-500">
                        {site.distanceToParent} {t('km')}
                      </span>
                    )}
                  </div>
                </div>
              </div>
              <div className="flex items-center space-x-2">
                <div className="text-right text-sm">
                  <div>{site.performance.serviceLevel}% {t('service_level')}</div>
                  <div className="text-gray-500">{site.performance.employeeCount} {t('employees')}</div>
                </div>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    setSelectedSite(site);
                    setIsEditModalOpen(true);
                  }}
                  className="p-2 hover:bg-gray-200 rounded"
                  title={t('edit_site')}
                >
                  <Edit3 className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
          
          {hasChildren && isExpanded && (
            <div className="ml-4">
              {childSites.map(child => renderSiteNode(child, level + 1))}
            </div>
          )}
        </div>
      );
    };

    return (
      <div>
        {rootSites.map(site => renderSiteNode(site))}
      </div>
    );
  };

  const renderEmployeeAssignments = () => (
    <div className="space-y-4">
      {assignments.map(assignment => (
        <div key={assignment.id} className="p-4 border border-gray-200 rounded-lg">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <User className="w-5 h-5 text-blue-500" />
              <div>
                <div className="font-medium text-lg">{assignment.employeeName}</div>
                <div className="text-sm text-gray-600">
                  {t('primary_site')}: {assignment.primarySiteName}
                </div>
              </div>
            </div>
            <div className="text-right">
              <div className={`px-2 py-1 rounded text-xs ${
                assignment.status === 'active' ? 'bg-green-100 text-green-800' :
                assignment.status === 'transferred' ? 'bg-blue-100 text-blue-800' :
                'bg-yellow-100 text-yellow-800'
              }`}>
                {assignment.status}
              </div>
              {assignment.travelAllowance && (
                <div className="text-sm text-gray-500 mt-1">
                  {t('travel_allowance')}: ₽{assignment.travelAllowance.toLocaleString()}
                </div>
              )}
            </div>
          </div>
          
          {assignment.secondarySites.length > 0 && (
            <div className="mt-3">
              <div className="text-sm font-medium text-gray-700 mb-2">{t('secondary_sites')}:</div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                {assignment.secondarySites.map((secondary, index) => (
                  <div key={index} className="flex items-center space-x-2 text-sm">
                    <MapPin className="w-4 h-4 text-gray-400" />
                    <span>{secondary.siteName}</span>
                    <span className="px-2 py-1 bg-gray-100 text-gray-600 rounded text-xs">
                      {t(secondary.assignmentType)}
                    </span>
                    <span className="text-gray-500">({secondary.schedule})</span>
                  </div>
                ))}
              </div>
            </div>
          )}
          
          <div className="mt-3 flex items-center space-x-4 text-sm text-gray-600">
            <div>
              {t('effective_dates')}: {new Date(assignment.effectiveDates.start).toLocaleDateString()}
              {assignment.effectiveDates.end && ` - ${new Date(assignment.effectiveDates.end).toLocaleDateString()}`}
            </div>
            <div>
              {t('skills_required')}: {assignment.skillsRequired.join(', ')}
            </div>
          </div>
        </div>
      ))}
    </div>
  );

  const renderSitePerformance = () => (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {sitePerformance.map(perf => (
        <div key={perf.siteId} className="p-6 border border-gray-200 rounded-lg">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold">{perf.siteName}</h3>
            <div className="text-sm text-gray-500">
              {t('last_updated')}: {new Date(perf.lastUpdated).toLocaleString()}
            </div>
          </div>
          
          <div className="grid grid-cols-2 gap-4 mb-4">
            <div className="bg-blue-50 p-3 rounded">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">{t('service_level')}</span>
                {getTrendIcon(perf.trends.serviceLevel)}
              </div>
              <div className="text-xl font-bold text-blue-600">
                {perf.metrics.serviceLevel}%
              </div>
            </div>
            
            <div className="bg-green-50 p-3 rounded">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">{t('productivity')}</span>
                {getTrendIcon(perf.trends.productivity)}
              </div>
              <div className="text-xl font-bold text-green-600">
                {perf.metrics.productivity}
              </div>
            </div>
            
            <div className="bg-purple-50 p-3 rounded">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">{t('customer_satisfaction')}</span>
                <BarChart3 className="w-4 h-4 text-purple-500" />
              </div>
              <div className="text-xl font-bold text-purple-600">
                {perf.metrics.customerSatisfaction}/5
              </div>
            </div>
            
            <div className="bg-orange-50 p-3 rounded">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">{t('operational_cost')}</span>
                {getTrendIcon(perf.trends.cost)}
              </div>
              <div className="text-xl font-bold text-orange-600">
                ₽{perf.metrics.operationalCost}
              </div>
            </div>
          </div>
          
          <div className="flex justify-between text-sm text-gray-600 mb-3">
            <span>{t('employees')}: {perf.metrics.employeeCount}</span>
            <span>{t('utilization_rate')}: {perf.metrics.utilizationRate}%</span>
          </div>
          
          {perf.alerts.length > 0 && (
            <div className="space-y-2">
              <div className="text-sm font-medium text-gray-700">{t('alerts')}:</div>
              {perf.alerts.map((alert, index) => (
                <div key={index} className={`p-2 rounded text-sm ${
                  alert.type === 'critical' ? 'bg-red-50 border border-red-200' :
                  alert.type === 'warning' ? 'bg-yellow-50 border border-yellow-200' :
                  'bg-blue-50 border border-blue-200'
                }`}>
                  <div className="flex items-start space-x-2">
                    <AlertCircle className={`w-4 h-4 mt-0.5 ${
                      alert.type === 'critical' ? 'text-red-500' :
                      alert.type === 'warning' ? 'text-yellow-500' :
                      'text-blue-500'
                    }`} />
                    <div>
                      <div>{alert.message}</div>
                      {alert.recommendation && (
                        <div className="text-xs text-gray-600 mt-1">
                          {t('recommendations')}: {alert.recommendation}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      ))}
    </div>
  );

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <RefreshCw className="w-8 h-8 animate-spin text-blue-500" />
        <span className="ml-2">Загрузка данных о площадках...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 p-6">
        <div className="max-w-7xl mx-auto">
          <div className="bg-white rounded-lg shadow-sm p-6">
            <div className="flex items-center justify-center h-64">
              <div className="text-center">
                <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
                <h3 className="text-lg font-semibold text-gray-900 mb-2">Ошибка загрузки данных</h3>
                <p className="text-gray-600 mb-4">{error}</p>
                <button
                  onClick={async () => {
                    setError(null);
                    setIsLoading(true);
                    try {
                      const hierarchyResult = await realSiteService.getSiteHierarchy();
                      setSites(hierarchyResult.sites);
                    } catch (err) {
                      setError('Failed to load site data');
                    } finally {
                      setIsLoading(false);
                    }
                  }}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Попробовать снова
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <Globe2 className="w-8 h-8 text-blue-600" />
              <div>
                <h1 className="text-2xl font-bold text-gray-900">
                  {t('multi_site_management')}
                </h1>
                <p className="text-gray-600">
                  Управление {sites.length} площадками в {new Set(sites.map(s => s.timezone)).size} временных зонах
                </p>
              </div>
            </div>
            
            <div className="flex items-center space-x-3">
              <button
                onClick={() => setLanguage(language === 'ru' ? 'en' : 'ru')}
                className="px-3 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                {language.toUpperCase()}
              </button>
              <button className="flex items-center space-x-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">
                <Download className="w-4 h-4" />
                <span>{t('export_data')}</span>
              </button>
              <button 
                onClick={async () => {
                  setIsLoading(true);
                  try {
                    const hierarchyResult = await realSiteService.getSiteHierarchy();
                    setSites(hierarchyResult.sites);
                    setError(null);
                  } catch (err) {
                    setError('Failed to refresh site data');
                  } finally {
                    setIsLoading(false);
                  }
                }}
                className="flex items-center space-x-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50"
                disabled={isLoading}
              >
                <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
                <span>{t('refresh_data')}</span>
              </button>
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div className="bg-white rounded-lg shadow-sm mb-6">
          <div className="border-b border-gray-200">
            <nav className="flex space-x-8 px-6">
              {[
                { id: 'hierarchy', label: t('site_hierarchy'), icon: Building },
                { id: 'assignments', label: t('employee_assignments'), icon: Users },
                { id: 'performance', label: t('site_performance'), icon: BarChart3 },
                { id: 'security', label: t('security_policies'), icon: Shield }
              ].map(tab => {
                const Icon = tab.icon;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id as any)}
                    className={`flex items-center space-x-2 py-4 border-b-2 font-medium text-sm ${
                      activeTab === tab.id
                        ? 'border-blue-500 text-blue-600'
                        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                    }`}
                  >
                    <Icon className="w-5 h-5" />
                    <span>{tab.label}</span>
                  </button>
                );
              })}
            </nav>
          </div>
        </div>

        {/* Filters */}
        <div className="bg-white rounded-lg shadow-sm p-4 mb-6">
          <div className="flex items-center space-x-4">
            <div className="flex-1">
              <div className="relative">
                <Search className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  placeholder={t('search_sites')}
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>
            
            <div className="flex items-center space-x-2">
              <Filter className="w-5 h-5 text-gray-400" />
              <select
                value={filterLevel}
                onChange={(e) => setFilterLevel(e.target.value)}
                className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">{t('all_levels')}</option>
                <option value="corporate">{t('corporate')}</option>
                <option value="regional">{t('regional')}</option>
                <option value="site">{t('site')}</option>
                <option value="department">{t('department')}</option>
              </select>
            </div>
            
            <button className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
              <Plus className="w-4 h-4" />
              <span>{t('add_site')}</span>
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="bg-white rounded-lg shadow-sm p-6">
          {activeTab === 'hierarchy' && renderSiteHierarchy()}
          {activeTab === 'assignments' && renderEmployeeAssignments()}
          {activeTab === 'performance' && renderSitePerformance()}
          {activeTab === 'security' && (
            <div className="text-center py-12">
              <Shield className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-500">{t('security_policies')} - В разработке</p>
            </div>
          )}
        </div>

        {/* Selected Site Details */}
        {selectedSite && (
          <div className="bg-white rounded-lg shadow-sm p-6 mt-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-xl font-semibold">
                {language === 'ru' ? selectedSite.siteNameRu || selectedSite.siteName : selectedSite.siteNameEn || selectedSite.siteName}
              </h3>
              <button
                onClick={() => setSelectedSite(null)}
                className="p-2 hover:bg-gray-100 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div>
                <h4 className="font-medium text-gray-900 mb-3">Основная информация</h4>
                <div className="space-y-2 text-sm">
                  <div><span className="text-gray-600">Код:</span> {selectedSite.siteCode}</div>
                  <div><span className="text-gray-600">Адрес:</span> {selectedSite.address}</div>
                  <div><span className="text-gray-600">Часовой пояс:</span> {selectedSite.timezone}</div>
                  <div><span className="text-gray-600">Статус:</span> {t(selectedSite.status)}</div>
                  {selectedSite.coordinates && (
                    <div><span className="text-gray-600">Координаты:</span> {selectedSite.coordinates.latitude}, {selectedSite.coordinates.longitude}</div>
                  )}
                </div>
              </div>
              
              <div>
                <h4 className="font-medium text-gray-900 mb-3">Производительность</h4>
                <div className="space-y-2 text-sm">
                  <div><span className="text-gray-600">Уровень сервиса:</span> {selectedSite.performance.serviceLevel}%</div>
                  <div><span className="text-gray-600">Производительность:</span> {selectedSite.performance.productivity}</div>
                  <div><span className="text-gray-600">Стоимость/час:</span> ₽{selectedSite.performance.costPerHour}</div>
                  <div><span className="text-gray-600">Сотрудники:</span> {selectedSite.performance.employeeCount}</div>
                  <div><span className="text-gray-600">Загрузка:</span> {selectedSite.capacity.current}/{selectedSite.capacity.maximum}</div>
                </div>
              </div>
              
              <div>
                <h4 className="font-medium text-gray-900 mb-3">Контакты</h4>
                <div className="space-y-2 text-sm">
                  {selectedSite.contactInfo.phone && (
                    <div><span className="text-gray-600">Телефон:</span> {selectedSite.contactInfo.phone}</div>
                  )}
                  {selectedSite.contactInfo.email && (
                    <div><span className="text-gray-600">Email:</span> {selectedSite.contactInfo.email}</div>
                  )}
                  {selectedSite.contactInfo.manager && (
                    <div><span className="text-gray-600">Руководитель:</span> {selectedSite.contactInfo.manager}</div>
                  )}
                  <div><span className="text-gray-600">Рабочие часы:</span> {selectedSite.workingHours.start} - {selectedSite.workingHours.end}</div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Spec22MultiSiteManagement;