using Amazon.S3;
using Amazon.S3.Model;
using Amazon.S3.Util; // 引入 AmazonS3Util

namespace BKMusic.MediaService.Services;

public interface IStorageService
{
    /// <summary>
    /// 异步生成一个用于上传（PUT）的预签名 URL。
    /// </summary>
    /// <param name="bucket">存储桶名称</param>
    /// <param name="key">对象键（文件路径）</param>
    /// <param name="contentType">文件类型</param>
    /// <param name="expiry">URL 有效期</param>
    /// <returns>预签名 URL</returns>
    Task<string> GeneratePresignedUploadUrlAsync(string bucket, string key, string contentType, TimeSpan expiry);

    /// <summary>
    /// 确保指定的存储桶存在，如果不存在则创建并配置 CORS。
    /// </summary>
    /// <param name="bucketName">存储桶名称</param>
    Task EnsureBucketExistsAsync(string bucketName);

    Task DeleteFileAsync(string bucket, string key);
    // 【新增】删除目录 (MinIO/S3 没有真正的目录，其实是删除特定前缀的所有对象)
    Task DeleteDirectoryAsync(string bucket, string prefix);
}

public class S3StorageService : IStorageService
{
    private readonly IAmazonS3 _s3Client;
    private readonly ILogger<S3StorageService> _logger;

    public S3StorageService(IAmazonS3 s3Client, ILogger<S3StorageService> logger)
    {
        _s3Client = s3Client;
        _logger = logger;
    }

    public async Task EnsureBucketExistsAsync(string bucketName)
    {
        // 1. 检查桶是否存在
        // 1. 检查桶是否存在
        var exists = await AmazonS3Util.DoesS3BucketExistV2Async(_s3Client, bucketName);

        if (!exists)
        {
            _logger.LogInformation("Bucket '{BucketName}' not found. Creating it...", bucketName);
            await _s3Client.PutBucketAsync(bucketName);
            _logger.LogInformation("Bucket '{BucketName}' created successfully.", bucketName);
        }

        // ====================================================================================
        // 【核心修复】2. 设置公开读取策略 (Public Read Policy)
        // ====================================================================================
        // 这段 JSON 告诉 MinIO：允许任何人 (Principal: *) 下载 (s3:GetObject) 这个桶里的文件
        // 使用 C# 原始字符串 (""") 避免转义噩梦
        var policyJson = """
                         {
                             "Version": "2012-10-17",
                             "Statement": [
                                 {
                                     "Effect": "Allow",
                                     "Principal": "*",
                                     "Action": [ "s3:GetObject" ],
                                     "Resource": [ "arn:aws:s3:::BUCKET_PLACEHOLDER/*" ]
                                 }
                             ]
                         }
                         """.Replace("BUCKET_PLACEHOLDER", bucketName);

        try
        {
            await _s3Client.PutBucketPolicyAsync(bucketName, policyJson);
            _logger.LogInformation("Public Read policy applied to bucket '{BucketName}'.", bucketName);
        }
        catch (Exception ex)
        {
            // 生产环境可能需要更严格的权限控制，这里作为开发环境警告处理
            _logger.LogWarning(ex, "Failed to apply public policy to '{BucketName}'. Please check MinIO permissions.", bucketName);
        }
    }

    public Task<string> GeneratePresignedUploadUrlAsync(string bucket, string key, string contentType, TimeSpan expiry)
    {
        var request = new GetPreSignedUrlRequest
        {
            BucketName = bucket,
            Key = key,
            Verb = HttpVerb.PUT,
            Expires = DateTime.UtcNow.Add(expiry),
            ContentType = contentType,
            Protocol = Protocol.HTTP
        };

        // GetPreSignedURL 是同步方法，我们用 Task.FromResult 包装它以符合异步接口
        string url = _s3Client.GetPreSignedURL(request);
        return Task.FromResult(url);
    }
    public async Task DeleteFileAsync(string bucket, string key)
    {
        try
        {
            await _s3Client.DeleteObjectAsync(bucket, key);
            _logger.LogInformation("Deleted file: {Bucket}/{Key}", bucket, key);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to delete file: {Bucket}/{Key}", bucket, key);
        }
    }

    public async Task DeleteDirectoryAsync(string bucket, string prefix)
    {
        try
        {
            // S3 删除目录需要先列出所有对象，然后批量删除
            var listRequest = new ListObjectsV2Request
            {
                BucketName = bucket,
                Prefix = prefix
            };

            var listResponse = await _s3Client.ListObjectsV2Async(listRequest);

            if (listResponse.S3Objects.Any())
            {
                var deleteRequest = new DeleteObjectsRequest
                {
                    BucketName = bucket,
                    Objects = listResponse.S3Objects.Select(x => new KeyVersion { Key = x.Key }).ToList()
                };

                await _s3Client.DeleteObjectsAsync(deleteRequest);
                _logger.LogInformation("Deleted directory: {Bucket}/{Prefix}", bucket, prefix);
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to delete directory: {Bucket}/{Prefix}", bucket, prefix);
        }
    }
}