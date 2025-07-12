import React, { useState, useEffect } from 'react';
import { Play, X, ChevronRight, Sparkles, Zap, TrendingUp } from 'lucide-react';
import { useDemoStore } from '../../hooks/useDemoMode';
import GuidedTour from './GuidedTour';
import ComparisonView from './ComparisonView';

interface DemoScenario {
  id: string;
  name: string;
  description: string;
  duration: string;
  highlights: string[];
  icon: React.ElementType;
  steps: DemoStep[];
}

interface DemoStep {
  action: string;
  target: string;
  data?: any;
  highlight?: string;
  comparison?: {
    argus: string;
    ours: string;
  };
}

const demoScenarios: DemoScenario[] = [
  {
    id: 'multi-skill-victory',
    name: 'Multi-Skill Excellence',
    description: 'Watch us achieve 85%+ accuracy where Argus only gets 60-70%',
    duration: '3 min',
    highlights: ['85%+ accuracy', '68 queues', 'ML optimization'],
    icon: Sparkles,
    steps: [
      {
        action: 'navigate',
        target: 'multiskill',
        highlight: 'Opening our revolutionary multi-skill planning interface'
      },
      {
        action: 'load-data',
        target: 'project-i',
        data: { queues: 68, employees: 150 },
        highlight: 'Loading Project И: 68 queues, 150 employees'
      },
      {
        action: 'show-comparison',
        comparison: {
          argus: '65% accuracy, manual allocation',
          ours: '85%+ accuracy, ML-optimized'
        }
      },
      {
        action: 'run-optimization',
        target: 'ml-optimizer',
        highlight: 'Watch our ML algorithm optimize in real-time'
      },
      {
        action: 'show-results',
        highlight: '85.3% accuracy achieved! 20% better than Argus!'
      }
    ]
  },
  {
    id: 'growth-factor-demo',
    name: 'Explosive Growth Handling',
    description: 'Scale from 1,000 to 5,000 calls with one click',
    duration: '2 min',
    highlights: ['5x growth', 'Real-time preview', 'Pattern selection'],
    icon: TrendingUp,
    steps: [
      {
        action: 'navigate',
        target: 'forecast',
        highlight: 'Opening forecast tab'
      },
      {
        action: 'open-gear',
        target: 'gear-menu',
        highlight: 'Accessing advanced features'
      },
      {
        action: 'click',
        target: 'growth-factor',
        highlight: 'Opening Growth Factor - exclusive to WFM Enterprise'
      },
      {
        action: 'set-growth',
        data: { from: 1000, to: 5000, pattern: 'exponential' },
        highlight: 'Setting 5x growth with exponential pattern'
      },
      {
        action: 'show-preview',
        highlight: 'Real-time preview shows impact instantly'
      },
      {
        action: 'apply',
        highlight: 'Applied! Forecast updated in milliseconds'
      }
    ]
  },
  {
    id: 'speed-showcase',
    name: '41x Speed Demonstration',
    description: 'See calculations that take Argus seconds complete in milliseconds',
    duration: '1 min',
    highlights: ['<10ms calculations', '41x faster', 'Real-time updates'],
    icon: Zap,
    steps: [
      {
        action: 'navigate',
        target: 'calculation',
        highlight: 'Opening calculation tab'
      },
      {
        action: 'set-parameters',
        data: { volume: 10000, aht: 180, sl: 80, shrinkage: 30 },
        highlight: 'Setting complex calculation parameters'
      },
      {
        action: 'show-comparison',
        comparison: {
          argus: 'Calculating... (415ms)',
          ours: 'Complete! (9.8ms)'
        }
      },
      {
        action: 'rapid-changes',
        highlight: 'Watch real-time updates as we change parameters'
      }
    ]
  }
];

export default function DemoMode() {
  const [isActive, setIsActive] = useState(false);
  const [selectedScenario, setSelectedScenario] = useState<DemoScenario | null>(null);
  const [currentStep, setCurrentStep] = useState(0);
  const [showComparison, setShowComparison] = useState(false);
  const { startDemo, stopDemo, executeStep } = useDemoStore();

  const handleStartDemo = (scenario: DemoScenario) => {
    setSelectedScenario(scenario);
    setCurrentStep(0);
    setIsActive(true);
    startDemo(scenario.id);
  };

  const handleStopDemo = () => {
    setIsActive(false);
    setSelectedScenario(null);
    setCurrentStep(0);
    setShowComparison(false);
    stopDemo();
  };

  const handleNextStep = async () => {
    if (!selectedScenario || currentStep >= selectedScenario.steps.length) return;
    
    const step = selectedScenario.steps[currentStep];
    
    // Execute the step
    await executeStep(step);
    
    // Show comparison if needed
    if (step.comparison) {
      setShowComparison(true);
    }
    
    // Move to next step
    if (currentStep < selectedScenario.steps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      // Demo complete
      setTimeout(() => {
        alert('Demo complete! 🎉');
        handleStopDemo();
      }, 2000);
    }
  };

  // Auto-advance for smooth demos
  useEffect(() => {
    if (isActive && selectedScenario) {
      const timer = setTimeout(handleNextStep, 3000);
      return () => clearTimeout(timer);
    }
  }, [currentStep, isActive]);

  if (!isActive) {
    return (
      <div className="fixed bottom-6 right-6 z-50">
        <div className="bg-white rounded-lg shadow-2xl p-6 w-96 border-2 border-purple-200">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2">
              <Play className="h-5 w-5 text-purple-600" />
              Demo Mode
            </h3>
            <span className="text-sm text-purple-600 font-medium">Ready to impress!</span>
          </div>
          
          <p className="text-sm text-gray-600 mb-4">
            Choose a scenario to showcase WFM Enterprise superiority:
          </p>
          
          <div className="space-y-3">
            {demoScenarios.map(scenario => {
              const Icon = scenario.icon;
              return (
                <button
                  key={scenario.id}
                  onClick={() => handleStartDemo(scenario)}
                  className="w-full text-left p-4 rounded-lg border-2 border-gray-200 hover:border-purple-400 hover:bg-purple-50 transition-all group"
                >
                  <div className="flex items-start gap-3">
                    <Icon className="h-5 w-5 text-purple-600 mt-0.5 group-hover:scale-110 transition-transform" />
                    <div className="flex-1">
                      <div className="flex items-center justify-between">
                        <h4 className="font-semibold text-gray-900">{scenario.name}</h4>
                        <span className="text-xs text-gray-500">{scenario.duration}</span>
                      </div>
                      <p className="text-sm text-gray-600 mt-1">{scenario.description}</p>
                      <div className="flex gap-2 mt-2">
                        {scenario.highlights.map((highlight, i) => (
                          <span key={i} className="text-xs bg-purple-100 text-purple-700 px-2 py-1 rounded">
                            {highlight}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      </div>
    );
  }

  return (
    <>
      {/* Demo Control Panel */}
      <div className="fixed top-20 left-1/2 transform -translate-x-1/2 z-50">
        <div className="bg-gradient-to-r from-purple-600 to-pink-600 text-white rounded-full shadow-2xl px-6 py-3 flex items-center gap-4">
          <Sparkles className="h-5 w-5 animate-pulse" />
          <span className="font-semibold">{selectedScenario?.name}</span>
          <div className="h-4 w-px bg-white/30" />
          <span className="text-sm">
            Step {currentStep + 1} of {selectedScenario?.steps.length}
          </span>
          <button
            onClick={handleNextStep}
            className="ml-2 bg-white/20 hover:bg-white/30 rounded-full p-1 transition-colors"
          >
            <ChevronRight className="h-4 w-4" />
          </button>
          <button
            onClick={handleStopDemo}
            className="ml-2 bg-red-500/20 hover:bg-red-500/30 rounded-full p-1 transition-colors"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
      </div>

      {/* Current Step Highlight */}
      {selectedScenario && (
        <div className="fixed bottom-6 left-6 z-50 max-w-md">
          <div className="bg-white rounded-lg shadow-2xl p-4 border-2 border-purple-200">
            <div className="flex items-start gap-3">
              <div className="bg-purple-600 text-white rounded-full w-8 h-8 flex items-center justify-center text-sm font-bold">
                {currentStep + 1}
              </div>
              <div>
                <p className="text-gray-900 font-medium">
                  {selectedScenario.steps[currentStep].highlight}
                </p>
                {selectedScenario.steps[currentStep].comparison && (
                  <div className="mt-2 grid grid-cols-2 gap-2 text-sm">
                    <div className="bg-red-50 p-2 rounded">
                      <span className="text-red-600 font-medium">Argus:</span>
                      <p className="text-red-900">{selectedScenario.steps[currentStep].comparison.argus}</p>
                    </div>
                    <div className="bg-green-50 p-2 rounded">
                      <span className="text-green-600 font-medium">WFM Enterprise:</span>
                      <p className="text-green-900">{selectedScenario.steps[currentStep].comparison.ours}</p>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Guided Tour Overlay */}
      <GuidedTour
        isActive={isActive}
        currentStep={selectedScenario?.steps[currentStep]}
      />

      {/* Comparison Animation */}
      {showComparison && (
        <ComparisonView
          onClose={() => setShowComparison(false)}
          comparison={selectedScenario?.steps[currentStep].comparison}
        />
      )}
    </>
  );
}