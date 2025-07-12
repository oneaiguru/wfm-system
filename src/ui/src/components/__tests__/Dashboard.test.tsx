import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import Dashboard from '../Dashboard';

describe('Dashboard Component', () => {
  // 🔴 RED: Test key metrics display
  it('renders dashboard with key metrics', () => {
    render(<Dashboard />);
    
    // Should show title
    expect(screen.getByText('WFM Dashboard')).toBeInTheDocument();
    
    // Should show key metrics
    expect(screen.getByText('Active Agents')).toBeInTheDocument();
    expect(screen.getByText('127')).toBeInTheDocument();
    
    expect(screen.getByText('Service Level')).toBeInTheDocument();
    expect(screen.getByText('94.2%')).toBeInTheDocument();
    
    expect(screen.getByText('Calls Handled')).toBeInTheDocument();
    expect(screen.getByText('3,847')).toBeInTheDocument();
    
    expect(screen.getByText('Average Wait Time')).toBeInTheDocument();
    expect(screen.getByText('0:45')).toBeInTheDocument();
  });

  it('renders navigation links to other modules', () => {
    render(<Dashboard />);
    
    expect(screen.getByText('Schedule Management')).toBeInTheDocument();
    expect(screen.getByText('Forecasting Analytics')).toBeInTheDocument();
    expect(screen.getByText('Reports & Analytics')).toBeInTheDocument();
  });

  it('shows real-time status indicator', () => {
    render(<Dashboard />);
    
    expect(screen.getByText(/Live Data/)).toBeInTheDocument();
    expect(screen.getByText(/Last updated:/)).toBeInTheDocument();
  });
});