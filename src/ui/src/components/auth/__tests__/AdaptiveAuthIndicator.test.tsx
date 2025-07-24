import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import { AdaptiveAuthIndicator } from '../AdaptiveAuthIndicator';
import { enhancedAuthService } from '../../../services/realAuthService';

// Mock the auth service
jest.mock('../../../services/realAuthService', () => ({
  enhancedAuthService: {
    performAdaptiveAuthentication: jest.fn(),
  },
}));

describe('AdaptiveAuthIndicator Component', () => {
  const mockAdaptiveResponse = {
    success: true,
    data: {
      authentication_id: 'adapt_test123',
      authentication_status: 'approved',
      required_methods: ['password'],
      access_level: 'full',
      session_duration: 480,
      risk_score: 15,
      access_restrictions: {},
      monitoring_level: 'standard',
      next_verification: '2025-07-24T16:00:00Z',
    },
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Compact Mode', () => {
    it('renders risk indicator in compact mode', async () => {
      (enhancedAuthService.performAdaptiveAuthentication as jest.Mock).mockResolvedValue(
        mockAdaptiveResponse
      );

      render(<AdaptiveAuthIndicator mode="compact" />);

      await waitFor(() => {
        expect(screen.getByText('Low Risk')).toBeInTheDocument();
        const indicator = screen.getByTestId('risk-indicator');
        expect(indicator).toHaveClass('bg-green-100');
      });
    });

    it('shows high risk warning in compact mode', async () => {
      const highRiskResponse = {
        ...mockAdaptiveResponse,
        data: {
          ...mockAdaptiveResponse.data,
          risk_score: 85,
          authentication_status: 'restricted',
        },
      };

      (enhancedAuthService.performAdaptiveAuthentication as jest.Mock).mockResolvedValue(
        highRiskResponse
      );

      render(<AdaptiveAuthIndicator mode="compact" />);

      await waitFor(() => {
        expect(screen.getByText('High Risk')).toBeInTheDocument();
        const indicator = screen.getByTestId('risk-indicator');
        expect(indicator).toHaveClass('bg-red-100');
      });
    });
  });

  describe('Detailed Mode', () => {
    it('renders complete authentication details', async () => {
      (enhancedAuthService.performAdaptiveAuthentication as jest.Mock).mockResolvedValue(
        mockAdaptiveResponse
      );

      render(<AdaptiveAuthIndicator mode="detailed" />);

      await waitFor(() => {
        expect(screen.getByText('Adaptive Authentication')).toBeInTheDocument();
        expect(screen.getByText('Risk Score: 15')).toBeInTheDocument();
        expect(screen.getByText('Access Level: Full')).toBeInTheDocument();
        expect(screen.getByText('Session Duration: 8 hours')).toBeInTheDocument();
        expect(screen.getByText('Required Methods:')).toBeInTheDocument();
        expect(screen.getByText('Password')).toBeInTheDocument();
      });
    });

    it('displays access restrictions when present', async () => {
      const restrictedResponse = {
        ...mockAdaptiveResponse,
        data: {
          ...mockAdaptiveResponse.data,
          access_restrictions: {
            'sensitive_data': 'denied',
            'export_functions': 'requires_approval',
            'system_settings': 'read_only',
          },
        },
      };

      (enhancedAuthService.performAdaptiveAuthentication as jest.Mock).mockResolvedValue(
        restrictedResponse
      );

      render(<AdaptiveAuthIndicator mode="detailed" />);

      await waitFor(() => {
        expect(screen.getByText('Access Restrictions:')).toBeInTheDocument();
        expect(screen.getByText('Sensitive Data: Denied')).toBeInTheDocument();
        expect(screen.getByText('Export Functions: Requires Approval')).toBeInTheDocument();
        expect(screen.getByText('System Settings: Read Only')).toBeInTheDocument();
      });
    });
  });

  describe('Widget Mode', () => {
    it('renders dashboard widget view', async () => {
      (enhancedAuthService.performAdaptiveAuthentication as jest.Mock).mockResolvedValue(
        mockAdaptiveResponse
      );

      render(<AdaptiveAuthIndicator mode="widget" />);

      await waitFor(() => {
        expect(screen.getByText('Security Status')).toBeInTheDocument();
        expect(screen.getByText('15')).toBeInTheDocument(); // Risk score
        expect(screen.getByText('Low Risk')).toBeInTheDocument();
        expect(screen.getByText('Full Access')).toBeInTheDocument();
      });
    });

    it('shows risk mitigation actions in widget', async () => {
      const responseWithMitigation = {
        ...mockAdaptiveResponse,
        data: {
          ...mockAdaptiveResponse.data,
          risk_score: 65,
          mitigation_strategies: ['Enable MFA', 'Verify location', 'Review recent activity'],
        },
      };

      (enhancedAuthService.performAdaptiveAuthentication as jest.Mock).mockResolvedValue(
        responseWithMitigation
      );

      render(<AdaptiveAuthIndicator mode="widget" />);

      await waitFor(() => {
        expect(screen.getByText('Recommended Actions:')).toBeInTheDocument();
        expect(screen.getByText('Enable MFA')).toBeInTheDocument();
        expect(screen.getByText('Verify location')).toBeInTheDocument();
      });
    });
  });

  describe('Real-time Updates', () => {
    it('updates authentication status in real-time', async () => {
      const initialResponse = mockAdaptiveResponse;
      const updatedResponse = {
        ...mockAdaptiveResponse,
        data: {
          ...mockAdaptiveResponse.data,
          risk_score: 75,
          authentication_status: 'restricted',
        },
      };

      (enhancedAuthService.performAdaptiveAuthentication as jest.Mock)
        .mockResolvedValueOnce(initialResponse)
        .mockResolvedValueOnce(updatedResponse);

      const { rerender } = render(<AdaptiveAuthIndicator mode="detailed" refreshInterval={1} />);

      await waitFor(() => {
        expect(screen.getByText('Risk Score: 15')).toBeInTheDocument();
      });

      jest.useFakeTimers();
      jest.advanceTimersByTime(60000);

      await waitFor(() => {
        expect(screen.getByText('Risk Score: 75')).toBeInTheDocument();
      });

      jest.useRealTimers();
    });
  });

  describe('Error Handling', () => {
    it('displays error message when authentication fails', async () => {
      (enhancedAuthService.performAdaptiveAuthentication as jest.Mock).mockResolvedValue({
        success: false,
        error: 'Authentication service unavailable',
      });

      render(<AdaptiveAuthIndicator mode="detailed" />);

      await waitFor(() => {
        expect(screen.getByText('Authentication service unavailable')).toBeInTheDocument();
      });
    });

    it('shows retry button on error', async () => {
      (enhancedAuthService.performAdaptiveAuthentication as jest.Mock)
        .mockResolvedValueOnce({
          success: false,
          error: 'Network error',
        })
        .mockResolvedValueOnce(mockAdaptiveResponse);

      render(<AdaptiveAuthIndicator mode="detailed" />);

      await waitFor(() => {
        expect(screen.getByText('Network error')).toBeInTheDocument();
      });

      const retryButton = screen.getByText('Retry');
      fireEvent.click(retryButton);

      await waitFor(() => {
        expect(screen.getByText('Risk Score: 15')).toBeInTheDocument();
      });
    });
  });

  describe('Callbacks', () => {
    it('calls onAuthStatusChange when status changes', async () => {
      const onAuthStatusChange = jest.fn();

      (enhancedAuthService.performAdaptiveAuthentication as jest.Mock).mockResolvedValue(
        mockAdaptiveResponse
      );

      render(
        <AdaptiveAuthIndicator 
          mode="detailed" 
          onAuthStatusChange={onAuthStatusChange} 
        />
      );

      await waitFor(() => {
        expect(onAuthStatusChange).toHaveBeenCalledWith({
          status: 'approved',
          riskScore: 15,
          accessLevel: 'full',
        });
      });
    });

    it('calls onRiskLevelChange when risk changes', async () => {
      const onRiskLevelChange = jest.fn();

      (enhancedAuthService.performAdaptiveAuthentication as jest.Mock).mockResolvedValue(
        mockAdaptiveResponse
      );

      render(
        <AdaptiveAuthIndicator 
          mode="detailed" 
          onRiskLevelChange={onRiskLevelChange} 
        />
      );

      await waitFor(() => {
        expect(onRiskLevelChange).toHaveBeenCalledWith('low');
      });
    });
  });

  describe('Multiple Authentication Methods', () => {
    it('displays all required authentication methods', async () => {
      const multiMethodResponse = {
        ...mockAdaptiveResponse,
        data: {
          ...mockAdaptiveResponse.data,
          required_methods: ['password', 'sms', 'biometric'],
        },
      };

      (enhancedAuthService.performAdaptiveAuthentication as jest.Mock).mockResolvedValue(
        multiMethodResponse
      );

      render(<AdaptiveAuthIndicator mode="detailed" />);

      await waitFor(() => {
        expect(screen.getByText('Password')).toBeInTheDocument();
        expect(screen.getByText('SMS')).toBeInTheDocument();
        expect(screen.getByText('Biometric')).toBeInTheDocument();
      });
    });
  });

  describe('Session Management', () => {
    it('displays next verification time', async () => {
      (enhancedAuthService.performAdaptiveAuthentication as jest.Mock).mockResolvedValue(
        mockAdaptiveResponse
      );

      render(<AdaptiveAuthIndicator mode="detailed" />);

      await waitFor(() => {
        expect(screen.getByText(/Next verification:/)).toBeInTheDocument();
      });
    });

    it('shows monitoring level indicator', async () => {
      const enhancedMonitoringResponse = {
        ...mockAdaptiveResponse,
        data: {
          ...mockAdaptiveResponse.data,
          monitoring_level: 'enhanced',
        },
      };

      (enhancedAuthService.performAdaptiveAuthentication as jest.Mock).mockResolvedValue(
        enhancedMonitoringResponse
      );

      render(<AdaptiveAuthIndicator mode="detailed" />);

      await waitFor(() => {
        expect(screen.getByText('Monitoring: Enhanced')).toBeInTheDocument();
      });
    });
  });
});