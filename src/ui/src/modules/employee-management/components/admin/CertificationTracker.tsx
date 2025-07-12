import React, { useState, useEffect } from 'react';
import { Award, Calendar, AlertTriangle, CheckCircle, Clock, FileText } from 'lucide-react';

interface Certification {
  id: string;
  employeeId: string;
  employeeName: string;
  certificationName: string;
  issuer: string;
  issueDate: Date;
  expirationDate?: Date;
  status: 'active' | 'expired' | 'expiring-soon' | 'pending';
  documentUrl?: string;
}

const CertificationTracker: React.FC = () => {
  const [certifications, setCertifications] = useState<Certification[]>([]);
  const [filter, setFilter] = useState<'all' | 'active' | 'expired' | 'expiring-soon'>('all');
  const [searchTerm, setSearchTerm] = useState('');

  // Generate mock data
  useEffect(() => {
    const mockCertifications: Certification[] = [
      {
        id: 'cert_001',
        employeeId: 'EMP001',
        employeeName: 'Anna Petrov',
        certificationName: 'Customer Service Excellence',
        issuer: 'Customer Service Institute',
        issueDate: new Date('2023-06-15'),
        expirationDate: new Date('2025-06-15'),
        status: 'active'
      },
      {
        id: 'cert_002',
        employeeId: 'EMP002',
        employeeName: 'Mikhail Volkov',
        certificationName: 'Quality Assurance Specialist',
        issuer: 'Quality Management Board',
        issueDate: new Date('2023-03-20'),
        expirationDate: new Date('2024-08-20'),
        status: 'expiring-soon'
      },
      {
        id: 'cert_003',
        employeeId: 'EMP003',
        employeeName: 'Elena Kozlov',
        certificationName: 'Sales Professional',
        issuer: 'Sales Excellence Academy',
        issueDate: new Date('2022-11-10'),
        expirationDate: new Date('2024-02-10'),
        status: 'expired'
      },
      {
        id: 'cert_004',
        employeeId: 'EMP004',
        employeeName: 'Pavel Orlov',
        certificationName: 'Technical Support Certified',
        issuer: 'Technical Institute',
        issueDate: new Date('2024-01-15'),
        expirationDate: new Date('2026-01-15'),
        status: 'active'
      },
      {
        id: 'cert_005',
        employeeId: 'EMP005',
        employeeName: 'Sofia Ivanov',
        certificationName: 'Team Leadership',
        issuer: 'Leadership Development Center',
        issueDate: new Date('2024-07-01'),
        status: 'pending'
      },
      {
        id: 'cert_006',
        employeeId: 'EMP001',
        employeeName: 'Anna Petrov',
        certificationName: 'Data Privacy Compliance',
        issuer: 'Privacy Protection Agency',
        issueDate: new Date('2023-12-01'),
        expirationDate: new Date('2024-09-01'),
        status: 'expiring-soon'
      }
    ];

    // Calculate status based on expiration date
    const today = new Date();
    const processedCerts = mockCertifications.map(cert => {
      if (!cert.expirationDate) return cert;
      
      const daysUntilExpiration = Math.ceil((cert.expirationDate.getTime() - today.getTime()) / (1000 * 3600 * 24));
      
      let status: 'active' | 'expired' | 'expiring-soon' | 'pending' = 'active';
      if (daysUntilExpiration < 0) {
        status = 'expired';
      } else if (daysUntilExpiration <= 30) {
        status = 'expiring-soon';
      }
      
      return { ...cert, status };
    });

    setCertifications(processedCerts);
  }, []);

  const filteredCertifications = certifications.filter(cert => {
    const matchesFilter = filter === 'all' || cert.status === filter;
    const matchesSearch = 
      cert.employeeName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      cert.certificationName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      cert.issuer.toLowerCase().includes(searchTerm.toLowerCase());
    
    return matchesFilter && matchesSearch;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800';
      case 'expired':
        return 'bg-red-100 text-red-800';
      case 'expiring-soon':
        return 'bg-yellow-100 text-yellow-800';
      case 'pending':
        return 'bg-blue-100 text-blue-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'expired':
        return <AlertTriangle className="h-4 w-4 text-red-500" />;
      case 'expiring-soon':
        return <Clock className="h-4 w-4 text-yellow-500" />;
      case 'pending':
        return <Clock className="h-4 w-4 text-blue-500" />;
      default:
        return <Award className="h-4 w-4 text-gray-500" />;
    }
  };

  const getDaysUntilExpiration = (expirationDate?: Date) => {
    if (!expirationDate) return null;
    const today = new Date();
    const days = Math.ceil((expirationDate.getTime() - today.getTime()) / (1000 * 3600 * 24));
    return days;
  };

  const stats = {
    total: certifications.length,
    active: certifications.filter(c => c.status === 'active').length,
    expired: certifications.filter(c => c.status === 'expired').length,
    expiringSoon: certifications.filter(c => c.status === 'expiring-soon').length,
    pending: certifications.filter(c => c.status === 'pending').length
  };

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Award className="h-6 w-6 mr-2 text-blue-600" />
          Certification Tracker
        </h2>
        <p className="mt-2 text-gray-600">
          Monitor employee certifications, renewals, and compliance status
        </p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Award className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Total</h3>
              <p className="text-2xl font-bold text-blue-600">{stats.total}</p>
              <p className="text-sm text-gray-600">Certifications</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <CheckCircle className="h-8 w-8 text-green-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Active</h3>
              <p className="text-2xl font-bold text-green-600">{stats.active}</p>
              <p className="text-sm text-gray-600">Valid Certs</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Clock className="h-8 w-8 text-yellow-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Expiring</h3>
              <p className="text-2xl font-bold text-yellow-600">{stats.expiringSoon}</p>
              <p className="text-sm text-gray-600">Next 30 Days</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <AlertTriangle className="h-8 w-8 text-red-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Expired</h3>
              <p className="text-2xl font-bold text-red-600">{stats.expired}</p>
              <p className="text-sm text-gray-600">Need Renewal</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center">
            <Clock className="h-8 w-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-semibold text-gray-900">Pending</h3>
              <p className="text-2xl font-bold text-blue-600">{stats.pending}</p>
              <p className="text-sm text-gray-600">In Progress</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
        <div className="flex items-center space-x-4">
          <div className="relative">
            <input
              type="text"
              placeholder="Search certifications..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-4 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <select
            value={filter}
            onChange={(e) => setFilter(e.target.value as any)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Certifications</option>
            <option value="active">Active</option>
            <option value="expiring-soon">Expiring Soon</option>
            <option value="expired">Expired</option>
            <option value="pending">Pending</option>
          </select>

          <span className="text-sm text-gray-600">
            {filteredCertifications.length} certifications
          </span>
        </div>
      </div>

      {/* Expiring Soon Alert */}
      {stats.expiringSoon > 0 && (
        <div className="mb-6 bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-center">
            <AlertTriangle className="h-5 w-5 text-yellow-600 mr-3" />
            <div>
              <h3 className="font-semibold text-yellow-900">Certifications Expiring Soon</h3>
              <p className="text-yellow-800 text-sm">
                {stats.expiringSoon} certification{stats.expiringSoon > 1 ? 's' : ''} will expire in the next 30 days. 
                Review and schedule renewals.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Certifications Table */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Certifications</h3>
        </div>
        
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Employee
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Certification
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Issuer
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Issue Date
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Expiration
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredCertifications.map((cert) => {
                const daysUntilExpiration = getDaysUntilExpiration(cert.expirationDate);
                
                return (
                  <tr key={cert.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm font-medium text-gray-900">{cert.employeeName}</div>
                        <div className="text-sm text-gray-500">{cert.employeeId}</div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-sm text-gray-900">{cert.certificationName}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {cert.issuer}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {cert.issueDate.toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {cert.expirationDate ? (
                        <div>
                          <div className="text-sm text-gray-900">{cert.expirationDate.toLocaleDateString()}</div>
                          {daysUntilExpiration !== null && (
                            <div className={`text-xs ${
                              daysUntilExpiration < 0 ? 'text-red-600' :
                              daysUntilExpiration <= 30 ? 'text-yellow-600' :
                              'text-gray-500'
                            }`}>
                              {daysUntilExpiration < 0 
                                ? `Expired ${Math.abs(daysUntilExpiration)} days ago`
                                : daysUntilExpiration === 0
                                ? 'Expires today'
                                : `${daysUntilExpiration} days remaining`
                              }
                            </div>
                          )}
                        </div>
                      ) : (
                        <span className="text-sm text-gray-500">No expiration</span>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        {getStatusIcon(cert.status)}
                        <span className={`ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(cert.status)}`}>
                          {cert.status === 'expiring-soon' ? 'Expiring Soon' : 
                           cert.status.charAt(0).toUpperCase() + cert.status.slice(1)}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm">
                      <div className="flex space-x-2">
                        <button className="text-blue-600 hover:text-blue-900">
                          <FileText className="h-4 w-4" />
                        </button>
                        <button className="text-green-600 hover:text-green-900">
                          <Calendar className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {filteredCertifications.length === 0 && (
          <div className="text-center py-12">
            <Award className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No certifications found</h3>
            <p className="text-gray-600">Try adjusting your search criteria.</p>
          </div>
        )}
      </div>

      {/* Quick Actions */}
      <div className="mt-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Add Certification</h4>
            <p className="text-sm text-gray-600 mt-1">Record new employee certification</p>
          </button>
          
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Bulk Import</h4>
            <p className="text-sm text-gray-600 mt-1">Upload multiple certifications</p>
          </button>
          
          <button className="p-4 border border-gray-300 rounded-lg hover:bg-gray-50 text-left">
            <h4 className="font-medium text-gray-900">Renewal Reminders</h4>
            <p className="text-sm text-gray-600 mt-1">Set up automated notifications</p>
          </button>
        </div>
      </div>
    </div>
  );
};

export default CertificationTracker;