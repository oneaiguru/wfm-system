import React, { useState } from 'react';
import { 
  Shield, 
  Activity, 
  BarChart3, 
  Settings, 
  RefreshCw,
  Eye,
  Users,
  Lock
} from 'lucide-react';
import ZeroTrustVerification from './ZeroTrustVerification';
import AdaptiveAuthIndicator from './AdaptiveAuthIndicator';

// Demo Component: Authentication Enhancement Showcase
// Demonstrates all new auth enhancement features in one comprehensive view

interface AuthEnhancementDemoProps {
  /**
   * Demo mode selection
   */
  demoMode?: 'full' | 'executive' | 'technical';
}

const AuthEnhancementDemo: React.FC<AuthEnhancementDemoProps> = ({
  demoMode = 'full'
}) => {
  const [activeTab, setActiveTab] = useState<'overview' | 'zerotrust' | 'adaptive' | 'analytics'>('overview');
  const [trustScore, setTrustScore] = useState<number>(0);
  const [adaptiveRisk, setAdaptiveRisk] = useState<number>(0);

  const handleTrustScoreChange = (score: number, status: string) => {
    setTrustScore(score);
    console.log('[AUTH DEMO] Trust score updated:', { score, status });
  };

  const handleAdaptiveAuthChange = (authData: any) => {
    setAdaptiveRisk(authData.risk_score);
    console.log('[AUTH DEMO] Adaptive auth updated:', authData);
  };

  const renderOverview = () => (
    <div className="space-y-6">
      {/* Executive Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-gradient-to-br from-blue-50 to-blue-100 border border-blue-200 rounded-lg p-6">
          <div className="flex items-center justify-between mb-4">
            <Shield className="h-8 w-8 text-blue-600" />
            <span className="text-xs bg-blue-200 text-blue-800 px-2 py-1 rounded-full font-medium">
              ENHANCED
            </span>
          </div>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Zero Trust Security</h3>
          <p className="text-gray-600 text-sm mb-4">
            Continuous verification with real-time trust scoring and risk assessment
          </p>
          <div className="flex items-center justify-between">
            <span className="text-2xl font-bold text-blue-600">
              {trustScore || 87}%
            </span>
            <span className="text-xs text-gray-500">Trust Score</span>
          </div>
        </div>

        <div className="bg-gradient-to-br from-green-50 to-green-100 border border-green-200 rounded-lg p-6">
          <div className="flex items-center justify-between mb-4">
            <Activity className="h-8 w-8 text-green-600" />
            <span className="text-xs bg-green-200 text-green-800 px-2 py-1 rounded-full font-medium">
              ADAPTIVE
            </span>
          </div>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Adaptive Authentication</h3>
          <p className="text-gray-600 text-sm mb-4">
            Risk-based access control with contextual authentication decisions
          </p>
          <div className="flex items-center justify-between">
            <span className="text-2xl font-bold text-green-600">
              {adaptiveRisk || 23}
            </span>
            <span className="text-xs text-gray-500">Risk Score</span>
          </div>
        </div>

        <div className="bg-gradient-to-br from-purple-50 to-purple-100 border border-purple-200 rounded-lg p-6">
          <div className="flex items-center justify-between mb-4">
            <BarChart3 className="h-8 w-8 text-purple-600" />
            <span className="text-xs bg-purple-200 text-purple-800 px-2 py-1 rounded-full font-medium">
              ANALYTICS
            </span>
          </div>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Security Analytics</h3>
          <p className="text-gray-600 text-sm mb-4">
            Advanced business intelligence with predictive security insights
          </p>
          <div className="flex items-center justify-between">
            <span className="text-2xl font-bold text-purple-600">94.2</span>
            <span className="text-xs text-gray-500">Security Posture</span>
          </div>
        </div>
      </div>

      {/* Key Features Overview */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Authentication Enhancement Features</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h4 className="font-medium text-gray-900 mb-3 flex items-center">
              <Shield className="h-5 w-5 mr-2 text-blue-600" />
              Zero Trust Implementation
            </h4>
            <ul className="space-y-2 text-sm text-gray-600">
              <li className="flex items-center">
                <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                Continuous device and user verification
              </li>
              <li className="flex items-center">
                <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                Real-time trust score calculation
              </li>
              <li className="flex items-center">
                <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                Risk factor analysis and monitoring
              </li>
              <li className="flex items-center">
                <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                Session expiry management
              </li>
            </ul>
          </div>

          <div>
            <h4 className="font-medium text-gray-900 mb-3 flex items-center">
              <Activity className="h-5 w-5 mr-2 text-green-600" />
              Adaptive Authentication
            </h4>
            <ul className="space-y-2 text-sm text-gray-600">
              <li className="flex items-center">
                <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                Context-aware access decisions
              </li>
              <li className="flex items-center">
                <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                Dynamic risk assessment
              </li>
              <li className="flex items-center">
                <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                Behavioral analysis integration
              </li>
              <li className="flex items-center">
                <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                Mitigation strategy recommendations
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-6 pt-6 border-t border-gray-200">
          <h4 className="font-medium text-gray-900 mb-3 flex items-center">
            <BarChart3 className="h-5 w-5 mr-2 text-purple-600" />
            Business Intelligence & Analytics
          </h4>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-gray-50 rounded-lg p-4">
              <div className="font-medium text-gray-900 mb-2">Security Posture</div>
              <div className="text-sm text-gray-600">
                Real-time security health monitoring with comprehensive threat detection
              </div>
            </div>
            <div className="bg-gray-50 rounded-lg p-4">
              <div className="font-medium text-gray-900 mb-2">Predictive Insights</div>
              <div className="text-sm text-gray-600">
                AI-powered predictions for capacity planning and risk mitigation
              </div>
            </div>
            <div className="bg-gray-50 rounded-lg p-4">
              <div className="font-medium text-gray-900 mb-2">Executive Reporting</div>
              <div className="text-sm text-gray-600">
                Strategic dashboards with actionable business intelligence
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Integration Status */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Integration Status</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h4 className="font-medium text-gray-900 mb-3">API Endpoints</h4>
            <div className="space-y-2">
              <div className="flex items-center justify-between p-2 bg-green-50 rounded">
                <span className="text-sm font-medium text-gray-700">Zero Trust Verification</span>
                <span className="text-xs bg-green-200 text-green-800 px-2 py-1 rounded font-medium">READY</span>
              </div>
              <div className="flex items-center justify-between p-2 bg-green-50 rounded">
                <span className="text-sm font-medium text-gray-700">Adaptive Authentication</span>
                <span className="text-xs bg-green-200 text-green-800 px-2 py-1 rounded font-medium">READY</span>
              </div>
              <div className="flex items-center justify-between p-2 bg-green-50 rounded">
                <span className="text-sm font-medium text-gray-700">Security Analytics</span>
                <span className="text-xs bg-green-200 text-green-800 px-2 py-1 rounded font-medium">READY</span>
              </div>
            </div>
          </div>

          <div>
            <h4 className="font-medium text-gray-900 mb-3">UI Components</h4>
            <div className="space-y-2">
              <div className="flex items-center justify-between p-2 bg-blue-50 rounded">
                <span className="text-sm font-medium text-gray-700">ZeroTrustVerification</span>
                <span className="text-xs bg-blue-200 text-blue-800 px-2 py-1 rounded font-medium">ACTIVE</span>
              </div>
              <div className="flex items-center justify-between p-2 bg-blue-50 rounded">
                <span className="text-sm font-medium text-gray-700">AdaptiveAuthIndicator</span>
                <span className="text-xs bg-blue-200 text-blue-800 px-2 py-1 rounded font-medium">ACTIVE</span>
              </div>
              <div className="flex items-center justify-between p-2 bg-blue-50 rounded">
                <span className="text-sm font-medium text-gray-700">Enhanced ExecutiveDashboard</span>
                <span className="text-xs bg-blue-200 text-blue-800 px-2 py-1 rounded font-medium">ACTIVE</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  const renderTabContent = () => {
    switch (activeTab) {
      case 'overview':
        return renderOverview();
      case 'zerotrust':
        return (
          <ZeroTrustVerification 
            mode="full" 
            refreshInterval={300}
            onTrustScoreChange={handleTrustScoreChange}
          />
        );
      case 'adaptive':
        return (
          <AdaptiveAuthIndicator 
            mode="detailed" 
            refreshInterval={180}
            showRiskBreakdown={true}
            onAuthStatusChange={handleAdaptiveAuthChange}
          />
        );
      case 'analytics':
        return (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Security Analytics Dashboard</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 text-center">
                <div className="text-2xl font-bold text-blue-600 mb-1">96.8%</div>
                <div className="text-sm text-gray-600">Auth Success Rate</div>
              </div>
              <div className="bg-green-50 border border-green-200 rounded-lg p-4 text-center">
                <div className="text-2xl font-bold text-green-600 mb-1">1,247</div>
                <div className="text-sm text-gray-600">Active Users</div>
              </div>
              <div className="bg-purple-50 border border-purple-200 rounded-lg p-4 text-center">
                <div className="text-2xl font-bold text-purple-600 mb-1">0</div>
                <div className="text-sm text-gray-600">Security Incidents</div>
              </div>
              <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 text-center">
                <div className="text-2xl font-bold text-yellow-600 mb-1">4.2h</div>
                <div className="text-sm text-gray-600">Avg Session</div>
              </div>
            </div>
            
            <div className="bg-gray-50 rounded-lg p-6">
              <h4 className="font-medium text-gray-900 mb-4">Key Insights</h4>
              <div className="space-y-3">
                <div className="flex items-start space-x-3">
                  <div className="w-2 h-2 bg-green-500 rounded-full mt-2"></div>
                  <div>
                    <div className="font-medium text-gray-900">Zero security incidents in the last 30 days</div>
                    <div className="text-sm text-gray-600">Enhanced threat detection preventing all potential breaches</div>
                  </div>
                </div>
                <div className="flex items-start space-x-3">
                  <div className="w-2 h-2 bg-blue-500 rounded-full mt-2"></div>
                  <div>
                    <div className="font-medium text-gray-900">Authentication success rate improved by 3.2%</div>
                    <div className="text-sm text-gray-600">Adaptive authentication reducing false positives</div>
                  </div>
                </div>
                <div className="flex items-start space-x-3">
                  <div className="w-2 h-2 bg-purple-500 rounded-full mt-2"></div>
                  <div>
                    <div className="font-medium text-gray-900">User satisfaction increased to 88.9%</div>
                    <div className="text-sm text-gray-600">Seamless security experience with minimal friction</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        );
      default:
        return renderOverview();
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b border-gray-200">
        <div className="px-6 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 flex items-center">
                <Lock className="h-6 w-6 mr-3 text-blue-600" />
                Authentication Enhancement Demo
              </h1>
              <p className="text-gray-500 mt-1">
                Comprehensive showcase of Zero Trust, Adaptive Auth, and Advanced Analytics
              </p>
            </div>
            <div className="flex items-center space-x-3">
              <span className="text-sm text-gray-600">
                Demo Mode: <span className="font-medium capitalize">{demoMode}</span>
              </span>
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span className="text-sm text-green-600 font-medium">Live</span>
            </div>
          </div>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="bg-white border-b border-gray-200">
        <div className="px-6">
          <nav className="flex space-x-6">
            {[
              { id: 'overview', label: 'Overview', icon: Eye },
              { id: 'zerotrust', label: 'Zero Trust', icon: Shield },
              { id: 'adaptive', label: 'Adaptive Auth', icon: Activity },
              { id: 'analytics', label: 'Analytics', icon: BarChart3 }
            ].map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id as any)}
                  className={`flex items-center space-x-2 py-4 border-b-2 font-medium text-sm transition-colors ${
                    activeTab === tab.id
                      ? 'border-blue-600 text-blue-600'
                      : 'border-transparent text-gray-600 hover:text-gray-900'
                  }`}
                >
                  <Icon className="h-4 w-4" />
                  <span>{tab.label}</span>
                </button>
              );
            })}
          </nav>
        </div>
      </div>

      {/* Compact Status Bar */}
      <div className="bg-blue-50 border-b border-blue-200 px-6 py-2">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-6">
            <ZeroTrustVerification 
              mode="compact" 
              onTrustScoreChange={handleTrustScoreChange}
            />
            <AdaptiveAuthIndicator 
              mode="compact" 
              onAuthStatusChange={handleAdaptiveAuthChange}
            />
          </div>
          <div className="flex items-center space-x-4 text-sm text-gray-600">
            <div className="flex items-center space-x-2">
              <Users className="h-4 w-4" />
              <span>1,247 Active Users</span>
            </div>
            <div className="flex items-center space-x-2">
              <Shield className="h-4 w-4" />
              <span>Security: Excellent</span>
            </div>
            <div className="flex items-center space-x-2">
              <RefreshCw className="h-4 w-4" />
              <span>Updated: {new Date().toLocaleTimeString()}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-6 py-6">
        {renderTabContent()}
      </div>

      {/* Footer */}
      <div className="bg-white border-t border-gray-200 px-6 py-4">
        <div className="flex items-center justify-between text-sm text-gray-500">
          <div className="flex items-center space-x-4">
            <span>🔐 Authentication Enhancement Suite v2.0</span>
            <span>•</span>
            <span>🛡️ Zero Trust Architecture</span>
            <span>•</span>
            <span>🤖 AI-Powered Risk Assessment</span>
          </div>
          <div className="flex items-center space-x-4">
            <span>Status: Operational</span>
            <span>•</span>
            <span>Security Level: Maximum</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AuthEnhancementDemo;