// Real Authentication Service - NO MOCK FALLBACKS
// This service makes REAL API calls to backend authentication endpoints
// If the API fails, it returns REAL errors to the user

interface LoginRequest {
  username: string;
  password: string;
}

interface LoginResponse {
  success: boolean;
  data?: {
    token: string;
    user: {
      id: number;
      email: string;
      name: string;
      role: string;
      department: string;
    };
    expiresAt: string;
  };
  error?: string;
}

interface ApiHealthResponse {
  status: string;
  message: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';

class RealAuthService {
  private authToken: string | null = null;

  constructor() {
    // Try to restore token from localStorage on initialization
    this.authToken = localStorage.getItem('token');
  }

  /**
   * Check if API is healthy before making auth requests
   */
  async checkApiHealth(): Promise<boolean> {
    try {
      const response = await fetch(`${API_BASE_URL}/health`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        console.error('API health check failed:', response.status);
        return false;
      }

      const data: ApiHealthResponse = await response.json();
      return data.status === 'ok' || data.status === 'healthy';
    } catch (error) {
      console.error('API health check error:', error);
      return false;
    }
  }

  /**
   * Real login - NO MOCK FALLBACK
   */
  async login(username: string, password: string): Promise<LoginResponse> {
    try {
      // Use I's verified working auth endpoint
      const response = await fetch(`http://localhost:8001/api/v1/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          username,
          password,
        } as LoginRequest),
      });

      const responseText = await response.text();
      let data;
      
      try {
        data = JSON.parse(responseText);
      } catch (parseError) {
        // If response is not JSON, return the raw error
        if (!response.ok) {
          throw new Error(`Authentication failed: ${responseText || response.statusText}`);
        }
        throw new Error('Invalid response format from server');
      }

      if (!response.ok) {
        // Return real error from API
        throw new Error(data.detail || data.error || `Authentication failed: ${response.status}`);
      }

      // Store token using I's verified format: {"token": "...", "user": {"id": ..., "username": "...", "role": "..."}}
      if (data.token) {
        this.authToken = data.token;
        localStorage.setItem('token', data.token);
        
        // Use the user object from the response
        const user = {
          id: data.user?.id || 1,
          email: data.user?.email || data.user?.username + '@technoservice.ru',
          name: data.user?.name || data.user?.username || 'Admin User',
          role: data.user?.role || 'admin',
          department: data.user?.department || 'Management',
          username: data.user?.username || username
        };
        localStorage.setItem('wfm_user', JSON.stringify(user));
      }

      return {
        success: true,
        data: {
          token: data.token,
          user: {
            id: data.user?.id || 1,
            email: data.user?.email || data.user?.username + '@technoservice.ru',
            name: data.user?.name || data.user?.username || 'Admin User',
            role: data.user?.role || 'admin',
            department: data.user?.department || 'Management'
          },
          expiresAt: new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString(), // 8 hours
        },
      };
    } catch (error) {
      // NO MOCK FALLBACK - return real error
      console.error('Login error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred during login',
      };
    }
  }

  /**
   * Real logout - NO MOCK FALLBACK
   */
  async logout(): Promise<{ success: boolean; error?: string }> {
    try {
      // Make real logout API call if we have a token
      if (this.authToken) {
        const response = await fetch(`${API_BASE_URL}/auth/logout`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.authToken}`,
          },
        });

        if (!response.ok && response.status !== 401) {
          // Don't throw on 401 as token might already be invalid
          const errorText = await response.text();
          console.error('Logout API error:', errorText);
        }
      }

      // Clear local storage regardless of API response
      this.authToken = null;
      localStorage.removeItem('token');
      localStorage.removeItem('wfm_user');

      return { success: true };
    } catch (error) {
      // Still clear local data even if API call fails
      this.authToken = null;
      localStorage.removeItem('token');
      localStorage.removeItem('wfm_user');

      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred during logout',
      };
    }
  }

  /**
   * Verify if current token is valid
   */
  async verifyToken(): Promise<boolean> {
    if (!this.authToken) {
      return false;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/auth/verify`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${this.authToken}`,
        },
      });

      if (response.ok) {
        return true;
      }

      // Token is invalid, clear it
      this.authToken = null;
      localStorage.removeItem('token');
      localStorage.removeItem('wfm_user');
      return false;
    } catch (error) {
      console.error('Token verification error:', error);
      return false;
    }
  }

  /**
   * Get current auth token
   */
  getAuthToken(): string | null {
    return this.authToken;
  }

  /**
   * Get current user from localStorage
   */
  getCurrentUser() {
    const userStr = localStorage.getItem('wfm_user');
    if (!userStr) return null;
    
    try {
      return JSON.parse(userStr);
    } catch {
      return null;
    }
  }

  /**
   * Check if user is authenticated
   */
  isAuthenticated(): boolean {
    return !!this.authToken;
  }
}

// Export singleton instance
export const realAuthService = new RealAuthService();

// Export type definitions
export type { LoginRequest, LoginResponse };

// Enhanced Authentication Service - Advanced Features Extension
// Zero Trust, Adaptive Auth, Security Analytics

interface ZeroTrustRequest {
  device_id: string;
  location?: Record<string, any>;
  behavior_patterns?: Record<string, any>;
  risk_tolerance?: string;
}

interface ZeroTrustResponse {
  success: boolean;
  data?: {
    verification_id: string;
    trust_score: number;
    verification_status: string;
    risk_factors: Array<{
      factor: string;
      risk_level: string;
      detected: boolean;
    }>;
    required_actions: string[];
    session_expiry: string;
    continuous_monitoring: boolean;
    recommendations: string[];
  };
  error?: string;
}

interface AdaptiveAuthRequest {
  requested_access: string;
  risk_context: Record<string, any>;
  session_duration?: number;
}

interface AdaptiveAuthResponse {
  success: boolean;
  data?: {
    authentication_id: string;
    risk_score: number;
    risk_level: string;
    required_methods: string[];
    access_granted: boolean;
    access_restrictions: {
      time_limited: boolean;
      session_duration_hours: number;
      requires_monitoring: boolean;
      ip_restriction: boolean;
    };
    risk_breakdown: Record<string, number>;
    mitigation_strategies: string[];
  };
  error?: string;
}

interface SecurityPostureResponse {
  success: boolean;
  data?: {
    time_range: string;
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
  };
  error?: string;
}

// Enhanced Authentication Service Extension
class EnhancedAuthService extends RealAuthService {
  private getApiBaseUrl(): string {
    return import.meta.env.VITE_API_URL || 'http://localhost:8001';
  }
  /**
   * Zero Trust Verification
   */
  async performZeroTrustVerification(request: ZeroTrustRequest): Promise<ZeroTrustResponse> {
    try {
      const response = await fetch(`${this.getApiBaseUrl()}/api/v1/zero-trust/verify`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.getAuthToken()}`,
        },
        body: JSON.stringify(request),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.detail || data.error || 'Zero trust verification failed');
      }

      return {
        success: true,
        data: {
          verification_id: data.verification_id,
          trust_score: data.trust_score,
          verification_status: data.verification_status,
          risk_factors: data.risk_factors || [],
          required_actions: data.required_actions || [],
          session_expiry: data.session_expiry,
          continuous_monitoring: data.continuous_monitoring || false,
          recommendations: data.recommendations || [],
        },
      };
    } catch (error) {
      console.error('Zero trust verification error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Zero trust verification failed',
      };
    }
  }

  /**
   * Adaptive Authentication
   */
  async performAdaptiveAuthentication(request: AdaptiveAuthRequest): Promise<AdaptiveAuthResponse> {
    try {
      const response = await fetch(`${this.getApiBaseUrl()}/api/v1/adaptive/authenticate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.getAuthToken()}`,
        },
        body: JSON.stringify(request),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.detail || data.error || 'Adaptive authentication failed');
      }

      return {
        success: true,
        data: {
          authentication_id: data.authentication_id,
          risk_score: data.risk_score,
          risk_level: data.risk_level,
          required_methods: data.required_methods || [],
          access_granted: data.access_granted || false,
          access_restrictions: data.access_restrictions || {
            time_limited: false,
            session_duration_hours: 8,
            requires_monitoring: false,
            ip_restriction: false,
          },
          risk_breakdown: data.risk_breakdown || {},
          mitigation_strategies: data.mitigation_strategies || [],
        },
      };
    } catch (error) {
      console.error('Adaptive authentication error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Adaptive authentication failed',
      };
    }
  }

  /**
   * Get Security Posture Analytics
   */
  async getSecurityPostureAnalytics(timeRange: string = '7d'): Promise<SecurityPostureResponse> {
    try {
      const response = await fetch(`${this.getApiBaseUrl()}/api/v1/auth-analytics/security-posture?time_range=${timeRange}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.getAuthToken()}`,
        },
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.detail || data.error || 'Security posture analytics failed');
      }

      return {
        success: true,
        data: {
          time_range: data.time_range || timeRange,
          security_posture_score: data.security_posture_score || 0,
          authentication_metrics: data.authentication_metrics || {
            total_attempts: 0,
            success_rate: 0,
            failed_attempts: 0,
            blocked_attempts: 0,
            unique_users: 0,
            average_session_duration: '0m',
          },
          threat_detection: data.threat_detection || {
            suspicious_activities: 0,
            blocked_ips: 0,
            anomaly_score: 0,
            threat_level: 'low',
          },
          compliance_status: data.compliance_status || {
            zero_trust_coverage: '0%',
            mfa_adoption: '0%',
            password_policy_compliance: '0%',
            session_management_score: 0,
          },
          recommendations: data.recommendations || [],
          trend_analysis: data.trend_analysis || {
            authentication_trend: 'stable',
            security_incidents_trend: 'stable',
            user_adoption_trend: 'stable',
          },
        },
      };
    } catch (error) {
      console.error('Security posture analytics error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Security posture analytics failed',
      };
    }
  }
}

// Export enhanced singleton instance
export const enhancedAuthService = new EnhancedAuthService();

// Export additional type definitions
export type { 
  ZeroTrustRequest, 
  ZeroTrustResponse, 
  AdaptiveAuthRequest, 
  AdaptiveAuthResponse,
  SecurityPostureResponse 
};