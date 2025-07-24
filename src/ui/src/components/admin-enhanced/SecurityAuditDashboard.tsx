import React, { useState, useEffect } from 'react';
import { 
  Shield, 
  AlertTriangle, 
  TrendingUp, 
  TrendingDown, 
  Users, 
  Activity,
  CheckCircle,
  XCircle,
  RefreshCw,
  Clock,
  Lock,
  Globe,
  Eye
} from 'lucide-react';
import { enhancedAuthService, SecurityPostureResponse } from '../../services/realAuthService';

interface SecurityEvent {
  id: string;
  timestamp: string;
  type: 'login' | 'logout' | 'failed_login' | 'permission_change' | 'data_access';
  user: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  description: string;
  ipAddress: string;
}

interface SecurityPostureMetrics {
  security_posture_score: number;
  authentication_metrics: {
    total_attempts: number;
    success_rate: number;
    failed_attempts: number;
    blocked_attempts: number;
    unique_users: number;
    average_session_duration: string;
  };
  threat_detection: {
    suspicious_activities: number;
    blocked_ips: number;
    anomaly_score: number;
    threat_level: string;
  };
  compliance_status: {
    zero_trust_coverage: string;
    mfa_adoption: string;
    password_policy_compliance: string;
    session_management_score: number;
  };
  recommendations: string[];
  trend_analysis: {
    authentication_trend: string;
    security_incidents_trend: string;
    user_adoption_trend: string;
  };
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

const SecurityAuditDashboard: React.FC = () => {
  const [events, setEvents] = useState<SecurityEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filterSeverity, setFilterSeverity] = useState('all');
  
  // Enhanced Security Analytics State
  const [securityPosture, setSecurityPosture] = useState<SecurityPostureMetrics | null>(null);
  const [postureLoading, setPostureLoading] = useState(false);
  const [postureError, setPostureError] = useState<string | null>(null);
  const [timeRange, setTimeRange] = useState('7d');
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [autoRefresh, setAutoRefresh] = useState(true);

  useEffect(() => {
    fetchSecurityEvents();
    loadSecurityPosture();
  }, []);

  useEffect(() => {
    loadSecurityPosture();
  }, [timeRange]);

  const fetchSecurityEvents = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/admin/security/audit/dashboard`);
      if (!response.ok) throw new Error('Ошибка загрузки событий безопасности');
      const data = await response.json();
      setEvents(data.events || []);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Неизвестная ошибка');
    } finally {
      setLoading(false);
    }
  };

  const loadSecurityPosture = async () => {
    try {
      setPostureLoading(true);
      setPostureError(null);
      
      const result = await enhancedAuthService.getSecurityPostureAnalytics(timeRange);
      
      if (result.success && result.data) {
        setSecurityPosture(result.data);
        setLastUpdate(new Date());
        console.log('[SECURITY DASHBOARD] Security posture data loaded:', result.data);
      } else {
        setPostureError(result.error || 'Failed to load security posture');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setPostureError(errorMessage);
      console.error('[SECURITY DASHBOARD] Posture load error:', errorMessage);
    } finally {
      setPostureLoading(false);
    }
  };

  // Auto-refresh security posture every 5 minutes
  useEffect(() => {
    if (!autoRefresh) return;

    const interval = setInterval(async () => {
      try {
        await loadSecurityPosture();
      } catch (error) {
        console.warn('[SECURITY DASHBOARD] Auto-refresh failed:', error);
      }
    }, 300000); // 5 minutes

    return () => clearInterval(interval);
  }, [autoRefresh, timeRange]);

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return '#e74c3c';
      case 'high': return '#f39c12';
      case 'medium': return '#f1c40f';
      case 'low': return '#27ae60';
      default: return '#95a5a6';
    }
  };

  const getPostureScoreColor = (score: number) => {
    if (score >= 90) return 'text-green-600 bg-green-100 border-green-200';
    if (score >= 75) return 'text-blue-600 bg-blue-100 border-blue-200';
    if (score >= 60) return 'text-yellow-600 bg-yellow-100 border-yellow-200';
    return 'text-red-600 bg-red-100 border-red-200';
  };

  const getThreatLevelColor = (level: string) => {
    switch (level.toLowerCase()) {
      case 'low': return 'text-green-600 bg-green-50 border-green-200';
      case 'medium': return 'text-yellow-600 bg-yellow-50 border-yellow-200';
      case 'high': return 'text-red-600 bg-red-50 border-red-200';
      case 'critical': return 'text-red-800 bg-red-100 border-red-300';
      default: return 'text-gray-600 bg-gray-50 border-gray-200';
    }
  };

  const getTrendIcon = (trend: string) => {
    switch (trend.toLowerCase()) {
      case 'increasing': return <TrendingUp className="h-4 w-4 text-green-500" />;
      case 'decreasing': return <TrendingDown className="h-4 w-4 text-red-500" />;
      case 'stable': return <Activity className="h-4 w-4 text-blue-500" />;
      default: return <Activity className="h-4 w-4 text-gray-500" />;
    }
  };

  const renderSecurityPostureGauge = (score: number) => {
    const radius = 50;
    const strokeWidth = 8;
    const normalizedRadius = radius - strokeWidth * 2;
    const circumference = normalizedRadius * 2 * Math.PI;
    const strokeDasharray = `${circumference} ${circumference}`;
    const strokeDashoffset = circumference - (score / 100) * circumference;

    return (
      <div className="relative w-32 h-32">
        <svg
          height={radius * 2}
          width={radius * 2}
          className="transform -rotate-90"
        >
          <circle
            stroke="#e5e7eb"
            fill="transparent"
            strokeWidth={strokeWidth}
            r={normalizedRadius}
            cx={radius}
            cy={radius}
          />
          <circle
            stroke={score >= 80 ? "#10b981" : score >= 60 ? "#f59e0b" : "#ef4444"}
            fill="transparent"
            strokeWidth={strokeWidth}
            strokeDasharray={strokeDasharray}
            style={{ strokeDashoffset }}
            strokeLinecap="round"
            r={normalizedRadius}
            cx={radius}
            cy={radius}
            className="transition-all duration-1000"
          />
        </svg>
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="text-center">
            <div className="text-2xl font-bold text-gray-900">{score}</div>
            <div className="text-xs text-gray-500">Score</div>
          </div>
        </div>
      </div>
    );
  };

  const filteredEvents = events.filter(event => 
    filterSeverity === 'all' || event.severity === filterSeverity
  );

  if (loading && !securityPosture) {
    return (
      <div className="p-6 space-y-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="animate-pulse">
            <div className="h-8 bg-gray-200 rounded w-1/3 mb-4"></div>
            <div className="h-4 bg-gray-200 rounded w-1/2"></div>
          </div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[1,2,3,4].map((i) => (
            <div key={i} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 animate-pulse">
              <div className="h-24 bg-gray-200 rounded"></div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header with Controls */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 flex items-center">
              <Shield className="h-6 w-6 mr-2 text-blue-600" />
              Security Analytics Dashboard
            </h1>
            <p className="text-gray-500 flex items-center mt-1">
              <span className="text-xl mr-2">🛡️</span>
              Advanced security posture monitoring and threat detection
            </p>
          </div>
          
          <div className="flex items-center space-x-4">
            <select 
              value={timeRange} 
              onChange={(e) => setTimeRange(e.target.value)}
              className="border border-gray-300 rounded px-3 py-1 text-sm"
            >
              <option value="1d">Last 24 Hours</option>
              <option value="7d">Last 7 Days</option>
              <option value="30d">Last 30 Days</option>
            </select>
            
            <button
              onClick={() => setAutoRefresh(!autoRefresh)}
              className={`flex items-center space-x-2 px-3 py-1 rounded text-sm transition-colors ${
                autoRefresh ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'
              }`}
            >
              <RefreshCw className={`h-4 w-4 ${postureLoading ? 'animate-spin' : ''}`} />
              <span>{autoRefresh ? 'Auto-refresh ON' : 'Auto-refresh OFF'}</span>
            </button>
            
            <div className="text-sm text-gray-500">
              <Clock className="h-4 w-4 inline mr-1" />
              Updated: {lastUpdate.toLocaleTimeString()}
            </div>
          </div>
        </div>
      </div>

      {/* Error Display */}
      {(error || postureError) && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center gap-2 text-red-800">
            <AlertTriangle className="h-5 w-5 text-red-500" />
            <div>
              <div className="font-medium">Connection Failed</div>
              <div className="text-sm">{error || postureError}</div>
            </div>
            <button
              onClick={() => {
                fetchSecurityEvents();
                loadSecurityPosture();
              }}
              className="ml-auto px-3 py-1 bg-red-100 text-red-700 rounded text-sm hover:bg-red-200"
            >
              Retry
            </button>
          </div>
        </div>
      )}

      {/* Security Posture Overview */}
      {securityPosture && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Overall Security Score */}
          <div className={`bg-white rounded-lg shadow-sm border-2 p-6 ${getPostureScoreColor(securityPosture.security_posture_score)}`}>
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-semibold text-gray-900 flex items-center">
                <Shield className="h-5 w-5 mr-2" />
                Security Posture Score
              </h3>
              {getTrendIcon(securityPosture.trend_analysis.security_incidents_trend)}
            </div>
            
            <div className="flex items-center justify-center">
              {renderSecurityPostureGauge(securityPosture.security_posture_score)}
            </div>
            
            <p className="text-sm text-gray-600 text-center mt-4">
              Overall security health and compliance rating
            </p>
          </div>

          {/* Authentication Metrics */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="font-semibold text-gray-900 mb-4 flex items-center">
              <Users className="h-5 w-5 mr-2 text-blue-600" />
              Authentication Overview
            </h3>
            
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Success Rate</span>
                <span className="font-semibold text-green-600">
                  {securityPosture.authentication_metrics.success_rate.toFixed(1)}%
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Total Attempts</span>
                <span className="font-semibold">
                  {securityPosture.authentication_metrics.total_attempts.toLocaleString()}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Failed Attempts</span>
                <span className="font-semibold text-red-600">
                  {securityPosture.authentication_metrics.failed_attempts}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Blocked Attempts</span>
                <span className="font-semibold text-red-800">
                  {securityPosture.authentication_metrics.blocked_attempts}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600">Unique Users</span>
                <span className="font-semibold text-blue-600">
                  {securityPosture.authentication_metrics.unique_users}
                </span>
              </div>
            </div>
          </div>

          {/* Threat Detection */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="font-semibold text-gray-900 mb-4 flex items-center">
              <Eye className="h-5 w-5 mr-2 text-red-600" />
              Threat Detection
            </h3>
            
            <div className="space-y-4">
              <div className={`p-3 rounded-lg border ${getThreatLevelColor(securityPosture.threat_detection.threat_level)}`}>
                <div className="flex justify-between items-center">
                  <span className="font-medium">Threat Level</span>
                  <span className="uppercase text-sm font-semibold">
                    {securityPosture.threat_detection.threat_level}
                  </span>
                </div>
              </div>
              
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Suspicious Activities</span>
                  <span className="font-semibold text-orange-600">
                    {securityPosture.threat_detection.suspicious_activities}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Blocked IPs</span>
                  <span className="font-semibold text-red-600">
                    {securityPosture.threat_detection.blocked_ips}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Anomaly Score</span>
                  <span className="font-semibold">
                    {securityPosture.threat_detection.anomaly_score.toFixed(1)}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Compliance Status */}
      {securityPosture && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-6 flex items-center">
            <CheckCircle className="h-5 w-5 mr-2 text-green-600" />
            Compliance & Adoption Status
          </h3>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="text-center p-4 bg-blue-50 rounded-lg">
              <Lock className="h-8 w-8 text-blue-600 mx-auto mb-2" />
              <div className="text-2xl font-bold text-blue-600">
                {securityPosture.compliance_status.zero_trust_coverage}
              </div>
              <div className="text-sm text-gray-600">Zero Trust Coverage</div>
            </div>
            
            <div className="text-center p-4 bg-green-50 rounded-lg">
              <Shield className="h-8 w-8 text-green-600 mx-auto mb-2" />
              <div className="text-2xl font-bold text-green-600">
                {securityPosture.compliance_status.mfa_adoption}
              </div>
              <div className="text-sm text-gray-600">MFA Adoption</div>
            </div>
            
            <div className="text-center p-4 bg-yellow-50 rounded-lg">
              <Globe className="h-8 w-8 text-yellow-600 mx-auto mb-2" />
              <div className="text-2xl font-bold text-yellow-600">
                {securityPosture.compliance_status.password_policy_compliance}
              </div>
              <div className="text-sm text-gray-600">Password Policy</div>
            </div>
            
            <div className="text-center p-4 bg-purple-50 rounded-lg">
              <Activity className="h-8 w-8 text-purple-600 mx-auto mb-2" />
              <div className="text-2xl font-bold text-purple-600">
                {securityPosture.compliance_status.session_management_score.toFixed(1)}
              </div>
              <div className="text-sm text-gray-600">Session Management</div>
            </div>
          </div>
        </div>
      )}

      {/* Security Recommendations */}
      {securityPosture && securityPosture.recommendations.length > 0 && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
            <AlertTriangle className="h-5 w-5 mr-2 text-orange-600" />
            Security Recommendations
          </h3>
          
          <div className="space-y-3">
            {securityPosture.recommendations.map((recommendation, index) => (
              <div key={index} className="flex items-start p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
                <AlertTriangle className="h-5 w-5 text-yellow-600 mr-3 mt-0.5 flex-shrink-0" />
                <p className="text-sm text-gray-700">{recommendation}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Traditional Security Events */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-semibold text-gray-900">Security Events</h3>
          <select 
            value={filterSeverity} 
            onChange={(e) => setFilterSeverity(e.target.value)}
            className="border border-gray-300 rounded px-3 py-1 text-sm"
          >
            <option value="all">All Levels</option>
            <option value="critical">Critical</option>
            <option value="high">High</option>
            <option value="medium">Medium</option>
            <option value="low">Low</option>
          </select>
        </div>

        {/* Event Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div className="text-center p-3 bg-red-50 rounded-lg border border-red-200">
            <div className="text-2xl font-bold text-red-600">
              {events.filter(e => e.severity === 'critical').length}
            </div>
            <div className="text-sm text-gray-600">Critical</div>
          </div>
          <div className="text-center p-3 bg-orange-50 rounded-lg border border-orange-200">
            <div className="text-2xl font-bold text-orange-600">
              {events.filter(e => e.severity === 'high').length}
            </div>
            <div className="text-sm text-gray-600">High</div>
          </div>
          <div className="text-center p-3 bg-yellow-50 rounded-lg border border-yellow-200">
            <div className="text-2xl font-bold text-yellow-600">
              {events.filter(e => e.severity === 'medium').length}
            </div>
            <div className="text-sm text-gray-600">Medium</div>
          </div>
          <div className="text-center p-3 bg-green-50 rounded-lg border border-green-200">
            <div className="text-2xl font-bold text-green-600">
              {events.filter(e => e.severity === 'low').length}
            </div>
            <div className="text-sm text-gray-600">Low</div>
          </div>
        </div>

        {/* Events List */}
        <div className="space-y-3">
          {filteredEvents.map(event => (
            <div key={event.id} className="border border-gray-200 rounded-lg p-4">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center space-x-3">
                  <div 
                    className="w-3 h-3 rounded-full"
                    style={{ backgroundColor: getSeverityColor(event.severity) }}
                  ></div>
                  <h4 className="font-medium text-gray-900">{event.description}</h4>
                </div>
                <span className="text-sm text-gray-500">
                  {new Date(event.timestamp).toLocaleString()}
                </span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm text-gray-600">
                <div><strong>User:</strong> {event.user}</div>
                <div><strong>IP Address:</strong> {event.ipAddress}</div>
                <div><strong>Event Type:</strong> {event.type}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Status Footer */}
      <div className="bg-gray-50 rounded-lg p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="flex items-center">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse mr-2"></div>
              <span className="text-sm text-gray-600">Security dashboard active</span>
            </div>
            <div className="text-sm text-gray-500">
              Auto-refresh: 5 minutes
            </div>
          </div>
          <div className="flex items-center space-x-4 text-sm text-gray-500">
            <span>🛡️ Posture Score: {securityPosture?.security_posture_score || 'N/A'}</span>
            <span>🔍 Events: {filteredEvents.length}</span>
            <span>⏰ Updated: {lastUpdate.toLocaleTimeString()}</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SecurityAuditDashboard;