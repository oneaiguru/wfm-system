import React, { useState } from 'react';
import { DollarSign, TrendingUp, AlertCircle, Check, X, Clock, Server, Users } from 'lucide-react';

interface VendorComparison {
  name: string;
  logo?: string;
  type: 'subscription' | 'license' | 'custom';
  yearlyLicense: number;
  implementationCost: number;
  maintenancePercent: number;
  customizationCost: number;
  totalYear1: number;
  totalYear3: number;
  totalYear5: number;
  pros: string[];
  cons: string[];
  features: {
    forecasting: boolean;
    scheduling: boolean;
    reporting: boolean;
    mobile: boolean;
    api: boolean;
    customization: boolean;
    russianLocalization: boolean;
    support247: boolean;
  };
}

const CostComparison: React.FC = () => {
  const [selectedTimeframe, setSelectedTimeframe] = useState<1 | 3 | 5>(3);
  const [showDetails, setShowDetails] = useState<string | null>(null);

  const vendors: VendorComparison[] = [
    {
      name: 'Our Solution',
      type: 'custom',
      yearlyLicense: 0,
      implementationCost: 2000000,
      maintenancePercent: 15,
      customizationCost: 0,
      totalYear1: 2000000,
      totalYear3: 2600000,
      totalYear5: 3400000,
      pros: [
        'One-time cost, no recurring fees',
        'Full source code ownership',
        'Unlimited customization',
        '100% Russian localization',
        'In-house support capability'
      ],
      cons: [
        'Upfront investment required',
        'Internal team training needed'
      ],
      features: {
        forecasting: true,
        scheduling: true,
        reporting: true,
        mobile: true,
        api: true,
        customization: true,
        russianLocalization: true,
        support247: false
      }
    },
    {
      name: 'Argus WFM CC',
      type: 'license',
      yearlyLicense: 3000000,
      implementationCost: 2000000,
      maintenancePercent: 20,
      customizationCost: 1000000,
      totalYear1: 6000000,
      totalYear3: 12000000,
      totalYear5: 20000000,
      pros: [
        'Established enterprise solution',
        'Comprehensive feature set',
        '24/7 vendor support',
        'Regular updates included'
      ],
      cons: [
        'High annual licensing costs',
        'Vendor lock-in',
        'Limited customization',
        'Additional cost for changes'
      ],
      features: {
        forecasting: true,
        scheduling: true,
        reporting: true,
        mobile: true,
        api: true,
        customization: false,
        russianLocalization: false,
        support247: true
      }
    },
    {
      name: 'Naumen WFM',
      type: 'subscription',
      yearlyLicense: 9100000,
      implementationCost: 1500000,
      maintenancePercent: 0,
      customizationCost: 2000000,
      totalYear1: 12600000,
      totalYear3: 30800000,
      totalYear5: 48000000,
      pros: [
        'Russian vendor',
        'Cloud-based solution',
        'Quick deployment',
        'Integrated with Naumen suite'
      ],
      cons: [
        'Extremely high subscription cost',
        'Limited flexibility',
        'Performance concerns at scale',
        'Customization very expensive'
      ],
      features: {
        forecasting: true,
        scheduling: true,
        reporting: true,
        mobile: false,
        api: true,
        customization: false,
        russianLocalization: true,
        support247: false
      }
    },
    {
      name: 'Goodt WFM',
      type: 'license',
      yearlyLicense: 2000000,
      implementationCost: 1000000,
      maintenancePercent: 18,
      customizationCost: 500000,
      totalYear1: 3500000,
      totalYear3: 7500000,
      totalYear5: 11500000,
      pros: [
        'Good price-performance ratio',
        'Modern interface',
        'Flexible licensing options',
        'Growing feature set'
      ],
      cons: [
        'Less mature platform',
        'Limited Russian presence',
        'Fewer integrations',
        'Support quality varies'
      ],
      features: {
        forecasting: true,
        scheduling: true,
        reporting: true,
        mobile: true,
        api: false,
        customization: false,
        russianLocalization: false,
        support247: false
      }
    }
  ];

  const getVendorTotal = (vendor: VendorComparison, years: number) => {
    if (years === 1) return vendor.totalYear1;
    if (years === 3) return vendor.totalYear3;
    return vendor.totalYear5;
  };

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(value);
  };

  const getSavingsVsVendor = (vendorName: string, years: number) => {
    const vendor = vendors.find(v => v.name === vendorName);
    const ourSolution = vendors.find(v => v.name === 'Our Solution');
    if (!vendor || !ourSolution) return 0;
    
    return getVendorTotal(vendor, years) - getVendorTotal(ourSolution, years);
  };

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Total Cost of Ownership Analysis</h2>
        <p className="mt-2 text-gray-600">
          Comprehensive comparison of WFM solutions in the market
        </p>
      </div>

      {/* Timeframe Selector */}
      <div className="mb-6 flex items-center space-x-4">
        <span className="text-sm font-medium text-gray-700">Compare over:</span>
        <div className="flex space-x-2">
          {[1, 3, 5].map((years) => (
            <button
              key={years}
              onClick={() => setSelectedTimeframe(years as 1 | 3 | 5)}
              className={`px-4 py-2 rounded-md text-sm font-medium ${
                selectedTimeframe === years
                  ? 'bg-blue-600 text-white'
                  : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
              }`}
            >
              {years} Year{years > 1 ? 's' : ''}
            </button>
          ))}
        </div>
      </div>

      {/* Key Savings Alert */}
      <div className="mb-6 bg-gradient-to-r from-green-50 to-blue-50 border border-green-200 rounded-lg p-6">
        <div className="flex items-start">
          <TrendingUp className="h-6 w-6 text-green-600 mt-0.5 mr-3" />
          <div>
            <h3 className="font-semibold text-green-900">
              Total Savings with Our Solution ({selectedTimeframe} Year{selectedTimeframe > 1 ? 's' : ''})
            </h3>
            <div className="mt-2 grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <p className="text-sm text-gray-600">vs Argus WFM</p>
                <p className="text-2xl font-bold text-green-600">
                  {formatCurrency(getSavingsVsVendor('Argus WFM CC', selectedTimeframe))}
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-600">vs Naumen WFM</p>
                <p className="text-2xl font-bold text-green-600">
                  {formatCurrency(getSavingsVsVendor('Naumen WFM', selectedTimeframe))}
                </p>
              </div>
              <div>
                <p className="text-sm text-gray-600">vs Goodt WFM</p>
                <p className="text-2xl font-bold text-green-600">
                  {formatCurrency(getSavingsVsVendor('Goodt WFM', selectedTimeframe))}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Vendor Comparison Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {vendors.map((vendor) => {
          const isOurSolution = vendor.name === 'Our Solution';
          
          return (
            <div
              key={vendor.name}
              className={`bg-white rounded-lg shadow-sm border-2 ${
                isOurSolution ? 'border-blue-500' : 'border-gray-200'
              }`}
            >
              {isOurSolution && (
                <div className="bg-blue-500 text-white px-4 py-2 text-center text-sm font-medium">
                  RECOMMENDED SOLUTION
                </div>
              )}
              
              <div className="p-6">
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h3 className="text-xl font-semibold text-gray-900">{vendor.name}</h3>
                    <p className="text-sm text-gray-600">
                      {vendor.type === 'subscription' ? 'Annual Subscription' : 
                       vendor.type === 'license' ? 'Perpetual License' : 
                       'Custom Development'}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-2xl font-bold text-gray-900">
                      {formatCurrency(getVendorTotal(vendor, selectedTimeframe))}
                    </p>
                    <p className="text-sm text-gray-600">{selectedTimeframe}-year total</p>
                  </div>
                </div>

                {/* Cost Breakdown */}
                <div className="mb-4 p-4 bg-gray-50 rounded-lg">
                  <h4 className="text-sm font-medium text-gray-700 mb-2">Cost Breakdown</h4>
                  <div className="space-y-1 text-sm">
                    <div className="flex justify-between">
                      <span className="text-gray-600">Implementation</span>
                      <span className="font-medium">{formatCurrency(vendor.implementationCost)}</span>
                    </div>
                    {vendor.yearlyLicense > 0 && (
                      <div className="flex justify-between">
                        <span className="text-gray-600">Annual License</span>
                        <span className="font-medium">{formatCurrency(vendor.yearlyLicense)}/yr</span>
                      </div>
                    )}
                    {vendor.maintenancePercent > 0 && (
                      <div className="flex justify-between">
                        <span className="text-gray-600">Maintenance</span>
                        <span className="font-medium">{vendor.maintenancePercent}% annually</span>
                      </div>
                    )}
                    {vendor.customizationCost > 0 && (
                      <div className="flex justify-between">
                        <span className="text-gray-600">Customization</span>
                        <span className="font-medium">{formatCurrency(vendor.customizationCost)}</span>
                      </div>
                    )}
                  </div>
                </div>

                {/* Features */}
                <div className="mb-4">
                  <h4 className="text-sm font-medium text-gray-700 mb-2">Key Features</h4>
                  <div className="grid grid-cols-2 gap-2">
                    {Object.entries(vendor.features).map(([feature, available]) => (
                      <div key={feature} className="flex items-center text-sm">
                        {available ? (
                          <Check className="h-4 w-4 text-green-500 mr-1" />
                        ) : (
                          <X className="h-4 w-4 text-red-500 mr-1" />
                        )}
                        <span className={available ? 'text-gray-700' : 'text-gray-400'}>
                          {feature.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Pros and Cons */}
                <button
                  onClick={() => setShowDetails(showDetails === vendor.name ? null : vendor.name)}
                  className="w-full text-sm text-blue-600 hover:text-blue-800 font-medium"
                >
                  {showDetails === vendor.name ? 'Hide' : 'Show'} pros & cons
                </button>

                {showDetails === vendor.name && (
                  <div className="mt-4 space-y-3">
                    <div>
                      <h5 className="text-sm font-medium text-green-700 mb-1">Advantages</h5>
                      <ul className="space-y-1">
                        {vendor.pros.map((pro, idx) => (
                          <li key={idx} className="text-sm text-gray-600 flex items-start">
                            <span className="text-green-500 mr-1">+</span>
                            {pro}
                          </li>
                        ))}
                      </ul>
                    </div>
                    <div>
                      <h5 className="text-sm font-medium text-red-700 mb-1">Disadvantages</h5>
                      <ul className="space-y-1">
                        {vendor.cons.map((con, idx) => (
                          <li key={idx} className="text-sm text-gray-600 flex items-start">
                            <span className="text-red-500 mr-1">-</span>
                            {con}
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Bottom Summary */}
      <div className="mt-8 bg-gray-100 rounded-lg p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Why Our Solution Wins</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="flex items-start">
            <DollarSign className="h-6 w-6 text-green-600 mr-3 mt-0.5" />
            <div>
              <h4 className="font-medium text-gray-900">Lowest TCO</h4>
              <p className="text-sm text-gray-600 mt-1">
                60-80% lower total cost over 5 years compared to major vendors
              </p>
            </div>
          </div>
          <div className="flex items-start">
            <Server className="h-6 w-6 text-blue-600 mr-3 mt-0.5" />
            <div>
              <h4 className="font-medium text-gray-900">Full Ownership</h4>
              <p className="text-sm text-gray-600 mt-1">
                Complete source code ownership with unlimited customization rights
              </p>
            </div>
          </div>
          <div className="flex items-start">
            <Users className="h-6 w-6 text-purple-600 mr-3 mt-0.5" />
            <div>
              <h4 className="font-medium text-gray-900">Russian Ready</h4>
              <p className="text-sm text-gray-600 mt-1">
                100% localized for Russian market with native language support
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CostComparison;