import React, { useState } from 'react';
import { Users, Clock, MapPin, MessageSquare, Star } from 'lucide-react';

interface Employee {
  id: string;
  name: string;
}

interface ShiftOffer {
  id: string;
  employeeName: string;
  date: string;
  startTime: string;
  endTime: string;
  shiftType: string;
  location: string;
  reason: string;
  rating: number;
  interests: number;
}

interface ShiftMarketplaceProps {
  employee: Employee;
  className?: string;
}

const ShiftMarketplace: React.FC<ShiftMarketplaceProps> = ({ employee, className = '' }) => {
  const [offers] = useState<ShiftOffer[]>([
    {
      id: '1',
      employeeName: 'Sarah Johnson',
      date: '2024-12-20',
      startTime: '09:00',
      endTime: '17:00',
      shiftType: 'Day Shift',
      location: 'Floor 3',
      reason: 'Family appointment',
      rating: 4.8,
      interests: 3
    },
    {
      id: '2',
      employeeName: 'Mike Chen',
      date: '2024-12-22',
      startTime: '14:00',
      endTime: '22:00',
      shiftType: 'Evening Shift',
      location: 'Floor 2',
      reason: 'Personal matter',
      rating: 4.6,
      interests: 2
    }
  ]);

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-900">Shift Marketplace</h2>
        <button className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors">
          Offer My Shift
        </button>
      </div>

      {/* Available Shifts */}
      <div className="grid gap-4">
        {offers.map(offer => (
          <div key={offer.id} className="bg-white p-6 rounded-lg border hover:border-blue-300 transition-colors">
            <div className="flex items-start justify-between">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                  <Users className="w-6 h-6 text-blue-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900">{offer.employeeName}</h3>
                  <div className="flex items-center gap-2 mt-1">
                    <Star className="w-4 h-4 text-yellow-500 fill-current" />
                    <span className="text-sm text-gray-600">{offer.rating}</span>
                  </div>
                  <p className="text-sm text-gray-600 mt-2">{offer.reason}</p>
                </div>
              </div>
              <div className="text-right">
                <div className="text-sm text-gray-500">
                  {new Date(offer.date).toLocaleDateString()}
                </div>
                <div className="font-medium text-gray-900">
                  {offer.startTime} - {offer.endTime}
                </div>
                <div className="text-sm text-gray-600">{offer.shiftType}</div>
              </div>
            </div>
            
            <div className="mt-4 flex items-center justify-between">
              <div className="flex items-center gap-4 text-sm text-gray-600">
                <div className="flex items-center gap-1">
                  <MapPin className="w-4 h-4" />
                  {offer.location}
                </div>
                <div className="flex items-center gap-1">
                  <MessageSquare className="w-4 h-4" />
                  {offer.interests} interested
                </div>
              </div>
              <div className="flex items-center gap-2">
                <button className="px-3 py-1 text-blue-600 hover:text-blue-800 text-sm">
                  Message
                </button>
                <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm">
                  Express Interest
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ShiftMarketplace;