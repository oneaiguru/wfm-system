import React, { useState } from 'react';
import { Calendar, Layout, Settings, Send, Activity, HeatMap } from 'lucide-react';
import { 
  ScheduleEditor, 
  TemplateManager, 
  PublishDialog, 
  RealtimeSchedule,
  CoverageHeatmap 
} from '../components/schedule';

const ScheduleManagementDemo: React.FC = () => {
  const [activeTab, setActiveTab] = useState<string>('editor');
  const [showPublishDialog, setShowPublishDialog] = useState(false);

  const tabs = [
    { id: 'editor', label: 'Schedule Editor', icon: Calendar, spec: 'SPEC-16' },
    { id: 'templates', label: 'Template Manager', icon: Settings, spec: 'SPEC-20' },
    { id: 'coverage', label: 'Coverage Heatmap', icon: HeatMap, spec: 'SPEC-19' },
    { id: 'realtime', label: 'Realtime Monitor', icon: Activity, spec: 'SPEC-24' }
  ];

  const handlePublish = (data: any) => {
    console.log('Publishing schedule:', data);
    setShowPublishDialog(false);
    // In a real app, this would trigger a notification or update
  };

  const today = new Date();
  const startDate = today.toISOString().split('T')[0];
  const endDate = new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="py-4">
            <h1 className="text-2xl font-bold text-gray-900">Schedule Management Demo</h1>
            <p className="text-sm text-gray-600 mt-1">
              Demonstrating 5 schedule management features (SPEC-16, 19, 20, 22, 24)
            </p>
          </div>
        </div>
      </div>

      {/* Tab Navigation */}
      <div className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <nav className="flex space-x-8" aria-label="Tabs">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`
                    py-4 px-1 border-b-2 font-medium text-sm flex items-center gap-2
                    ${activeTab === tab.id
                      ? 'border-blue-500 text-blue-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                    }
                  `}
                >
                  <Icon className="h-4 w-4" />
                  {tab.label}
                  <span className="text-xs text-gray-400">({tab.spec})</span>
                </button>
              );
            })}
          </nav>
        </div>
      </div>

      {/* Publish Button (SPEC-22) */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
        <div className="flex justify-end">
          <button
            onClick={() => setShowPublishDialog(true)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg 
              hover:bg-blue-700 transition-colors"
          >
            <Send className="h-4 w-4" />
            Publish Schedule (SPEC-22)
          </button>
        </div>
      </div>

      {/* Tab Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {activeTab === 'editor' && (
          <div>
            <div className="mb-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <h3 className="font-semibold text-blue-900 mb-2">SPEC-16: Schedule Editor</h3>
              <p className="text-sm text-blue-800">
                Drag and drop shifts between employees to reschedule. Click on shifts to edit details.
                All changes are saved via PUT /api/v1/schedules/shift/{'{id}'}.
              </p>
            </div>
            <ScheduleEditor 
              startDate={startDate} 
              endDate={endDate}
              onScheduleUpdate={() => console.log('Schedule updated')}
            />
          </div>
        )}

        {activeTab === 'templates' && (
          <div>
            <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg">
              <h3 className="font-semibold text-green-900 mb-2">SPEC-20: Template Manager</h3>
              <p className="text-sm text-green-800">
                Create, edit, and manage shift templates. Templates can be reused across schedules.
                Uses CRUD endpoints at /api/v1/schedules/templates.
              </p>
            </div>
            <TemplateManager />
          </div>
        )}

        {activeTab === 'coverage' && (
          <div>
            <div className="mb-4 p-4 bg-purple-50 border border-purple-200 rounded-lg">
              <h3 className="font-semibold text-purple-900 mb-2">SPEC-19: Coverage Heatmap</h3>
              <p className="text-sm text-purple-800">
                Visualize schedule coverage with a heatmap. Red indicates understaffing, green shows optimal coverage.
                Data from GET /api/v1/schedules/coverage/analysis.
              </p>
            </div>
            <CoverageHeatmap />
          </div>
        )}

        {activeTab === 'realtime' && (
          <div>
            <div className="mb-4 p-4 bg-orange-50 border border-orange-200 rounded-lg">
              <h3 className="font-semibold text-orange-900 mb-2">SPEC-24: Realtime Schedule Monitor</h3>
              <p className="text-sm text-orange-800">
                Live view of current shifts and updates. Auto-refreshes every 30 seconds.
                Uses GET /api/v1/schedules/realtime/updates (WebSocket support planned).
              </p>
            </div>
            <RealtimeSchedule 
              refreshInterval={30}
              enableWebSocket={false}
            />
          </div>
        )}
      </div>

      {/* Publish Dialog (SPEC-22) */}
      <PublishDialog
        isOpen={showPublishDialog}
        onClose={() => setShowPublishDialog(false)}
        onConfirm={handlePublish}
        scheduleData={{
          startDate,
          endDate,
          employeeCount: 15,
          shiftCount: 75,
          departments: ['Customer Service', 'Sales', 'Support']
        }}
      />

      {/* Demo Commands Footer */}
      <div className="mt-12 bg-gray-800 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <h3 className="text-lg font-semibold mb-4">Demo Commands</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h4 className="font-medium mb-2">Test Schedule Editor (SPEC-16):</h4>
              <pre className="bg-gray-900 p-3 rounded text-sm overflow-x-auto">
{`curl -X PUT http://localhost:8001/api/v1/schedules/shift/1 \\
  -H "Content-Type: application/json" \\
  -d '{"startTime":"09:00","endTime":"17:00"}'`}
              </pre>
            </div>
            
            <div>
              <h4 className="font-medium mb-2">Test Template Manager (SPEC-20):</h4>
              <pre className="bg-gray-900 p-3 rounded text-sm overflow-x-auto">
{`curl -X POST http://localhost:8001/api/v1/schedules/templates \\
  -H "Content-Type: application/json" \\
  -d '{"name":"Morning Shift","startTime":"08:00","endTime":"16:00"}'`}
              </pre>
            </div>
            
            <div>
              <h4 className="font-medium mb-2">Test Publish Schedule (SPEC-22):</h4>
              <pre className="bg-gray-900 p-3 rounded text-sm overflow-x-auto">
{`curl -X POST http://localhost:8001/api/v1/schedules/publish \\
  -H "Content-Type: application/json" \\
  -d '{"start_date":"2025-08-01","end_date":"2025-08-07","notify_employees":true}'`}
              </pre>
            </div>
            
            <div>
              <h4 className="font-medium mb-2">Test Coverage Analysis (SPEC-19):</h4>
              <pre className="bg-gray-900 p-3 rounded text-sm overflow-x-auto">
{`curl http://localhost:8001/api/v1/schedules/coverage/analysis?service_id=1&period=7d`}
              </pre>
            </div>
            
            <div className="md:col-span-2">
              <h4 className="font-medium mb-2">Test Realtime Updates (SPEC-24):</h4>
              <pre className="bg-gray-900 p-3 rounded text-sm overflow-x-auto">
{`curl http://localhost:8001/api/v1/schedules/realtime/updates`}
              </pre>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ScheduleManagementDemo;