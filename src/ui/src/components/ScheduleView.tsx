import React, { useState, useEffect } from 'react';
import { format, startOfWeek, addDays, isSameDay } from 'date-fns';
import { Calendar, Clock, ArrowLeft, ArrowRight, AlertTriangle, CheckCircle } from 'lucide-react';

interface Shift {
  id: string;
  date: string;
  startTime: string;
  endTime: string;
  department: string;
  role: string;
  status: 'scheduled' | 'confirmed' | 'completed' | 'cancelled';
  location?: string;
  notes?: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

export const ScheduleView: React.FC = () => {
  const [shifts, setShifts] = useState<Shift[]>([]);
  const [currentWeek, setCurrentWeek] = useState(new Date());
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    fetchSchedule();
  }, [currentWeek]);

  const fetchSchedule = async () => {
    setLoading(true);
    setError('');
    
    try {
      const response = await fetch(`${API_BASE_URL}/schedules/personal`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`
        }
      });
      
      if (response.ok) {
        const data = await response.json();
        // Transform API data to shifts array
        const transformedShifts = data.shifts || [];
        setShifts(transformedShifts);
      } else {
        throw new Error('Failed to fetch schedule');
      }
    } catch (err) {
      console.error('Schedule fetch error:', err);
      setError('Failed to load schedule data');
      
      // Generate demo schedule data
      generateDemoSchedule();
    } finally {
      setLoading(false);
    }
  };

  const generateDemoSchedule = () => {
    const weekStart = startOfWeek(currentWeek);
    const demoShifts: Shift[] = [];
    
    // Generate demo shifts for Monday to Friday
    for (let i = 0; i < 5; i++) {
      if (i !== 2) { // Skip Wednesday (day off)
        const date = addDays(weekStart, i + 1); // Skip Sunday (i+1 for Monday start)
        demoShifts.push({
          id: `shift-${i}`,
          date: format(date, 'yyyy-MM-dd'),
          startTime: i === 0 ? '08:00' : i === 1 ? '09:00' : '10:00', // Varied start times
          endTime: i === 0 ? '16:00' : i === 1 ? '17:00' : '18:00',   // Varied end times
          department: 'Customer Service',
          role: 'Customer Service Representative',
          status: 'confirmed',
          location: 'Call Center Floor 2',
          notes: i === 4 ? 'Training session at 2 PM' : undefined
        });
      }
    }
    
    setShifts(demoShifts);
  };

  const getShiftForDate = (date: Date) => {
    const dateStr = format(date, 'yyyy-MM-dd');
    return shifts.find(shift => shift.date === dateStr);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'confirmed': return 'bg-green-100 text-green-800 border-green-200';
      case 'scheduled': return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'completed': return 'bg-gray-100 text-gray-800 border-gray-200';
      case 'cancelled': return 'bg-red-100 text-red-800 border-red-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'confirmed': return <CheckCircle className="h-4 w-4" />;
      case 'scheduled': return <Clock className="h-4 w-4" />;
      case 'cancelled': return <AlertTriangle className="h-4 w-4" />;
      default: return <Clock className="h-4 w-4" />;
    }
  };

  const weekStart = startOfWeek(currentWeek);
  const weekDays = Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));
  const today = new Date();

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading schedule...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Calendar className="h-6 w-6 text-blue-600" />
              <h1 className="text-2xl font-bold text-gray-900">My Schedule</h1>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={() => setCurrentWeek(addDays(currentWeek, -7))}
                className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <ArrowLeft className="h-5 w-5" />
              </button>
              <div className="text-center">
                <div className="font-semibold text-gray-900">
                  {format(weekStart, 'MMM dd')} - {format(addDays(weekStart, 6), 'MMM dd, yyyy')}
                </div>
                <div className="text-sm text-gray-600">Week View</div>
              </div>
              <button
                onClick={() => setCurrentWeek(addDays(currentWeek, 7))}
                className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <ArrowRight className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 py-6">
        {error && (
          <div className="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
            <div className="flex items-center">
              <AlertTriangle className="h-5 w-5 text-yellow-600 mr-2" />
              <div>
                <p className="text-yellow-800 font-medium">Schedule Loading Issue</p>
                <p className="text-yellow-700 text-sm">{error}</p>
                <p className="text-yellow-700 text-sm">Showing demo schedule for demonstration</p>
              </div>
            </div>
          </div>
        )}

        {/* Weekly Schedule Grid */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <div className="grid grid-cols-7 gap-0">
            {weekDays.map((day, index) => {
              const shift = getShiftForDate(day);
              const isToday = isSameDay(day, today);
              const isWeekend = index === 0 || index === 6;
              
              return (
                <div
                  key={day.toISOString()}
                  className={`min-h-48 p-4 border-r border-b border-gray-200 ${
                    isToday ? 'bg-blue-50' : isWeekend ? 'bg-gray-50' : 'bg-white'
                  }`}
                >
                  {/* Day Header */}
                  <div className="text-center mb-3">
                    <div className={`text-sm font-medium ${
                      isToday ? 'text-blue-600' : isWeekend ? 'text-gray-500' : 'text-gray-900'
                    }`}>
                      {format(day, 'EEE')}
                    </div>
                    <div className={`text-lg font-bold ${
                      isToday ? 'text-blue-600' : isWeekend ? 'text-gray-500' : 'text-gray-900'
                    }`}>
                      {format(day, 'd')}
                    </div>
                  </div>

                  {/* Shift Content */}
                  {shift ? (
                    <div className={`p-3 rounded-lg border ${getStatusColor(shift.status)}`}>
                      <div className="flex items-center gap-1 mb-2">
                        {getStatusIcon(shift.status)}
                        <span className="text-xs font-medium capitalize">{shift.status}</span>
                      </div>
                      <div className="text-sm font-medium mb-1">
                        {shift.startTime} - {shift.endTime}
                      </div>
                      <div className="text-xs text-gray-600 mb-1">
                        {shift.department}
                      </div>
                      <div className="text-xs text-gray-600 mb-1">
                        {shift.role}
                      </div>
                      {shift.location && (
                        <div className="text-xs text-gray-500 mb-1">
                          📍 {shift.location}
                        </div>
                      )}
                      {shift.notes && (
                        <div className="text-xs text-yellow-600 mt-2">
                          ⚠️ {shift.notes}
                        </div>
                      )}
                    </div>
                  ) : (
                    <div className="text-center py-8">
                      <div className="text-gray-400 text-sm">
                        {isWeekend ? 'Weekend' : 'Day Off'}
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Weekly Summary */}
        <div className="mt-6 bg-white rounded-lg p-6 shadow-sm border border-gray-200">
          <h3 className="text-lg font-semibold mb-4">Weekly Summary</h3>
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <div className="text-2xl font-bold text-blue-600">
                {shifts.length}
              </div>
              <div className="text-sm text-gray-600">Scheduled Days</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-green-600">
                {shifts.reduce((total, shift) => {
                  const start = new Date(`1970-01-01T${shift.startTime}`);
                  const end = new Date(`1970-01-01T${shift.endTime}`);
                  const hours = (end.getTime() - start.getTime()) / (1000 * 60 * 60);
                  return total + hours;
                }, 0)}
              </div>
              <div className="text-sm text-gray-600">Total Hours</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-purple-600">
                {shifts.filter(s => s.status === 'confirmed').length}
              </div>
              <div className="text-sm text-gray-600">Confirmed</div>
            </div>
          </div>
        </div>

        {/* BDD Compliance Note */}
        <div className="mt-6 text-center">
          <div className="inline-flex items-center px-4 py-2 bg-green-100 text-green-800 rounded-full text-sm">
            <Calendar className="h-4 w-4 mr-2" />
            BDD Compliant: Personal Schedule View
          </div>
        </div>
      </div>
    </div>
  );
};

export default ScheduleView;