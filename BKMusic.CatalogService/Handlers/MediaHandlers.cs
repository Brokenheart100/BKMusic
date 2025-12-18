using BKMusic.CatalogService.Data;
using BKMusic.Shared.Messaging;
using Microsoft.EntityFrameworkCore; // 引入 EF Core 命名空间
using Wolverine;
using Wolverine.Attributes;

namespace BKMusic.CatalogService.Handlers;

[WolverineHandler]
public class MediaHandlers
{
    // Wolverine 会自动注入 DbContext 和 ILogger
    public async Task Handle(
        MediaProcessedEvent @event,
        CatalogDbContext dbContext,
        ILogger<MediaHandlers> logger)
    {
        // ✅ 收到消息
        logger.LogInformation("✅ [Catalog] 收到 MediaProcessedEvent: {SongId}", @event.SongId);

        // 1. 查询数据库
        var song = await dbContext.Songs.FindAsync(@event.SongId);

        if (song == null)
        {
            // ⚠️ 警告：找到了消息，但数据库里没有对应的歌
            logger.LogWarning("⚠️ [Catalog] 找不到要更新的歌曲记录: {SongId}", @event.SongId);
            return; // 中断处理
        }

        logger.LogInformation("  🎵 [Catalog] 正在更新歌曲元数据...");
        logger.LogInformation("    - Title: {Title}, Artist: {Artist}, Album: {Album}",
            @event.Title, @event.Artist, @event.Album);

        // 2. 调用实体方法更新状态
        song.SetPlayable(
            @event.HlsUrl,
            @event.DurationSeconds,
            @event.Title,
            @event.Artist,
            @event.Album,
            @event.CoverStorageKey
        );

        // 3. 保存到数据库
        try
        {
            await dbContext.SaveChangesAsync();
            // 🎉 成功
            logger.LogInformation("🎉 [Catalog] 歌曲 {SongId} 已成功更新为 'Ready' 状态。", @event.SongId);
        }
        catch (DbUpdateException ex)
        {
            // ❌ 数据库错误
            logger.LogError(ex, "❌ [Catalog] 更新歌曲 {SongId} 时数据库保存失败。", @event.SongId);
            // 重新抛出异常，让 Wolverine 根据策略重试或移入死信队列
            throw;
        }
    }
}