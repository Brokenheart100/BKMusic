using System;
using System.Collections.Generic;
using System.Text;

namespace BKMusic.Shared.Messaging;
// 基础接口，用于标记这是一个集成事件
public interface IIntegrationEvent
{
    Guid Id { get; }
    DateTime OccurredOn { get; }
}

// 1. 媒体已上传事件 (Media Service 发出 -> 转码 Worker 接收)
// 包含：歌曲ID，Bucket名称，原始文件Key
public record MediaUploadedEvent(
    Guid SongId,
    string BucketName,
    string FileKey
) : IIntegrationEvent
{
    public Guid Id { get; init; } = Guid.NewGuid();
    public DateTime OccurredOn { get; init; } = DateTime.UtcNow;
}

// 2. 媒体处理完成事件 (转码 Worker 发出 -> Catalog Service 接收)
// 包含：歌曲ID，HLS播放地址，时长，波形数据

// 3. 处理失败事件
public record MediaProcessingFailedEvent(
    Guid SongId,
    string Reason
) : IIntegrationEvent
{
    public Guid Id { get; init; } = Guid.NewGuid();
    public DateTime OccurredOn { get; init; } = DateTime.UtcNow;
}


// 用户注册事件
public record UserRegisteredEvent(
    Guid UserId,
    string Email,
    string Nickname,
    string? AvatarUrl // 【新增】
) : IIntegrationEvent
{
    public Guid Id { get; init; } = Guid.NewGuid();
    public DateTime OccurredOn { get; init; } = DateTime.UtcNow;
}


// 歌曲删除事件
public record SongDeletedEvent(Guid SongId) : IIntegrationEvent
{
    public Guid Id { get; init; } = Guid.NewGuid();
    public DateTime OccurredOn { get; init; } = DateTime.UtcNow;
}

public record MediaProcessedEvent(
    Guid SongId,
    string HlsUrl,
    double DurationSeconds,
    // --- 新增字段 ---
    string? Title,
    string? Artist,
    string? Album,
    string? CoverStorageKey // 封面图在 MinIO 的地址
) : IIntegrationEvent
{
    public Guid Id { get; init; } = Guid.NewGuid();
    public DateTime OccurredOn { get; init; } = DateTime.UtcNow;
}