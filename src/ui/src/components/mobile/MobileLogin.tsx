import React, { useState, useEffect } from 'react';
import './MobileLogin.css';

interface BiometricCredentials {
  type: 'fingerprint' | 'face' | 'voice';
  data: string;
}

interface LoginCredentials {
  username: string;
  password: string;
  biometric?: BiometricCredentials;
  deviceId?: string;
}

interface MobileLoginProps {
  onLogin: (credentials: LoginCredentials) => Promise<void>;
  loading?: boolean;
}

const MobileLogin: React.FC<MobileLoginProps> = ({ onLogin, loading = false }) => {
  const [credentials, setCredentials] = useState<LoginCredentials>({
    username: '',
    password: ''
  });
  const [biometricSupported, setBiometricSupported] = useState(false);
  const [biometricEnabled, setBiometricEnabled] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [loginAttempts, setLoginAttempts] = useState(0);
  const [isLocked, setIsLocked] = useState(false);
  const [rememberDevice, setRememberDevice] = useState(false);

  useEffect(() => {
    checkBiometricSupport();
    loadSavedCredentials();
    generateDeviceId();
  }, []);

  const checkBiometricSupport = async () => {
    try {
      // Check if device supports biometric authentication
      if ('credentials' in navigator && 'create' in navigator.credentials) {
        const available = await (navigator.credentials as any).create({
          publicKey: {
            challenge: new Uint8Array(32),
            rp: { name: 'WFM Mobile' },
            user: {
              id: new Uint8Array(16),
              name: 'test',
              displayName: 'Test User'
            },
            pubKeyCredParams: [{ alg: -7, type: 'public-key' }],
            authenticatorSelection: {
              authenticatorAttachment: 'platform',
              userVerification: 'required'
            }
          }
        });
        
        if (available) {
          setBiometricSupported(true);
          setBiometricEnabled(localStorage.getItem('biometric_enabled') === 'true');
        }
      }
    } catch (error) {
      console.log('Биометрическая аутентификация недоступна:', error);
    }
  };

  const loadSavedCredentials = () => {
    const savedUsername = localStorage.getItem('mobile_username');
    const savedRememberDevice = localStorage.getItem('remember_device') === 'true';
    
    if (savedUsername) {
      setCredentials(prev => ({ ...prev, username: savedUsername }));
    }
    setRememberDevice(savedRememberDevice);
  };

  const generateDeviceId = () => {
    let deviceId = localStorage.getItem('device_id');
    if (!deviceId) {
      deviceId = 'mobile_' + Math.random().toString(36).substr(2, 9) + '_' + Date.now();
      localStorage.setItem('device_id', deviceId);
    }
    setCredentials(prev => ({ ...prev, deviceId }));
  };

  const authenticateWithBiometric = async (): Promise<BiometricCredentials | null> => {
    try {
      if (!biometricSupported) return null;

      const credential = await (navigator.credentials as any).get({
        publicKey: {
          challenge: new Uint8Array(32),
          allowCredentials: [],
          userVerification: 'required'
        }
      });

      if (credential) {
        return {
          type: 'fingerprint', // Could be enhanced to detect actual type
          data: btoa(String.fromCharCode(...new Uint8Array(credential.response.signature)))
        };
      }
    } catch (error) {
      console.error('Биометрическая аутентификация не удалась:', error);
    }
    return null;
  };

  const handleBiometricLogin = async () => {
    const biometric = await authenticateWithBiometric();
    if (biometric && credentials.username) {
      const loginData = {
        ...credentials,
        biometric
      };
      
      try {
        await callMobileAuthAPI(loginData);
        await onLogin(loginData);
      } catch (error) {
        console.error('Вход с биометрией не удался:', error);
      }
    }
  };

  const handlePasswordLogin = async () => {
    if (!credentials.username || !credentials.password) {
      alert('Пожалуйста, введите имя пользователя и пароль');
      return;
    }

    if (isLocked) {
      alert('Аккаунт заблокирован. Попробуйте через 15 минут.');
      return;
    }

    try {
      await callMobileAuthAPI(credentials);
      await onLogin(credentials);
      
      // Save credentials if remember device is enabled
      if (rememberDevice) {
        localStorage.setItem('mobile_username', credentials.username);
        localStorage.setItem('remember_device', 'true');
      }
      
      setLoginAttempts(0);
    } catch (error) {
      console.error('Вход не удался:', error);
      handleFailedLogin();
    }
  };

  const callMobileAuthAPI = async (loginData: LoginCredentials) => {
    const response = await fetch('/api/v1/mobile/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'WFM-Mobile-App',
        'Device-ID': loginData.deviceId || ''
      },
      body: JSON.stringify({
        username: loginData.username,
        password: loginData.password,
        biometric_data: loginData.biometric,
        device_info: {
          platform: navigator.platform,
          user_agent: navigator.userAgent,
          screen_resolution: `${screen.width}x${screen.height}`,
          timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
        },
        remember_device: rememberDevice
      })
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Ошибка аутентификации');
    }

    const result = await response.json();
    
    // Store auth token
    if (result.access_token) {
      localStorage.setItem('mobile_auth_token', result.access_token);
      if (result.refresh_token) {
        localStorage.setItem('mobile_refresh_token', result.refresh_token);
      }
    }

    return result;
  };

  const handleFailedLogin = () => {
    setLoginAttempts(prev => prev + 1);
    
    if (loginAttempts >= 4) {
      setIsLocked(true);
      setTimeout(() => setIsLocked(false), 15 * 60 * 1000); // 15 minutes lock
    }
  };

  const enableBiometric = async () => {
    const biometric = await authenticateWithBiometric();
    if (biometric) {
      setBiometricEnabled(true);
      localStorage.setItem('biometric_enabled', 'true');
      alert('Биометрическая аутентификация включена');
    }
  };

  return (
    <div className="mobile-login">
      <div className="mobile-login__container">
        <div className="mobile-login__header">
          <div className="mobile-login__logo">
            <svg viewBox="0 0 24 24" className="mobile-login__logo-icon">
              <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" 
                    stroke="currentColor" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
          <h1 className="mobile-login__title">WFM Мобильный</h1>
          <p className="mobile-login__subtitle">Личный кабинет сотрудника</p>
        </div>

        <div className="mobile-login__form">
          <div className="mobile-login__field">
            <label className="mobile-login__label">Имя пользователя</label>
            <input
              type="text"
              className="mobile-login__input"
              value={credentials.username}
              onChange={(e) => setCredentials(prev => ({ ...prev, username: e.target.value }))}
              placeholder="Введите имя пользователя"
              autoComplete="username"
              disabled={loading}
            />
          </div>

          <div className="mobile-login__field">
            <label className="mobile-login__label">Пароль</label>
            <div className="mobile-login__password-field">
              <input
                type={showPassword ? 'text' : 'password'}
                className="mobile-login__input"
                value={credentials.password}
                onChange={(e) => setCredentials(prev => ({ ...prev, password: e.target.value }))}
                placeholder="Введите пароль"
                autoComplete="current-password"
                disabled={loading}
              />
              <button
                type="button"
                className="mobile-login__password-toggle"
                onClick={() => setShowPassword(!showPassword)}
                disabled={loading}
              >
                {showPassword ? '👁️' : '👁️‍🗨️'}
              </button>
            </div>
          </div>

          <div className="mobile-login__options">
            <label className="mobile-login__checkbox">
              <input
                type="checkbox"
                checked={rememberDevice}
                onChange={(e) => setRememberDevice(e.target.checked)}
                disabled={loading}
              />
              <span className="mobile-login__checkbox-text">Запомнить устройство</span>
            </label>
          </div>

          <button
            className="mobile-login__button mobile-login__button--primary"
            onClick={handlePasswordLogin}
            disabled={loading || isLocked}
          >
            {loading ? 'Вход...' : isLocked ? 'Заблокировано' : 'Войти'}
          </button>

          {biometricSupported && (
            <div className="mobile-login__biometric">
              {biometricEnabled ? (
                <button
                  className="mobile-login__button mobile-login__button--biometric"
                  onClick={handleBiometricLogin}
                  disabled={loading || !credentials.username}
                >
                  🔐 Вход по биометрии
                </button>
              ) : (
                <button
                  className="mobile-login__button mobile-login__button--secondary"
                  onClick={enableBiometric}
                  disabled={loading}
                >
                  🔒 Включить биометрию
                </button>
              )}
            </div>
          )}

          {loginAttempts > 0 && (
            <div className="mobile-login__warning">
              ⚠️ Неверные данные. Попыток: {loginAttempts}/5
            </div>
          )}
        </div>

        <div className="mobile-login__footer">
          <p className="mobile-login__version">v2.0.0 • Сборка 240715</p>
          <p className="mobile-login__copyright">© 2024 WFM Enterprise</p>
        </div>
      </div>
    </div>
  );
};

export default MobileLogin;