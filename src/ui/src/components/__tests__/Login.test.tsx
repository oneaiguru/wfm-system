import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import Login from '../Login';

describe('Login Component', () => {
  // 🔴 RED: Test what the user should see and do
  it('renders login form with email and password fields', () => {
    render(<Login />);
    
    expect(screen.getByPlaceholderText('Email')).toBeInTheDocument();
    expect(screen.getByPlaceholderText('Password')).toBeInTheDocument();
    expect(screen.getByText('Login to WFM System')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Login' })).toBeInTheDocument();
  });

  it('shows welcome message after login', () => {
    render(<Login />);
    
    const emailInput = screen.getByPlaceholderText('Email');
    const passwordInput = screen.getByPlaceholderText('Password');
    const loginButton = screen.getByRole('button', { name: 'Login' });
    
    // User enters credentials
    fireEvent.change(emailInput, { target: { value: 'anna@wfm.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });
    fireEvent.click(loginButton);
    
    // Should see welcome message
    expect(screen.getByText('Welcome, Anna Petrov!')).toBeInTheDocument();
    expect(screen.getByText('Redirecting to dashboard...')).toBeInTheDocument();
  });

  it('shows demo credentials hint', () => {
    render(<Login />);
    
    expect(screen.getByText(/Demo: anna@wfm.com/)).toBeInTheDocument();
  });
});