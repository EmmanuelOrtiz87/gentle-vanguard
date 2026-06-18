import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

const WS_PORT = parseInt(process.env.WS_PORT || '8080', 10);
const VITE_PORT = parseInt(process.env.VITE_DEV_PORT || '5173', 10);

export default defineConfig({
  plugins: [react()],
  server: {
    port: VITE_PORT,
    strictPort: false,
    proxy: {
      '/api': {
        target: `http://localhost:${WS_PORT}`,
        changeOrigin: true,
      },
      '/ws': {
        target: `http://localhost:${WS_PORT}`,
        ws: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom'],
          charts: ['recharts'],
          icons: ['lucide-react'],
        },
      },
    },
    chunkSizeWarningLimit: 500,
  },
});
