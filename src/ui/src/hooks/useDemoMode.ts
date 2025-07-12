import { create } from 'zustand';

interface DemoState {
  isActive: boolean;
  currentScenario: string | null;
  currentStep: number;
  demoData: Record<string, any>;
  startDemo: (scenarioId: string) => void;
  stopDemo: () => void;
  executeStep: (step: any) => Promise<void>;
  setDemoData: (key: string, value: any) => void;
}

export const useDemoStore = create<DemoState>((set, get) => ({
  isActive: false,
  currentScenario: null,
  currentStep: 0,
  demoData: {},

  startDemo: (scenarioId: string) => {
    set({
      isActive: true,
      currentScenario: scenarioId,
      currentStep: 0,
      demoData: {}
    });

    // Add demo mode class to body
    document.body.classList.add('demo-mode');
    
    // Initialize demo data based on scenario
    if (scenarioId === 'multi-skill-victory') {
      set({
        demoData: {
          projectI: {
            queues: 68,
            employees: 150,
            skills: generateProjectIData()
          }
        }
      });
    }
  },

  stopDemo: () => {
    set({
      isActive: false,
      currentScenario: null,
      currentStep: 0,
      demoData: {}
    });

    // Remove demo mode class
    document.body.classList.remove('demo-mode');
  },

  executeStep: async (step: any) => {
    const { demoData } = get();

    switch (step.action) {
      case 'navigate':
        // Simulate navigation
        const tabElement = document.querySelector(`[data-tab-id="${step.target}"]`);
        if (tabElement) {
          (tabElement as HTMLElement).click();
        }
        break;

      case 'load-data':
        // Simulate data loading
        if (step.target === 'project-i') {
          // Trigger data load in the multi-skill component
          const event = new CustomEvent('demo-load-data', {
            detail: demoData.projectI
          });
          window.dispatchEvent(event);
        }
        break;

      case 'open-gear':
        // Open gear menu
        const gearButton = document.querySelector('[data-demo-id="gear-menu"]');
        if (gearButton) {
          (gearButton as HTMLElement).click();
        }
        break;

      case 'click':
        // Generic click action
        const element = document.querySelector(`[data-demo-id="${step.target}"]`);
        if (element) {
          (element as HTMLElement).click();
        }
        break;

      case 'set-growth':
        // Set growth factor values
        const fromInput = document.querySelector('[data-demo-id="growth-from"]') as HTMLInputElement;
        const toInput = document.querySelector('[data-demo-id="growth-to"]') as HTMLInputElement;
        const patternSelect = document.querySelector('[data-demo-id="growth-pattern"]') as HTMLSelectElement;
        
        if (fromInput && toInput && patternSelect) {
          fromInput.value = step.data.from;
          toInput.value = step.data.to;
          patternSelect.value = step.data.pattern;
          
          // Trigger change events
          fromInput.dispatchEvent(new Event('change', { bubbles: true }));
          toInput.dispatchEvent(new Event('change', { bubbles: true }));
          patternSelect.dispatchEvent(new Event('change', { bubbles: true }));
        }
        break;

      case 'show-preview':
        // Click preview button
        const previewButton = document.querySelector('[data-demo-id="preview-growth"]');
        if (previewButton) {
          (previewButton as HTMLElement).click();
        }
        break;

      case 'apply':
        // Apply changes
        const applyButton = document.querySelector('[data-demo-id="apply-growth"]');
        if (applyButton) {
          (applyButton as HTMLElement).click();
        }
        break;

      case 'run-optimization':
        // Run ML optimization
        const optimizeButton = document.querySelector('[data-demo-id="ml-optimize"]');
        if (optimizeButton) {
          (optimizeButton as HTMLElement).click();
        }
        break;

      case 'set-parameters':
        // Set calculation parameters
        Object.entries(step.data).forEach(([key, value]) => {
          const input = document.querySelector(`[data-demo-id="calc-${key}"]`) as HTMLInputElement;
          if (input) {
            input.value = String(value);
            input.dispatchEvent(new Event('change', { bubbles: true }));
          }
        });
        break;

      case 'rapid-changes':
        // Demonstrate rapid parameter changes
        const params = ['volume', 'aht', 'sl'];
        let index = 0;
        
        const interval = setInterval(() => {
          const param = params[index % params.length];
          const input = document.querySelector(`[data-demo-id="calc-${param}"]`) as HTMLInputElement;
          if (input) {
            const currentValue = parseFloat(input.value);
            const newValue = currentValue * (0.9 + Math.random() * 0.2); // ±10% change
            input.value = String(Math.round(newValue));
            input.dispatchEvent(new Event('change', { bubbles: true }));
          }
          index++;
          
          if (index >= 9) { // 3 changes per parameter
            clearInterval(interval);
          }
        }, 300);
        break;
    }

    // Wait a bit for visual effect
    await new Promise(resolve => setTimeout(resolve, 500));
  },

  setDemoData: (key: string, value: any) => {
    set(state => ({
      demoData: {
        ...state.demoData,
        [key]: value
      }
    }));
  }
}));

// Helper function to generate Project I demo data
function generateProjectIData() {
  const skills = [
    'Technical Support', 'Billing', 'General Inquiries', 'Sales',
    'Complaints', 'VIP Support', 'Social Media', 'Email Support'
  ];
  
  const queues = Array.from({ length: 68 }, (_, i) => ({
    id: `queue-${i + 1}`,
    name: `Queue ${String.fromCharCode(65 + (i % 26))}${Math.floor(i / 26) || ''}`,
    requiredSkills: skills.slice(0, 1 + (i % 4)).map(s => ({
      skill: s,
      minLevel: 2 + (i % 3)
    })),
    volume: 100 + Math.floor(Math.random() * 900),
    aht: 120 + Math.floor(Math.random() * 180),
    sl: 70 + Math.floor(Math.random() * 20)
  }));

  const employees = Array.from({ length: 150 }, (_, i) => ({
    id: `emp-${i + 1}`,
    name: `Agent ${i + 1}`,
    skills: skills
      .filter(() => Math.random() > 0.6)
      .map(skill => ({
        skill,
        level: 1 + Math.floor(Math.random() * 5)
      }))
  }));

  return { queues, employees, skills };
}