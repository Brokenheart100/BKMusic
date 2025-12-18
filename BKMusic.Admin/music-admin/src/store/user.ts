import { defineStore } from 'pinia';
import { ref, computed } from 'vue';

export const useUserStore = defineStore('user', () => {
    // 1. State
    // 从 localStorage 初始化，防止刷新丢失
    const token = ref<string>(localStorage.getItem('access_token') || '');
    const refreshToken = ref<string>(localStorage.getItem('refresh_token') || '');
    const nickname = ref<string>(localStorage.getItem('nickname') || '');

    // 2. Getters
    const isLoggedIn = computed(() => !!token.value);

    // 3. Actions

    // 设置登录状态
    const setLoginState = (accessToken: string, newRefreshToken: string) => {
        token.value = accessToken;
        refreshToken.value = newRefreshToken;

        // 持久化
        localStorage.setItem('access_token', accessToken);
        localStorage.setItem('refresh_token', newRefreshToken);
    };

    // 设置用户信息
    const setUserInfo = (name: string) => {
        nickname.value = name;
        localStorage.setItem('nickname', name);
    };

    // 登出 (清除所有状态)
    const logout = () => {
        token.value = '';
        refreshToken.value = '';
        nickname.value = '';

        localStorage.clear(); // 或者只移除特定 key

        // 强制重定向到登录页
        // 注意：这里不使用 router.push，因为可能在 axios 拦截器外部调用
        window.location.href = '/login';
    };

    return {
        token,
        refreshToken,
        nickname,
        isLoggedIn,
        setLoginState,
        setUserInfo,
        logout
    };
});