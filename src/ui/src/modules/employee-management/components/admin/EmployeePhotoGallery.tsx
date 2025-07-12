import React, { useState, useEffect } from 'react';
import { Search, Grid, List, Download, Upload, Eye, Users, Filter } from 'lucide-react';

interface Employee {
  id: string;
  firstName: string;
  lastName: string;
  position: string;
  team: string;
  photo: string;
  status: 'active' | 'inactive' | 'vacation' | 'probation';
  hireDate: Date;
}

const EmployeePhotoGallery: React.FC = () => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [filteredEmployees, setFilteredEmployees] = useState<Employee[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedTeam, setSelectedTeam] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [gridSize, setGridSize] = useState<'small' | 'medium' | 'large'>('medium');

  // Generate mock data
  useEffect(() => {
    const mockEmployees: Employee[] = [];
    const teams = ['Support Team', 'Sales Team', 'Quality Team', 'Training Team'];
    const positions = ['Junior Operator', 'Senior Operator', 'Team Lead', 'Quality Specialist'];
    const statuses: ('active' | 'inactive' | 'vacation' | 'probation')[] = ['active', 'active', 'active', 'vacation', 'probation'];

    for (let i = 1; i <= 60; i++) {
      mockEmployees.push({
        id: `emp_${i.toString().padStart(3, '0')}`,
        firstName: `Employee${i}`,
        lastName: `LastName${i}`,
        position: positions[i % positions.length],
        team: teams[i % teams.length],
        photo: `https://i.pravatar.cc/300?img=${(i % 70) + 1}`,
        status: statuses[i % statuses.length],
        hireDate: new Date(2020 + (i % 5), (i % 12), (i % 28) + 1)
      });
    }

    setEmployees(mockEmployees);
    setFilteredEmployees(mockEmployees);
  }, []);

  // Filter employees
  useEffect(() => {
    let filtered = [...employees];

    if (searchTerm) {
      filtered = filtered.filter(emp =>
        emp.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        emp.lastName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        emp.position.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (selectedTeam) {
      filtered = filtered.filter(emp => emp.team === selectedTeam);
    }

    if (selectedStatus) {
      filtered = filtered.filter(emp => emp.status === selectedStatus);
    }

    setFilteredEmployees(filtered);
  }, [employees, searchTerm, selectedTeam, selectedStatus]);

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
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getGridSizeClass = () => {
    switch (gridSize) {
      case 'small':
        return 'grid-cols-2 md:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8';
      case 'medium':
        return 'grid-cols-1 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6';
      case 'large':
        return 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4';
      default:
        return 'grid-cols-1 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6';
    }
  };

  const getPhotoSizeClass = () => {
    switch (gridSize) {
      case 'small':
        return 'h-16 w-16';
      case 'medium':
        return 'h-24 w-24';
      case 'large':
        return 'h-32 w-32';
      default:
        return 'h-24 w-24';
    }
  };

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Eye className="h-6 w-6 mr-2 text-blue-600" />
          Employee Photo Gallery
        </h2>
        <p className="mt-2 text-gray-600">
          Visual directory of all employees with photos and basic information
        </p>
      </div>

      {/* Filters and Controls */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center space-x-4">
            <div className="relative">
              <Search className="h-4 w-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Search employees..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <select
              value={selectedTeam}
              onChange={(e) => setSelectedTeam(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Teams</option>
              <option value="Support Team">Support Team</option>
              <option value="Sales Team">Sales Team</option>
              <option value="Quality Team">Quality Team</option>
              <option value="Training Team">Training Team</option>
            </select>

            <select
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Statuses</option>
              <option value="active">Active</option>
              <option value="vacation">On Vacation</option>
              <option value="probation">Probation</option>
              <option value="inactive">Inactive</option>
            </select>
          </div>

          <div className="flex items-center space-x-2">
            <span className="text-sm text-gray-600">{filteredEmployees.length} employees</span>
            
            {/* Grid Size Control */}
            <div className="flex rounded-md border border-gray-300">
              <button
                onClick={() => setGridSize('small')}
                className={`px-2 py-1 text-xs ${
                  gridSize === 'small' 
                    ? 'bg-blue-500 text-white' 
                    : 'bg-white text-gray-700 hover:bg-gray-50'
                }`}
              >
                S
              </button>
              <button
                onClick={() => setGridSize('medium')}
                className={`px-2 py-1 text-xs border-l border-gray-300 ${
                  gridSize === 'medium' 
                    ? 'bg-blue-500 text-white' 
                    : 'bg-white text-gray-700 hover:bg-gray-50'
                }`}
              >
                M
              </button>
              <button
                onClick={() => setGridSize('large')}
                className={`px-2 py-1 text-xs border-l border-gray-300 ${
                  gridSize === 'large' 
                    ? 'bg-blue-500 text-white' 
                    : 'bg-white text-gray-700 hover:bg-gray-50'
                }`}
              >
                L
              </button>
            </div>

            {/* View Mode Toggle */}
            <div className="flex rounded-md border border-gray-300">
              <button
                onClick={() => setViewMode('grid')}
                className={`px-3 py-1 text-sm ${
                  viewMode === 'grid' 
                    ? 'bg-blue-500 text-white' 
                    : 'bg-white text-gray-700 hover:bg-gray-50'
                }`}
              >
                <Grid className="h-4 w-4" />
              </button>
              <button
                onClick={() => setViewMode('list')}
                className={`px-3 py-1 text-sm border-l border-gray-300 ${
                  viewMode === 'list' 
                    ? 'bg-blue-500 text-white' 
                    : 'bg-white text-gray-700 hover:bg-gray-50'
                }`}
              >
                <List className="h-4 w-4" />
              </button>
            </div>

            <button className="flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50">
              <Download className="h-4 w-4 mr-2" />
              Export
            </button>
          </div>
        </div>
      </div>

      {/* Employee Gallery */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        {viewMode === 'grid' ? (
          <div className={`grid gap-4 ${getGridSizeClass()}`}>
            {filteredEmployees.map((employee) => (
              <div
                key={employee.id}
                className="group relative bg-white border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer"
              >
                <div className="text-center">
                  <img
                    className={`${getPhotoSizeClass()} rounded-full mx-auto mb-2 object-cover`}
                    src={employee.photo}
                    alt={`${employee.firstName} ${employee.lastName}`}
                  />
                  
                  <h3 className="text-sm font-medium text-gray-900 truncate">
                    {employee.firstName} {employee.lastName}
                  </h3>
                  
                  {gridSize !== 'small' && (
                    <>
                      <p className="text-xs text-gray-600 truncate">{employee.position}</p>
                      <p className="text-xs text-gray-500 truncate">{employee.team}</p>
                      
                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium mt-2 ${getStatusColor(employee.status)}`}>
                        {employee.status}
                      </span>
                    </>
                  )}
                </div>

                {/* Hover overlay */}
                <div className="absolute inset-0 bg-black bg-opacity-75 opacity-0 group-hover:opacity-100 transition-opacity rounded-lg flex items-center justify-center">
                  <div className="text-white text-center">
                    <Eye className="h-8 w-8 mx-auto mb-2" />
                    <p className="text-sm font-medium">View Details</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="space-y-2">
            {filteredEmployees.map((employee) => (
              <div
                key={employee.id}
                className="flex items-center space-x-4 p-3 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer"
              >
                <img
                  className="h-12 w-12 rounded-full object-cover"
                  src={employee.photo}
                  alt={`${employee.firstName} ${employee.lastName}`}
                />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="text-sm font-medium text-gray-900">
                        {employee.firstName} {employee.lastName}
                      </h3>
                      <p className="text-sm text-gray-600">{employee.position}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-gray-600">{employee.team}</p>
                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(employee.status)}`}>
                        {employee.status}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {filteredEmployees.length === 0 && (
          <div className="text-center py-12">
            <Users className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No employees found</h3>
            <p className="text-gray-600">Try adjusting your search criteria.</p>
          </div>
        )}
      </div>

      {/* Photo Upload Section */}
      <div className="mt-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Bulk Photo Upload</h3>
        <div className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center">
          <Upload className="h-8 w-8 text-gray-400 mx-auto mb-4" />
          <p className="text-sm text-gray-600 mb-2">Upload multiple employee photos at once</p>
          <p className="text-xs text-gray-500 mb-4">Name files as: EmployeeID.jpg (e.g., EMP001.jpg)</p>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
            Choose Files
          </button>
        </div>
      </div>
    </div>
  );
};

export default EmployeePhotoGallery;