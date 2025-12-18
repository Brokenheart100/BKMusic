using BKMusic.MediaService.Data;
using BKMusic.MediaService.Services;
using BKMusic.Shared.Messaging;
using Microsoft.EntityFrameworkCore;
using Wolverine;
using Wolverine.Attributes;

namespace BKMusic.MediaService.Handlers;

[WolverineHandler]
public class SongDeletedHandler
{
    public async Task Handle(
        SongDeletedEvent @event,
        MediaDbContext dbContext,
        IStorageService storage,
        ILogger<SongDeletedHandler> logger)
    {
        logger.LogInformation("⚠️ 收到删除请求，开始清理资源: {SongId}", @event.SongId);

        // 1. 清理数据库 (MediaFiles)
        // 注意：MediaFile 表里我们之前加了 SongId 字段
        var mediaFiles = await dbContext.MediaFiles
            .Where(m => m.SongId == @event.SongId)
            .ToListAsync();

        if (mediaFiles.Count != 0)
        {
            // 2. 清理 music-raw (原始文件)
            foreach (var file in mediaFiles)
            {
                await storage.DeleteFileAsync(file.BucketName, file.StorageKey);
            }

            // 从数据库移除记录
            dbContext.MediaFiles.RemoveRange(mediaFiles);
            await dbContext.SaveChangesAsync();
            logger.LogInformation("已清理 MediaFiles 数据库记录");
        }

        // 3. 清理 music-hls (转码文件)
        // 约定路径规则: hls/{SongId}/...
        await storage.DeleteDirectoryAsync("music-hls", $"hls/{@event.SongId}");

        // 4. 清理 music-covers (封面图)
        // 约定路径规则: covers/{SongId}.jpg
        // 我们尝试删除 jpg 和 png 两种可能
        await storage.DeleteFileAsync("music-covers", $"covers/{@event.SongId}.jpg");
        await storage.DeleteFileAsync("music-covers", $"covers/{@event.SongId}.png");

        logger.LogInformation("✅ 资源清理完毕: {SongId}", @event.SongId);
    }
}