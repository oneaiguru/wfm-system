import React, { useState, useEffect, useMemo } from 'react';
import { Line, Bar, Doughnut } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
);

interface ROIInputs {
  // Organization Metrics
  numberOfAgents: number;
  averageAgentSalary: number;
  numberOfQueues: number;
  numberOfSkills: number;
  callVolume: number; // per month
  averageHandleTime: number; // minutes
  
  // Current Performance
  currentServiceLevel: number; // percentage
  currentAccuracy: number; // multi-skill allocation accuracy
  currentPlanningTime: number; // hours per week
  currentOvertimePercentage: number;
  currentAttritionRate: number; // percentage annually
  
  // Cost Factors
  implementationCost: number;
  annualLicenseCost: number;
  trainingCost: number;
  
  // Advanced Options
  industryType: 'retail' | 'telecom' | 'banking' | 'insurance' | 'tech' | 'other';
  growthRate: number; // annual percentage
  peakSeasonImpact: number; // percentage increase during peak
}

interface ROIMetrics {
  // Time Savings
  algorithmTimeSavings: number;
  planningTimeSavings: number;
  
  // Accuracy Improvements
  multiSkillAccuracyGain: number;
  serviceLevelImprovement: number;
  
  // Cost Savings
  agentReduction: number;
  overtimeReduction: number;
  attritionSavings: number;
  
  // Revenue Impact
  customerSatisfactionRevenue: number;
  firstCallResolutionRevenue: number;
  
  // Total ROI
  totalAnnualSavings: number;
  totalAnnualCosts: number;
  netAnnualBenefit: number;
  roiPercentage: number;
  paybackMonths: number;
  fiveYearNPV: number;
}

const ROICalculator: React.FC = () => {
  const [inputs, setInputs] = useState<ROIInputs>({
    numberOfAgents: 100,
    averageAgentSalary: 35000,
    numberOfQueues: 20,
    numberOfSkills: 10,
    callVolume: 100000,
    averageHandleTime: 5,
    currentServiceLevel: 75,
    currentAccuracy: 65,
    currentPlanningTime: 40,
    currentOvertimePercentage: 15,
    currentAttritionRate: 25,
    implementationCost: 50000,
    annualLicenseCost: 30000,
    trainingCost: 10000,
    industryType: 'telecom',
    growthRate: 10,
    peakSeasonImpact: 30
  });

  const [showAdvanced, setShowAdvanced] = useState(false);
  const [comparisonMode, setComparisonMode] = useState<'argus' | 'manual' | 'other'>('argus');

  // Calculate ROI metrics based on inputs
  const roiMetrics = useMemo((): ROIMetrics => {
    // Algorithm Time Savings (based on 41x performance improvement)
    const algorithmCalls = inputs.callVolume * 12;
    const timeSavedPerCall = 0.405; // seconds (415ms - 10ms)
    const algorithmTimeSavings = (algorithmCalls * timeSavedPerCall) / 3600 * 50; // $50/hour
    
    // Planning Time Savings (87.5% reduction from specs)
    const planningTimeSavings = inputs.currentPlanningTime * 52 * 0.875 * 50;
    
    // Multi-skill Accuracy Improvements
    const accuracyImprovement = 85 - inputs.currentAccuracy; // Our system achieves 85%+
    const multiSkillAccuracyGain = (accuracyImprovement / 100) * inputs.numberOfAgents * inputs.averageAgentSalary * 0.1;
    
    // Service Level Improvements (15% typical improvement)
    const serviceLevelGain = Math.min(15, 95 - inputs.currentServiceLevel);
    const serviceLevelImprovement = (serviceLevelGain / 100) * inputs.callVolume * 12 * 0.5; // $0.50 per call value
    
    // Agent Reduction (20-30% typical from better optimization)
    const efficiencyGain = inputs.numberOfQueues > 50 ? 0.3 : 0.2;
    const agentReduction = Math.floor(inputs.numberOfAgents * efficiencyGain) * inputs.averageAgentSalary;
    
    // Overtime Reduction (66% reduction from specs)
    const overtimeReduction = inputs.numberOfAgents * inputs.averageAgentSalary * (inputs.currentOvertimePercentage / 100) * 0.66 * 0.5;
    
    // Attrition Savings (26% improvement in satisfaction)
    const attritionReduction = Math.max(0, inputs.currentAttritionRate - 20);
    const attritionSavings = (attritionReduction / 100) * inputs.numberOfAgents * inputs.averageAgentSalary * 0.5;
    
    // Revenue Impact
    const customerSatisfactionRevenue = inputs.callVolume * 12 * 0.02 * serviceLevelGain; // 2% revenue per point
    const firstCallResolutionRevenue = inputs.callVolume * 12 * 0.15 * (accuracyImprovement / 100) * 2; // $2 per resolved call
    
    // Total Calculations
    const totalAnnualSavings = 
      algorithmTimeSavings +
      planningTimeSavings +
      multiSkillAccuracyGain +
      serviceLevelImprovement +
      agentReduction +
      overtimeReduction +
      attritionSavings +
      customerSatisfactionRevenue +
      firstCallResolutionRevenue;
    
    const totalAnnualCosts = inputs.annualLicenseCost;
    const netAnnualBenefit = totalAnnualSavings - totalAnnualCosts;
    const totalInvestment = inputs.implementationCost + inputs.trainingCost;
    const roiPercentage = (netAnnualBenefit / totalInvestment) * 100;
    const paybackMonths = totalInvestment / (netAnnualBenefit / 12);
    
    // 5-year NPV calculation (12% discount rate)
    const discountRate = 0.12;
    let fiveYearNPV = -totalInvestment;
    for (let year = 1; year <= 5; year++) {
      const yearBenefit = netAnnualBenefit * Math.pow(1 + inputs.growthRate / 100, year - 1);
      fiveYearNPV += yearBenefit / Math.pow(1 + discountRate, year);
    }
    
    return {
      algorithmTimeSavings,
      planningTimeSavings,
      multiSkillAccuracyGain,
      serviceLevelImprovement,
      agentReduction,
      overtimeReduction,
      attritionSavings,
      customerSatisfactionRevenue,
      firstCallResolutionRevenue,
      totalAnnualSavings,
      totalAnnualCosts,
      netAnnualBenefit,
      roiPercentage,
      paybackMonths,
      fiveYearNPV
    };
  }, [inputs]);

  // Chart data for savings breakdown
  const savingsBreakdownData = {
    labels: [
      'Agent Reduction',
      'Multi-skill Accuracy',
      'Customer Satisfaction',
      'First Call Resolution',
      'Overtime Reduction',
      'Planning Time',
      'Attrition Savings',
      'Service Level',
      'Algorithm Speed'
    ],
    datasets: [{
      data: [
        roiMetrics.agentReduction,
        roiMetrics.multiSkillAccuracyGain,
        roiMetrics.customerSatisfactionRevenue,
        roiMetrics.firstCallResolutionRevenue,
        roiMetrics.overtimeReduction,
        roiMetrics.planningTimeSavings,
        roiMetrics.attritionSavings,
        roiMetrics.serviceLevelImprovement,
        roiMetrics.algorithmTimeSavings
      ],
      backgroundColor: [
        '#FF6384',
        '#36A2EB',
        '#FFCE56',
        '#4BC0C0',
        '#9966FF',
        '#FF9F40',
        '#FF6384',
        '#C9CBCF',
        '#4BC0C0'
      ]
    }]
  };

  // 5-year projection chart
  const projectionData = {
    labels: ['Year 0', 'Year 1', 'Year 2', 'Year 3', 'Year 4', 'Year 5'],
    datasets: [
      {
        label: 'Cumulative Savings',
        data: [
          -inputs.implementationCost - inputs.trainingCost,
          roiMetrics.netAnnualBenefit,
          roiMetrics.netAnnualBenefit * (2 + inputs.growthRate / 100),
          roiMetrics.netAnnualBenefit * (3 + inputs.growthRate / 100 * 2),
          roiMetrics.netAnnualBenefit * (4 + inputs.growthRate / 100 * 3),
          roiMetrics.netAnnualBenefit * (5 + inputs.growthRate / 100 * 4)
        ],
        borderColor: 'rgb(75, 192, 192)',
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        fill: true
      },
      {
        label: 'Break-even Line',
        data: [0, 0, 0, 0, 0, 0],
        borderColor: 'rgb(255, 99, 132)',
        borderDash: [5, 5]
      }
    ]
  };

  // TCO Comparison
  const tcoComparisonData = {
    labels: ['Implementation', 'Year 1', 'Year 2', 'Year 3', 'Year 4', 'Year 5'],
    datasets: [
      {
        label: 'WFM Enterprise',
        data: [
          inputs.implementationCost + inputs.trainingCost,
          inputs.annualLicenseCost,
          inputs.annualLicenseCost * 1.05,
          inputs.annualLicenseCost * 1.1,
          inputs.annualLicenseCost * 1.15,
          inputs.annualLicenseCost * 1.2
        ],
        backgroundColor: 'rgba(54, 162, 235, 0.8)'
      },
      {
        label: comparisonMode === 'argus' ? 'Argus CCWFM' : 'Current System',
        data: [
          inputs.implementationCost * 1.5,
          inputs.annualLicenseCost * 1.8,
          inputs.annualLicenseCost * 1.9,
          inputs.annualLicenseCost * 2.0,
          inputs.annualLicenseCost * 2.1,
          inputs.annualLicenseCost * 2.2
        ],
        backgroundColor: 'rgba(255, 99, 132, 0.8)'
      }
    ]
  };

  const handleInputChange = (field: keyof ROIInputs, value: any) => {
    setInputs(prev => ({ ...prev, [field]: value }));
  };

  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-600 to-purple-600 text-white p-6 rounded-lg shadow-lg">
        <h2 className="text-3xl font-bold mb-2">ROI Calculator</h2>
        <p className="text-blue-100">
          Calculate your return on investment with WFM Enterprise's advanced optimization capabilities
        </p>
      </div>

      {/* Key Metrics Summary */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-green-50 border border-green-200 rounded-lg p-4">
          <div className="text-green-600 text-sm font-medium">Annual Savings</div>
          <div className="text-2xl font-bold text-green-700">
            ${roiMetrics.totalAnnualSavings.toLocaleString()}
          </div>
        </div>
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div className="text-blue-600 text-sm font-medium">ROI Percentage</div>
          <div className="text-2xl font-bold text-blue-700">
            {roiMetrics.roiPercentage.toFixed(0)}%
          </div>
        </div>
        <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
          <div className="text-purple-600 text-sm font-medium">Payback Period</div>
          <div className="text-2xl font-bold text-purple-700">
            {roiMetrics.paybackMonths.toFixed(1)} months
          </div>
        </div>
        <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
          <div className="text-orange-600 text-sm font-medium">5-Year NPV</div>
          <div className="text-2xl font-bold text-orange-700">
            ${roiMetrics.fiveYearNPV.toLocaleString()}
          </div>
        </div>
      </div>

      {/* Input Section */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-xl font-bold mb-4">Organization Profile</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Number of Agents
            </label>
            <input
              type="number"
              value={inputs.numberOfAgents}
              onChange={(e) => handleInputChange('numberOfAgents', parseInt(e.target.value))}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Average Agent Salary ($)
            </label>
            <input
              type="number"
              value={inputs.averageAgentSalary}
              onChange={(e) => handleInputChange('averageAgentSalary', parseInt(e.target.value))}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Number of Queues
            </label>
            <input
              type="number"
              value={inputs.numberOfQueues}
              onChange={(e) => handleInputChange('numberOfQueues', parseInt(e.target.value))}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Monthly Call Volume
            </label>
            <input
              type="number"
              value={inputs.callVolume}
              onChange={(e) => handleInputChange('callVolume', parseInt(e.target.value))}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Current Service Level (%)
            </label>
            <input
              type="number"
              value={inputs.currentServiceLevel}
              onChange={(e) => handleInputChange('currentServiceLevel', parseInt(e.target.value))}
              min="0"
              max="100"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Current Multi-skill Accuracy (%)
            </label>
            <input
              type="number"
              value={inputs.currentAccuracy}
              onChange={(e) => handleInputChange('currentAccuracy', parseInt(e.target.value))}
              min="0"
              max="100"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        <button
          onClick={() => setShowAdvanced(!showAdvanced)}
          className="mt-4 text-blue-600 hover:text-blue-700 font-medium"
        >
          {showAdvanced ? 'Hide' : 'Show'} Advanced Options
        </button>

        {showAdvanced && (
          <div className="mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Weekly Planning Time (hours)
              </label>
              <input
                type="number"
                value={inputs.currentPlanningTime}
                onChange={(e) => handleInputChange('currentPlanningTime', parseInt(e.target.value))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Current Overtime (%)
              </label>
              <input
                type="number"
                value={inputs.currentOvertimePercentage}
                onChange={(e) => handleInputChange('currentOvertimePercentage', parseInt(e.target.value))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Annual Growth Rate (%)
              </label>
              <input
                type="number"
                value={inputs.growthRate}
                onChange={(e) => handleInputChange('growthRate', parseInt(e.target.value))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>
        )}
      </div>

      {/* Savings Breakdown Chart */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-xl font-bold mb-4">Annual Savings Breakdown</h3>
        <div className="h-80">
          <Doughnut 
            data={savingsBreakdownData}
            options={{
              responsive: true,
              maintainAspectRatio: false,
              plugins: {
                legend: {
                  position: 'right'
                },
                tooltip: {
                  callbacks: {
                    label: function(context) {
                      const label = context.label || '';
                      const value = '$' + context.raw.toLocaleString();
                      return label + ': ' + value;
                    }
                  }
                }
              }
            }}
          />
        </div>
      </div>

      {/* 5-Year Projection */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-xl font-bold mb-4">5-Year Financial Projection</h3>
        <div className="h-80">
          <Line 
            data={projectionData}
            options={{
              responsive: true,
              maintainAspectRatio: false,
              plugins: {
                legend: {
                  display: true
                },
                tooltip: {
                  callbacks: {
                    label: function(context) {
                      return context.dataset.label + ': $' + context.raw.toLocaleString();
                    }
                  }
                }
              },
              scales: {
                y: {
                  beginAtZero: true,
                  ticks: {
                    callback: function(value) {
                      return '$' + value.toLocaleString();
                    }
                  }
                }
              }
            }}
          />
        </div>
      </div>

      {/* TCO Comparison */}
      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-xl font-bold">5-Year TCO Comparison</h3>
          <select
            value={comparisonMode}
            onChange={(e) => setComparisonMode(e.target.value as any)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="argus">vs Argus CCWFM</option>
            <option value="manual">vs Manual Process</option>
            <option value="other">vs Other WFM</option>
          </select>
        </div>
        <div className="h-80">
          <Bar 
            data={tcoComparisonData}
            options={{
              responsive: true,
              maintainAspectRatio: false,
              plugins: {
                legend: {
                  display: true
                },
                tooltip: {
                  callbacks: {
                    label: function(context) {
                      return context.dataset.label + ': $' + context.raw.toLocaleString();
                    }
                  }
                }
              },
              scales: {
                y: {
                  beginAtZero: true,
                  ticks: {
                    callback: function(value) {
                      return '$' + value.toLocaleString();
                    }
                  }
                }
              }
            }}
          />
        </div>
      </div>

      {/* Detailed Metrics */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-xl font-bold mb-4">Detailed ROI Metrics</h3>
        
        <div className="space-y-4">
          <div className="border-b pb-4">
            <h4 className="font-semibold mb-2">Time & Efficiency Savings</h4>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-600">Algorithm Speed (41x faster)</span>
                <span className="font-medium">${roiMetrics.algorithmTimeSavings.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Planning Time (87.5% reduction)</span>
                <span className="font-medium">${roiMetrics.planningTimeSavings.toLocaleString()}</span>
              </div>
            </div>
          </div>

          <div className="border-b pb-4">
            <h4 className="font-semibold mb-2">Accuracy & Quality Improvements</h4>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-600">Multi-skill Optimization (85%+ accuracy)</span>
                <span className="font-medium">${roiMetrics.multiSkillAccuracyGain.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Service Level Improvement</span>
                <span className="font-medium">${roiMetrics.serviceLevelImprovement.toLocaleString()}</span>
              </div>
            </div>
          </div>

          <div className="border-b pb-4">
            <h4 className="font-semibold mb-2">Cost Reductions</h4>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-600">Agent Optimization (20-30% reduction)</span>
                <span className="font-medium">${roiMetrics.agentReduction.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Overtime Reduction (66% less)</span>
                <span className="font-medium">${roiMetrics.overtimeReduction.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Attrition Savings (26% improvement)</span>
                <span className="font-medium">${roiMetrics.attritionSavings.toLocaleString()}</span>
              </div>
            </div>
          </div>

          <div className="pt-4">
            <h4 className="font-semibold mb-2">Revenue Impact</h4>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-600">Customer Satisfaction Revenue</span>
                <span className="font-medium">${roiMetrics.customerSatisfactionRevenue.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">First Call Resolution Improvement</span>
                <span className="font-medium">${roiMetrics.firstCallResolutionRevenue.toLocaleString()}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Call to Action */}
      <div className="bg-gradient-to-r from-green-500 to-blue-600 text-white p-6 rounded-lg shadow-lg">
        <div className="text-center">
          <h3 className="text-2xl font-bold mb-2">Ready to Transform Your Contact Center?</h3>
          <p className="mb-4">
            Based on your inputs, WFM Enterprise can deliver {roiMetrics.roiPercentage.toFixed(0)}% ROI 
            with a payback period of just {roiMetrics.paybackMonths.toFixed(1)} months
          </p>
          <button className="bg-white text-blue-600 px-6 py-3 rounded-lg font-semibold hover:bg-gray-100 transition-colors">
            Schedule a Personalized Demo
          </button>
        </div>
      </div>
    </div>
  );
};

export default ROICalculator;