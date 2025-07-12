import { useState, useRef, useEffect, useCallback } from 'react';
import { GearMenuAction, GearMenuActionResult, GrowthFactorConfig } from '@/types/GearMenuTypes';

interface UseGearMenuProps {
  onAction: (action: GearMenuAction, tabId: string) => void | Promise<void>;
  tabId: string;
}

interface UseGearMenuReturn {
  isOpen: boolean;
  openMenu: () => void;
  closeMenu: () => void;
  toggleMenu: () => void;
  menuRef: React.RefObject<HTMLDivElement>;
  buttonRef: React.RefObject<HTMLButtonElement>;
  handleAction: (action: GearMenuAction) => Promise<void>;
  isProcessing: boolean;
  lastActionResult: GearMenuActionResult | null;
}

export const useGearMenu = ({ onAction, tabId }: UseGearMenuProps): UseGearMenuReturn => {
  const [isOpen, setIsOpen] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [lastActionResult, setLastActionResult] = useState<GearMenuActionResult | null>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);

  const openMenu = useCallback(() => setIsOpen(true), []);
  const closeMenu = useCallback(() => setIsOpen(false), []);
  const toggleMenu = useCallback(() => setIsOpen(prev => !prev), []);

  const handleAction = useCallback(async (action: GearMenuAction) => {
    setIsProcessing(true);
    try {
      // Special handling for growth factor
      if (action === 'growth_factor') {
        const showGrowthFactorDialog = () => {
          const modal = document.createElement('div');
          modal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50';
          
          const currentDate = new Date();
          const startDate = new Date(currentDate.getFullYear(), currentDate.getMonth() - 2, 1);
          const endDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0);
          
          modal.innerHTML = `
            <div class="bg-white rounded-lg p-6 w-96 shadow-xl">
              <h3 class="text-lg font-semibold mb-4">📈 Growth Factor Configuration</h3>
              <p class="text-sm text-gray-600 mb-4">Scale your forecast volumes (e.g., from 1,000 to 5,000 calls)</p>
              
              <div class="space-y-4">
                <div>
                  <label class="block text-sm font-medium mb-1">Period</label>
                  <div class="grid grid-cols-2 gap-2">
                    <input type="date" id="growth-start" value="${startDate.toISOString().split('T')[0]}" class="border rounded px-3 py-2 text-sm" />
                    <input type="date" id="growth-end" value="${endDate.toISOString().split('T')[0]}" class="border rounded px-3 py-2 text-sm" />
                  </div>
                </div>
                
                <div>
                  <label class="block text-sm font-medium mb-1">Growth Factor</label>
                  <input type="number" id="growth-factor" value="5.0" min="0.1" max="10" step="0.1" class="w-full border rounded px-3 py-2" />
                  <p class="text-xs text-gray-500 mt-1">Enter 5.0 to scale from 1,000 to 5,000 calls</p>
                </div>
                
                <div>
                  <label class="block text-sm font-medium mb-1">Apply to</label>
                  <select id="growth-apply-to" class="w-full border rounded px-3 py-2">
                    <option value="call_volume">Call Volume Only</option>
                    <option value="both">Call Volume and AHT</option>
                  </select>
                </div>
                
                <div>
                  <label class="flex items-center space-x-2">
                    <input type="checkbox" id="growth-maintain-aht" checked class="rounded" />
                    <span class="text-sm">Maintain AHT values</span>
                  </label>
                </div>
              </div>
              
              <div class="flex justify-end space-x-3 mt-6">
                <button id="growth-cancel" class="px-4 py-2 text-gray-600 hover:text-gray-800">Cancel</button>
                <button id="growth-apply" class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">Apply Growth Factor</button>
              </div>
            </div>
          `;
          
          document.body.appendChild(modal);
          
          const applyBtn = modal.querySelector('#growth-apply') as HTMLButtonElement;
          const cancelBtn = modal.querySelector('#growth-cancel') as HTMLButtonElement;
          
          const handleApply = async () => {
            const config: GrowthFactorConfig = {
              period: {
                start: new Date((modal.querySelector('#growth-start') as HTMLInputElement).value),
                end: new Date((modal.querySelector('#growth-end') as HTMLInputElement).value)
              },
              growthFactor: parseFloat((modal.querySelector('#growth-factor') as HTMLInputElement).value),
              applyTo: (modal.querySelector('#growth-apply-to') as HTMLSelectElement).value as 'call_volume' | 'both',
              maintainAHT: (modal.querySelector('#growth-maintain-aht') as HTMLInputElement).checked
            };
            
            document.body.removeChild(modal);
            await onAction('growth_factor', tabId);
            
            // Show success message
            const successMsg = document.createElement('div');
            successMsg.className = 'fixed top-4 right-4 bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded shadow-lg z-50';
            successMsg.innerHTML = `
              <div class="flex items-center">
                <span class="mr-2">✓</span>
                <span>Growth factor of ${config.growthFactor}x applied successfully!</span>
              </div>
            `;
            document.body.appendChild(successMsg);
            setTimeout(() => document.body.removeChild(successMsg), 3000);
          };
          
          applyBtn.addEventListener('click', handleApply);
          cancelBtn.addEventListener('click', () => document.body.removeChild(modal));
          modal.addEventListener('click', (e) => {
            if (e.target === modal) document.body.removeChild(modal);
          });
        };
        
        showGrowthFactorDialog();
      } else {
        await onAction(action, tabId);
      }
      
      setLastActionResult({ success: true, message: `Action ${action} completed` });
      closeMenu();
    } catch (error) {
      setLastActionResult({ 
        success: false, 
        message: error instanceof Error ? error.message : 'Action failed' 
      });
    } finally {
      setIsProcessing(false);
    }
  }, [onAction, tabId, closeMenu]);

  // Handle clicks outside menu
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        isOpen &&
        menuRef.current &&
        buttonRef.current &&
        !menuRef.current.contains(event.target as Node) &&
        !buttonRef.current.contains(event.target as Node)
      ) {
        closeMenu();
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen, closeMenu]);

  // Handle keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && isOpen) {
        closeMenu();
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, closeMenu]);

  return {
    isOpen,
    openMenu,
    closeMenu,
    toggleMenu,
    menuRef,
    buttonRef,
    handleAction,
    isProcessing,
    lastActionResult
  };
};