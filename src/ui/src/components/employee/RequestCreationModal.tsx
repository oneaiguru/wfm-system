import React, { useState } from 'react';
import { Calendar, Clock, Users, AlertCircle, CheckCircle } from 'lucide-react';

interface RequestCreationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (request: RequestFormData) => void;
  requestType?: 'time_off' | 'sick_leave' | 'vacation' | 'shift_exchange';
}

interface RequestFormData {
  type: 'time_off' | 'sick_leave' | 'vacation' | 'shift_exchange';
  startDate: string;
  endDate: string;
  reason: string;
  description?: string;
  exchangeEmployeeId?: string;
  exchangeDate?: string;
  exchangeTime?: string;
}

// Russian translations per BDD spec
const translations = {
  requestTypes: {
    time_off: 'отгул',
    sick_leave: 'больничный',
    vacation: 'внеочередной отпуск',
    shift_exchange: 'обмен сменами'
  },
  labels: {
    title: 'Создать заявку',
    requestType: 'Тип заявки',
    startDate: 'Дата начала',
    endDate: 'Дата окончания',
    reason: 'Причина',
    description: 'Описание',
    exchangeEmployee: 'Сотрудник для обмена',
    exchangeDate: 'Дата обмена',
    exchangeTime: 'Время обмена',
    submit: 'Создать заявку',
    cancel: 'Отмена'
  },
  placeholders: {
    reason: 'Укажите причину запроса...',
    description: 'Дополнительная информация...'
  }
};

const RequestCreationModal: React.FC<RequestCreationModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  requestType = 'time_off'
}) => {
  const [formData, setFormData] = useState<RequestFormData>({
    type: requestType,
    startDate: '',
    endDate: '',
    reason: '',
    description: '',
    exchangeEmployeeId: '',
    exchangeDate: '',
    exchangeTime: ''
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.startDate) {
      newErrors.startDate = 'Дата начала обязательна';
    }

    if (!formData.endDate && formData.type !== 'shift_exchange') {
      newErrors.endDate = 'Дата окончания обязательна';
    }

    if (!formData.reason.trim()) {
      newErrors.reason = 'Причина обязательна';
    }

    if (formData.type === 'shift_exchange') {
      if (!formData.exchangeEmployeeId) {
        newErrors.exchangeEmployeeId = 'Выберите сотрудника для обмена';
      }
      if (!formData.exchangeDate) {
        newErrors.exchangeDate = 'Дата обмена обязательна';
      }
      if (!formData.exchangeTime) {
        newErrors.exchangeTime = 'Время обмена обязательно';
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) return;

    setIsSubmitting(true);

    try {
      await onSubmit(formData);
      onClose();
      // Reset form
      setFormData({
        type: requestType,
        startDate: '',
        endDate: '',
        reason: '',
        description: '',
        exchangeEmployeeId: '',
        exchangeDate: '',
        exchangeTime: ''
      });
    } catch (error) {
      console.error('Error submitting request:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleInputChange = (field: keyof RequestFormData, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  const getRequestTypeIcon = (type: string) => {
    switch (type) {
      case 'time_off': return <Clock className="h-5 w-5" />;
      case 'sick_leave': return <AlertCircle className="h-5 w-5" />;
      case 'vacation': return <Calendar className="h-5 w-5" />;
      case 'shift_exchange': return <Users className="h-5 w-5" />;
      default: return <Calendar className="h-5 w-5" />;
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full mx-4 max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              {getRequestTypeIcon(formData.type)}
              <h2 className="text-xl font-semibold text-gray-900">
                {translations.labels.title}
              </h2>
            </div>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600"
            >
              ✕
            </button>
          </div>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {/* Request Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {translations.labels.requestType}
            </label>
            <select
              value={formData.type}
              onChange={(e) => handleInputChange('type', e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              data-testid="request-type-select"
            >
              <option value="time_off">{translations.requestTypes.time_off}</option>
              <option value="sick_leave">{translations.requestTypes.sick_leave}</option>
              <option value="vacation">{translations.requestTypes.vacation}</option>
              <option value="shift_exchange">{translations.requestTypes.shift_exchange}</option>
            </select>
          </div>

          {/* Date Range */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                {translations.labels.startDate}
              </label>
              <input
                type="date"
                value={formData.startDate}
                onChange={(e) => handleInputChange('startDate', e.target.value)}
                className={`w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                  errors.startDate ? 'border-red-300' : 'border-gray-300'
                }`}
              />
              {errors.startDate && (
                <p className="mt-1 text-xs text-red-600">{errors.startDate}</p>
              )}
            </div>

            {formData.type !== 'shift_exchange' && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  {translations.labels.endDate}
                </label>
                <input
                  type="date"
                  value={formData.endDate}
                  onChange={(e) => handleInputChange('endDate', e.target.value)}
                  className={`w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                    errors.endDate ? 'border-red-300' : 'border-gray-300'
                  }`}
                />
                {errors.endDate && (
                  <p className="mt-1 text-xs text-red-600">{errors.endDate}</p>
                )}
              </div>
            )}
          </div>

          {/* Shift Exchange Fields */}
          {formData.type === 'shift_exchange' && (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  {translations.labels.exchangeEmployee}
                </label>
                <select
                  value={formData.exchangeEmployeeId}
                  onChange={(e) => handleInputChange('exchangeEmployeeId', e.target.value)}
                  className={`w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                    errors.exchangeEmployeeId ? 'border-red-300' : 'border-gray-300'
                  }`}
                >
                  <option value="">Выберите сотрудника...</option>
                  {/* TODO: Load from API */}
                  <option value="employee1">Иванов И.И.</option>
                  <option value="employee2">Петров П.П.</option>
                  <option value="employee3">Сидоров С.С.</option>
                </select>
                {errors.exchangeEmployeeId && (
                  <p className="mt-1 text-xs text-red-600">{errors.exchangeEmployeeId}</p>
                )}
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    {translations.labels.exchangeDate}
                  </label>
                  <input
                    type="date"
                    value={formData.exchangeDate}
                    onChange={(e) => handleInputChange('exchangeDate', e.target.value)}
                    className={`w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                      errors.exchangeDate ? 'border-red-300' : 'border-gray-300'
                    }`}
                  />
                  {errors.exchangeDate && (
                    <p className="mt-1 text-xs text-red-600">{errors.exchangeDate}</p>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    {translations.labels.exchangeTime}
                  </label>
                  <input
                    type="time"
                    value={formData.exchangeTime}
                    onChange={(e) => handleInputChange('exchangeTime', e.target.value)}
                    className={`w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                      errors.exchangeTime ? 'border-red-300' : 'border-gray-300'
                    }`}
                  />
                  {errors.exchangeTime && (
                    <p className="mt-1 text-xs text-red-600">{errors.exchangeTime}</p>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* Reason */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {translations.labels.reason}
            </label>
            <textarea
              value={formData.reason}
              onChange={(e) => handleInputChange('reason', e.target.value)}
              placeholder={translations.placeholders.reason}
              rows={3}
              className={`w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                errors.reason ? 'border-red-300' : 'border-gray-300'
              }`}
            />
            {errors.reason && (
              <p className="mt-1 text-xs text-red-600">{errors.reason}</p>
            )}
          </div>

          {/* Description */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {translations.labels.description}
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => handleInputChange('description', e.target.value)}
              placeholder={translations.placeholders.description}
              rows={2}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          {/* Action Buttons */}
          <div className="flex justify-end gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200 transition-colors"
            >
              {translations.labels.cancel}
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
            >
              {isSubmitting ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  Создание...
                </>
              ) : (
                <>
                  <CheckCircle className="h-4 w-4" />
                  {translations.labels.submit}
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default RequestCreationModal;