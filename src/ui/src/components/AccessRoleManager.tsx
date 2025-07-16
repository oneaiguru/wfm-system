import React, { useState, useEffect } from 'react';
import {
  Settings,
  Users,
  Shield,
  Plus,
  Edit,
  Trash2,
  Save,
  X,
  Check,
  AlertTriangle,
  Search,
  Filter,
  Globe,
  Key,
  UserCheck,
  Eye,
  EyeOff,
  MoreVertical,
  Copy,
  CheckCircle,
  XCircle
} from 'lucide-react';
import realAccessRoleService, { AccessRole, Permission, PermissionGroup, UserRoleAssignment } from '../services/realAccessRoleService';

// Russian translations per BDD requirements
const translations = {
  ru: {
    title: 'Управление ролями и правами доступа',
    subtitle: 'Создание и настройка пользовательских ролей',
    systemRoles: 'Системные роли',
    businessRoles: 'Бизнес роли',
    customRoles: 'Пользовательские роли',
    createRole: 'Создать роль',
    editRole: 'Редактировать роль',
    deleteRole: 'Удалить роль',
    assignRole: 'Назначить роль',
    permissions: 'Разрешения',
    users: 'Пользователи',
    search: 'Поиск...',
    filter: 'Фильтр',
    save: 'Сохранить',
    cancel: 'Отменить',
    apply: 'Применить',
    fields: {
      name: 'Название роли',
      description: 'Описание',
      category: 'Категория',
      active: 'Активная',
      default: 'По умолчанию',
      permissions: 'Разрешения'
    },
    categories: {
      system: 'Системная',
      business: 'Бизнес',
      custom: 'Пользовательская'
    },
    permissionCategories: {
      personnel: 'Управление персоналом',
      planning: 'Планирование',
      reporting: 'Отчетность',
      system: 'Системное администрирование',
      monitoring: 'Мониторинг'
    },
    permissionLevels: {
      none: 'Нет доступа',
      view: 'Просмотр',
      edit: 'Редактирование',
      full: 'Полный доступ'
    },
    defaultRoles: {
      administrator: 'Администратор',
      seniorOperator: 'Старший оператор',
      operator: 'Оператор',
      qualityManager: 'Менеджер качества'
    },
    actions: {
      view: 'Просмотреть',
      edit: 'Редактировать',
      delete: 'Удалить',
      duplicate: 'Дублировать',
      assign: 'Назначить',
      unassign: 'Снять назначение'
    },
    validation: {
      nameRequired: 'Название роли обязательно',
      nameExists: 'Роль с таким именем уже существует',
      nameLength: 'Название должно быть 3-50 символов',
      descriptionLength: 'Описание не более 500 символов',
      conflictingPermissions: 'Конфликтующие разрешения',
      insufficientPermissions: 'Недостаточные разрешения',
      excessivePermissions: 'Избыточные разрешения',
      minimumAccess: 'Требуется минимум доступ LOGIN'
    },
    status: {
      loading: 'Загрузка...',
      saving: 'Сохранение...',
      saved: 'Сохранено',
      error: 'Ошибка',
      success: 'Успешно',
      active: 'Активна',
      inactive: 'Неактивна',
      default: 'По умолчанию'
    },
    stats: {
      totalRoles: 'Всего ролей',
      activeRoles: 'Активных ролей',
      assignedUsers: 'Назначенных пользователей',
      permissions: 'Разрешений'
    }
  },
  en: {
    title: 'Role and Access Rights Management',
    subtitle: 'Create and configure user roles',
    systemRoles: 'System Roles',
    businessRoles: 'Business Roles',
    customRoles: 'Custom Roles',
    createRole: 'Create Role',
    editRole: 'Edit Role',
    deleteRole: 'Delete Role',
    assignRole: 'Assign Role',
    permissions: 'Permissions',
    users: 'Users',
    search: 'Search...',
    filter: 'Filter',
    save: 'Save',
    cancel: 'Cancel',
    apply: 'Apply',
    fields: {
      name: 'Role Name',
      description: 'Description',
      category: 'Category',
      active: 'Active',
      default: 'Default',
      permissions: 'Permissions'
    },
    categories: {
      system: 'System',
      business: 'Business',
      custom: 'Custom'
    },
    permissionCategories: {
      personnel: 'Personnel Management',
      planning: 'Planning',
      reporting: 'Reporting',
      system: 'System Administration',
      monitoring: 'Monitoring'
    },
    permissionLevels: {
      none: 'No Access',
      view: 'View Only',
      edit: 'Edit',
      full: 'Full Access'
    },
    defaultRoles: {
      administrator: 'Administrator',
      seniorOperator: 'Senior Operator',
      operator: 'Operator',
      qualityManager: 'Quality Manager'
    },
    actions: {
      view: 'View',
      edit: 'Edit',
      delete: 'Delete',
      duplicate: 'Duplicate',
      assign: 'Assign',
      unassign: 'Unassign'
    },
    validation: {
      nameRequired: 'Role name is required',
      nameExists: 'Role name already exists',
      nameLength: 'Name must be 3-50 characters',
      descriptionLength: 'Description max 500 characters',
      conflictingPermissions: 'Conflicting permissions',
      insufficientPermissions: 'Insufficient permissions',
      excessivePermissions: 'Excessive permissions',
      minimumAccess: 'Minimum LOGIN access required'
    },
    status: {
      loading: 'Loading...',
      saving: 'Saving...',
      saved: 'Saved',
      error: 'Error',
      success: 'Success',
      active: 'Active',
      inactive: 'Inactive',
      default: 'Default'
    },
    stats: {
      totalRoles: 'Total Roles',
      activeRoles: 'Active Roles',
      assignedUsers: 'Assigned Users',
      permissions: 'Permissions'
    }
  }
};

interface AccessRoleManagerProps {
  initialView?: 'roles' | 'permissions' | 'assignments';
  onRoleSelect?: (role: AccessRole) => void;
  onClose?: () => void;
}

const AccessRoleManager: React.FC<AccessRoleManagerProps> = ({
  initialView = 'roles',
  onRoleSelect,
  onClose
}) => {
  const [language, setLanguage] = useState<'ru' | 'en'>('ru');
  const [activeView, setActiveView] = useState<'roles' | 'permissions' | 'assignments'>(initialView);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState('');
  const [filterCategory, setFilterCategory] = useState<string>('all');
  
  // Role management state
  const [roles, setRoles] = useState<AccessRole[]>([]);
  const [selectedRole, setSelectedRole] = useState<AccessRole | null>(null);
  const [isCreating, setIsCreating] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  
  // Permission management state
  const [permissionGroups, setPermissionGroups] = useState<PermissionGroup[]>([]);
  const [selectedPermissions, setSelectedPermissions] = useState<Permission[]>([]);
  
  // Form state
  const [formData, setFormData] = useState<Partial<AccessRole>>({
    name: '',
    description: '',
    category: 'custom',
    isActive: true,
    isDefault: false,
    permissions: []
  });
  
  // Validation state
  const [validationErrors, setValidationErrors] = useState<string[]>([]);
  
  // Statistics
  const [stats, setStats] = useState({
    totalRoles: 0,
    activeRoles: 0,
    assignedUsers: 0,
    totalPermissions: 0
  });
  
  const t = translations[language];

  useEffect(() => {
    loadInitialData();
  }, []);

  const loadInitialData = async () => {
    setIsLoading(true);
    setError('');
    
    try {
      const [rolesResult, permissionsResult, statsResult] = await Promise.all([
        realAccessRoleService.getAllRoles(),
        realAccessRoleService.getPermissionGroups(),
        realAccessRoleService.getRoleUsageStats()
      ]);
      
      if (rolesResult.success && rolesResult.data) {
        setRoles(rolesResult.data);
        setStats(prev => ({
          ...prev,
          totalRoles: rolesResult.data.length,
          activeRoles: rolesResult.data.filter(r => r.isActive).length
        }));
      }
      
      if (permissionsResult.success && permissionsResult.data) {
        setPermissionGroups(permissionsResult.data);
        const totalPermissions = permissionsResult.data.reduce((sum, group) => sum + group.permissions.length, 0);
        setStats(prev => ({ ...prev, totalPermissions }));
      }
      
      if (statsResult.success && statsResult.data) {
        const assignedUsers = statsResult.data.reduce((sum, stat) => sum + stat.userCount, 0);
        setStats(prev => ({ ...prev, assignedUsers }));
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load data');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateRole = () => {
    setIsCreating(true);
    setIsEditing(false);
    setSelectedRole(null);
    setFormData({
      name: '',
      description: '',
      category: 'custom',
      isActive: true,
      isDefault: false,
      permissions: []
    });
    setValidationErrors([]);
  };

  const handleEditRole = (role: AccessRole) => {
    setIsEditing(true);
    setIsCreating(false);
    setSelectedRole(role);
    setFormData(role);
    setSelectedPermissions(role.permissions || []);
    setValidationErrors([]);
  };

  const handleSaveRole = async () => {
    if (!(await validateForm())) {
      return;
    }
    
    setIsSaving(true);
    setError('');
    
    try {
      let result;
      
      if (isCreating) {
        result = await realAccessRoleService.createRole({
          ...formData,
          permissions: selectedPermissions
        } as Omit<AccessRole, 'id' | 'createdDate' | 'lastModified'>);
      } else if (selectedRole) {
        result = await realAccessRoleService.updateRole(selectedRole.id, {
          ...formData,
          permissions: selectedPermissions
        });
      }
      
      if (result?.success && result.data) {
        if (isCreating) {
          setRoles(prev => [...prev, result.data]);
        } else {
          setRoles(prev => prev.map(r => r.id === result.data.id ? result.data : r));
        }
        
        setIsCreating(false);
        setIsEditing(false);
        setSelectedRole(null);
        
        if (onRoleSelect && result.data) {
          onRoleSelect(result.data);
        }
      } else {
        setError(result?.error || 'Failed to save role');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save role');
    } finally {
      setIsSaving(false);
    }
  };

  const validateForm = async (): Promise<boolean> => {
    const errors: string[] = [];
    
    if (!formData.name?.trim()) {
      errors.push(t.validation.nameRequired);
    }
    
    if (formData.name && (formData.name.length < 3 || formData.name.length > 50)) {
      errors.push(t.validation.nameLength);
    }
    
    if (formData.description && formData.description.length > 500) {
      errors.push(t.validation.descriptionLength);
    }
    
    // Check for name uniqueness
    if (formData.name && (!selectedRole || selectedRole.name !== formData.name)) {
      const existingRole = roles.find(r => r.name === formData.name);
      if (existingRole) {
        errors.push(t.validation.nameExists);
      }
    }
    
    setValidationErrors(errors);
    
    // Server-side validation
    if (errors.length === 0) {
      const validationResult = await realAccessRoleService.validateRole({
        ...formData,
        permissions: selectedPermissions
      });
      
      if (validationResult.success && validationResult.data) {
        if (!validationResult.data.valid) {
          setValidationErrors(validationResult.data.violations);
          return false;
        }
      }
    }
    
    return errors.length === 0;
  };

  const handleDeleteRole = async (roleId: string) => {
    if (!confirm('Вы уверены, что хотите удалить эту роль?')) {
      return;
    }
    
    try {
      const result = await realAccessRoleService.deleteRole(roleId);
      if (result.success) {
        setRoles(prev => prev.filter(r => r.id !== roleId));
      } else {
        setError(result.error || 'Failed to delete role');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete role');
    }
  };

  const handlePermissionToggle = (permission: Permission) => {
    setSelectedPermissions(prev => {
      const exists = prev.find(p => p.id === permission.id);
      if (exists) {
        return prev.filter(p => p.id !== permission.id);
      } else {
        return [...prev, permission];
      }
    });
  };

  const getFilteredRoles = () => {
    return roles.filter(role => {
      const matchesSearch = role.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          role.description.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesCategory = filterCategory === 'all' || role.category === filterCategory;
      return matchesSearch && matchesCategory;
    });
  };

  const getRolesBadgeColor = (role: AccessRole) => {
    if (!role.isActive) return 'bg-gray-100 text-gray-600';
    if (role.category === 'system') return 'bg-blue-100 text-blue-800';
    if (role.category === 'business') return 'bg-green-100 text-green-800';
    return 'bg-purple-100 text-purple-800';
  };

  const getPermissionLevelColor = (level: string) => {
    switch (level) {
      case 'none': return 'text-gray-500';
      case 'view': return 'text-blue-600';
      case 'edit': return 'text-orange-600';
      case 'full': return 'text-green-600';
      default: return 'text-gray-500';
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <span className="ml-2 text-gray-600">{t.status.loading}</span>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-lg h-full flex flex-col">
      {/* Header */}
      <div className="border-b px-6 py-4 flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-gray-900">{t.title}</h2>
          <p className="text-sm text-gray-600">{t.subtitle}</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setLanguage(language === 'ru' ? 'en' : 'ru')}
            className="p-2 text-gray-500 hover:text-gray-700"
          >
            <Globe className="h-4 w-4" />
          </button>
          {onClose && (
            <button
              onClick={onClose}
              className="p-2 text-gray-500 hover:text-gray-700"
            >
              <X className="h-5 w-5" />
            </button>
          )}
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="mx-6 mt-4 bg-red-50 border border-red-200 rounded-lg p-4 flex items-center">
          <AlertTriangle className="h-5 w-5 text-red-600 mr-3" />
          <div>
            <p className="font-medium text-red-800">{t.status.error}</p>
            <p className="text-red-700 text-sm">{error}</p>
          </div>
        </div>
      )}

      {/* Statistics */}
      <div className="px-6 py-4 bg-gray-50 border-b">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="text-center">
            <div className="text-2xl font-bold text-gray-900">{stats.totalRoles}</div>
            <div className="text-sm text-gray-600">{t.stats.totalRoles}</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-green-600">{stats.activeRoles}</div>
            <div className="text-sm text-gray-600">{t.stats.activeRoles}</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-blue-600">{stats.assignedUsers}</div>
            <div className="text-sm text-gray-600">{t.stats.assignedUsers}</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-purple-600">{stats.totalPermissions}</div>
            <div className="text-sm text-gray-600">{t.stats.permissions}</div>
          </div>
        </div>
      </div>

      {/* Tab Navigation */}
      <div className="border-b">
        <nav className="flex px-6">
          <button
            onClick={() => setActiveView('roles')}
            className={`py-3 px-4 border-b-2 font-medium text-sm ${
              activeView === 'roles'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            <Shield className="h-4 w-4 inline mr-2" />
            {t.systemRoles}
          </button>
          <button
            onClick={() => setActiveView('permissions')}
            className={`py-3 px-4 border-b-2 font-medium text-sm ${
              activeView === 'permissions'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            <Key className="h-4 w-4 inline mr-2" />
            {t.permissions}
          </button>
          <button
            onClick={() => setActiveView('assignments')}
            className={`py-3 px-4 border-b-2 font-medium text-sm ${
              activeView === 'assignments'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            <UserCheck className="h-4 w-4 inline mr-2" />
            {t.users}
          </button>
        </nav>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-hidden flex">
        {/* Main Content */}
        <div className="flex-1 overflow-y-auto">
          {activeView === 'roles' && (
            <div className="p-6">
              {/* Controls */}
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-4">
                  <div className="relative">
                    <Search className="h-4 w-4 absolute left-3 top-3 text-gray-400" />
                    <input
                      type="text"
                      placeholder={t.search}
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  <select
                    value={filterCategory}
                    onChange={(e) => setFilterCategory(e.target.value)}
                    className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="all">Все категории</option>
                    <option value="system">{t.categories.system}</option>
                    <option value="business">{t.categories.business}</option>
                    <option value="custom">{t.categories.custom}</option>
                  </select>
                </div>
                <button
                  onClick={handleCreateRole}
                  className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  <Plus className="h-4 w-4" />
                  {t.createRole}
                </button>
              </div>

              {/* Roles List */}
              <div className="space-y-4">
                {getFilteredRoles().map((role) => (
                  <div
                    key={role.id}
                    className="border rounded-lg p-4 hover:shadow-md transition-shadow"
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <h3 className="text-lg font-medium text-gray-900">{role.name}</h3>
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${getRolesBadgeColor(role)}`}>
                            {t.categories[role.category]}
                          </span>
                          {role.isDefault && (
                            <span className="px-2 py-1 bg-yellow-100 text-yellow-800 rounded-full text-xs font-medium">
                              {t.status.default}
                            </span>
                          )}
                        </div>
                        <p className="text-gray-600 text-sm mb-2">{role.description}</p>
                        <div className="flex items-center gap-4 text-sm text-gray-500">
                          <span>{role.permissions?.length || 0} {t.permissions.toLowerCase()}</span>
                          <span className={role.isActive ? 'text-green-600' : 'text-gray-400'}>
                            {role.isActive ? t.status.active : t.status.inactive}
                          </span>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => handleEditRole(role)}
                          className="p-2 text-gray-500 hover:text-gray-700"
                        >
                          <Edit className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleDeleteRole(role.id)}
                          className="p-2 text-red-500 hover:text-red-700"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeView === 'permissions' && (
            <div className="p-6">
              <div className="space-y-6">
                {permissionGroups.map((group) => (
                  <div key={group.id} className="border rounded-lg p-4">
                    <h3 className="text-lg font-medium text-gray-900 mb-4">
                      {t.permissionCategories[group.category as keyof typeof t.permissionCategories] || group.name}
                    </h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {group.permissions.map((permission) => (
                        <div key={permission.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                          <div>
                            <h4 className="font-medium text-gray-900">{permission.name}</h4>
                            <p className="text-sm text-gray-600">{permission.description}</p>
                          </div>
                          <span className={`font-medium ${getPermissionLevelColor(permission.level)}`}>
                            {t.permissionLevels[permission.level as keyof typeof t.permissionLevels]}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeView === 'assignments' && (
            <div className="p-6">
              <div className="text-center py-12">
                <Users className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">Назначение ролей</h3>
                <p className="text-gray-600">Функциональность назначения ролей пользователям</p>
              </div>
            </div>
          )}
        </div>

        {/* Side Panel for Role Creation/Editing */}
        {(isCreating || isEditing) && (
          <div className="w-96 border-l bg-gray-50 p-6 overflow-y-auto">
            <div className="mb-6">
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                {isCreating ? t.createRole : t.editRole}
              </h3>
              <p className="text-sm text-gray-600">
                {isCreating ? 'Создание новой роли' : 'Редактирование существующей роли'}
              </p>
            </div>

            {/* Form */}
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t.fields.name}
                </label>
                <input
                  type="text"
                  value={formData.name || ''}
                  onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Введите название роли"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t.fields.description}
                </label>
                <textarea
                  value={formData.description || ''}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows={3}
                  placeholder="Описание роли"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t.fields.category}
                </label>
                <select
                  value={formData.category || 'custom'}
                  onChange={(e) => setFormData(prev => ({ ...prev, category: e.target.value as 'system' | 'business' | 'custom' }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="custom">{t.categories.custom}</option>
                  <option value="business">{t.categories.business}</option>
                  <option value="system">{t.categories.system}</option>
                </select>
              </div>

              <div className="flex items-center gap-4">
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={formData.isActive || false}
                    onChange={(e) => setFormData(prev => ({ ...prev, isActive: e.target.checked }))}
                    className="mr-2"
                  />
                  <span className="text-sm text-gray-700">{t.fields.active}</span>
                </label>
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={formData.isDefault || false}
                    onChange={(e) => setFormData(prev => ({ ...prev, isDefault: e.target.checked }))}
                    className="mr-2"
                  />
                  <span className="text-sm text-gray-700">{t.fields.default}</span>
                </label>
              </div>

              {/* Permissions Selection */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t.fields.permissions}
                </label>
                <div className="max-h-64 overflow-y-auto border border-gray-300 rounded-lg p-3">
                  {permissionGroups.map((group) => (
                    <div key={group.id} className="mb-4">
                      <h4 className="font-medium text-gray-900 mb-2">
                        {t.permissionCategories[group.category as keyof typeof t.permissionCategories] || group.name}
                      </h4>
                      <div className="space-y-2">
                        {group.permissions.map((permission) => (
                          <label key={permission.id} className="flex items-center">
                            <input
                              type="checkbox"
                              checked={selectedPermissions.some(p => p.id === permission.id)}
                              onChange={() => handlePermissionToggle(permission)}
                              className="mr-2"
                            />
                            <span className="text-sm text-gray-700">{permission.name}</span>
                          </label>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Validation Errors */}
              {validationErrors.length > 0 && (
                <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                  <div className="flex items-center mb-2">
                    <AlertTriangle className="h-5 w-5 text-red-600 mr-2" />
                    <p className="font-medium text-red-800">Ошибки валидации:</p>
                  </div>
                  <ul className="text-red-700 text-sm space-y-1">
                    {validationErrors.map((error, index) => (
                      <li key={index}>• {error}</li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Actions */}
              <div className="flex items-center gap-3 pt-4">
                <button
                  onClick={handleSaveRole}
                  disabled={isSaving}
                  className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
                >
                  {isSaving ? (
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  ) : (
                    <Save className="h-4 w-4" />
                  )}
                  {isSaving ? t.status.saving : t.save}
                </button>
                <button
                  onClick={() => {
                    setIsCreating(false);
                    setIsEditing(false);
                    setSelectedRole(null);
                  }}
                  className="px-4 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  {t.cancel}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default AccessRoleManager;