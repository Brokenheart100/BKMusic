using BKMusic.Shared.Domain;

namespace BKMusic.MediaService.Domain;
public enum MediaStatus
{
    Pending = 0,    // 已创建记录，但文件未上传
    Uploaded = 1,   // 文件已上传到 MinIO
    Processing = 2, // 转码中
    Ready = 3,      // 转码完成，可播放
    Failed = 4      // 处理失败
}

public class MediaFile : Entity<Guid>
{
    public Guid SongId { get; private set; }
    public string FileName { get; private set; }
    public string ContentType { get; private set; } // e.g., "audio/flac"
    public long FileSize { get; private set; }
    public string BucketName { get; private set; }
    public string StorageKey { get; private set; } // MinIO 中的文件名
    public MediaStatus Status { get; private set; }
    public DateTime CreatedAt { get; private set; }

    // EF Core 需要空构造函数
    private MediaFile(Guid id) : base(id) { }

    // 工厂方法创建实例
    public static MediaFile Create(Guid songId, string fileName, string contentType, string bucketName)
    {
        return new MediaFile(Guid.NewGuid())
        {
            SongId = songId,
            FileName = fileName,
            ContentType = contentType,
            BucketName = bucketName,
            // 生成随机唯一的文件名，防止覆盖，并按日期分目录
            StorageKey = $"{DateTime.UtcNow:yyyy/MM/dd}/{Guid.NewGuid()}{Path.GetExtension(fileName)}",
            Status = MediaStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
    }

    public void MarkAsUploaded(long fileSize)
    {
        if (Status != MediaStatus.Pending) return; // 幂等保护
        Status = MediaStatus.Uploaded;
        FileSize = fileSize;
    }
}