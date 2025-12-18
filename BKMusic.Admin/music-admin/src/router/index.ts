import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router';
import { useUserStore } from '../store/user';
import NProgress from 'nprogress';
import 'nprogress/nprogress.css'; // 引入进度条样式
import Layout from '../layout/index.vue';

// 配置 NProgress
NProgress.configure({ showSpinner: false });

// 定义路由表
// 使用 RouteRecordRaw 类型提示
const routes: RouteRecordRaw[] = [
    {
        path: '/login',
        name: 'Login',
        component: () => import('../views/login/index.vue'),
        meta: { title: '登录' }
    },
    {
        path: '/',
        component: Layout,
        redirect: '/song',
        children: [
            {
                path: 'song',
                name: 'Song',
                component: () => import('../views/song/index.vue'),
                meta: { title: '歌曲管理', requiresAuth: true }
            }
            // 未来可以在这里扩展 User, Dashboard 等模块
        ]
    },
    // 404 页面 (可选，企业级通常需要)
    {
        path: '/:pathMatch(.*)*',
        redirect: '/'
    }
];

const router = createRouter({
    // 使用 HTML5 History 模式
    history: createWebHistory(),
    routes,
    // 切换路由时滚动条复位
    scrollBehavior: () => ({ top: 0 }),
});

// --- 路由守卫 (Permission Guard) ---

const whiteList = ['/login']; // 白名单

router.beforeEach((to, _from, next) => {
    // 1. 开启进度条
    NProgress.start();

    // 2. 设置网页标题
    document.title = `${to.meta.title ? to.meta.title + ' - ' : ''}BKMusic Admin`;

    const userStore = useUserStore();

    // 3. 鉴权逻辑
    if (userStore.token) {
        // 已登录
        if (to.path === '/login') {
            next({ path: '/' }); // 已登录去登录页，重定向到首页
        } else {
            next(); // 放行
        }
    } else {
        // 未登录
        if (whiteList.includes(to.path)) {
            next(); // 在白名单，放行
        } else {
            next(`/login?redirect=${to.path}`); // 否则重定向到登录页
        }
    }
});

router.afterEach(() => {
    // 关闭进度条
    NProgress.done();
});

export default router;