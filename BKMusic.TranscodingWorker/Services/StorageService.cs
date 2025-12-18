using Amazon.S3;
using Amazon.S3.Model;
using Amazon.S3.Transfer;

namespace BKMusic.TranscodingWorker.Services;

public interface IStorageService
{
    Task DownloadFileAsync(string bucket, string key, string localPath);
    Task<string> UploadDirectoryAsync(string localDirectory, string bucket, string keyPrefix);
    // 补充：单文件上传方法 (用于上传封面)
    Task UploadSingleFileAsync(string bucket, string key, string filePath);
}

public class S3StorageService : IStorageService
{
    // 【修复 CS0103】必须声明这个字段
    private readonly IAmazonS3 _s3Client;

    // 【修复 CS0103】通过构造函数注入
    public S3StorageService(IAmazonS3 s3Client)
    {
        _s3Client = s3Client;
    }

    public async Task DownloadFileAsync(string bucket, string key, string localPath)
    {
        var response = await _s3Client.GetObjectAsync(bucket, key);
        await response.WriteResponseStreamToFileAsync(localPath, false, CancellationToken.None);
    }

    public async Task<string> UploadDirectoryAsync(string localDirectory, string bucket, string keyPrefix)
    {
        var bucketExists = await Amazon.S3.Util.AmazonS3Util.DoesS3BucketExistV2Async(_s3Client, bucket);
        if (!bucketExists)
        {
            await _s3Client.PutBucketAsync(bucket);
            var policy = """
                         {
                             "Version": "2012-10-17",
                             "Statement": [
                                 {
                                     "Effect": "Allow",
                                     "Principal": "*",
                                     "Action": [ "s3:GetObject" ],
                                     "Resource": [ "arn:aws:s3:::{{BUCKET_NAME}}/*" ]
                                 }
                             ]
                         }
                         """.Replace("{{BUCKET_NAME}}", bucket);

            await _s3Client.PutBucketPolicyAsync(bucket, policy);
        }

        var utility = new TransferUtility(_s3Client);
        var directoryInfo = new DirectoryInfo(localDirectory);

        foreach (var file in directoryInfo.GetFiles())
        {
            var request = new TransferUtilityUploadRequest
            {
                BucketName = bucket,
                FilePath = file.FullName,
                Key = $"{keyPrefix}/{file.Name}",
                CannedACL = S3CannedACL.Private
            };
            await utility.UploadAsync(request);
        }
        return $"{keyPrefix}/index.m3u8";
    }

    public async Task UploadSingleFileAsync(string bucket, string key, string filePath)
    {
        // 【修正】使用 AmazonS3Util.DoesS3BucketExistV2Async
        bool bucketExists = await Amazon.S3.Util.AmazonS3Util.DoesS3BucketExistV2Async(_s3Client, bucket);

        if (!bucketExists)
        {
        
                await _s3Client.PutBucketAsync(bucket);

            // 【核心修复】创建桶之后，立刻设置它的访问策略为“公开读取”
            // 【修改】去掉开头的 '$' 符号
            // 只使用普通的多行原始字符串，不进行插值
            var policy = """
                         {
                             "Version": "2012-10-17",
                             "Statement": [
                                 {
                                     "Effect": "Allow",
                                     "Principal": "*",
                                     "Action": [ "s3:GetObject" ],
                                     "Resource": [ "arn:aws:s3:::{{BUCKET_NAME}}/*" ]
                                 }
                             ]
                         }
                         """.Replace("{{BUCKET_NAME}}", bucket);

            await _s3Client.PutBucketPolicyAsync(bucket, policy);
            
        }

        var request = new Amazon.S3.Transfer.TransferUtilityUploadRequest
        {
            BucketName = bucket,
            Key = key,
            FilePath = filePath
        };

        // TransferUtility 需要实例化
        var utility = new Amazon.S3.Transfer.TransferUtility(_s3Client);
        await utility.UploadAsync(request);
    }
}