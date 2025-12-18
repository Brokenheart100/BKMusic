using Amazon.S3;
using BKMusic.MediaService.Data;
using BKMusic.MediaService.Features;
using BKMusic.MediaService.Handlers;
using BKMusic.MediaService.Services;
using Microsoft.EntityFrameworkCore; // 确保引用
using Wolverine;
using Wolverine.EntityFrameworkCore;
using Wolverine.RabbitMQ;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = null;
    options.Limits.KeepAliveTimeout = TimeSpan.FromMinutes(10);
    options.Limits.RequestHeadersTimeout = TimeSpan.FromMinutes(10);
});

// 1. 注册数据库 (PostgreSQL)
// 使用 Aspire 提供的标准方法，它会自动处理连接字符串和遥测
builder.AddNpgsqlDbContext<MediaDbContext>("media-db");

// 2. 注册 S3 / MinIO
builder.Services.AddSingleton<IAmazonS3>(sp =>
{
    var serviceUrl = builder.Configuration["ConnectionStrings:minio"];
    // 增加空值检查，方便调试
    if (string.IsNullOrEmpty(serviceUrl))
    {
        throw new InvalidOperationException("ConnectionStrings:minio is missing. Check AppHost configuration.");
    }

    var config = new AmazonS3Config
    {
        ServiceURL = serviceUrl,
        ForcePathStyle = true, // MinIO 必须开启
        UseHttp = true
    };
    var logger = sp.GetRequiredService<ILogger<Program>>();
    logger.LogInformation("【DEBUG】 S3 Client is configured with URL: {ServiceUrl}", config.ServiceURL);
    return new AmazonS3Client("minioadmin", "minioadmin", config);
});

builder.Services.AddScoped<IStorageService, S3StorageService>();

// 3. 配置 Wolverine
builder.Host.UseWolverine(opts =>
{
    // A. 配置 RabbitMQ
    var rabbitConnectionString = builder.Configuration.GetConnectionString("messaging");
    opts.UseRabbitMq(rabbitConnectionString)
        .AutoProvision()
        .UseConventionalRouting();

    opts.UseEntityFrameworkCoreTransactions();
    opts.Discovery.IncludeAssembly(typeof(SongDeletedHandler).Assembly);
    // C. 对所有发送的消息启用 Outbox
    opts.Policies.UseDurableOutboxOnAllSendingEndpoints();
});

builder.Services.AddControllers();
builder.Services.AddOpenApi();

var app = builder.Build();

app.MapDefaultEndpoints();

// 4. 确保数据库创建 (包含 Wolverine 的表)
using (var scope = app.Services.CreateScope())
{

    var services = scope.ServiceProvider;
    var logger = services.GetRequiredService<ILogger<Program>>();
    var db = services.GetRequiredService<MediaDbContext>();

    try
    {
        logger.LogInformation("Applying database migrations for MediaDbContext...");

        // 确保你用的是 Migrate()，而不是 EnsureCreated()
        //db.Database.Migrate();
        db.Database.EnsureCreated();
        logger.LogInformation("Migrations applied successfully.");
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "An error occurred while migrating the database.");
        // 在开发环境中，让它崩溃是好事，能让你注意到问题
        throw;
    }
}

// 5. 映射 API
app.MapPost("/api/media/upload/init", InitUploadEndpoint.Handle);
app.MapPost("/api/media/upload/confirm", ConfirmUploadEndpoint.Handle);

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

//app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();