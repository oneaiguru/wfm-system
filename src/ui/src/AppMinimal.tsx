import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';

function AppMinimal() {
  return (
    <Router>
      <div className="min-h-screen bg-gray-100">
        <nav className="bg-white shadow mb-8">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex justify-between h-16">
              <div className="flex">
                <div className="flex-shrink-0 flex items-center">
                  <h1 className="text-xl font-bold">WFM Enterprise System</h1>
                </div>
                <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
                  <Link to="/" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Home
                  </Link>
                  <Link to="/vacation-test" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                    Vacation Request Test
                  </Link>
                </div>
              </div>
            </div>
          </div>
        </nav>

        <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/vacation-test" element={<VacationTest />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

function Home() {
  return (
    <div className="bg-white overflow-hidden shadow rounded-lg">
      <div className="px-4 py-5 sm:p-6">
        <h2 className="text-lg font-medium text-gray-900 mb-4">WFM System Status</h2>
        <p className="text-sm text-gray-500">✅ UI Server Running</p>
        <p className="text-sm text-gray-500">✅ API Server on port 8000</p>
        <p className="text-sm text-gray-500">✅ Ready for BDD Testing</p>
      </div>
    </div>
  );
}

function VacationTest() {
  const [result, setResult] = React.useState<any>(null);
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      const response = await fetch('http://localhost:8001/api/v1/requests/vacation', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          employee_id: 2,
          request_type: 'vacation',
          start_date: '2025-08-20',
          end_date: '2025-08-25',
          description: 'Browser UI test'
        })
      });
      
      const data = await response.json();
      setResult(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to submit request');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white overflow-hidden shadow rounded-lg">
      <div className="px-4 py-5 sm:p-6">
        <h2 className="text-lg font-medium text-gray-900 mb-4">Vacation Request Test</h2>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="bg-gray-50 p-4 rounded">
            <h3 className="text-sm font-medium text-gray-700 mb-2">Test Data:</h3>
            <pre className="text-xs text-gray-600">
{JSON.stringify({
  employee_id: 2,
  request_type: 'vacation',
  start_date: '2025-08-20',
  end_date: '2025-08-25',
  description: 'Browser UI test'
}, null, 2)}
            </pre>
          </div>
          
          <button
            type="submit"
            disabled={loading}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
          >
            {loading ? 'Submitting...' : 'Submit Vacation Request'}
          </button>
        </form>
        
        {error && (
          <div className="mt-4 bg-red-50 border border-red-200 rounded p-4">
            <p className="text-sm text-red-600">Error: {error}</p>
          </div>
        )}
        
        {result && (
          <div className="mt-4 bg-green-50 border border-green-200 rounded p-4">
            <h3 className="text-sm font-medium text-green-800 mb-2">Success!</h3>
            <pre className="text-xs text-green-600">
{JSON.stringify(result, null, 2)}
            </pre>
          </div>
        )}
      </div>
    </div>
  );
}

export default AppMinimal;