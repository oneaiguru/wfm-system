import React, { useState, useEffect } from 'react';
import { Search, Filter, Download, Upload, Users, Grid, List, RefreshCw } from 'lucide-react';
import { Employee, EmployeeFilters, EmployeeStats } from '../../types/employee';

interface EmployeeListContainerProps {
  viewMode: 'list' | 'grid' | 'gallery';
}

const EmployeeListContainer: React.FC<EmployeeListContainerProps> = ({ viewMode }) => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [filteredEmployees, setFilteredEmployees] = useState<Employee[]>([]);
  const [filters, setFilters] = useState<EmployeeFilters>({
    search: '',
    team: '',
    status: '',
    skill: '',
    position: '',
    sortBy: 'name',
    sortOrder: 'asc',
    showInactive: false
  });
  const [stats, setStats] = useState<EmployeeStats>({
    total: 0,
    active: 0,
    vacation: 0,
    probation: 0,
    inactive: 0,
    terminated: 0
  });
  const [selectedEmployees, setSelectedEmployees] = useState<string[]>([]);
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);

  // Mock data generation
  useEffect(() => {
    const mockEmployees: Employee[] = [
      {
        id: 'emp_001',
        employeeId: 'EMP001',
        personalInfo: {
          firstName: 'Anna',
          lastName: 'Petrov',
          email: 'anna.petrov@company.com',
          phone: '+7 495 123 4567',
          photo: 'https://i.pravatar.cc/150?img=1'
        },
        workInfo: {
          position: 'Senior Operator',
          team: {
            id: 't1',
            name: 'Support Team',
            color: '#3b82f6',
            managerId: 'mgr_001',
            memberCount: 12,
            targetUtilization: 0.85
          },
          manager: 'Ivanov I.I.',
          hireDate: new Date('2022-03-15'),
          contractType: 'full-time',
          workLocation: 'Moscow Office',
          department: 'Customer Support'
        },
        skills: [],
        status: 'active',
        preferences: {
          preferredShifts: ['morning', 'day'],
          notifications: {
            email: true,
            sms: false,
            push: true,
            scheduleChanges: true,
            announcements: true,
            reminders: true
          },
          language: 'ru',
          workingHours: {
            start: '09:00',
            end: '18:00'
          }
        },
        performance: {
          averageHandleTime: 4.2,
          callsPerHour: 12,
          qualityScore: 94.5,
          adherenceScore: 98.2,
          customerSatisfaction: 4.7,
          lastEvaluation: new Date('2024-06-01')
        },
        certifications: [],
        metadata: {
          createdAt: new Date('2022-03-15'),
          updatedAt: new Date(),
          createdBy: 'admin',
          lastModifiedBy: 'admin',
          lastLogin: new Date()
        }
      },
      // Add more mock employees...
      {
        id: 'emp_002',
        employeeId: 'EMP002',
        personalInfo: {
          firstName: 'Mikhail',
          lastName: 'Volkov',
          email: 'mikhail.volkov@company.com',
          phone: '+7 495 123 4568',
          photo: 'https://i.pravatar.cc/150?img=2'
        },
        workInfo: {
          position: 'Junior Operator',
          team: {
            id: 't2',
            name: 'Sales Team',
            color: '#10b981',
            managerId: 'mgr_002',
            memberCount: 8,
            targetUtilization: 0.80
          },
          manager: 'Petrov P.P.',
          hireDate: new Date('2024-01-10'),
          contractType: 'full-time',
          workLocation: 'St. Petersburg Office',
          department: 'Sales'
        },
        skills: [],
        status: 'probation',
        preferences: {
          preferredShifts: ['afternoon', 'evening'],
          notifications: {
            email: true,
            sms: true,
            push: true,
            scheduleChanges: true,
            announcements: false,
            reminders: true
          },
          language: 'ru',
          workingHours: {
            start: '10:00',
            end: '19:00'
          }
        },
        performance: {
          averageHandleTime: 5.8,
          callsPerHour: 9,
          qualityScore: 87.3,
          adherenceScore: 92.1,
          customerSatisfaction: 4.2,
          lastEvaluation: new Date('2024-06-15')
        },
        certifications: [],
        metadata: {
          createdAt: new Date('2024-01-10'),
          updatedAt: new Date(),
          createdBy: 'admin',
          lastModifiedBy: 'admin',
          lastLogin: new Date()
        }
      }
    ];

    // Generate more mock data
    for (let i = 3; i <= 50; i++) {
      const statuses: ('active' | 'inactive' | 'vacation' | 'probation')[] = ['active', 'active', 'active', 'vacation', 'probation'];
      const positions = ['Senior Operator', 'Junior Operator', 'Team Lead', 'Quality Specialist', 'Training Specialist'];
      const teams = [
        { id: 't1', name: 'Support Team', color: '#3b82f6', managerId: 'mgr_001', memberCount: 12, targetUtilization: 0.85 },
        { id: 't2', name: 'Sales Team', color: '#10b981', managerId: 'mgr_002', memberCount: 8, targetUtilization: 0.80 },
        { id: 't3', name: 'Quality Team', color: '#f59e0b', managerId: 'mgr_003', memberCount: 5, targetUtilization: 0.75 }
      ];

      mockEmployees.push({
        id: `emp_${i.toString().padStart(3, '0')}`,
        employeeId: `EMP${i.toString().padStart(3, '0')}`,
        personalInfo: {
          firstName: `Employee${i}`,
          lastName: `LastName${i}`,
          email: `employee${i}@company.com`,
          phone: `+7 495 123 ${(4000 + i).toString()}`,
          photo: `https://i.pravatar.cc/150?img=${(i % 70) + 1}`
        },
        workInfo: {
          position: positions[i % positions.length],
          team: teams[i % teams.length],
          manager: `Manager ${Math.ceil(i / 10)}`,
          hireDate: new Date(2020 + (i % 5), (i % 12), (i % 28) + 1),
          contractType: 'full-time',
          workLocation: i % 2 === 0 ? 'Moscow Office' : 'St. Petersburg Office',
          department: i % 3 === 0 ? 'Support' : i % 3 === 1 ? 'Sales' : 'Quality'
        },
        skills: [],
        status: statuses[i % statuses.length],
        preferences: {
          preferredShifts: ['morning'],
          notifications: {
            email: true,
            sms: false,
            push: true,
            scheduleChanges: true,
            announcements: true,
            reminders: true
          },
          language: 'ru',
          workingHours: {
            start: '09:00',
            end: '18:00'
          }
        },
        performance: {
          averageHandleTime: 3 + Math.random() * 4,
          callsPerHour: 8 + Math.random() * 8,
          qualityScore: 80 + Math.random() * 20,
          adherenceScore: 85 + Math.random() * 15,
          customerSatisfaction: 3.5 + Math.random() * 1.5,
          lastEvaluation: new Date()
        },
        certifications: [],
        metadata: {
          createdAt: new Date(2020 + (i % 5), (i % 12), (i % 28) + 1),
          updatedAt: new Date(),
          createdBy: 'admin',
          lastModifiedBy: 'admin',
          lastLogin: Math.random() > 0.1 ? new Date() : undefined
        }
      });
    }

    setEmployees(mockEmployees);
    setFilteredEmployees(mockEmployees);

    // Calculate stats
    const statsData = mockEmployees.reduce((acc, emp) => {
      acc.total++;
      acc[emp.status]++;
      return acc;
    }, { total: 0, active: 0, vacation: 0, probation: 0, inactive: 0, terminated: 0 });

    setStats(statsData);
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

  // Filter employees
  useEffect(() => {
    let filtered = [...employees];

    if (filters.search) {
      filtered = filtered.filter(emp =>
        emp.personalInfo.firstName.toLowerCase().includes(filters.search.toLowerCase()) ||
        emp.personalInfo.lastName.toLowerCase().includes(filters.search.toLowerCase()) ||
        emp.employeeId.toLowerCase().includes(filters.search.toLowerCase())
      );
    }

    if (filters.team) {
      filtered = filtered.filter(emp => emp.workInfo.team.id === filters.team);
    }

    if (filters.status) {
      filtered = filtered.filter(emp => emp.status === filters.status);
    }

    if (!filters.showInactive) {
      filtered = filtered.filter(emp => emp.status !== 'inactive' && emp.status !== 'terminated');
    }

    // Sort
    filtered.sort((a, b) => {
      let aValue: any, bValue: any;
      
      switch (filters.sortBy) {
        case 'name':
          aValue = `${a.personalInfo.firstName} ${a.personalInfo.lastName}`;
          bValue = `${b.personalInfo.firstName} ${b.personalInfo.lastName}`;
          break;
        case 'position':
          aValue = a.workInfo.position;
          bValue = b.workInfo.position;
          break;
        case 'team':
          aValue = a.workInfo.team.name;
          bValue = b.workInfo.team.name;
          break;
        case 'hireDate':
          aValue = a.workInfo.hireDate;
          bValue = b.workInfo.hireDate;
          break;
        case 'performance':
          aValue = a.performance.qualityScore;
          bValue = b.performance.qualityScore;
          break;
        default:
          aValue = a.personalInfo.firstName;
          bValue = b.personalInfo.firstName;
      }

      if (filters.sortOrder === 'desc') {
        return aValue > bValue ? -1 : 1;
      }
      return aValue < bValue ? -1 : 1;
    });

    setFilteredEmployees(filtered);
  }, [employees, filters]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800';
      case 'vacation':
        return 'bg-blue-100 text-blue-800';
      case 'probation':
        return 'bg-yellow-100 text-yellow-800';
      case 'inactive':
        return 'bg-gray-100 text-gray-800';
      case 'terminated':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getPerformanceColor = (score: number) => {
    if (score >= 90) return 'text-green-600';
    if (score >= 80) return 'text-yellow-600';
    return 'text-red-600';
  };

  const handleSelectEmployee = (employeeId: string) => {
    setSelectedEmployees(prev =>
      prev.includes(employeeId)
        ? prev.filter(id => id !== employeeId)
        : [...prev, employeeId]
    );
  };

  const handleSelectAll = () => {
    setSelectedEmployees(
      selectedEmployees.length === filteredEmployees.length
        ? []
        : filteredEmployees.map(emp => emp.id)
    );
  };

  return (
    <div>
      {/* Header with Stats */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-gray-900">Employee Directory</h2>
          <div className={`flex items-center space-x-2 text-sm ${isUpdating ? 'text-blue-600' : 'text-gray-500'}`}>
            <RefreshCw className={`h-4 w-4 ${isUpdating ? 'animate-spin' : ''}`} />
            <span>Last updated: {lastUpdate.toLocaleTimeString()}</span>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-2 md:grid-cols-6 gap-4 mb-6">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-gray-900">{stats.total}</div>
            <div className="text-sm text-gray-600">Total</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-green-600">{stats.active}</div>
            <div className="text-sm text-gray-600">Active</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-blue-600">{stats.vacation}</div>
            <div className="text-sm text-gray-600">On Vacation</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-yellow-600">{stats.probation}</div>
            <div className="text-sm text-gray-600">Probation</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-gray-600">{stats.inactive}</div>
            <div className="text-sm text-gray-600">Inactive</div>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
            <div className="text-2xl font-bold text-red-600">{stats.terminated}</div>
            <div className="text-sm text-gray-600">Terminated</div>
          </div>
        </div>
      </div>

      {/* Filters and Actions */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center space-x-4">
            <div className="relative">
              <Search className="h-4 w-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Search employees..."
                value={filters.search}
                onChange={(e) => setFilters(prev => ({ ...prev, search: e.target.value }))}
                className="pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <select
              value={filters.status}
              onChange={(e) => setFilters(prev => ({ ...prev, status: e.target.value }))}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Statuses</option>
              <option value="active">Active</option>
              <option value="vacation">On Vacation</option>
              <option value="probation">Probation</option>
              <option value="inactive">Inactive</option>
            </select>

            <select
              value={filters.sortBy}
              onChange={(e) => setFilters(prev => ({ ...prev, sortBy: e.target.value as any }))}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="name">Sort by Name</option>
              <option value="position">Sort by Position</option>
              <option value="team">Sort by Team</option>
              <option value="hireDate">Sort by Hire Date</option>
              <option value="performance">Sort by Performance</option>
            </select>
          </div>

          <div className="flex items-center space-x-2">
            {selectedEmployees.length > 0 && (
              <span className="text-sm text-gray-600">
                {selectedEmployees.length} selected
              </span>
            )}
            <button className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50">
              <Download className="h-4 w-4 mr-2" />
              Export
            </button>
            <button className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50">
              <Upload className="h-4 w-4 mr-2" />
              Import
            </button>
          </div>
        </div>
      </div>

      {/* Employee List */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        {viewMode === 'list' ? (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left">
                    <input
                      type="checkbox"
                      checked={selectedEmployees.length === filteredEmployees.length}
                      onChange={handleSelectAll}
                      className="rounded"
                    />
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Employee
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Position
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Team
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Performance
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Last Login
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredEmployees.map((employee) => (
                  <tr key={employee.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <input
                        type="checkbox"
                        checked={selectedEmployees.includes(employee.id)}
                        onChange={() => handleSelectEmployee(employee.id)}
                        className="rounded"
                      />
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <img
                          className="h-10 w-10 rounded-full"
                          src={employee.personalInfo.photo}
                          alt=""
                        />
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900">
                            {employee.personalInfo.firstName} {employee.personalInfo.lastName}
                          </div>
                          <div className="text-sm text-gray-500">{employee.employeeId}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">{employee.workInfo.position}</div>
                      <div className="text-sm text-gray-500">{employee.workInfo.department}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span 
                        className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                        style={{ backgroundColor: employee.workInfo.team.color + '20', color: employee.workInfo.team.color }}
                      >
                        {employee.workInfo.team.name}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(employee.status)}`}>
                        {employee.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className={`text-sm font-medium ${getPerformanceColor(employee.performance.qualityScore)}`}>
                        {employee.performance.qualityScore.toFixed(1)}%
                      </div>
                      <div className="text-xs text-gray-500">Quality Score</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {employee.metadata.lastLogin ? 
                        employee.metadata.lastLogin.toLocaleDateString() : 
                        'Never'
                      }
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 p-6">
            {filteredEmployees.map((employee) => (
              <div key={employee.id} className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow">
                <div className="flex items-center space-x-3 mb-3">
                  <img
                    className="h-12 w-12 rounded-full"
                    src={employee.personalInfo.photo}
                    alt=""
                  />
                  <div>
                    <h3 className="text-sm font-medium text-gray-900">
                      {employee.personalInfo.firstName} {employee.personalInfo.lastName}
                    </h3>
                    <p className="text-xs text-gray-500">{employee.employeeId}</p>
                  </div>
                </div>
                <div className="space-y-2">
                  <div className="text-sm text-gray-900">{employee.workInfo.position}</div>
                  <span 
                    className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
                    style={{ backgroundColor: employee.workInfo.team.color + '20', color: employee.workInfo.team.color }}
                  >
                    {employee.workInfo.team.name}
                  </span>
                  <div className="flex justify-between items-center">
                    <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(employee.status)}`}>
                      {employee.status}
                    </span>
                    <span className={`text-sm font-medium ${getPerformanceColor(employee.performance.qualityScore)}`}>
                      {employee.performance.qualityScore.toFixed(1)}%
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default EmployeeListContainer;