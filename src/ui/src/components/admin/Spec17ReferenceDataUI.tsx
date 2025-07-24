import React, { useState, useEffect } from 'react';
import {
  Database,
  Plus,
  Search,
  Filter,
  Download,
  Upload,
  Edit3,
  Trash2,
  Save,
  X,
  RefreshCw,
  AlertCircle,
  CheckCircle,
  Eye,
  BarChart3,
  Sync,
  FolderPlus,
  FileText,
  Settings,
  Tag,
  Calendar,
  User,
  Activity,
  Globe,
  GitBranch,
  TreePine,
  ChevronDown,
  ChevronRight
} from 'lucide-react';

// SPEC-17: Reference Data Management & Configuration
// Enhanced from ReferenceDataManager.tsx with multi-language, hierarchical data, and 1C ZUP integration
// Focus: Admin configuration interface for 10+ daily admin users

interface Spec17ReferenceDataItem {
  id: string;
  category: string;
  key: string;
  value: string;
  displayName: string;
  displayNameRu?: string; // Russian display name
  displayNameEn?: string; // English display name  
  description?: string;
  descriptionRu?: string; // Russian description
  descriptionEn?: string; // English description
  dataType: 'string' | 'number' | 'boolean' | 'array' | 'object';
  isSystemManaged: boolean;
  isActive: boolean;
  
  // Hierarchical support
  parentId?: string;
  children?: Spec17ReferenceDataItem[];
  level?: number;
  sortOrder?: number;
  
  // 1C ZUP integration
  externalId?: string; // 1C system code
  syncStatus?: 'synced' | 'pending' | 'error' | 'not_synced';
  lastSyncDate?: string;
  
  // Versioning and audit
  version?: number;
  createdBy?: string;
  createdAt?: string;
  modifiedBy?: string;
  modifiedAt?: string;
  
  // Validation and business rules
  validationRules?: Record<string, any>;
  businessRules?: Record<string, any>;
  effectiveDate?: string;
  expirationDate?: string;
  
  // Metadata
  metadata?: {
    tags?: string[];
    priority?: number;
    region?: string;
    compliance?: string[];
  };
}

interface ReferenceDataCategory {
  id: string;
  name: string;
  nameRu?: string;
  nameEn?: string;
  description: string;
  descriptionRu?: string;
  descriptionEn?: string;
  isSystemCategory: boolean;
  itemCount: number;
  isHierarchical: boolean; // Supports parent-child relationships
  supports1CSync: boolean; // Can sync with 1C ZUP
}

const Spec17ReferenceDataUI: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [saveSuccess, setSaveSuccess] = useState(false);
  
  // UI State
  const [currentLanguage, setCurrentLanguage] = useState<'ru' | 'en'>('ru');
  const [selectedCategory, setSelectedCategory] = useState<string>('work-rules');
  const [hierarchicalView, setHierarchicalView] = useState<boolean>(false);
  const [expandedNodes, setExpandedNodes] = useState<Set<string>>(new Set());
  
  // Data State
  const [categories, setCategories] = useState<ReferenceDataCategory[]>([]);
  const [referenceData, setReferenceData] = useState<Spec17ReferenceDataItem[]>([]);
  const [filteredData, setFilteredData] = useState<Spec17ReferenceDataItem[]>([]);
  
  // Search and Filter
  const [searchTerm, setSearchTerm] = useState('');
  const [filterActive, setFilterActive] = useState<boolean | undefined>(undefined);
  const [selectedItems, setSelectedItems] = useState<Set<string>>(new Set());
  
  // Modal State
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editingItem, setEditingItem] = useState<Spec17ReferenceDataItem | null>(null);
  
  // Form State
  const [newItem, setNewItem] = useState<Partial<Spec17ReferenceDataItem>>({
    category: 'work-rules',
    key: '',
    value: '',
    displayName: '',
    displayNameRu: '',
    displayNameEn: '',
    description: '',
    descriptionRu: '',
    descriptionEn: '',
    dataType: 'string',
    isSystemManaged: false,
    isActive: true,
    parentId: '',
    sortOrder: 100,
    syncStatus: 'not_synced',
    validationRules: {},
    businessRules: {},
    metadata: { tags: [], priority: 1 }
  });

  useEffect(() => {
    loadCategories();
  }, []);

  useEffect(() => {
    if (selectedCategory) {
      loadReferenceData();
    }
  }, [selectedCategory]);

  useEffect(() => {
    // Filter data based on search and status
    let filtered = referenceData.filter(item => item.category === selectedCategory);

    if (searchTerm) {
      filtered = filtered.filter(item =>
        item.key.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.displayName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (item.displayNameRu && item.displayNameRu.toLowerCase().includes(searchTerm.toLowerCase())) ||
        item.value.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (filterActive !== undefined) {
      filtered = filtered.filter(item => item.isActive === filterActive);
    }

    setFilteredData(filtered);
  }, [referenceData, selectedCategory, searchTerm, filterActive]);

  const loadCategories = async () => {
    try {
      console.log('[SPEC-17 REFERENCE] Loading categories...');
      
      // Demo categories for SPEC-17
      const demoCategories: ReferenceDataCategory[] = [
        {
          id: 'work-rules',
          name: 'Work Rules',
          nameRu: 'Правила работы',
          nameEn: 'Work Rules',
          description: 'Work time and shift configuration rules',
          descriptionRu: 'Правила рабочего времени и смен',
          descriptionEn: 'Work time and shift configuration rules',
          isSystemCategory: false,
          itemCount: 12,
          isHierarchical: false,
          supports1CSync: true
        },
        {
          id: 'absence-codes',
          name: 'Absence Codes',
          nameRu: 'Коды отсутствий',
          nameEn: 'Absence Codes',
          description: 'Vacation, sick leave, and other absence types',
          descriptionRu: 'Отпуска, больничные и другие виды отсутствий',
          descriptionEn: 'Vacation, sick leave, and other absence types',
          isSystemCategory: false,
          itemCount: 18,
          isHierarchical: false,
          supports1CSync: true
        },
        {
          id: 'departments',
          name: 'Department Hierarchy',
          nameRu: 'Иерархия подразделений',
          nameEn: 'Department Hierarchy',
          description: 'Organizational structure and departments',
          descriptionRu: 'Организационная структура и подразделения',
          descriptionEn: 'Organizational structure and departments',
          isSystemCategory: false,
          itemCount: 45,
          isHierarchical: true,
          supports1CSync: true
        },
        {
          id: 'service-levels',
          name: 'Service Levels',
          nameRu: 'Уровни обслуживания',
          nameEn: 'Service Levels',
          description: 'Customer service and quality metrics',
          descriptionRu: 'Метрики качества обслуживания клиентов',
          descriptionEn: 'Customer service and quality metrics',
          isSystemCategory: false,
          itemCount: 8,
          isHierarchical: false,
          supports1CSync: false
        },
        {
          id: 'business-rules',
          name: 'Business Rules',
          nameRu: 'Бизнес-правила',
          nameEn: 'Business Rules',
          description: 'Configurable business logic and validation rules',
          descriptionRu: 'Настраиваемая бизнес-логика и правила валидации',
          descriptionEn: 'Configurable business logic and validation rules',
          isSystemCategory: true,
          itemCount: 23,
          isHierarchical: false,
          supports1CSync: false
        }
      ];

      setCategories(demoCategories);
    } catch (error) {
      setApiError('Failed to load reference data categories');
      console.error('[SPEC-17 REFERENCE] Load categories error:', error);
    }
  };

  const loadReferenceData = async () => {
    setLoading(true);
    setApiError('');

    try {
      const authToken = localStorage.getItem('authToken');
      
      if (!authToken) {
        throw new Error('No authentication token');
      }

      console.log('[SPEC-17 REFERENCE] Loading data from I verified training programs endpoint');
      
      // Use INTEGRATION-OPUS verified training programs as reference data
      const response = await fetch('http://localhost:8001/api/v1/training/programs', {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const trainingData = await response.json();
        console.log('✅ Training programs loaded from I as reference data:', trainingData);
        
        // Convert training programs to reference data format
        const referenceItems = convertTrainingToReferenceData(trainingData);
        setReferenceData(referenceItems);
      } else {
        console.error(`❌ Reference data API error: ${response.status}`);
        setApiError(`API Error: ${response.status}`);
        // Fallback to demo data
        const demoData = getDemoDataForCategory(selectedCategory);
        setReferenceData(demoData);
      }
      
    } catch (error) {
      setApiError('Failed to load reference data');
      console.error('[SPEC-17 REFERENCE] Load data error:', error);
      // Fallback to demo data
      const demoData = getDemoDataForCategory(selectedCategory);
      setReferenceData(demoData);
    } finally {
      setLoading(false);
    }
  };

  // Convert INTEGRATION-OPUS training programs to reference data format
  const convertTrainingToReferenceData = (trainingData: any): Spec17ReferenceDataItem[] => {
    console.log('[SPEC-17 REFERENCE] Converting I training data to reference format');
    
    const referenceItems: Spec17ReferenceDataItem[] = [];
    
    if (trainingData.programs && Array.isArray(trainingData.programs)) {
      trainingData.programs.forEach((program: any, index: number) => {
        referenceItems.push({
          id: program.program_id || `training-${index}`,
          category: 'training-programs',
          key: program.program_id || `PROG_${index}`,
          value: program.title_en || program.title_ru || 'Training Program',
          displayName: program.title_en || program.title_ru || 'Training Program',
          displayNameRu: program.title_ru || program.title_en || 'Программа обучения',
          displayNameEn: program.title_en || program.title_ru || 'Training Program',
          description: program.description || '',
          descriptionRu: program.description || '',
          descriptionEn: program.description || '',
          dataType: 'object',
          isSystemManaged: program.training_type === 'mandatory' || program.training_type === 'compliance',
          isActive: true,
          sortOrder: (index + 1) * 10,
          externalId: program.program_id,
          syncStatus: 'synced',
          lastSyncDate: new Date().toISOString(),
          version: 1,
          createdBy: 'admin',
          createdAt: new Date().toISOString(),
          metadata: {
            tags: [program.training_type || 'general'],
            priority: program.training_type === 'mandatory' ? 1 : 2,
            region: 'global'
          }
        });
      });
    }

    // Add demo data for other categories when not training-programs
    if (selectedCategory !== 'training-programs') {
      return getDemoDataForCategory(selectedCategory);
    }

    return referenceItems;
  };

  const getDemoDataForCategory = (categoryId: string): Spec17ReferenceDataItem[] => {
    const baseData = {
      'work-rules': [
        {
          id: '1',
          category: 'work-rules',
          key: 'STANDARD_5_2',
          value: 'Standard 5/2 Schedule',
          displayName: 'Standard 5/2 Schedule',
          displayNameRu: 'Стандартный график 5/2',
          displayNameEn: 'Standard 5/2 Schedule',
          description: 'Monday to Friday, 8 hours per day',
          descriptionRu: 'Понедельник-пятница, 8 часов в день',
          descriptionEn: 'Monday to Friday, 8 hours per day',
          dataType: 'object' as const,
          isSystemManaged: false,
          isActive: true,
          sortOrder: 100,
          externalId: 'WR001',
          syncStatus: 'synced' as const,
          lastSyncDate: '2025-07-21T08:00:00Z',
          version: 2,
          createdBy: 'admin',
          createdAt: '2025-05-01T00:00:00Z',
          metadata: { tags: ['standard', 'full-time'], priority: 1, region: 'global' }
        },
        {
          id: '2',
          category: 'work-rules',
          key: 'SHIFT_2_2',
          value: 'Shift 2/2 Schedule',
          displayName: 'Shift 2/2 Schedule',
          displayNameRu: 'Сменный график 2/2',
          displayNameEn: 'Shift 2/2 Schedule',
          description: '2 days work, 2 days off, 12 hours per day',
          descriptionRu: '2 дня работы, 2 дня отдыха, 12 часов в день',
          descriptionEn: '2 days work, 2 days off, 12 hours per day',
          dataType: 'object' as const,
          isSystemManaged: false,
          isActive: true,
          sortOrder: 110,
          externalId: 'WR002',
          syncStatus: 'pending' as const,
          version: 1,
          createdBy: 'hr_manager',
          createdAt: '2025-06-15T00:00:00Z',
          metadata: { tags: ['shift', 'extended'], priority: 2, region: 'russia' }
        }
      ],
      'absence-codes': [
        {
          id: '3',
          category: 'absence-codes',
          key: 'VACATION_ANNUAL',
          value: 'Annual Vacation',
          displayName: 'Annual Vacation',
          displayNameRu: 'Ежегодный отпуск',
          displayNameEn: 'Annual Vacation',
          description: 'Paid annual leave entitlement',
          descriptionRu: 'Оплачиваемый ежегодный отпуск',
          descriptionEn: 'Paid annual leave entitlement',
          dataType: 'string' as const,
          isSystemManaged: false,
          isActive: true,
          sortOrder: 200,
          externalId: 'AC001',
          syncStatus: 'synced' as const,
          lastSyncDate: '2025-07-20T12:00:00Z',
          version: 1,
          createdBy: 'admin',
          createdAt: '2025-04-01T00:00:00Z',
          metadata: { tags: ['vacation', 'paid'], priority: 1, region: 'global' }
        },
        {
          id: '4',
          category: 'absence-codes',
          key: 'SICK_LEAVE',
          value: 'Sick Leave',
          displayName: 'Sick Leave',
          displayNameRu: 'Больничный лист',
          displayNameEn: 'Sick Leave',
          description: 'Medical leave with certificate',
          descriptionRu: 'Медицинский отпуск по справке врача',
          descriptionEn: 'Medical leave with certificate',
          dataType: 'string' as const,
          isSystemManaged: false,
          isActive: true,
          sortOrder: 210,
          externalId: 'AC002',
          syncStatus: 'synced' as const,
          lastSyncDate: '2025-07-19T15:30:00Z',
          version: 3,
          createdBy: 'hr_specialist',
          createdAt: '2025-04-01T00:00:00Z',
          metadata: { tags: ['medical', 'paid'], priority: 1, region: 'russia' }
        }
      ],
      'departments': [
        {
          id: '5',
          category: 'departments',
          key: 'IT_DEPARTMENT',
          value: 'Information Technology',
          displayName: 'Information Technology',
          displayNameRu: 'Информационные технологии',
          displayNameEn: 'Information Technology',
          description: 'IT development and infrastructure teams',
          descriptionRu: 'Команды разработки и ИТ-инфраструктуры',
          descriptionEn: 'IT development and infrastructure teams',
          dataType: 'object' as const,
          isSystemManaged: false,
          isActive: true,
          level: 1,
          sortOrder: 100,
          externalId: 'DP001',
          syncStatus: 'synced' as const,
          lastSyncDate: '2025-07-21T09:00:00Z',
          version: 1,
          createdBy: 'admin',
          createdAt: '2025-01-15T00:00:00Z',
          metadata: { tags: ['department', 'technology'], priority: 1, region: 'global' }
        },
        {
          id: '6',
          category: 'departments',
          key: 'IT_DEVELOPMENT',
          value: 'Software Development',
          displayName: 'Software Development',
          displayNameRu: 'Разработка ПО',
          displayNameEn: 'Software Development',
          description: 'Application development team',
          descriptionRu: 'Команда разработки приложений',
          descriptionEn: 'Application development team',
          dataType: 'object' as const,
          isSystemManaged: false,
          isActive: true,
          parentId: '5',
          level: 2,
          sortOrder: 110,
          externalId: 'DP001-DEV',
          syncStatus: 'synced' as const,
          lastSyncDate: '2025-07-21T09:15:00Z',
          version: 1,
          createdBy: 'admin',
          createdAt: '2025-01-15T00:00:00Z',
          metadata: { tags: ['team', 'development'], priority: 1, region: 'global' }
        },
        {
          id: '7',
          category: 'departments',
          key: 'CUSTOMER_SUPPORT',
          value: 'Customer Support',
          displayName: 'Customer Support',
          displayNameRu: 'Служба поддержки',
          displayNameEn: 'Customer Support',
          description: 'Customer service and technical support',
          descriptionRu: 'Обслуживание клиентов и техническая поддержка',
          descriptionEn: 'Customer service and technical support',
          dataType: 'object' as const,
          isSystemManaged: false,
          isActive: true,
          level: 1,
          sortOrder: 200,
          externalId: 'CS',
          syncStatus: 'synced' as const,
          lastSyncDate: '2025-07-21T07:00:00Z',
          version: 1,
          createdBy: 'admin',
          createdAt: '2025-06-01T00:00:00Z',
          metadata: { tags: ['customer', 'support'], priority: 1, region: 'global' }
        }
      ]
    };
    
    return (baseData[categoryId as keyof typeof baseData] || []) as Spec17ReferenceDataItem[];
  };

  const handleSave = async (item: Partial<Spec17ReferenceDataItem>) => {
    setSaving(true);
    setApiError('');
    
    try {
      console.log('[SPEC-17 REFERENCE] Saving item:', item);
      
      // In real implementation, this would call SPEC-17 reference data save API
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
      
      // Reload data
      await loadReferenceData();
      
      // Close modals
      setShowCreateModal(false);
      setShowEditModal(false);
      setEditingItem(null);
      resetNewItem();
      
    } catch (error) {
      setApiError('Failed to save reference data item');
      console.error('[SPEC-17 REFERENCE] Save error:', error);
    } finally {
      setSaving(false);
    }
  };

  const handleSync1C = async (items: string[]) => {
    setSyncing(true);
    setApiError('');
    
    try {
      console.log('[SPEC-17 REFERENCE] Syncing with 1C ZUP:', items);
      
      // In real implementation, this would call SPEC-17 1C sync API
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Update sync status for selected items
      const updatedData = referenceData.map(item => {
        if (items.includes(item.id)) {
          return {
            ...item,
            syncStatus: 'synced' as const,
            lastSyncDate: new Date().toISOString()
          };
        }
        return item;
      });
      
      setReferenceData(updatedData);
      setSaveSuccess(true);
      setTimeout(() => setSaveSuccess(false), 3000);
      
    } catch (error) {
      setApiError('Failed to sync with 1C ZUP system');
      console.error('[SPEC-17 REFERENCE] 1C sync error:', error);
    } finally {
      setSyncing(false);
    }
  };

  const resetNewItem = () => {
    setNewItem({
      category: selectedCategory,
      key: '',
      value: '',
      displayName: '',
      displayNameRu: '',
      displayNameEn: '',
      description: '',
      descriptionRu: '',
      descriptionEn: '',
      dataType: 'string',
      isSystemManaged: false,
      isActive: true,
      parentId: '',
      sortOrder: 100,
      syncStatus: 'not_synced',
      validationRules: {},
      businessRules: {},
      metadata: { tags: [], priority: 1 }
    });
  };

  const selectedCategoryData = categories.find(cat => cat.id === selectedCategory);
  const supports1CSync = selectedCategoryData?.supports1CSync || false;

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                {currentLanguage === 'ru' ? 'Управление справочными данными' : 'Reference Data Management'}
              </h1>
              <p className="text-gray-600 mt-1">
                {currentLanguage === 'ru' ? 
                  'SPEC-17: Конфигурация системы и многоязычные справочники' : 
                  'SPEC-17: System configuration and multi-language reference data'
                }
              </p>
            </div>
            <div className="flex items-center space-x-4">
              <button
                onClick={() => setCurrentLanguage(currentLanguage === 'ru' ? 'en' : 'ru')}
                className="flex items-center gap-2 px-3 py-2 text-sm bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                <Globe size={16} />
                {currentLanguage === 'ru' ? 'EN' : 'RU'}
              </button>
              <button
                onClick={() => setShowCreateModal(true)}
                className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                <Plus size={16} />
                {currentLanguage === 'ru' ? 'Добавить данные' : 'Add Data'}
              </button>
            </div>
          </div>
        </div>

        {/* Status Messages */}
        {apiError && (
          <div className="mb-6 bg-red-50 border border-red-200 rounded-lg p-4 flex items-center">
            <AlertCircle className="h-5 w-5 text-red-600 mr-3" />
            <div>
              <p className="font-medium text-red-800">
                {currentLanguage === 'ru' ? 'Ошибка' : 'Error'}
              </p>
              <p className="text-red-700 text-sm">{apiError}</p>
            </div>
          </div>
        )}

        {saveSuccess && (
          <div className="mb-6 bg-green-50 border border-green-200 rounded-lg p-4 flex items-center">
            <CheckCircle className="h-5 w-5 text-green-600 mr-3" />
            <p className="text-green-800">
              {currentLanguage === 'ru' ? 'Изменения сохранены успешно' : 'Changes saved successfully'}
            </p>
          </div>
        )}

        {/* Categories */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-medium text-gray-900">
              {currentLanguage === 'ru' ? 'Категории справочных данных' : 'Reference Data Categories'}
            </h2>
            {supports1CSync && selectedItems.size > 0 && (
              <button
                onClick={() => handleSync1C(Array.from(selectedItems))}
                disabled={syncing}
                className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
              >
                {syncing ? (
                  <RefreshCw className="h-4 w-4 animate-spin" />
                ) : (
                  <Sync className="h-4 w-4" />
                )}
                {syncing ? 
                  (currentLanguage === 'ru' ? 'Синхронизация...' : 'Syncing...') :
                  (currentLanguage === 'ru' ? 'Синхронизация с 1С ЗУП' : 'Sync with 1C ZUP')
                }
              </button>
            )}
          </div>

          {/* Category Grid */}
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-6">
            {categories.map((category) => (
              <button
                key={category.id}
                onClick={() => setSelectedCategory(category.id)}
                className={`p-4 rounded-lg border-2 text-left transition-colors ${
                  selectedCategory === category.id
                    ? 'border-blue-500 bg-blue-50 text-blue-900'
                    : 'border-gray-200 bg-white hover:border-gray-300 hover:bg-gray-50'
                }`}
              >
                <div className="flex items-center justify-between mb-2">
                  <Database size={20} className={selectedCategory === category.id ? 'text-blue-600' : 'text-gray-600'} />
                  {category.supports1CSync && <Sync size={16} className="text-green-600" />}
                </div>
                <div className="font-medium">
                  {currentLanguage === 'ru' && category.nameRu ? category.nameRu : category.name}
                </div>
                <div className="text-sm text-gray-600 mt-1">
                  {category.itemCount} {currentLanguage === 'ru' ? 'элементов' : 'items'}
                </div>
                {category.isHierarchical && (
                  <div className="flex items-center mt-2 text-xs text-gray-500">
                    <GitBranch size={12} className="mr-1" />
                    {currentLanguage === 'ru' ? 'Иерархия' : 'Hierarchical'}
                  </div>
                )}
              </button>
            ))}
          </div>

          {/* Search Controls */}
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
                <input
                  type="text"
                  placeholder={currentLanguage === 'ru' ? 'Поиск...' : 'Search...'}
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              
              <select
                value={filterActive ?? ''}
                onChange={(e) => setFilterActive(e.target.value === '' ? undefined : e.target.value === 'true')}
                className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">{currentLanguage === 'ru' ? 'Все статусы' : 'All Status'}</option>
                <option value="true">{currentLanguage === 'ru' ? 'Активные' : 'Active'}</option>
                <option value="false">{currentLanguage === 'ru' ? 'Неактивные' : 'Inactive'}</option>
              </select>
            </div>

            <div className="flex items-center space-x-2">
              <button className="flex items-center gap-2 px-3 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50">
                <Download size={16} />
                {currentLanguage === 'ru' ? 'Экспорт' : 'Export'}
              </button>
              <button className="flex items-center gap-2 px-3 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50">
                <Upload size={16} />
                {currentLanguage === 'ru' ? 'Импорт' : 'Import'}
              </button>
            </div>
          </div>
        </div>

        {/* Data Display */}
        {loading ? (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
            <RefreshCw className="h-8 w-8 animate-spin mx-auto mb-4 text-gray-400" />
            <p className="text-gray-600">
              {currentLanguage === 'ru' ? 'Загрузка справочных данных...' : 'Loading reference data...'}
            </p>
          </div>
        ) : filteredData.length === 0 ? (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
            <Database className="h-12 w-12 mx-auto mb-4 text-gray-400" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              {currentLanguage === 'ru' ? 'Данные не найдены' : 'No Data Found'}
            </h3>
            <p className="text-gray-600 mb-4">
              {currentLanguage === 'ru' ? 
                'Попробуйте изменить фильтры или добавить новые данные' : 
                'Try adjusting filters or add new data'
              }
            </p>
            <button
              onClick={() => setShowCreateModal(true)}
              className="flex items-center gap-2 mx-auto px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              <Plus size={16} />
              {currentLanguage === 'ru' ? 'Добавить первые данные' : 'Add First Data'}
            </button>
          </div>
        ) : (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {currentLanguage === 'ru' ? 'Ключ' : 'Key'}
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {currentLanguage === 'ru' ? 'Отображаемое имя' : 'Display Name'}
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {currentLanguage === 'ru' ? 'Значение' : 'Value'}
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {currentLanguage === 'ru' ? 'Тип' : 'Type'}
                    </th>
                    {supports1CSync && (
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        {currentLanguage === 'ru' ? '1С ЗУП' : '1C ZUP'}
                      </th>
                    )}
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {currentLanguage === 'ru' ? 'Статус' : 'Status'}
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {currentLanguage === 'ru' ? 'Действия' : 'Actions'}
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {filteredData.map((item) => (
                    <tr key={item.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        {item.key}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        <div>{currentLanguage === 'ru' && item.displayNameRu ? item.displayNameRu : item.displayName}</div>
                        {currentLanguage === 'en' && item.displayNameRu && (
                          <div className="text-xs text-gray-500 mt-1">RU: {item.displayNameRu}</div>
                        )}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-900">
                        <div className="max-w-xs truncate" title={item.value}>{item.value}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                        {item.dataType}
                      </td>
                      {supports1CSync && (
                        <td className="px-6 py-4 whitespace-nowrap">
                          {item.syncStatus && (
                            <span className={`px-2 py-1 text-xs font-medium rounded-full border ${
                              item.syncStatus === 'synced' ? 'text-green-700 bg-green-50 border-green-200' :
                              item.syncStatus === 'pending' ? 'text-yellow-700 bg-yellow-50 border-yellow-200' :
                              item.syncStatus === 'error' ? 'text-red-700 bg-red-50 border-red-200' :
                              'text-gray-700 bg-gray-50 border-gray-200'
                            }`}>
                              {item.syncStatus.toUpperCase()}
                            </span>
                          )}
                          {item.externalId && (
                            <div className="text-xs text-gray-500 mt-1">ID: {item.externalId}</div>
                          )}
                        </td>
                      )}
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                          item.isActive ? 'text-green-700 bg-green-100' : 'text-gray-700 bg-gray-100'
                        }`}>
                          {item.isActive ? (currentLanguage === 'ru' ? 'Активно' : 'Active') : (currentLanguage === 'ru' ? 'Неактивно' : 'Inactive')}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm space-x-2">
                        <button
                          onClick={() => {
                            setEditingItem(item);
                            setShowEditModal(true);
                          }}
                          className="text-blue-600 hover:text-blue-700"
                        >
                          <Edit3 size={16} />
                        </button>
                        {!item.isSystemManaged && (
                          <button className="text-red-600 hover:text-red-700">
                            <Trash2 size={16} />
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Create Modal */}
        {showCreateModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
              <div className="sticky top-0 bg-white border-b px-6 py-4 flex items-center justify-between">
                <h2 className="text-xl font-bold text-gray-900">
                  {currentLanguage === 'ru' ? 'Создать справочные данные' : 'Create Reference Data'}
                </h2>
                <button
                  onClick={() => {
                    setShowCreateModal(false);
                    resetNewItem();
                  }}
                  className="p-2 text-gray-500 hover:text-gray-700"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              <div className="p-6 space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      {currentLanguage === 'ru' ? 'Ключ' : 'Key'}
                    </label>
                    <input
                      type="text"
                      value={newItem.key || ''}
                      onChange={(e) => setNewItem({...newItem, key: e.target.value})}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder={currentLanguage === 'ru' ? 'Введите ключ' : 'Enter key'}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      {currentLanguage === 'ru' ? 'Тип данных' : 'Data Type'}
                    </label>
                    <select
                      value={newItem.dataType || 'string'}
                      onChange={(e) => setNewItem({...newItem, dataType: e.target.value as any})}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="string">{currentLanguage === 'ru' ? 'Строка' : 'String'}</option>
                      <option value="number">{currentLanguage === 'ru' ? 'Число' : 'Number'}</option>
                      <option value="boolean">{currentLanguage === 'ru' ? 'Логическое' : 'Boolean'}</option>
                      <option value="array">{currentLanguage === 'ru' ? 'Массив' : 'Array'}</option>
                      <option value="object">{currentLanguage === 'ru' ? 'Объект' : 'Object'}</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {currentLanguage === 'ru' ? 'Значение' : 'Value'}
                  </label>
                  <input
                    type="text"
                    value={newItem.value || ''}
                    onChange={(e) => setNewItem({...newItem, value: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder={currentLanguage === 'ru' ? 'Введите значение' : 'Enter value'}
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      {currentLanguage === 'ru' ? 'Отображаемое имя (RU)' : 'Display Name (RU)'}
                    </label>
                    <input
                      type="text"
                      value={newItem.displayNameRu || ''}
                      onChange={(e) => setNewItem({...newItem, displayNameRu: e.target.value})}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder={currentLanguage === 'ru' ? 'Русское название' : 'Russian name'}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      {currentLanguage === 'ru' ? 'Отображаемое имя (EN)' : 'Display Name (EN)'}
                    </label>
                    <input
                      type="text"
                      value={newItem.displayNameEn || ''}
                      onChange={(e) => setNewItem({...newItem, displayNameEn: e.target.value, displayName: e.target.value})}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder={currentLanguage === 'ru' ? 'Английское название' : 'English name'}
                    />
                  </div>
                </div>
              </div>

              <div className="sticky bottom-0 bg-gray-50 border-t px-6 py-4 flex items-center justify-end space-x-3">
                <button
                  onClick={() => {
                    setShowCreateModal(false);
                    resetNewItem();
                  }}
                  className="px-4 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  {currentLanguage === 'ru' ? 'Отмена' : 'Cancel'}
                </button>
                <button
                  onClick={() => handleSave(newItem)}
                  disabled={saving}
                  className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
                >
                  {saving ? (
                    <RefreshCw className="h-4 w-4 animate-spin" />
                  ) : (
                    <Save className="h-4 w-4" />
                  )}
                  {saving ? 
                    (currentLanguage === 'ru' ? 'Сохранение...' : 'Saving...') :
                    (currentLanguage === 'ru' ? 'Создать' : 'Create')
                  }
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Edit Modal */}
        {showEditModal && editingItem && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
              <div className="sticky top-0 bg-white border-b px-6 py-4 flex items-center justify-between">
                <h2 className="text-xl font-bold text-gray-900">
                  {currentLanguage === 'ru' ? 'Редактировать справочные данные' : 'Edit Reference Data'}
                </h2>
                <button
                  onClick={() => {
                    setShowEditModal(false);
                    setEditingItem(null);
                  }}
                  className="p-2 text-gray-500 hover:text-gray-700"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              <div className="p-6 space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      {currentLanguage === 'ru' ? 'Ключ' : 'Key'}
                    </label>
                    <input
                      type="text"
                      value={editingItem.key}
                      onChange={(e) => setEditingItem({...editingItem, key: e.target.value})}
                      disabled={editingItem.isSystemManaged}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      {currentLanguage === 'ru' ? 'Тип данных' : 'Data Type'}
                    </label>
                    <select
                      value={editingItem.dataType}
                      onChange={(e) => setEditingItem({...editingItem, dataType: e.target.value as any})}
                      disabled={editingItem.isSystemManaged}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
                    >
                      <option value="string">{currentLanguage === 'ru' ? 'Строка' : 'String'}</option>
                      <option value="number">{currentLanguage === 'ru' ? 'Число' : 'Number'}</option>
                      <option value="boolean">{currentLanguage === 'ru' ? 'Логическое' : 'Boolean'}</option>
                      <option value="array">{currentLanguage === 'ru' ? 'Массив' : 'Array'}</option>
                      <option value="object">{currentLanguage === 'ru' ? 'Объект' : 'Object'}</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {currentLanguage === 'ru' ? 'Значение' : 'Value'}
                  </label>
                  <input
                    type="text"
                    value={editingItem.value}
                    onChange={(e) => setEditingItem({...editingItem, value: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      {currentLanguage === 'ru' ? 'Отображаемое имя (RU)' : 'Display Name (RU)'}
                    </label>
                    <input
                      type="text"
                      value={editingItem.displayNameRu || ''}
                      onChange={(e) => setEditingItem({...editingItem, displayNameRu: e.target.value})}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      {currentLanguage === 'ru' ? 'Отображаемое имя (EN)' : 'Display Name (EN)'}
                    </label>
                    <input
                      type="text"
                      value={editingItem.displayNameEn || ''}
                      onChange={(e) => setEditingItem({...editingItem, displayNameEn: e.target.value, displayName: e.target.value})}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>

                <div className="flex items-center space-x-6">
                  <div className="flex items-center">
                    <input
                      type="checkbox"
                      id="editItemActive"
                      checked={editingItem.isActive}
                      onChange={(e) => setEditingItem({...editingItem, isActive: e.target.checked})}
                      className="mr-3 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    />
                    <label htmlFor="editItemActive" className="text-sm font-medium text-gray-700">
                      {currentLanguage === 'ru' ? 'Активно' : 'Active'}
                    </label>
                  </div>
                </div>
              </div>

              <div className="sticky bottom-0 bg-gray-50 border-t px-6 py-4 flex items-center justify-end space-x-3">
                <button
                  onClick={() => {
                    setShowEditModal(false);
                    setEditingItem(null);
                  }}
                  className="px-4 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  {currentLanguage === 'ru' ? 'Отмена' : 'Cancel'}
                </button>
                <button
                  onClick={() => handleSave(editingItem)}
                  disabled={saving}
                  className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
                >
                  {saving ? (
                    <RefreshCw className="h-4 w-4 animate-spin" />
                  ) : (
                    <Save className="h-4 w-4" />
                  )}
                  {saving ? 
                    (currentLanguage === 'ru' ? 'Сохранение...' : 'Saving...') :
                    (currentLanguage === 'ru' ? 'Сохранить изменения' : 'Save Changes')
                  }
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Spec17ReferenceDataUI;