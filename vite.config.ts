import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'prompt',
      includeAssets: ['favicon.svg'],
      manifest: {
        name: 'MAGIZH POS',
        short_name: 'MAGIZH POS',
        description: 'Mobile point of sale and business management',
        theme_color: '#123d32',
        background_color: '#f7f5ef',
        display: 'standalone',
        orientation: 'portrait',
        start_url: '/',
        scope: '/',
        icons: [
          { src: '/pwa-192.svg', sizes: '192x192', type: 'image/svg+xml', purpose: 'any' },
          { src: '/pwa-512.svg', sizes: '512x512', type: 'image/svg+xml', purpose: 'any' }
        ]
      },
      workbox: {
        navigateFallback: 'index.html',
        globPatterns: ['**/*.{js,css,html,svg,png,ico}']
      }
    })
  ]
})