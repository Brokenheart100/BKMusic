using BKMusic.MediaService.Data;
using BKMusic.Shared.Messaging;
using BKMusic.Shared.Results;
using Microsoft.AspNetCore.Mvc;
using Wolverine;

namespace BKMusic.MediaService.Features;

public record ConfirmUploadRequest(Guid UploadId);

public static class ConfirmUploadEndpoint
{
    public static async Task<IResult> Handle(
        [FromBody] ConfirmUploadRequest request,
        MediaDbContext dbContext,
        ILogger<Program> logger,
        IMessageBus bus) // 【修改点】注入 Wolverine 的 Bus
    {
        logger.LogInformation("【Media】收到 ConfirmUpload 请求: {UploadId}", request.UploadId);
        // 1. 查询记录
        var mediaFile = await dbContext.MediaFiles.FindAsync(request.UploadId);

        if (mediaFile == null)
        {
            logger.LogWarning("【Media】ConfirmUpload 失败，未找到记录: {UploadId}", request.UploadId);
            return Results.NotFound(Result.Failure(new Error("Media.NotFound", "Upload not found")));
        }

        if (mediaFile.Status != Domain.MediaStatus.Pending)
            return Results.Ok(Result.Success());

        // 2. 更新实体状态
        mediaFile.MarkAsUploaded(0);

        logger.LogInformation("【Media】正在发布 MediaUploadedEvent 事件...");
        // 3. 【修改点】发送消息
        // 由于我们在 Program.cs 启用了 Outbox，这行代码并不会发起网络请求
        // 而是仅仅把消息标记为 "待发送"，并在下一步 SaveChangesAsync 时随事务一起提交
        await bus.PublishAsync(new MediaUploadedEvent(
            mediaFile.SongId,
            mediaFile.BucketName,
            mediaFile.StorageKey
        ));

        // 4. 提交事务 (原子操作：保存状态 + 保存消息)
        await dbContext.SaveChangesAsync();

        logger.LogInformation("【Media】MediaUploadedEvent 已成功写入 Outbox。");

        return Results.Ok(Result.Success());
    }
}