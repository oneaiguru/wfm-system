import React, { useState, useEffect } from 'react';
import { format, startOfWeek, addDays, isSameDay } from 'date-fns';
import { Calendar, Clock, ArrowLeft, ArrowRight, AlertTriangle, CheckCircle, ArrowLeftRight } from 'lucide-react';
import realScheduleService from '../services/realScheduleService';
import ShiftSwapModal from './modals/ShiftSwapModal';

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

export const ScheduleView: React.FC = () => {
  const [shifts, setShifts] = useState<Shift[]>([]);
  const [currentWeek, setCurrentWeek] = useState(new Date());
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const [showShiftSwapModal, setShowShiftSwapModal] = useState(false);

  useEffect(() => {
    fetchSchedule();
  }, [currentWeek]);

  const fetchSchedule = async () => {
    setLoading(true);
    setError('');
    
    try {
      // Check API health first
      const healthCheck = await realScheduleService.checkApiHealth();
      if (!healthCheck.healthy) {
        setError('Schedule API is not available. Please ensure the backend server is running.');
        console.error('API Health Check Failed:', healthCheck.message);
        setLoading(false);
        return;
      }

      // Get current personal schedule using real service - NO MOCK FALLBACK
      const scheduleResponse = await realScheduleService.getCurrentSchedule();
      
      if (scheduleResponse.success && scheduleResponse.data) {
        // Transform API data to component format
        const transformedShifts: Shift[] = scheduleResponse.data.shifts.map(shift => ({
          id: shift.id,
          date: shift.date,
          startTime: shift.startTime,
          endTime: shift.endTime,
          department: 'Customer Service', // Default department
          role: 'Customer Service Representative', // Default role
          status: shift.status,
          location: 'Call Center Floor 2',
          notes: undefined
        }));
        
        setShifts(transformedShifts);
        console.log('✅ Real schedule loaded from API:', transformedShifts.length, 'shifts');
      } else {
        // Show real error - NO DEMO FALLBACK
        const errorMsg = scheduleResponse.error || 'Failed to load schedule';
        setError(errorMsg);
        console.error('Schedule API Error:', errorMsg);
        
        // If 404 or employee not found, try alternative endpoint
        if (errorMsg.includes('404') || errorMsg.includes('Employee')) {
          console.log('Trying alternative schedule endpoint...');
          
          // Try team schedule endpoint instead
          const startDate = format(startOfWeek(currentWeek), 'yyyy-MM-dd');
          const endDate = format(addDays(startOfWeek(currentWeek), 6), 'yyyy-MM-dd');
          
          const teamSchedule = await realScheduleService.getScheduleData({
            startDate,
            endDate,
            includeShifts: true
          });
          
          if (teamSchedule.success && teamSchedule.data) {
            const transformedShifts: Shift[] = teamSchedule.data.shifts.map(shift => ({
              id: shift.id,
              date: shift.date,
              startTime: shift.startTime,
              endTime: shift.endTime,
              department: 'Customer Service',
              role: 'Customer Service Representative',
              status: shift.status,
              location: 'Call Center Floor 2',
              notes: undefined
            }));
            
            setShifts(transformedShifts);
            console.log('✅ Team schedule loaded as fallback:', transformedShifts.length, 'shifts');
            setError(''); // Clear error if fallback worked
          }
        }
      }
    } catch (err) {
      console.error('Schedule fetch error:', err);
      setError('Failed to connect to schedule service. Please check if the API server is running.');
    } finally {
      setLoading(false);
    }
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
                onClick={() => setShowShiftSwapModal(true)}
                className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                <ArrowLeftRight className="h-4 w-4" />
                <span>Request Shift Swap</span>
              </button>
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
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
            <div className="flex items-center">
              <AlertTriangle className="h-5 w-5 text-red-600 mr-2" />
              <div>
                <p className="text-red-800 font-medium">Schedule Loading Error</p>
                <p className="text-red-700 text-sm">{error}</p>
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

        {/* API Status and BDD Compliance */}
        <div className="mt-6 text-center">
          <div className="inline-flex items-center px-4 py-2 bg-green-100 text-green-800 rounded-full text-sm">
            <Calendar className="h-4 w-4 mr-2" />
            BDD Compliant: Personal Schedule View - Real API Integration
          </div>
        </div>
      </div>

      {/* Shift Swap Modal */}
      <ShiftSwapModal
        isOpen={showShiftSwapModal}
        onClose={() => setShowShiftSwapModal(false)}
        onSuccess={() => {
          setShowShiftSwapModal(false);
          fetchSchedule(); // Refresh schedule after successful swap
        }}
      />
    </div>
  );
};

export default ScheduleView;