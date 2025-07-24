import React, { useState, useEffect } from 'react';
import { 
  Shield, 
  AlertTriangle, 
  CheckCircle, 
  Clock, 
  RefreshCw,
  User,
  Globe,
  Smartphone,
  Eye,
  XCircle
} from 'lucide-react';
import { enhancedAuthService, ZeroTrustResponse } from '../../services/realAuthService';

interface ZeroTrustVerificationProps {
  /**
   * Inline mode for embedding in headers/sidebars
   * Compact mode for minimal space usage
   */
  mode?: 'inline' | 'compact' | 'full';
  
  /**
   * Auto-refresh interval in seconds (default: 300 = 5 minutes)
   */
  refreshInterval?: number;
  
  /**
   * Callback when trust score changes significantly
   */
  onTrustScoreChange?: (score: number, status: string) => void;
  
  /**
   * Callback when required actions are detected
   */
  onRequiredActions?: (actions: string[]) => void;
}

const ZeroTrustVerification: React.FC<ZeroTrustVerificationProps> = ({
  mode = 'full',
  refreshInterval = 300,
  onTrustScoreChange,
  onRequiredActions
}) => {
  const [trustData, setTrustData] = useState<ZeroTrustResponse['data'] | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [timeUntilExpiry, setTimeUntilExpiry] = useState<number>(0);

  // Auto-refresh zero trust verification
  useEffect(() => {
    loadZeroTrustStatus();
    
    const interval = setInterval(() => {
      loadZeroTrustStatus();
    }, refreshInterval * 1000);

    return () => clearInterval(interval);
  }, [refreshInterval]);

  // Session expiry countdown
  useEffect(() => {
    if (!trustData?.session_expiry) return;

    const interval = setInterval(() => {
      const expiry = new Date(trustData.session_expiry);
      const now = new Date();
      const remaining = Math.max(0, expiry.getTime() - now.getTime());
      setTimeUntilExpiry(remaining);
    }, 1000);

    return () => clearInterval(interval);
  }, [trustData?.session_expiry]);

  // Notify parent components of changes
  useEffect(() => {
    if (trustData) {
      onTrustScoreChange?.(trustData.trust_score, trustData.verification_status);
      
      if (trustData.required_actions.length > 0) {
        onRequiredActions?.(trustData.required_actions);
      }
    }
  }, [trustData, onTrustScoreChange, onRequiredActions]);

  const loadZeroTrustStatus = async () => {
    try {
      setError(null);
      
      // Create verification request with device/location context
      const verificationRequest = {
        device_id: getDeviceId(),
        location: {
          new_location: false, // Could be enhanced with geolocation
          ip_address: 'auto-detect'
        },
        behavior_patterns: {
          login_time: new Date().getHours(),
          usual_activity: true
        },
        risk_tolerance: 'standard'
      };

      const result = await enhancedAuthService.performZeroTrustVerification(verificationRequest);
      
      if (result.success && result.data) {
        setTrustData(result.data);
        setLastUpdate(new Date());
        console.log('[ZERO TRUST] Verification data loaded:', result.data);
      } else {
        setError(result.error || 'Failed to load zero trust status');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Zero trust verification failed';
      setError(errorMessage);
      console.error('[ZERO TRUST] Verification error:', errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const getDeviceId = (): string => {
    // Generate or retrieve device fingerprint
    let deviceId = localStorage.getItem('wfm_device_id');
    if (!deviceId) {
      deviceId = 'device_' + Math.random().toString(36).substr(2, 9);
      localStorage.setItem('wfm_device_id', deviceId);
    }
    return deviceId;
  };

  const getTrustScoreColor = (score: number) => {
    if (score >= 70) return { bg: 'bg-green-50', border: 'border-green-200', text: 'text-green-600', ring: 'stroke-green-500' };
    if (score >= 40) return { bg: 'bg-yellow-50', border: 'border-yellow-200', text: 'text-yellow-600', ring: 'stroke-yellow-500' };
    return { bg: 'bg-red-50', border: 'border-red-200', text: 'text-red-600', ring: 'stroke-red-500' };
  };

  const getVerificationStatusIcon = (status: string) => {
    switch (status.toLowerCase()) {
      case 'verified': return <CheckCircle className="h-5 w-5 text-green-500" />;
      case 'pending': return <Clock className="h-5 w-5 text-yellow-500" />;
      case 'denied': return <XCircle className="h-5 w-5 text-red-500" />;
      default: return <AlertTriangle className="h-5 w-5 text-gray-500" />;
    }
  };

  const getRiskFactorIcon = (factor: string) => {
    switch (factor.toLowerCase()) {
      case 'new_device': return <Smartphone className="h-4 w-4" />;
      case 'unusual_location': return <Globe className="h-4 w-4" />;
      case 'behavior_anomaly': return <User className="h-4 w-4" />;
      case 'time_based_risk': return <Clock className="h-4 w-4" />;
      default: return <Eye className="h-4 w-4" />;
    }
  };

  const formatTimeRemaining = (milliseconds: number): string => {
    const hours = Math.floor(milliseconds / (1000 * 60 * 60));
    const minutes = Math.floor((milliseconds % (1000 * 60 * 60)) / (1000 * 60));
    return `${hours}h ${minutes}m`;
  };

  const renderTrustScoreGauge = (score: number, size: 'small' | 'medium' | 'large' = 'medium') => {
    const dimensions = {
      small: { radius: 30, strokeWidth: 4 },
      medium: { radius: 40, strokeWidth: 6 },
      large: { radius: 50, strokeWidth: 8 }
    };
    
    const { radius, strokeWidth } = dimensions[size];
    const normalizedRadius = radius - strokeWidth * 2;
    const circumference = normalizedRadius * 2 * Math.PI;
    const strokeDasharray = `${circumference} ${circumference}`;
    const strokeDashoffset = circumference - (score / 100) * circumference;
    const colors = getTrustScoreColor(score);

    return (
      <div className={`relative w-${radius * 2} h-${radius * 2}`}>
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
            stroke={colors.ring.replace('stroke-', '#')}
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
            <div className={`${size === 'small' ? 'text-lg' : size === 'medium' ? 'text-xl' : 'text-2xl'} font-bold ${colors.text}`}>
              {score}
            </div>
            {size !== 'small' && (
              <div className="text-xs text-gray-500">Trust</div>
            )}
          </div>
        </div>
      </div>
    );
  };

  // Compact mode for headers/sidebars
  if (mode === 'compact') {
    if (loading) {
      return (
        <div className="flex items-center space-x-2 px-3 py-1 bg-gray-50 rounded-lg">
          <RefreshCw className="h-4 w-4 animate-spin text-gray-400" />
          <span className="text-sm text-gray-500">Loading...</span>
        </div>
      );
    }

    if (error) {
      return (
        <div className="flex items-center space-x-2 px-3 py-1 bg-red-50 border border-red-200 rounded-lg">
          <AlertTriangle className="h-4 w-4 text-red-500" />
          <span className="text-sm text-red-600">Trust Error</span>
        </div>
      );
    }

    if (!trustData) return null;

    const colors = getTrustScoreColor(trustData.trust_score);
    
    return (
      <div className={`flex items-center space-x-2 px-3 py-1 ${colors.bg} ${colors.border} border rounded-lg`}>
        {renderTrustScoreGauge(trustData.trust_score, 'small')}
        <div className="flex flex-col">
          <div className="flex items-center space-x-1">
            {getVerificationStatusIcon(trustData.verification_status)}
            <span className={`text-sm font-medium ${colors.text}`}>
              {trustData.verification_status}
            </span>
          </div>
          {trustData.required_actions.length > 0 && (
            <span className="text-xs text-orange-600">
              {trustData.required_actions.length} action(s) required
            </span>
          )}
        </div>
      </div>
    );
  }

  // Inline mode for dashboard widgets
  if (mode === 'inline') {
    if (loading) {
      return (
        <div className="flex items-center justify-center p-4">
          <RefreshCw className="h-6 w-6 animate-spin text-gray-400" />
        </div>
      );
    }

    if (error || !trustData) {
      return (
        <div className="flex items-center justify-center p-4">
          <div className="text-center">
            <AlertTriangle className="h-8 w-8 text-red-500 mx-auto mb-2" />
            <p className="text-sm text-red-600">Trust verification unavailable</p>
          </div>
        </div>
      );
    }

    const colors = getTrustScoreColor(trustData.trust_score);
    
    return (
      <div className={`p-4 ${colors.bg} ${colors.border} border rounded-lg`}>
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-medium text-gray-900">Zero Trust Status</h3>
          {getVerificationStatusIcon(trustData.verification_status)}
        </div>
        
        <div className="flex items-center justify-center mb-3">
          {renderTrustScoreGauge(trustData.trust_score, 'medium')}
        </div>
        
        {trustData.required_actions.length > 0 && (
          <div className="space-y-2">
            <p className="text-xs font-medium text-gray-700">Required Actions:</p>
            {trustData.required_actions.map((action, index) => (
              <div key={index} className="flex items-center space-x-2">
                <AlertTriangle className="h-3 w-3 text-orange-500" />
                <span className="text-xs text-gray-600">{action}</span>
              </div>
            ))}
          </div>
        )}
        
        {timeUntilExpiry > 0 && (
          <div className="mt-3 pt-3 border-t border-gray-200">
            <div className="flex items-center justify-between">
              <span className="text-xs text-gray-500">Session expires:</span>
              <span className="text-xs font-medium text-gray-700">
                {formatTimeRemaining(timeUntilExpiry)}
              </span>
            </div>
          </div>
        )}
      </div>
    );
  }

  // Full mode for dedicated zero trust dashboard
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
          <h2 className="text-xl font-bold text-gray-900 flex items-center">
            <Shield className="h-6 w-6 mr-2 text-blue-600" />
            Zero Trust Verification
          </h2>
          <p className="text-gray-500 text-sm mt-1">
            Continuous security verification and trust scoring
          </p>
        </div>
        
        <button
          onClick={loadZeroTrustStatus}
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
              <div className="font-medium">Verification Failed</div>
              <div className="text-sm">{error}</div>
            </div>
            <button
              onClick={loadZeroTrustStatus}
              className="ml-auto px-3 py-1 bg-red-100 text-red-700 rounded text-sm hover:bg-red-200"
            >
              Retry
            </button>
          </div>
        </div>
      )}

      {/* Trust Status Display */}
      {trustData && (
        <div className="space-y-6">
          {/* Trust Score and Status */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Trust Score Gauge */}
            <div className={`p-6 ${getTrustScoreColor(trustData.trust_score).bg} ${getTrustScoreColor(trustData.trust_score).border} border rounded-lg`}>
              <div className="text-center">
                <h3 className="font-semibold text-gray-900 mb-4">Trust Score</h3>
                <div className="flex justify-center mb-4">
                  {renderTrustScoreGauge(trustData.trust_score, 'large')}
                </div>
                <div className="flex items-center justify-center space-x-2">
                  {getVerificationStatusIcon(trustData.verification_status)}
                  <span className="font-medium text-gray-900 capitalize">
                    {trustData.verification_status}
                  </span>
                </div>
              </div>
            </div>

            {/* Session Information */}
            <div className="p-6 bg-gray-50 border border-gray-200 rounded-lg">
              <h3 className="font-semibold text-gray-900 mb-4">Session Details</h3>
              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Verification ID</span>
                  <span className="text-sm font-mono text-gray-900">
                    {trustData.verification_id}
                  </span>
                </div>
                
                {timeUntilExpiry > 0 && (
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-600">Session Expires</span>
                    <span className="text-sm font-medium text-gray-900">
                      {formatTimeRemaining(timeUntilExpiry)}
                    </span>
                  </div>
                )}
                
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Continuous Monitoring</span>
                  <span className={`text-sm font-medium ${trustData.continuous_monitoring ? 'text-green-600' : 'text-gray-600'}`}>
                    {trustData.continuous_monitoring ? 'Active' : 'Inactive'}
                  </span>
                </div>
                
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Last Update</span>
                  <span className="text-sm text-gray-900">
                    {lastUpdate.toLocaleTimeString()}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Risk Factors */}
          {trustData.risk_factors.length > 0 && (
            <div className="bg-white border border-gray-200 rounded-lg p-6">
              <h3 className="font-semibold text-gray-900 mb-4">Risk Factors Analysis</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {trustData.risk_factors.map((factor, index) => (
                  <div 
                    key={index} 
                    className={`p-4 rounded-lg border ${
                      factor.detected 
                        ? factor.risk_level === 'high' 
                          ? 'bg-red-50 border-red-200' 
                          : factor.risk_level === 'medium'
                          ? 'bg-yellow-50 border-yellow-200'
                          : 'bg-blue-50 border-blue-200'
                        : 'bg-green-50 border-green-200'
                    }`}
                  >
                    <div className="flex items-center space-x-3 mb-2">
                      {getRiskFactorIcon(factor.factor)}
                      <span className="font-medium text-gray-900 capitalize">
                        {factor.factor.replace('_', ' ')}
                      </span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className={`text-xs px-2 py-1 rounded-full ${
                        factor.risk_level === 'high' 
                          ? 'bg-red-100 text-red-700'
                          : factor.risk_level === 'medium'
                          ? 'bg-yellow-100 text-yellow-700'
                          : 'bg-blue-100 text-blue-700'
                      }`}>
                        {factor.risk_level.toUpperCase()}
                      </span>
                      <span className={`text-xs font-medium ${
                        factor.detected ? 'text-red-600' : 'text-green-600'
                      }`}>
                        {factor.detected ? 'Detected' : 'Clear'}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Required Actions */}
          {trustData.required_actions.length > 0 && (
            <div className="bg-orange-50 border border-orange-200 rounded-lg p-6">
              <h3 className="font-semibold text-orange-900 mb-4 flex items-center">
                <AlertTriangle className="h-5 w-5 mr-2 text-orange-600" />
                Required Actions
              </h3>
              <div className="space-y-3">
                {trustData.required_actions.map((action, index) => (
                  <div key={index} className="flex items-start p-3 bg-white border border-orange-200 rounded-lg">
                    <AlertTriangle className="h-5 w-5 text-orange-600 mr-3 mt-0.5 flex-shrink-0" />
                    <p className="text-sm text-gray-700">{action}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Recommendations */}
          {trustData.recommendations.length > 0 && (
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
              <h3 className="font-semibold text-blue-900 mb-4 flex items-center">
                <CheckCircle className="h-5 w-5 mr-2 text-blue-600" />
                Security Recommendations
              </h3>
              <div className="space-y-2">
                {trustData.recommendations.map((recommendation, index) => (
                  <div key={index} className="flex items-start p-2">
                    <CheckCircle className="h-4 w-4 text-blue-600 mr-2 mt-0.5 flex-shrink-0" />
                    <p className="text-sm text-gray-700">{recommendation}</p>
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
              <span>Zero trust monitoring active</span>
            </div>
            <span>Auto-refresh: {refreshInterval / 60} minutes</span>
          </div>
          <div className="flex items-center space-x-4">
            <span>🛡️ Trust: {trustData?.trust_score || 'N/A'}</span>
            <span>⏰ Updated: {lastUpdate.toLocaleTimeString()}</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ZeroTrustVerification;