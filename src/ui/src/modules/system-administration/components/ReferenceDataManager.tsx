import React, { useState, useEffect } from 'react';
import {
  Database,
  Plus,
  Search,
  Filter,
  Download,
  Upload,
  Edit3,
  Trash2,
  Save,
  X,
  RefreshCw,
  AlertCircle,
  CheckCircle,
  Eye,
  BarChart3,
  Sync,
  FolderPlus,
  FileText,
  Settings,
  Tag,
  Calendar,
  User,
  Activity
} from 'lucide-react';
import realReferenceDataService, {
  ReferenceDataItem,
  ReferenceDataCategory,
  ReferenceDataValidationResult
} from '../../../services/realReferenceDataService';

const ReferenceDataManager: React.FC = () => {
  const [categories, setCategories] = useState<ReferenceDataCategory[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [referenceData, setReferenceData] = useState<ReferenceDataItem[]>([]);
  const [filteredData, setFilteredData] = useState<ReferenceDataItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [apiError, setApiError] = useState<string>('');
  const [saveSuccess, setSaveSuccess] = useState(false);
  
  const [searchTerm, setSearchTerm] = useState('');
  const [filterActive, setFilterActive] = useState<boolean | undefined>(undefined);
  const [selectedItems, setSelectedItems] = useState<Set<string>>(new Set());
  
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showCategoryModal, setShowCategoryModal] = useState(false);
  const [editingItem, setEditingItem] = useState<ReferenceDataItem | null>(null);
  const [validationErrors, setValidationErrors] = useState<Array<{ field: string; message: string }>>([]);
  
  const [newItem, setNewItem] = useState<Partial<ReferenceDataItem>>({
    category: '',
    key: '',
    value: '',
    displayName: '',
    description: '',
    dataType: 'string',
    isSystemManaged: false,
    isActive: true,
    validationRules: {},
    metadata: { tags: [] }
  });

  const [newCategory, setNewCategory] = useState<Partial<ReferenceDataCategory>>({
    name: '',
    description: '',
    isSystemCategory: false
  });

  const dataTypes = [
    { value: 'string', label: 'Text' },
    { value: 'number', label: 'Number' },
    { value: 'boolean', label: 'Boolean' },
    { value: 'array', label: 'Array' },
    { value: 'object', label: 'Object' }
  ];

  useEffect(() => {
    loadCategories();
  }, []);

  useEffect(() => {
    if (selectedCategory) {
      loadReferenceData(selectedCategory);
    }
  }, [selectedCategory]);

  useEffect(() => {
    // Filter data based on search and filters
    let filtered = referenceData;

    if (searchTerm) {
      filtered = filtered.filter(item =>
        item.key.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.displayName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        JSON.stringify(item.value).toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (filterActive !== undefined) {
      filtered = filtered.filter(item => item.isActive === filterActive);
    }

    setFilteredData(filtered);
  }, [referenceData, searchTerm, filterActive]);

  const loadCategories = async () => {
    setApiError('');
    
    try {
      // Check API health first
      const isApiHealthy = await realReferenceDataService.checkApiHealth();
      if (!isApiHealthy) {
        throw new Error('API server is not available. Please try again later.');
      }

      const result = await realReferenceDataService.getReferenceDataCategories();
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Loaded reference data categories:', result.data);
        setCategories(result.data);
        
        // Select first category by default
        if (result.data.length > 0 && !selectedCategory) {
          setSelectedCategory(result.data[0].id);
        }
      } else {
        setApiError(result.error || 'Failed to load categories');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to load categories:', error);
    }
  };

  const loadReferenceData = async (category: string) => {
    setLoading(true);
    setApiError('');
    
    try {
      const result = await realReferenceDataService.getReferenceDataByCategory(category);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Loaded reference data:', result.data);
        setReferenceData(result.data);
      } else {
        setApiError(result.error || 'Failed to load reference data');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to load reference data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateItem = async () => {
    setSaving(true);
    setApiError('');
    setValidationErrors([]);
    
    try {
      // Validate item first
      const validationResult = await realReferenceDataService.validateReferenceDataItem({
        ...newItem,
        category: selectedCategory
      });
      
      if (!validationResult.success) {
        throw new Error(validationResult.error || 'Validation failed');
      }
      
      if (validationResult.data && !validationResult.data.valid) {
        setValidationErrors(validationResult.data.errors);
        return;
      }

      // Create item
      const result = await realReferenceDataService.createReferenceDataItem({
        ...newItem,
        category: selectedCategory
      } as any);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Item created successfully:', result.data);
        await loadReferenceData(selectedCategory);
        setShowCreateModal(false);
        setNewItem({
          category: '',
          key: '',
          value: '',
          displayName: '',
          description: '',
          dataType: 'string',
          isSystemManaged: false,
          isActive: true,
          validationRules: {},
          metadata: { tags: [] }
        });
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to create item');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Creation failed';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to create item:', error);
    } finally {
      setSaving(false);
    }
  };

  const handleUpdateItem = async () => {
    if (!editingItem) return;
    
    setSaving(true);
    setApiError('');
    setValidationErrors([]);
    
    try {
      // Validate item first
      const validationResult = await realReferenceDataService.validateReferenceDataItem(editingItem);
      
      if (!validationResult.success) {
        throw new Error(validationResult.error || 'Validation failed');
      }
      
      if (validationResult.data && !validationResult.data.valid) {
        setValidationErrors(validationResult.data.errors);
        return;
      }

      // Update item
      const result = await realReferenceDataService.updateReferenceDataItem(editingItem.id, editingItem);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Item updated successfully:', result.data);
        await loadReferenceData(selectedCategory);
        setShowEditModal(false);
        setEditingItem(null);
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to update item');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Update failed';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to update item:', error);
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteItem = async (id: string) => {
    if (!confirm('Are you sure you want to delete this item?')) return;
    
    setApiError('');
    
    try {
      const result = await realReferenceDataService.deleteReferenceDataItem(id);
      
      if (result.success) {
        console.log('[REAL COMPONENT] Item deleted successfully');
        await loadReferenceData(selectedCategory);
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to delete item');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Delete failed';
      setApiError(errorMessage);
    }
  };

  const handleBulkDelete = async () => {
    if (selectedItems.size === 0) return;
    if (!confirm(`Are you sure you want to delete ${selectedItems.size} items?`)) return;
    
    setApiError('');
    
    try {
      const result = await realReferenceDataService.bulkDeleteReferenceData(Array.from(selectedItems));
      
      if (result.success) {
        console.log('[REAL COMPONENT] Bulk delete completed:', result.data);
        await loadReferenceData(selectedCategory);
        setSelectedItems(new Set());
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to delete items');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Bulk delete failed';
      setApiError(errorMessage);
    }
  };

  const handleCreateCategory = async () => {
    setSaving(true);
    setApiError('');
    
    try {
      const result = await realReferenceDataService.createReferenceDataCategory(newCategory as any);
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Category created successfully:', result.data);
        await loadCategories();
        setShowCategoryModal(false);
        setNewCategory({
          name: '',
          description: '',
          isSystemCategory: false
        });
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to create category');
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Category creation failed';
      setApiError(errorMessage);
      console.error('[REAL COMPONENT] Failed to create category:', error);
    } finally {
      setSaving(false);
    }
  };

  const handleExport = async () => {
    try {
      const result = await realReferenceDataService.exportReferenceData(selectedCategory, 'csv');
      
      if (result.success && result.data) {
        // Create download link
        const url = window.URL.createObjectURL(result.data);
        const a = document.createElement('a');
        a.href = url;
        a.download = `reference-data-${selectedCategory}-${new Date().toISOString().split('T')[0]}.csv`;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
        
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      } else {
        setApiError(result.error || 'Failed to export data');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Export failed';
      setApiError(errorMessage);
    }
  };

  const handleFileImport = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;
    
    setApiError('');
    
    try {
      const result = await realReferenceDataService.importReferenceData(file, selectedCategory, {
        skipDuplicates: true,
        updateExisting: false
      });
      
      if (result.success && result.data) {
        console.log('[REAL COMPONENT] Import completed:', result.data);
        await loadReferenceData(selectedCategory);
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
        
        if (result.data.errors.length > 0) {
          const errorSummary = `Import completed with ${result.data.errors.length} errors. Check console for details.`;
          setApiError(errorSummary);
        }
      } else {
        setApiError(result.error || 'Failed to import data');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Import failed';
      setApiError(errorMessage);
    }
    
    // Reset file input
    event.target.value = '';
  };

  const renderValue = (item: ReferenceDataItem) => {
    if (item.dataType === 'boolean') {
      return item.value ? 'Yes' : 'No';
    } else if (item.dataType === 'object' || item.dataType === 'array') {
      return JSON.stringify(item.value, null, 2);
    } else {
      return String(item.value);
    }
  };

  const getStatusColor = (item: ReferenceDataItem) => {
    if (!item.isActive) return 'bg-red-100 text-red-800';
    if (item.isSystemManaged) return 'bg-blue-100 text-blue-800';
    return 'bg-green-100 text-green-800';
  };

  // Loading state
  if (loading && referenceData.length === 0) {
    return (
      <div className="p-6">
        <div className="bg-white rounded-lg shadow-sm p-12 text-center">
          <RefreshCw className="h-8 w-8 text-blue-600 mx-auto mb-4 animate-spin" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Loading Reference Data</h3>
          <p className="text-gray-600">Fetching data from server...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 flex items-center">
          <Database className="h-6 w-6 mr-2 text-blue-600" />
          Reference Data Manager
        </h2>
        <p className="mt-2 text-gray-600">
          Manage system reference data and lookup values
        </p>
      </div>

      {/* Success Message */}
      {saveSuccess && (
        <div className="mb-6 px-6 py-3 bg-green-50 border border-green-200 rounded-lg">
          <div className="flex items-center gap-2 text-green-800">
            <CheckCircle className="h-5 w-5 text-green-500" />
            <div className="font-medium">Operation completed successfully!</div>
          </div>
        </div>
      )}

      {/* Validation Errors */}
      {validationErrors.length > 0 && (
        <div className="mb-6 px-6 py-3 bg-red-50 border border-red-200 rounded-lg">
          <div className="flex items-start gap-2 text-red-800">
            <AlertCircle className="h-5 w-5 text-red-500 mt-0.5" />
            <div>
              <div className="font-medium">Validation errors:</div>
              <ul className="text-sm list-disc list-inside">
                {validationErrors.map((error, index) => (
                  <li key={index}>{error.field}: {error.message}</li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      )}

      {/* Error Message */}
      {apiError && (
        <div className="mb-6 bg-white rounded-lg shadow-sm border border-red-200">
          <div className="px-6 py-4 bg-red-50 border-b border-red-200">
            <div className="flex items-center gap-2 text-red-800">
              <AlertCircle className="h-5 w-5 text-red-500" />
              <div>
                <div className="font-medium">Reference Data Error</div>
                <div className="text-sm">{apiError}</div>
              </div>
            </div>
          </div>
          <div className="p-4">
            <button
              onClick={selectedCategory ? () => loadReferenceData(selectedCategory) : loadCategories}
              className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700"
            >
              Retry
            </button>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Categories Sidebar */}
        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200 flex justify-between items-center">
              <h3 className="text-sm font-medium text-gray-900">Categories</h3>
              <button
                onClick={() => setShowCategoryModal(true)}
                className="p-1 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded"
                title="Add Category"
              >
                <FolderPlus className="h-4 w-4" />
              </button>
            </div>
            <nav className="p-2 max-h-96 overflow-y-auto">
              {categories.map((category) => (
                <button
                  key={category.id}
                  onClick={() => setSelectedCategory(category.id)}
                  className={`w-full flex items-center justify-between px-3 py-2 text-sm rounded-md transition-colors ${
                    selectedCategory === category.id
                      ? 'bg-blue-50 text-blue-700 border-blue-200'
                      : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                  }`}
                >
                  <div className="flex items-center">
                    <Database className="h-4 w-4 mr-3" />
                    <div className="text-left">
                      <div className="font-medium">{category.name}</div>
                      <div className="text-xs text-gray-500">{category.itemCount} items</div>
                    </div>
                  </div>
                  {category.isSystemCategory && (
                    <Settings className="h-3 w-3 text-gray-400" />
                  )}
                </button>
              ))}
            </nav>
          </div>
        </div>

        {/* Main Content */}
        <div className="lg:col-span-3">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            {/* Toolbar */}
            <div className="px-6 py-4 border-b border-gray-200">
              <div className="flex flex-col sm:flex-row gap-4 justify-between items-start sm:items-center">
                <div className="flex-1 max-w-md">
                  <div className="relative">
                    <Search className="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
                    <input
                      type="text"
                      placeholder="Search reference data..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>
                
                <div className="flex items-center gap-2">
                  <select
                    value={filterActive === undefined ? '' : filterActive.toString()}
                    onChange={(e) => setFilterActive(e.target.value === '' ? undefined : e.target.value === 'true')}
                    className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">All Status</option>
                    <option value="true">Active</option>
                    <option value="false">Inactive</option>
                  </select>
                  
                  <input
                    type="file"
                    accept=".csv,.xlsx,.xls"
                    onChange={handleFileImport}
                    className="hidden"
                    id="import-file"
                  />
                  <label
                    htmlFor="import-file"
                    className="px-3 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 cursor-pointer flex items-center"
                  >
                    <Upload className="h-4 w-4 mr-2" />
                    Import
                  </label>
                  
                  <button
                    onClick={handleExport}
                    className="px-3 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 flex items-center"
                  >
                    <Download className="h-4 w-4 mr-2" />
                    Export
                  </button>
                  
                  {selectedItems.size > 0 && (
                    <button
                      onClick={handleBulkDelete}
                      className="px-3 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 flex items-center"
                    >
                      <Trash2 className="h-4 w-4 mr-2" />
                      Delete ({selectedItems.size})
                    </button>
                  )}
                  
                  <button
                    onClick={() => setShowCreateModal(true)}
                    disabled={!selectedCategory}
                    className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
                  >
                    <Plus className="h-4 w-4 mr-2" />
                    Add Item
                  </button>
                </div>
              </div>
            </div>

            {/* Data Table */}
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="w-8 px-6 py-3 text-left">
                      <input
                        type="checkbox"
                        checked={selectedItems.size === filteredData.length && filteredData.length > 0}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSelectedItems(new Set(filteredData.map(item => item.id)));
                          } else {
                            setSelectedItems(new Set());
                          }
                        }}
                        className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                      />
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Key / Display Name
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Value
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Type
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Modified
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {filteredData.map((item) => (
                    <tr key={item.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4">
                        <input
                          type="checkbox"
                          checked={selectedItems.has(item.id)}
                          onChange={(e) => {
                            const newSelected = new Set(selectedItems);
                            if (e.target.checked) {
                              newSelected.add(item.id);
                            } else {
                              newSelected.delete(item.id);
                            }
                            setSelectedItems(newSelected);
                          }}
                          className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        />
                      </td>
                      <td className="px-6 py-4">
                        <div>
                          <div className="text-sm font-medium text-gray-900">{item.key}</div>
                          <div className="text-sm text-gray-500">{item.displayName}</div>
                          {item.description && (
                            <div className="text-xs text-gray-400 mt-1">{item.description}</div>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm text-gray-900 max-w-xs truncate">
                          {renderValue(item)}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                          {item.dataType}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(item)}`}>
                          {!item.isActive ? 'Inactive' : item.isSystemManaged ? 'System' : 'Active'}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-500">
                        <div>
                          <div>{new Date(item.updatedAt).toLocaleDateString()}</div>
                          <div className="text-xs">{item.updatedBy}</div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center space-x-2">
                          <button
                            onClick={() => {
                              setEditingItem({ ...item });
                              setShowEditModal(true);
                            }}
                            className="p-1 text-gray-400 hover:text-blue-600"
                            title="Edit"
                          >
                            <Edit3 className="h-4 w-4" />
                          </button>
                          {!item.isSystemManaged && (
                            <button
                              onClick={() => handleDeleteItem(item.id)}
                              className="p-1 text-gray-400 hover:text-red-600"
                              title="Delete"
                            >
                              <Trash2 className="h-4 w-4" />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {filteredData.length === 0 && !loading && (
                <div className="text-center py-12">
                  <Database className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">No reference data found</h3>
                  <p className="text-gray-600">
                    {selectedCategory ? 'Try adjusting your search criteria or add some data.' : 'Select a category to view data.'}
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Create Item Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-96 overflow-y-auto">
            <div className="px-6 py-4 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">Add Reference Data Item</h3>
            </div>
            <div className="p-6 space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Key</label>
                  <input
                    type="text"
                    value={newItem.key || ''}
                    onChange={(e) => setNewItem(prev => ({ ...prev, key: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Display Name</label>
                  <input
                    type="text"
                    value={newItem.displayName || ''}
                    onChange={(e) => setNewItem(prev => ({ ...prev, displayName: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea
                  value={newItem.description || ''}
                  onChange={(e) => setNewItem(prev => ({ ...prev, description: e.target.value }))}
                  rows={2}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Data Type</label>
                  <select
                    value={newItem.dataType || 'string'}
                    onChange={(e) => setNewItem(prev => ({ ...prev, dataType: e.target.value as any }))}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {dataTypes.map(type => (
                      <option key={type.value} value={type.value}>{type.label}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Value</label>
                  {newItem.dataType === 'boolean' ? (
                    <select
                      value={String(newItem.value || false)}
                      onChange={(e) => setNewItem(prev => ({ ...prev, value: e.target.value === 'true' }))}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="true">True</option>
                      <option value="false">False</option>
                    </select>
                  ) : newItem.dataType === 'number' ? (
                    <input
                      type="number"
                      value={newItem.value || ''}
                      onChange={(e) => setNewItem(prev => ({ ...prev, value: parseFloat(e.target.value) || 0 }))}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  ) : newItem.dataType === 'object' || newItem.dataType === 'array' ? (
                    <textarea
                      value={JSON.stringify(newItem.value || (newItem.dataType === 'array' ? [] : {}), null, 2)}
                      onChange={(e) => {
                        try {
                          setNewItem(prev => ({ ...prev, value: JSON.parse(e.target.value) }));
                        } catch {
                          // Invalid JSON, keep as string for now
                        }
                      }}
                      rows={3}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  ) : (
                    <input
                      type="text"
                      value={newItem.value || ''}
                      onChange={(e) => setNewItem(prev => ({ ...prev, value: e.target.value }))}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  )}
                </div>
              </div>
              
              <div className="flex items-center space-x-4">
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={newItem.isActive || false}
                    onChange={(e) => setNewItem(prev => ({ ...prev, isActive: e.target.checked }))}
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="ml-2 text-sm text-gray-700">Active</span>
                </label>
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={newItem.isSystemManaged || false}
                    onChange={(e) => setNewItem(prev => ({ ...prev, isSystemManaged: e.target.checked }))}
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="ml-2 text-sm text-gray-700">System Managed</span>
                </label>
              </div>
            </div>
            <div className="px-6 py-4 border-t border-gray-200 flex justify-end space-x-3">
              <button
                onClick={() => setShowCreateModal(false)}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleCreateItem}
                disabled={saving}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
              >
                {saving ? (
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                ) : (
                  <Save className="h-4 w-4 mr-2" />
                )}
                {saving ? 'Creating...' : 'Create Item'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Edit Item Modal */}
      {showEditModal && editingItem && (
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-96 overflow-y-auto">
            <div className="px-6 py-4 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">Edit Reference Data Item</h3>
            </div>
            <div className="p-6 space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Key</label>
                  <input
                    type="text"
                    value={editingItem.key}
                    onChange={(e) => setEditingItem(prev => prev ? { ...prev, key: e.target.value } : null)}
                    disabled={editingItem.isSystemManaged}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Display Name</label>
                  <input
                    type="text"
                    value={editingItem.displayName}
                    onChange={(e) => setEditingItem(prev => prev ? { ...prev, displayName: e.target.value } : null)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea
                  value={editingItem.description || ''}
                  onChange={(e) => setEditingItem(prev => prev ? { ...prev, description: e.target.value } : null)}
                  rows={2}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Value</label>
                {editingItem.dataType === 'boolean' ? (
                  <select
                    value={String(editingItem.value)}
                    onChange={(e) => setEditingItem(prev => prev ? { ...prev, value: e.target.value === 'true' } : null)}
                    disabled={editingItem.isSystemManaged}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
                  >
                    <option value="true">True</option>
                    <option value="false">False</option>
                  </select>
                ) : editingItem.dataType === 'number' ? (
                  <input
                    type="number"
                    value={editingItem.value}
                    onChange={(e) => setEditingItem(prev => prev ? { ...prev, value: parseFloat(e.target.value) || 0 } : null)}
                    disabled={editingItem.isSystemManaged}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
                  />
                ) : editingItem.dataType === 'object' || editingItem.dataType === 'array' ? (
                  <textarea
                    value={JSON.stringify(editingItem.value, null, 2)}
                    onChange={(e) => {
                      try {
                        setEditingItem(prev => prev ? { ...prev, value: JSON.parse(e.target.value) } : null);
                      } catch {
                        // Invalid JSON, keep as string for now
                      }
                    }}
                    disabled={editingItem.isSystemManaged}
                    rows={4}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
                  />
                ) : (
                  <input
                    type="text"
                    value={editingItem.value}
                    onChange={(e) => setEditingItem(prev => prev ? { ...prev, value: e.target.value } : null)}
                    disabled={editingItem.isSystemManaged}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-50"
                  />
                )}
              </div>
              
              <div className="flex items-center space-x-4">
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={editingItem.isActive}
                    onChange={(e) => setEditingItem(prev => prev ? { ...prev, isActive: e.target.checked } : null)}
                    disabled={editingItem.isSystemManaged}
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500 disabled:opacity-50"
                  />
                  <span className="ml-2 text-sm text-gray-700">Active</span>
                </label>
                {editingItem.isSystemManaged && (
                  <span className="text-sm text-gray-500">System managed items cannot be modified</span>
                )}
              </div>
            </div>
            <div className="px-6 py-4 border-t border-gray-200 flex justify-end space-x-3">
              <button
                onClick={() => setShowEditModal(false)}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleUpdateItem}
                disabled={saving || editingItem.isSystemManaged}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
              >
                {saving ? (
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                ) : (
                  <Save className="h-4 w-4 mr-2" />
                )}
                {saving ? 'Updating...' : 'Update Item'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Create Category Modal */}
      {showCategoryModal && (
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-lg w-full">
            <div className="px-6 py-4 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">Add Category</h3>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
                <input
                  type="text"
                  value={newCategory.name || ''}
                  onChange={(e) => setNewCategory(prev => ({ ...prev, name: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea
                  value={newCategory.description || ''}
                  onChange={(e) => setNewCategory(prev => ({ ...prev, description: e.target.value }))}
                  rows={3}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              
              <label className="flex items-center">
                <input
                  type="checkbox"
                  checked={newCategory.isSystemCategory || false}
                  onChange={(e) => setNewCategory(prev => ({ ...prev, isSystemCategory: e.target.checked }))}
                  className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                />
                <span className="ml-2 text-sm text-gray-700">System Category</span>
              </label>
            </div>
            <div className="px-6 py-4 border-t border-gray-200 flex justify-end space-x-3">
              <button
                onClick={() => setShowCategoryModal(false)}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleCreateCategory}
                disabled={saving}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
              >
                {saving ? (
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                ) : (
                  <Save className="h-4 w-4 mr-2" />
                )}
                {saving ? 'Creating...' : 'Create Category'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ReferenceDataManager;