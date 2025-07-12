import React from 'react';
import { motion } from 'framer-motion';
import { X, TrendingDown, TrendingUp } from 'lucide-react';

interface ComparisonViewProps {
  onClose: () => void;
  comparison?: {
    argus: string;
    ours: string;
  };
}

export default function ComparisonView({ onClose, comparison }: ComparisonViewProps) {
  if (!comparison) return null;

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
      onClick={onClose}
    >
      <motion.div
        initial={{ scale: 0.9, y: 20 }}
        animate={{ scale: 1, y: 0 }}
        exit={{ scale: 0.9, y: 20 }}
        className="bg-white rounded-2xl shadow-2xl max-w-4xl w-full p-8"
        onClick={e => e.stopPropagation()}
      >
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-2xl font-bold text-gray-900">System Comparison</h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700 transition-colors"
          >
            <X className="h-6 w-6" />
          </button>
        </div>

        <div className="grid grid-cols-2 gap-8">
          {/* Argus Side */}
          <motion.div
            initial={{ x: -50, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            transition={{ delay: 0.2 }}
            className="relative"
          >
            <div className="absolute -top-3 -left-3 bg-red-500 text-white text-xs font-bold px-3 py-1 rounded-full">
              ARGUS CCWFM
            </div>
            <div className="bg-red-50 border-2 border-red-200 rounded-lg p-6">
              <div className="flex items-center gap-2 mb-4">
                <TrendingDown className="h-5 w-5 text-red-600" />
                <h3 className="font-semibold text-red-900">Limited Capabilities</h3>
              </div>
              <p className="text-red-800 text-lg">{comparison.argus}</p>
              
              {/* Animated issues */}
              <div className="mt-4 space-y-2">
                <motion.div
                  initial={{ x: -20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: 0.4 }}
                  className="flex items-center gap-2 text-red-600"
                >
                  <span className="text-xl">❌</span>
                  <span className="text-sm">Manual processes</span>
                </motion.div>
                <motion.div
                  initial={{ x: -20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: 0.5 }}
                  className="flex items-center gap-2 text-red-600"
                >
                  <span className="text-xl">❌</span>
                  <span className="text-sm">Slow calculations</span>
                </motion.div>
                <motion.div
                  initial={{ x: -20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: 0.6 }}
                  className="flex items-center gap-2 text-red-600"
                >
                  <span className="text-xl">❌</span>
                  <span className="text-sm">Limited accuracy</span>
                </motion.div>
              </div>
            </div>
          </motion.div>

          {/* WFM Enterprise Side */}
          <motion.div
            initial={{ x: 50, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            transition={{ delay: 0.2 }}
            className="relative"
          >
            <div className="absolute -top-3 -right-3 bg-gradient-to-r from-purple-600 to-pink-600 text-white text-xs font-bold px-3 py-1 rounded-full animate-pulse">
              WFM ENTERPRISE
            </div>
            <div className="bg-gradient-to-br from-purple-50 to-pink-50 border-2 border-purple-200 rounded-lg p-6">
              <div className="flex items-center gap-2 mb-4">
                <TrendingUp className="h-5 w-5 text-purple-600" />
                <h3 className="font-semibold text-purple-900">Superior Performance</h3>
              </div>
              <p className="text-purple-800 text-lg font-medium">{comparison.ours}</p>
              
              {/* Animated advantages */}
              <div className="mt-4 space-y-2">
                <motion.div
                  initial={{ x: 20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: 0.4 }}
                  className="flex items-center gap-2 text-green-600"
                >
                  <span className="text-xl">✅</span>
                  <span className="text-sm">ML-powered automation</span>
                </motion.div>
                <motion.div
                  initial={{ x: 20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: 0.5 }}
                  className="flex items-center gap-2 text-green-600"
                >
                  <span className="text-xl">✅</span>
                  <span className="text-sm">Real-time calculations</span>
                </motion.div>
                <motion.div
                  initial={{ x: 20, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  transition={{ delay: 0.6 }}
                  className="flex items-center gap-2 text-green-600"
                >
                  <span className="text-xl">✅</span>
                  <span className="text-sm">Industry-leading accuracy</span>
                </motion.div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* Victory message */}
        <motion.div
          initial={{ y: 30, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.8 }}
          className="mt-8 text-center"
        >
          <div className="inline-flex items-center gap-2 bg-gradient-to-r from-purple-600 to-pink-600 text-white px-6 py-3 rounded-full font-semibold">
            <span className="text-2xl">🏆</span>
            <span>WFM Enterprise delivers superior results every time!</span>
            <span className="text-2xl">🏆</span>
          </div>
        </motion.div>
      </motion.div>
    </motion.div>
  );
}