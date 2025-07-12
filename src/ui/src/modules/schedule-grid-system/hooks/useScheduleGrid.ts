import { useState, useCallback, useMemo } from 'react';
import { Employee, Shift, GridSelection, GridCell } from '../types/schedule';

export const useScheduleGrid = () => {
  const [selectedCells, setSelectedCells] = useState<Set<string>>(new Set());
  const [dragState, setDragState] = useState<any>(null);
  const [scrollPosition, setScrollPosition] = useState({ top: 0, left: 0 });

  const selectCell = useCallback((employeeId: string, dateIndex: number) => {
    const cellId = `${employeeId}-${dateIndex}`;
    setSelectedCells(prev => {
      const newSet = new Set(prev);
      if (newSet.has(cellId)) {
        newSet.delete(cellId);
      } else {
        newSet.add(cellId);
      }
      return newSet;
    });
  }, []);

  const selectRange = useCallback((startCell: GridCell, endCell: GridCell) => {
    const newSelected = new Set<string>();
    
    // Logic to select range of cells
    // This is a simplified version - would need more complex logic for multi-dimensional selection
    
    setSelectedCells(newSelected);
  }, []);

  const clearSelection = useCallback(() => {
    setSelectedCells(new Set());
  }, []);

  const isCellSelected = useCallback((employeeId: string, dateIndex: number) => {
    return selectedCells.has(`${employeeId}-${dateIndex}`);
  }, [selectedCells]);

  const selectedCount = useMemo(() => selectedCells.size, [selectedCells]);

  return {
    selectedCells,
    selectCell,
    selectRange,
    clearSelection,
    isCellSelected,
    selectedCount,
    dragState,
    setDragState,
    scrollPosition,
    setScrollPosition
  };
};
