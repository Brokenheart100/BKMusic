using BKMusic.Shared.Domain;

namespace BKMusic.MediaService.Domain;

public enum MediaStatus
{
    Pending = 0,
    Uploaded = 1,
    Processing = 2,
    Ready = 3,
    Failed = 4
}

public class MediaFile : Entity<Guid>
{
    public Guid SongId { get; private set; }
    public string FileName { get; private set; }
    public string ContentType { get; private set; }
    public long FileSize { get; private set; }
    public string BucketName { get; private set; }
    public string StorageKey { get; private set; }
    public MediaStatus Status { get; private set; }
    public DateTime CreatedAt { get; private set; }

    private MediaFile(Guid id) : base(id) { }

    public static MediaFile Create(Guid songId, string fileName, string contentType, string bucketName, string? folderPrefix = null)
    {
        var fileId = Guid.NewGuid();
        var extension = Path.GetExtension(fileName);

        // 智能路径生成
        string directory = string.IsNullOrEmpty(folderPrefix)
            ? $"{DateTime.UtcNow:yyyy/MM/dd}"
            : folderPrefix;

        return new MediaFile(fileId)
        {
            SongId = songId,
            FileName = fileName,
            ContentType = contentType,
            BucketName = bucketName,
            StorageKey = $"{directory}/{fileId}{extension}", // 拼接完整路径
            Status = MediaStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
    }

    public void MarkAsUploaded(long fileSize)
    {
        if (Status != MediaStatus.Pending) return;
        Status = MediaStatus.Uploaded;
        FileSize = fileSize;
    }
}