import React, { useState, useEffect } from 'react';
import { 
  Shield, 
  CheckCircle, 
  AlertTriangle, 
  Clock, 
  Eye,
  Smartphone,
  MapPin,
  Activity,
  RefreshCw,
  XCircle
} from 'lucide-react';
import { enhancedAuthService, ZeroTrustRequest, ZeroTrustResponse } from '../../services/realAuthService';

interface ZeroTrustIndicatorProps {
  userId?: string;
  deviceId?: string;
  onVerificationComplete?: (result: ZeroTrustResponse) => void;
  className?: string;
}

interface TrustScoreGaugeProps {
  score: number;
  status: string;
}

const TrustScoreGauge: React.FC<TrustScoreGaugeProps> = ({ score, status }) => {
  const radius = 40;
  const strokeWidth = 6;
  const normalizedRadius = radius - strokeWidth * 2;
  const circumference = normalizedRadius * 2 * Math.PI;
  const strokeDasharray = `${circumference} ${circumference}`;
  const strokeDashoffset = circumference - (score / 100) * circumference;

  const getScoreColor = () => {
    if (score >= 80) return "#10b981"; // green
    if (score >= 60) return "#f59e0b"; // yellow
    if (score >= 40) return "#f97316"; // orange
    return "#ef4444"; // red
  };

  return (
    <div className="relative w-24 h-24">
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
          stroke={getScoreColor()}
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
          <div className="text-lg font-bold text-gray-900">{score}</div>
          <div className="text-xs text-gray-500">Trust</div>
        </div>
      </div>
    </div>
  );
};

const ZeroTrustVerificationIndicator: React.FC<ZeroTrustIndicatorProps> = ({
  userId = 'current_user',
  deviceId,
  onVerificationComplete,
  className = ''
}) => {
  const [verificationData, setVerificationData] = useState<ZeroTrustResponse['data'] | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastVerification, setLastVerification] = useState<Date | null>(null);
  const [sessionExpiry, setSessionExpiry] = useState<Date | null>(null);
  const [autoVerify, setAutoVerify] = useState(true);

  // Generate or get device ID
  const getDeviceId = () => {
    if (deviceId) return deviceId;
    
    let storedDeviceId = localStorage.getItem('zero_trust_device_id');
    if (!storedDeviceId) {
      storedDeviceId = `device_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      localStorage.setItem('zero_trust_device_id', storedDeviceId);
    }
    return storedDeviceId;
  };

  const performVerification = async () => {
    try {
      setLoading(true);
      setError(null);

      // Collect context information
      const request: ZeroTrustRequest = {
        device_id: getDeviceId(),
        location: {
          timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
          new_location: !localStorage.getItem('verified_locations')?.includes(window.location.origin),
          user_agent: navigator.userAgent
        },
        behavior_patterns: {
          normal_hours: new Date().getHours() >= 8 && new Date().getHours() <= 18,
          frequent_location: true,
          typical_browser: !navigator.userAgent.includes('Mobile')
        },
        risk_tolerance: 'medium'
      };

      const result = await enhancedAuthService.performZeroTrustVerification(request);
      
      if (result.success && result.data) {
        setVerificationData(result.data);
        setLastVerification(new Date());
        setSessionExpiry(new Date(result.data.session_expiry));
        
        // Store verified location
        const verifiedLocations = localStorage.getItem('verified_locations') || '';
        if (!verifiedLocations.includes(window.location.origin)) {
          localStorage.setItem('verified_locations', `${verifiedLocations},${window.location.origin}`);
        }
        
        if (onVerificationComplete) {
          onVerificationComplete(result);
        }
        
        console.log('[ZERO TRUST] Verification completed:', result.data);
      } else {
        setError(result.error || 'Verification failed');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown verification error';
      setError(errorMessage);
      console.error('[ZERO TRUST] Verification error:', errorMessage);
    } finally {
      setLoading(false);
    }
  };

  // Perform initial verification
  useEffect(() => {
    performVerification();
  }, []);

  // Auto-verify every 10 minutes
  useEffect(() => {
    if (!autoVerify) return;

    const interval = setInterval(() => {
      performVerification();
    }, 600000); // 10 minutes

    return () => clearInterval(interval);
  }, [autoVerify]);

  // Check session expiry
  useEffect(() => {
    if (!sessionExpiry) return;

    const checkExpiry = () => {
      if (new Date() > sessionExpiry) {
        performVerification();
      }
    };

    const interval = setInterval(checkExpiry, 60000); // Check every minute
    return () => clearInterval(interval);
  }, [sessionExpiry]);

  const getStatusIcon = () => {
    if (loading) return <RefreshCw className="h-5 w-5 animate-spin text-blue-500" />;
    if (error) return <XCircle className="h-5 w-5 text-red-500" />;
    if (!verificationData) return <Eye className="h-5 w-5 text-gray-500" />;
    
    switch (verificationData.verification_status) {
      case 'verified':
        return <CheckCircle className="h-5 w-5 text-green-500" />;
      case 'requires_additional_auth':
        return <AlertTriangle className="h-5 w-5 text-yellow-500" />;
      default:
        return <XCircle className="h-5 w-5 text-red-500" />;
    }
  };

  const getStatusColor = () => {
    if (loading) return 'border-blue-200 bg-blue-50';
    if (error) return 'border-red-200 bg-red-50';
    if (!verificationData) return 'border-gray-200 bg-gray-50';
    
    switch (verificationData.verification_status) {
      case 'verified':
        return 'border-green-200 bg-green-50';
      case 'requires_additional_auth':
        return 'border-yellow-200 bg-yellow-50';
      default:
        return 'border-red-200 bg-red-50';
    }
  };

  const getRiskFactorIcon = (factor: string) => {
    switch (factor) {
      case 'new_device': return <Smartphone className="h-4 w-4" />;
      case 'unusual_location': return <MapPin className="h-4 w-4" />;
      case 'behavior_anomaly': return <Activity className="h-4 w-4" />;
      default: return <AlertTriangle className="h-4 w-4" />;
    }
  };

  const getRiskLevelColor = (level: string) => {
    switch (level.toLowerCase()) {
      case 'low': return 'text-green-600 bg-green-100';
      case 'medium': return 'text-yellow-600 bg-yellow-100';
      case 'high': return 'text-red-600 bg-red-100';
      default: return 'text-gray-600 bg-gray-100';
    }
  };

  return (
    <div className={`bg-white rounded-lg shadow-sm border-2 p-4 ${getStatusColor()} ${className}`}>
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-2">
          {getStatusIcon()}
          <div>
            <h3 className="font-semibold text-gray-900">Zero Trust Security</h3>
            <p className="text-xs text-gray-600">Real-time verification status</p>
          </div>
        </div>
        
        <button
          onClick={performVerification}
          disabled={loading}
          className="flex items-center space-x-1 px-2 py-1 text-xs bg-white border border-gray-300 rounded hover:bg-gray-50 disabled:opacity-50"
        >
          <RefreshCw className={`h-3 w-3 ${loading ? 'animate-spin' : ''}`} />
          <span>Verify</span>
        </button>
      </div>

      {/* Error Display */}
      {error && (
        <div className="mb-4 p-2 bg-red-100 border border-red-300 rounded text-sm text-red-700">
          <strong>Verification Error:</strong> {error}
        </div>
      )}

      {/* Trust Score and Status */}
      {verificationData && (
        <div className="space-y-4">
          <div className="flex items-center space-x-4">
            <TrustScoreGauge 
              score={verificationData.trust_score} 
              status={verificationData.verification_status}
            />
            
            <div className="flex-1">
              <div className="text-sm font-medium text-gray-900 mb-1">
                Verification Status
              </div>
              <div className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                verificationData.verification_status === 'verified' 
                  ? 'bg-green-100 text-green-800'
                  : 'bg-yellow-100 text-yellow-800'
              }`}>
                {verificationData.verification_status === 'verified' ? 'Verified' : 'Additional Auth Required'}
              </div>
              
              {sessionExpiry && (
                <div className="text-xs text-gray-500 mt-2 flex items-center">
                  <Clock className="h-3 w-3 mr-1" />
                  Session expires: {sessionExpiry.toLocaleTimeString()}
                </div>
              )}
            </div>
          </div>

          {/* Risk Factors */}
          {verificationData.risk_factors && verificationData.risk_factors.length > 0 && (
            <div>
              <h4 className="text-sm font-medium text-gray-900 mb-2">Risk Factors</h4>
              <div className="space-y-1">
                {verificationData.risk_factors.map((factor, index) => (
                  <div key={index} className="flex items-center justify-between text-xs">
                    <div className="flex items-center space-x-2">
                      {getRiskFactorIcon(factor.factor)}
                      <span className="text-gray-700">
                        {factor.factor.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                      </span>
                    </div>
                    <div className={`px-2 py-0.5 rounded ${getRiskLevelColor(factor.risk_level)}`}>
                      {factor.detected ? factor.risk_level : 'OK'}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Required Actions */}
          {verificationData.required_actions && verificationData.required_actions.length > 0 && (
            <div>
              <h4 className="text-sm font-medium text-gray-900 mb-2">Required Actions</h4>
              <div className="space-y-1">
                {verificationData.required_actions.map((action, index) => (
                  <div key={index} className="flex items-center space-x-2 text-xs text-orange-700">
                    <AlertTriangle className="h-3 w-3" />
                    <span>{action.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Recommendations */}
          {verificationData.recommendations && verificationData.recommendations.length > 0 && (
            <div>
              <h4 className="text-sm font-medium text-gray-900 mb-2">Recommendations</h4>
              <div className="space-y-1">
                {verificationData.recommendations.map((recommendation, index) => (
                  <div key={index} className="text-xs text-blue-700 flex items-start space-x-1">
                    <span className="text-blue-500 mt-0.5">•</span>
                    <span>{recommendation}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Continuous Monitoring */}
          {verificationData.continuous_monitoring && (
            <div className="flex items-center space-x-2 text-xs text-gray-600 pt-2 border-t border-gray-200">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span>Continuous monitoring active</span>
            </div>
          )}
        </div>
      )}

      {/* Last Verification Time */}
      {lastVerification && (
        <div className="mt-4 pt-2 border-t border-gray-200 text-xs text-gray-500">
          Last verified: {lastVerification.toLocaleTimeString()}
        </div>
      )}
    </div>
  );
};

export default ZeroTrustVerificationIndicator;