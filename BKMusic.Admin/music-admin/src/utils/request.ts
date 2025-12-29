import axios, { type InternalAxiosRequestConfig, type AxiosResponse } from 'axios';
import { ElMessage, ElNotification } from 'element-plus';
import { createConsola } from "consola/browser"; // 使用浏览器版构建
import { useUserStore } from '../store/user';
import type { ApiResponse } from '../types/api';

// 初始化 Consola 实例 (配置日志级别)
const logger = createConsola({
    level: import.meta.env.DEV ? 4 : 0, // 开发环境显示所有，生产环境静默
});

// 1. 创建 Axios 实例
const service = axios.create({
    // baseURL: import.meta.env.VITE_API_BASE_URL || '/',
    baseURL: '/api',
    timeout: 15000,
    headers: {
        'Content-Type': 'application/json',
    },
});

// 2. 请求拦截器 (Request Interceptor)
service.interceptors.request.use(
    (config: InternalAxiosRequestConfig) => {
        const userStore = useUserStore();
        if (userStore.token) {
            config.headers.Authorization = `Bearer ${userStore.token}`;
        }

        // 【Consola 日志】请求开始
        if (import.meta.env.DEV) {
            // 使用 start 类型表示流程开始
            logger.start(`🚀 发起请求 [${config.method?.toUpperCase()}]`);
            logger.info(`🌐 URL: ${config.url}`);

            if (config.params) {
                logger.log(`   🔍 Query Params:`, config.params);
            }
            if (config.data) {
                logger.log(`   📦 Body Data:`, config.data);
            }
            // 打印 Headers 比较杂，折叠起来
            console.groupCollapsed(`   🏷️ Headers (点击展开)`);
            console.log(config.headers);
            console.groupEnd();
        }

        return config;
    },
    (error: any) => {
        if (import.meta.env.DEV) {
            logger.error(`❌ 请求构建失败:`, error);
        }
        return Promise.reject(error);
    }
);

// 3. 响应拦截器 (Response Interceptor)
service.interceptors.response.use(
    (response: AxiosResponse<ApiResponse>) => {
        const res = response.data;
        const url = response.config.url?.replace(response.config.baseURL || '', '');

        // 【Consola 日志】响应成功
        if (import.meta.env.DEV) {
            // 使用 success 类型表示成功
            logger.success(`✅ 请求成功 [${response.config.method?.toUpperCase()}] ${url}`);
            logger.log(`   🔢 Status: ${response.status}`);

            // 智能打印数据：如果是列表，打印长度；如果是对象，打印详情
            if (Array.isArray(res.value)) {
                logger.log(`   📚 Data (Array): Length ${res.value.length}`, res);
            } else {
                logger.log(`   📄 Data (Object):`, res);
            }

            // 分割线，让日志更清晰
            console.log('%c------------------------------------------------------------------', 'color: #eee');
        }

        return res as any;
    },
    (error: any) => {
        const { response } = error;
        const url = error.config?.url || 'Unknown URL';

        // 【Consola 日志】响应错误
        if (import.meta.env.DEV) {
            logger.error(`💥 请求报错 [${url}]`);
            logger.log(`   🛑 Error Name: ${error.name}`);
            logger.log(`   📢 Message: ${error.message}`);

            if (response) {
                logger.warn(`   🔢 Status Code: ${response.status}`);
                logger.warn(`   📉 Response Data:`, response.data);
            }
            console.log('%c------------------------------------------------------------------', 'color: #ffcccc');
        }

        // 统一错误处理逻辑 (保持不变)
        if (response) {
            const status = response.status;
            const data = response.data as ApiResponse;

            switch (status) {
                case 400:
                    ElMessage.error(data.error?.description || '请求参数有误');
                    break;
                case 401:
                    handle401();
                    break;
                case 403:
                    ElMessage.warning('您没有权限执行此操作');
                    break;
                case 404:
                    ElMessage.error('请求的资源不存在');
                    break;
                case 500:
                    ElMessage.error('服务器内部错误，请联系管理员');
                    break;
                default:
                    ElMessage.error(data.error?.description || `网络错误 ${status}`);
            }
        } else {
            if (error.message.includes('timeout')) {
                ElMessage.error('请求超时，请检查网络');
            } else {
                ElMessage.error('网络连接异常');
            }
        }

        return Promise.reject(error);
    }
);

// 401 处理逻辑
let isRelogging = false;
function handle401() {
    if (isRelogging) return;
    isRelogging = true;

    // 使用 Consola 打印醒目的警告
    if (import.meta.env.DEV) {
        logger.box("⚠️ 登录状态已过期，正在执行登出流程...");
    }

    ElNotification({
        title: '登录过期',
        message: '您的登录状态已失效，请重新登录',
        type: 'warning',
        duration: 3000,
        onClose: () => {
            const userStore = useUserStore();
            userStore.logout();
            isRelogging = false;
        }
    });

    const userStore = useUserStore();
    userStore.logout();
}

export default service;