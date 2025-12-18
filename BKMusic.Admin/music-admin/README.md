这是一个非常详尽的落地指南。我们将从零开始，构建一个**基于 Vue 3 + TypeScript + Element Plus** 的企业级管理后台，并将其无缝集成到你的 **.NET Aspire** 架构中。

---

### 准备工作

确保你的电脑上安装了：

1. **Node.js** (推荐 v18 或 v20 LTS 版本)
2. **VS Code** (前端开发推荐) + **Vetur** 或 **Volar** 插件

---

### 第一阶段：项目初始化 (Initialization)

在你的解决方案根目录下（即 `BKMusic` 文件夹内，与 `musicapp`、`BKMusic.AppHost` 平级的位置），打开终端：

#### 1. 创建 Vite 项目

```bash
# 创建名为 music-admin 的 Vue+TS 项目
npm create vite@latest music-admin -- --template vue-ts

# 进入目录
cd music-admin

# 安装基础依赖
npm install
```

#### 2. 安装企业级全家桶

我们需要安装 UI 库、路由、状态管理、网络请求库和 Sass 预处理器。

```bash
npm install element-plus @element-plus/icons-vue vue-router pinia axios sass
```

#### 3. 安装类型定义 (开发依赖)

```bash
npm install -D @types/node
```

---

### 第二阶段：基础设施配置 (Infrastructure)

我们需要配置 Vite，让它能识别路径别名（`@`），并配置 Aspire 集成。

#### 1. 修改 `vite.config.ts`

```typescript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src') // 设置 @ 指向 src 目录
    }
  },
  server: {
    port: 5173, // 固定端口，方便 CORS 配置
    strictPort: true,
  }
})
```

#### 2. 建立目录结构

请手动创建以下文件夹，保持结构清晰：

```text
src/
├── api/          # 接口
├── assets/
├── components/
├── layout/       # 布局 (侧边栏/头部)
├── router/       # 路由
├── store/        # 状态 (Pinia)
├── utils/        # 工具 (Request)
├── views/        # 页面
│   ├── login/
│   └── song/
├── App.vue
└── main.ts
```

#### 3. 修改 Aspire AppHost (`BKMusic.AppHost/Program.cs`)

让 Aspire 能够启动这个前端项目。

```csharp
// ... 其他服务注册 ...

// 注册 Vue 项目
var vueAdmin = builder.AddNpmApp("vue-admin", "../music-admin")
    .WithEnvironment("VITE_API_BASE_URL", "https://localhost:7101") // 注入网关地址
    .WithExternalHttpEndpoints(); 

// Build().Run();
```

---

### 第三阶段：核心工具封装 (Core Utils)

#### 1. Axios 网络请求封装 (`src/utils/request.ts`)

企业级开发不直接用 axios，必须封装拦截器来处理 Token 和错误。

```typescript
import axios from 'axios'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/store/user'

// 读取 Aspire 注入的环境变量
const baseURL = import.meta.env.VITE_API_BASE_URL || 'https://localhost:7101'

const service = axios.create({
  baseURL: baseURL,
  timeout: 15000,
})

// 请求拦截器
service.interceptors.request.use(
  (config) => {
    const userStore = useUserStore()
    if (userStore.token) {
      config.headers.Authorization = `Bearer ${userStore.token}`
    }
    return config
  },
  (error) => Promise.reject(error)
)

// 响应拦截器
service.interceptors.response.use(
  (response) => {
    // 假设后端返回 { isSuccess: true, value: ... }
    // 如果 isSuccess 为 false，也可以在这里拦截
    return response.data
  },
  (error) => {
    if (error.response?.status === 401) {
      ElMessage.error('登录已过期')
      const userStore = useUserStore()
      userStore.logout()
    } else {
      ElMessage.error(error.message || '请求失败')
    }
    return Promise.reject(error)
  }
)

export default service
```

#### 2. 用户状态管理 (`src/store/user.ts`)

```typescript
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useRouter } from 'vue-router'

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('token') || '')
  const router = useRouter()

  const setToken = (t: string) => {
    token.value = t
    localStorage.setItem('token', t)
  }

  const logout = () => {
    token.value = ''
    localStorage.removeItem('token')
    // 强制刷新或跳转
    window.location.href = '/login'
  }

  return { token, setToken, logout }
})
```

---

### 第四阶段：API 定义 (API Layer)

将所有后端接口映射为 TS 函数。

**1. `src/api/auth.ts`**

```typescript
import request from '@/utils/request'

export const login = (data: any) => {
  return request.post('/api/auth/login', data)
}
```

**2. `src/api/catalog.ts`**

```typescript
import request from '@/utils/request'

export interface CreateSongRequest {
  title: string
  artist: string
  album: string
  coverUrl?: string
}

export const getSongs = () => {
  return request.get('/api/songs')
}

export const createSong = (data: CreateSongRequest) => {
  return request.post('/api/songs', data)
}
```

**3. `src/api/media.ts`**

```typescript
import request from '@/utils/request'
import axios from 'axios'

// 获取上传链接
export const initUpload = (fileName: string, contentType: string) => {
  return request.post('/api/media/upload/init', { fileName, contentType })
}

// 确认上传
export const confirmUpload = (uploadId: string) => {
  return request.post('/api/media/upload/confirm', { uploadId })
}

// 物理上传 (直连 MinIO，不走 request 拦截器，因为 MinIO 不需要 Bearer Token)
export const uploadToMinio = (url: string, file: File) => {
  return axios.put(url, file, {
    headers: { 'Content-Type': file.type }
  })
}
```

---

### 第五阶段：页面开发 (Views)

#### 1. 简单布局 (`src/layout/index.vue`)

一个简单的头部+内容区域布局。

```vue
<template>
  <div class="common-layout">
    <el-container>
      <el-header class="header">
        <h3>BKMusic Admin</h3>
        <el-button link @click="handleLogout">退出登录</el-button>
      </el-header>
      <el-main>
        <router-view />
      </el-main>
    </el-container>
  </div>
</template>

<script setup lang="ts">
import { useUserStore } from '@/store/user'
const userStore = useUserStore()
const handleLogout = () => userStore.logout()
</script>

<style scoped>
.header {
  background-color: #545c64;
  color: white;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
```

#### 2. 登录页 (`src/views/login/index.vue`)

```vue
<template>
  <div class="login-container">
    <el-card class="login-card">
      <h2>系统登录</h2>
      <el-form :model="form" label-width="0">
        <el-form-item>
          <el-input v-model="form.email" placeholder="邮箱" />
        </el-form-item>
        <el-form-item>
          <el-input v-model="form.password" type="password" placeholder="密码" />
        </el-form-item>
        <el-button type="primary" class="w-100" @click="handleLogin" :loading="loading">
          登录
        </el-button>
      </el-form>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/store/user'
import { login } from '@/api/auth'
import { ElMessage } from 'element-plus'

const router = useRouter()
const userStore = useUserStore()
const loading = ref(false)

const form = reactive({
  email: 'user@example.com',
  password: 'Password1234'
})

const handleLogin = async () => {
  loading.value = true
  try {
    const res: any = await login(form)
    // 假设后端返回结构 { isSuccess: true, value: { accessToken: '...' } }
    if (res.isSuccess) {
      userStore.setToken(res.value.accessToken)
      ElMessage.success('登录成功')
      router.push('/')
    } else {
      ElMessage.error('登录失败')
    }
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-container { height: 100vh; display: flex; justify-content: center; align-items: center; background: #f0f2f5; }
.login-card { width: 400px; padding: 20px; }
.w-100 { width: 100%; }
</style>
```

#### 3. 歌曲管理页 (`src/views/song/index.vue`) - **最核心的业务页**

```vue
<template>
  <div>
    <div style="margin-bottom: 20px;">
      <el-button type="primary" @click="dialogVisible = true">上传新歌</el-button>
      <el-button @click="fetchData">刷新列表</el-button>
    </div>

    <!-- 列表 -->
    <el-table :data="tableData" border v-loading="loading">
      <el-table-column prop="title" label="歌名" />
      <el-table-column prop="artist" label="歌手" />
      <el-table-column label="封面" width="120">
        <template #default="{ row }">
          <el-image 
            v-if="row.coverUrl" 
            :src="row.coverUrl" 
            style="width: 60px; height: 60px" 
            fit="cover" 
          />
        </template>
      </el-table-column>
      <el-table-column prop="url" label="播放地址" show-overflow-tooltip />
    </el-table>

    <!-- 上传弹窗 -->
    <el-dialog v-model="dialogVisible" title="发布新歌" width="500px">
      <el-form :model="form" label-width="80px">
        <el-form-item label="歌名">
          <el-input v-model="form.title" />
        </el-form-item>
        <el-form-item label="歌手">
          <el-input v-model="form.artist" />
        </el-form-item>
        <el-form-item label="专辑">
          <el-input v-model="form.album" />
        </el-form-item>
        <el-form-item label="封面URL">
          <el-input v-model="form.coverUrl" placeholder="输入图片链接" />
        </el-form-item>
        <el-form-item label="文件">
          <input type="file" @change="handleFileChange" accept=".mp3,.flac,.wav" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleUpload">
          开始上传
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { getSongs, createSong } from '@/api/catalog'
import { initUpload, uploadToMinio, confirmUpload } from '@/api/media'
import { ElMessage } from 'element-plus'

// --- 列表逻辑 ---
const tableData = ref([])
const loading = ref(false)

const fetchData = async () => {
  loading.value = true
  try {
    const res: any = await getSongs()
    tableData.value = res.value || []
  } finally {
    loading.value = false
  }
}

onMounted(fetchData)

// --- 上传逻辑 ---
const dialogVisible = ref(false)
const submitting = ref(false)
const selectedFile = ref<File | null>(null)
const form = reactive({
  title: '',
  artist: '',
  album: 'Vue Album',
  coverUrl: 'https://via.placeholder.com/150'
})

const handleFileChange = (e: Event) => {
  const target = e.target as HTMLInputElement
  if (target.files && target.files.length > 0) {
    selectedFile.value = target.files[0]
  }
}

const handleUpload = async () => {
  if (!selectedFile.value) return ElMessage.warning('请选择文件')
  
  submitting.value = true
  try {
    // 1. 创建元数据 (Catalog)
    const metaRes: any = await createSong(form)
    // 拿到 SongId (虽然这里流程上不需要传给 Media，但业务上可能需要关联)
  
    // 2. 获取上传链接 (Media)
    const initRes: any = await initUpload(selectedFile.value.name, selectedFile.value.type)
    const { uploadId, uploadUrl } = initRes.value

    // 3. 直传 MinIO (PUT)
    await uploadToMinio(uploadUrl, selectedFile.value)

    // 4. 确认上传 (触发转码)
    await confirmUpload(uploadId)

    ElMessage.success('上传成功，转码中...')
    dialogVisible.value = false
  
    // 稍等两秒刷新列表
    setTimeout(fetchData, 2000)
  } catch (error) {
    console.error(error)
    ElMessage.error('上传流程失败')
  } finally {
    submitting.value = false
  }
}
</script>
```

---

### 第六阶段：路由配置与入口 (`main.ts`)

#### 1. 路由配置 (`src/router/index.ts`)

```typescript
import { createRouter, createWebHistory } from 'vue-router'
import Layout from '@/layout/index.vue'
import { useUserStore } from '@/store/user'

const routes = [
  {
    path: '/login',
    component: () => import('@/views/login/index.vue')
  },
  {
    path: '/',
    component: Layout,
    redirect: '/song',
    children: [
      {
        path: 'song',
        component: () => import('@/views/song/index.vue')
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫
router.beforeEach((to, from, next) => {
  const userStore = useUserStore()
  if (to.path !== '/login' && !userStore.token) {
    next('/login')
  } else {
    next()
  }
})

export default router
```

#### 2. 入口文件 (`src/main.ts`)

```typescript
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import App from './App.vue'
import router from './router'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(ElementPlus)

app.mount('#app')
```

#### 3. 根组件 (`src/App.vue`)

```vue
<template>
  <router-view />
</template>

<style>
body { margin: 0; padding: 0; font-family: sans-serif; }
</style>
```

---

### 第七阶段：运行与测试

1. **在后端配置允许跨域**：确保 Gateway 的 CORS 允许了前端端口（或 `AllowAnyOrigin`）。
2. **启动 AppHost**：
   * Aspire 会自动启动 Vue 项目。
   * 浏览器打开 `http://localhost:5173` (或者 Aspire 分配的端口)。
3. **测试流程**：
   * **登录**：输入默认账号密码 -> 成功跳转首页。
   * **查看列表**：应该能看到之前 Postman 上传的歌。
   * **上传**：点击按钮 -> 填信息 -> 选文件 -> 确定。
   * **验证**：看到提示成功，等待几秒刷新，列表出现新歌。
   * **验证 Flutter**：打开 Flutter 客户端刷新，新歌也同步出现了！




sequenceDiagram
    autonumber
    participant Vue as Vue前端
    participant Gateway as 网关(YARP)
    participant Catalog as Catalog Service
    participant Media as Media Service
    participant MinIO as 对象存储
    participant MQ as RabbitMQ
    participant Worker as Transcoding Worker

    Note over Vue, Catalog: 第一阶段：元数据创建
    Vue->>Gateway: POST /api/songs (Title, Artist...)
    Gateway->>Catalog: 转发请求
    Catalog->>Catalog: DB: Insert Song (Status=Draft)
    Catalog-->>Vue: 返回 SongId

    Note over Vue, MinIO: 第二阶段：直传文件 (流量卸载)
    Vue->>Gateway: POST /api/media/upload/init (FileName, Type)
    Gateway->>Media: 转发请求
    Media->>Media: 1. DB: Insert MediaFile (Status=Pending)`<br/>`2. S3 SDK: 生成预签名 URL (PUT)
    Media-->>Vue: 返回 uploadUrl, uploadId

    Vue->>MinIO: PUT uploadUrl (Binary File)
    Note right of Vue: ⚠️ 不经过后端服务器`<br/>`直接传给存储，节省带宽
    MinIO-->>Vue: 200 OK

    Note over Vue, Worker: 第三阶段：确认与异步处理
    Vue->>Gateway: POST /api/media/upload/confirm
    Gateway->>Media: 转发请求
    Media->>Media: DB: Update Status=Uploaded
    Media->>MQ: 🚀 Publish: MediaUploadedEvent (Outbox模式)
    Media-->>Vue: 200 OK (前端流程结束)

    MQ->>Worker: 消费消息
    Worker->>MinIO: 下载原始文件
    Worker->>Worker: 提取标签 (TagLib) + FFmpeg 转码 (HLS)
    Worker->>MinIO: 上传 .m3u8 和 .ts 切片
    Worker->>MQ: 🚀 Publish: MediaProcessedEvent

    MQ->>Catalog: 消费消息
    Catalog->>Catalog: DB: Update Song (Url, Status=Ready)

    Note over Catalog: 第四阶段：数据对齐
    Vue->>Gateway: 刷新列表 (GET /api/songs)
    Gateway->>Catalog: 查询 DB
    Catalog-->>Vue: 返回包含 m3u8 地址的完整数据
