import React, { useState, useCallback } from 'react';
import * as XLSX from 'xlsx';

interface ExcelUploaderProps {
  onDataUploaded?: (data: any, fileName: string) => void;
  onError?: (error: string) => void;
  maxFileSize?: number; // in bytes
  acceptedFormats?: string[];
  className?: string;
}

interface ParsedData {
  headers: string[];
  rows: any[][];
  fileName: string;
  totalRows: number;
  raw: any; // Raw data for processing
}

const ExcelUploader: React.FC<ExcelUploaderProps> = ({
  onDataUploaded,
  onError,
  maxFileSize = 10 * 1024 * 1024, // 10MB default
  acceptedFormats = ['.xlsx', '.xls', '.csv'],
  className = ''
}) => {
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [parsedData, setParsedData] = useState<ParsedData | null>(null);
  const [isDragOver, setIsDragOver] = useState(false);

  const validateFile = (file: File): string | null => {
    const fileExtension = '.' + file.name.split('.').pop()?.toLowerCase();
    
    if (!acceptedFormats.includes(fileExtension)) {
      return `Invalid file format. Allowed formats: ${acceptedFormats.join(', ')}`;
    }
    
    if (file.size > maxFileSize) {
      return `File too large. Maximum size: ${(maxFileSize / (1024 * 1024)).toFixed(1)}MB`;
    }
    
    return null;
  };

  const parseExcelFile = useCallback((file: File): Promise<ParsedData> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      
      reader.onload = (e) => {
        try {
          const data = e.target?.result;
          const workbook = XLSX.read(data, { type: 'binary' });
          
          const sheetName = workbook.SheetNames[0];
          const worksheet = workbook.Sheets[sheetName];
          
          const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
          const rawData = XLSX.utils.sheet_to_json(worksheet);
          
          if (jsonData.length === 0) {
            reject(new Error('File is empty or contains no data'));
            return;
          }
          
          const headers = jsonData[0] as string[];
          const rows = jsonData.slice(1) as any[][];
          
          const validRows = rows.filter(row => row.some(cell => cell !== null && cell !== undefined && cell !== ''));
          
          resolve({
            headers,
            rows: validRows,
            fileName: file.name,
            totalRows: validRows.length,
            raw: rawData
          });
        } catch (error) {
          reject(new Error('Failed to parse Excel file. Please check the file format.'));
        }
      };
      
      reader.onerror = () => reject(new Error('Failed to read file'));
      reader.readAsBinaryString(file);
    });
  }, []);

  const handleFileUpload = useCallback(async (file: File) => {
    const validationError = validateFile(file);
    if (validationError) {
      onError?.(validationError);
      return;
    }

    setIsUploading(true);
    setUploadProgress(0);

    try {
      const progressInterval = setInterval(() => {
        setUploadProgress(prev => Math.min(prev + 10, 90));
      }, 100);

      const data = await parseExcelFile(file);
      
      clearInterval(progressInterval);
      setUploadProgress(100);
      
      setParsedData(data);
      onDataUploaded?.(data.raw, data.fileName);
      
      setTimeout(() => {
        setIsUploading(false);
        setUploadProgress(0);
      }, 500);
      
    } catch (error) {
      setIsUploading(false);
      setUploadProgress(0);
      onError?.(error instanceof Error ? error.message : 'Upload failed');
    }
  }, [parseExcelFile, onDataUploaded, onError]);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
    
    const files = e.dataTransfer.files;
    if (files.length > 0) {
      handleFileUpload(files[0]);
    }
  }, [handleFileUpload]);

  const handleFileSelect = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      handleFileUpload(file);
    }
  }, [handleFileUpload]);

  return (
    <div className={`w-full ${className}`}>
      <div
        className={`
          relative border-2 border-dashed rounded-lg p-8 text-center transition-all
          ${isDragOver ? 'border-blue-400 bg-blue-50' : 'border-gray-300 hover:border-gray-400'}
          ${isUploading ? 'pointer-events-none opacity-60' : 'cursor-pointer'}
        `}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
      >
        <input
          type="file"
          accept={acceptedFormats.join(',')}
          onChange={handleFileSelect}
          className="hidden"
          id="excel-upload"
          disabled={isUploading}
        />
        
        <label htmlFor="excel-upload" className="cursor-pointer">
          <div className="text-gray-600 mb-4">
            <svg className="w-12 h-12 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
            </svg>
          </div>
          <p className="text-lg font-medium text-gray-700">
            {isUploading ? 'Processing...' : 'Click to upload or drag and drop'}
          </p>
          <p className="text-sm text-gray-500 mt-1">
            {acceptedFormats.join(', ')} files up to {(maxFileSize / (1024 * 1024)).toFixed(0)}MB
          </p>
        </label>

        {isUploading && (
          <div className="mt-4">
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div
                className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                style={{ width: `${uploadProgress}%` }}
              />
            </div>
            <p className="text-sm text-gray-600 mt-2">{uploadProgress}% complete</p>
          </div>
        )}
      </div>

      {parsedData && (
        <div className="mt-6 bg-white rounded-lg border border-gray-200 overflow-hidden">
          <div className="bg-gray-50 px-4 py-3 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-sm font-medium text-gray-900">
                  📊 {parsedData.fileName}
                </h3>
                <p className="text-sm text-gray-500">
                  {parsedData.totalRows} rows • {parsedData.headers.length} columns
                </p>
              </div>
              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                ✅ Uploaded
              </span>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  {parsedData.headers.map((header, index) => (
                    <th
                      key={index}
                      className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                    >
                      {header || `Column ${index + 1}`}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {parsedData.rows.slice(0, 10).map((row, rowIndex) => (
                  <tr key={rowIndex} className={rowIndex % 2 === 0 ? 'bg-white' : 'bg-gray-50'}>
                    {parsedData.headers.map((_, colIndex) => (
                      <td
                        key={colIndex}
                        className="px-3 py-2 text-sm text-gray-900 whitespace-nowrap"
                      >
                        {row[colIndex] || '—'}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {parsedData.totalRows > 10 && (
            <div className="bg-gray-50 px-4 py-3 border-t border-gray-200">
              <p className="text-sm text-gray-600">
                Showing first 10 rows of {parsedData.totalRows} total rows
              </p>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default ExcelUploader;