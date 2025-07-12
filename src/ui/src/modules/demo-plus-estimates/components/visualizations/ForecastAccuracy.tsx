import React, { useEffect, useState } from 'react';
import { Target, TrendingUp, AlertCircle, CheckCircle, Eye, Brain } from 'lucide-react';

interface AccuracyMetric {
  system: string;
  accuracy: number;
  description: string;
  color: string;
  status: 'excellent' | 'good' | 'warning' | 'poor';
  features: string[];
}

interface ForecastScenario {
  id: string;
  scenario: string;
  manual: number;
  legacy: number;
  ourSystem: number;
  difficulty: 'Easy' | 'Medium' | 'Hard' | 'Expert';
}

const ForecastAccuracy: React.FC = () => {
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [isUpdating, setIsUpdating] = useState(false);
  const [selectedScenario, setSelectedScenario] = useState<string>('all');

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

  const accuracyComparison: AccuracyMetric[] = [
    {
      system: 'Our WFM Enterprise',
      accuracy: 85,
      description: 'ML-powered multi-skill optimization with real-time adjustments',
      color: 'from-green-500 to-green-600',
      status: 'excellent',
      features: [
        'Machine learning algorithms',
        'Multi-skill optimization',
        'Real-time pattern recognition',
        'Historical trend analysis',
        'Seasonal adjustment engine',
        'External factor integration'
      ]
    },
    {
      system: 'Argus WFM Legacy',
      accuracy: 68,
      description: 'Traditional rule-based forecasting with limited multi-skill support',
      color: 'from-yellow-500 to-orange-500',
      status: 'warning',
      features: [
        'Basic statistical models',
        'Limited skill consideration',
        'Manual adjustments required',
        'Weekly planning cycles',
        'Static rule sets'
      ]
    },
    {
      system: 'Manual Planning',
      accuracy: 60,
      description: 'Spreadsheet-based planning with human intuition and historical data',
      color: 'from-red-500 to-red-600',
      status: 'poor',
      features: [
        'Excel-based calculations',
        'Historical averages',
        'Manual pattern recognition',
        'Experience-based adjustments',
        'Time-consuming process'
      ]
    },
    {
      system: 'Naumen WFM',
      accuracy: 72,
      description: 'Cloud-based system with basic forecasting capabilities',
      color: 'from-blue-500 to-blue-600',
      status: 'good',
      features: [
        'Cloud-based processing',
        'Basic ML models',
        'Limited customization',
        'Standard algorithms',
        'Subscription-based'
      ]
    }
  ];

  const forecastScenarios: ForecastScenario[] = [
    {
      id: 'basic',
      scenario: 'Single Queue, Steady Volume',
      manual: 85,
      legacy: 80,
      ourSystem: 95,
      difficulty: 'Easy'
    },
    {
      id: 'multi-skill',
      scenario: 'Multi-skill Routing (5+ skills)',
      manual: 55,
      legacy: 65,
      ourSystem: 88,
      difficulty: 'Medium'
    },
    {
      id: 'peak-season',
      scenario: 'Holiday Peak with 300% Volume',
      manual: 45,
      legacy: 58,
      ourSystem: 82,
      difficulty: 'Hard'
    },
    {
      id: 'complex',
      scenario: 'Multi-site, 20+ Skills, Variable Demand',
      manual: 35,
      legacy: 52,
      ourSystem: 78,
      difficulty: 'Expert'
    }
  ];

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'excellent':
        return <CheckCircle className="h-5 w-5 text-green-600" />;
      case 'good':
        return <Eye className="h-5 w-5 text-blue-600" />;
      case 'warning':
        return <AlertCircle className="h-5 w-5 text-yellow-600" />;
      case 'poor':
        return <AlertCircle className="h-5 w-5 text-red-600" />;
      default:
        return null;
    }
  };

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'Easy':
        return 'bg-green-100 text-green-800';
      case 'Medium':
        return 'bg-yellow-100 text-yellow-800';
      case 'Hard':
        return 'bg-orange-100 text-orange-800';
      case 'Expert':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const filteredScenarios = selectedScenario === 'all' 
    ? forecastScenarios 
    : forecastScenarios.filter(s => s.difficulty === selectedScenario);

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Forecast Accuracy Analysis</h2>
        <div className="mt-2 flex items-center space-x-4">
          <p className="text-gray-600">
            Comparative analysis of forecasting accuracy across different systems and scenarios
          </p>
          <div className={`flex items-center space-x-2 text-sm ${isUpdating ? 'text-blue-600' : 'text-gray-500'}`}>
            <div className={`h-2 w-2 rounded-full ${isUpdating ? 'bg-blue-600 animate-pulse' : 'bg-gray-400'}`} />
            <span>Last updated: {lastUpdate.toLocaleTimeString()}</span>
          </div>
        </div>
      </div>

      {/* Accuracy Overview */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {accuracyComparison.map((system) => (
          <div 
            key={system.system}
            className="bg-white rounded-lg shadow-sm border border-gray-200"
          >
            <div className={`bg-gradient-to-r ${system.color} text-white p-4 rounded-t-lg`}>
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-semibold text-sm">{system.system}</h3>
                  <p className="text-2xl font-bold">{system.accuracy}%</p>
                </div>
                {getStatusIcon(system.status)}
              </div>
            </div>
            
            <div className="p-4">
              <p className="text-sm text-gray-600 mb-3">{system.description}</p>
              
              <div className="space-y-1">
                {system.features.slice(0, 3).map((feature, idx) => (
                  <div key={idx} className="flex items-center text-xs text-gray-500">
                    <span className="w-1 h-1 bg-gray-400 rounded-full mr-2" />
                    {feature}
                  </div>
                ))}
                {system.features.length > 3 && (
                  <p className="text-xs text-gray-400">+{system.features.length - 3} more features</p>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Competitive Advantage Alert */}
      <div className="mb-8 bg-gradient-to-r from-green-50 to-blue-50 border border-green-200 rounded-lg p-6">
        <div className="flex items-start">
          <Target className="h-6 w-6 text-green-600 mt-0.5 mr-3" />
          <div>
            <h3 className="font-semibold text-green-900">Accuracy Advantage Summary</h3>
            <div className="mt-2 grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <p className="text-sm text-gray-600">vs Manual Planning</p>
                <p className="text-2xl font-bold text-green-600">+25%</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">vs Argus Legacy</p>
                <p className="text-2xl font-bold text-green-600">+17%</p>
              </div>
              <div>
                <p className="text-sm text-gray-600">vs Naumen WFM</p>
                <p className="text-2xl font-bold text-green-600">+13%</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Scenario Analysis */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-8">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-gray-900">Accuracy by Complexity Scenario</h3>
          <select
            value={selectedScenario}
            onChange={(e) => setSelectedScenario(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Scenarios</option>
            <option value="Easy">Easy Scenarios</option>
            <option value="Medium">Medium Scenarios</option>
            <option value="Hard">Hard Scenarios</option>
            <option value="Expert">Expert Scenarios</option>
          </select>
        </div>

        <div className="space-y-4">
          {filteredScenarios.map((scenario) => (
            <div key={scenario.id} className="border border-gray-200 rounded-lg p-4">
              <div className="flex items-center justify-between mb-3">
                <div>
                  <h4 className="font-medium text-gray-900">{scenario.scenario}</h4>
                  <span className={`inline-block px-2 py-1 rounded-full text-xs font-medium ${getDifficultyColor(scenario.difficulty)}`}>
                    {scenario.difficulty}
                  </span>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div className="text-center">
                  <p className="text-sm text-gray-600">Manual</p>
                  <p className="text-xl font-bold text-red-600">{scenario.manual}%</p>
                  <div className="w-full bg-gray-200 rounded-full h-2 mt-1">
                    <div className="bg-red-500 h-2 rounded-full" style={{ width: `${scenario.manual}%` }} />
                  </div>
                </div>
                
                <div className="text-center">
                  <p className="text-sm text-gray-600">Legacy WFM</p>
                  <p className="text-xl font-bold text-yellow-600">{scenario.legacy}%</p>
                  <div className="w-full bg-gray-200 rounded-full h-2 mt-1">
                    <div className="bg-yellow-500 h-2 rounded-full" style={{ width: `${scenario.legacy}%` }} />
                  </div>
                </div>
                
                <div className="text-center">
                  <p className="text-sm text-gray-600">Our System</p>
                  <p className="text-xl font-bold text-green-600">{scenario.ourSystem}%</p>
                  <div className="w-full bg-gray-200 rounded-full h-2 mt-1">
                    <div className="bg-green-500 h-2 rounded-full" style={{ width: `${scenario.ourSystem}%` }} />
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Technical Deep Dive */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <Brain className="h-5 w-5 mr-2 text-purple-600" />
          Advanced Forecasting Capabilities
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h4 className="font-medium text-gray-900 mb-3">Machine Learning Features</h4>
            <ul className="space-y-2 text-sm">
              <li className="flex items-start">
                <CheckCircle className="h-4 w-4 text-green-500 mt-0.5 mr-2" />
                <span className="text-gray-600">Multi-dimensional skill mapping with real-time optimization</span>
              </li>
              <li className="flex items-start">
                <CheckCircle className="h-4 w-4 text-green-500 mt-0.5 mr-2" />
                <span className="text-gray-600">Pattern recognition across seasonal, weekly, and daily cycles</span>
              </li>
              <li className="flex items-start">
                <CheckCircle className="h-4 w-4 text-green-500 mt-0.5 mr-2" />
                <span className="text-gray-600">External factor integration (holidays, events, weather)</span>
              </li>
              <li className="flex items-start">
                <CheckCircle className="h-4 w-4 text-green-500 mt-0.5 mr-2" />
                <span className="text-gray-600">Continuous learning from actual vs predicted volumes</span>
              </li>
            </ul>
          </div>
          
          <div>
            <h4 className="font-medium text-gray-900 mb-3">Business Impact</h4>
            <ul className="space-y-2 text-sm">
              <li className="flex items-start">
                <TrendingUp className="h-4 w-4 text-blue-500 mt-0.5 mr-2" />
                <span className="text-gray-600">20-30% reduction in required agents for same service level</span>
              </li>
              <li className="flex items-start">
                <TrendingUp className="h-4 w-4 text-blue-500 mt-0.5 mr-2" />
                <span className="text-gray-600">66% reduction in emergency overtime requirements</span>
              </li>
              <li className="flex items-start">
                <TrendingUp className="h-4 w-4 text-blue-500 mt-0.5 mr-2" />
                <span className="text-gray-600">15% improvement in customer satisfaction scores</span>
              </li>
              <li className="flex items-start">
                <TrendingUp className="h-4 w-4 text-blue-500 mt-0.5 mr-2" />
                <span className="text-gray-600">Real-time adjustments prevent service level drops</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ForecastAccuracy;