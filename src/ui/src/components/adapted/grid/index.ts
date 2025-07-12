// Main grid components
export { ScheduleGrid } from './ScheduleGrid';
export { VirtualizedScheduleGrid } from './VirtualizedScheduleGrid';
export { GridShowcase } from './GridShowcase';

// Sub-components
export { GridCell } from './GridCell';
export { GridHeader } from './GridHeader';
export { DraggableShift } from './DraggableShift';

// Hooks
export { useGridSelection } from './hooks/useGridSelection';
export { useShiftManagement } from './hooks/useShiftManagement';

// Types
export type {
  Employee,
  Shift,
  GridDate,
  ShiftTemplate,
  SchedulePattern,
  GridSelection,
  GridFilter
} from './types';