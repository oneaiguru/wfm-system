import React, { useState, useMemo } from 'react';
import { FixedSizeList as List } from 'react-window';
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  DragOverlay,
  DragStartEvent,
  DragEndEvent,
  useDraggable,
  useDroppable,
} from '@dnd-kit/core';
import {
  sortableKeyboardCoordinates,
} from '@dnd-kit/sortable';
import { Employee, Shift } from '../types/schedule';
import ForecastChart from './ForecastChart';

// Generate 500+ employees for testing
const generateEmployees = (count: number): Employee[] => {
  const firstNames = ['Анна', 'Мария', 'Дарья', 'Ольга', 'Елена', 'Светлана', 'Наталья', 'Екатерина', 'Татьяна', 'Ирина'];
  const lastNames = ['Иванова', 'Петрова', 'Сидорова', 'Козлова', 'Новикова', 'Морозова', 'Петров', 'Волков', 'Соловьев', 'Васильев'];
  const roles = ['Оператор', 'Старший оператор', 'Супервизор', 'Тим-лидер'];
  const skills = ['Входящая линия_1', 'Исходящая линия', 'Email поддержка', 'Чат поддержка', 'VIP клиенты'];
  
  return Array.from({ length: count }, (_, index) => {
    const firstName = firstNames[index % firstNames.length];
    const lastName = lastNames[index % lastNames.length];
    const role = roles[index % roles.length];
    const scheduledHours = Math.floor(Math.random() * 40) + 140; // 140-180
    const plannedHours = Math.floor(Math.random() * 30) + 150; // 150-180
    
    return {
      id: (index + 1).toString(),
      employeeId: `EMP${String(index + 1).padStart(3, '0')}`,
      firstName,
      lastName,
      fullName: `${lastName} ${firstName.charAt(0)}.`,
      role,
      scheduledHours,
      plannedHours,
      photo: firstName.charAt(0),
      skills: [skills[index % skills.length]],
      isActive: true,
    };
  });
};

// Draggable Shift Block Component
const DraggableShiftBlock: React.FC<{
  shift: Shift;
  isDragOverlay?: boolean;
}> = ({ shift, isDragOverlay = false }) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    isDragging,
  } = useDraggable({
    id: shift.id,
    data: {
      shift,
      type: 'shift',
    },
  });

  return (
    <div
      ref={setNodeRef}
      style={{
        transform: transform ? `translate3d(${transform.x}px, ${transform.y}px, 0)` : undefined,
        backgroundColor: shift.shiftTypeId === 'night' ? '#4f46e5' : '#74a689',
        opacity: isDragging ? 0.5 : 1,
      }}
      {...listeners}
      {...attributes}
      className={`w-full h-full rounded text-white text-xs flex flex-col items-center justify-center font-medium cursor-grab active:cursor-grabbing transition-all duration-200 ${
        isDragOverlay ? 'rotate-3 scale-105 shadow-lg' : ''
      }`}
      title={`${shift.startTime} - ${shift.endTime}`}
    >
      <span>{shift.startTime.substring(0, 5)}</span>
      <span style={{ opacity: 0.6 }}>...</span>
      <span>{shift.endTime.substring(0, 5)}</span>
    </div>
  );
};

// Droppable Grid Cell Component
const DroppableGridCell: React.FC<{
  employeeId: string;
  dateIndex: number;
  date: any;
  shift: Shift | null;
  isSelected: boolean;
  onCellClick: (employeeId: string, dateIndex: number) => void;
}> = ({ employeeId, dateIndex, date, shift, isSelected, onCellClick }) => {
  const {
    isOver,
    setNodeRef
  } = useDroppable({
    id: `cell-${employeeId}-${dateIndex}`,
    data: {
      employeeId,
      dateIndex,
      type: 'cell',
    },
  });

  return (
    <td 
      ref={setNodeRef}
      style={{ 
        width: '70px',
        height: '50px',
        padding: '4px',
        borderRight: '1px solid #e5e7eb',
        borderBottom: '1px solid #e5e7eb',
        backgroundColor: isOver ? '#bfdbfe' : 
                        isSelected ? '#dbeafe' : 
                        date.isToday ? '#fef3c7' : 
                        date.isWeekend ? '#f3f4f6' : 'transparent',
        cursor: 'pointer',
        position: 'relative',
        transition: 'background-color 0.2s ease'
      }}
      onClick={() => onCellClick(employeeId, dateIndex)}
    >
      {shift ? (
        <DraggableShiftBlock shift={shift} />
      ) : (
        <div style={{ 
          width: '100%', 
          height: '100%', 
          backgroundColor: isOver ? '#e0e7ff' : '#f3f4f6', 
          borderRadius: '4px', 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'center',
          border: isOver ? '2px dashed #3b82f6' : '1px solid transparent',
          transition: 'all 0.2s ease'
        }}>
          <span style={{ color: '#9ca3af', fontSize: '12px' }}>
            {isOver ? '📍' : '—'}
          </span>
        </div>
      )}
    </td>
  );
};

// Virtual Employee Row Component
const VirtualEmployeeRow: React.FC<{
  index: number;
  style: React.CSSProperties;
  data: {
    employees: Employee[];
    dates: any[];
    shifts: Map<string, Shift>;
    selectedCells: Set<string>;
    onCellClick: (employeeId: string, dateIndex: number) => void;
    getShiftForCell: (employeeId: string, dateIndex: number) => Shift | null;
  };
}> = ({ index, style, data }) => {
  const { employees, dates, shifts, selectedCells, onCellClick, getShiftForCell } = data;
  const employee = employees[index];
  
  if (!employee) return null;

  const variance = employee.scheduledHours - employee.plannedHours;
  const isPositive = variance > 0;

  return (
    <div style={style}>
      <table style={{ width: '100%', borderCollapse: 'collapse', height: '50px' }}>
        <tbody>
          <tr style={{ backgroundColor: index % 2 === 0 ? 'white' : '#f9fafb' }}>
            {/* Employee Info Cell */}
            <td style={{ 
              width: '320px',
              padding: '8px 16px', 
              borderRight: '2px solid #2d3e50',
              borderBottom: '1px solid #e5e7eb',
              backgroundColor: index % 2 === 0 ? 'white' : '#f9fafb'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <div style={{ 
                  width: '32px', 
                  height: '32px', 
                  backgroundColor: '#dbeafe', 
                  borderRadius: '50%', 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center', 
                  fontSize: '14px', 
                  fontWeight: 'bold', 
                  color: '#1d4ed8' 
                }}>
                  {employee.photo}
                </div>
                
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ 
                    fontSize: '14px', 
                    fontWeight: '500', 
                    color: '#111827',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    whiteSpace: 'nowrap'
                  }}>
                    {employee.fullName}
                  </div>
                  <div style={{ fontSize: '12px', color: '#6b7280' }}>
                    {employee.role}
                  </div>
                  <div style={{ fontSize: '12px' }}>
                    <span style={{ color: '#111827', fontWeight: '500' }}>{employee.scheduledHours}</span>
                    <span style={{ color: '#6b7280' }}> / {employee.plannedHours}</span>
                    <span style={{ color: '#6b7280' }}> | </span>
                    <span style={{ color: isPositive ? '#059669' : '#dc2626' }}>
                      {isPositive ? '+' : ''}{variance} ч.
                    </span>
                  </div>
                </div>
              </div>
            </td>
            
            {/* Schedule Cells */}
            {dates.map((date, dateIndex) => {
              const shift = getShiftForCell(employee.id, dateIndex);
              const cellId = `${employee.id}-${dateIndex}`;
              const isSelected = selectedCells.has(cellId);
              
              return (
                <DroppableGridCell
                  key={dateIndex}
                  employeeId={employee.id}
                  dateIndex={dateIndex}
                  date={date}
                  shift={shift}
                  isSelected={isSelected}
                  onCellClick={onCellClick}
                />
              );
            })}
          </tr>
        </tbody>
      </table>
    </div>
  );
};

const VirtualizedScheduleGrid: React.FC<{ employeeCount?: number }> = ({ 
  employeeCount = 500 
}) => {
  // Generate large dataset of employees
  const employees = useMemo(() => generateEmployees(employeeCount), [employeeCount]);
  
  const [selectedCells, setSelectedCells] = useState<Set<string>>(new Set());
  const [shifts, setShifts] = useState<Map<string, Shift>>(new Map());
  const [activeShift, setActiveShift] = useState<Shift | null>(null);
  const [activeChartView, setActiveChartView] = useState<'forecast' | 'deviations' | 'service'>('forecast');

  // Generate dates for July 2024
  const dates = useMemo(() => {
    const result = [];
    for (let i = 1; i <= 31; i++) {
      const date = new Date(2024, 6, i);
      result.push({
        day: i,
        dayName: ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'][date.getDay()],
        isWeekend: date.getDay() === 0 || date.getDay() === 6,
        isToday: i === 17,
        dateString: `2024-07-${String(i).padStart(2, '0')}`
      });
    }
    return result;
  }, []);

  // Initialize shifts with efficient generation
  React.useEffect(() => {
    const initialShifts = new Map<string, Shift>();
    
    // Only generate shifts for first 100 employees to keep demo responsive
    const activeEmployees = employees.slice(0, Math.min(100, employees.length));
    
    activeEmployees.forEach(employee => {
      dates.forEach((_, dateIndex) => {
        // Pattern based on employee ID
        const empNumber = parseInt(employee.id);
        const patterns: Record<number, number[]> = {
          0: [1, 1, 1, 1, 1, 0, 0], // 5/2
          1: [1, 1, 0, 0, 1, 1, 0], // 2/2
          2: [0, 1, 1, 0, 0, 1, 1], // irregular
          3: [1, 1, 1, 1, 1, 1, 0], // 6/1
          4: [1, 0, 1, 0, 1, 0, 1], // alternating
        };
        
        const pattern = patterns[empNumber % 5];
        const hasShift = pattern[dateIndex % 7];
        
        if (hasShift) {
          const cellKey = `${employee.id}-${dateIndex}`;
          const isNightShift = empNumber % 7 === 2; // Every 7th employee has night shifts
          
          initialShifts.set(cellKey, {
            id: `shift-${employee.id}-${dateIndex}`,
            employeeId: employee.id,
            date: `2024-07-${String(dateIndex + 1).padStart(2, '0')}`,
            startTime: isNightShift ? '20:00' : '08:00',
            endTime: isNightShift ? '09:00' : '17:00',
            shiftTypeId: isNightShift ? 'night' : 'day',
            status: 'scheduled',
            duration: isNightShift ? 660 : 480,
            color: isNightShift ? '#4f46e5' : '#74a689'
          });
        }
      });
    });
    
    setShifts(initialShifts);
  }, [employees, dates]);

  // Get shift for specific cell
  const getShiftForCell = (employeeId: string, dateIndex: number): Shift | null => {
    const cellKey = `${employeeId}-${dateIndex}`;
    return shifts.get(cellKey) || null;
  };

  // Drag and drop sensors
  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  // Handle drag start
  const handleDragStart = (event: DragStartEvent) => {
    const { active } = event;
    const shiftData = active.data.current?.shift as Shift;
    setActiveShift(shiftData);
    console.log('🚀 Drag started:', shiftData);
  };

  // Handle drag end
  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    setActiveShift(null);

    if (!over) {
      console.log('❌ Dropped outside valid area');
      return;
    }

    const sourceShift = active.data.current?.shift as Shift;
    const targetCell = over.data.current;

    if (!sourceShift || !targetCell || targetCell.type !== 'cell') {
      console.log('❌ Invalid drop target');
      return;
    }

    const sourceKey = `${sourceShift.employeeId}-${dates.findIndex(d => d.dateString === sourceShift.date)}`;
    const targetKey = `${targetCell.employeeId}-${targetCell.dateIndex}`;

    if (sourceKey === targetKey) {
      console.log('ℹ️ Dropped on same cell');
      return;
    }

    console.log(`📦 Moving shift from ${sourceKey} to ${targetKey}`);

    setShifts(prev => {
      const newShifts = new Map(prev);
      
      // Remove shift from source
      newShifts.delete(sourceKey);
      
      // Add shift to target (if target is empty)
      if (!newShifts.has(targetKey)) {
        const newShift: Shift = {
          ...sourceShift,
          id: `shift-${targetCell.employeeId}-${targetCell.dateIndex}`,
          employeeId: targetCell.employeeId,
          date: dates[targetCell.dateIndex].dateString,
        };
        newShifts.set(targetKey, newShift);
        
        console.log('✅ Shift moved successfully!');
      } else {
        // Target cell occupied, return shift to source
        newShifts.set(sourceKey, sourceShift);
        console.log('⚠️ Target cell occupied, shift returned');
      }
      
      return newShifts;
    });
  };

  // Event handlers
  const handleCellClick = (employeeId: string, dateIndex: number) => {
    console.log(`🎯 CLICK DETECTED! Employee: ${employeeId}, Date: ${dateIndex + 1}`);
    const cellId = `${employeeId}-${dateIndex}`;
    const newSelected = new Set(selectedCells);
    
    if (newSelected.has(cellId)) {
      newSelected.delete(cellId);
      console.log(`❌ Deselected cell: ${cellId}`);
    } else {
      newSelected.add(cellId);
      console.log(`✅ Selected cell: ${cellId}`);
    }
    
    setSelectedCells(newSelected);
    console.log(`📊 Total selected: ${newSelected.size} cells`);
  };

  // Virtual list data
  const virtualListData = {
    employees,
    dates,
    shifts,
    selectedCells,
    onCellClick: handleCellClick,
    getShiftForCell,
  };

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCenter}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
    >
      <div style={{ height: 'calc(100vh - 180px)', display: 'flex', flexDirection: 'column', backgroundColor: 'white' }}>
        {/* Chart Area */}
        <div style={{ height: '140px', borderBottom: '2px solid #2d3e50', padding: '16px', backgroundColor: 'white' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
            <div style={{ display: 'flex', gap: '16px' }}>
              <button style={{ 
                padding: '4px 12px', 
                backgroundColor: activeChartView === 'forecast' ? '#dbeafe' : 'transparent', 
                color: activeChartView === 'forecast' ? '#1d4ed8' : '#6b7280', 
                borderRadius: '6px', 
                fontSize: '14px', 
                fontWeight: '500',
                border: 'none',
                cursor: 'pointer'
              }}
              onClick={() => {
                setActiveChartView('forecast');
                console.log('🔄 Switched to: Прогноз + план');
              }}
              >
                Прогноз + план
              </button>
              <button style={{ 
                padding: '4px 12px', 
                backgroundColor: activeChartView === 'deviations' ? '#dbeafe' : 'transparent', 
                color: activeChartView === 'deviations' ? '#1d4ed8' : '#6b7280', 
                borderRadius: '6px', 
                fontSize: '14px',
                border: 'none',
                cursor: 'pointer'
              }}
              onClick={() => {
                setActiveChartView('deviations');
                console.log('🔄 Switched to: Отклонения');
              }}
              >
                Отклонения
              </button>
              <button style={{ 
                padding: '4px 12px', 
                backgroundColor: activeChartView === 'service' ? '#dbeafe' : 'transparent', 
                color: activeChartView === 'service' ? '#1d4ed8' : '#6b7280', 
                borderRadius: '6px', 
                fontSize: '14px',
                border: 'none',
                cursor: 'pointer'
              }}
              onClick={() => {
                setActiveChartView('service');
                console.log('🔄 Switched to: Уровень сервиса');
              }}
              >
                Уровень сервиса (SL)
              </button>
            </div>
            
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '12px' }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                <input type="checkbox" style={{ width: '12px', height: '12px' }} />
                <span>Σ</span>
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                <input type="checkbox" style={{ width: '12px', height: '12px' }} />
                <span>123</span>
              </label>
            </div>
          </div>
          
          <div style={{ 
            height: '80px', 
            borderRadius: '6px', 
            overflow: 'hidden'
          }}>
            <ForecastChart activeView={activeChartView} />
          </div>
        </div>

        {/* Filter Controls */}
        <div style={{ 
          borderBottom: '1px solid #e5e7eb', 
          padding: '16px', 
          backgroundColor: '#f9fafb',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <input type="checkbox" style={{ borderRadius: '4px' }} />
              <span style={{ fontSize: '14px', fontWeight: '500' }}>Все ({employees.length} сотрудников)</span>
            </div>
            
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <div style={{ 
                width: '16px', 
                height: '16px', 
                borderRadius: '4px', 
                backgroundColor: '#bc0181' 
              }}></div>
              <span style={{ fontSize: '14px' }}>Входящая линия_1</span>
            </div>
          </div>
          
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <input 
              type="text" 
              placeholder="Поиск по навыкам"
              style={{ 
                padding: '4px 12px', 
                border: '1px solid #d1d5db', 
                borderRadius: '6px', 
                fontSize: '14px', 
                width: '192px' 
              }}
            />
            <button style={{ 
              padding: '4px 8px', 
              border: '1px solid #d1d5db', 
              borderRadius: '6px', 
              fontSize: '14px',
              backgroundColor: 'white',
              cursor: 'pointer'
            }}>🔽</button>
          </div>
        </div>

        {/* Virtual Grid Header */}
        <div style={{ backgroundColor: '#f9fafb', borderBottom: '1px solid #e5e7eb' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr>
                <th style={{ 
                  width: '320px', 
                  padding: '12px 16px', 
                  backgroundColor: '#f9fafb', 
                  borderRight: '2px solid #2d3e50',
                  textAlign: 'left',
                  fontSize: '14px',
                  fontWeight: '500'
                }}>
                  По сотрудникам
                </th>
                {dates.map((date, index) => (
                  <th 
                    key={index}
                    style={{ 
                      width: '70px',
                      padding: '4px',
                      borderRight: '1px solid #e5e7eb',
                      backgroundColor: date.isWeekend ? '#f3f4f6' : '#f9fafb',
                      textAlign: 'center',
                      fontSize: '12px',
                      fontWeight: date.isWeekend ? 'bold' : 'normal'
                    }}
                  >
                    <div style={{ color: '#374151' }}>{date.dayName}</div>
                    <div style={{ color: '#6b7280' }}>
                      {String(date.day).padStart(2, '0')}.07
                    </div>
                  </th>
                ))}
              </tr>
            </thead>
          </table>
        </div>

        {/* Virtual Employee List */}
        <div style={{ flex: 1, overflow: 'hidden' }}>
          <List
            height={400}
            itemCount={employees.length}
            itemSize={50}
            itemData={virtualListData}
            width="100%"
          >
            {VirtualEmployeeRow}
          </List>
        </div>
        
        {/* Footer */}
        <div style={{ 
          borderTop: '1px solid #e5e7eb', 
          padding: '12px 16px', 
          backgroundColor: '#f9fafb',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          fontSize: '14px'
        }}>
          <span style={{ color: '#6b7280' }}>
            Показано: {employees.length} сотрудников • Период: Июль 2024
          </span>
          <div style={{ display: 'flex', gap: '16px' }}>
            <span style={{ color: '#6b7280' }}>
              Покрытие: <span style={{ fontWeight: '500', color: '#059669' }}>
                {Math.round((shifts.size / (employees.slice(0, 100).length * dates.length)) * 100)}%
              </span>
            </span>
            <span style={{ color: '#6b7280' }}>
              Выбрано ячеек: <span style={{ fontWeight: '500' }}>{selectedCells.size}</span>
            </span>
            <span style={{ color: '#6b7280' }}>
              Смен в расписании: <span style={{ fontWeight: '500' }}>{shifts.size}</span>
            </span>
          </div>
        </div>
      </div>

      {/* Drag Overlay */}
      <DragOverlay>
        {activeShift ? <DraggableShiftBlock shift={activeShift} isDragOverlay /> : null}
      </DragOverlay>
    </DndContext>
  );
};

export default VirtualizedScheduleGrid;