import request from '../utils/request';
import type { ApiResponse } from '../types/api';

// --- DTO 定义 (对应后端 record) ---

export interface LoginRequest {
    email: string;
    password: string;
}

export interface AuthResponse {
    accessToken: string;
    refreshToken: string;
}


/**
 * 用户登录
 * POST /api/auth/login
 */
export const login = (data: LoginRequest) => {
    // 泛型说明：
    // 第一个 any: AxiosRequestConfig 的类型 (通常不关注)
    // 第二个 ApiResponse<AuthResponse>: 我们期望返回的结构
    return request.post<any, ApiResponse<AuthResponse>>('/api/auth/login', data);
};

/**
 * 刷新 Token (可选，通常在拦截器自动处理，但在后台管理中有时需要手动触发)
 * POST /api/auth/refresh
 */
export const refreshToken = (data: { accessToken: string; refreshToken: string }) => {
    return request.post<any, ApiResponse<AuthResponse>>('/api/auth/refresh', data);
};