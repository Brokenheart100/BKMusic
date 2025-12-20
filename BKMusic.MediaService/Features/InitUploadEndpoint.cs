using System.Security.Claims;
using BKMusic.MediaService.Data;
using BKMusic.MediaService.Domain;
using BKMusic.MediaService.Services;
using BKMusic.Shared.Results;
using Microsoft.AspNetCore.Mvc;

namespace BKMusic.MediaService.Features;

// 【修复】DTO 必须包含所有需要的字段
public record InitUploadRequest(Guid? SongId, string FileName, string ContentType, string? Category);

public record InitUploadResponse(Guid UploadId, string UploadUrl, string Key);

public static class InitUploadEndpoint
{
    public static async Task<IResult> Handle(
        [FromBody] InitUploadRequest request,
        ClaimsPrincipal user,
        MediaDbContext dbContext,
        ILogger<Program> logger,
        IStorageService storageService)
    {
        logger.LogInformation("【Media】收到 InitUpload 请求: {FileName}, Category: {Category}", request.FileName, request.Category);

        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? "temp";

        // 1. 确定文件夹前缀
        string folderPrefix = request.Category?.ToLower() switch
        {
            "avatar" => $"avatars/{userId}",
            "cover" => $"covers/{DateTime.UtcNow:yyyyMM}",
            _ => $"audio/{DateTime.UtcNow:yyyy/MM/dd}"
        };

        // 2. 创建实体
        // 如果 Category 是 avatar，SongId 可以为空；如果是音频，SongId 应该有值
        // 这里用 Guid.Empty 作为兜底，或者允许 nullable
        var songId = request.SongId ?? Guid.Empty;

        var mediaFile = MediaFile.Create(
            songId,
            request.FileName,
            request.ContentType,
            "music-raw",
            folderPrefix
        );

        dbContext.MediaFiles.Add(mediaFile);
        await dbContext.SaveChangesAsync();

        // 3. 确保存储桶存在
        try
        {
            await storageService.EnsureBucketExistsAsync(mediaFile.BucketName);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "【Media】创建/检查 Bucket 失败");
            return Results.Problem("Failed to ensure bucket exists.");
        }

        // 4. 生成 URL
        var presignedUrl = await storageService.GeneratePresignedUploadUrlAsync(
            mediaFile.BucketName,
            mediaFile.StorageKey,
            request.ContentType,
            TimeSpan.FromMinutes(10)
        );

        logger.LogInformation("【Media】生成的预签名 URL: {Url}", presignedUrl);

        var response = new InitUploadResponse(mediaFile.Id, presignedUrl, mediaFile.StorageKey);
        return Results.Ok(Result.Success(response));
    }
}