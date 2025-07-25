import React, { useState } from 'react';
import { User, Lock, AlertCircle, Globe } from 'lucide-react';
import { realAuthService } from '../services/realAuthService';

// Russian translations per BDD requirements
const translations = {
  ru: {
    title: 'Вход в систему WFM',
    subtitle: 'Введите ваши учетные данные для доступа к системе',
    email: 'Имя пользователя',
    password: 'Пароль',
    login: 'Войти',
    logging: 'Вход в систему...',
    welcome: 'Добро пожаловать',
    redirecting: 'Перенаправление на панель управления...',
    errors: {
      required: 'Пожалуйста, введите имя пользователя и пароль',
      apiUnavailable: 'Сервер API недоступен. Попробуйте позже.',
      authFailed: 'Ошибка аутентификации. Проверьте ваши учетные данные.',
      unexpected: 'Произошла неожиданная ошибка. Попробуйте еще раз.'
    }
  },
  en: {
    title: 'Login to WFM System',
    subtitle: 'Enter your credentials to access the system',
    email: 'Username',
    password: 'Password',
    login: 'Login',
    logging: 'Logging in...',
    welcome: 'Welcome',
    redirecting: 'Redirecting to dashboard...',
    errors: {
      required: 'Please enter both username and password',
      usernameRequired: 'Username is required',
      passwordRequired: 'Password is required',
      apiUnavailable: 'API server is not available. Please try again later.',
      authFailed: 'Invalid credentials',
      unexpected: 'An unexpected error occurred. Please try again.'
    }
  }
};

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [language, setLanguage] = useState<'ru' | 'en'>('en'); // Default to English for E2E tests

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [apiError, setApiError] = useState('');
  const [usernameError, setUsernameError] = useState('');
  const [passwordError, setPasswordError] = useState('');

  const t = translations[language];

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    console.log('Login form submitted with:', { email, password });
    
    setIsLoading(true);
    setError('');
    setApiError('');
    setUsernameError('');
    setPasswordError('');
    
    // Validate individual fields for E2E test compatibility
    let hasErrors = false;
    if (!email || email.trim() === '') {
      console.log('Username validation failed');
      setUsernameError(t.errors.usernameRequired);
      hasErrors = true;
    }
    if (!password || password.trim() === '') {
      console.log('Password validation failed');
      setPasswordError(t.errors.passwordRequired);
      hasErrors = true;
    }
    
    if (hasErrors) {
      console.log('Form has validation errors, stopping submission');
      setIsLoading(false);
      return;
    }

    try {
      // Check API health first
      const isApiHealthy = await realAuthService.checkApiHealth();
      if (!isApiHealthy) {
        setApiError(t.errors.apiUnavailable);
        setIsLoading(false);
        return;
      }

      // Make REAL login call - NO MOCKS
      // Use email as username (API expects username field)
      const result = await realAuthService.login(email, password);
      
      if (result.success && result.data) {
        // Real authentication successful
        setIsLoggedIn(true);
        
        // Store user name for welcome message
        const userName = result.data.user?.name || email.split('@')[0];
        
        // Redirect to dashboard after showing success (E2E test compatibility)
        setTimeout(() => {
          window.location.href = '/dashboard';
        }, 1500);
      } else {
        // Show real error from API in Russian
        setError(result.error || t.errors.authFailed);
        setIsLoading(false);
      }
    } catch (err) {
      // Unexpected error in Russian
      console.error('Login error:', err);
      setError(t.errors.unexpected);
      setIsLoading(false);
    }
  };

  // Get current user for welcome message
  const currentUser = realAuthService.getCurrentUser();
  
  // Show welcome screen after login in Russian
  if (isLoggedIn) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="bg-white p-8 rounded-lg shadow-md text-center">
          <div className="text-green-600 text-6xl mb-4">✓</div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            {t.welcome}, {currentUser?.name || email.split('@')[0]}!
          </h2>
          <p className="text-gray-600">{t.redirecting}</p>
        </div>
      </div>
    );
  }

  // Login form
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8">
        <div>
          {/* Language switcher per BDD requirements */}
          <div className="flex justify-center mb-4">
            <button
              data-testid="language-switcher"
              onClick={() => setLanguage(language === 'ru' ? 'en' : 'ru')}
              className="flex items-center gap-2 px-3 py-1 text-sm text-gray-600 hover:text-gray-900"
            >
              <Globe className="h-4 w-4" />
              {language === 'ru' ? 'English' : 'Русский'}
            </button>
          </div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            {t.title}
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            {t.subtitle}
          </p>
        </div>
        
        <form className="mt-8 space-y-6" onSubmit={handleLogin}>
          <div className="rounded-md shadow-sm -space-y-px">
            <div>
              <label htmlFor="username" className="sr-only">{t.email}</label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center">
                  <User className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  data-testid="login-username-input"
                  id="username"
                  name="username"
                  type="text"
                  autoComplete="username"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="appearance-none rounded-none relative block w-full pl-10 px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                  placeholder={t.email}
                />
              </div>
              {usernameError && (
                <div className="mt-1 text-sm text-red-600">
                  {usernameError}
                </div>
              )}
            </div>
            <div>
              <label htmlFor="password" className="sr-only">{t.password}</label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center">
                  <Lock className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  data-testid="login-password-input"
                  id="password"
                  name="password"
                  type="password"
                  autoComplete="current-password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="appearance-none rounded-none relative block w-full pl-10 px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                  placeholder={t.password}
                />
              </div>
              {passwordError && (
                <div className="mt-1 text-sm text-red-600">
                  {passwordError}
                </div>
              )}
            </div>
          </div>

          <div>
            <button
              data-testid="login-submit-button"
              type="submit"
              disabled={isLoading}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? t.logging : t.login}
            </button>
          </div>
          
          {error && (
            <div data-testid="login-error-message" className="mt-3 p-3 bg-red-50 border border-red-200 rounded-md">
              <div className="flex">
                <AlertCircle className="h-5 w-5 text-red-400 mr-2" />
                <div className="text-sm text-red-800">
                  {error}
                </div>
              </div>
            </div>
          )}
          
          {apiError && (
            <div data-testid="login-api-error-message" className="mt-3 p-3 bg-yellow-50 border border-yellow-200 rounded-md">
              <div className="flex">
                <AlertCircle className="h-5 w-5 text-yellow-400 mr-2" />
                <div className="text-sm text-yellow-800">
                  {apiError}
                </div>
              </div>
            </div>
          )}
        </form>
      </div>
    </div>
  );
};

export default Login;