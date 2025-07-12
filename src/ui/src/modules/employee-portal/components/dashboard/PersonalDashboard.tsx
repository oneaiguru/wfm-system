import React, { useState, useEffect } from 'react';

interface PersonalDashboardProps {
  employeeId: string;
}

interface DashboardMetrics {
  currentMonth: {
    hoursWorked: number;
    hoursScheduled: number;
    attendanceRate: number;
    overtimeHours: number;
    timeOffDays: number;
  };
  previousMonth: {
    hoursWorked: number;
    attendanceRate: number;
    overtimeHours: number;
  };
  goals: {
    monthlyHoursTarget: number;
    attendanceTarget: number;
    completedTrainings: number;
    totalTrainings: number;
  };
  upcomingEvents: UpcomingEvent[];
  recentAchievements: Achievement[];
}

interface UpcomingEvent {
  id: string;
  type: 'shift' | 'training' | 'meeting' | 'deadline' | 'review';
  title: string;
  date: Date;
  description?: string;
  priority: 'low' | 'normal' | 'high';
  actionRequired?: boolean;
}

interface Achievement {
  id: string;
  title: string;
  description: string;
  achievedAt: Date;
  type: 'attendance' | 'performance' | 'training' | 'teamwork';
  icon: string;
}

const PersonalDashboard: React.FC<PersonalDashboardProps> = ({ employeeId }) => {
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedPeriod, setSelectedPeriod] = useState<'week' | 'month' | 'quarter'>('month');

  // Load dashboard data
  useEffect(() => {
    const loadDashboardData = async () => {
      setLoading(true);
      
      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Mock dashboard data
      const mockMetrics: DashboardMetrics = {
        currentMonth: {
          hoursWorked: 167.5,
          hoursScheduled: 176,
          attendanceRate: 97.2,
          overtimeHours: 12.5,
          timeOffDays: 2
        },
        previousMonth: {
          hoursWorked: 182.0,
          attendanceRate: 98.5,
          overtimeHours: 8.0
        },
        goals: {
          monthlyHoursTarget: 176,
          attendanceTarget: 95,
          completedTrainings: 4,
          totalTrainings: 6
        },
        upcomingEvents: [
          {
            id: '1',
            type: 'training',
            title: 'Customer Conflict Resolution Training',
            date: new Date('2025-06-15T09:00:00'),
            description: 'Mandatory training for all customer service agents',
            priority: 'high',
            actionRequired: true
          },
          {
            id: '2',
            type: 'shift',
            title: 'Morning Shift',
            date: new Date('2025-06-05T08:00:00'),
            priority: 'normal'
          },
          {
            id: '3',
            type: 'review',
            title: 'Monthly Performance Review',
            date: new Date('2025-06-30T14:00:00'),
            description: 'Meeting with supervisor to discuss results',
            priority: 'normal',
            actionRequired: true
          }
        ],
        recentAchievements: [
          {
            id: '1',
            title: 'Perfect Attendance',
            description: 'No tardiness for the entire month of May',
            achievedAt: new Date('2025-05-31'),
            type: 'attendance',
            icon: '⏰'
          },
          {
            id: '2',
            title: 'High Customer Rating',
            description: 'Average rating of 4.8/5 in May',
            achievedAt: new Date('2025-05-28'),
            type: 'performance',
            icon: '⭐'
          }
        ]
      };
      
      setMetrics(mockMetrics);
      setLoading(false);
    };
    
    loadDashboardData();
  }, [employeeId]);

  const calculateProgress = (current: number, target: number) => {
    return Math.min((current / target) * 100, 100);
  };

  const getProgressColor = (progress: number) => {
    if (progress >= 100) return 'bg-green-500';
    if (progress >= 80) return 'bg-blue-500';
    if (progress >= 60) return 'bg-yellow-500';
    return 'bg-red-500';
  };

  const getEventIcon = (type: string) => {
    const icons = {
      shift: '👥',
      training: '📚',
      meeting: '🤝',
      deadline: '⏰',
      review: '📊'
    };
    return icons[type as keyof typeof icons] || '📅';
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (loading) {
    return (
      <div className="p-6 space-y-6">
        <div className="animate-pulse">
          <div className="h-8 bg-gray-300 rounded w-1/3 mb-4"></div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="h-32 bg-gray-300 rounded-lg"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (!metrics) return null;

  const hoursProgress = calculateProgress(metrics.currentMonth.hoursWorked, metrics.goals.monthlyHoursTarget);
  const attendanceProgress = calculateProgress(metrics.currentMonth.attendanceRate, metrics.goals.attendanceTarget);
  const trainingProgress = calculateProgress(metrics.goals.completedTrainings, metrics.goals.totalTrainings);

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Welcome back, John!</h1>
          <p className="text-gray-600">Here's your performance overview</p>
        </div>
        <div className="flex gap-2">
          {(['week', 'month', 'quarter'] as const).map((period) => (
            <button
              key={period}
              onClick={() => setSelectedPeriod(period)}
              className={`px-3 py-1 text-sm rounded-md transition-colors ${
                selectedPeriod === period
                  ? 'bg-blue-100 text-blue-700'
                  : 'text-gray-600 hover:bg-gray-100'
              }`}
            >
              {period.charAt(0).toUpperCase() + period.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Hours Worked */}
        <div className="bg-white p-6 rounded-lg shadow border">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-sm font-medium text-gray-600">Hours This Month</h3>
            <span className="text-2xl">⏱️</span>
          </div>
          <div className="text-2xl font-bold text-gray-900 mb-1">
            {metrics.currentMonth.hoursWorked}h
          </div>
          <div className="flex items-center gap-2">
            <div className="flex-1 bg-gray-200 rounded-full h-2">
              <div 
                className={`h-2 rounded-full ${getProgressColor(hoursProgress)}`}
                style={{ width: `${hoursProgress}%` }}
              ></div>
            </div>
            <span className="text-xs text-gray-500">
              {metrics.goals.monthlyHoursTarget}h goal
            </span>
          </div>
        </div>

        {/* Attendance Rate */}
        <div className="bg-white p-6 rounded-lg shadow border">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-sm font-medium text-gray-600">Attendance Rate</h3>
            <span className="text-2xl">📊</span>
          </div>
          <div className="text-2xl font-bold text-gray-900 mb-1">
            {metrics.currentMonth.attendanceRate}%
          </div>
          <div className="flex items-center gap-2">
            <div className="flex-1 bg-gray-200 rounded-full h-2">
              <div 
                className={`h-2 rounded-full ${getProgressColor(attendanceProgress)}`}
                style={{ width: `${attendanceProgress}%` }}
              ></div>
            </div>
            <span className="text-xs text-gray-500">
              {metrics.goals.attendanceTarget}% target
            </span>
          </div>
        </div>

        {/* Overtime Hours */}
        <div className="bg-white p-6 rounded-lg shadow border">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-sm font-medium text-gray-600">Overtime</h3>
            <span className="text-2xl">🕒</span>
          </div>
          <div className="text-2xl font-bold text-gray-900 mb-1">
            {metrics.currentMonth.overtimeHours}h
          </div>
          <div className="text-xs text-gray-500">
            {metrics.currentMonth.overtimeHours > metrics.previousMonth.overtimeHours ? '↗️' : '↘️'} 
            {' '}vs last month ({metrics.previousMonth.overtimeHours}h)
          </div>
        </div>

        {/* Training Progress */}
        <div className="bg-white p-6 rounded-lg shadow border">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-sm font-medium text-gray-600">Training</h3>
            <span className="text-2xl">🎓</span>
          </div>
          <div className="text-2xl font-bold text-gray-900 mb-1">
            {metrics.goals.completedTrainings}/{metrics.goals.totalTrainings}
          </div>
          <div className="flex items-center gap-2">
            <div className="flex-1 bg-gray-200 rounded-full h-2">
              <div 
                className={`h-2 rounded-full ${getProgressColor(trainingProgress)}`}
                style={{ width: `${trainingProgress}%` }}
              ></div>
            </div>
            <span className="text-xs text-gray-500">
              {Math.round(trainingProgress)}% complete
            </span>
          </div>
        </div>
      </div>

      {/* Bottom Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Upcoming Events */}
        <div className="bg-white rounded-lg shadow border">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Upcoming Events</h3>
          </div>
          <div className="p-6 space-y-4">
            {metrics.upcomingEvents.slice(0, 4).map((event) => (
              <div
                key={event.id}
                className="p-4 border-l-4 rounded-r-lg border-l-blue-400 bg-blue-50"
              >
                <div className="flex items-start gap-3">
                  <span className="text-xl">{getEventIcon(event.type)}</span>
                  <div className="flex-1 min-w-0">
                    <h4 className="font-medium text-gray-900 truncate">{event.title}</h4>
                    <p className="text-sm text-gray-600">{formatDate(event.date)}</p>
                    {event.description && (
                      <p className="text-sm text-gray-500 mt-1">{event.description}</p>
                    )}
                    {event.actionRequired && (
                      <span className="inline-block mt-2 px-2 py-1 text-xs bg-yellow-100 text-yellow-800 rounded">
                        Action Required
                      </span>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Achievements */}
        <div className="bg-white rounded-lg shadow border">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Recent Achievements</h3>
          </div>
          <div className="p-6 space-y-4">
            {metrics.recentAchievements.map((achievement) => (
              <div key={achievement.id} className="flex items-start gap-3">
                <span className="text-2xl">{achievement.icon}</span>
                <div className="flex-1">
                  <h4 className="font-medium text-gray-900">{achievement.title}</h4>
                  <p className="text-sm text-gray-600">{achievement.description}</p>
                  <p className="text-xs text-gray-500 mt-1">
                    {achievement.achievedAt.toLocaleDateString('en-US', {
                      month: 'short',
                      day: 'numeric'
                    })}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default PersonalDashboard;