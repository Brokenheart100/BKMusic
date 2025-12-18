using BKMusic.Shared.Domain;

namespace BKMusic.CatalogService.Domain;

public class Song : Entity<Guid>
{
    public string Title { get; private set; }
    public string ArtistName { get; private set; } // 简化设计，暂不关联 Artist 表
    public string AlbumName { get; private set; }

    // 核心字段：HLS 播放地址 (MinIO/S3 的 Key)
    public string? HlsStorageKey { get; private set; }

    // 歌曲时长 (秒)
    public double Duration { get; private set; }

    // 状态：Draft(草稿) -> Processing(转码中) -> Ready(可播放)
    public SongStatus Status { get; private set; }

    public string? CoverUrl { get; private set; }

    private Song(Guid id) : base(id) { }

    public static Song Create(string title, string artist, string album, string? coverUrl)
    {
        return new Song(Guid.NewGuid())
        {
            Title = title,
            ArtistName = artist,
            AlbumName = album,
            Status = SongStatus.Draft,
            CoverUrl = coverUrl
        };
    }

    // 当转码完成时调用
    // 修改 SetPlayable 方法，接收更多参数
    public void SetPlayable(string hlsKey, double duration, string? title, string? artist, string? album, string? coverKey)
    {
        HlsStorageKey = hlsKey;
        Duration = duration;
        Status = SongStatus.Ready;

        // 如果 Worker 解析到了数据，且当前数据库里是默认值/空值，则更新
        // 或者你可以强制覆盖，取决于业务策略。这里采用“优先使用解析值”策略。
        if (!string.IsNullOrEmpty(title)) Title = title;
        if (!string.IsNullOrEmpty(artist)) ArtistName = artist;
        if (!string.IsNullOrEmpty(album)) AlbumName = album;

        // 如果有封面，更新封面
        if (!string.IsNullOrEmpty(coverKey))
        {
            // 假设 MinIO 配置在 AppSettings
            // 注意：这里最好只存 Key，由 API 拼接 Host，或者这里简单拼接一下
            // 为了演示，我们假设前端能拼接，或者这里存完整 URL
            // 实际上 Catalog Service 知道 MinIO_PublicHost
            CoverUrl = coverKey; // 这里存 Key，API 吐出去的时候再拼 Host
        }
    }
}

public enum SongStatus { Draft, Processing, Ready }