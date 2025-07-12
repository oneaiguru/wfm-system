import React, { useState, useEffect } from 'react';
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
} from '@dnd-kit/core';
import {
  sortableKeyboardCoordinates,
} from '@dnd-kit/sortable';
import { Employee, Shift } from '../types/schedule';
import ForecastChart from './ForecastChart';
import VirtualizedScheduleGrid from './VirtualizedScheduleGrid';
import { DraggableShiftBlock, DroppableGridCell } from './GridComponents';
// @ts-ignore - mock data stub location
import { UIMockDataStub } from '/Users/m/Documents/wfm/main/project/DAY1_STUBS/ui-mock-data-stub';

const ScheduleGridContainer: React.FC = () => {
  // Use mock data instead of hardcoded employees
  const mockDataService = new UIMockDataStub();
  const mockAgents = mockDataService.generateAgents(5); // Start with 5 for testing
  
  // Convert mock agents to Employee format
  const employees: Employee[] = mockAgents.map((agent, index) => ({
    id: agent.id,
    employeeId: `EMP${String(index + 1).padStart(3, '0')}`,
    firstName: agent.name.split(' ')[0],
    lastName: agent.name.split(' ')[1] || '',
    fullName: agent.name,
    role: 'Operator',
    scheduledHours: Math.floor(Math.random() * 40) + 140,
    plannedHours: Math.floor(Math.random() * 40) + 130,
    photo: agent.name.charAt(0),
    skills: agent.skills,
    isActive: agent.currentStatus !== 'offline'
  }));

  const [selectedCells, setSelectedCells] = useState<Set<string>>(new Set());
  const [shifts, setShifts] = useState<Map<string, Shift>>(new Map());
  const [activeShift, setActiveShift] = useState<Shift | null>(null);
  const [activeChartView, setActiveChartView] = useState<'forecast' | 'deviations' | 'service'>('forecast');
  const [isVirtualized, setIsVirtualized] = useState(false);

  // Generate dates for current month
  const today = new Date();
  const currentMonth = today.getMonth();
  const currentYear = today.getFullYear();
  const dates = [];
  const daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();
  
  for (let i = 1; i <= daysInMonth; i++) {
    const date = new Date(currentYear, currentMonth, i);
    dates.push({
      day: i,
      dayName: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.getDay()],
      isWeekend: date.getDay() === 0 || date.getDay() === 6,
      isToday: i === today.getDate(),
      dateString: `${currentYear}-${String(currentMonth + 1).padStart(2, '0')}-${String(i).padStart(2, '0')}`
    });
  }

  // Initialize shifts using mock schedule data
  useEffect(() => {
    const initialShifts = new Map<string, Shift>();
    
    // Generate schedule data using mock service
    employees.forEach(employee => {
      const scheduleData = mockDataService.generateScheduleData([employee], new Date())[0];
      
      scheduleData.shifts.forEach((shift, shiftIndex) => {
        if (shift.type === 'work') {
          const dateIndex = Math.floor(shiftIndex / 2); // Assuming 2 shifts per day max
          if (dateIndex < dates.length) {
            const cellKey = `${employee.id}-${dateIndex}`;
            
            initialShifts.set(cellKey, {
              id: `shift-${employee.id}-${dateIndex}`,
              employeeId: employee.id,
              date: dates[dateIndex].dateString,
              startTime: shift.start,
              endTime: shift.end,
              shiftTypeId: shift.start.includes('20:') ? 'night' : 'day',
              status: 'scheduled',
              duration: 480, // 8 hours default
              color: shift.start.includes('20:') ? '#4f46e5' : '#74a689'
            });
          }
        }
      });
    });
    
    setShifts(initialShifts);
  }, [employees.length]);

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
  };

  // Handle drag end
  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    setActiveShift(null);

    if (!over) return;

    const sourceShift = active.data.current?.shift as Shift;
    const targetCell = over.data.current;

    if (!sourceShift || !targetCell || targetCell.type !== 'cell') return;

    const sourceKey = `${sourceShift.employeeId}-${dates.findIndex(d => d.dateString === sourceShift.date)}`;
    const targetKey = `${targetCell.employeeId}-${targetCell.dateIndex}`;

    if (sourceKey === targetKey) return;

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
      } else {
        // Target cell occupied, return shift to source
        newShifts.set(sourceKey, sourceShift);
      }
      
      return newShifts;
    });
  };

  // Event handlers
  const handleCellClick = (employeeId: string, dateIndex: number) => {
    const cellId = `${employeeId}-${dateIndex}`;
    const newSelected = new Set(selectedCells);
    
    if (newSelected.has(cellId)) {
      newSelected.delete(cellId);
    } else {
      newSelected.add(cellId);
    }
    
    setSelectedCells(newSelected);
  };

  return (
    <>
      {isVirtualized ? (
        <VirtualizedScheduleGrid employeeCount={500} />
      ) : (
        <DndContext
          sensors={sensors}
          collisionDetection={closestCenter}
          onDragStart={handleDragStart}
          onDragEnd={handleDragEnd}
        >
          <div className="h-full flex flex-col bg-white">
            {/* Chart Area */}
            <div className="h-[140px] border-b-2 border-gray-700 p-4 bg-white">
              <div className="flex items-center justify-between mb-2">
                <div className="flex gap-4">
                  <button 
                    className={`px-3 py-1 rounded-md text-sm font-medium transition-colors ${
                      activeChartView === 'forecast' 
                        ? 'bg-blue-100 text-blue-700' 
                        : 'text-gray-600 hover:bg-gray-100'
                    }`}
                    onClick={() => setActiveChartView('forecast')}
                  >
                    Forecast + Plan
                  </button>
                  <button 
                    className={`px-3 py-1 rounded-md text-sm font-medium transition-colors ${
                      activeChartView === 'deviations' 
                        ? 'bg-blue-100 text-blue-700' 
                        : 'text-gray-600 hover:bg-gray-100'
                    }`}
                    onClick={() => setActiveChartView('deviations')}
                  >
                    Deviations
                  </button>
                  <button 
                    className={`px-3 py-1 rounded-md text-sm font-medium transition-colors ${
                      activeChartView === 'service' 
                        ? 'bg-blue-100 text-blue-700' 
                        : 'text-gray-600 hover:bg-gray-100'
                    }`}
                    onClick={() => setActiveChartView('service')}
                  >
                    Service Level (SL)
                  </button>
                </div>
                
                <div className="flex items-center gap-2 text-xs">
                  <label className="flex items-center gap-1">
                    <input type="checkbox" className="w-3 h-3" />
                    <span>Σ</span>
                  </label>
                  <label className="flex items-center gap-1">
                    <input type="checkbox" className="w-3 h-3" />
                    <span>123</span>
                  </label>
                </div>
              </div>
              
              <div className="h-20 rounded-md overflow-hidden">
                <ForecastChart activeView={activeChartView} />
              </div>
            </div>

            {/* Filter Controls */}
            <div className="border-b p-4 bg-gray-50 flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="flex items-center gap-2">
                  <input type="checkbox" className="rounded" />
                  <span className="text-sm font-medium">All</span>
                </div>
                
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 rounded bg-pink-600"></div>
                  <span className="text-sm">Main Queue</span>
                </div>
                
                <button
                  onClick={() => setIsVirtualized(!isVirtualized)}
                  className="px-3 py-1.5 bg-blue-600 text-white rounded-md text-xs font-medium hover:bg-blue-700 transition-colors"
                >
                  🚀 500+ Employees
                </button>
              </div>
              
              <div className="flex items-center gap-2">
                <input 
                  type="text" 
                  placeholder="Search by skills"
                  className="px-3 py-1 border rounded-md text-sm w-48"
                />
                <button className="px-2 py-1 border rounded-md text-sm bg-white hover:bg-gray-50">
                  🔽
                </button>
              </div>
            </div>

            {/* Main Grid */}
            <div className="flex-1 overflow-auto">
              <table className="w-full border-collapse">
                {/* Header Row */}
                <thead className="sticky top-0 z-10">
                  <tr>
                    <th className="w-80 p-3 bg-gray-50 border-r-2 border-gray-700 border-b text-left text-sm font-medium sticky left-0">
                      By Employee
                    </th>
                    {dates.map((date, index) => (
                      <th 
                        key={index}
                        className={`w-[70px] p-1 border-r border-b text-center text-xs ${
                          date.isWeekend ? 'bg-gray-100 font-bold' : 'bg-gray-50'
                        }`}
                      >
                        <div className="text-gray-700">{date.dayName}</div>
                        <div className="text-gray-600">
                          {String(date.day).padStart(2, '0')}.{String(currentMonth + 1).padStart(2, '0')}
                        </div>
                      </th>
                    ))}
                  </tr>
                </thead>
                
                {/* Body Rows */}
                <tbody>
                  {employees.map((employee, empIndex) => {
                    const variance = employee.scheduledHours - employee.plannedHours;
                    const isPositive = variance > 0;
                    
                    return (
                      <tr 
                        key={employee.id}
                        className={empIndex % 2 === 0 ? 'bg-white' : 'bg-gray-50'}
                      >
                        {/* Employee Info Cell */}
                        <td className="p-2 border-r-2 border-gray-700 border-b sticky left-0 bg-inherit">
                          <div className="flex items-center gap-3">
                            <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-sm font-bold text-blue-700">
                              {employee.photo}
                            </div>
                            
                            <div className="flex-1 min-w-0">
                              <div className="text-sm font-medium text-gray-900 truncate">
                                {employee.fullName}
                              </div>
                              <div className="text-xs text-gray-600">
                                {employee.role}
                              </div>
                              <div className="text-xs">
                                <span className="text-gray-900 font-medium">{employee.scheduledHours}</span>
                                <span className="text-gray-600"> / {employee.plannedHours}</span>
                                <span className="text-gray-600"> | </span>
                                <span className={isPositive ? 'text-green-600' : 'text-red-600'}>
                                  {isPositive ? '+' : ''}{variance} h
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
                              onCellClick={handleCellClick}
                            />
                          );
                        })}
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
            
            {/* Footer */}
            <div className="border-t p-3 bg-gray-50 flex justify-between items-center text-sm">
              <span className="text-gray-600">
                Showing: {employees.length} employees • Period: {dates[0]?.dayName} - {dates[dates.length - 1]?.dayName}
              </span>
              <div className="flex gap-4">
                <span className="text-gray-600">
                  Coverage: <span className="font-medium text-green-600">92%</span>
                </span>
                <span className="text-gray-600">
                  Selected cells: <span className="font-medium">{selectedCells.size}</span>
                </span>
                <span className="text-gray-600">
                  Shifts scheduled: <span className="font-medium">{shifts.size}</span>
                </span>
              </div>
            </div>

            {/* Drag Overlay */}
            <DragOverlay>
              {activeShift ? <DraggableShiftBlock shift={activeShift} isDragOverlay /> : null}
            </DragOverlay>
          </div>
        </DndContext>
      )}
    </>
  );
};

export default ScheduleGridContainer;