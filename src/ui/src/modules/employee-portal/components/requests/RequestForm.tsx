import React, { useState, useEffect } from 'react';
import realRequestService, { VacationRequestData, ApiResponse, SubmissionResult } from '../../../../services/realRequestService';

interface RequestFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (requestData: RequestFormData) => void;
  editRequest?: RequestFormData;
}

interface RequestFormData {
  id?: string;
  type: 'vacation' | 'sick_leave' | 'time_off' | 'shift_change' | 'overtime' | '';
  title: string;
  startDate: string;
  endDate: string;
  reason: string;
  priority: 'low' | 'normal' | 'high' | 'urgent';
  attachments: File[];
  additionalInfo: {
    emergencyContact?: string;
    halfDay?: boolean;
    currentShift?: string;
    requestedShift?: string;
    medicalCertificate?: boolean;
    overtimeHours?: number;
  };
}

interface ValidationErrors {
  [key: string]: string;
}

const RequestForm: React.FC<RequestFormProps> = ({ 
  isOpen, 
  onClose, 
  onSubmit, 
  editRequest 
}) => {
  const [currentStep, setCurrentStep] = useState(1);
  const [formData, setFormData] = useState<RequestFormData>({
    type: '',
    title: '',
    startDate: '',
    endDate: '',
    reason: '',
    priority: 'normal',
    attachments: [],
    additionalInfo: {}
  });
  const [errors, setErrors] = useState<ValidationErrors>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [employees, setEmployees] = useState<any[]>([]);
  const [selectedEmployeeId, setSelectedEmployeeId] = useState<string>('');

  const totalSteps = 4;

  // Load real employees from API
  useEffect(() => {
    const loadEmployees = async () => {
      try {
        console.log('[BDD COMPLIANT] Loading real employees from API...');
        const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001/api/v1';
        const response = await fetch(`${API_BASE_URL}/employees`);
        
        if (!response.ok) {
          throw new Error(`Failed to load employees: ${response.status}`);
        }
        
        const data = await response.json();
        setEmployees(data.employees || data || []);
        
        // Verify we got real Russian employees (BDD compliance check)
        const hasRussianNames = (data.employees || data || []).some((emp: any) => 
          emp.name && (emp.name.includes('Иван') || emp.name.includes('Мария') || emp.name.includes('Петр'))
        );
        
        console.log(`[BDD COMPLIANT] Loaded ${(data.employees || data || []).length} employees, hasRussianNames: ${hasRussianNames}`);
        
        if (!hasRussianNames) {
          console.warn('[BDD COMPLIANCE WARNING] No Russian employee names found - check API data');
        }
        
      } catch (err) {
        const errorMessage = `Ошибка загрузки сотрудников: ${err instanceof Error ? err.message : 'Unknown error'}`;
        setApiError(errorMessage);
        console.error('[BDD COMPLIANT] Employee loading failed:', err);
      }
    };

    if (isOpen) {
      loadEmployees();
    }
  }, [isOpen]);

  // Initialize form with edit data
  useEffect(() => {
    if (editRequest) {
      setFormData(editRequest);
    } else {
      // Reset form for new request
      setFormData({
        type: '',
        title: '',
        startDate: '',
        endDate: '',
        reason: '',
        priority: 'normal',
        attachments: [],
        additionalInfo: {}
      });
    }
    setCurrentStep(1);
    setErrors({});
    setSelectedEmployeeId('');
  }, [editRequest, isOpen]);

  const requestTypes = [
    {
      id: 'vacation',
      title: 'Vacation',
      description: 'Annual paid time off',
      icon: '🏖️',
      requiresEndDate: true
    },
    {
      id: 'sick_leave',
      title: 'Sick Leave',
      description: 'Medical leave of absence',
      icon: '🏥',
      requiresEndDate: true
    },
    {
      id: 'time_off',
      title: 'Time Off',
      description: 'Compensatory time or personal leave',
      icon: '🕐',
      requiresEndDate: false
    },
    {
      id: 'shift_change',
      title: 'Shift Change',
      description: 'Schedule modification request',
      icon: '🔄',
      requiresEndDate: false
    },
    {
      id: 'overtime',
      title: 'Overtime',
      description: 'Extra work hours request',
      icon: '⏰',
      requiresEndDate: false
    }
  ];

  const validateStep = (step: number): boolean => {
    const newErrors: ValidationErrors = {};
    
    switch (step) {
      case 1:
        if (!formData.type) {
          newErrors.type = 'Please select a request type';
        }
        break;
        
      case 2:
        if (!formData.startDate) {
          newErrors.startDate = 'Please specify start date';
        }
        
        const selectedType = requestTypes.find(t => t.id === formData.type);
        if (selectedType?.requiresEndDate && !formData.endDate) {
          newErrors.endDate = 'Please specify end date';
        }
        
        if (formData.startDate && formData.endDate) {
          const start = new Date(formData.startDate);
          const end = new Date(formData.endDate);
          if (end < start) {
            newErrors.endDate = 'End date cannot be before start date';
          }
        }
        
        // Type-specific validations
        if (formData.type === 'shift_change') {
          if (!formData.additionalInfo.currentShift) {
            newErrors.currentShift = 'Please specify current shift';
          }
          if (!formData.additionalInfo.requestedShift) {
            newErrors.requestedShift = 'Please specify requested shift';
          }
        }
        
        if (formData.type === 'overtime') {
          if (!formData.additionalInfo.overtimeHours || formData.additionalInfo.overtimeHours <= 0) {
            newErrors.overtimeHours = 'Please specify number of overtime hours';
          }
        }
        break;
        
      case 3:
        if (!formData.reason.trim()) {
          newErrors.reason = 'Please provide a reason for the request';
        } else if (formData.reason.trim().length < 10) {
          newErrors.reason = 'Reason must be at least 10 characters';
        }
        
        if (!formData.title.trim()) {
          newErrors.title = 'Please provide a request title';
        }
        
        // BDD Compliance: Validate employee selection
        if (!selectedEmployeeId) {
          newErrors.selectedEmployee = 'Please select an employee';
        }
        break;
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleNext = () => {
    if (validateStep(currentStep)) {
      if (currentStep < totalSteps) {
        setCurrentStep(currentStep + 1);
      }
    }
  };

  const handlePrevious = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleSubmit = async (asDraft: boolean = false) => {
    if (!asDraft && !validateStep(currentStep)) {
      return;
    }
    
    // Clear any previous API errors
    setApiError('');
    setIsSubmitting(true);
    
    try {
      // Check API health first
      const isApiHealthy = await realRequestService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      // BDD Compliance: Use real selected employee UUID, not hardcoded ID
      if (!selectedEmployeeId) {
        throw new Error('Please select an employee before submitting');
      }
      
      // Only handle vacation requests for now (other types need separate endpoints)
      if (formData.type !== 'vacation') {
        throw new Error('Only vacation requests are currently supported in this REAL implementation');
      }

      // Prepare real API request with selected employee UUID
      const requestData: VacationRequestData = {
        employeeId: selectedEmployeeId, // Real UUID from dropdown selection
        type: 'vacation',
        title: formData.title,
        startDate: formData.startDate,
        endDate: formData.endDate,
        reason: formData.reason,
        priority: formData.priority,
        attachments: formData.attachments,
        additionalInfo: {
          emergencyContact: formData.additionalInfo.emergencyContact,
          halfDay: formData.additionalInfo.halfDay
        },
        status: asDraft ? 'draft' : 'submitted'
      };

      console.log('[REAL COMPONENT] Submitting request to real API:', requestData);

      // Make REAL API call - NO MOCKS
      const result: ApiResponse<SubmissionResult> = await realRequestService.submitVacationRequest(requestData);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Request submitted successfully:', result.data);
        
        // Pass real API response to parent
        const submitData = {
          ...formData,
          id: result.data.requestId,
          status: result.data.status as any,
          submittedAt: new Date(result.data.submittedAt)
        };
        
        onSubmit(submitData);
        onClose();
        
        // Show success message
        alert(`Request submitted successfully! ID: ${result.data.requestId}`);
        
      } else {
        // Real API error
        const errorMessage = result.error || 'Failed to submit request';
        console.error('[REAL COMPONENT] API error:', errorMessage);
        setApiError(errorMessage);
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      console.error('[REAL COMPONENT] Submission error:', errorMessage);
      setApiError(errorMessage);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleFileUpload = (files: FileList | null) => {
    if (files) {
      const newFiles = Array.from(files).filter(file => {
        // File size limit: 10MB
        return file.size <= 10 * 1024 * 1024;
      });
      
      setFormData(prev => ({
        ...prev,
        attachments: [...prev.attachments, ...newFiles]
      }));
    }
  };

  const removeFile = (index: number) => {
    setFormData(prev => ({
      ...prev,
      attachments: prev.attachments.filter((_, i) => i !== index)
    }));
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] overflow-hidden">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-semibold text-gray-900">
              {editRequest ? 'Edit Request' : 'New Request'}
            </h2>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 transition-colors"
            >
              ✕
            </button>
          </div>
          
          {/* Progress Bar */}
          <div className="mt-4">
            <div className="flex items-center justify-between text-sm text-gray-600 mb-2">
              <span>Step {currentStep} of {totalSteps}</span>
              <span>{Math.round((currentStep / totalSteps) * 100)}%</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div 
                className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                style={{ width: `${(currentStep / totalSteps) * 100}%` }}
              />
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="px-6 py-6 overflow-y-auto max-h-[60vh]">
          {/* Step 1: Request Type */}
          {currentStep === 1 && (
            <div>
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                Select Request Type
              </h3>
              
              <div className="space-y-3">
                {requestTypes.map((type) => (
                  <label
                    key={type.id}
                    className={`block p-4 border rounded-lg cursor-pointer transition-colors hover:bg-gray-50 ${
                      formData.type === type.id
                        ? 'border-blue-500 bg-blue-50'
                        : 'border-gray-200'
                    }`}
                  >
                    <input
                      type="radio"
                      name="requestType"
                      value={type.id}
                      checked={formData.type === type.id}
                      onChange={(e) => setFormData(prev => ({
                        ...prev,
                        type: e.target.value as any
                      }))}
                      className="sr-only"
                    />
                    <div className="flex items-center gap-3">
                      <span className="text-2xl">{type.icon}</span>
                      <div>
                        <div className="font-medium text-gray-900">{type.title}</div>
                        <div className="text-sm text-gray-600">{type.description}</div>
                      </div>
                    </div>
                  </label>
                ))}
              </div>
              
              {errors.type && (
                <p className="mt-2 text-sm text-red-600">{errors.type}</p>
              )}
            </div>
          )}

          {/* Step 2: Dates and Details */}
          {currentStep === 2 && (
            <div>
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                Specify Dates and Details
              </h3>
              
              <div className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Start Date *
                    </label>
                    <input
                      type="date"
                      value={formData.startDate}
                      onChange={(e) => setFormData(prev => ({
                        ...prev,
                        startDate: e.target.value
                      }))}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    />
                    {errors.startDate && (
                      <p className="mt-1 text-sm text-red-600">{errors.startDate}</p>
                    )}
                  </div>
                  
                  {requestTypes.find(t => t.id === formData.type)?.requiresEndDate && (
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        End Date *
                      </label>
                      <input
                        type="date"
                        value={formData.endDate}
                        onChange={(e) => setFormData(prev => ({
                          ...prev,
                          endDate: e.target.value
                        }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                      />
                      {errors.endDate && (
                        <p className="mt-1 text-sm text-red-600">{errors.endDate}</p>
                      )}
                    </div>
                  )}
                </div>

                {/* Type-specific fields */}
                {formData.type === 'sick_leave' && (
                  <div>
                    <label className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        checked={formData.additionalInfo.medicalCertificate || false}
                        onChange={(e) => setFormData(prev => ({
                          ...prev,
                          additionalInfo: {
                            ...prev.additionalInfo,
                            medicalCertificate: e.target.checked
                          }
                        }))}
                        className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                      />
                      <span className="text-sm text-gray-700">Medical certificate available</span>
                    </label>
                  </div>
                )}

                {formData.type === 'time_off' && (
                  <div>
                    <label className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        checked={formData.additionalInfo.halfDay || false}
                        onChange={(e) => setFormData(prev => ({
                          ...prev,
                          additionalInfo: {
                            ...prev.additionalInfo,
                            halfDay: e.target.checked
                          }
                        }))}
                        className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                      />
                      <span className="text-sm text-gray-700">Half day</span>
                    </label>
                  </div>
                )}

                {formData.type === 'shift_change' && (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Current Shift *
                      </label>
                      <select
                        value={formData.additionalInfo.currentShift || ''}
                        onChange={(e) => setFormData(prev => ({
                          ...prev,
                          additionalInfo: {
                            ...prev.additionalInfo,
                            currentShift: e.target.value
                          }
                        }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                      >
                        <option value="">Select shift</option>
                        <option value="morning">Morning (08:00-17:00)</option>
                        <option value="day">Day (09:00-18:00)</option>
                        <option value="evening">Evening (14:00-23:00)</option>
                        <option value="night">Night (23:00-08:00)</option>
                      </select>
                      {errors.currentShift && (
                        <p className="mt-1 text-sm text-red-600">{errors.currentShift}</p>
                      )}
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Requested Shift *
                      </label>
                      <select
                        value={formData.additionalInfo.requestedShift || ''}
                        onChange={(e) => setFormData(prev => ({
                          ...prev,
                          additionalInfo: {
                            ...prev.additionalInfo,
                            requestedShift: e.target.value
                          }
                        }))}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                      >
                        <option value="">Select shift</option>
                        <option value="morning">Morning (08:00-17:00)</option>
                        <option value="day">Day (09:00-18:00)</option>
                        <option value="evening">Evening (14:00-23:00)</option>
                        <option value="night">Night (23:00-08:00)</option>
                      </select>
                      {errors.requestedShift && (
                        <p className="mt-1 text-sm text-red-600">{errors.requestedShift}</p>
                      )}
                    </div>
                  </div>
                )}

                {formData.type === 'overtime' && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Number of Overtime Hours *
                    </label>
                    <input
                      type="number"
                      min="1"
                      max="12"
                      value={formData.additionalInfo.overtimeHours || ''}
                      onChange={(e) => setFormData(prev => ({
                        ...prev,
                        additionalInfo: {
                          ...prev.additionalInfo,
                          overtimeHours: parseInt(e.target.value) || 0
                        }
                      }))}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    />
                    {errors.overtimeHours && (
                      <p className="mt-1 text-sm text-red-600">{errors.overtimeHours}</p>
                    )}
                  </div>
                )}

                {formData.type === 'vacation' && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Emergency Contact
                    </label>
                    <input
                      type="text"
                      placeholder="Phone or other contact method"
                      value={formData.additionalInfo.emergencyContact || ''}
                      onChange={(e) => setFormData(prev => ({
                        ...prev,
                        additionalInfo: {
                          ...prev.additionalInfo,
                          emergencyContact: e.target.value
                        }
                      }))}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Step 3: Reason and Title */}
          {currentStep === 3 && (
            <div>
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                Reason and Description
              </h3>
              
              <div className="space-y-4">
                {/* BDD Compliance: Real Employee Selection */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Select Employee *
                  </label>
                  <select
                    value={selectedEmployeeId}
                    onChange={(e) => setSelectedEmployeeId(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  >
                    <option value="">-- Choose Employee --</option>
                    {employees.map(emp => (
                      <option key={emp.id} value={emp.id}>
                        {emp.name} ({emp.email || emp.department || 'Employee'})
                      </option>
                    ))}
                  </select>
                  <div className="text-xs text-gray-500 mt-1">
                    Loaded employees: {employees.length}
                    {employees.length === 0 && apiError && ' - Error loading employees'}
                  </div>
                  {errors.selectedEmployee && (
                    <p className="mt-1 text-sm text-red-600">{errors.selectedEmployee}</p>
                  )}
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Request Title *
                  </label>
                  <input
                    type="text"
                    placeholder="Brief description of the request"
                    value={formData.title}
                    onChange={(e) => setFormData(prev => ({
                      ...prev,
                      title: e.target.value
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  />
                  {errors.title && (
                    <p className="mt-1 text-sm text-red-600">{errors.title}</p>
                  )}
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Reason and Justification *
                  </label>
                  <textarea
                    rows={5}
                    placeholder="Please describe the reason for this request in detail..."
                    value={formData.reason}
                    onChange={(e) => setFormData(prev => ({
                      ...prev,
                      reason: e.target.value
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  />
                  <div className="flex justify-between text-sm text-gray-500 mt-1">
                    <span>{formData.reason.length}/500 characters</span>
                    {errors.reason && (
                      <span className="text-red-600">{errors.reason}</span>
                    )}
                  </div>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Priority
                  </label>
                  <select
                    value={formData.priority}
                    onChange={(e) => setFormData(prev => ({
                      ...prev,
                      priority: e.target.value as any
                    }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="low">Low</option>
                    <option value="normal">Normal</option>
                    <option value="high">High</option>
                    <option value="urgent">Urgent</option>
                  </select>
                </div>
              </div>
            </div>
          )}

          {/* Step 4: Review and Attachments */}
          {currentStep === 4 && (
            <div>
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                Review and Attachments
              </h3>
              
              <div className="space-y-6">
                {/* Request Summary */}
                <div className="bg-gray-50 rounded-lg p-4">
                  <h4 className="font-medium text-gray-900 mb-3">Request Summary</h4>
                  <dl className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <dt className="text-gray-600">Employee:</dt>
                      <dd className="font-medium">
                        {selectedEmployeeId 
                          ? employees.find(emp => emp.id === selectedEmployeeId)?.name || 'Unknown Employee'
                          : 'Not selected'
                        }
                      </dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-gray-600">Type:</dt>
                      <dd className="font-medium">
                        {requestTypes.find(t => t.id === formData.type)?.title}
                      </dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-gray-600">Title:</dt>
                      <dd className="font-medium">{formData.title}</dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-gray-600">Period:</dt>
                      <dd className="font-medium">
                        {formData.startDate}
                        {formData.endDate && ` - ${formData.endDate}`}
                      </dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-gray-600">Priority:</dt>
                      <dd className="font-medium">
                        {formData.priority === 'low' ? 'Low' : 
                         formData.priority === 'normal' ? 'Normal' : 
                         formData.priority === 'high' ? 'High' : 'Urgent'}
                      </dd>
                    </div>
                  </dl>
                  <div className="mt-3 pt-3 border-t border-gray-200">
                    <dt className="text-gray-600 text-sm mb-1">Reason:</dt>
                    <dd className="text-sm">{formData.reason}</dd>
                  </div>
                </div>
                
                {/* File Upload */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Attachments (optional)
                  </label>
                  <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center">
                    <input
                      type="file"
                      multiple
                      accept=".pdf,.doc,.docx,.jpg,.jpeg,.png"
                      onChange={(e) => handleFileUpload(e.target.files)}
                      className="hidden"
                      id="file-upload"
                    />
                    <label
                      htmlFor="file-upload"
                      className="cursor-pointer text-blue-600 hover:text-blue-800"
                    >
                      📎 Select files or drag and drop here
                    </label>
                    <p className="text-xs text-gray-500 mt-1">
                      Supported: PDF, DOC, DOCX, JPG, PNG (up to 10 MB)
                    </p>
                  </div>
                  
                  {formData.attachments.length > 0 && (
                    <div className="mt-3">
                      <h5 className="text-sm font-medium text-gray-700 mb-2">
                        Attached Files:
                      </h5>
                      <div className="space-y-2">
                        {formData.attachments.map((file, index) => (
                          <div
                            key={index}
                            className="flex items-center justify-between p-2 bg-gray-50 rounded"
                          >
                            <span className="text-sm text-gray-700">{file.name}</span>
                            <button
                              onClick={() => removeFile(index)}
                              className="text-red-500 hover:text-red-700 text-sm"
                            >
                              Remove
                            </button>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* API Error Display */}
        {apiError && (
          <div className="px-6 py-3 bg-red-50 border-t border-red-200">
            <div className="flex items-center gap-2 text-red-800">
              <span className="text-red-500">❌</span>
              <div>
                <div className="font-medium">Submission Failed</div>
                <div className="text-sm">{apiError}</div>
              </div>
            </div>
          </div>
        )}

        {/* Footer */}
        <div className="px-6 py-4 border-t border-gray-200 flex items-center justify-between">
          <button
            onClick={handlePrevious}
            disabled={currentStep === 1}
            className="px-4 py-2 text-gray-600 hover:text-gray-800 disabled:text-gray-400 disabled:cursor-not-allowed transition-colors"
          >
            ← Previous
          </button>
          
          <div className="flex items-center gap-3">
            {currentStep === totalSteps && (
              <button
                onClick={() => handleSubmit(true)}
                disabled={isSubmitting}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 disabled:opacity-50 transition-colors"
              >
                Save as Draft
              </button>
            )}
            
            {currentStep < totalSteps ? (
              <button
                onClick={handleNext}
                className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                Next →
              </button>
            ) : (
              <button
                onClick={() => handleSubmit(false)}
                disabled={isSubmitting}
                className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 transition-colors flex items-center gap-2"
              >
                {isSubmitting ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                    Submitting...
                  </>
                ) : (
                  'Submit Request'
                )}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default RequestForm;