using BKMusic.Shared.Messaging;
using BKMusic.TranscodingWorker.Services;
using TagLib;
using Wolverine;
using Wolverine.Attributes;

namespace BKMusic.TranscodingWorker.Handlers;

[WolverineHandler] // 加上也无妨，保持明确
public class MediaHandlers
{
    private static string GetExtensionFromMimeType(string mimeType)
    {
        return mimeType?.ToLower() switch
        {
            "image/jpeg" => ".jpg",
            "image/png" => ".png",
            "image/gif" => ".gif",
            // 添加更多你可能遇到的类型
            _ => ".jpg" // 默认返回 .jpg
        };
    }
    // 【修改1】改回 async Task<...>
    public async Task<MediaProcessedEvent> Handle(
        MediaUploadedEvent @event,
        IStorageService storage,
         IFfmpegService ffmpeg, // 暂时不用
        ILogger<MediaHandlers> logger)
    {
        logger.LogInformation("✅ [Worker] 收到任务 (简化版): {SongId}", @event.SongId);

        var tempPath = Path.Combine(Path.GetTempPath(), "music_transcode", @event.SongId.ToString());
        var inputFile = Path.Combine(tempPath, "input_raw" + Path.GetExtension(@event.FileKey));
        var outputDir = Path.Combine(tempPath, "hls_output");

        try
        {
            Directory.CreateDirectory(tempPath);

            // 1. 下载文件 (使用 await)
            logger.LogInformation("  📥 [Worker] 下载文件...");
            await storage.DownloadFileAsync(@event.BucketName, @event.FileKey, inputFile);
            logger.LogInformation("  📥 [Worker] 文件下载成功。");

            // 2. 解析元数据 (使用 await)
            logger.LogInformation("  🎵 [Worker] 解析元数据...");
            var metadata = await ExtractMetadataAsync(inputFile, @event.SongId, storage, logger);
            logger.LogInformation("  🎵 [Worker] 元数据解析完成: Title={Title}", metadata.Title);

            // 3. 【核心修改】执行 FFmpeg 转码
            logger.LogInformation("  🎞️ [Worker] 开始 FFmpeg 转码...");
            var success = await ffmpeg.ConvertToHlsAsync(inputFile, outputDir);
            if (!success)
            {
                // 如果转码失败，抛出异常，让 Wolverine 根据策略重试
                throw new InvalidOperationException($"FFmpeg transcoding failed for SongId: {@event.SongId}");
            }
            logger.LogInformation("  🎞️ [Worker] FFmpeg 转码成功。");

            // 4. 上传 HLS 文件
            logger.LogInformation("  📤 [Worker] 开始上传 HLS 文件到 'music-hls' 桶...");
            var s3KeyPrefix = $"hls/{@event.SongId}";
            var hlsKey = await storage.UploadDirectoryAsync(outputDir, "music-hls", s3KeyPrefix);
            logger.LogInformation("  📤 [Worker] HLS 上传成功: {HlsKey}", hlsKey);

            // 4. 发布完成事件
            logger.LogInformation("  🚀 [Worker] 正在发布 MediaProcessedEvent...");
            return new MediaProcessedEvent(
                @event.SongId,
                hlsKey,
                metadata.Duration,
                metadata.Title,
                metadata.Artist,
                metadata.Album,
                metadata.CoverKey
            );
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "❌ [Worker] 简化流程发生错误: {SongId}", @event.SongId);
            throw;
        }
        finally
        {
            if (Directory.Exists(tempPath))
            {
                logger.LogInformation("  🧹 [Worker] 清理临时文件: {Path}", tempPath);
                Directory.Delete(tempPath, true);
            }
        }
    }

    // 【修改2】增加 ILogger 参数，用于记录内部日志
    private async Task<(string? Title, string? Artist, string? Album, double Duration, string? CoverKey)>
        ExtractMetadataAsync(string filePath, Guid songId, IStorageService storage, ILogger logger)
    {
        try
        {
            var file = TagLib.File.Create(filePath);
            var title = file.Tag.Title;
            var artist = file.Tag.FirstPerformer ?? file.Tag.Performers.FirstOrDefault();
            var album = file.Tag.Album;
            var duration = file.Properties.Duration.TotalSeconds;
            string? coverKey = null;

            if (file.Tag.Pictures.Length > 0)
            {
                var pic = file.Tag.Pictures[0];
                var coverData = pic.Data.Data;
                var coverExt = GetExtensionFromMimeType(pic.MimeType);

                var coverTempPath = filePath + "_cover" + coverExt;
                await System.IO.File.WriteAllBytesAsync(coverTempPath, coverData);

                coverKey = $"covers/{songId}{coverExt}";
                logger.LogInformation("    🖼️ [Worker] 提取到封面，正在上传到: {CoverKey}", coverKey);
                await storage.UploadSingleFileAsync("music-covers", coverKey, coverTempPath);
            }
            else
            {
                logger.LogWarning("    ⚠️ [Worker] 未在文件中找到内嵌封面。");
            }

            return (title, artist, album, duration, coverKey);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "    ❌ [Worker] 元数据解析失败。");
            return (null, null, null, 0, null);
        }
    }
}