import React, { useState, useEffect } from 'react';

interface ShiftMarketplaceProps {
  currentEmployeeId?: string;
}

interface ShiftOffer {
  id: string;
  employee: {
    id: string;
    name: string;
    position: string;
    team: string;
    avatar?: string;
    rating?: number;
    exchangeCount?: number;
  };
  shift: {
    date: Date;
    startTime: string;
    endTime: string;
    type: 'regular' | 'overtime' | 'training' | 'night' | 'holiday';
    location?: string;
    description?: string;
    duration: number;
  };
  reason?: string;
  wantedInReturn?: string;
  postedAt: Date;
  expiresAt: Date;
  interestCount: number;
  status: 'available' | 'pending' | 'completed' | 'expired';
  interestedEmployees: string[];
  urgency: 'low' | 'normal' | 'high';
}

const ShiftMarketplace: React.FC<ShiftMarketplaceProps> = ({
  currentEmployeeId = '1'
}) => {
  const [offers, setOffers] = useState<ShiftOffer[]>([]);
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [searchTerm, setSearchTerm] = useState('');
  const [filterUrgent, setFilterUrgent] = useState(false);

  // Load offers
  useEffect(() => {
    const loadOffers = async () => {
      setLoading(true);
      
      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 800));
      
      const mockOffers: ShiftOffer[] = [
        {
          id: '1',
          employee: {
            id: 'emp2',
            name: 'Anna Peterson',
            position: 'Customer Service Agent',
            team: 'Customer Support',
            avatar: 'https://images.unsplash.com/photo-1494790108755-2616b31e6752?w=50&h=50&fit=crop&crop=face',
            rating: 4.8,
            exchangeCount: 12
          },
          shift: {
            date: new Date('2025-07-15'),
            startTime: '09:00',
            endTime: '17:00',
            type: 'regular',
            location: 'Main Office',
            description: 'Morning shift - Customer Support',
            duration: 8
          },
          reason: 'Doctor appointment',
          wantedInReturn: 'Any weekend shift or next week',
          postedAt: new Date('2025-07-10T10:30:00'),
          expiresAt: new Date('2025-07-14T23:59:00'),
          interestCount: 3,
          status: 'available',
          interestedEmployees: ['emp3', 'emp4', 'emp5'],
          urgency: 'high'
        },
        {
          id: '2',
          employee: {
            id: 'emp3',
            name: 'Mike Johnson',
            position: 'Technical Support Agent',
            team: 'Technical Support',
            avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=50&h=50&fit=crop&crop=face',
            rating: 4.6,
            exchangeCount: 8
          },
          shift: {
            date: new Date('2025-07-18'),
            startTime: '14:00',
            endTime: '22:00',
            type: 'regular',
            location: 'Remote',
            description: 'Afternoon shift - Technical Support',
            duration: 8
          },
          reason: 'Family event',
          wantedInReturn: 'Morning shift same week',
          postedAt: new Date('2025-07-10T14:15:00'),
          expiresAt: new Date('2025-07-17T12:00:00'),
          interestCount: 1,
          status: 'available',
          interestedEmployees: ['emp6'],
          urgency: 'normal'
        },
        {
          id: '3',
          employee: {
            id: 'emp4',
            name: 'Sarah Williams',
            position: 'Sales Representative',
            team: 'Sales',
            avatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=50&h=50&fit=crop&crop=face',
            rating: 4.9,
            exchangeCount: 15
          },
          shift: {
            date: new Date('2025-07-20'),
            startTime: '10:00',
            endTime: '18:00',
            type: 'overtime',
            location: 'Main Office',
            description: 'Saturday overtime - Sales',
            duration: 8
          },
          reason: 'Weekend plans',
          wantedInReturn: 'Weekday shift with overtime pay',
          postedAt: new Date('2025-07-09T16:45:00'),
          expiresAt: new Date('2025-07-19T18:00:00'),
          interestCount: 5,
          status: 'available',
          interestedEmployees: ['emp1', 'emp7', 'emp8', 'emp9', 'emp10'],
          urgency: 'low'
        }
      ];
      
      setOffers(mockOffers);
      setLoading(false);
    };
    
    loadOffers();
  }, []);

  const getUrgencyColor = (urgency: string) => {
    switch (urgency) {
      case 'high': return 'border-l-red-400 bg-red-50';
      case 'normal': return 'border-l-blue-400 bg-blue-50';
      case 'low': return 'border-l-green-400 bg-green-50';
      default: return 'border-l-gray-400 bg-gray-50';
    }
  };

  const getShiftTypeIcon = (type: string) => {
    switch (type) {
      case 'regular': return '🕐';
      case 'overtime': return '⏰';
      case 'training': return '📚';
      case 'night': return '🌙';
      case 'holiday': return '🎉';
      default: return '📅';
    }
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric'
    });
  };

  const formatPostedTime = (date: Date) => {
    const now = new Date();
    const diffInHours = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60));
    
    if (diffInHours < 1) return 'Just posted';
    if (diffInHours < 24) return `${diffInHours}h ago`;
    return `${Math.floor(diffInHours / 24)}d ago`;
  };

  const handleExpressInterest = (offerId: string) => {
    console.log('Expressing interest in offer:', offerId);
    // In real app, would call API
    setOffers(prev => prev.map(offer => 
      offer.id === offerId 
        ? { 
            ...offer, 
            interestCount: offer.interestCount + 1,
            interestedEmployees: [...offer.interestedEmployees, currentEmployeeId]
          }
        : offer
    ));
  };

  const filteredOffers = offers.filter(offer => {
    const matchesSearch = !searchTerm || 
      offer.employee.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      offer.shift.description?.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesUrgent = !filterUrgent || offer.urgency === 'high';
    
    return matchesSearch && matchesUrgent;
  });

  if (loading) {
    return (
      <div className="p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-300 rounded w-1/3"></div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="h-64 bg-gray-300 rounded-lg"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Shift Exchange Marketplace</h1>
          <p className="text-gray-600">Find and exchange shifts with your colleagues</p>
        </div>
        
        <div className="flex gap-3">
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
            📝 Post New Offer
          </button>
          <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors">
            📋 My Offers
          </button>
        </div>
      </div>

      {/* Filters and Search */}
      <div className="bg-white rounded-lg shadow border p-4">
        <div className="flex flex-wrap items-center gap-4">
          <div className="flex-1 min-w-64">
            <input
              type="text"
              placeholder="Search by name, description..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={filterUrgent}
              onChange={(e) => setFilterUrgent(e.target.checked)}
              className="rounded"
            />
            🚨 Urgent only
          </label>
          
          <div className="flex items-center gap-2">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-2 rounded ${viewMode === 'grid' ? 'bg-blue-100 text-blue-700' : 'text-gray-600'}`}
            >
              ▦
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`p-2 rounded ${viewMode === 'list' ? 'bg-blue-100 text-blue-700' : 'text-gray-600'}`}
            >
              ≡
            </button>
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-lg shadow border">
          <div className="text-2xl font-bold text-blue-600">{filteredOffers.length}</div>
          <div className="text-sm text-gray-600">Available Offers</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow border">
          <div className="text-2xl font-bold text-orange-600">
            {filteredOffers.filter(o => o.urgency === 'high').length}
          </div>
          <div className="text-sm text-gray-600">Urgent Requests</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow border">
          <div className="text-2xl font-bold text-green-600">
            {filteredOffers.reduce((sum, offer) => sum + offer.interestCount, 0)}
          </div>
          <div className="text-sm text-gray-600">Total Interest</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow border">
          <div className="text-2xl font-bold text-purple-600">
            {new Set(filteredOffers.map(o => o.employee.team)).size}
          </div>
          <div className="text-sm text-gray-600">Teams Involved</div>
        </div>
      </div>

      {/* Offers Grid */}
      <div className={`grid gap-4 ${viewMode === 'grid' ? 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3' : 'grid-cols-1'}`}>
        {filteredOffers.map((offer) => (
          <div
            key={offer.id}
            className={`bg-white rounded-lg shadow border hover:shadow-lg transition-shadow border-l-4 ${getUrgencyColor(offer.urgency)}`}
          >
            <div className="p-6">
              {/* Header */}
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-full overflow-hidden bg-gray-200">
                    {offer.employee.avatar ? (
                      <img 
                        src={offer.employee.avatar} 
                        alt={offer.employee.name}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-gray-600 font-semibold">
                        {offer.employee.name.charAt(0)}
                      </div>
                    )}
                  </div>
                  <div>
                    <h3 className="font-semibold text-gray-900">{offer.employee.name}</h3>
                    <p className="text-sm text-gray-600">{offer.employee.position}</p>
                    <div className="flex items-center gap-2 text-xs text-gray-500">
                      <span>⭐ {offer.employee.rating}</span>
                      <span>•</span>
                      <span>{offer.employee.exchangeCount} exchanges</span>
                    </div>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-xs text-gray-500">{formatPostedTime(offer.postedAt)}</div>
                  {offer.urgency === 'high' && (
                    <span className="inline-block mt-1 px-2 py-1 text-xs bg-red-100 text-red-800 rounded">
                      🚨 Urgent
                    </span>
                  )}
                </div>
              </div>

              {/* Shift Details */}
              <div className="mb-4 p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                  <span className="text-lg">{getShiftTypeIcon(offer.shift.type)}</span>
                  <span className="font-medium">{formatDate(offer.shift.date)}</span>
                  <span className="text-gray-600">
                    {offer.shift.startTime} - {offer.shift.endTime}
                  </span>
                </div>
                <p className="text-sm text-gray-600">{offer.shift.description}</p>
                {offer.shift.location && (
                  <p className="text-xs text-gray-500 mt-1">📍 {offer.shift.location}</p>
                )}
              </div>

              {/* Reason & Exchange */}
              <div className="mb-4 space-y-2">
                {offer.reason && (
                  <div>
                    <span className="text-xs font-medium text-gray-600">Reason:</span>
                    <p className="text-sm text-gray-800">{offer.reason}</p>
                  </div>
                )}
                {offer.wantedInReturn && (
                  <div>
                    <span className="text-xs font-medium text-gray-600">Wants in return:</span>
                    <p className="text-sm text-gray-800">{offer.wantedInReturn}</p>
                  </div>
                )}
              </div>

              {/* Interest & Actions */}
              <div className="flex items-center justify-between">
                <div className="text-sm text-gray-600">
                  👥 {offer.interestCount} interested
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => handleExpressInterest(offer.id)}
                    disabled={offer.interestedEmployees.includes(currentEmployeeId)}
                    className={`px-3 py-1 text-sm rounded transition-colors ${
                      offer.interestedEmployees.includes(currentEmployeeId)
                        ? 'bg-green-100 text-green-700 cursor-not-allowed'
                        : 'bg-blue-100 text-blue-700 hover:bg-blue-200'
                    }`}
                  >
                    {offer.interestedEmployees.includes(currentEmployeeId) ? '✓ Interested' : '👋 Express Interest'}
                  </button>
                  <button className="px-3 py-1 text-sm bg-gray-100 text-gray-700 rounded hover:bg-gray-200 transition-colors">
                    💬 Message
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {filteredOffers.length === 0 && (
        <div className="text-center py-12">
          <div className="text-4xl mb-4">🔍</div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No offers found</h3>
          <p className="text-gray-600">Try adjusting your search criteria or check back later.</p>
        </div>
      )}
    </div>
  );
};

export default ShiftMarketplace;