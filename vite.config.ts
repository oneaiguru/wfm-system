import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  root: '.',
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src/ui/src'),
      '@components': path.resolve(__dirname, './src/ui/src/components'),
      '@services': path.resolve(__dirname, './src/ui/src/services'),
      '@types': path.resolve(__dirname, './src/ui/src/types'),
      '@utils': path.resolve(__dirname, './src/ui/src/utils')
    }
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true
      }
    },
    // Handle SPA routing - serve index.html for all routes
    middlewareMode: false,
    hmr: {
      overlay: true
    }
  },
  preview: {
    port: 3000
  },
  build: {
    outDir: 'dist',
    sourcemap: true
  }
})