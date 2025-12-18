import { createApp } from 'vue';
import { createPinia } from 'pinia';

// 1. 引入 Element Plus 及其样式
import ElementPlus from 'element-plus';
import 'element-plus/dist/index.css';
// 引入暗黑模式样式 (可选，企业级常用)
import 'element-plus/theme-chalk/dark/css-vars.css';
// 引入所有图标
import * as ElementPlusIconsVue from '@element-plus/icons-vue';

// 2. 引入自定义全局样式
import '@/styles/index.scss';

import App from './App.vue';
import router from './router';

const app = createApp(App);

// 3. 注册 Pinia (状态管理)
const pinia = createPinia();
app.use(pinia);

// 4. 注册 Router (路由)
// 注意：Router 依赖 Pinia 中的 UserStore (在守卫中)，所以建议先注册 Pinia
app.use(router);

// 5. 注册 Element Plus
app.use(ElementPlus);

// 6. 全局注册所有图标 (方便动态组件使用)
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
    app.component(key, component);
}

app.mount('#app');