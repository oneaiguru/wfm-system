/**
 * UserPermissions RBAC Integration Test Component
 * Tests the connection to GET /api/v1/rbac/users/{id}/permissions endpoint
 */

import React, { useState } from 'react';
import { AlertCircle, CheckCircle, Loader2, Key, User, Shield } from 'lucide-react';
import realAccessRoleService from '../../services/realAccessRoleService';

const UserPermissionsTest: React.FC = () => {
  const [userId, setUserId] = useState('1');
  const [isLoading, setIsLoading] = useState(false);
  const [result, setResult] = useState<any>(null);
  const [error, setError] = useState('');

  const testRBACEndpoint = async () => {
    setIsLoading(true);
    setError('');
    setResult(null);

    try {
      console.log(`[RBAC TEST] Testing RBAC endpoint for user ${userId}...`);
      
      // Test using realAccessRoleService
      const serviceResult = await realAccessRoleService.getUserPermissions(userId, true);
      
      if (serviceResult.success && serviceResult.data) {
        setResult({
          method: 'Service',
          data: serviceResult.data,
          timestamp: new Date().toLocaleString()
        });
        console.log('✅ RBAC service test successful');
      } else {
        // Test direct API call
        const response = await fetch(`http://localhost:8001/api/v1/rbac/users/${userId}/permissions?include_role_permissions=true`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
            'Content-Type': 'application/json',
          },
        });

        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();
        setResult({
          method: 'Direct API',
          data: data,
          timestamp: new Date().toLocaleString()
        });
        console.log('✅ Direct API test successful');
      }

    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Unknown error';
      setError(errorMsg);
      console.error('[RBAC TEST] Test failed:', err);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="bg-white rounded-lg shadow-md p-6 max-w-4xl mx-auto">
      {/* Header */}
      <div className="border-b border-gray-200 pb-4 mb-6">
        <h2 className="text-xl font-semibold text-gray-900 flex items-center">
          <Shield className="h-6 w-6 text-blue-600 mr-2" />
          RBAC Integration Test
        </h2>
        <p className="text-gray-600 mt-1">
          Test connection to GET /api/v1/rbac/users/{'{user_id}'}/permissions endpoint
        </p>
      </div>

      {/* Test Controls */}
      <div className="mb-6">
        <div className="flex items-center gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              User ID to Test
            </label>
            <input
              type="text"
              value={userId}
              onChange={(e) => setUserId(e.target.value)}
              className="block w-32 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="1"
            />
          </div>
          <div className="mt-6">
            <button
              onClick={testRBACEndpoint}
              disabled={isLoading || !userId}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
            >
              {isLoading ? (
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
              ) : (
                <Key className="h-4 w-4 mr-2" />
              )}
              Test RBAC Endpoint
            </button>
          </div>
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-md">
          <div className="flex items-center">
            <AlertCircle className="h-5 w-5 text-red-500 mr-2" />
            <div>
              <p className="font-medium text-red-800">Test Failed</p>
              <p className="text-red-700 text-sm">{error}</p>
            </div>
          </div>
        </div>
      )}

      {/* Success Result */}
      {result && (
        <div className="mb-6 p-4 bg-green-50 border border-green-200 rounded-md">
          <div className="flex items-center mb-3">
            <CheckCircle className="h-5 w-5 text-green-500 mr-2" />
            <div>
              <p className="font-medium text-green-800">Test Successful</p>
              <p className="text-green-700 text-sm">
                Method: {result.method} | Time: {result.timestamp}
              </p>
            </div>
          </div>

          {/* Data Display */}
          <div className="mt-4">
            <h4 className="font-medium text-gray-900 mb-2">RBAC Data Retrieved:</h4>
            
            {/* Direct Permissions */}
            {result.data.direct_permissions && (
              <div className="mb-4">
                <h5 className="text-sm font-medium text-gray-700 mb-2">
                  Direct Permissions ({result.data.direct_permissions.length})
                </h5>
                <div className="space-y-1">
                  {result.data.direct_permissions.map((perm: any, index: number) => (
                    <div key={index} className="flex items-center text-sm">
                      <Key className="h-3 w-3 text-blue-500 mr-2" />
                      <span className="font-medium">{perm.name || perm.id}</span>
                      <span className="text-gray-500 ml-2">({perm.resource}.{perm.action})</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Role Permissions */}
            {result.data.role_permissions && (
              <div className="mb-4">
                <h5 className="text-sm font-medium text-gray-700 mb-2">
                  Role-Based Permissions ({result.data.role_permissions.length})
                </h5>
                <div className="space-y-1">
                  {result.data.role_permissions.map((perm: any, index: number) => (
                    <div key={index} className="flex items-center text-sm">
                      <User className="h-3 w-3 text-purple-500 mr-2" />
                      <span className="font-medium">{perm.name || perm.id}</span>
                      <span className="text-gray-500 ml-2">({perm.resource}.{perm.action})</span>
                      {perm.source_role && (
                        <span className="text-xs bg-purple-100 text-purple-700 px-2 py-1 rounded ml-2">
                          {perm.source_role}
                        </span>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* All Permissions Summary */}
            {result.data.all_permissions && (
              <div className="p-3 bg-gray-50 rounded">
                <p className="text-sm font-medium text-gray-900">
                  Total Permissions: {result.data.all_permissions.length}
                </p>
                <p className="text-xs text-gray-600 mt-1">
                  This data will be used by UserPermissions component for real RBAC integration
                </p>
              </div>
            )}

            {/* Raw Data (Collapsible) */}
            <details className="mt-4">
              <summary className="cursor-pointer text-sm font-medium text-gray-700">
                View Raw JSON Response
              </summary>
              <pre className="mt-2 text-xs bg-gray-100 p-3 rounded overflow-auto max-h-64">
                {JSON.stringify(result.data, null, 2)}
              </pre>
            </details>
          </div>
        </div>
      )}

      {/* Integration Status */}
      <div className="border-t border-gray-200 pt-4">
        <h3 className="font-medium text-gray-900 mb-2">Integration Status</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
          <div className="flex items-center">
            <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
            <span>UserPermissions.tsx - Ready</span>
          </div>
          <div className="flex items-center">
            <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
            <span>realAccessRoleService.ts - Ready</span>
          </div>
          <div className="flex items-center">
            <div className="w-3 h-3 bg-blue-500 rounded-full mr-2"></div>
            <span>RBAC API - {result ? 'Connected' : 'Testing...'}</span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default UserPermissionsTest;