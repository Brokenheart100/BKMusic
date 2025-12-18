import request from '../utils/request';
import type { ApiResponse } from '../types/api';

// --- DTO 定义 ---

export interface SongDto {
    id: string;        // Guid 转 string
    title: string;
    artist: string;
    url: string;       // m3u8 播放地址
    coverUrl?: string; // 封面图
}

export interface CreateSongRequest {
    title: string;
    artist: string;
    album: string;
    coverUrl?: string;
}

// --- API 方法 ---

/**
 * 获取歌曲列表
 * GET /api/songs
 */
export const getSongs = () => {
    return request.get<any, ApiResponse<SongDto[]>>('/api/songs');
};

/**
 * 获取单曲详情
 * GET /api/songs/{id}
 */
export const getSongDetail = (id: string) => {
    return request.get<any, ApiResponse<SongDto>>(`/api/songs/${id}`);
};

/**
 * 创建歌曲元数据 (返回 SongId)
 * POST /api/songs
 */
export const createSong = (data: CreateSongRequest) => {
    // 后端返回的是 Result<Guid>，前端对应 string
    return request.post<any, ApiResponse<string>>('/api/songs', data);
};

export const deleteSong = (id: string) => {
    return request.delete<any, ApiResponse<void>>(`/api/songs/${id}`);
};