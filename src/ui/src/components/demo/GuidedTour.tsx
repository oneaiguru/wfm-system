import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface GuidedTourProps {
  isActive: boolean;
  currentStep: any;
}

export default function GuidedTour({ isActive, currentStep }: GuidedTourProps) {
  const [highlightBox, setHighlightBox] = useState<DOMRect | null>(null);

  useEffect(() => {
    if (!isActive || !currentStep?.target) return;

    // Find the target element
    const findTarget = () => {
      // Try different selectors
      const selectors = [
        `[data-demo-id="${currentStep.target}"]`,
        `#${currentStep.target}`,
        `.${currentStep.target}`,
        `[aria-label="${currentStep.target}"]`
      ];

      for (const selector of selectors) {
        try {
          const element = document.querySelector(selector);
          if (element) {
            const rect = element.getBoundingClientRect();
            setHighlightBox(rect);
            
            // Scroll element into view
            element.scrollIntoView({ behavior: 'smooth', block: 'center' });
            
            // Add highlight class
            element.classList.add('demo-highlight');
            
            return () => {
              element.classList.remove('demo-highlight');
            };
          }
        } catch (e) {
          // Continue to next selector
        }
      }
    };

    const cleanup = findTarget();
    return cleanup;
  }, [isActive, currentStep]);

  if (!isActive) return null;

  return (
    <AnimatePresence>
      {/* Dark overlay */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 z-40 pointer-events-none"
        style={{ backgroundColor: 'rgba(0, 0, 0, 0.5)' }}
      >
        {/* Highlight cutout */}
        {highlightBox && (
          <div
            className="absolute bg-transparent"
            style={{
              left: highlightBox.left - 8,
              top: highlightBox.top - 8,
              width: highlightBox.width + 16,
              height: highlightBox.height + 16,
              boxShadow: '0 0 0 9999px rgba(0, 0, 0, 0.5)',
              borderRadius: '8px'
            }}
          />
        )}
      </motion.div>

      {/* Animated arrow pointing to element */}
      {highlightBox && (
        <motion.div
          initial={{ scale: 0, rotate: -180 }}
          animate={{ scale: 1, rotate: 0 }}
          exit={{ scale: 0 }}
          className="fixed z-50 pointer-events-none"
          style={{
            left: highlightBox.left + highlightBox.width / 2 - 20,
            top: highlightBox.top - 50
          }}
        >
          <div className="relative">
            <div className="bg-purple-600 text-white rounded-full p-2 animate-bounce">
              <svg className="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" />
              </svg>
            </div>
            <div className="absolute -bottom-1 left-1/2 transform -translate-x-1/2 w-0 h-0 border-l-8 border-r-8 border-t-8 border-transparent border-t-purple-600" />
          </div>
        </motion.div>
      )}

      {/* Ripple effect on target */}
      {highlightBox && (
        <div
          className="fixed z-30 pointer-events-none"
          style={{
            left: highlightBox.left + highlightBox.width / 2,
            top: highlightBox.top + highlightBox.height / 2
          }}
        >
          <div className="absolute -translate-x-1/2 -translate-y-1/2">
            <div className="animate-ping absolute inline-flex h-16 w-16 rounded-full bg-purple-400 opacity-75" />
            <div className="animate-ping absolute inline-flex h-16 w-16 rounded-full bg-purple-400 opacity-75 animation-delay-200" />
          </div>
        </div>
      )}

      <style jsx>{`
        @keyframes ping {
          75%, 100% {
            transform: scale(2);
            opacity: 0;
          }
        }
        
        .animation-delay-200 {
          animation-delay: 0.2s;
        }
        
        :global(.demo-highlight) {
          position: relative;
          z-index: 41 !important;
          box-shadow: 0 0 0 4px #9333ea !important;
          animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite !important;
        }
        
        @keyframes pulse {
          0%, 100% {
            opacity: 1;
          }
          50% {
            opacity: .5;
          }
        }
      `}</style>
    </AnimatePresence>
  );
}