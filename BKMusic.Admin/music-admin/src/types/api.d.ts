// 通用响应结构，对应后端 Result<T>
export interface ApiResponse<T = any> {
    isSuccess: boolean;
    isFailure: boolean;
    error?: ApiError;
    value?: T; // 后端的实际数据
}

// 错误结构，对应后端 Error
export interface ApiError {
    code: string;
    description: string;
}

// 分页结构 (如果有用到 PagedResult<T>)
export interface PagedResult<T> {
    items: T[];
    pageNumber: number;
    pageSize: number;
    totalCount: number;
    hasNextPage: boolean;
    hasPreviousPage: boolean;
}