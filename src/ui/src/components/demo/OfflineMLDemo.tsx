/**
 * Offline & ML Features Demo Component
 * Demonstrates offline mode and ML model selection capabilities
 */
import React, { useState, useEffect } from 'react';
import { Wifi, Brain, Settings, TestTube } from 'lucide-react';
import { OfflineIndicator, SyncManager } from '../offline';
import { ModelSelector, AlgorithmDashboard, RecommendationPanel, AnomalyAlerts } from '../ai';

interface OfflineMLDemoProps {
  className?: string;
}

export const OfflineMLDemo: React.FC<OfflineMLDemoProps> = ({ className = '' }) => {
  const [activeTab, setActiveTab] = useState<'offline' | 'ml' | 'pwa'>('offline');
  const [pwaInstallPrompt, setPwaInstallPrompt] = useState<any>(null);
  const [isInstalled, setIsInstalled] = useState(false);

  const tabs = [
    { id: 'offline', name: 'Offline Mode', icon: Wifi },
    { id: 'ml', name: 'ML Features', icon: Brain },
    { id: 'pwa', name: 'PWA Features', icon: Settings }
  ];

  // PWA install handling
  useEffect(() => {
    const handleBeforeInstallPrompt = (e: Event) => {
      e.preventDefault();
      setPwaInstallPrompt(e);
    };

    const handleAppInstalled = () => {
      setIsInstalled(true);
      setPwaInstallPrompt(null);
    };

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    window.addEventListener('appinstalled', handleAppInstalled);

    // Check if already installed
    if (window.matchMedia('(display-mode: standalone)').matches) {
      setIsInstalled(true);
    }

    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
      window.removeEventListener('appinstalled', handleAppInstalled);
    };
  }, []);

  const installPWA = async () => {
    if (pwaInstallPrompt) {
      pwaInstallPrompt.prompt();
      const { outcome } = await pwaInstallPrompt.userChoice;
      if (outcome === 'accepted') {
        setPwaInstallPrompt(null);
      }
    }
  };

  // Register service worker
  const registerServiceWorker = async () => {
    if ('serviceWorker' in navigator) {
      try {
        const registration = await navigator.serviceWorker.register('/sw.js');
        console.log('Service Worker registered:', registration);
        return true;
      } catch (error) {
        console.error('Service Worker registration failed:', error);
        return false;
      }
    }
    return false;
  };

  // Test offline functionality
  const testOfflineMode = () => {
    // Simulate offline mode by setting navigator.onLine to false (for demo purposes)
    console.log('Testing offline mode...');
    
    // In a real app, you might want to intercept network requests
    // or use a service worker to simulate offline conditions
    
    // Show offline indicator
    window.dispatchEvent(new Event('offline'));
    
    setTimeout(() => {
      window.dispatchEvent(new Event('online'));
    }, 5000);
  };

  const PWAFeatures = () => (
    <div className="space-y-6">
      <div className="bg-gradient-to-r from-blue-50 to-indigo-50 p-6 rounded-lg border border-blue-200">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Progressive Web App Features</h3>
        
        {/* Installation Status */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          <div className="bg-white p-4 rounded border">
            <h4 className="font-medium text-gray-900 mb-2">Installation Status</h4>
            <div className="flex items-center gap-2">
              <div className={`w-3 h-3 rounded-full ${isInstalled ? 'bg-green-500' : 'bg-yellow-500'}`}></div>
              <span className="text-sm text-gray-700">
                {isInstalled ? 'App is installed' : 'App not installed'}
              </span>
            </div>
            {pwaInstallPrompt && !isInstalled && (
              <button 
                onClick={installPWA}
                className="mt-2 px-3 py-1 bg-blue-500 text-white rounded text-sm hover:bg-blue-600"
              >
                Install App
              </button>
            )}
          </div>
          
          <div className="bg-white p-4 rounded border">
            <h4 className="font-medium text-gray-900 mb-2">Service Worker</h4>
            <div className="flex items-center gap-2">
              <div className={`w-3 h-3 rounded-full ${
                'serviceWorker' in navigator ? 'bg-green-500' : 'bg-red-500'
              }`}></div>
              <span className="text-sm text-gray-700">
                {'serviceWorker' in navigator ? 'Supported' : 'Not supported'}
              </span>
            </div>
            <button 
              onClick={registerServiceWorker}
              className="mt-2 px-3 py-1 bg-green-500 text-white rounded text-sm hover:bg-green-600"
            >
              Register SW
            </button>
          </div>
        </div>

        {/* PWA Capabilities */}
        <div className="bg-white p-4 rounded border">
          <h4 className="font-medium text-gray-900 mb-3">PWA Capabilities</h4>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-green-500 rounded-full"></div>
              <span>Offline-first</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-green-500 rounded-full"></div>
              <span>Push notifications</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-green-500 rounded-full"></div>
              <span>Background sync</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-green-500 rounded-full"></div>
              <span>App shortcuts</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-green-500 rounded-full"></div>
              <span>Share target</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-green-500 rounded-full"></div>
              <span>Standalone mode</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-green-500 rounded-full"></div>
              <span>30-day offline</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-green-500 rounded-full"></div>
              <span>Auto-updates</span>
            </div>
          </div>
        </div>

        {/* Test Buttons */}
        <div className="flex gap-3 mt-4">
          <button
            onClick={testOfflineMode}
            className="px-4 py-2 bg-orange-500 text-white rounded hover:bg-orange-600"
          >
            <TestTube className="w-4 h-4 inline mr-2" />
            Test Offline Mode
          </button>
        </div>
      </div>
    </div>
  );

  return (
    <div className={`bg-white border border-gray-200 rounded-lg ${className}`}>
      {/* Header with Tabs */}
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-xl font-semibold text-gray-900">Offline & ML Features Demo</h2>
            <p className="text-sm text-gray-600">
              Interactive demonstration of PWA capabilities, offline functionality, and AI features
            </p>
          </div>
          <OfflineIndicator showDetails={false} />
        </div>

        {/* Tab Navigation */}
        <div className="flex gap-1">
          {tabs.map(tab => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors ${
                  activeTab === tab.id
                    ? 'bg-blue-100 text-blue-700 border border-blue-200'
                    : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
                }`}
              >
                <Icon className="w-4 h-4" />
                {tab.name}
              </button>
            );
          })}
        </div>
      </div>

      {/* Tab Content */}
      <div className="p-6">
        {activeTab === 'offline' && (
          <div className="space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Offline Indicator */}
              <div className="bg-gray-50 p-4 rounded-lg">
                <h3 className="font-medium text-gray-900 mb-3">Network Status</h3>
                <OfflineIndicator showDetails={true} className="relative" />
              </div>

              {/* Sync Manager */}
              <div>
                <h3 className="font-medium text-gray-900 mb-3">Sync Management</h3>
                <SyncManager className="h-fit" />
              </div>
            </div>

            {/* Offline Capabilities */}
            <div className="bg-blue-50 p-6 rounded-lg border border-blue-200">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Offline Capabilities</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                <div className="bg-white p-4 rounded border">
                  <h4 className="font-medium text-blue-900 mb-2">Data Caching</h4>
                  <ul className="text-sm text-gray-700 space-y-1">
                    <li>• 30-day schedule cache</li>
                    <li>• User profile data</li>
                    <li>• Recent notifications</li>
                    <li>• Dashboard metrics</li>
                  </ul>
                </div>
                <div className="bg-white p-4 rounded border">
                  <h4 className="font-medium text-blue-900 mb-2">Offline Actions</h4>
                  <ul className="text-sm text-gray-700 space-y-1">
                    <li>• Submit requests</li>
                    <li>• Update profile</li>
                    <li>• Mark notifications</li>
                    <li>• Queue changes</li>
                  </ul>
                </div>
                <div className="bg-white p-4 rounded border">
                  <h4 className="font-medium text-blue-900 mb-2">Sync Features</h4>
                  <ul className="text-sm text-gray-700 space-y-1">
                    <li>• Background sync</li>
                    <li>• Conflict resolution</li>
                    <li>• Retry mechanisms</li>
                    <li>• Progress tracking</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'ml' && (
          <div className="space-y-6">
            {/* Model Selector */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-4">AI Model Selection</h3>
              <ModelSelector className="mb-6" />
            </div>

            {/* Algorithm Dashboard */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Algorithm Management</h3>
              <AlgorithmDashboard />
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Recommendations */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4">AI Recommendations</h3>
                <RecommendationPanel limit={3} />
              </div>

              {/* Anomaly Alerts */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Anomaly Detection</h3>
                <AnomalyAlerts maxItems={5} />
              </div>
            </div>
          </div>
        )}

        {activeTab === 'pwa' && <PWAFeatures />}
      </div>
    </div>
  );
};

export default OfflineMLDemo;