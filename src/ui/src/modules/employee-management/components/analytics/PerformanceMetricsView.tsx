import React, { useState, useEffect } from 'react';
import { BarChart3, TrendingUp, Award, Clock, Users, Target, RefreshCw } from 'lucide-react';

interface PerformanceData {
  employeeId: string;
  name: string;
  team: string;
  qualityScore: number;
  adherenceScore: number;
  customerSatisfaction: number;
  callsPerHour: number;
  averageHandleTime: number;
  status: 'excellent' | 'good' | 'needs-improvement';
}

const PerformanceMetricsView: React.FC = () => {
  const [performanceData, setPerformanceData] = useState<PerformanceData[]>([]);
  const [selectedTeam, setSelectedTeam] = useState('');
  const [selectedMetric, setSelectedMetric] = useState('qualityScore');
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);

  // Generate mock performance data
  useEffect(() => {
    const teams = ['Support Team', 'Sales Team', 'Quality Team'];
    const mockData: PerformanceData[] = [];

    for (let i = 1; i <= 30; i++) {
      const qualityScore = 75 + Math.random() * 25;
      const adherenceScore = 80 + Math.random() * 20;
      const customerSat = 3.5 + Math.random() * 1.5;

      let status: 'excellent' | 'good' | 'needs-improvement';
      if (qualityScore >= 90 && adherenceScore >= 95) status = 'excellent';
      else if (qualityScore >= 80 && adherenceScore >= 85) status = 'good';
      else status = 'needs-improvement';

      mockData.push({
        employeeId: `EMP${i.toString().padStart(3, '0')}`,
        name: `Employee ${i}`,
        team: teams[i % teams.length],
        qualityScore,
        adherenceScore,
        customerSatisfaction: customerSat,
        callsPerHour: 8 + Math.random() * 8,
        averageHandleTime: 3 + Math.random() * 4,
        status
      });
    }

    setPerformanceData(mockData);
  }, []);

  // Real-time update simulation
  useEffect(() => {
    const interval = setInterval(() => {
      setIsUpdating(true);
      setTimeout(() => {
        setLastUpdate(new Date());
        setIsUpdating(false);
      }, 500);
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  const filteredData = selectedTeam 
    ? performanceData.filter(emp => emp.team === selectedTeam)
    : performanceData;

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'excellent':
        return 'bg-green-100 text-green-800';
      case 'good':
        return 'bg-blue-100 text-blue-800';
      case 'needs-improvement':
        return 'bg-yellow-100 text-yellow-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getMetricColor = (value: number, metric: string) => {
    let threshold: number;
    switch (metric) {
      case 'qualityScore':
      case 'adherenceScore':
        threshold = value >= 90 ? 'green' : value >= 80 ? 'blue' : 'yellow';
        break;
      case 'customerSatisfaction':
        threshold = value >= 4.5 ? 'green' : value >= 4.0 ? 'blue' : 'yellow';
        break;
      default:
        threshold = 'blue';
    }
    
    return threshold === 'green' ? 'text-green-600' : 
           threshold === 'blue' ? 'text-blue-600' : 'text-yellow-600';
  };

  // Calculate team averages
  const teamAverages = teams => {
    const avg = {
      qualityScore: 0,
      adherenceScore: 0,
      customerSatisfaction: 0,
      callsPerHour: 0
    };

    if (filteredData.length === 0) return avg;

    filteredData.forEach(emp => {
      avg.qualityScore += emp.qualityScore;
      avg.adherenceScore += emp.adherenceScore;
      avg.customerSatisfaction += emp.customerSatisfaction;
      avg.callsPerHour += emp.callsPerHour;
    });

    Object.keys(avg).forEach(key => {
      avg[key] = avg[key] / filteredData.length;
    });

    return avg;
  };

  const averages = teamAverages(filteredData);

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 flex items-center">
              <BarChart3 className="h-6 w-6 mr-2 text-blue-600" />
              Performance Metrics
            </h2>
            <p className="mt-2 text-gray-600">
              Track employee performance across key metrics and KPIs
            </p>
          </div>
          <div className={`flex items-center space-x-2 text-sm ${isUpdating ? 'text-blue-600' : 'text-gray-500'}`}>
            <RefreshCw className={`h-4 w-4 ${isUpdating ? 'animate-spin' : ''}`} />
            <span>Last updated: {lastUpdate.toLocaleTimeString()}</span>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
        <div className="flex items-center space-x-4">
          <select
            value={selectedTeam}
            onChange={(e) => setSelectedTeam(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">All Teams</option>
            <option value="Support Team">Support Team</option>
            <option value="Sales Team">Sales Team</option>
            <option value="Quality Team">Quality Team</option>
          </select>

          <select
            value={selectedMetric}
            onChange={(e) => setSelectedMetric(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="qualityScore">Quality Score</option>
            <option value="adherenceScore">Adherence Score</option>
            <option value="customerSatisfaction">Customer Satisfaction</option>
            <option value="callsPerHour">Calls per Hour</option>
          </select>

          <span className="text-sm text-gray-600">
            Showing {filteredData.length} employees
          </span>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Target className="h-8 w-8 text-green-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Quality Score</h3>
              <p className="text-2xl font-bold text-green-600">{averages.qualityScore.toFixed(1)}%</p>
              <p className="text-sm text-gray-600">Team Average</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Clock className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Adherence</h3>
              <p className="text-2xl font-bold text-blue-600">{averages.adherenceScore.toFixed(1)}%</p>
              <p className="text-sm text-gray-600">Schedule Adherence</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Award className="h-8 w-8 text-purple-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Customer Sat</h3>
              <p className="text-2xl font-bold text-purple-600">{averages.customerSatisfaction.toFixed(2)}</p>
              <p className="text-sm text-gray-600">Average Rating</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <TrendingUp className="h-8 w-8 text-orange-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Productivity</h3>
              <p className="text-2xl font-bold text-orange-600">{averages.callsPerHour.toFixed(1)}</p>
              <p className="text-sm text-gray-600">Calls per Hour</p>
            </div>
          </div>
        </div>
      </div>

      {/* Performance Table */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Individual Performance</h3>
        </div>
        
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Employee
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Team
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Quality Score
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Adherence
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Customer Sat
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Calls/Hour
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredData.map((employee) => (
                <tr key={employee.employeeId} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div>
                      <div className="text-sm font-medium text-gray-900">{employee.name}</div>
                      <div className="text-sm text-gray-500">{employee.employeeId}</div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {employee.team}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className={`text-sm font-medium ${getMetricColor(employee.qualityScore, 'qualityScore')}`}>
                      {employee.qualityScore.toFixed(1)}%
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-1 mt-1">
                      <div 
                        className="bg-blue-500 h-1 rounded-full" 
                        style={{ width: `${employee.qualityScore}%` }}
                      />
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className={`text-sm font-medium ${getMetricColor(employee.adherenceScore, 'adherenceScore')}`}>
                      {employee.adherenceScore.toFixed(1)}%
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-1 mt-1">
                      <div 
                        className="bg-green-500 h-1 rounded-full" 
                        style={{ width: `${employee.adherenceScore}%` }}
                      />
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className={`text-sm font-medium ${getMetricColor(employee.customerSatisfaction, 'customerSatisfaction')}`}>
                      {employee.customerSatisfaction.toFixed(2)}
                    </div>
                    <div className="text-xs text-gray-500">out of 5.0</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {employee.callsPerHour.toFixed(1)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(employee.status)}`}>
                      {employee.status === 'needs-improvement' ? 'Needs Improvement' : 
                       employee.status.charAt(0).toUpperCase() + employee.status.slice(1)}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Performance Insights */}
      <div className="mt-8 grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Top Performers</h3>
          {filteredData
            .sort((a, b) => b.qualityScore - a.qualityScore)
            .slice(0, 5)
            .map((employee, index) => (
              <div key={employee.employeeId} className="flex items-center justify-between py-2">
                <div className="flex items-center">
                  <span className="text-sm font-medium text-gray-600 mr-3">#{index + 1}</span>
                  <span className="text-sm text-gray-900">{employee.name}</span>
                </div>
                <span className="text-sm font-medium text-green-600">
                  {employee.qualityScore.toFixed(1)}%
                </span>
              </div>
            ))}
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Improvement Opportunities</h3>
          {filteredData
            .filter(emp => emp.status === 'needs-improvement')
            .slice(0, 5)
            .map((employee) => (
              <div key={employee.employeeId} className="flex items-center justify-between py-2">
                <span className="text-sm text-gray-900">{employee.name}</span>
                <div className="text-right">
                  <span className="text-sm font-medium text-yellow-600">
                    {employee.qualityScore.toFixed(1)}%
                  </span>
                  <p className="text-xs text-gray-500">Quality Score</p>
                </div>
              </div>
            ))}
        </div>
      </div>
    </div>
  );
};

export default PerformanceMetricsView;