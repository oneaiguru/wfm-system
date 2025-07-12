import React from 'react';
import { GearMenuProps, GEAR_MENU_CONFIGS, GearMenuItem } from '@/types/GearMenuTypes';
import { useGearMenu } from '@/hooks/useGearMenu';

const GearMenu: React.FC<GearMenuProps> = ({ 
  tabId, 
  onAction, 
  position = 'top-right',
  className = ''
}) => {
  const {
    isOpen,
    toggleMenu,
    menuRef,
    buttonRef,
    handleAction,
    isProcessing
  } = useGearMenu({ onAction, tabId });

  const menuItems = GEAR_MENU_CONFIGS[tabId] || [];

  const handleMenuItemClick = async (item: GearMenuItem) => {
    if (item.disabled || isProcessing) return;

    if (item.requiresConfirmation && item.confirmationMessage) {
      const confirmed = window.confirm(item.confirmationMessage);
      if (!confirmed) return;
    }

    await handleAction(item.id);
  };

  const getPositionClasses = () => {
    switch (position) {
      case 'top-left':
        return 'left-0 mt-2';
      case 'bottom-right':
        return 'right-0 bottom-full mb-2';
      case 'bottom-left':
        return 'left-0 bottom-full mb-2';
      case 'top-right':
      default:
        return 'right-0 mt-2';
    }
  };

  return (
    <div className={`relative ${className}`}>
      <button
        ref={buttonRef}
        onClick={toggleMenu}
        className="p-2 rounded-lg hover:bg-gray-100 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
        aria-label="Open menu"
        title="Open menu"
      >
        <svg
          className="w-5 h-5 text-gray-600"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
          />
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
          />
        </svg>
      </button>

      {isOpen && (
        <div
          ref={menuRef}
          className={`absolute ${getPositionClasses()} w-64 bg-white rounded-lg shadow-lg border border-gray-200 z-50`}
        >
          <div className="py-1">
            {menuItems.length === 0 ? (
              <div className="px-4 py-3 text-sm text-gray-500">No actions available</div>
            ) : (
              menuItems.map((item, index) => (
                <React.Fragment key={item.id}>
                  {item.divider && index > 0 && (
                    <div className="h-px bg-gray-200 my-1" />
                  )}
                  <button
                    onClick={() => handleMenuItemClick(item)}
                    disabled={item.disabled || isProcessing}
                    className={`
                      w-full text-left px-4 py-2 text-sm flex items-center justify-between
                      ${item.disabled || isProcessing
                        ? 'text-gray-400 cursor-not-allowed'
                        : 'text-gray-700 hover:bg-gray-100 hover:text-gray-900'
                      }
                      transition-colors duration-150
                    `}
                    title={item.tooltip}
                  >
                    <div className="flex items-center">
                      {item.icon && <span className="mr-2">{item.icon}</span>}
                      <span>{item.label}</span>
                    </div>
                    {item.shortcut && (
                      <span className="text-xs text-gray-500 ml-2">{item.shortcut}</span>
                    )}
                  </button>
                </React.Fragment>
              ))
            )}
          </div>
          
          {isProcessing && (
            <div className="absolute inset-0 bg-white bg-opacity-75 flex items-center justify-center rounded-lg">
              <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default GearMenu;