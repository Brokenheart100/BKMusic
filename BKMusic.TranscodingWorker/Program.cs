using Amazon.S3;
using BKMusic.Shared.Messaging;
using BKMusic.TranscodingWorker.Handlers;
using BKMusic.TranscodingWorker.Services;
using System.Reflection;
using Wolverine;
using Wolverine.RabbitMQ;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

//1.注册 S3
 builder.Services.AddSingleton<IAmazonS3>(sp =>
 {
     var config = new AmazonS3Config
     {
         ServiceURL = builder.Configuration["ConnectionStrings:minio"],
         ForcePathStyle = true
     };
     return new AmazonS3Client("minioadmin", "minioadmin", config);
 });
builder.Services.AddSingleton<IStorageService, S3StorageService>();

// 2. 注册 FFmpeg 服务
builder.Services.AddSingleton<IFfmpegService, FfmpegService>();

// 3. 配置 Wolverine
builder.Host.UseWolverine(opts =>
{
    var rabbitConnectionString = builder.Configuration.GetConnectionString("messaging");

    opts.UseRabbitMq(rabbitConnectionString)
        .AutoProvision()
        .UseConventionalRouting();


    opts.DescribeHandlerMatch(typeof(MediaHandlers));

    opts.Discovery.IncludeAssembly(Assembly.GetExecutingAssembly());

    // 如果事件在 Shared 项目，也扫描它
    opts.Discovery.IncludeAssembly(typeof(MediaUploadedEvent).Assembly);

    opts.ApplicationAssembly = typeof(Program).Assembly;
    // 可选：开启更详细的诊断日志
    opts.Discovery.DisableConventionalDiscovery(false);
    opts.Discovery.IncludeAssembly(typeof(MediaHandlers).Assembly);
    // 监听名为 "MediaUploadedEvent" 的队列
    // Wolverine 默认会根据 Handler 的参数类型自动创建队列，通常不需要手动配置
});

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

app.MapDefaultEndpoints();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
