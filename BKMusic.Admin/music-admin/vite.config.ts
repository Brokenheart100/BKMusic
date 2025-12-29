import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path' // 需确保安装了 @types/node

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src')
    }
  },
  server: {
    port: 8123,
    strictPort: true,
    proxy: {
      // 凡是 '/api' 开头的请求，都代理到网关
      '/api': {
        target: 'http://localhost:8765',  // 👈 这里填你本地 Gateway 的 HTTPS 地址 (VS启动的端口)
        changeOrigin: true,
        secure: false, // 关键：忽略 .NET 自签名证书错误
        // rewrite: (path) => path.replace(/^\/api/, '') // 如果网关不需要 /api 前缀，可以开启这行去掉
      }
    }
  }
})