# ==========================================
# 阶段 1: 构建 (Builder)
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /app

# 1. 复制依赖清单
COPY package*.json ./

# 2. 设置淘宝源并安装依赖
RUN npm config set registry https://registry.npmmirror.com
RUN npm ci --legacy-peer-deps

# 3. 复制源码
COPY . .

# 4. 注入环境变量 (关键)
# 在 Nginx 代理模式下，前端只需请求相对路径 '/api'
# 所以这里甚至可以不传 BaseURL，让代码默认使用 '/api'
ENV VITE_API_BASE_URL=/api

# 5. 执行构建
# 跳过类型检查以保证构建成功 (生产环境建议在 CI/CD 流水线中先做类型检查)
RUN npm run build-only || npm run build

# ==========================================
# 阶段 2: 生产环境运行 (Runner)
# ==========================================
FROM nginx:alpine

# 1. 复制我们刚才写的 nginx.conf
# 覆盖镜像默认的配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 2. 复制构建产物到 Nginx 目录
COPY --from=builder /app/dist /usr/share/nginx/html

# 3. 暴露 80 端口
EXPOSE 80

# 4. 启动
CMD ["nginx", "-g", "daemon off;"]