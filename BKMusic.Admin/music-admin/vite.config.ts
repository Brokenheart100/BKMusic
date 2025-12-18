import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path' // 需确保安装了 @types/node

export default defineConfig({
  plugins: [vue()],
  // 【核心检查点】有没有这一段？
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src')
    }
  },
  server: {
    port: 5173,
    strictPort: true,
  }
})