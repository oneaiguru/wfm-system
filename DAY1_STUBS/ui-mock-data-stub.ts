// UI Mock Data Stubs for UI-OPUS
// Mock data structures and API responses for rapid UI development

// Agent data structures
export interface Agent {
  id: string;
  name: string;
  email: string;
  skills: string[];
  availability: {
    start: string;
    end: string;
    daysOfWeek: number[]; // 0-6, Sunday-Saturday
  };
  currentStatus: 'available' | 'busy' | 'break' | 'offline';
  efficiency: number; // 0-1
}

// Forecast data structures
export interface ForecastData {
  date: string;
  intervals: Array<{
    time: string;
    callVolume: number;
    aht: number;
    requiredStaff: number;
    scheduledStaff: number;
    serviceLevel: number;
  }>;
}

// Schedule data structures
export interface ScheduleData {
  agentId: string;
  agentName: string;
  date: string;
  shifts: Array<{
    start: string;
    end: string;
    type: 'work' | 'break' | 'lunch' | 'training';
    skill?: string;
  }>;
}

// Vacancy data structures
export interface VacancyData {
  id: string;
  date: string;
  timeSlot: string;
  requiredStaff: number;
  currentStaff: number;
  gap: number;
  skills: string[];
  priority: 'critical' | 'high' | 'medium' | 'low';
  suggestions: string[];
}

// Mock data generators
export class UIMockDataStub {
  
  // Generate mock agents
  generateAgents(count: number = 50): Agent[] {
    const skills = ['voice', 'email', 'chat', 'technical', 'billing', 'sales'];
    const agents: Agent[] = [];
    
    for (let i = 1; i <= count; i++) {
      agents.push({
        id: `agent${i}`,
        name: `Agent ${i}`,
        email: `agent${i}@company.com`,
        skills: skills.filter(() => Math.random() > 0.5),
        availability: {
          start: '08:00',
          end: '17:00',
          daysOfWeek: [1, 2, 3, 4, 5] // Mon-Fri
        },
        currentStatus: ['available', 'busy', 'break', 'offline'][Math.floor(Math.random() * 4)] as any,
        efficiency: 0.7 + Math.random() * 0.3
      });
    }
    
    return agents;
  }
  
  // Generate forecast data
  generateForecastData(startDate: Date, days: number = 7): ForecastData[] {
    const forecasts: ForecastData[] = [];
    
    for (let d = 0; d < days; d++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + d);
      
      const intervals = [];
      for (let h = 0; h < 24; h++) {
        for (let m = 0; m < 60; m += 15) {
          const hour = h.toString().padStart(2, '0');
          const minute = m.toString().padStart(2, '0');
          const time = `${hour}:${minute}`;
          
          // Simulate call volume pattern (higher during business hours)
          const baseVolume = (h >= 8 && h <= 17) ? 50 : 10;
          const callVolume = baseVolume + Math.floor(Math.random() * 20);
          const requiredStaff = Math.ceil(callVolume / 10);
          
          intervals.push({
            time,
            callVolume,
            aht: 180 + Math.floor(Math.random() * 120),
            requiredStaff,
            scheduledStaff: requiredStaff + Math.floor(Math.random() * 3) - 1,
            serviceLevel: 0.7 + Math.random() * 0.25
          });
        }
      }
      
      forecasts.push({
        date: date.toISOString().split('T')[0],
        intervals
      });
    }
    
    return forecasts;
  }
  
  // Generate schedule data
  generateScheduleData(agents: Agent[], date: Date): ScheduleData[] {
    const schedules: ScheduleData[] = [];
    
    agents.forEach(agent => {
      const dayOfWeek = date.getDay();
      if (!agent.availability.daysOfWeek.includes(dayOfWeek)) return;
      
      const shifts = [];
      const [startHour, startMin] = agent.availability.start.split(':').map(Number);
      const [endHour, endMin] = agent.availability.end.split(':').map(Number);
      
      // Morning work
      shifts.push({
        start: agent.availability.start,
        end: '10:15',
        type: 'work' as const,
        skill: agent.skills[0]
      });
      
      // Break
      shifts.push({
        start: '10:15',
        end: '10:30',
        type: 'break' as const
      });
      
      // Mid-morning work
      shifts.push({
        start: '10:30',
        end: '12:30',
        type: 'work' as const,
        skill: agent.skills[0]
      });
      
      // Lunch
      shifts.push({
        start: '12:30',
        end: '13:30',
        type: 'lunch' as const
      });
      
      // Afternoon work
      shifts.push({
        start: '13:30',
        end: agent.availability.end,
        type: 'work' as const,
        skill: agent.skills[0]
      });
      
      schedules.push({
        agentId: agent.id,
        agentName: agent.name,
        date: date.toISOString().split('T')[0],
        shifts
      });
    });
    
    return schedules;
  }
  
  // Generate vacancy data
  generateVacancyData(forecastData: ForecastData[], scheduleData: ScheduleData[]): VacancyData[] {
    const vacancies: VacancyData[] = [];
    
    forecastData.forEach(forecast => {
      const dateSchedules = scheduleData.filter(s => s.date === forecast.date);
      
      forecast.intervals.forEach((interval, idx) => {
        // Count scheduled staff for this interval
        const scheduledStaff = dateSchedules.filter(schedule => {
          return schedule.shifts.some(shift => {
            if (shift.type !== 'work') return false;
            const [shiftStartH, shiftStartM] = shift.start.split(':').map(Number);
            const [shiftEndH, shiftEndM] = shift.end.split(':').map(Number);
            const [intervalH, intervalM] = interval.time.split(':').map(Number);
            
            const shiftStartMinutes = shiftStartH * 60 + shiftStartM;
            const shiftEndMinutes = shiftEndH * 60 + shiftEndM;
            const intervalMinutes = intervalH * 60 + intervalM;
            
            return intervalMinutes >= shiftStartMinutes && intervalMinutes < shiftEndMinutes;
          });
        }).length;
        
        const gap = interval.requiredStaff - scheduledStaff;
        
        if (gap > 0) {
          vacancies.push({
            id: `vacancy-${forecast.date}-${idx}`,
            date: forecast.date,
            timeSlot: interval.time,
            requiredStaff: interval.requiredStaff,
            currentStaff: scheduledStaff,
            gap,
            skills: ['voice'], // Simplified for stub
            priority: gap > 3 ? 'critical' : gap > 2 ? 'high' : gap > 1 ? 'medium' : 'low',
            suggestions: [
              'Schedule overtime for available agents',
              'Call in part-time staff',
              'Redistribute workload to adjacent intervals'
            ]
          });
        }
      });
    });
    
    return vacancies;
  }
  
  // API response mocks
  mockApiResponses = {
    // GET /api/agents
    getAgents: () => ({
      success: true,
      data: this.generateAgents(50),
      total: 50
    }),
    
    // GET /api/forecast/:date
    getForecast: (date: string) => ({
      success: true,
      data: this.generateForecastData(new Date(date), 1)[0]
    }),
    
    // GET /api/schedule/:date
    getSchedule: (date: string) => ({
      success: true,
      data: this.generateScheduleData(this.generateAgents(30), new Date(date))
    }),
    
    // GET /api/vacancies/:date
    getVacancies: (date: string) => {
      const forecast = this.generateForecastData(new Date(date), 1);
      const agents = this.generateAgents(30);
      const schedule = this.generateScheduleData(agents, new Date(date));
      return {
        success: true,
        data: this.generateVacancyData(forecast, schedule)
      };
    },
    
    // POST /api/schedule/optimize
    optimizeSchedule: (params: any) => ({
      success: true,
      data: {
        originalScore: 75,
        optimizedScore: 92,
        improvements: [
          'Reduced total gap hours by 35%',
          'Improved skill coverage by 20%',
          'Balanced workload across agents'
        ],
        schedule: this.generateScheduleData(this.generateAgents(30), new Date())
      }
    }),
    
    // GET /api/realtime/metrics
    getRealtimeMetrics: () => ({
      success: true,
      data: {
        timestamp: new Date().toISOString(),
        queues: [
          {
            id: 'queue1',
            name: 'Voice Support',
            callsInQueue: Math.floor(Math.random() * 20),
            avgWaitTime: Math.floor(Math.random() * 300),
            serviceLevel: 0.75 + Math.random() * 0.2,
            agentsAvailable: Math.floor(Math.random() * 10) + 5
          }
        ]
      }
    })
  };
}

// Export singleton instance
export const uiMockData = new UIMockDataStub();

// Example usage for UI development:
/*
import { uiMockData } from './ui-mock-data-stub';

// In React component
const [agents, setAgents] = useState([]);
const [forecast, setForecast] = useState(null);

useEffect(() => {
  // Simulate API call
  const response = uiMockData.mockApiResponses.getAgents();
  setAgents(response.data);
  
  // Get forecast for today
  const forecastResponse = uiMockData.mockApiResponses.getForecast(new Date().toISOString());
  setForecast(forecastResponse.data);
}, []);

// Use WebSocket stub for real-time updates
wsStub.subscribe(WS_EVENTS.QUEUE_METRICS_UPDATE, (event) => {
  updateMetrics(event.payload);
});
*/