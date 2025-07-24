import React, { useState, useEffect } from 'react';
import { 
  Shield, 
  AlertTriangle, 
  CheckCircle, 
  Clock, 
  RefreshCw,
  Activity,
  Lock,
  Unlock,
  Eye,
  User,
  Globe,
  Smartphone
} from 'lucide-react';
import { enhancedAuthService, AdaptiveAuthResponse } from '../../services/realAuthService';

interface AdaptiveAuthIndicatorProps {
  /**
   * Display mode for different UI contexts
   */
  mode?: 'compact' | 'detailed' | 'widget';
  
  /**
   * Auto-refresh interval in seconds
   */
  refreshInterval?: number;
  
  /**
   * Show risk breakdown details
   */
  showRiskBreakdown?: boolean;
  
  /**
   * Callback when authentication status changes
   */
  onAuthStatusChange?: (authData: AdaptiveAuthResponse['data']) => void;
}

const AdaptiveAuthIndicator: React.FC<AdaptiveAuthIndicatorProps> = ({
  mode = 'widget',
  refreshInterval = 180, // 3 minutes
  showRiskBreakdown = true,
  onAuthStatusChange
}) => {
  const [authData, setAuthData] = useState<AdaptiveAuthResponse['data'] | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState(new Date());

  // Auto-refresh adaptive authentication status
  useEffect(() => {
    loadAdaptiveAuthStatus();
    
    const interval = setInterval(() => {
      loadAdaptiveAuthStatus();
    }, refreshInterval * 1000);

    return () => clearInterval(interval);
  }, [refreshInterval]);

  // Notify parent of auth status changes
  useEffect(() => {
    if (authData) {
      onAuthStatusChange?.(authData);
    }
  }, [authData, onAuthStatusChange]);

  const loadAdaptiveAuthStatus = async () => {
    try {
      setError(null);
      
      const currentUser = JSON.parse(localStorage.getItem('wfm_user') || '{}');
      
      // Create adaptive auth request with contextual information
      const authRequest = {
        requested_access: 'dashboard_access',
        risk_context: {
          user_id: currentUser.id || 1,
          session_duration: getSessionDuration(),
          access_patterns: getAccessPatterns(),
          device_info: getDeviceInfo(),
          location_context: getLocationContext()
        },
        session_duration: 480 // 8 hours
      };

      const result = await enhancedAuthService.performAdaptiveAuthentication(authRequest);
      
      if (result.success && result.data) {
        setAuthData(result.data);
        setLastUpdate(new Date());
        console.log('[ADAPTIVE AUTH] Authentication data loaded:', result.data);
      } else {
        setError(result.error || 'Failed to load adaptive authentication status');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Adaptive authentication failed';
      setError(errorMessage);
      console.error('[ADAPTIVE AUTH] Authentication error:', errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const getSessionDuration = (): number => {
    const loginTime = localStorage.getItem('wfm_login_time');
    if (!loginTime) return 0;
    
    const now = new Date().getTime();
    const login = new Date(loginTime).getTime();
    return Math.floor((now - login) / (1000 * 60)); // minutes
  };

  const getAccessPatterns = (): any => {
    return {
      frequent_features: ['dashboard', 'team_schedule', 'requests'],
      usage_frequency: 'high',
      typical_hours: 'business_hours',
      behavioral_consistency: 'normal'
    };
  };

  const getDeviceInfo = (): any => {
    return {
      device_type: 'desktop',
      browser: navigator.userAgent.split(' ')[0],
      screen_resolution: `${screen.width}x${screen.height}`,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
    };
  };

  const getLocationContext = (): any => {
    return {
      ip_changed: false,
      location_consistent: true,
      network_type: 'corporate',
      trust_level: 'high'
    };
  };

  const getRiskLevelColor = (level: string) => {
    switch (level.toLowerCase()) {
      case 'low': return { bg: 'bg-green-50', border: 'border-green-200', text: 'text-green-700', icon: 'text-green-500' };
      case 'medium': return { bg: 'bg-yellow-50', border: 'border-yellow-200', text: 'text-yellow-700', icon: 'text-yellow-500' };
      case 'high': return { bg: 'bg-red-50', border: 'border-red-200', text: 'text-red-700', icon: 'text-red-500' };
      default: return { bg: 'bg-gray-50', border: 'border-gray-200', text: 'text-gray-700', icon: 'text-gray-500' };
    }
  };

  const getAccessStatusIcon = (granted: boolean) => {
    return granted ? 
      <CheckCircle className="h-5 w-5 text-green-500" /> :
      <AlertTriangle className="h-5 w-5 text-red-500" />;
  };

  const getRiskFactorIcon = (factor: string) => {
    switch (factor.toLowerCase()) {
      case 'user_behavior': return <User className="h-4 w-4" />;
      case 'device_trust': return <Smartphone className="h-4 w-4" />;
      case 'location_risk': return <Globe className="h-4 w-4" />;
      case 'session_context': return <Clock className="h-4 w-4" />;
      case 'access_patterns': return <Activity className="h-4 w-4" />;
      default: return <Eye className="h-4 w-4" />;
    }
  };

  const formatTimeRemaining = (hours: number): string => {
    if (hours < 1) {
      const minutes = Math.floor(hours * 60);
      return `${minutes}m`;
    }
    return `${Math.floor(hours)}h ${Math.floor((hours % 1) * 60)}m`;
  };

  // Compact mode for headers/navigation
  if (mode === 'compact') {
    if (loading) {
      return (
        <div className="flex items-center space-x-2 px-2 py-1">
          <RefreshCw className="h-4 w-4 animate-spin text-gray-400" />
          <span className="text-xs text-gray-500">Auth...</span>
        </div>
      );
    }

    if (error || !authData) {
      return (
        <div className="flex items-center space-x-2 px-2 py-1 bg-red-50 rounded">
          <AlertTriangle className="h-4 w-4 text-red-500" />
          <span className="text-xs text-red-600">Auth Error</span>
        </div>
      );
    }

    const colors = getRiskLevelColor(authData.risk_level);
    
    return (
      <div className={`flex items-center space-x-2 px-2 py-1 ${colors.bg} ${colors.border} border rounded`}>
        {authData.access_granted ? 
          <Lock className="h-4 w-4 text-green-500" /> :
          <Unlock className="h-4 w-4 text-red-500" />
        }
        <span className={`text-xs font-medium ${colors.text}`}>
          {authData.risk_level.toUpperCase()}
        </span>
        <span className="text-xs text-gray-600">
          {authData.risk_score.toFixed(0)}
        </span>
      </div>
    );
  }

  // Detailed mode for dedicated auth panels
  if (mode === 'detailed') {
    if (loading) {
      return (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="animate-pulse">
            <div className="h-6 bg-gray-200 rounded w-1/3 mb-4"></div>
            <div className="h-32 bg-gray-200 rounded mb-4"></div>
            <div className="h-4 bg-gray-200 rounded w-1/2"></div>
          </div>
        </div>
      );
    }

    return (
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div>
            <h3 className="text-lg font-semibold text-gray-900 flex items-center">
              <Shield className="h-5 w-5 mr-2 text-blue-600" />
              Adaptive Authentication
            </h3>
            <p className="text-gray-500 text-sm mt-1">
              Real-time risk assessment and access control
            </p>
          </div>
          
          <button
            onClick={loadAdaptiveAuthStatus}
            disabled={loading}
            className="flex items-center space-x-2 px-3 py-1 bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            <span className="text-sm">Refresh</span>
          </button>
        </div>

        {/* Error Display */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
            <div className="flex items-center gap-2 text-red-800">
              <AlertTriangle className="h-5 w-5 text-red-500" />
              <div>
                <div className="font-medium">Authentication Check Failed</div>
                <div className="text-sm">{error}</div>
              </div>
              <button
                onClick={loadAdaptiveAuthStatus}
                className="ml-auto px-3 py-1 bg-red-100 text-red-700 rounded text-sm hover:bg-red-200"
              >
                Retry
              </button>
            </div>
          </div>
        )}

        {/* Authentication Status */}
        {authData && (
          <div className="space-y-6">
            {/* Access Status and Risk Score */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className={`p-4 ${authData.access_granted ? 'bg-green-50 border-green-200' : 'bg-red-50 border-red-200'} border rounded-lg`}>
                <div className="flex items-center justify-between mb-3">
                  <h4 className="font-medium text-gray-900">Access Status</h4>
                  {getAccessStatusIcon(authData.access_granted)}
                </div>
                <div className="text-2xl font-bold mb-1">
                  {authData.access_granted ? 'GRANTED' : 'DENIED'}
                </div>
                <div className="text-sm text-gray-600">
                  Authentication ID: {authData.authentication_id}
                </div>
              </div>

              <div className={`p-4 ${getRiskLevelColor(authData.risk_level).bg} ${getRiskLevelColor(authData.risk_level).border} border rounded-lg`}>
                <div className="flex items-center justify-between mb-3">
                  <h4 className="font-medium text-gray-900">Risk Assessment</h4>
                  <Activity className={`h-5 w-5 ${getRiskLevelColor(authData.risk_level).icon}`} />
                </div>
                <div className="text-2xl font-bold mb-1">
                  {authData.risk_score.toFixed(1)}
                </div>
                <div className={`text-sm font-medium ${getRiskLevelColor(authData.risk_level).text}`}>
                  {authData.risk_level.toUpperCase()} RISK
                </div>
              </div>
            </div>

            {/* Access Restrictions */}
            {authData.access_restrictions && (
              <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
                <h4 className="font-medium text-gray-900 mb-3">Access Restrictions</h4>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                  <div className="flex items-center justify-between">
                    <span className="text-gray-600">Time Limited:</span>
                    <span className={`font-medium ${authData.access_restrictions.time_limited ? 'text-yellow-600' : 'text-green-600'}`}>
                      {authData.access_restrictions.time_limited ? 'Yes' : 'No'}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-gray-600">Session Duration:</span>
                    <span className="font-medium text-gray-900">
                      {formatTimeRemaining(authData.access_restrictions.session_duration_hours)}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-gray-600">Monitoring:</span>
                    <span className={`font-medium ${authData.access_restrictions.requires_monitoring ? 'text-yellow-600' : 'text-green-600'}`}>
                      {authData.access_restrictions.requires_monitoring ? 'Required' : 'Standard'}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-gray-600">IP Restriction:</span>
                    <span className={`font-medium ${authData.access_restrictions.ip_restriction ? 'text-yellow-600' : 'text-green-600'}`}>
                      {authData.access_restrictions.ip_restriction ? 'Active' : 'None'}
                    </span>
                  </div>
                </div>
              </div>
            )}

            {/* Risk Breakdown */}
            {showRiskBreakdown && authData.risk_breakdown && Object.keys(authData.risk_breakdown).length > 0 && (
              <div className="bg-white border border-gray-200 rounded-lg p-4">
                <h4 className="font-medium text-gray-900 mb-3">Risk Factor Analysis</h4>
                <div className="space-y-3">
                  {Object.entries(authData.risk_breakdown).map(([factor, score]) => (
                    <div key={factor} className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        {getRiskFactorIcon(factor)}
                        <span className="text-sm text-gray-700 capitalize">
                          {factor.replace('_', ' ')}
                        </span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <div className="w-20 bg-gray-200 rounded-full h-2">
                          <div 
                            className={`h-2 rounded-full ${
                              score > 70 ? 'bg-red-500' : score > 40 ? 'bg-yellow-500' : 'bg-green-500'
                            }`}
                            style={{ width: `${score}%` }}
                          />
                        </div>
                        <span className="text-sm font-medium text-gray-900 w-10 text-right">
                          {score}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Mitigation Strategies */}
            {authData.mitigation_strategies.length > 0 && (
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <h4 className="font-medium text-blue-900 mb-3 flex items-center">
                  <CheckCircle className="h-5 w-5 mr-2 text-blue-600" />
                  Recommended Actions
                </h4>
                <div className="space-y-2">
                  {authData.mitigation_strategies.map((strategy, index) => (
                    <div key={index} className="flex items-start p-2">
                      <CheckCircle className="h-4 w-4 text-blue-600 mr-2 mt-0.5 flex-shrink-0" />
                      <p className="text-sm text-gray-700">{strategy}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* Status Footer */}
        <div className="mt-6 pt-4 border-t border-gray-200">
          <div className="flex items-center justify-between text-sm text-gray-500">
            <div className="flex items-center space-x-4">
              <div className="flex items-center">
                <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse mr-2"></div>
                <span>Adaptive auth active</span>
              </div>
              <span>Refresh: {refreshInterval / 60} min</span>
            </div>
            <div className="flex items-center space-x-4">
              <span>🛡️ Risk: {authData?.risk_score.toFixed(0) || 'N/A'}</span>
              <span>⏰ Updated: {lastUpdate.toLocaleTimeString()}</span>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Widget mode for dashboard cards (default)
  if (loading) {
    return (
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <div className="flex items-center justify-center">
          <RefreshCw className="h-6 w-6 animate-spin text-gray-400" />
        </div>
      </div>
    );
  }

  if (error || !authData) {
    return (
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <div className="text-center">
          <AlertTriangle className="h-6 w-6 text-red-500 mx-auto mb-2" />
          <p className="text-sm text-red-600">Auth check failed</p>
        </div>
      </div>
    );
  }

  const colors = getRiskLevelColor(authData.risk_level);
  
  return (
    <div className={`bg-white rounded-lg shadow-sm border border-gray-200 p-4 ${colors.bg} ${colors.border}`}>
      <div className="flex items-center justify-between mb-3">
        <h4 className="font-medium text-gray-900">Adaptive Auth</h4>
        {getAccessStatusIcon(authData.access_granted)}
      </div>
      
      <div className="text-center mb-3">
        <div className="text-2xl font-bold text-gray-900 mb-1">
          {authData.risk_score.toFixed(0)}
        </div>
        <div className={`text-sm font-medium ${colors.text}`}>
          {authData.risk_level.toUpperCase()} RISK
        </div>
      </div>
      
      <div className="text-xs text-gray-500 text-center">
        {authData.access_granted ? 'Access Granted' : 'Access Restricted'}
      </div>
      
      {authData.access_restrictions.time_limited && (
        <div className="mt-2 pt-2 border-t border-gray-200">
          <div className="text-xs text-gray-600 text-center">
            Session: {formatTimeRemaining(authData.access_restrictions.session_duration_hours)}
          </div>
        </div>
      )}
    </div>
  );
};

export default AdaptiveAuthIndicator;