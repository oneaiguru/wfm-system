import React from 'react';
import { CheckCircle, Clock, XCircle, AlertCircle, Users } from 'lucide-react';

interface RequestStatusTrackerProps {
  requestType: 'time_off' | 'sick_leave' | 'vacation' | 'shift_exchange';
  currentStatus: 'created' | 'pending' | 'approved' | 'rejected';
  submittedAt: Date;
  approvedAt?: Date;
  approver?: {
    name: string;
    comments?: string;
  };
  exchangeStatus?: {
    accepted: boolean;
    acceptedBy?: string;
    acceptedAt?: Date;
  };
}

// Status progression per BDD spec
const statusProgression = {
  created: {
    order: 1,
    label: 'Создана',
    description: 'Заявка создана и готова к рассмотрению',
    icon: AlertCircle,
    color: 'text-blue-600',
    bgColor: 'bg-blue-100'
  },
  pending: {
    order: 2,
    label: 'На рассмотрении',
    description: 'Заявка передана руководителю для рассмотрения',
    icon: Clock,
    color: 'text-yellow-600',
    bgColor: 'bg-yellow-100'
  },
  approved: {
    order: 3,
    label: 'Одобрена',
    description: 'Заявка одобрена руководителем',
    icon: CheckCircle,
    color: 'text-green-600',
    bgColor: 'bg-green-100'
  },
  rejected: {
    order: 3,
    label: 'Отклонена',
    description: 'Заявка отклонена руководителем',
    icon: XCircle,
    color: 'text-red-600',
    bgColor: 'bg-red-100'
  }
};

// Russian translations per BDD spec
const translations = {
  statusTitle: 'Статус заявки',
  timeline: 'Хронология',
  submittedAt: 'Подано',
  reviewedAt: 'Рассмотрено',
  approvedBy: 'Одобрил',
  rejectedBy: 'Отклонил',
  comments: 'Комментарии',
  exchangeAccepted: 'Обмен принят',
  exchangeAcceptedBy: 'Принял',
  requestTypes: {
    time_off: 'Отгул',
    sick_leave: 'Больничный',
    vacation: 'Внеочередной отпуск',
    shift_exchange: 'Обмен сменами'
  }
};

const RequestStatusTracker: React.FC<RequestStatusTrackerProps> = ({
  requestType,
  currentStatus,
  submittedAt,
  approvedAt,
  approver,
  exchangeStatus
}) => {
  const getStatusSteps = () => {
    const steps = [
      statusProgression.created,
      statusProgression.pending
    ];

    if (currentStatus === 'approved') {
      steps.push(statusProgression.approved);
    } else if (currentStatus === 'rejected') {
      steps.push(statusProgression.rejected);
    }

    return steps;
  };

  const isStepCompleted = (stepStatus: string) => {
    const currentOrder = statusProgression[currentStatus as keyof typeof statusProgression].order;
    const stepOrder = statusProgression[stepStatus as keyof typeof statusProgression].order;
    
    if (currentStatus === 'rejected' && stepStatus === 'approved') return false;
    if (currentStatus === 'approved' && stepStatus === 'rejected') return false;
    
    return stepOrder <= currentOrder;
  };

  const isStepActive = (stepStatus: string) => {
    return stepStatus === currentStatus;
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('ru-RU', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const steps = getStatusSteps();

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6" data-testid="status-tracker">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">
        {translations.statusTitle}
      </h3>

      {/* Current Status */}
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-2">
          <div className={`p-2 rounded-lg ${statusProgression[currentStatus].bgColor}`}>
            {React.createElement(statusProgression[currentStatus].icon, {
              className: `h-5 w-5 ${statusProgression[currentStatus].color}`
            })}
          </div>
          <div>
            <div className="font-medium text-gray-900">
              {statusProgression[currentStatus].label}
            </div>
            <div className="text-sm text-gray-600">
              {statusProgression[currentStatus].description}
            </div>
          </div>
        </div>
      </div>

      {/* Progress Steps */}
      <div className="mb-6">
        <h4 className="text-sm font-medium text-gray-900 mb-3">
          {translations.timeline}
        </h4>
        
        <div className="space-y-4">
          {steps.map((step, index) => {
            const completed = isStepCompleted(Object.keys(statusProgression).find(key => 
              statusProgression[key as keyof typeof statusProgression] === step
            ) || '');
            const active = isStepActive(Object.keys(statusProgression).find(key => 
              statusProgression[key as keyof typeof statusProgression] === step
            ) || '');
            
            return (
              <div key={index} className="flex items-start gap-3">
                <div className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center ${
                  completed 
                    ? active 
                      ? step.bgColor 
                      : 'bg-gray-100'
                    : 'bg-gray-50 border border-gray-200'
                }`}>
                  {React.createElement(step.icon, {
                    className: `h-4 w-4 ${
                      completed 
                        ? active 
                          ? step.color 
                          : 'text-gray-400'
                        : 'text-gray-300'
                    }`
                  })}
                </div>
                
                <div className="flex-1">
                  <div className={`font-medium ${
                    completed 
                      ? active 
                        ? 'text-gray-900' 
                        : 'text-gray-600'
                      : 'text-gray-400'
                  }`}>
                    {step.label}
                  </div>
                  <div className="text-sm text-gray-500">
                    {step.description}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Timeline Details */}
      <div className="border-t border-gray-200 pt-4">
        <div className="space-y-3">
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600">{translations.submittedAt}:</span>
            <span className="text-sm text-gray-900">{formatDate(submittedAt)}</span>
          </div>
          
          {approvedAt && (
            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600">
                {currentStatus === 'approved' ? translations.reviewedAt : translations.reviewedAt}:
              </span>
              <span className="text-sm text-gray-900">{formatDate(approvedAt)}</span>
            </div>
          )}
          
          {approver && (
            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600">
                {currentStatus === 'approved' ? translations.approvedBy : translations.rejectedBy}:
              </span>
              <span className="text-sm text-gray-900">{approver.name}</span>
            </div>
          )}
          
          {approver?.comments && (
            <div>
              <span className="text-sm text-gray-600 block mb-1">{translations.comments}:</span>
              <div className="text-sm text-gray-900 bg-gray-50 p-2 rounded">
                {approver.comments}
              </div>
            </div>
          )}
          
          {/* Shift Exchange Status */}
          {requestType === 'shift_exchange' && exchangeStatus && (
            <div className="mt-4 p-3 bg-blue-50 rounded-lg">
              <div className="flex items-center gap-2 mb-2">
                <Users className="h-4 w-4 text-blue-600" />
                <span className="text-sm font-medium text-blue-900">
                  Статус обмена сменами
                </span>
              </div>
              
              {exchangeStatus.accepted && (
                <div className="space-y-2">
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-blue-600">{translations.exchangeAccepted}:</span>
                    <span className="text-sm text-blue-900">
                      {exchangeStatus.acceptedAt ? formatDate(exchangeStatus.acceptedAt) : 'Да'}
                    </span>
                  </div>
                  
                  {exchangeStatus.acceptedBy && (
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-blue-600">{translations.exchangeAcceptedBy}:</span>
                      <span className="text-sm text-blue-900">{exchangeStatus.acceptedBy}</span>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default RequestStatusTracker;