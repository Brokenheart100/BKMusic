using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

// 1. 注册 YARP 服务
builder.Services.AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"))
    .AddServiceDiscoveryDestinationResolver();

// 2. 配置全局限流
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddFixedWindowLimiter("fixed", limiterOptions =>
    {
        limiterOptions.PermitLimit = 100;
        limiterOptions.Window = TimeSpan.FromMinutes(1);
        limiterOptions.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        limiterOptions.QueueLimit = 5;
    });
});

// 3. 配置 CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowVueApp", policy =>
    {
        policy
            .WithOrigins(
                "http://localhost:5173",      // 本地 Vue 开发端口
                "https://admin.bkmusic.com" ,  // 生产环境域名
        "https://music-admin.vercel.app", // 👈 你的 Vercel 项目域名(部署后才知道，先预留)
        "https://*.vercel.app"
            )
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials(); // 如果需要带 Cookie/Token
    });
});


// Gateway 通常不需要 Controller，但保留也无妨
builder.Services.AddControllers();
builder.Services.AddOpenApi();

var app = builder.Build();

// ==========================================
// 1. 中间件管道 (Middleware Pipeline)
// ==========================================

// 1.1 CORS (最先执行，确保出错也能返回跨域头)
app.UseCors("AllowVueApp");

// 1.2. HTTPS 重定向 (Docker 环境下必须禁用，保持注释状态)
// app.UseHttpsRedirection();

// 1.3. 身份认证 (Authentication)
app.UseAuthentication();

// 1.4. 授权 (Authorization)
app.UseAuthorization();

// 1.5. 限流 (RateLimiter)
app.UseRateLimiter();

// ==========================================
// 2. 路由映射 (Endpoint Mapping)
// ==========================================

// 2.1 Aspire 健康检查 (建议放这里，和其他 Map 在一起)
app.MapDefaultEndpoints();

// 2.2 开发环境 Swagger
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// 2.3 控制器
app.MapControllers();

// 2.4 反向代理 (YARP) - 通常作为最后兜底
app.MapReverseProxy();
app.Run();