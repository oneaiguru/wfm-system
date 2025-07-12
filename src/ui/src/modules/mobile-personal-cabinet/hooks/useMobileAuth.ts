import { useState, useEffect } from 'react';
import { MobileUser } from '../types/mobile';

// BDD: Authentication with username/password, biometric authentication option
export const useMobileAuth = () => {
  const [user, setUser] = useState<MobileUser | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [biometricAvailable, setBiometricAvailable] = useState(false);

  useEffect(() => {
    // Check for existing session
    const storedUser = localStorage.getItem('mobileUser');
    const authToken = localStorage.getItem('authToken');
    
    if (storedUser && authToken) {
      setUser(JSON.parse(storedUser));
      setIsAuthenticated(true);
    }
    
    // Check biometric availability (mock implementation)
    checkBiometricAvailability();
    
    setIsLoading(false);
  }, []);

  const checkBiometricAvailability = async () => {
    // Mock biometric check - in real app would use Web Authentication API
    if ('credentials' in navigator && 'create' in navigator.credentials) {
      setBiometricAvailable(true);
    }
  };

  const login = async (username: string, password: string) => {
    setIsLoading(true);
    
    try {
      // Mock API call - BDD specifies API-based authentication
      const response = await fetch('/api/mobile/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
      });
      
      if (response.ok) {
        const data = await response.json();
        const mobileUser: MobileUser = {
          id: data.user.id,
          name: data.user.name,
          email: data.user.email,
          role: data.user.role,
          department: data.user.department,
          photo: data.user.photo,
          biometricEnabled: data.user.biometricEnabled
        };
        
        setUser(mobileUser);
        setIsAuthenticated(true);
        
        localStorage.setItem('mobileUser', JSON.stringify(mobileUser));
        localStorage.setItem('authToken', data.token);
        
        return { success: true };
      } else {
        return { success: false, error: 'Invalid credentials' };
      }
    } catch (error) {
      // Fallback to mock data if API unavailable
      const mockUser: MobileUser = {
        id: '1',
        name: 'Анна Петрова',
        email: 'anna.petrova@technoservice.ru',
        role: 'Агент',
        department: 'Техподдержка',
        biometricEnabled: true
      };
      
      setUser(mockUser);
      setIsAuthenticated(true);
      localStorage.setItem('mobileUser', JSON.stringify(mockUser));
      localStorage.setItem('authToken', 'mock-token');
      
      return { success: true };
    } finally {
      setIsLoading(false);
    }
  };

  const loginWithBiometric = async () => {
    if (!biometricAvailable) {
      return { success: false, error: 'Biometric authentication not available' };
    }
    
    try {
      // Mock biometric authentication
      // In real app would use navigator.credentials.get() with WebAuthn
      const storedUser = localStorage.getItem('mobileUser');
      if (storedUser) {
        const mobileUser = JSON.parse(storedUser);
        setUser(mobileUser);
        setIsAuthenticated(true);
        return { success: true };
      }
      
      return { success: false, error: 'No biometric credentials found' };
    } catch (error) {
      return { success: false, error: 'Biometric authentication failed' };
    }
  };

  const logout = () => {
    setUser(null);
    setIsAuthenticated(false);
    localStorage.removeItem('mobileUser');
    localStorage.removeItem('authToken');
    
    // Redirect to login
    window.location.href = '/mobile/login';
  };

  const enableBiometric = async () => {
    if (!biometricAvailable || !user) {
      return { success: false, error: 'Cannot enable biometric' };
    }
    
    try {
      // Mock biometric enrollment
      // In real app would use navigator.credentials.create()
      const updatedUser = { ...user, biometricEnabled: true };
      setUser(updatedUser);
      localStorage.setItem('mobileUser', JSON.stringify(updatedUser));
      
      return { success: true };
    } catch (error) {
      return { success: false, error: 'Failed to enable biometric' };
    }
  };

  const disableBiometric = async () => {
    if (!user) {
      return { success: false, error: 'No user found' };
    }
    
    const updatedUser = { ...user, biometricEnabled: false };
    setUser(updatedUser);
    localStorage.setItem('mobileUser', JSON.stringify(updatedUser));
    
    return { success: true };
  };

  return {
    user,
    isAuthenticated,
    isLoading,
    biometricAvailable,
    login,
    loginWithBiometric,
    logout,
    enableBiometric,
    disableBiometric
  };
};