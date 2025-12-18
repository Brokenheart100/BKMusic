import request from '../utils/request';
import axios from 'axios'; // 引入原生 axios 用于直传
import type { ApiResponse } from '../types/api';

// --- DTO 定义 ---
export interface InitUploadRequest {
    songId: string; // 关联的歌曲 ID
    fileName: string;
    contentType: string;
}

export interface InitUploadResponse {
    uploadId: string; // 业务流水号
    uploadUrl: string; // MinIO 预签名 PUT 地址
    key: string; // 存储路径
}

export interface ConfirmUploadRequest {
    uploadId: string;
}

// --- API 方法 ---

/**
 * 1. 申请上传链接
 * POST /api/media/upload/init
 */
export const initUpload = (data: InitUploadRequest) => {
    if (import.meta.env.DEV) {
        console.groupCollapsed('📤 [Media API] Init Upload Request');
        console.log('File Name:', data.fileName);
        console.log('Content Type:', data.contentType);
        console.groupEnd();
    }

    return request.post<any, ApiResponse<InitUploadResponse>>('/api/media/upload/init', data)
        .then((response) => {
            if (import.meta.env.DEV) {
                console.group('✅ [Media API] Init Upload Success');
                console.log('Upload ID:', response.value?.uploadId);
                console.log('Object Key:', response.value?.key);
                console.log('Presigned URL:', response.value?.uploadUrl);
                // 特别突出协议部分，便于检查是 http 还是 https
                console.log('URL Protocol:', response.value?.uploadUrl?.startsWith('https') ? 'HTTPS 🔒' : 'HTTP 🔓');
                console.groupEnd();
            }
            return response;
        })
        .catch((error) => {
            if (import.meta.env.DEV) {
                console.group('❌ [Media API] Init Upload Failed');
                console.error(error);
                console.groupEnd();
            }
            throw error;
        });
};

/**
 * 2. 物理文件直传 (直接 PUT 到 MinIO/S3)
 * 注意：不走网关，不走拦截器
 */
export const uploadToMinio = (url: string, file: File) => {
    if (import.meta.env.DEV) {
        console.groupCollapsed('⬆️ [Media API] Direct Upload to MinIO/S3');
        console.log('Target URL:', url);
        console.log('URL Protocol:', url.startsWith('https') ? 'HTTPS 🔒' : 'HTTP 🔓');
        console.log('File Name:', file.name);
        console.log('File Size:', (file.size / 1024 / 1024).toFixed(2) + ' MB');
        console.log('File Type:', file.type);
        console.groupEnd();
    }

    return axios.put(url, file, {
        headers: {
            'Content-Type': file.type || 'application/octet-stream'
        },
        // 上传进度回调
        onUploadProgress: (progressEvent) => {
            if (!progressEvent.total) return;

            const percentCompleted = Math.round(
                (progressEvent.loaded * 100) / progressEvent.total
            );

            // 开发环境实时打印进度（不会太频繁影响性能）
            if (import.meta.env.DEV) {
                console.log(`⬆️ Upload Progress: ${percentCompleted}% (${(progressEvent.loaded / 1024 / 1024).toFixed(2)} MB / ${(progressEvent.total / 1024 / 1024).toFixed(2)} MB)`);
            }

            // 如果你在组件中需要进度，可以通过事件或 Pinia 抛出，这里仅示例
            // emit('progress', percentCompleted);
        },
    })
        .then((response) => {
            if (import.meta.env.DEV) {
                console.group('✅ [Media API] Direct Upload Success');
                console.log('Status:', response.status);
                console.log('Headers:', response.headers);
                console.groupEnd();
            }
            return response;
        })
        .catch((error) => {
            if (import.meta.env.DEV) {
                console.group('❌ [Media API] Direct Upload Failed');
                if (error.response) {
                    console.error('Status:', error.response.status);
                    console.error('Data:', error.response.data);
                    console.error('Headers:', error.response.headers);
                } else {
                    console.error('Error Message:', error.message);
                    console.error('Error Code:', error.code);
                }
                console.groupEnd();
            }
            throw error;
        });
};

/**
 * 3. 确认上传 (通知后端开始转码)
 * POST /api/media/upload/confirm
 */
export const confirmUpload = (uploadId: string) => {
    if (import.meta.env.DEV) {
        console.groupCollapsed('✔️ [Media API] Confirm Upload');
        console.log('Upload ID:', uploadId);
        console.groupEnd();
    }

    return request.post<any, ApiResponse<void>>('/api/media/upload/confirm', { uploadId })
        .then((response) => {
            if (import.meta.env.DEV) {
                console.group('✅ [Media API] Confirm Upload Success');
                console.log('Response:', response);
                console.groupEnd();
            }
            return response;
        })
        .catch((error) => {
            if (import.meta.env.DEV) {
                console.group('❌ [Media API] Confirm Upload Failed');
                console.error(error);
                console.groupEnd();
            }
            throw error;
        });
};