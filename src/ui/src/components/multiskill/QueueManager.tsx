import React, { useState, useMemo } from 'react';
import { Line, Bar } from 'react-chartjs-2';
import { 
  Chart as ChartJS, 
  CategoryScale, 
  LinearScale, 
  PointElement, 
  LineElement, 
  BarElement,
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
  Title, 
  Tooltip, 
  Legend,
  Filler
);

interface Queue {
  id: string;
  name: string;
  type: 'voice' | 'email' | 'chat' | 'video';
  priority: 'high' | 'medium' | 'low';
  currentVolume: number;
  avgHandleTime: number;
  serviceLevel: number;
  targetServiceLevel: number;
  requiredOperators: number;
  assignedOperators: number;
  skills: string[];
  department: string;
  lastUpdated: Date;
}

interface QueueGroup {
  id: string;
  name: string;
  queues: string[];
  aggregateMetrics: boolean;
}

interface QueueMetrics {
  queueId: string;
  intervalData: {
    time: string;
    volume: number;
    aht: number;
    serviceLevel: number;
    operators: number;
  }[];
  dailyPattern: number[];
  weeklyPattern: number[];
}

interface QueueManagerProps {
  queues: Queue[];
  queueGroups?: QueueGroup[];
  metrics?: QueueMetrics[];
  onQueueUpdate: (queues: Queue[]) => void;
  onGroupUpdate?: (groups: QueueGroup[]) => void;
  simulationMode?: boolean;
}

const QueueManager: React.FC<QueueManagerProps> = ({
  queues,
  queueGroups = [],
  metrics = [],
  onQueueUpdate,
  onGroupUpdate,
  simulationMode = false
}) => {
  const [selectedQueues, setSelectedQueues] = useState<Set<string>>(new Set());
  const [filterType, setFilterType] = useState<string>('all');
  const [filterPriority, setFilterPriority] = useState<string>('all');
  const [sortBy, setSortBy] = useState<string>('volume');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [showProjectIDemo, setShowProjectIDemo] = useState(false);

  // Calculate aggregate metrics
  const aggregateMetrics = useMemo(() => {
    const totalVolume = queues.reduce((sum, q) => sum + q.currentVolume, 0);
    const totalRequired = queues.reduce((sum, q) => sum + q.requiredOperators, 0);
    const totalAssigned = queues.reduce((sum, q) => sum + q.assignedOperators, 0);
    const avgServiceLevel = queues.reduce((sum, q) => sum + q.serviceLevel, 0) / queues.length;
    
    const byType = queues.reduce((acc, q) => {
      if (!acc[q.type]) acc[q.type] = { count: 0, volume: 0, operators: 0 };
      acc[q.type].count++;
      acc[q.type].volume += q.currentVolume;
      acc[q.type].operators += q.requiredOperators;
      return acc;
    }, {} as Record<string, any>);

    const criticalQueues = queues.filter(q => 
      q.serviceLevel < q.targetServiceLevel * 0.8 || 
      q.assignedOperators < q.requiredOperators * 0.9
    );

    return {
      totalQueues: queues.length,
      totalVolume,
      totalRequired,
      totalAssigned,
      avgServiceLevel,
      operatorGap: totalRequired - totalAssigned,
      coverageRatio: (totalAssigned / totalRequired) * 100,
      byType,
      criticalQueues
    };
  }, [queues]);

  // Project И demo data (68 queues scenario)
  const generateProjectIQueues = () => {
    const departments = ['Technical Support', 'Billing', 'Sales', 'Customer Service', 'VIP Support'];
    const languages = ['EN', 'RU', 'ES', 'FR', 'DE'];
    const channels = ['voice', 'email', 'chat', 'video'] as const;
    
    const projectQueues: Queue[] = [];
    let queueIndex = 0;

    departments.forEach(dept => {
      languages.forEach(lang => {
        channels.forEach(channel => {
          if (queueIndex < 68) {
            const baseVolume = Math.floor(Math.random() * 500) + 100;
            const required = Math.ceil(baseVolume / (channel === 'voice' ? 30 : 50));
            
            projectQueues.push({
              id: `queue-${queueIndex + 1}`,
              name: `${dept} - ${lang} - ${channel.toUpperCase()}`,
              type: channel,
              priority: queueIndex < 20 ? 'high' : queueIndex < 40 ? 'medium' : 'low',
              currentVolume: baseVolume,
              avgHandleTime: channel === 'voice' ? 180 : channel === 'email' ? 600 : 240,
              serviceLevel: 70 + Math.random() * 20,
              targetServiceLevel: 80,
              requiredOperators: required,
              assignedOperators: Math.floor(required * (0.7 + Math.random() * 0.4)),
              skills: [`${dept.toLowerCase()}-${lang.toLowerCase()}`, `${channel}-specialist`],
              department: dept,
              lastUpdated: new Date()
            });
            queueIndex++;
          }
        });
      });
    });

    return projectQueues;
  };

  const filteredQueues = useMemo(() => {
    let filtered = showProjectIDemo ? generateProjectIQueues() : queues;

    if (filterType !== 'all') {
      filtered = filtered.filter(q => q.type === filterType);
    }

    if (filterPriority !== 'all') {
      filtered = filtered.filter(q => q.priority === filterPriority);
    }

    // Sort queues
    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'volume':
          return b.currentVolume - a.currentVolume;
        case 'serviceLevel':
          return a.serviceLevel - b.serviceLevel;
        case 'gap':
          return (b.requiredOperators - b.assignedOperators) - (a.requiredOperators - a.assignedOperators);
        case 'priority':
          const priorityOrder = { high: 0, medium: 1, low: 2 };
          return priorityOrder[a.priority] - priorityOrder[b.priority];
        default:
          return 0;
      }
    });

    return filtered;
  }, [queues, filterType, filterPriority, sortBy, showProjectIDemo]);

  const handleQueueSelection = (queueId: string) => {
    const newSelection = new Set(selectedQueues);
    if (newSelection.has(queueId)) {
      newSelection.delete(queueId);
    } else {
      newSelection.add(queueId);
    }
    setSelectedQueues(newSelection);
  };

  const handleBulkPriorityChange = (priority: 'high' | 'medium' | 'low') => {
    const updatedQueues = queues.map(q => 
      selectedQueues.has(q.id) ? { ...q, priority } : q
    );
    onQueueUpdate(updatedQueues);
    setSelectedQueues(new Set());
  };

  const handleCreateGroup = () => {
    if (selectedQueues.size < 2) {
      alert('Select at least 2 queues to create a group');
      return;
    }

    const groupName = prompt('Enter group name:');
    if (!groupName) return;

    const newGroup: QueueGroup = {
      id: `group-${Date.now()}`,
      name: groupName,
      queues: Array.from(selectedQueues),
      aggregateMetrics: true
    };

    onGroupUpdate?.([...queueGroups, newGroup]);
    setSelectedQueues(new Set());
  };

  const getQueueStatusColor = (queue: Queue) => {
    const slRatio = queue.serviceLevel / queue.targetServiceLevel;
    const staffRatio = queue.assignedOperators / queue.requiredOperators;
    
    if (slRatio < 0.8 || staffRatio < 0.8) return 'bg-red-100 border-red-300';
    if (slRatio < 0.95 || staffRatio < 0.95) return 'bg-yellow-100 border-yellow-300';
    return 'bg-green-100 border-green-300';
  };

  const QueueCard: React.FC<{ queue: Queue }> = ({ queue }) => {
    const operatorGap = queue.requiredOperators - queue.assignedOperators;
    const isSelected = selectedQueues.has(queue.id);

    return (
      <div 
        className={`
          border-2 rounded-lg p-4 cursor-pointer transition-all
          ${getQueueStatusColor(queue)}
          ${isSelected ? 'ring-2 ring-blue-500' : ''}
        `}
        onClick={() => handleQueueSelection(queue.id)}
      >
        <div className="flex justify-between items-start mb-2">
          <div>
            <h4 className="font-semibold text-sm">{queue.name}</h4>
            <div className="flex items-center gap-2 mt-1">
              <span className={`text-xs px-2 py-1 rounded ${
                queue.priority === 'high' ? 'bg-red-200 text-red-800' :
                queue.priority === 'medium' ? 'bg-yellow-200 text-yellow-800' :
                'bg-gray-200 text-gray-800'
              }`}>
                {queue.priority}
              </span>
              <span className="text-xs text-gray-500">{queue.type}</span>
            </div>
          </div>
          <input
            type="checkbox"
            checked={isSelected}
            onChange={(e) => e.stopPropagation()}
            className="mt-1"
          />
        </div>

        <div className="grid grid-cols-2 gap-2 text-xs">
          <div>
            <span className="text-gray-600">Volume:</span>
            <span className="font-medium ml-1">{queue.currentVolume}</span>
          </div>
          <div>
            <span className="text-gray-600">AHT:</span>
            <span className="font-medium ml-1">{queue.avgHandleTime}s</span>
          </div>
          <div>
            <span className="text-gray-600">SL:</span>
            <span className={`font-medium ml-1 ${
              queue.serviceLevel < queue.targetServiceLevel ? 'text-red-600' : 'text-green-600'
            }`}>
              {queue.serviceLevel.toFixed(0)}%
            </span>
          </div>
          <div>
            <span className="text-gray-600">Operators:</span>
            <span className={`font-medium ml-1 ${operatorGap > 0 ? 'text-red-600' : ''}`}>
              {queue.assignedOperators}/{queue.requiredOperators}
            </span>
          </div>
        </div>

        {operatorGap > 0 && (
          <div className="mt-2 text-xs text-red-600 font-medium">
            Need {operatorGap} more operators
          </div>
        )}

        <div className="mt-2 flex flex-wrap gap-1">
          {queue.skills.slice(0, 3).map(skill => (
            <span key={skill} className="text-xs bg-gray-200 px-2 py-0.5 rounded">
              {skill}
            </span>
          ))}
          {queue.skills.length > 3 && (
            <span className="text-xs text-gray-500">+{queue.skills.length - 3}</span>
          )}
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-6">
      {/* Header with Project И Demo Toggle */}
      <div className="bg-white p-6 rounded-lg shadow">
        <div className="flex justify-between items-center mb-4">
          <div>
            <h2 className="text-2xl font-bold">Queue Management Center</h2>
            <p className="text-gray-600">
              Managing {aggregateMetrics.totalQueues} queues across all channels
            </p>
          </div>
          <button
            onClick={() => setShowProjectIDemo(!showProjectIDemo)}
            className={`px-4 py-2 rounded transition-colors ${
              showProjectIDemo 
                ? 'bg-purple-600 text-white' 
                : 'bg-gray-200 hover:bg-gray-300'
            }`}
          >
            {showProjectIDemo ? 'Project И Demo (68 Queues)' : 'Show Project И Demo'}
          </button>
        </div>

        {/* Aggregate Metrics Dashboard */}
        <div className="grid grid-cols-5 gap-4">
          <div className="bg-blue-50 p-4 rounded-lg">
            <div className="text-2xl font-bold text-blue-600">
              {aggregateMetrics.totalVolume.toLocaleString()}
            </div>
            <div className="text-sm text-gray-600">Total Volume</div>
          </div>
          <div className="bg-green-50 p-4 rounded-lg">
            <div className="text-2xl font-bold text-green-600">
              {aggregateMetrics.avgServiceLevel.toFixed(1)}%
            </div>
            <div className="text-sm text-gray-600">Avg Service Level</div>
          </div>
          <div className="bg-purple-50 p-4 rounded-lg">
            <div className="text-2xl font-bold text-purple-600">
              {aggregateMetrics.totalAssigned}
            </div>
            <div className="text-sm text-gray-600">Total Operators</div>
          </div>
          <div className={`p-4 rounded-lg ${
            aggregateMetrics.operatorGap > 0 ? 'bg-red-50' : 'bg-green-50'
          }`}>
            <div className={`text-2xl font-bold ${
              aggregateMetrics.operatorGap > 0 ? 'text-red-600' : 'text-green-600'
            }`}>
              {aggregateMetrics.operatorGap > 0 ? '-' : '+'}{Math.abs(aggregateMetrics.operatorGap)}
            </div>
            <div className="text-sm text-gray-600">Operator Gap</div>
          </div>
          <div className="bg-yellow-50 p-4 rounded-lg">
            <div className="text-2xl font-bold text-yellow-600">
              {aggregateMetrics.criticalQueues.length}
            </div>
            <div className="text-sm text-gray-600">Critical Queues</div>
          </div>
        </div>
      </div>

      {/* Controls and Filters */}
      <div className="bg-white p-4 rounded-lg shadow">
        <div className="flex gap-4 items-center justify-between">
          <div className="flex gap-4">
            <select
              value={filterType}
              onChange={(e) => setFilterType(e.target.value)}
              className="border rounded px-3 py-2"
            >
              <option value="all">All Channels</option>
              <option value="voice">Voice</option>
              <option value="email">Email</option>
              <option value="chat">Chat</option>
              <option value="video">Video</option>
            </select>

            <select
              value={filterPriority}
              onChange={(e) => setFilterPriority(e.target.value)}
              className="border rounded px-3 py-2"
            >
              <option value="all">All Priorities</option>
              <option value="high">High Priority</option>
              <option value="medium">Medium Priority</option>
              <option value="low">Low Priority</option>
            </select>

            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="border rounded px-3 py-2"
            >
              <option value="volume">Sort by Volume</option>
              <option value="serviceLevel">Sort by Service Level</option>
              <option value="gap">Sort by Operator Gap</option>
              <option value="priority">Sort by Priority</option>
            </select>

            <div className="flex gap-2">
              <button
                onClick={() => setViewMode('grid')}
                className={`px-3 py-2 rounded ${
                  viewMode === 'grid' ? 'bg-blue-600 text-white' : 'bg-gray-200'
                }`}
              >
                Grid
              </button>
              <button
                onClick={() => setViewMode('list')}
                className={`px-3 py-2 rounded ${
                  viewMode === 'list' ? 'bg-blue-600 text-white' : 'bg-gray-200'
                }`}
              >
                List
              </button>
            </div>
          </div>

          <div className="flex gap-2">
            {selectedQueues.size > 0 && (
              <>
                <button
                  onClick={handleCreateGroup}
                  className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
                >
                  Create Group ({selectedQueues.size})
                </button>
                <select
                  onChange={(e) => handleBulkPriorityChange(e.target.value as any)}
                  className="border rounded px-3 py-2"
                  defaultValue=""
                >
                  <option value="" disabled>Change Priority</option>
                  <option value="high">High</option>
                  <option value="medium">Medium</option>
                  <option value="low">Low</option>
                </select>
                <button
                  onClick={() => setSelectedQueues(new Set())}
                  className="px-4 py-2 border border-gray-300 rounded hover:bg-gray-50"
                >
                  Clear Selection
                </button>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Channel Distribution Chart */}
      <div className="bg-white p-6 rounded-lg shadow">
        <h3 className="text-lg font-semibold mb-4">Channel Distribution</h3>
        <div className="grid grid-cols-2 gap-6">
          <div className="h-64">
            <Bar
              data={{
                labels: Object.keys(aggregateMetrics.byType),
                datasets: [{
                  label: 'Queue Count',
                  data: Object.values(aggregateMetrics.byType).map((t: any) => t.count),
                  backgroundColor: ['#3B82F6', '#10B981', '#F59E0B', '#8B5CF6']
                }]
              }}
              options={{
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                  legend: { display: false }
                }
              }}
            />
          </div>
          <div className="h-64">
            <Bar
              data={{
                labels: Object.keys(aggregateMetrics.byType),
                datasets: [{
                  label: 'Total Volume',
                  data: Object.values(aggregateMetrics.byType).map((t: any) => t.volume),
                  backgroundColor: ['#93C5FD', '#86EFAC', '#FCD34D', '#C4B5FD']
                }]
              }}
              options={{
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                  legend: { display: false }
                }
              }}
            />
          </div>
        </div>
      </div>

      {/* Queue Grid/List */}
      <div className="bg-white p-6 rounded-lg shadow">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-semibold">
            {showProjectIDemo ? 'Project И - 68 Queues Demo' : 'Active Queues'}
          </h3>
          <span className="text-sm text-gray-600">
            Showing {filteredQueues.length} queues
          </span>
        </div>

        {viewMode === 'grid' ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {filteredQueues.map(queue => (
              <QueueCard key={queue.id} queue={queue} />
            ))}
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b text-left">
                  <th className="p-2">
                    <input
                      type="checkbox"
                      checked={filteredQueues.every(q => selectedQueues.has(q.id))}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setSelectedQueues(new Set(filteredQueues.map(q => q.id)));
                        } else {
                          setSelectedQueues(new Set());
                        }
                      }}
                    />
                  </th>
                  <th className="p-2">Queue Name</th>
                  <th className="p-2">Type</th>
                  <th className="p-2">Priority</th>
                  <th className="p-2">Volume</th>
                  <th className="p-2">AHT</th>
                  <th className="p-2">Service Level</th>
                  <th className="p-2">Operators</th>
                  <th className="p-2">Gap</th>
                </tr>
              </thead>
              <tbody>
                {filteredQueues.map(queue => {
                  const operatorGap = queue.requiredOperators - queue.assignedOperators;
                  return (
                    <tr key={queue.id} className="border-b hover:bg-gray-50">
                      <td className="p-2">
                        <input
                          type="checkbox"
                          checked={selectedQueues.has(queue.id)}
                          onChange={() => handleQueueSelection(queue.id)}
                        />
                      </td>
                      <td className="p-2 font-medium">{queue.name}</td>
                      <td className="p-2">{queue.type}</td>
                      <td className="p-2">
                        <span className={`text-xs px-2 py-1 rounded ${
                          queue.priority === 'high' ? 'bg-red-200 text-red-800' :
                          queue.priority === 'medium' ? 'bg-yellow-200 text-yellow-800' :
                          'bg-gray-200 text-gray-800'
                        }`}>
                          {queue.priority}
                        </span>
                      </td>
                      <td className="p-2">{queue.currentVolume}</td>
                      <td className="p-2">{queue.avgHandleTime}s</td>
                      <td className="p-2">
                        <span className={queue.serviceLevel < queue.targetServiceLevel ? 'text-red-600' : 'text-green-600'}>
                          {queue.serviceLevel.toFixed(0)}%
                        </span>
                      </td>
                      <td className="p-2">{queue.assignedOperators}/{queue.requiredOperators}</td>
                      <td className="p-2">
                        {operatorGap > 0 && (
                          <span className="text-red-600 font-medium">-{operatorGap}</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Queue Groups */}
      {queueGroups.length > 0 && (
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold mb-4">Queue Groups</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {queueGroups.map(group => {
              const groupQueues = queues.filter(q => group.queues.includes(q.id));
              const groupVolume = groupQueues.reduce((sum, q) => sum + q.currentVolume, 0);
              const groupOperators = groupQueues.reduce((sum, q) => sum + q.assignedOperators, 0);
              
              return (
                <div key={group.id} className="border rounded-lg p-4">
                  <div className="flex justify-between items-start mb-2">
                    <h4 className="font-semibold">{group.name}</h4>
                    <span className="text-sm text-gray-500">{group.queues.length} queues</span>
                  </div>
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <div>
                      <span className="text-gray-600">Total Volume:</span>
                      <span className="font-medium ml-1">{groupVolume}</span>
                    </div>
                    <div>
                      <span className="text-gray-600">Total Operators:</span>
                      <span className="font-medium ml-1">{groupOperators}</span>
                    </div>
                  </div>
                  <div className="mt-2 flex flex-wrap gap-1">
                    {groupQueues.slice(0, 3).map(q => (
                      <span key={q.id} className="text-xs bg-gray-200 px-2 py-0.5 rounded">
                        {q.name}
                      </span>
                    ))}
                    {groupQueues.length > 3 && (
                      <span className="text-xs text-gray-500">+{groupQueues.length - 3}</span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
};

export default QueueManager;