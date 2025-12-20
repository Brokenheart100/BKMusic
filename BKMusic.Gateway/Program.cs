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
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});


// Gateway 通常不需要 Controller，但保留也无妨
builder.Services.AddControllers();
builder.Services.AddOpenApi();

var app = builder.Build();

app.MapDefaultEndpoints();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// 4. 中间件管道
app.UseHttpsRedirection();
app.UseCors();
app.UseRateLimiter();
app.UseAuthorization();

// 5. 映射本地 Controller (如果有)
app.MapControllers();

// 【⭐⭐⭐ 核心修复 ⭐⭐⭐】
// 必须加上这一行！这才是 YARP 开始工作的地方！
// 它会接管所有没被 Controller 捕获的请求，并根据 appsettings.json 转发出去
app.MapReverseProxy();

app.Run();