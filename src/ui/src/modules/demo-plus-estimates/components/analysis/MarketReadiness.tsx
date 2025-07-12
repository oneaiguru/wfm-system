import React, { useEffect, useState } from 'react';
import { Award, Globe, Shield, FileText, Users, Clock, CheckCircle, AlertTriangle } from 'lucide-react';

interface ReadinessCategory {
  id: string;
  title: string;
  completion: number;
  status: 'excellent' | 'good' | 'warning';
  icon: any;
  features: {
    name: string;
    completed: boolean;
    description: string;
  }[];
}

interface CompetitorReadiness {
  vendor: string;
  localization: number;
  compliance: number;
  support: number;
  overall: number;
  gaps: string[];
}

const MarketReadiness: React.FC = () => {
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);

  // Real-time update simulation
  useEffect(() => {
    const interval = setInterval(() => {
      setIsUpdating(true);
      setTimeout(() => {
        setLastUpdate(new Date());
        setIsUpdating(false);
      }, 500);
    }, 30000); // 30-second updates

    return () => clearInterval(interval);
  }, []);

  const readinessCategories: ReadinessCategory[] = [
    {
      id: 'localization',
      title: 'Russian Localization',
      completion: 100,
      status: 'excellent',
      icon: Globe,
      features: [
        { name: 'Native Russian UI/UX', completed: true, description: 'Complete interface in Russian with proper grammar and terminology' },
        { name: 'Cyrillic Character Support', completed: true, description: 'Full support for Cyrillic text input, search, and display' },
        { name: 'Russian Date/Time Formats', completed: true, description: 'DD.MM.YYYY format, Russian month names, proper time zones' },
        { name: 'Number/Currency Formatting', completed: true, description: 'Ruble symbol, Russian number separators, proper decimal notation' },
        { name: 'Regional Settings', completed: true, description: 'Moscow timezone, Russian holidays, work week configuration' },
        { name: 'Documentation in Russian', completed: true, description: 'User manuals, help system, and training materials in Russian' }
      ]
    },
    {
      id: 'compliance',
      title: 'Legal Compliance',
      completion: 95,
      status: 'excellent',
      icon: Shield,
      features: [
        { name: 'Labor Code Compliance', completed: true, description: 'Adherence to Russian Federation Labor Code requirements' },
        { name: 'Working Time Regulations', completed: true, description: 'Proper handling of overtime, breaks, and maximum working hours' },
        { name: 'Data Protection (152-FZ)', completed: true, description: 'Compliance with Federal Law 152-FZ on Personal Data' },
        { name: 'Holiday Calendar Integration', completed: true, description: 'Russian federal and regional holidays built-in' },
        { name: 'Shift Pattern Compliance', completed: true, description: 'Legal shift patterns for 24/7 operations' },
        { name: 'Reporting Standards', completed: false, description: 'Government reporting formats and requirements' }
      ]
    },
    {
      id: 'integration',
      title: '1C Integration Readiness',
      completion: 90,
      status: 'good',
      icon: FileText,
      features: [
        { name: '1C:ZUP Integration', completed: true, description: 'Direct integration with 1C:Salary and Personnel Management' },
        { name: 'Employee Data Sync', completed: true, description: 'Automatic synchronization of employee records and positions' },
        { name: 'Payroll Integration', completed: true, description: 'Export work hours and overtime for payroll processing' },
        { name: 'Organizational Structure', completed: true, description: 'Import departments, positions, and reporting hierarchies' },
        { name: 'Time Tracking Export', completed: true, description: 'Export attendance data in 1C-compatible formats' },
        { name: 'Real-time API', completed: false, description: 'Live bidirectional data synchronization with 1C systems' }
      ]
    },
    {
      id: 'support',
      title: 'Local Support Infrastructure',
      completion: 85,
      status: 'good',
      icon: Users,
      features: [
        { name: 'Russian-speaking Support', completed: true, description: 'Native Russian support team available during business hours' },
        { name: 'Moscow Timezone Coverage', completed: true, description: 'Support available 9 AM - 6 PM Moscow time' },
        { name: 'On-site Implementation', completed: true, description: 'Local implementation specialists available for deployment' },
        { name: 'Training Programs', completed: true, description: 'Comprehensive training in Russian for administrators and users' },
        { name: 'Local Partner Network', completed: false, description: 'Certified implementation partners across Russian regions' },
        { name: '24/7 Emergency Support', completed: false, description: 'Round-the-clock critical issue support' }
      ]
    }
  ];

  const competitorComparison: CompetitorReadiness[] = [
    {
      vendor: 'Our WFM Enterprise',
      localization: 100,
      compliance: 95,
      support: 85,
      overall: 93,
      gaps: []
    },
    {
      vendor: 'Argus WFM',
      localization: 70,
      compliance: 80,
      support: 60,
      overall: 70,
      gaps: ['Limited Russian UI', 'No 1C integration', 'Foreign support only']
    },
    {
      vendor: 'Naumen WFM',
      localization: 95,
      compliance: 85,
      support: 70,
      overall: 83,
      gaps: ['High subscription cost', 'Limited customization', 'Cloud-only deployment']
    },
    {
      vendor: 'International Vendors',
      localization: 40,
      compliance: 50,
      support: 30,
      overall: 40,
      gaps: ['English-only interface', 'No legal compliance', 'No local support', 'No 1C integration']
    }
  ];

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'excellent':
        return 'text-green-600 bg-green-100';
      case 'good':
        return 'text-blue-600 bg-blue-100';
      case 'warning':
        return 'text-yellow-600 bg-yellow-100';
      default:
        return 'text-gray-600 bg-gray-100';
    }
  };

  const getOverallColor = (score: number) => {
    if (score >= 90) return 'from-green-500 to-green-600';
    if (score >= 75) return 'from-blue-500 to-blue-600';
    if (score >= 60) return 'from-yellow-500 to-orange-500';
    return 'from-red-500 to-red-600';
  };

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Russian Market Readiness Analysis</h2>
        <div className="mt-2 flex items-center space-x-4">
          <p className="text-gray-600">
            Comprehensive assessment of localization, compliance, and market-specific capabilities
          </p>
          <div className={`flex items-center space-x-2 text-sm ${isUpdating ? 'text-blue-600' : 'text-gray-500'}`}>
            <div className={`h-2 w-2 rounded-full ${isUpdating ? 'bg-blue-600 animate-pulse' : 'bg-gray-400'}`} />
            <span>Last updated: {lastUpdate.toLocaleTimeString()}</span>
          </div>
        </div>
      </div>

      {/* Overall Readiness Score */}
      <div className="mb-8 bg-gradient-to-r from-green-500 to-blue-600 rounded-lg p-6 text-white">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-2xl font-bold">Overall Russian Market Readiness</h3>
            <p className="text-blue-100 mt-2">Complete solution ready for immediate deployment in Russian market</p>
          </div>
          <div className="text-right">
            <div className="text-4xl font-bold">93%</div>
            <div className="text-blue-100">Market Ready</div>
          </div>
        </div>
      </div>

      {/* Readiness Categories */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        {readinessCategories.map((category) => {
          const Icon = category.icon;
          const completedFeatures = category.features.filter(f => f.completed).length;
          
          return (
            <div 
              key={category.id}
              className="bg-white rounded-lg shadow-sm border border-gray-200"
            >
              <div className="p-6">
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center">
                    <div className={`p-2 rounded-lg ${getStatusColor(category.status)}`}>
                      <Icon className="h-6 w-6" />
                    </div>
                    <div className="ml-3">
                      <h3 className="text-lg font-semibold text-gray-900">{category.title}</h3>
                      <p className="text-sm text-gray-600">
                        {completedFeatures}/{category.features.length} features complete
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-2xl font-bold text-gray-900">{category.completion}%</div>
                  </div>
                </div>

                {/* Progress Bar */}
                <div className="w-full bg-gray-200 rounded-full h-2 mb-4">
                  <div 
                    className={`bg-gradient-to-r ${getOverallColor(category.completion)} h-2 rounded-full transition-all duration-1000`}
                    style={{ width: `${category.completion}%` }}
                  />
                </div>

                {/* Features List */}
                <div className="space-y-2">
                  {category.features.map((feature, idx) => (
                    <div key={idx} className="flex items-start">
                      {feature.completed ? (
                        <CheckCircle className="h-4 w-4 text-green-500 mt-0.5 mr-2" />
                      ) : (
                        <Clock className="h-4 w-4 text-yellow-500 mt-0.5 mr-2" />
                      )}
                      <div>
                        <p className={`text-sm font-medium ${feature.completed ? 'text-gray-900' : 'text-gray-600'}`}>
                          {feature.name}
                        </p>
                        <p className="text-xs text-gray-500">{feature.description}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Competitive Comparison */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-8">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Market Readiness Comparison</h3>
        
        <div className="space-y-4">
          {competitorComparison.map((competitor) => (
            <div key={competitor.vendor} className="border border-gray-200 rounded-lg p-4">
              <div className="flex items-center justify-between mb-3">
                <h4 className="font-medium text-gray-900">{competitor.vendor}</h4>
                <div className="flex items-center">
                  <span className="text-lg font-bold text-gray-900 mr-2">{competitor.overall}%</span>
                  {competitor.vendor === 'Our WFM Enterprise' && (
                    <Award className="h-5 w-5 text-yellow-500" />
                  )}
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4 mb-3">
                <div className="text-center">
                  <p className="text-xs text-gray-600">Localization</p>
                  <p className="text-lg font-semibold">{competitor.localization}%</p>
                  <div className="w-full bg-gray-200 rounded-full h-1 mt-1">
                    <div 
                      className={`bg-gradient-to-r ${getOverallColor(competitor.localization)} h-1 rounded-full`}
                      style={{ width: `${competitor.localization}%` }}
                    />
                  </div>
                </div>
                
                <div className="text-center">
                  <p className="text-xs text-gray-600">Compliance</p>
                  <p className="text-lg font-semibold">{competitor.compliance}%</p>
                  <div className="w-full bg-gray-200 rounded-full h-1 mt-1">
                    <div 
                      className={`bg-gradient-to-r ${getOverallColor(competitor.compliance)} h-1 rounded-full`}
                      style={{ width: `${competitor.compliance}%` }}
                    />
                  </div>
                </div>
                
                <div className="text-center">
                  <p className="text-xs text-gray-600">Support</p>
                  <p className="text-lg font-semibold">{competitor.support}%</p>
                  <div className="w-full bg-gray-200 rounded-full h-1 mt-1">
                    <div 
                      className={`bg-gradient-to-r ${getOverallColor(competitor.support)} h-1 rounded-full`}
                      style={{ width: `${competitor.support}%` }}
                    />
                  </div>
                </div>
              </div>

              {competitor.gaps.length > 0 && (
                <div className="pt-2 border-t border-gray-100">
                  <p className="text-xs text-gray-600 mb-1">Key Gaps:</p>
                  <div className="flex flex-wrap gap-1">
                    {competitor.gaps.map((gap, idx) => (
                      <span 
                        key={idx}
                        className="inline-block px-2 py-1 bg-red-100 text-red-700 text-xs rounded"
                      >
                        {gap}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Market Advantages */}
      <div className="bg-gradient-to-r from-gray-50 to-blue-50 rounded-lg p-6">
        <h3 className="text-xl font-semibold text-gray-900 mb-4 flex items-center">
          <Award className="h-6 w-6 mr-2 text-blue-600" />
          Competitive Market Advantages
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h4 className="font-medium text-gray-900 mb-3">Unique Strengths</h4>
            <ul className="space-y-2 text-sm">
              <li className="flex items-start">
                <CheckCircle className="h-4 w-4 text-green-500 mt-0.5 mr-2" />
                <span className="text-gray-600">100% Russian localization with native language support</span>
              </li>
              <li className="flex items-start">
                <CheckCircle className="h-4 w-4 text-green-500 mt-0.5 mr-2" />
                <span className="text-gray-600">Built-in compliance with Russian labor legislation</span>
              </li>
              <li className="flex items-start">
                <CheckCircle className="h-4 w-4 text-green-500 mt-0.5 mr-2" />
                <span className="text-gray-600">Native 1C:ZUP integration for seamless payroll</span>
              </li>
              <li className="flex items-start">
                <CheckCircle className="h-4 w-4 text-green-500 mt-0.5 mr-2" />
                <span className="text-gray-600">Local development team and support infrastructure</span>
              </li>
            </ul>
          </div>
          
          <div>
            <h4 className="font-medium text-gray-900 mb-3">Market Position</h4>
            <ul className="space-y-2 text-sm">
              <li className="flex items-start">
                <AlertTriangle className="h-4 w-4 text-blue-500 mt-0.5 mr-2" />
                <span className="text-gray-600">Only solution combining enterprise features with full Russian compliance</span>
              </li>
              <li className="flex items-start">
                <AlertTriangle className="h-4 w-4 text-blue-500 mt-0.5 mr-2" />
                <span className="text-gray-600">Significant cost advantage over international vendors</span>
              </li>
              <li className="flex items-start">
                <AlertTriangle className="h-4 w-4 text-blue-500 mt-0.5 mr-2" />
                <span className="text-gray-600">Superior technical capabilities compared to domestic alternatives</span>
              </li>
              <li className="flex items-start">
                <AlertTriangle className="h-4 w-4 text-blue-500 mt-0.5 mr-2" />
                <span className="text-gray-600">Ready for immediate deployment without localization delays</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MarketReadiness;