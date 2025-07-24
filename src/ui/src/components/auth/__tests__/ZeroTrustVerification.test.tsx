import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import { ZeroTrustVerification } from '../ZeroTrustVerification';
import { enhancedAuthService } from '../../../services/realAuthService';

// Mock the auth service
jest.mock('../../../services/realAuthService', () => ({
  enhancedAuthService: {
    performZeroTrustVerification: jest.fn(),
  },
}));

describe('ZeroTrustVerification Component', () => {
  const mockZeroTrustResponse = {
    success: true,
    data: {
      verification_id: 'zt_test123',
      trust_score: 95,
      verification_status: 'verified',
      risk_factors: [
        { factor: 'new_device', risk_level: 'medium', detected: false },
        { factor: 'unusual_location', risk_level: 'high', detected: false },
        { factor: 'behavior_anomaly', risk_level: 'low', detected: false },
      ],
      required_actions: [],
      session_expiry: '2025-07-24T12:00:00Z',
      continuous_monitoring: true,
      recommendations: ['Device trusted', 'Location approved'],
    },
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Compact Mode', () => {
    it('renders trust score in compact mode', async () => {
      (enhancedAuthService.performZeroTrustVerification as jest.Mock).mockResolvedValue(
        mockZeroTrustResponse
      );

      render(<ZeroTrustVerification mode="compact" />);

      await waitFor(() => {
        expect(screen.getByText('95')).toBeInTheDocument();
        expect(screen.getByText('Trust Score')).toBeInTheDocument();
      });
    });

    it('shows low trust warning in compact mode', async () => {
      const lowTrustResponse = {
        ...mockZeroTrustResponse,
        data: {
          ...mockZeroTrustResponse.data,
          trust_score: 45,
          verification_status: 'warning',
        },
      };

      (enhancedAuthService.performZeroTrustVerification as jest.Mock).mockResolvedValue(
        lowTrustResponse
      );

      render(<ZeroTrustVerification mode="compact" />);

      await waitFor(() => {
        expect(screen.getByText('45')).toBeInTheDocument();
        const trustElement = screen.getByText('45').closest('div');
        expect(trustElement).toHaveClass('text-red-600');
      });
    });
  });

  describe('Full Mode', () => {
    it('renders all verification details in full mode', async () => {
      (enhancedAuthService.performZeroTrustVerification as jest.Mock).mockResolvedValue(
        mockZeroTrustResponse
      );

      render(<ZeroTrustVerification mode="full" />);

      await waitFor(() => {
        // Header
        expect(screen.getByText('Zero Trust Verification')).toBeInTheDocument();
        
        // Trust Score
        expect(screen.getByText('95%')).toBeInTheDocument();
        expect(screen.getByText('Verified')).toBeInTheDocument();
        
        // Risk Factors
        expect(screen.getByText('Risk Factors')).toBeInTheDocument();
        expect(screen.getByText('New Device')).toBeInTheDocument();
        expect(screen.getByText('Unusual Location')).toBeInTheDocument();
        expect(screen.getByText('Behavior Anomaly')).toBeInTheDocument();
        
        // Recommendations
        expect(screen.getByText('Recommendations')).toBeInTheDocument();
        expect(screen.getByText('Device trusted')).toBeInTheDocument();
        expect(screen.getByText('Location approved')).toBeInTheDocument();
      });
    });

    it('displays required actions when present', async () => {
      const responseWithActions = {
        ...mockZeroTrustResponse,
        data: {
          ...mockZeroTrustResponse.data,
          required_actions: ['Verify phone number', 'Update security questions'],
        },
      };

      (enhancedAuthService.performZeroTrustVerification as jest.Mock).mockResolvedValue(
        responseWithActions
      );

      render(<ZeroTrustVerification mode="full" />);

      await waitFor(() => {
        expect(screen.getByText('Required Actions')).toBeInTheDocument();
        expect(screen.getByText('Verify phone number')).toBeInTheDocument();
        expect(screen.getByText('Update security questions')).toBeInTheDocument();
      });
    });
  });

  describe('Error Handling', () => {
    it('displays error message when verification fails', async () => {
      (enhancedAuthService.performZeroTrustVerification as jest.Mock).mockResolvedValue({
        success: false,
        error: 'Network connection error',
      });

      render(<ZeroTrustVerification mode="full" />);

      await waitFor(() => {
        expect(screen.getByText('Network connection error')).toBeInTheDocument();
      });
    });

    it('handles API errors gracefully', async () => {
      (enhancedAuthService.performZeroTrustVerification as jest.Mock).mockRejectedValue(
        new Error('API Error')
      );

      render(<ZeroTrustVerification mode="full" />);

      await waitFor(() => {
        expect(screen.getByText('Failed to perform Zero Trust verification')).toBeInTheDocument();
      });
    });
  });

  describe('Auto-refresh', () => {
    it('refreshes data at specified interval', async () => {
      jest.useFakeTimers();
      
      (enhancedAuthService.performZeroTrustVerification as jest.Mock).mockResolvedValue(
        mockZeroTrustResponse
      );

      render(<ZeroTrustVerification mode="full" refreshInterval={1} />); // 1 minute

      await waitFor(() => {
        expect(screen.getByText('95%')).toBeInTheDocument();
      });

      expect(enhancedAuthService.performZeroTrustVerification).toHaveBeenCalledTimes(1);

      // Fast forward 1 minute
      jest.advanceTimersByTime(60000);

      await waitFor(() => {
        expect(enhancedAuthService.performZeroTrustVerification).toHaveBeenCalledTimes(2);
      });

      jest.useRealTimers();
    });
  });

  describe('Callbacks', () => {
    it('calls onTrustScoreChange when trust score changes', async () => {
      const onTrustScoreChange = jest.fn();
      
      (enhancedAuthService.performZeroTrustVerification as jest.Mock).mockResolvedValue(
        mockZeroTrustResponse
      );

      render(
        <ZeroTrustVerification 
          mode="full" 
          onTrustScoreChange={onTrustScoreChange} 
        />
      );

      await waitFor(() => {
        expect(onTrustScoreChange).toHaveBeenCalledWith(95);
      });
    });

    it('calls onRequiredActions when actions are present', async () => {
      const onRequiredActions = jest.fn();
      
      const responseWithActions = {
        ...mockZeroTrustResponse,
        data: {
          ...mockZeroTrustResponse.data,
          required_actions: ['Verify phone'],
        },
      };

      (enhancedAuthService.performZeroTrustVerification as jest.Mock).mockResolvedValue(
        responseWithActions
      );

      render(
        <ZeroTrustVerification 
          mode="full" 
          onRequiredActions={onRequiredActions} 
        />
      );

      await waitFor(() => {
        expect(onRequiredActions).toHaveBeenCalledWith(['Verify phone']);
      });
    });
  });

  describe('Loading State', () => {
    it('shows loading spinner while fetching data', async () => {
      (enhancedAuthService.performZeroTrustVerification as jest.Mock).mockImplementation(
        () => new Promise(() => {}) // Never resolves
      );

      render(<ZeroTrustVerification mode="full" />);

      expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
    });
  });

  describe('Session Expiry', () => {
    it('displays session expiry countdown', async () => {
      const futureDate = new Date();
      futureDate.setHours(futureDate.getHours() + 2);
      
      const responseWithExpiry = {
        ...mockZeroTrustResponse,
        data: {
          ...mockZeroTrustResponse.data,
          session_expiry: futureDate.toISOString(),
        },
      };

      (enhancedAuthService.performZeroTrustVerification as jest.Mock).mockResolvedValue(
        responseWithExpiry
      );

      render(<ZeroTrustVerification mode="full" />);

      await waitFor(() => {
        expect(screen.getByText(/Session expires in/)).toBeInTheDocument();
      });
    });
  });
});