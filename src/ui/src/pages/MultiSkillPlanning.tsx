import React, { useState, useEffect } from 'react';
import SkillMatrix from '@/components/multiskill/SkillMatrix';
import QueueManager from '@/components/multiskill/QueueManager';
import SkillOptimizer from '@/components/multiskill/SkillOptimizer';
import { useMultiSkillOptimization } from '@/hooks/useMultiSkillOptimization';

interface MultiSkillPlanningProps {
  onDataUpdate?: (data: any) => void;
}

const MultiSkillPlanning: React.FC<MultiSkillPlanningProps> = ({ onDataUpdate }) => {
  const [activeView, setActiveView] = useState<'matrix' | 'queues' | 'optimizer'>('matrix');
  const [employees, setEmployees] = useState<any[]>([]);
  const [skills, setSkills] = useState<any[]>([]);
  const [queues, setQueues] = useState<any[]>([]);
  const [assignments, setAssignments] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showDemo, setShowDemo] = useState(false);

  const {
    optimizeAssignments,
    generateProjectIData,
    calculateAccuracy,
    isOptimizing,
    optimizationProgress,
    lastOptimizationResult
  } = useMultiSkillOptimization();

  // Load or generate demo data
  useEffect(() => {
    const loadData = async () => {
      setIsLoading(true);
      
      try {
        if (showDemo) {
          // Generate Project И demo data (68 queues)
          const demoData = generateProjectIData();
          setSkills(demoData.skills);
          setQueues(demoData.queues);
          setEmployees(demoData.employees);
          
          // Generate some initial assignments
          const initialAssignments: any[] = [];
          demoData.employees.forEach(emp => {
            if (emp.skills.length > 0 && Math.random() > 0.3) {
              const skillId = emp.skills[0];
              const proficiency = emp.proficiencyLevels[skillId];
              initialAssignments.push({
                employeeId: emp.id,
                skillId: skillId,
                proficiency: proficiency,
                isPrimary: proficiency >= 4,
                lastUsed: new Date(),
                performanceScore: 0.7 + (proficiency * 0.06)
              });
            }
          });
          setAssignments(initialAssignments);
        } else {
          // Load from API or use default data
          // For now, using smaller demo data
          setEmployees([
            { id: 'emp-1', name: 'John Smith', department: 'Technical Support', currentLoad: 2, maxCapacity: 3, efficiency: 0.85, availability: 'available' },
            { id: 'emp-2', name: 'Sarah Johnson', department: 'Billing', currentLoad: 1, maxCapacity: 3, efficiency: 0.90, availability: 'available' },
            { id: 'emp-3', name: 'Mike Chen', department: 'Sales', currentLoad: 2, maxCapacity: 3, efficiency: 0.88, availability: 'available' },
            { id: 'emp-4', name: 'Lisa Wang', department: 'Customer Service', currentLoad: 1, maxCapacity: 3, efficiency: 0.92, availability: 'available' },
            { id: 'emp-5', name: 'David Brown', department: 'VIP Support', currentLoad: 1, maxCapacity: 2, efficiency: 0.95, availability: 'available' }
          ]);
          
          setSkills([
            { id: 'skill-1', name: 'Technical Support EN', queueId: 'queue-1', requiredCoverage: 3, currentCoverage: 2, priority: 'high', avgHandleTime: 180 },
            { id: 'skill-2', name: 'Billing Support', queueId: 'queue-2', requiredCoverage: 2, currentCoverage: 1, priority: 'medium', avgHandleTime: 240 },
            { id: 'skill-3', name: 'Sales Chat', queueId: 'queue-3', requiredCoverage: 2, currentCoverage: 1, priority: 'high', avgHandleTime: 120 },
            { id: 'skill-4', name: 'Customer Service', queueId: 'queue-4', requiredCoverage: 3, currentCoverage: 1, priority: 'medium', avgHandleTime: 150 },
            { id: 'skill-5', name: 'VIP Support', queueId: 'queue-5', requiredCoverage: 1, currentCoverage: 1, priority: 'high', avgHandleTime: 300 }
          ]);
          
          setQueues([
            { id: 'queue-1', name: 'Technical Support - EN - VOICE', type: 'voice', priority: 'high', currentVolume: 150, avgHandleTime: 180, serviceLevel: 75, targetServiceLevel: 80, requiredOperators: 3, assignedOperators: 2, skills: ['skill-1'], department: 'Technical Support', lastUpdated: new Date() },
            { id: 'queue-2', name: 'Billing - Multi - EMAIL', type: 'email', priority: 'medium', currentVolume: 80, avgHandleTime: 240, serviceLevel: 82, targetServiceLevel: 80, requiredOperators: 2, assignedOperators: 1, skills: ['skill-2'], department: 'Billing', lastUpdated: new Date() },
            { id: 'queue-3', name: 'Sales - EN - CHAT', type: 'chat', priority: 'high', currentVolume: 120, avgHandleTime: 120, serviceLevel: 70, targetServiceLevel: 85, requiredOperators: 2, assignedOperators: 1, skills: ['skill-3'], department: 'Sales', lastUpdated: new Date() },
            { id: 'queue-4', name: 'Customer Service - Multi - VOICE', type: 'voice', priority: 'medium', currentVolume: 200, avgHandleTime: 150, serviceLevel: 78, targetServiceLevel: 80, requiredOperators: 3, assignedOperators: 1, skills: ['skill-4'], department: 'Customer Service', lastUpdated: new Date() },
            { id: 'queue-5', name: 'VIP Support - EN - VIDEO', type: 'video', priority: 'high', currentVolume: 20, avgHandleTime: 300, serviceLevel: 95, targetServiceLevel: 95, requiredOperators: 1, assignedOperators: 1, skills: ['skill-5'], department: 'VIP Support', lastUpdated: new Date() }
          ]);
          
          setAssignments([
            { employeeId: 'emp-1', skillId: 'skill-1', proficiency: 5, isPrimary: true, lastUsed: new Date(), performanceScore: 0.92 },
            { employeeId: 'emp-2', skillId: 'skill-2', proficiency: 4, isPrimary: true, lastUsed: new Date(), performanceScore: 0.88 },
            { employeeId: 'emp-3', skillId: 'skill-3', proficiency: 4, isPrimary: true, lastUsed: new Date(), performanceScore: 0.85 },
            { employeeId: 'emp-4', skillId: 'skill-4', proficiency: 3, isPrimary: true, lastUsed: new Date(), performanceScore: 0.80 },
            { employeeId: 'emp-5', skillId: 'skill-5', proficiency: 5, isPrimary: true, lastUsed: new Date(), performanceScore: 0.95 }
          ]);
        }
      } finally {
        setIsLoading(false);
      }
    };
    
    loadData();
  }, [showDemo, generateProjectIData]);

  const handleAssignmentUpdate = (newAssignments: any[]) => {
    setAssignments(newAssignments);
    onDataUpdate?.({ assignments: newAssignments });
    
    // Update skill coverage
    const coverageMap = new Map<string, number>();
    newAssignments.forEach(assignment => {
      const current = coverageMap.get(assignment.skillId) || 0;
      coverageMap.set(assignment.skillId, current + 1);
    });
    
    setSkills(skills.map(skill => ({
      ...skill,
      currentCoverage: coverageMap.get(skill.id) || 0
    })));
  };

  const handleQueueUpdate = (updatedQueues: any[]) => {
    setQueues(updatedQueues);
    onDataUpdate?.({ queues: updatedQueues });
  };

  const handleApplyOptimization = async (scenario: any) => {
    const result = await optimizeAssignments(
      employees,
      skills,
      queues,
      {
        mode: 'balanced',
        constraints: {
          minServiceLevel: 80,
          minCoverage: 0.8
        },
        weights: {
          accuracy: 0.4,
          efficiency: 0.3,
          cost: 0.2,
          coverage: 0.1
        }
      }
    );
    
    if (result) {
      handleAssignmentUpdate(result.assignments);
      alert(`Optimization applied! New accuracy: ${result.metrics.accuracy.toFixed(1)}%`);
    }
  };

  const currentAccuracy = calculateAccuracy(assignments, skills, employees);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading multi-skill planning data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header with Demo Toggle */}
      <div className="bg-white p-6 rounded-lg shadow">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold mb-2">Multi-Skill Planning Center</h1>
            <p className="text-gray-600">
              Advanced ML-powered skill optimization for {queues.length} queues
            </p>
          </div>
          <div className="flex items-center gap-4">
            <div className="text-right">
              <div className="text-3xl font-bold text-blue-600">{currentAccuracy.toFixed(1)}%</div>
              <div className="text-sm text-gray-600">Current Accuracy</div>
              <div className="text-xs text-green-600">+{(currentAccuracy - 65).toFixed(1)}% vs Industry</div>
            </div>
            <button
              onClick={() => setShowDemo(!showDemo)}
              className={`px-4 py-2 rounded transition-colors ${
                showDemo 
                  ? 'bg-purple-600 text-white' 
                  : 'bg-gray-200 hover:bg-gray-300'
              }`}
            >
              {showDemo ? 'Project И Mode (68 Queues)' : 'Enable Project И Demo'}
            </button>
          </div>
        </div>
      </div>

      {/* View Navigation */}
      <div className="bg-white p-4 rounded-lg shadow">
        <div className="flex gap-2">
          <button
            onClick={() => setActiveView('matrix')}
            className={`px-6 py-3 rounded-lg font-medium transition-colors ${
              activeView === 'matrix'
                ? 'bg-blue-600 text-white'
                : 'bg-gray-100 hover:bg-gray-200 text-gray-700'
            }`}
          >
            Skill Matrix
          </button>
          <button
            onClick={() => setActiveView('queues')}
            className={`px-6 py-3 rounded-lg font-medium transition-colors ${
              activeView === 'queues'
                ? 'bg-blue-600 text-white'
                : 'bg-gray-100 hover:bg-gray-200 text-gray-700'
            }`}
          >
            Queue Management
          </button>
          <button
            onClick={() => setActiveView('optimizer')}
            className={`px-6 py-3 rounded-lg font-medium transition-colors ${
              activeView === 'optimizer'
                ? 'bg-blue-600 text-white'
                : 'bg-gray-100 hover:bg-gray-200 text-gray-700'
            }`}
          >
            ML Optimizer
          </button>
        </div>
      </div>

      {/* Content Area */}
      {activeView === 'matrix' && (
        <SkillMatrix
          employees={employees}
          skills={skills}
          assignments={assignments}
          onAssignmentUpdate={handleAssignmentUpdate}
          targetAccuracy={85}
        />
      )}

      {activeView === 'queues' && (
        <QueueManager
          queues={queues}
          onQueueUpdate={handleQueueUpdate}
          simulationMode={showDemo}
        />
      )}

      {activeView === 'optimizer' && (
        <SkillOptimizer
          currentAssignments={assignments}
          skills={skills}
          queues={queues}
          employees={employees}
          onApplyOptimization={handleApplyOptimization}
        />
      )}

      {/* Key Differentiators Summary */}
      <div className="bg-gradient-to-r from-blue-50 to-purple-50 p-6 rounded-lg shadow">
        <h3 className="text-lg font-semibold mb-4">Our Competitive Advantages</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-white p-4 rounded-lg">
            <div className="text-2xl font-bold text-blue-600 mb-2">85%+</div>
            <div className="font-medium">Accuracy Achievement</div>
            <div className="text-sm text-gray-600 mt-1">
              vs Argus 60-70% on multi-skill scenarios
            </div>
          </div>
          <div className="bg-white p-4 rounded-lg">
            <div className="text-2xl font-bold text-green-600 mb-2">68+</div>
            <div className="font-medium">Queue Support</div>
            <div className="text-sm text-gray-600 mt-1">
              Proven scalability for Project И requirements
            </div>
          </div>
          <div className="bg-white p-4 rounded-lg">
            <div className="text-2xl font-bold text-purple-600 mb-2">ML</div>
            <div className="font-medium">Enhanced Optimization</div>
            <div className="text-sm text-gray-600 mt-1">
              Real-time rebalancing and predictive allocation
            </div>
          </div>
        </div>
      </div>

      {/* Optimization Progress */}
      {isOptimizing && (
        <div className="fixed bottom-4 right-4 bg-white p-4 rounded-lg shadow-lg">
          <div className="mb-2 font-medium">Optimizing Skills...</div>
          <div className="w-64 h-2 bg-gray-200 rounded-full overflow-hidden">
            <div 
              className="h-full bg-blue-600 transition-all duration-300"
              style={{ width: `${optimizationProgress}%` }}
            />
          </div>
          <div className="text-sm text-gray-600 mt-1">{optimizationProgress}% complete</div>
        </div>
      )}
    </div>
  );
};

export default MultiSkillPlanning;