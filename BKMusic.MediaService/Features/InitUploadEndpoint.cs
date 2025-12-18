using BKMusic.MediaService.Data;
using BKMusic.MediaService.Domain;
using BKMusic.MediaService.Services;
using BKMusic.Shared.Results;
using Microsoft.AspNetCore.Mvc;

namespace BKMusic.MediaService.Features;
// Request DTO
public record InitUploadRequest(Guid SongId, string FileName, string ContentType);

// Response DTO
public record InitUploadResponse(Guid UploadId, string UploadUrl, string Key);

public static class InitUploadEndpoint
{
    public static async Task<IResult> Handle(
        [FromBody] InitUploadRequest request,
        MediaDbContext dbContext,
        ILogger<Program> logger,
        IStorageService storageService)
    {
        logger.LogInformation("【Media】收到 InitUpload 请求: {FileName}", request.FileName);
        // 1. 创建数据库记录 (Status = Pending)
        var mediaFile = MediaFile.Create(request.SongId, request.FileName, request.ContentType, "music-raw");

        dbContext.MediaFiles.Add(mediaFile);
        await dbContext.SaveChangesAsync();


        // 【核心检查】确保这行代码被调用了！
        try
        {
            await storageService.EnsureBucketExistsAsync(mediaFile.BucketName);
            logger.LogInformation("【Media】Bucket '{BucketName}' 已确认存在。", mediaFile.BucketName);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "【Media】创建/检查 Bucket 时发生错误！");
            // 创建桶失败，直接返回错误，避免前端拿到无效 URL
            return Results.Problem("Failed to ensure bucket exists.");
        }


        // 2. 生成 S3 预签名 URL (有效期 10 分钟)
        var presignedUrl = await storageService.GeneratePresignedUploadUrlAsync(
            mediaFile.BucketName,
            mediaFile.StorageKey,
            request.ContentType, // 确保 contentType 被传递
            TimeSpan.FromMinutes(10)
        );
        logger.LogInformation("【Media】生成的预签名 URL: {Url}", presignedUrl);
        // 3. 返回给前端
        var response = new InitUploadResponse(mediaFile.Id, presignedUrl, mediaFile.StorageKey);
        return Results.Ok(Result.Success(response));
    }
}