import React, { useState } from 'react';
import { Monitor, Calendar, FileText, BarChart3, Users, ArrowRight } from 'lucide-react';
import EmployeeDashboard from './EmployeeDashboard';
import ScheduleView from './ScheduleView';
import RequestForm from './RequestForm';

export const DemoShowcase: React.FC = () => {
  const [currentDemo, setCurrentDemo] = useState<'overview' | 'dashboard' | 'schedule' | 'request'>('overview');

  const demos = [
    {
      id: 'dashboard',
      title: 'Employee Dashboard',
      description: 'Personalized dashboard with quick stats and actions',
      icon: Monitor,
      component: EmployeeDashboard
    },
    {
      id: 'schedule',
      title: 'Schedule View',
      description: 'Weekly calendar with shift details and navigation',
      icon: Calendar,
      component: ScheduleView
    },
    {
      id: 'request',
      title: 'Request Form',
      description: 'Time off request form with validation',
      icon: FileText,
      component: RequestForm
    }
  ];

  const DemoCard: React.FC<{
    demo: typeof demos[0];
    isActive: boolean;
    onClick: () => void;
  }> = ({ demo, isActive, onClick }) => (
    <div
      className={`p-6 rounded-lg border-2 cursor-pointer transition-all ${
        isActive 
          ? 'border-blue-500 bg-blue-50' 
          : 'border-gray-200 bg-white hover:border-gray-300'
      }`}
      onClick={onClick}
    >
      <div className="flex items-center gap-4">
        <div className={`p-3 rounded-lg ${isActive ? 'bg-blue-600' : 'bg-gray-100'}`}>
          <demo.icon className={`h-6 w-6 ${isActive ? 'text-white' : 'text-gray-600'}`} />
        </div>
        <div>
          <h3 className={`font-semibold ${isActive ? 'text-blue-900' : 'text-gray-900'}`}>
            {demo.title}
          </h3>
          <p className={`text-sm ${isActive ? 'text-blue-700' : 'text-gray-600'}`}>
            {demo.description}
          </p>
        </div>
        <ArrowRight className={`h-5 w-5 ${isActive ? 'text-blue-600' : 'text-gray-400'}`} />
      </div>
    </div>
  );

  if (currentDemo !== 'overview') {
    const demo = demos.find(d => d.id === currentDemo);
    if (demo) {
      const Component = demo.component;
      return (
        <div>
          <div className="bg-white border-b p-4">
            <button
              onClick={() => setCurrentDemo('overview')}
              className="flex items-center gap-2 text-blue-600 hover:text-blue-800"
            >
              ← Back to Demo Overview
            </button>
          </div>
          <Component />
        </div>
      );
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 py-8">
          <div className="text-center">
            <h1 className="text-3xl font-bold text-gray-900 mb-2">
              WFM Enterprise UI Demo
            </h1>
            <p className="text-lg text-gray-600">
              Interactive demonstration of our workforce management interface
            </p>
          </div>
        </div>
      </div>

      {/* Demo Overview */}
      <div className="max-w-7xl mx-auto px-4 py-8">
        {/* Key Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="bg-white rounded-lg p-6 shadow-sm border text-center">
            <div className="text-2xl font-bold text-blue-600 mb-1">3</div>
            <div className="text-sm text-gray-600">Working Components</div>
          </div>
          <div className="bg-white rounded-lg p-6 shadow-sm border text-center">
            <div className="text-2xl font-bold text-green-600 mb-1">100%</div>
            <div className="text-sm text-gray-600">Demo Ready</div>
          </div>
          <div className="bg-white rounded-lg p-6 shadow-sm border text-center">
            <div className="text-2xl font-bold text-purple-600 mb-1">15s</div>
            <div className="text-sm text-gray-600">Load Time</div>
          </div>
          <div className="bg-white rounded-lg p-6 shadow-sm border text-center">
            <div className="text-2xl font-bold text-orange-600 mb-1">0</div>
            <div className="text-sm text-gray-600">Auth Required</div>
          </div>
        </div>

        {/* Demo Features */}
        <div className="mb-8">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            Available Demonstrations
          </h2>
          <div className="space-y-4">
            {demos.map((demo) => (
              <DemoCard
                key={demo.id}
                demo={demo}
                isActive={false}
                onClick={() => setCurrentDemo(demo.id as any)}
              />
            ))}
          </div>
        </div>

        {/* Demo Flow */}
        <div className="bg-white rounded-lg p-6 shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
            Recommended Demo Flow
          </h3>
          <div className="space-y-3">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center text-sm font-medium">
                1
              </div>
              <div>
                <div className="font-medium">Employee Dashboard</div>
                <div className="text-sm text-gray-600">Show personalized welcome and quick stats</div>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center text-sm font-medium">
                2
              </div>
              <div>
                <div className="font-medium">Schedule View</div>
                <div className="text-sm text-gray-600">Demonstrate weekly calendar and shift details</div>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center text-sm font-medium">
                3
              </div>
              <div>
                <div className="font-medium">Request Form</div>
                <div className="text-sm text-gray-600">Show time off request process and validation</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DemoShowcase;