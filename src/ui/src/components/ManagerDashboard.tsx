import React, { useState, useEffect } from 'react';
import { Users, Clock, CheckCircle, XCircle, AlertTriangle, Calendar, FileText, TrendingUp, Loader2, ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

interface TeamMember {
  id: string;
  name: string;
  role: string;
  status: 'active' | 'on_leave' | 'sick';
  shiftsThisWeek: number;
  hoursThisWeek: number;
}

interface PendingRequest {
  id: string;
  employeeName: string;
  type: 'vacation' | 'sick' | 'personal';
  startDate: string;
  endDate: string;
  reason: string;
  days: number;
}

// Formal SPEC-04 interface (from I-stage integration)
interface FormalManagerDashboard {
  manager_id: number;
  team: {
    id: number;
    name: string;
    total_members: number;
  };
  today_metrics: {
    date: string;
    pending_requests: number;
    scheduled_employees: number;
    total_work_hours: number;
  };
  team_members: Array<{
    id: number;
    name: string;
    agent_code: string;
    role: 'member' | 'lead';
    has_schedule_today: boolean;
    pending_requests: number;
  }>;
  alerts: Array<{
    type: string;
    message: string;
    request_id?: number;
    created_at: string;
  }>;
  generated_at: string;
}

// Enhanced interface (includes both formal + enhanced data)
interface ManagerDashboardData {
  manager_id: number;
  manager_name: string;
  dashboard_date: string;
  team_metrics: {
    team_size: number;
    present_today: number;
    on_vacation: number;
    sick_leave: number;
    attendance_rate: number;
  };
  requests_summary: {
    pending_approvals: number;
    approved_this_week: number;
    rejected_this_week: number;
    urgent_requests: number;
  };
  schedule_metrics: {
    week_coverage: number;
    overtime_hours: number;
    understaffed_days: number;
    schedule_conflicts: number;
  };
  performance_indicators: {
    team_productivity: number;
    customer_satisfaction: number;
    average_handle_time: string;
    resolution_rate: number;
  };
  alerts: Array<{
    type: string;
    message: string;
    priority: 'low' | 'medium' | 'high';
  }>;
  week_overview: {
    start_date: string;
    end_date: string;
    scheduled_hours: number;
    actual_hours: number;
    efficiency: number;
  };
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

export const ManagerDashboard: React.FC = () => {
  const navigate = useNavigate();
  const [selectedTab, setSelectedTab] = useState<'overview' | 'requests' | 'schedule'>('overview');
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [dashboardData, setDashboardData] = useState<ManagerDashboardData | null>(null);
  const [formalData, setFormalData] = useState<FormalManagerDashboard | null>(null);
  const [error, setError] = useState<string>('');

  // Fetch real manager dashboard data
  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    setLoading(true);
    setError('');
    try {
      // Try formal SPEC-04 endpoint first (Jane Manager ID 7)
      const formalResponse = await fetch(`${API_BASE_URL}/managers/7/dashboard`);
      
      if (formalResponse.ok) {
        const formal = await formalResponse.json();
        setFormalData(formal);
        console.log('✅ Formal manager dashboard loaded (SPEC-04):', formal);
        
        // Try enhanced endpoint as well
        try {
          const enhancedResponse = await fetch(`${API_BASE_URL}/managers/1/dashboard`);
          if (enhancedResponse.ok) {
            const enhanced = await enhancedResponse.json();
            setDashboardData(enhanced);
            console.log('✅ Enhanced dashboard data also loaded:', enhanced);
          }
        } catch (enhancedErr) {
          console.log('Enhanced endpoint not available, using formal data only');
        }
      } else {
        setError('Failed to load formal dashboard data - using demo fallback');
      }
    } catch (err) {
      console.error('Dashboard fetch error:', err);
      setError('Network error - using demo fallback');
    } finally {
      setLoading(false);
    }
  };

  // Demo data (fallback)
  const teamMembers: TeamMember[] = [
    { id: '1', name: 'John Doe', role: 'Customer Service Rep', status: 'active', shiftsThisWeek: 5, hoursThisWeek: 40 },
    { id: '2', name: 'Jane Smith', role: 'Senior Agent', status: 'active', shiftsThisWeek: 5, hoursThisWeek: 40 },
    { id: '3', name: 'Mike Johnson', role: 'Team Lead', status: 'on_leave', shiftsThisWeek: 0, hoursThisWeek: 0 },
    { id: '4', name: 'Sarah Wilson', role: 'Customer Service Rep', status: 'active', shiftsThisWeek: 4, hoursThisWeek: 32 },
    { id: '5', name: 'David Brown', role: 'Senior Agent', status: 'sick', shiftsThisWeek: 2, hoursThisWeek: 16 }
  ];

  // Real vacation request UUIDs for demo (created via API)
  const pendingRequests: PendingRequest[] = [
    { id: '3c13896f-d9c2-431c-8ae2-f33fa6970307', employeeName: 'John Doe', type: 'vacation', startDate: '2025-08-01', endDate: '2025-08-05', reason: 'Test for approval', days: 5 },
    { id: 'demo-request-2', employeeName: 'Sarah Wilson', type: 'personal', startDate: '2025-07-22', endDate: '2025-07-22', reason: 'Medical appointment', days: 1 },
    { id: 'demo-request-3', employeeName: 'Jane Smith', type: 'vacation', startDate: '2025-08-01', endDate: '2025-08-05', reason: 'Summer break', days: 5 }
  ];

  // Use formal SPEC-04 data first, then enhanced data, then demo fallback
  const teamStats = formalData ? {
    totalMembers: formalData.team.total_members,
    activeMembers: formalData.team_members.filter(m => m.has_schedule_today).length,
    onLeave: formalData.team_members.filter(m => !m.has_schedule_today && m.role === 'member').length,
    sick: 0, // Not available in formal data
    pendingRequests: formalData.today_metrics.pending_requests,
    weeklyHours: formalData.today_metrics.total_work_hours
  } : dashboardData ? {
    totalMembers: dashboardData.team_metrics.team_size,
    activeMembers: dashboardData.team_metrics.present_today,
    onLeave: dashboardData.team_metrics.on_vacation,
    sick: dashboardData.team_metrics.sick_leave,
    pendingRequests: dashboardData.requests_summary.pending_approvals,
    weeklyHours: dashboardData.week_overview.actual_hours
  } : {
    totalMembers: teamMembers.length,
    activeMembers: teamMembers.filter(m => m.status === 'active').length,
    onLeave: teamMembers.filter(m => m.status === 'on_leave').length,
    sick: teamMembers.filter(m => m.status === 'sick').length,
    pendingRequests: pendingRequests.length,
    weeklyHours: teamMembers.reduce((sum, m) => sum + m.hoursThisWeek, 0)
  };

  const handleApproveRequest = async (requestId: string) => {
    setActionLoading(requestId);
    try {
      const authToken = localStorage.getItem('authToken');
      
      const response = await fetch(`${API_BASE_URL}/requests/${requestId}/approve`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authToken}`
        },
        body: JSON.stringify({
          manager_id: 1, // Demo manager ID
          approval_notes: 'Approved via manager dashboard',
          approved_date: new Date().toISOString()
        })
      });

      if (response.ok) {
        const result = await response.json();
        console.log('✅ Request approved:', result);
        // In real app, would refresh the requests list
        alert('Request approved successfully!');
      } else {
        console.warn('⚠️ Approval failed:', response.status);
        alert('Approval failed. API endpoint may need manager context.');
      }
    } catch (error) {
      console.error('Approval error:', error);
      alert('Network error during approval.');
    } finally {
      setActionLoading(null);
    }
  };

  const handleRejectRequest = async (requestId: string) => {
    setActionLoading(requestId);
    try {
      const authToken = localStorage.getItem('authToken');
      
      const response = await fetch(`${API_BASE_URL}/requests/${requestId}/reject`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authToken}`
        },
        body: JSON.stringify({
          manager_id: 1, // Demo manager ID
          rejection_reason: 'Rejected via manager dashboard',
          rejected_date: new Date().toISOString()
        })
      });

      if (response.ok) {
        const result = await response.json();
        console.log('✅ Request rejected:', result);
        alert('Request rejected successfully!');
      } else {
        console.warn('⚠️ Rejection failed:', response.status);
        alert('Rejection failed. API endpoint may need manager context.');
      }
    } catch (error) {
      console.error('Rejection error:', error);
      alert('Network error during rejection.');
    } finally {
      setActionLoading(null);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800';
      case 'on_leave': return 'bg-blue-100 text-blue-800';
      case 'sick': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getRequestTypeColor = (type: string) => {
    switch (type) {
      case 'vacation': return 'bg-blue-100 text-blue-800';
      case 'sick': return 'bg-red-100 text-red-800';
      case 'personal': return 'bg-yellow-100 text-yellow-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const StatCard: React.FC<{
    title: string;
    value: number;
    icon: React.ComponentType<any>;
    color: string;
  }> = ({ title, value, icon: Icon, color }) => (
    <div className="bg-white rounded-lg p-6 shadow-sm border">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-600">{title}</p>
          <p className="text-2xl font-bold text-gray-900">{value}</p>
        </div>
        <div className={`p-3 rounded-full ${color}`}>
          <Icon className="h-6 w-6 text-white" />
        </div>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <button
                onClick={() => navigate('/demo')}
                className="flex items-center gap-2 text-blue-600 hover:text-blue-800 transition-colors"
              >
                <ArrowLeft className="h-5 w-5" />
                Back to Demo
              </button>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">
                  {formalData ? 
                    `${formalData.team.name} Manager` : 
                    dashboardData ? dashboardData.manager_name : 
                    'Manager Dashboard'
                  }
                  {loading && <Loader2 className="inline h-5 w-5 animate-spin ml-2" />}
                </h1>
                <p className="text-gray-600">
                  {formalData ? 
                    `SPEC-04 Formal Dashboard • ${formalData.team.total_members} team members • ${formalData.today_metrics.date}` :
                    dashboardData ? 
                      `Enhanced data for ${dashboardData.dashboard_date}` : 
                      'Manage your team and approve requests with real API'
                  }
                  {error && <span className="text-yellow-600 ml-2">• {error}</span>}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-4">
              <div className="flex bg-gray-100 rounded-lg p-1">
                {[
                  { key: 'overview', label: 'Overview' },
                  { key: 'requests', label: 'Requests' },
                  { key: 'schedule', label: 'Schedule' }
                ].map((tab) => (
                  <button
                    key={tab.key}
                    onClick={() => setSelectedTab(tab.key as any)}
                    className={`px-4 py-2 text-sm font-medium rounded-md transition-colors ${
                      selectedTab === tab.key
                        ? 'bg-white text-blue-600 shadow-sm'
                        : 'text-gray-600 hover:text-gray-900'
                    }`}
                  >
                    {tab.label}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 py-6">
        {/* Team Stats */}
        <div className="grid grid-cols-1 md:grid-cols-5 gap-6 mb-8">
          <StatCard
            title="Total Members"
            value={teamStats.totalMembers}
            icon={Users}
            color="bg-blue-600"
          />
          <StatCard
            title="Active"
            value={teamStats.activeMembers}
            icon={CheckCircle}
            color="bg-green-600"
          />
          <StatCard
            title="On Leave"
            value={teamStats.onLeave}
            icon={Calendar}
            color="bg-yellow-600"
          />
          <StatCard
            title="Pending Requests"
            value={teamStats.pendingRequests}
            icon={AlertTriangle}
            color="bg-red-600"
          />
          <StatCard
            title="Weekly Hours"
            value={teamStats.weeklyHours}
            icon={Clock}
            color="bg-purple-600"
          />
        </div>

        {/* Performance Indicators (Real Data) */}
        {dashboardData && (
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
            <div className="bg-white rounded-lg p-6 shadow-sm border">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Team Productivity</p>
                  <p className="text-2xl font-bold text-gray-900">{dashboardData.performance_indicators.team_productivity}%</p>
                </div>
                <div className="p-3 rounded-full bg-green-600">
                  <TrendingUp className="h-6 w-6 text-white" />
                </div>
              </div>
            </div>
            <div className="bg-white rounded-lg p-6 shadow-sm border">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Customer Satisfaction</p>
                  <p className="text-2xl font-bold text-gray-900">{dashboardData.performance_indicators.customer_satisfaction}/5.0</p>
                </div>
                <div className="p-3 rounded-full bg-blue-600">
                  <Users className="h-6 w-6 text-white" />
                </div>
              </div>
            </div>
            <div className="bg-white rounded-lg p-6 shadow-sm border">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Avg Handle Time</p>
                  <p className="text-2xl font-bold text-gray-900">{dashboardData.performance_indicators.average_handle_time}</p>
                </div>
                <div className="p-3 rounded-full bg-purple-600">
                  <Clock className="h-6 w-6 text-white" />
                </div>
              </div>
            </div>
            <div className="bg-white rounded-lg p-6 shadow-sm border">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Resolution Rate</p>
                  <p className="text-2xl font-bold text-gray-900">{dashboardData.performance_indicators.resolution_rate}%</p>
                </div>
                <div className="p-3 rounded-full bg-orange-600">
                  <CheckCircle className="h-6 w-6 text-white" />
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Formal SPEC-04 Team Members */}
        {formalData && (
          <div className="bg-white rounded-lg shadow-sm border mb-8">
            <div className="p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Team Members (SPEC-04 Formal Data)</h2>
            </div>
            <div className="p-6">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {formalData.team_members.map((member) => (
                  <div key={member.id} className="p-4 border border-gray-200 rounded-lg">
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="font-medium text-gray-900">{member.name}</div>
                        <div className="text-sm text-gray-600">{member.agent_code} • {member.role}</div>
                        <div className="text-sm text-gray-500">
                          {member.has_schedule_today ? 'Scheduled today' : 'No schedule today'}
                        </div>
                      </div>
                      <div className="text-right">
                        <div className={`px-2 py-1 text-xs font-medium rounded-full ${
                          member.has_schedule_today ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                        }`}>
                          {member.has_schedule_today ? 'Active' : 'Off'}
                        </div>
                        {member.pending_requests > 0 && (
                          <div className="text-xs text-orange-600 mt-1">
                            {member.pending_requests} pending
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Formal SPEC-04 Alerts */}
        {formalData && formalData.alerts.length > 0 && (
          <div className="bg-white rounded-lg shadow-sm border mb-8">
            <div className="p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Formal Manager Alerts (SPEC-04)</h2>
            </div>
            <div className="p-6">
              <div className="space-y-4">
                {formalData.alerts.map((alert, index) => (
                  <div key={index} className="p-4 rounded-lg border-l-4 border-red-500 bg-red-50">
                    <div className="flex items-center gap-3">
                      <AlertTriangle className="h-5 w-5 text-red-600" />
                      <div>
                        <p className="font-medium text-gray-900">{alert.type.replace('_', ' ').toUpperCase()}</p>
                        <p className="text-sm text-gray-600">{alert.message}</p>
                        <p className="text-xs text-gray-500 mt-1">
                          {new Date(alert.created_at).toLocaleString()}
                          {alert.request_id && ` • Request ID: ${alert.request_id}`}
                        </p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Enhanced Alerts Section (Enhanced Data) */}
        {dashboardData && dashboardData.alerts.length > 0 && (
          <div className="bg-white rounded-lg shadow-sm border mb-8">
            <div className="p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Enhanced Analytics Alerts</h2>
            </div>
            <div className="p-6">
              <div className="space-y-4">
                {dashboardData.alerts.map((alert, index) => (
                  <div key={index} className={`p-4 rounded-lg border-l-4 ${
                    alert.priority === 'high' ? 'border-red-500 bg-red-50' :
                    alert.priority === 'medium' ? 'border-yellow-500 bg-yellow-50' :
                    'border-blue-500 bg-blue-50'
                  }`}>
                    <div className="flex items-center gap-3">
                      <AlertTriangle className={`h-5 w-5 ${
                        alert.priority === 'high' ? 'text-red-600' :
                        alert.priority === 'medium' ? 'text-yellow-600' :
                        'text-blue-600'
                      }`} />
                      <div>
                        <p className="font-medium text-gray-900">{alert.type.toUpperCase()}</p>
                        <p className="text-sm text-gray-600">{alert.message}</p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Tab Content */}
        {selectedTab === 'overview' && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Team Members */}
            <div className="bg-white rounded-lg shadow-sm border">
              <div className="p-6 border-b">
                <h2 className="text-lg font-semibold text-gray-900">Team Members</h2>
              </div>
              <div className="p-6">
                <div className="space-y-4">
                  {teamMembers.map((member) => (
                    <div key={member.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                          <span className="text-blue-600 font-medium text-sm">
                            {member.name.split(' ').map(n => n[0]).join('')}
                          </span>
                        </div>
                        <div>
                          <div className="font-medium text-gray-900">{member.name}</div>
                          <div className="text-sm text-gray-600">{member.role}</div>
                        </div>
                      </div>
                      <div className="flex items-center gap-3">
                        <div className="text-right">
                          <div className="text-sm font-medium text-gray-900">{member.hoursThisWeek}h</div>
                          <div className="text-xs text-gray-500">{member.shiftsThisWeek} shifts</div>
                        </div>
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(member.status)}`}>
                          {member.status.replace('_', ' ')}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Quick Actions */}
            <div className="bg-white rounded-lg shadow-sm border">
              <div className="p-6 border-b">
                <h2 className="text-lg font-semibold text-gray-900">Quick Actions</h2>
              </div>
              <div className="p-6">
                <div className="space-y-3">
                  <button className="w-full text-left p-4 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors">
                    <div className="flex items-center gap-3">
                      <FileText className="h-5 w-5 text-blue-600" />
                      <div>
                        <div className="font-medium text-blue-900">Review Pending Requests</div>
                        <div className="text-sm text-blue-700">{pendingRequests.length} requests awaiting approval</div>
                      </div>
                    </div>
                  </button>
                  <button className="w-full text-left p-4 bg-green-50 rounded-lg hover:bg-green-100 transition-colors">
                    <div className="flex items-center gap-3">
                      <Calendar className="h-5 w-5 text-green-600" />
                      <div>
                        <div className="font-medium text-green-900">View Team Schedule</div>
                        <div className="text-sm text-green-700">Current week overview</div>
                      </div>
                    </div>
                  </button>
                  <button className="w-full text-left p-4 bg-purple-50 rounded-lg hover:bg-purple-100 transition-colors">
                    <div className="flex items-center gap-3">
                      <TrendingUp className="h-5 w-5 text-purple-600" />
                      <div>
                        <div className="font-medium text-purple-900">Team Performance</div>
                        <div className="text-sm text-purple-700">View analytics and reports</div>
                      </div>
                    </div>
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {selectedTab === 'requests' && (
          <div className="bg-white rounded-lg shadow-sm border">
            <div className="p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Pending Approval Requests</h2>
            </div>
            <div className="p-6">
              <div className="space-y-4">
                {pendingRequests.map((request) => (
                  <div key={request.id} className="p-4 border border-gray-200 rounded-lg">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-4">
                        <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                          <span className="text-gray-600 font-medium text-sm">
                            {request.employeeName.split(' ').map(n => n[0]).join('')}
                          </span>
                        </div>
                        <div>
                          <div className="font-medium text-gray-900">{request.employeeName}</div>
                          <div className="text-sm text-gray-600">{request.startDate} - {request.endDate} ({request.days} days)</div>
                          <div className="text-sm text-gray-500 mt-1">{request.reason}</div>
                        </div>
                      </div>
                      <div className="flex items-center gap-3">
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${getRequestTypeColor(request.type)}`}>
                          {request.type}
                        </span>
                        <div className="flex gap-2">
                          <button
                            onClick={() => handleApproveRequest(request.id)}
                            disabled={actionLoading === request.id}
                            className="flex items-center gap-1 px-3 py-1 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                          >
                            {actionLoading === request.id ? (
                              <Loader2 className="h-4 w-4 animate-spin" />
                            ) : (
                              <CheckCircle className="h-4 w-4" />
                            )}
                            Approve
                          </button>
                          <button
                            onClick={() => handleRejectRequest(request.id)}
                            disabled={actionLoading === request.id}
                            className="flex items-center gap-1 px-3 py-1 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                          >
                            {actionLoading === request.id ? (
                              <Loader2 className="h-4 w-4 animate-spin" />
                            ) : (
                              <XCircle className="h-4 w-4" />
                            )}
                            Reject
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {selectedTab === 'schedule' && (
          <div className="bg-white rounded-lg shadow-sm border">
            <div className="p-6 border-b">
              <h2 className="text-lg font-semibold text-gray-900">Team Schedule Overview</h2>
            </div>
            <div className="p-6">
              <div className="text-center py-12">
                <Calendar className="h-16 w-16 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">Schedule Overview</h3>
                <p className="text-gray-600">
                  Team schedule functionality would be integrated here
                </p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ManagerDashboard;