import React, { useState, useEffect } from 'react';
import {
  Users,
  UserPlus,
  UserMinus,
  UserCheck,
  ArrowRight,
  Calendar,
  Clock,
  Building,
  Target,
  CheckCircle,
  AlertTriangle,
  Search,
  Filter,
  Download,
  Upload,
  RefreshCw,
  Settings,
  Eye,
  Edit3,
  Trash2,
  Copy,
  RotateCcw,
  Plus,
  Minus,
  X,
  Check,
  Calculator,
  MapPin,
  Layers,
  Activity,
  TrendingUp,
  BarChart3,
  Grid,
  List,
  Globe
} from 'lucide-react';

// SPEC-32: Mass Assignment Operations Dashboard
// 75% reuse from BulkAdjustments.tsx - adapted for employee assignment operations
// Focus: Mass assignment operations for HR managers and team leads (30+ daily users)

interface EmployeeAssignment {
  id: string;
  employeeId: string;
  employeeName: string;
  employeeNameRu: string;
  currentTeamId?: string;
  currentTeamName?: string;
  currentShiftId?: string;
  currentShiftName?: string;
  currentLocationId?: string;
  currentLocationName?: string;
  startDate: string;
  endDate?: string;
  status: 'active' | 'pending' | 'completed' | 'cancelled';
  isSelected: boolean;
  conflictLevel: 'none' | 'warning' | 'error';
  priority: 'low' | 'medium' | 'high' | 'urgent';
  metadata: {
    lastModified: string;
    modifiedBy: string;
    assignmentReason?: string;
    notes?: string;
  };
}

interface MassAssignmentOperation {
  type: 'assign_team' | 'assign_shift' | 'assign_location' | 'transfer' | 'reassign' | 'bulk_schedule';
  targetId: string;
  targetName: string;
  startDate?: string;
  endDate?: string;
  reason?: string;
  preserveExisting?: boolean;
  notifyEmployees?: boolean;
}

interface AssignmentConflict {
  employeeId: string;
  employeeName: string;
  conflictType: 'schedule' | 'skill' | 'capacity' | 'policy';
  conflictDescription: string;
  severity: 'warning' | 'error';
  canOverride: boolean;
}

interface AssignmentPreview {
  employeeId: string;
  employeeName: string;
  currentAssignment: string;
  newAssignment: string;
  changeDescription: string;
  impact: 'positive' | 'neutral' | 'negative';
  conflicts: AssignmentConflict[];
}

// Russian translations per BDD requirements
const translations = {
  ru: {
    title: 'Массовые операции назначения',
    subtitle: 'Управление массовыми назначениями сотрудников',
    selectedCount: 'выбрано',
    clearSelection: 'Очистить выбор',
    operationType: 'Тип операции',
    assignTeam: 'Назначить команду',
    assignShift: 'Назначить смену',
    assignLocation: 'Назначить локацию',
    transfer: 'Перевести',
    reassign: 'Переназначить',
    bulkSchedule: 'Массовое планирование',
    selectTarget: 'Выберите цель назначения',
    startDate: 'Дата начала',
    endDate: 'Дата окончания',
    reason: 'Причина назначения',
    preserveExisting: 'Сохранить существующие назначения',
    notifyEmployees: 'Уведомить сотрудников',
    previewChanges: 'Предварительный просмотр',
    applyChanges: 'Применить изменения',
    conflicts: 'Конфликты',
    warnings: 'Предупреждения',
    employee: 'Сотрудник',
    current: 'Текущее',
    new: 'Новое',
    change: 'Изменение',
    impact: 'Влияние',
    selectEmployees: 'Выберите сотрудников в таблице для массовых операций',
    operationTypes: {
      assign_team: {
        label: 'Назначить команду',
        desc: 'Назначить сотрудников в команду'
      },
      assign_shift: {
        label: 'Назначить смену',
        desc: 'Назначить рабочую смену'
      },
      assign_location: {
        label: 'Назначить локацию',
        desc: 'Назначить рабочее место'
      },
      transfer: {
        label: 'Перевести',
        desc: 'Перевести в другое подразделение'
      },
      reassign: {
        label: 'Переназначить',
        desc: 'Изменить текущие назначения'
      },
      bulk_schedule: {
        label: 'Массовое планирование',
        desc: 'Создать расписание для группы'
      }
    },
    quickActions: {
      title: 'Быстрые действия',
      assignMainTeam: 'Основная команда',
      assignDayShift: 'Дневная смена',
      assignOffice: 'Офис',
      clearAssignments: 'Очистить назначения'
    },
    validation: {
      selectEmployees: 'Выберите сотрудников',
      selectTarget: 'Выберите цель назначения',
      selectDates: 'Укажите даты',
      invalidDateRange: 'Неверный диапазон дат',
      conflictResolution: 'Требуется разрешение конфликтов'
    },
    status: {
      active: 'Активный',
      pending: 'Ожидает',
      completed: 'Завершен',
      cancelled: 'Отменен'
    },
    priority: {
      low: 'Низкий',
      medium: 'Средний',
      high: 'Высокий',
      urgent: 'Срочный'
    },
    conflictTypes: {
      schedule: 'Конфликт расписания',
      skill: 'Недостаток навыков',
      capacity: 'Превышение мощности',
      policy: 'Нарушение политики'
    }
  }
};

interface Spec32MassAssignmentOperationsProps {
  selectedAssignments: EmployeeAssignment[];
  availableTeams: { id: string; name: string; nameRu: string; capacity: number; currentCount: number; }[];
  availableShifts: { id: string; name: string; nameRu: string; startTime: string; endTime: string; }[];
  availableLocations: { id: string; name: string; nameRu: string; type: string; capacity: number; }[];
  onApplyMassOperation: (operation: MassAssignmentOperation, assignments: EmployeeAssignment[]) => Promise<{ success: boolean; conflicts?: AssignmentConflict[]; }>;
  onClearSelection: () => void;
  onValidateAssignments: (operation: MassAssignmentOperation, assignments: EmployeeAssignment[]) => Promise<AssignmentConflict[]>;
  loading?: boolean;
  disabled?: boolean;
}

const Spec32MassAssignmentOperations: React.FC<Spec32MassAssignmentOperationsProps> = ({
  selectedAssignments,
  availableTeams,
  availableShifts,
  availableLocations,
  onApplyMassOperation,
  onClearSelection,
  onValidateAssignments,
  loading = false,
  disabled = false
}) => {
  // Reused state pattern from BulkAdjustments.tsx (75% reuse)
  const [operation, setOperation] = useState<MassAssignmentOperation['type']>('assign_team');
  const [targetId, setTargetId] = useState<string>('');
  const [targetName, setTargetName] = useState<string>('');
  const [startDate, setStartDate] = useState<string>('');
  const [endDate, setEndDate] = useState<string>('');
  const [reason, setReason] = useState<string>('');
  const [preserveExisting, setPreserveExisting] = useState<boolean>(false);
  const [notifyEmployees, setNotifyEmployees] = useState<boolean>(true);
  const [previewMode, setPreviewMode] = useState<boolean>(false);
  const [validationError, setValidationError] = useState<string>('');
  const [conflicts, setConflicts] = useState<AssignmentConflict[]>([]);
  const [assignmentPreviews, setAssignmentPreviews] = useState<AssignmentPreview[]>([]);

  // Statistics
  const [stats, setStats] = useState({
    totalSelected: selectedAssignments.length,
    activeAssignments: selectedAssignments.filter(a => a.status === 'active').length,
    pendingAssignments: selectedAssignments.filter(a => a.status === 'pending').length,
    conflictCount: selectedAssignments.filter(a => a.conflictLevel !== 'none').length,
    highPriorityCount: selectedAssignments.filter(a => a.priority === 'high' || a.priority === 'urgent').length
  });

  // Update statistics when selection changes
  useEffect(() => {
    setStats({
      totalSelected: selectedAssignments.length,
      activeAssignments: selectedAssignments.filter(a => a.status === 'active').length,
      pendingAssignments: selectedAssignments.filter(a => a.status === 'pending').length,
      conflictCount: selectedAssignments.filter(a => a.conflictLevel !== 'none').length,
      highPriorityCount: selectedAssignments.filter(a => a.priority === 'high' || a.priority === 'urgent').length
    });
  }, [selectedAssignments]);

  // Validation logic adapted from BulkAdjustments.tsx
  const validateOperation = (op: MassAssignmentOperation): string => {
    if (!targetId || !targetName) {
      return translations.ru.validation.selectTarget;
    }

    if (!startDate) {
      return translations.ru.validation.selectDates;
    }

    if (endDate && new Date(endDate) <= new Date(startDate)) {
      return translations.ru.validation.invalidDateRange;
    }

    if (conflicts.some(c => c.severity === 'error' && !c.canOverride)) {
      return translations.ru.validation.conflictResolution;
    }

    return '';
  };

  // Preview calculation adapted from BulkAdjustments.tsx
  const generatePreview = async (op: MassAssignmentOperation): Promise<AssignmentPreview[]> => {
    const previews: AssignmentPreview[] = selectedAssignments.map(assignment => {
      let currentAssignment = '';
      let newAssignment = '';
      let changeDescription = '';
      let impact: 'positive' | 'neutral' | 'negative' = 'neutral';

      switch (op.type) {
        case 'assign_team':
          currentAssignment = assignment.currentTeamName || 'Не назначено';
          newAssignment = targetName;
          changeDescription = `Назначение в команду ${targetName}`;
          impact = assignment.currentTeamId ? 'neutral' : 'positive';
          break;
        case 'assign_shift':
          currentAssignment = assignment.currentShiftName || 'Не назначено';
          newAssignment = targetName;
          changeDescription = `Назначение на смену ${targetName}`;
          impact = 'positive';
          break;
        case 'assign_location':
          currentAssignment = assignment.currentLocationName || 'Не назначено';
          newAssignment = targetName;
          changeDescription = `Назначение на локацию ${targetName}`;
          impact = 'positive';
          break;
        case 'transfer':
          currentAssignment = `${assignment.currentTeamName || 'Не назначено'}`;
          newAssignment = targetName;
          changeDescription = `Перевод в ${targetName}`;
          impact = assignment.currentTeamId !== targetId ? 'neutral' : 'positive';
          break;
        case 'reassign':
          currentAssignment = 'Текущие назначения';
          newAssignment = `Новые назначения (${targetName})`;
          changeDescription = `Переназначение: ${targetName}`;
          impact = 'neutral';
          break;
        case 'bulk_schedule':
          currentAssignment = 'Без расписания';
          newAssignment = `Расписание ${targetName}`;
          changeDescription = `Создание расписания: ${targetName}`;
          impact = 'positive';
          break;
      }

      return {
        employeeId: assignment.employeeId,
        employeeName: assignment.employeeNameRu || assignment.employeeName,
        currentAssignment,
        newAssignment,
        changeDescription,
        impact,
        conflicts: conflicts.filter(c => c.employeeId === assignment.employeeId)
      };
    });

    return previews;
  };

  // Event handlers adapted from BulkAdjustments.tsx
  const handlePreview = async () => {
    const op: MassAssignmentOperation = {
      type: operation,
      targetId,
      targetName,
      startDate: startDate || undefined,
      endDate: endDate || undefined,
      reason: reason || undefined,
      preserveExisting,
      notifyEmployees
    };

    const error = validateOperation(op);
    if (error) {
      setValidationError(error);
      return;
    }

    try {
      // Validate assignments and get conflicts
      const validationConflicts = await onValidateAssignments(op, selectedAssignments);
      setConflicts(validationConflicts);

      // Generate preview
      const previews = await generatePreview(op);
      setAssignmentPreviews(previews);

      setValidationError('');
      setPreviewMode(true);
    } catch (error) {
      setValidationError('Ошибка при создании предварительного просмотра');
    }
  };

  const handleApply = async () => {
    const op: MassAssignmentOperation = {
      type: operation,
      targetId,
      targetName,
      startDate: startDate || undefined,
      endDate: endDate || undefined,
      reason: reason || undefined,
      preserveExisting,
      notifyEmployees
    };

    const error = validateOperation(op);
    if (error) {
      setValidationError(error);
      return;
    }

    try {
      const result = await onApplyMassOperation(op, selectedAssignments);
      
      if (result.success) {
        // Reset form on success
        setTargetId('');
        setTargetName('');
        setStartDate('');
        setEndDate('');
        setReason('');
        setValidationError('');
        setPreviewMode(false);
        setConflicts([]);
        setAssignmentPreviews([]);
      } else if (result.conflicts) {
        setConflicts(result.conflicts);
        setValidationError('Обнаружены конфликты назначений');
      }
    } catch (error) {
      setValidationError('Ошибка при применении операций назначения');
    }
  };

  const getOperationIcon = (type: MassAssignmentOperation['type']) => {
    switch (type) {
      case 'assign_team': return <Users className="w-4 h-4" />;
      case 'assign_shift': return <Clock className="w-4 h-4" />;
      case 'assign_location': return <MapPin className="w-4 h-4" />;
      case 'transfer': return <ArrowRight className="w-4 h-4" />;
      case 'reassign': return <RefreshCw className="w-4 h-4" />;
      case 'bulk_schedule': return <Calendar className="w-4 h-4" />;
      default: return <Users className="w-4 h-4" />;
    }
  };

  const getTargetOptions = () => {
    switch (operation) {
      case 'assign_team':
      case 'transfer':
        return availableTeams.map(team => ({ id: team.id, name: team.nameRu || team.name, extra: `${team.currentCount}/${team.capacity}` }));
      case 'assign_shift':
        return availableShifts.map(shift => ({ id: shift.id, name: shift.nameRu || shift.name, extra: `${shift.startTime}-${shift.endTime}` }));
      case 'assign_location':
        return availableLocations.map(location => ({ id: location.id, name: location.nameRu || location.name, extra: location.type }));
      case 'reassign':
      case 'bulk_schedule':
        return [
          ...availableTeams.map(team => ({ id: team.id, name: `Команда: ${team.nameRu || team.name}`, extra: '' })),
          ...availableShifts.map(shift => ({ id: shift.id, name: `Смена: ${shift.nameRu || shift.name}`, extra: '' })),
          ...availableLocations.map(location => ({ id: location.id, name: `Локация: ${location.nameRu || location.name}`, extra: '' }))
        ];
      default:
        return [];
    }
  };

  // Quick actions adapted from BulkAdjustments.tsx
  const quickActions = [
    { 
      label: translations.ru.quickActions.assignMainTeam, 
      op: 'assign_team', 
      targetId: availableTeams.find(t => t.name.toLowerCase().includes('main') || t.name.toLowerCase().includes('основная'))?.id || availableTeams[0]?.id || '',
      targetName: availableTeams.find(t => t.name.toLowerCase().includes('main') || t.name.toLowerCase().includes('основная'))?.nameRu || availableTeams[0]?.nameRu || ''
    },
    { 
      label: translations.ru.quickActions.assignDayShift, 
      op: 'assign_shift', 
      targetId: availableShifts.find(s => s.name.toLowerCase().includes('day') || s.name.toLowerCase().includes('дневная'))?.id || availableShifts[0]?.id || '',
      targetName: availableShifts.find(s => s.name.toLowerCase().includes('day') || s.name.toLowerCase().includes('дневная'))?.nameRu || availableShifts[0]?.nameRu || ''
    },
    { 
      label: translations.ru.quickActions.assignOffice, 
      op: 'assign_location', 
      targetId: availableLocations.find(l => l.name.toLowerCase().includes('office') || l.name.toLowerCase().includes('офис'))?.id || availableLocations[0]?.id || '',
      targetName: availableLocations.find(l => l.name.toLowerCase().includes('office') || l.name.toLowerCase().includes('офис'))?.nameRu || availableLocations[0]?.nameRu || ''
    }
  ];

  // Show empty state when no assignments selected
  if (selectedAssignments.length === 0) {
    return (
      <div style={{
        backgroundColor: 'white',
        borderRadius: '12px',
        border: '1px solid #e5e7eb',
        padding: '32px'
      }}>
        <div style={{ textAlign: 'center', padding: '32px 0' }}>
          <Users className="w-16 h-16 text-gray-300 mx-auto mb-6" />
          <h3 style={{ 
            fontSize: '20px', 
            fontWeight: '600', 
            color: '#111827', 
            marginBottom: '8px' 
          }}>
            {translations.ru.title}
          </h3>
          <p style={{ fontSize: '14px', color: '#6b7280' }}>
            {translations.ru.selectEmployees}
          </p>
        </div>
      </div>
    );
  }

  const targetOptions = getTargetOptions();

  return (
    <div style={{
      backgroundColor: 'white',
      borderRadius: '12px',
      border: '1px solid #e5e7eb',
      padding: '32px'
    }}>
      {/* Header section */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: '32px',
        paddingBottom: '16px',
        borderBottom: '1px solid #e5e7eb'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <Users className="w-6 h-6 text-blue-600" />
          <h3 style={{ 
            fontSize: '20px', 
            fontWeight: '600', 
            color: '#111827', 
            margin: 0 
          }}>
            {translations.ru.title}
          </h3>
          <span style={{
            backgroundColor: '#dbeafe',
            color: '#1e40af',
            fontSize: '12px',
            fontWeight: '500',
            padding: '4px 12px',
            borderRadius: '16px'
          }}>
            {stats.totalSelected} {translations.ru.selectedCount}
          </span>
        </div>
        <button
          onClick={onClearSelection}
          disabled={disabled}
          style={{
            fontSize: '14px',
            color: '#6b7280',
            background: 'none',
            border: 'none',
            cursor: disabled ? 'not-allowed' : 'pointer',
            opacity: disabled ? 0.6 : 1
          }}
        >
          {translations.ru.clearSelection}
        </button>
      </div>

      {/* Statistics Cards */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: '16px',
        marginBottom: '32px'
      }}>
        <div style={{
          padding: '16px',
          backgroundColor: '#f0fdf4',
          border: '1px solid #bbf7d0',
          borderRadius: '8px'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
            <CheckCircle className="w-4 h-4 text-green-600" />
            <span style={{ fontSize: '12px', color: '#166534', fontWeight: '500' }}>
              Активные назначения
            </span>
          </div>
          <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#166534' }}>
            {stats.activeAssignments}
          </div>
        </div>

        <div style={{
          padding: '16px',
          backgroundColor: '#fef3c7',
          border: '1px solid #fcd34d',
          borderRadius: '8px'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
            <Clock className="w-4 h-4 text-amber-600" />
            <span style={{ fontSize: '12px', color: '#92400e', fontWeight: '500' }}>
              Ожидающие
            </span>
          </div>
          <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#92400e' }}>
            {stats.pendingAssignments}
          </div>
        </div>

        <div style={{
          padding: '16px',
          backgroundColor: '#fee2e2',
          border: '1px solid #fca5a5',
          borderRadius: '8px'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
            <AlertTriangle className="w-4 h-4 text-red-600" />
            <span style={{ fontSize: '12px', color: '#991b1b', fontWeight: '500' }}>
              Конфликты
            </span>
          </div>
          <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#991b1b' }}>
            {stats.conflictCount}
          </div>
        </div>

        <div style={{
          padding: '16px',
          backgroundColor: '#eff6ff',
          border: '1px solid #93c5fd',
          borderRadius: '8px'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
            <Target className="w-4 h-4 text-blue-600" />
            <span style={{ fontSize: '12px', color: '#1e40af', fontWeight: '500' }}>
              Высокий приоритет
            </span>
          </div>
          <div style={{ fontSize: '24px', fontWeight: 'bold', color: '#1e40af' }}>
            {stats.highPriorityCount}
          </div>
        </div>
      </div>

      {/* Operation Type Selection - reused pattern from BulkAdjustments.tsx */}
      <div style={{ marginBottom: '24px' }}>
        <label style={{
          display: 'block',
          fontSize: '14px',
          fontWeight: '500',
          color: '#374151',
          marginBottom: '12px'
        }}>
          {translations.ru.operationType}
        </label>
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
          gap: '12px'
        }}>
          {Object.entries(translations.ru.operationTypes).map(([type, config]) => (
            <button
              key={type}
              onClick={() => {
                setOperation(type as MassAssignmentOperation['type']);
                setTargetId('');
                setTargetName('');
              }}
              disabled={disabled}
              style={{
                padding: '16px',
                borderRadius: '8px',
                border: operation === type ? '2px solid #3b82f6' : '1px solid #d1d5db',
                backgroundColor: operation === type ? '#eff6ff' : 'white',
                color: operation === type ? '#1e40af' : '#374151',
                textAlign: 'left',
                cursor: disabled ? 'not-allowed' : 'pointer',
                transition: 'all 0.2s',
                opacity: disabled ? 0.6 : 1
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                {getOperationIcon(type as MassAssignmentOperation['type'])}
                <span style={{ fontWeight: '500', fontSize: '14px' }}>{config.label}</span>
              </div>
              <p style={{ fontSize: '12px', color: '#6b7280', margin: 0 }}>
                {config.desc}
              </p>
            </button>
          ))}
        </div>
      </div>

      {/* Target Selection */}
      <div style={{ marginBottom: '24px' }}>
        <label style={{
          display: 'block',
          fontSize: '14px',
          fontWeight: '500',
          color: '#374151',
          marginBottom: '8px'
        }}>
          {translations.ru.selectTarget}
        </label>
        <select
          value={targetId}
          onChange={(e) => {
            const selectedOption = targetOptions.find(opt => opt.id === e.target.value);
            setTargetId(e.target.value);
            setTargetName(selectedOption?.name || '');
          }}
          disabled={disabled || targetOptions.length === 0}
          style={{
            width: '100%',
            padding: '12px 16px',
            border: '1px solid #d1d5db',
            borderRadius: '8px',
            fontSize: '14px',
            backgroundColor: 'white',
            cursor: disabled || targetOptions.length === 0 ? 'not-allowed' : 'pointer',
            opacity: disabled || targetOptions.length === 0 ? 0.6 : 1
          }}
        >
          <option value="">-- {translations.ru.selectTarget} --</option>
          {targetOptions.map(option => (
            <option key={option.id} value={option.id}>
              {option.name} {option.extra && `(${option.extra})`}
            </option>
          ))}
        </select>
      </div>

      {/* Date Range Selection */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: '1fr 1fr',
        gap: '16px',
        marginBottom: '24px'
      }}>
        <div>
          <label style={{
            display: 'block',
            fontSize: '14px',
            fontWeight: '500',
            color: '#374151',
            marginBottom: '8px'
          }}>
            {translations.ru.startDate} *
          </label>
          <input
            type="date"
            value={startDate}
            onChange={(e) => setStartDate(e.target.value)}
            disabled={disabled}
            style={{
              width: '100%',
              padding: '12px 16px',
              border: '1px solid #d1d5db',
              borderRadius: '8px',
              fontSize: '14px',
              cursor: disabled ? 'not-allowed' : 'pointer',
              opacity: disabled ? 0.6 : 1
            }}
          />
        </div>
        <div>
          <label style={{
            display: 'block',
            fontSize: '14px',
            fontWeight: '500',
            color: '#374151',
            marginBottom: '8px'
          }}>
            {translations.ru.endDate}
          </label>
          <input
            type="date"
            value={endDate}
            onChange={(e) => setEndDate(e.target.value)}
            disabled={disabled}
            style={{
              width: '100%',
              padding: '12px 16px',
              border: '1px solid #d1d5db',
              borderRadius: '8px',
              fontSize: '14px',
              cursor: disabled ? 'not-allowed' : 'pointer',
              opacity: disabled ? 0.6 : 1
            }}
          />
        </div>
      </div>

      {/* Additional Options */}
      <div style={{ marginBottom: '24px' }}>
        <div style={{ marginBottom: '16px' }}>
          <label style={{
            display: 'block',
            fontSize: '14px',
            fontWeight: '500',
            color: '#374151',
            marginBottom: '8px'
          }}>
            {translations.ru.reason}
          </label>
          <textarea
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="Причина массового назначения..."
            rows={3}
            disabled={disabled}
            style={{
              width: '100%',
              padding: '12px 16px',
              border: '1px solid #d1d5db',
              borderRadius: '8px',
              fontSize: '14px',
              resize: 'vertical',
              cursor: disabled ? 'not-allowed' : 'auto',
              opacity: disabled ? 0.6 : 1
            }}
          />
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          <label style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            fontSize: '14px',
            cursor: disabled ? 'not-allowed' : 'pointer',
            opacity: disabled ? 0.6 : 1
          }}>
            <input
              type="checkbox"
              checked={preserveExisting}
              onChange={(e) => setPreserveExisting(e.target.checked)}
              disabled={disabled}
              style={{ cursor: disabled ? 'not-allowed' : 'pointer' }}
            />
            {translations.ru.preserveExisting}
          </label>

          <label style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            fontSize: '14px',
            cursor: disabled ? 'not-allowed' : 'pointer',
            opacity: disabled ? 0.6 : 1
          }}>
            <input
              type="checkbox"
              checked={notifyEmployees}
              onChange={(e) => setNotifyEmployees(e.target.checked)}
              disabled={disabled}
              style={{ cursor: disabled ? 'not-allowed' : 'pointer' }}
            />
            {translations.ru.notifyEmployees}
          </label>
        </div>
      </div>

      {/* Validation Error Display */}
      {validationError && (
        <div style={{
          padding: '16px',
          backgroundColor: '#fee2e2',
          borderLeft: '4px solid #ef4444',
          borderRadius: '6px',
          marginBottom: '24px'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <AlertTriangle className="w-5 h-5 text-red-600" />
            <span style={{ fontSize: '14px', color: '#991b1b', fontWeight: '500' }}>
              {validationError}
            </span>
          </div>
        </div>
      )}

      {/* Conflicts Display */}
      {conflicts.length > 0 && (
        <div style={{
          padding: '16px',
          backgroundColor: '#fef3c7',
          border: '1px solid #fcd34d',
          borderRadius: '8px',
          marginBottom: '24px'
        }}>
          <h4 style={{ 
            fontSize: '14px', 
            fontWeight: '600', 
            color: '#92400e', 
            marginBottom: '12px',
            display: 'flex',
            alignItems: 'center',
            gap: '8px'
          }}>
            <AlertTriangle className="w-4 h-4" />
            {translations.ru.conflicts} ({conflicts.length})
          </h4>
          <div style={{ maxHeight: '200px', overflowY: 'auto' }}>
            {conflicts.map((conflict, index) => (
              <div key={index} style={{
                padding: '8px 12px',
                backgroundColor: conflict.severity === 'error' ? '#fee2e2' : '#fef3c7',
                border: `1px solid ${conflict.severity === 'error' ? '#fca5a5' : '#fcd34d'}`,
                borderRadius: '6px',
                marginBottom: '8px',
                fontSize: '13px'
              }}>
                <div style={{ fontWeight: '500', color: '#111827', marginBottom: '4px' }}>
                  {conflict.employeeName}
                </div>
                <div style={{ color: '#6b7280' }}>
                  {translations.ru.conflictTypes[conflict.conflictType]}: {conflict.conflictDescription}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Preview Section - adapted from BulkAdjustments.tsx */}
      {previewMode && assignmentPreviews.length > 0 && (
        <div style={{
          padding: '16px',
          backgroundColor: '#f9fafb',
          border: '1px solid #e5e7eb',
          borderRadius: '8px',
          marginBottom: '24px'
        }}>
          <h4 style={{
            fontSize: '14px',
            fontWeight: '600',
            color: '#111827',
            marginBottom: '16px',
            display: 'flex',
            alignItems: 'center',
            gap: '8px'
          }}>
            <Eye className="w-4 h-4" />
            {translations.ru.previewChanges}
          </h4>
          <div style={{ maxHeight: '300px', overflowY: 'auto' }}>
            {assignmentPreviews.slice(0, 10).map((preview, index) => (
              <div key={index} style={{
                padding: '12px',
                backgroundColor: 'white',
                border: '1px solid #e5e7eb',
                borderRadius: '6px',
                marginBottom: '8px'
              }}>
                <div style={{
                  display: 'grid',
                  gridTemplateColumns: '2fr 1fr 1fr 1fr',
                  gap: '12px',
                  alignItems: 'center'
                }}>
                  <div>
                    <div style={{ fontWeight: '500', fontSize: '13px', color: '#111827' }}>
                      {preview.employeeName}
                    </div>
                    <div style={{ fontSize: '11px', color: '#6b7280' }}>
                      {preview.changeDescription}
                    </div>
                  </div>
                  <div style={{ fontSize: '12px', color: '#6b7280' }}>
                    {preview.currentAssignment}
                  </div>
                  <div style={{ fontSize: '12px', color: '#111827' }}>
                    {preview.newAssignment}
                  </div>
                  <div style={{
                    fontSize: '11px',
                    fontWeight: '500',
                    color: preview.impact === 'positive' ? '#059669' : 
                           preview.impact === 'negative' ? '#dc2626' : '#6b7280'
                  }}>
                    {preview.impact === 'positive' ? '✓ Улучшение' : 
                     preview.impact === 'negative' ? '⚠ Внимание' : '→ Изменение'}
                  </div>
                </div>
                {preview.conflicts.length > 0 && (
                  <div style={{ marginTop: '8px', paddingTop: '8px', borderTop: '1px solid #f3f4f6' }}>
                    {preview.conflicts.slice(0, 2).map((conflict, cIndex) => (
                      <div key={cIndex} style={{
                        fontSize: '11px',
                        color: conflict.severity === 'error' ? '#dc2626' : '#f59e0b',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '4px'
                      }}>
                        <AlertTriangle className="w-3 h-3" />
                        {conflict.conflictDescription}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            ))}
            {assignmentPreviews.length > 10 && (
              <p style={{
                fontSize: '12px',
                color: '#6b7280',
                textAlign: 'center',
                margin: '8px 0 0 0'
              }}>
                ...и еще {assignmentPreviews.length - 10} назначений
              </p>
            )}
          </div>
        </div>
      )}

      {/* Action Buttons - reused pattern from BulkAdjustments.tsx */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '24px' }}>
        <button
          onClick={handlePreview}
          disabled={disabled || loading || !targetId || !startDate}
          style={{
            flex: 1,
            padding: '12px 24px',
            backgroundColor: '#f3f4f6',
            color: '#374151',
            border: 'none',
            borderRadius: '8px',
            fontSize: '14px',
            fontWeight: '500',
            cursor: disabled || loading || !targetId || !startDate ? 'not-allowed' : 'pointer',
            opacity: disabled || loading || !targetId || !startDate ? 0.6 : 1,
            transition: 'all 0.2s'
          }}
        >
          {translations.ru.previewChanges}
        </button>
        <button
          onClick={handleApply}
          disabled={disabled || loading || !targetId || !startDate}
          style={{
            flex: 1,
            padding: '12px 24px',
            backgroundColor: disabled || loading || !targetId || !startDate ? '#9ca3af' : '#059669',
            color: 'white',
            border: 'none',
            borderRadius: '8px',
            fontSize: '14px',
            fontWeight: '500',
            cursor: disabled || loading || !targetId || !startDate ? 'not-allowed' : 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '8px',
            transition: 'all 0.2s'
          }}
        >
          {loading ? (
            <div style={{
              width: '16px',
              height: '16px',
              border: '2px solid transparent',
              borderTop: '2px solid white',
              borderRadius: '50%',
              animation: 'spin 1s linear infinite'
            }} />
          ) : (
            <>
              <Check className="w-4 h-4" />
              {translations.ru.applyChanges} ({stats.totalSelected})
            </>
          )}
        </button>
      </div>

      {/* Quick Actions - adapted from BulkAdjustments.tsx */}
      <div style={{
        paddingTop: '24px',
        borderTop: '1px solid #e5e7eb'
      }}>
        <h4 style={{
          fontSize: '14px',
          fontWeight: '500',
          color: '#111827',
          marginBottom: '12px'
        }}>
          {translations.ru.quickActions.title}
        </h4>
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          {quickActions.map((quick, index) => (
            <button
              key={index}
              onClick={() => {
                if (quick.targetId && quick.targetName) {
                  setOperation(quick.op as MassAssignmentOperation['type']);
                  setTargetId(quick.targetId);
                  setTargetName(quick.targetName);
                  setStartDate(new Date().toISOString().split('T')[0]);
                  setTimeout(() => handleApply(), 100);
                }
              }}
              disabled={disabled || loading || !quick.targetId}
              style={{
                padding: '8px 16px',
                fontSize: '12px',
                backgroundColor: '#f3f4f6',
                color: '#374151',
                border: 'none',
                borderRadius: '6px',
                cursor: disabled || loading || !quick.targetId ? 'not-allowed' : 'pointer',
                opacity: disabled || loading || !quick.targetId ? 0.6 : 1,
                transition: 'all 0.2s'
              }}
            >
              {quick.label}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Spec32MassAssignmentOperations;