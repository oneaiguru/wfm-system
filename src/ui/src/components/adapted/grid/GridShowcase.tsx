import React, { useState, useMemo } from 'react';
import { ScheduleGrid } from './ScheduleGrid';
import { VirtualizedScheduleGrid } from './VirtualizedScheduleGrid';
import { Employee, Shift, GridDate } from './types';

// Generate mock employees
const generateEmployees = (count: number): Employee[] => {
  const firstNames = ['John', 'Jane', 'Mike', 'Sarah', 'David', 'Emma', 'Tom', 'Lisa', 'Chris', 'Anna'];
  const lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez'];
  const roles = ['Operator', 'Senior Operator', 'Supervisor', 'Team Lead'];
  const skills = ['Inbound', 'Outbound', 'Email Support', 'Chat Support', 'VIP Customers'];
  
  return Array.from({ length: count }, (_, index) => {
    const firstName = firstNames[index % firstNames.length];
    const lastName = lastNames[Math.floor(index / firstNames.length) % lastNames.length];
    const role = roles[index % roles.length];
    const scheduledHours = Math.floor(Math.random() * 40) + 140;
    const plannedHours = Math.floor(Math.random() * 30) + 150;
    
    return {
      id: (index + 1).toString(),
      employeeId: `EMP${String(index + 1).padStart(3, '0')}`,
      firstName,
      lastName,
      fullName: `${lastName}, ${firstName}`,
      role,
      scheduledHours,
      plannedHours,
      photo: firstName.charAt(0),
      skills: [skills[index % skills.length]],
      isActive: true,
    };
  });
};

// Generate dates for a month
const generateDates = (year: number, month: number): GridDate[] => {
  const daysInMonth = new Date(year, month, 0).getDate();
  const today = new Date();
  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  return Array.from({ length: daysInMonth }, (_, index) => {
    const date = new Date(year, month - 1, index + 1);
    return {
      day: index + 1,
      month,
      year,
      dayName: dayNames[date.getDay()],
      isWeekend: date.getDay() === 0 || date.getDay() === 6,
      isToday: date.toDateString() === today.toDateString(),
      dateString: `${year}-${String(month).padStart(2, '0')}-${String(index + 1).padStart(2, '0')}`
    };
  });
};

// Generate initial shifts
const generateShifts = (employees: Employee[], dates: GridDate[]): Map<string, Shift> => {
  const shifts = new Map<string, Shift>();
  
  employees.slice(0, 10).forEach((employee, empIndex) => {
    dates.forEach((date, dateIndex) => {
      // Different patterns for different employees
      const patterns: Record<number, number[]> = {
        0: [1, 1, 1, 1, 1, 0, 0], // 5/2
        1: [1, 1, 0, 0, 1, 1, 0], // 2/2
        2: [0, 1, 1, 0, 0, 1, 1], // irregular
        3: [1, 1, 1, 1, 1, 1, 0], // 6/1
        4: [1, 0, 1, 0, 1, 0, 1], // alternating
      };
      
      const pattern = patterns[empIndex % 5];
      const hasShift = pattern[dateIndex % 7];
      
      if (hasShift) {
        const cellKey = `${employee.id}-${dateIndex}`;
        const isNightShift = empIndex % 4 === 2;
        const isOvertime = empIndex % 7 === 5;
        
        shifts.set(cellKey, {
          id: `shift-${employee.id}-${dateIndex}`,
          employeeId: employee.id,
          date: date.dateString,
          startTime: isNightShift ? '20:00' : '08:00',
          endTime: isNightShift ? '05:00' : '17:00',
          shiftTypeId: isOvertime ? 'overtime' : isNightShift ? 'night' : 'day',
          status: 'scheduled',
          duration: isNightShift ? 540 : 480,
        });
      }
    });
  });
  
  return shifts;
};

export const GridShowcase: React.FC = () => {
  const [viewMode, setViewMode] = useState<'standard' | 'virtualized'>('standard');
  const [employeeCount, setEmployeeCount] = useState(10);
  const [selectedCells, setSelectedCells] = useState<Set<string>>(new Set());
  const [lastAction, setLastAction] = useState<string>('');

  // Generate data
  const currentDate = new Date();
  const employees = useMemo(() => generateEmployees(employeeCount), [employeeCount]);
  const dates = useMemo(() => generateDates(currentDate.getFullYear(), currentDate.getMonth() + 1), []);
  const initialShifts = useMemo(() => generateShifts(employees, dates), [employees, dates]);

  const handleShiftMove = (shift: Shift, targetEmployeeId: string, targetDate: string) => {
    setLastAction(`Moved shift from ${shift.employeeId} to ${targetEmployeeId} on ${targetDate}`);
  };

  const handleCellSelect = (cells: Set<string>) => {
    setSelectedCells(cells);
    setLastAction(`Selected ${cells.size} cells`);
  };

  return (
    <div className="p-6 max-w-full">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900 mb-2">Schedule Grid Component Showcase</h1>
        <p className="text-gray-600">
          Professional grid component extracted from Naumen with drag-drop, selection, and virtualization
        </p>
      </div>

      {/* Controls */}
      <div className="mb-6 bg-white rounded-lg shadow p-4">
        <div className="flex items-center gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">View Mode</label>
            <div className="flex gap-2">
              <button
                onClick={() => setViewMode('standard')}
                className={`px-4 py-2 rounded ${
                  viewMode === 'standard'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                Standard Grid
              </button>
              <button
                onClick={() => setViewMode('virtualized')}
                className={`px-4 py-2 rounded ${
                  viewMode === 'virtualized'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                Virtualized (500+ rows)
              </button>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Employee Count</label>
            <select
              value={employeeCount}
              onChange={(e) => setEmployeeCount(Number(e.target.value))}
              className="px-3 py-2 border border-gray-300 rounded-md"
            >
              <option value="10">10 employees</option>
              <option value="50">50 employees</option>
              <option value="100">100 employees</option>
              <option value="500">500 employees</option>
            </select>
          </div>

          <div className="flex-1">
            <label className="block text-sm font-medium text-gray-700 mb-1">Last Action</label>
            <div className="text-sm text-gray-600 bg-gray-50 px-3 py-2 rounded">
              {lastAction || 'No actions yet'}
            </div>
          </div>
        </div>
      </div>

      {/* Features List */}
      <div className="mb-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
        <h3 className="font-semibold text-blue-900 mb-2">Key Features:</h3>
        <div className="grid grid-cols-2 gap-2 text-sm text-blue-800">
          <div>✓ Drag & drop shift management</div>
          <div>✓ Multi-cell selection</div>
          <div>✓ Virtualization for 500+ employees</div>
          <div>✓ Weekend/holiday highlighting</div>
          <div>✓ Real-time hour calculations</div>
          <div>✓ Responsive design</div>
          <div>✓ Keyboard navigation support</div>
          <div>✓ Performance optimized</div>
        </div>
      </div>

      {/* Grid Display */}
      <div className="bg-gray-50 rounded-lg p-4">
        {viewMode === 'standard' ? (
          <ScheduleGrid
            employees={employees.slice(0, 20)}
            dates={dates}
            initialShifts={initialShifts}
            onShiftMove={handleShiftMove}
            onCellSelect={handleCellSelect}
          />
        ) : (
          <VirtualizedScheduleGrid
            employees={employees}
            dates={dates}
            visibleRows={12}
            initialShifts={initialShifts}
            onShiftMove={handleShiftMove}
            onCellSelect={handleCellSelect}
          />
        )}
      </div>

      {/* Usage Example */}
      <div className="mt-6 bg-gray-900 text-gray-100 rounded-lg p-4 overflow-x-auto">
        <h3 className="text-sm font-semibold mb-2 text-green-400">// Usage Example:</h3>
        <pre className="text-xs">
{`import { ScheduleGrid } from './components/adapted/grid/ScheduleGrid';

const MySchedule = () => {
  const employees = [...]; // Your employee data
  const dates = [...];     // Your date range
  
  return (
    <ScheduleGrid
      employees={employees}
      dates={dates}
      onShiftMove={(shift, empId, date) => {
        console.log('Shift moved:', shift, empId, date);
      }}
      onCellSelect={(cells) => {
        console.log('Selected cells:', cells);
      }}
    />
  );
};`}
        </pre>
      </div>
    </div>
  );
};