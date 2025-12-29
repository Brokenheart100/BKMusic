import request from '../utils/request';
import axios from 'axios';
import type { ApiResponse } from '../types/api';

// --- DTO 定义 ---

export interface InitUploadRequest {
    songId?: string;    // 允许为空 (上传头像时)
    fileName: string;
    contentType: string;
    category?: string;  // 【核心修复】添加 category 字段
}

export interface InitUploadResponse {
    uploadId: string;
    uploadUrl: string;
    key: string;
}

export interface ConfirmUploadRequest {
    uploadId: string;
}

// --- API 方法 ---

/**
 * 1. 申请上传链接
 */
export const initUpload = (data: InitUploadRequest) => {
    return request.post<any, ApiResponse<InitUploadResponse>>('/api/media/upload/init', data);
};

/**
 * 2. 物理文件直传 (直接 PUT 到 MinIO/S3)
 * 【核心修复】增加 contentType 参数，确保与 initUpload 时一致，防止 403 签名错误
 */
export const uploadToMinio = (url: string, file: File, contentType: string) => {
    return axios.put(url, file, {
        headers: {
            'Content-Type': contentType
        },
        onUploadProgress: (progressEvent) => {
            // 可选：打印进度
            if (import.meta.env.DEV) {
                const percent = Math.round((progressEvent.loaded * 100) / (progressEvent.total || 1));
                console.log(`Upload: ${percent}%`);
            }
        }
    });
};

/**
 * 3. 确认上传
 */
export const confirmUpload = (uploadId: string) => {
    return request.post<any, ApiResponse<void>>('/api/media/upload/confirm', { uploadId });
};