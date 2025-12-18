using BKMusic.CatalogService.Data;
using BKMusic.CatalogService.Features;
using Microsoft.OpenApi;
using Wolverine;
using Wolverine.RabbitMQ;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

// 1. 数据库
builder.AddNpgsqlDbContext<CatalogDbContext>("catalog-db");

// 2. Redis 缓存 (Aspire)
builder.AddRedisOutputCache("cache");

// 3. Wolverine (RabbitMQ)
builder.Host.UseWolverine(opts =>
{
    var rabbitConn = builder.Configuration.GetConnectionString("messaging");
    opts.UseRabbitMq(rabbitConn)
        .AutoProvision()
        .UseConventionalRouting();

    // 监听 MediaProcessedEvent
    // Catalog Service 是消费者，不需要配置 Outbox，除非它也要发消息
});
builder.Services.AddControllers();
builder.Services.AddOpenApi();


builder.Services.AddEndpointsApiExplorer();

// 5. 注册 Swagger 生成器
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "BKMusic Catalog Service API",
        Version = "v1",
        Description = "负责管理歌曲元数据和查询"
    });
});

var app = builder.Build();

app.MapDefaultEndpoints();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwagger();
    // 启用 Swagger UI 网页
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Catalog Service v1");
        // 设置为空，这样直接访问根路径 http://localhost:xxxx/ 就能看到 Swagger
        // c.RoutePrefix = string.Empty; 
    });
}
// 4. 确保建表
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<CatalogDbContext>();
    db.Database.EnsureCreated();
}

// 5. 注册路由
app.MapSongEndpoints();
app.MapPlaylistEndpoints();
app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
