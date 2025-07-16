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
import { AlertCircle, RefreshCw } from 'lucide-react';
import { Employee, Shift } from '../types/schedule';
import ForecastChart from './ForecastChart';
import VirtualizedScheduleGrid from './VirtualizedScheduleGrid';
import { DraggableShiftBlock, DroppableGridCell } from './GridComponents';
import realScheduleService from '../../../services/realScheduleService';

const ScheduleGridContainer: React.FC = () => {
  // State management for real data
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [apiHealth, setApiHealth] = useState<{ healthy: boolean; message: string } | null>(null);

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

  // Load real data from API
  useEffect(() => {
    loadEmployeesAndShifts();
    checkApiHealth();
  }, []);

  // Check API health status
  const checkApiHealth = async () => {
    try {
      const health = await realScheduleService.checkApiHealth();
      setApiHealth(health);
    } catch (error) {
      setApiHealth({
        healthy: false,
        message: error instanceof Error ? error.message : 'API health check failed'
      });
    }
  };

  // Load employees and their shifts
  const loadEmployeesAndShifts = async () => {
    setIsLoading(true);
    setError(null);

    try {
      // Load employees first
      const employeeResult = await realScheduleService.getEmployees();
      if (!employeeResult.success) {
        throw new Error(employeeResult.error || 'Failed to load employees');
      }

      if (employeeResult.employees) {
        setEmployees(employeeResult.employees);

        // Load shifts for current month
        const today = new Date();
        const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
        const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0);

        const shiftsResult = await realScheduleService.getShifts(
          startOfMonth.toISOString().split('T')[0],
          endOfMonth.toISOString().split('T')[0],
          employeeResult.employees.map(emp => emp.id)
        );

        if (shiftsResult.success && shiftsResult.shifts) {
          const shiftsMap = new Map<string, Shift>();
          shiftsResult.shifts.forEach(shift => {
            const date = new Date(shift.date);
            const dateIndex = date.getDate() - 1; // Convert to 0-based index
            const cellKey = `${shift.employeeId}-${dateIndex}`;
            shiftsMap.set(cellKey, shift);
          });
          setShifts(shiftsMap);
        }
      }
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to load schedule data');
      console.error('Schedule loading error:', error);
    } finally {
      setIsLoading(false);
    }
  };

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

  // Handle drag end with real API call
  const handleDragEnd = async (event: DragEndEvent) => {
    const { active, over } = event;
    setActiveShift(null);

    if (!over) return;

    const sourceShift = active.data.current?.shift as Shift;
    const targetCell = over.data.current;

    if (!sourceShift || !targetCell || targetCell.type !== 'cell') return;

    const sourceKey = `${sourceShift.employeeId}-${dates.findIndex(d => d.dateString === sourceShift.date)}`;
    const targetKey = `${targetCell.employeeId}-${targetCell.dateIndex}`;

    if (sourceKey === targetKey) return;

    // Check if target cell is occupied
    if (shifts.has(targetKey)) {
      setError('Target cell is already occupied');
      return;
    }

    try {
      // Make real API call to move shift
      const result = await realScheduleService.moveShift(
        sourceShift.id,
        targetCell.employeeId,
        sourceShift.startTime,
        sourceShift.endTime
      );

      if (result.success && result.shift) {
        // Update local state with API response
        setShifts(prev => {
          const newShifts = new Map(prev);
          newShifts.delete(sourceKey);
          newShifts.set(targetKey, result.shift!);
          return newShifts;
        });
        setError(null);
      } else {
        throw new Error(result.error || 'Failed to move shift');
      }
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to move shift');
      console.error('Shift move error:', error);
    }
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
      {/* API Health Status */}
      {apiHealth && !apiHealth.healthy && (
        <div className="mb-4 bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center gap-3">
            <AlertCircle className="w-5 h-5 text-red-600" />
            <div>
              <div className="text-sm font-medium text-red-800">Schedule API Connection Issue</div>
              <div className="text-sm text-red-600">{apiHealth.message}</div>
              <div className="text-xs text-red-500 mt-1">
                Schedule endpoints need INTEGRATION-OPUS implementation
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Error Message */}
      {error && (
        <div className="mb-4 bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-center gap-3">
            <AlertCircle className="w-5 h-5 text-yellow-600" />
            <div>
              <div className="text-sm font-medium text-yellow-800">Schedule Operation Error</div>
              <div className="text-sm text-yellow-600">{error}</div>
              <button 
                onClick={() => setError(null)}
                className="text-xs text-yellow-500 mt-1 underline"
              >
                Dismiss
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Loading State */}
      {isLoading && (
        <div className="flex items-center justify-center py-8">
          <div className="flex items-center gap-3">
            <RefreshCw className="w-6 h-6 text-blue-600 animate-spin" />
            <span className="text-gray-600">Loading schedule data...</span>
          </div>
        </div>
      )}

      {/* Main Content */}
      {!isLoading && (
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
      )}
    </>
  );
};

export default ScheduleGridContainer;